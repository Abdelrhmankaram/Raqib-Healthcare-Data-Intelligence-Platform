# consumer/doctor_consumer.py
# Consumes patients-topic.
# For each patient the doctor chooses one of 3 paths:
#   PATH A — direct admission: fills Admission + Diagnosis + Prescriptions → admissions-topic
#   PATH B — transfer: fills Services + TransferEvent → transfers-topic
#   PATH C — lab needed: sends to Lab consumer → lab-results-topic (handled by lab_consumer.py)
#
# In a real system the "choice" comes from a UI or rule engine.
# Here we simulate it with a simple routing function.

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

import uuid
import json
from datetime import datetime, timezone
from confluent_kafka import Consumer, Producer
from confluent_kafka.admin import AdminClient, NewTopic

from config.config import (
    PRODUCER_CONFIG, TOPIC_PATIENTS, TOPIC_ADMISSIONS,
    TOPIC_TRANSFERS, TOPIC_LAB_RESULTS,
    consumer_config,
)
from model.models import (
    Patient, Admission, Diagnosis, Prescription,
    Service, TransferEvent, AdmissionMessage, LabEvent,
)


# ── Static provider id for this doctor ────────────────────────────────────────
DOCTOR_PROVIDER_ID  = "PROV-DR-001"
DOCTOR_DEPARTMENT   = "General Medicine"
DOCTOR_ROOM         = "A101"
DOCTOR_SPECIALITY   = "Internal Medicine"

# ── Receiving doctor for transfers ────────────────────────────────────────────
RECEIVING_PROVIDER_ID = "PROV-DR-002"
RECEIVING_DEPARTMENT  = "Cardiology"
RECEIVING_ROOM        = "B205"

# ── Lab provider ──────────────────────────────────────────────────────────────
LAB_PROVIDER_ID = "PROV-LAB-001"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def create_topics(producer_cfg: dict):
    admin = AdminClient({"bootstrap.servers": producer_cfg["bootstrap.servers"]})
    topics = [
        NewTopic(TOPIC_ADMISSIONS,  num_partitions=3, replication_factor=3),
        NewTopic(TOPIC_TRANSFERS,   num_partitions=3, replication_factor=3),
        NewTopic(TOPIC_LAB_RESULTS, num_partitions=3, replication_factor=3),
    ]
    for topic, f in admin.create_topics(topics).items():
        try:
            f.result()
            print(f"[ADMIN] topic '{topic}' created")
        except Exception as e:
            print(f"[ADMIN] {topic}: {e}")


def on_delivery(err, msg):
    if err:
        print(f"[ERROR] delivery failed: {err}")
    else:
        print(f"[OK] → {msg.topic()} partition={msg.partition()} offset={msg.offset()}")


# ── Routing logic ──────────────────────────────────────────────────────────────
# In production this would be driven by the doctor's UI selection.
# Here we route by patient_id modulo 3 to simulate all 3 paths.

def choose_path(patient: Patient) -> str:
    routes = {0: "A", 1: "B", 2: "C"}
    return routes[patient.patient_id % 3]


# ══════════════════════════════════════════════════════════════════════════════
# PATH A — Direct admission with diagnosis and prescriptions
# ══════════════════════════════════════════════════════════════════════════════

def handle_path_a(patient: Patient, producer: Producer):
    admission_id = str(uuid.uuid4())

    admission = Admission(
        admission_id=admission_id,
        patient_id=patient.patient_id,
        admission_provider_id=DOCTOR_PROVIDER_ID,
        admission_datetime_in=now_iso(),
        admission_datetime_out=None,
        admission_type="ELECTIVE",
        admission_location=DOCTOR_DEPARTMENT,
        discharge_location=None,
        insurance_type="PRIVATE",
        total_cost=1500.00,
        payer_coverage=1200.00,
        hospital_expire_flag=False,
        primary_sdk="ITI",
    )

    diagnosis = Diagnosis(
        diagnosis_id=str(uuid.uuid4()),
        patient_id=patient.patient_id,
        admission_id=admission_id,
        provider_id=DOCTOR_PROVIDER_ID,
        description="Hypertension — stage 1",
        sub_domain_key="HYP-001",
        speciality=DOCTOR_SPECIALITY,
        sub_domain="Cardiovascular",
    )

    prescriptions = [
        Prescription(
            prescription_id=str(uuid.uuid4()),
            patient_id=patient.patient_id,
            admission_id=admission_id,
            provider_id=DOCTOR_PROVIDER_ID,
            drug_id="DRUG-AMLO-5MG",
            prescribed_date=now_iso(),
            status="ACTIVE",
        ),
        Prescription(
            prescription_id=str(uuid.uuid4()),
            patient_id=patient.patient_id,
            admission_id=admission_id,
            provider_id=DOCTOR_PROVIDER_ID,
            drug_id="DRUG-LOSA-50MG",
            prescribed_date=now_iso(),
            status="ACTIVE",
        ),
    ]

    # Bundle everything into one message so Spark writes all 3 tables atomically
    message = AdmissionMessage(
        admission=admission.__dict__,
        diagnosis=diagnosis.__dict__,
        prescriptions=[p.__dict__ for p in prescriptions],
    )

    producer.produce(
        topic=TOPIC_ADMISSIONS,
        key=str(patient.patient_id),
        value=message.to_json(),
        on_delivery=on_delivery,
    )
    producer.poll(0)
    print(f"[PATH A] patient_id={patient.patient_id} admission_id={admission_id}")


# ══════════════════════════════════════════════════════════════════════════════
# PATH B — Transfer to another doctor
# ══════════════════════════════════════════════════════════════════════════════

def handle_path_b(patient: Patient, producer: Producer):
    admission_id = str(uuid.uuid4())

    # Partial admission — datetime_out and discharge_location filled by receiving doctor
    admission = Admission(
        admission_id=admission_id,
        patient_id=patient.patient_id,
        admission_provider_id=DOCTOR_PROVIDER_ID,
        admission_datetime_in=now_iso(),
        admission_datetime_out=None,
        admission_type="URGENT",
        admission_location=DOCTOR_DEPARTMENT,
        discharge_location=None,
        insurance_type="PRIVATE",
        total_cost=0.0,
        payer_coverage=0.0,
        hospital_expire_flag=False,
        primary_sdk="ITI",
    )

    service = Service(
        service_id=str(uuid.uuid4()),
        patient_id=patient.patient_id,
        admission_id=admission_id,
        service_name="Cardiology Consultation",
        service_category="CONSULTATION",
        cost=300.00,
        duration=45,
    )

    transfer = TransferEvent(
        transfer_id=str(uuid.uuid4()),
        patient=patient.__dict__,
        admission=admission.__dict__,
        service=service.__dict__,
        from_provider_id=DOCTOR_PROVIDER_ID,
        to_provider_id=RECEIVING_PROVIDER_ID,
        from_department=DOCTOR_DEPARTMENT,
        to_department=RECEIVING_DEPARTMENT,
        from_room=DOCTOR_ROOM,
        to_room=RECEIVING_ROOM,
        transfer_datetime=now_iso(),
        transfer_reason="Patient requires specialist cardiac evaluation",
        doctor_notes=(
            f"Patient {patient.first_name} {patient.last_name} presenting with "
            f"chest discomfort. BP elevated. Referred to cardiology. "
            f"Blood type: {patient.blood_type}. Gender: {patient.gender}."
        ),
    )

    producer.produce(
        topic=TOPIC_TRANSFERS,
        key=str(patient.patient_id),
        value=transfer.to_json(),
        on_delivery=on_delivery,
    )
    producer.poll(0)
    print(f"[PATH B] patient_id={patient.patient_id} transfer_id={transfer.transfer_id}")


# ══════════════════════════════════════════════════════════════════════════════
# PATH C — Lab needed: produce a lab request to lab-results-topic
# The lab_consumer.py will consume this, fill the LabEvent, and produce back
# ══════════════════════════════════════════════════════════════════════════════

def handle_path_c(patient: Patient, producer: Producer):
    admission_id = str(uuid.uuid4())

    # Send a lab request — lab consumer fills the actual values
    lab_request = {
        "event_type":    "LAB_REQUEST",
        "patient_id":    patient.patient_id,
        "admission_id":  admission_id,
        "provider_id":   DOCTOR_PROVIDER_ID,
        "requested_at":  now_iso(),
        "tests_ordered": ["CBC", "BMP", "Lipid Panel"],
        # Pass full patient so lab has context
        "patient":       patient.__dict__,
    }

    producer.produce(
        topic=TOPIC_LAB_RESULTS,
        key=str(patient.patient_id),
        value=json.dumps(lab_request),
        on_delivery=on_delivery,
    )
    producer.poll(0)
    print(f"[PATH C] patient_id={patient.patient_id} admission_id={admission_id} → lab requested")


# ══════════════════════════════════════════════════════════════════════════════
# Main consumer loop
# ══════════════════════════════════════════════════════════════════════════════

def main():
    create_topics(PRODUCER_CONFIG)

    consumer = Consumer(consumer_config("doctor-consumer-group"))
    consumer.subscribe([TOPIC_PATIENTS])

    producer = Producer(PRODUCER_CONFIG)

    print("[DOCTOR] Listening on patients-topic...")

    try:
        while True:
            msg = consumer.poll(timeout=5.0)

            if msg is None:
                continue
            if msg.error():
                print(f"[ERROR] {msg.error()}")
                continue

            patient = Patient.from_json(msg.value().decode("utf-8"))
            path    = choose_path(patient)

            print(f"\n[DOCTOR] Received patient_id={patient.patient_id} → routing to PATH {path}")

            if path == "A":
                handle_path_a(patient, producer)
            elif path == "B":
                handle_path_b(patient, producer)
            elif path == "C":
                handle_path_c(patient, producer)

            consumer.commit(message=msg)

    except KeyboardInterrupt:
        print("\n[DOCTOR] Shutting down")
    finally:
        consumer.close()
        producer.flush()


if __name__ == "__main__":
    main()
