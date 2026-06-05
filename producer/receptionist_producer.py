# producer/receptionist_producer.py
# Reads all patients from data.py and produces them to patients-topic.
# Key = patient_id so the same patient always goes to the same partition.

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

from confluent_kafka import Producer
from confluent_kafka.admin import AdminClient, NewTopic
from config.config import PRODUCER_CONFIG, TOPIC_PATIENTS
from data.data import SAMPLE_PATIENTS


def create_topic():
    admin = AdminClient({"bootstrap.servers": PRODUCER_CONFIG["bootstrap.servers"]})
    futures = admin.create_topics([NewTopic(TOPIC_PATIENTS, num_partitions=3, replication_factor=3)])
    for topic, f in futures.items():
        try:
            f.result()
            print(f"[ADMIN] topic '{topic}' created")
        except Exception as e:
            print(f"[ADMIN] {topic}: {e}")


def on_delivery(err, msg):
    if err:
        print(f"[ERROR] {err}")
    else:
        print(f"[OK] topic={msg.topic()} partition={msg.partition()} offset={msg.offset()}")


def main():
    create_topic()

    producer = Producer(PRODUCER_CONFIG)

    for patient in SAMPLE_PATIENTS:
        producer.produce(
            topic=TOPIC_PATIENTS,
            key=str(patient.patient_id),   # partition by patient_id
            value=patient.to_json(),
            on_delivery=on_delivery,
        )
        producer.poll(0)
        print(f"[SENT] patient_id={patient.patient_id} name={patient.first_name} {patient.last_name}")

    remaining = producer.flush(timeout=10)
    if remaining:
        print(f"[WARN] {remaining} messages not delivered")
    else:
        print("[DONE] All patients produced")


if __name__ == "__main__":
    main()
