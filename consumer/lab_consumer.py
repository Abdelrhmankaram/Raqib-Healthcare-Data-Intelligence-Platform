# consumer/lab_consumer.py
# Consumes lab-results-topic for LAB_REQUEST events.
# Fills the LabEvent with actual values and produces the completed
# LabEvent back to lab-results-topic with event_type=LAB_RESULT.
# Spark then reads LAB_RESULT events and writes to Postgres.

import sys
import os

sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
)

import uuid
import json
from datetime import datetime, timezone
from confluent_kafka import Consumer, Producer

from config.config import PRODUCER_CONFIG, TOPIC_LAB_RESULTS, consumer_config
from model.models import LabEvent

LAB_PROVIDER_ID = "PROV-LAB-001"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def on_delivery(err, msg):
    if err:
        print(f"[ERROR] {err}")
    else:
        print(f"[OK] → {msg.topic()} partition={msg.partition()} offset={msg.offset()}")


def simulate_lab_results(test_name: str) -> dict:
    """
    Simulates actual lab machine results.
    In production this reads from lab equipment API or DB.
    Returns value, unit, range_lower, range_higher, abnormal_flag.
    """
    results = {
        "CBC": {
            "value": "4.5",
            "measurement_unit": "10^9/L",
            "range_lower": 4.0,
            "range_higher": 11.0,
            "abnormal_flag": False,
        },
        "BMP": {
            "value": "138",
            "measurement_unit": "mEq/L",
            "range_lower": 136.0,
            "range_higher": 145.0,
            "abnormal_flag": False,
        },
        "Lipid Panel": {
            "value": "240",
            "measurement_unit": "mg/dL",
            "range_lower": 0.0,
            "range_higher": 200.0,
            "abnormal_flag": True,       # high cholesterol
        },
        "Troponin": {
            "value": "0.15",
            "measurement_unit": "ng/mL",
            "range_lower": 0.0,
            "range_higher": 0.04,
            "abnormal_flag": True,       # elevated — cardiac damage indicator
        },
        "BNP": {
            "value": "420",
            "measurement_unit": "pg/mL",
            "range_lower": 0.0,
            "range_higher": 100.0,
            "abnormal_flag": True,       # heart failure indicator
        },
        "Echo": {
            "value": "EF 35%",
            "measurement_unit": "%",
            "range_lower": 55.0,
            "range_higher": 70.0,
            "abnormal_flag": True,       # reduced ejection fraction
        },
    }
    return results.get(test_name, {
        "value": "normal",
        "measurement_unit": "N/A",
        "range_lower": 0.0,
        "range_higher": 100.0,
        "abnormal_flag": False,
    })


def process_lab_request(request: dict, producer: Producer):
    patient_id   = request["patient_id"]
    admission_id = request["admission_id"]
    tests        = request.get("tests_ordered", [])

    for test in tests:
        result = simulate_lab_results(test)

        lab_event = LabEvent(
            lab_event_id=str(uuid.uuid4()),
            patient_id=patient_id,
            admission_id=admission_id,
            specimen_id=str(uuid.uuid4()),
            item_id=test.upper().replace(" ", "_"),
            provider_id=LAB_PROVIDER_ID,
            done_datetime=now_iso(),
            stored_datetime=now_iso(),
            value=result["value"],
            measurement_unit=result["measurement_unit"],
            range_lower=result["range_lower"],
            range_higher=result["range_higher"],
            abnormal_flag=result["abnormal_flag"],
        )

        # Produce back as LAB_RESULT so Spark can distinguish from LAB_REQUEST
        payload = {
            "event_type": "LAB_RESULT",
            **lab_event.__dict__,
        }

        producer.produce(
            topic=TOPIC_LAB_RESULTS,
            key=str(patient_id),
            value=json.dumps(payload),
            on_delivery=on_delivery,
        )
        producer.poll(0)

        flag_str = "⚠ ABNORMAL" if result["abnormal_flag"] else "✓ normal"
        print(f"[LAB] patient_id={patient_id} test={test} value={result['value']} {flag_str}")


def main():
    consumer = Consumer(consumer_config("lab-consumer-group"))
    consumer.subscribe([TOPIC_LAB_RESULTS])

    producer = Producer(PRODUCER_CONFIG)

    print("[LAB] Listening on lab-results-topic for LAB_REQUEST events...")

    try:
        while True:
            msg = consumer.poll(timeout=5.0)
            if msg is None:
                continue
            if msg.error():
                print(f"[ERROR] {msg.error()}")
                continue

            data = json.loads(msg.value().decode("utf-8"))

            # Only process LAB_REQUEST — skip LAB_RESULT (those are for Spark)
            if data.get("event_type") != "LAB_REQUEST":
                consumer.commit(message=msg)
                continue

            print(f"\n[LAB] Lab request for patient_id={data['patient_id']}")
            process_lab_request(data, producer)

            consumer.commit(message=msg)

    except KeyboardInterrupt:
        print("\n[LAB] Shutting down")
    finally:
        consumer.close()
        producer.flush()


if __name__ == "__main__":
    main()
