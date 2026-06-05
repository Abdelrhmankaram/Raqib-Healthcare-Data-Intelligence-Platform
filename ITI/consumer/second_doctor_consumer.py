import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import uuid
import json
from datetime import datetime, timezone
from confluent_kafka import Consumer, Producer

from config.config import (
    PRODUCER_CONFIG, TOPIC_TRANSFERS, TOPIC_ADMISSIONS,
    TOPIC_LAB_RESULTS, consumer_config,
)
from model.models import (
    Admission, Diagnosis, Prescription,
    TransferEvent, AdmissionMessage,
)

DOCTOR_PROVIDER_ID = "PROV-DR-002"
DOCTOR_SPECIALITY  = "Cardiology"
DOCTOR_DEPARTMENT  = "Cardiology"
DOCTOR_ROOM        = "B205"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def on_delivery(err, msg):
    if err:
        print(f"[ERROR] {err}")
    else:
        print(f"[OK] → {msg.topic()} partition={msg.partition()} offset={msg.offset()}")


# ─── PATH A — cure + write all 4 tables ───────────────────────────────────────

def handle_path_a(transfer: TransferEvent, producer: Producer):
    admission_id = transfer.admission["admission_id"]
    patient_id   = transfer.patient["patient_id"]

    completed_admission = dict(transfer.admission)
    completed_admission.update({
        "admission_provider_id": DOCTOR_PROVIDER_ID,
        "admission_datetime_out": now_iso(),
        "discharge_location":    "Home",
        "total_cost":            4500.00,
        "payer_coverage":        3600.00,
    })

    diagnosis = Diagnosis(
        diagnosis_id  = str(uuid.uuid4()),
        patient_id    = patient_id,
        admission_id  = admission_id,
        provider_id   = DOCTOR_PROVIDER_ID,
        description   = "Atrial fibrillation — paroxysmal",
        sub_domain_key= "AFIB-001",
        speciality    = DOCTOR_SPECIALITY,
        sub_domain    = "Cardiac Arrhythmia",
    )

    prescriptions = [
        Prescription(
            prescription_id = str(uuid.uuid4()),
            patient_id      = patient_id,
            admission_id    = admission_id,
            provider_id     = DOCTOR_PROVIDER_ID,
            drug_id         = "DRUG-BISOP-5MG",
            prescribed_date = now_iso(),
            status          = "ACTIVE",
        )
    ]

    transfer_data = {
        "transfer_id":       transfer.transfer_id,
        "patient_id":        patient_id,
        "from_provider_id":  transfer.from_provider_id,
        "to_provider_id":    transfer.to_provider_id,
        "from_department":   transfer.from_department,
        "to_department":     transfer.to_department,
        "from_room":         transfer.from_room,
        "to_room":           transfer.to_room,
        "transfer_datetime": transfer.transfer_datetime,
        "transfer_reason":   transfer.transfer_reason,
        "doctor_notes":      transfer.doctor_notes,
    }

    payload = {
        "admission":     completed_admission,
        "diagnosis":     diagnosis.__dict__,
        "prescriptions": [p.__dict__ for p in prescriptions],
        "transfer_data": transfer_data,
    }

    producer.produce(
        topic       = TOPIC_ADMISSIONS,
        key         = str(patient_id),
        value       = json.dumps(payload),
        on_delivery = on_delivery,
    )
    producer.poll(0)
    print(f"[2ND DR PATH A] patient_id={patient_id} ✓ all 4 tables will be written by Spark")


# ─── PATH C — lab needed ──────────────────────────────────────────────────────

def handle_path_c(transfer: TransferEvent, producer: Producer):
    patient_id   = transfer.patient["patient_id"]
    admission_id = transfer.admission["admission_id"]

    lab_request = {
        "event_type":   "LAB_REQUEST",
        "patient_id":   patient_id,
        "admission_id": admission_id,
        "provider_id":  DOCTOR_PROVIDER_ID,
        "requested_at": now_iso(),
        "tests_ordered": ["Troponin", "BNP", "Echo"],
        "patient":      transfer.patient,
        "transfer_data": {
            "transfer_id":      transfer.transfer_id,
            "patient_id":       patient_id,
            "from_provider_id": transfer.from_provider_id,
            "from_department":  transfer.from_department,
            "to_department":    transfer.to_department,
            "from_room":        transfer.from_room,
            "to_room":          transfer.to_room,
            "transfer_datetime":transfer.transfer_datetime,
            "transfer_reason":  transfer.transfer_reason,
        },
    }

    producer.produce(
        topic       = TOPIC_LAB_RESULTS,
        key         = str(patient_id),
        value       = json.dumps(lab_request),
        on_delivery = on_delivery,
    )
    producer.poll(0)
    print(f"[2ND DR PATH C] patient_id={patient_id} → lab requested")


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    consumer = Consumer(consumer_config("second-doctor-consumer-group"))
    consumer.subscribe([TOPIC_TRANSFERS])

    producer = Producer(PRODUCER_CONFIG)

    # ✅ Round-robin counter — guaranteed alternation A, C, A, C, ...
    message_count = 0

    print("[2ND DOCTOR] Listening on transfers-topic...")

    try:
        while True:
            msg = consumer.poll(timeout=5.0)
            if msg is None:
                continue
            if msg.error():
                print(f"[ERROR] {msg.error()}")
                continue

            transfer   = TransferEvent.from_json(msg.value().decode("utf-8"))
            patient_id = transfer.patient["patient_id"]

            # ✅ Alternates strictly: even count → A, odd count → C
            path = "A" if message_count % 2 == 0 else "C"
            message_count += 1

            print(f"\n[2ND DOCTOR] patient_id={patient_id} | msg #{message_count} → PATH {path}")

            if path == "A":
                handle_path_a(transfer, producer)
            elif path == "C":
                handle_path_c(transfer, producer)

            consumer.commit(message=msg)

    except KeyboardInterrupt:
        print("\n[2ND DOCTOR] Shutting down")
    finally:
        consumer.close()
        producer.flush()


if __name__ == "__main__":
    main()