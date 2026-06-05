# Hospital Kafka Pipeline — Run Order

pip install -r requirements.txt

# Terminal 1 — Lab consumer (start first so lab requests don't pile up)
python consumer/lab_consumer.py

# Terminal 2 — Doctor consumer (main branching logic)
python consumer/doctor_consumer.py

# Terminal 3 — 2nd Doctor consumer (receives transfers)
python consumer/second_doctor_consumer.py

# Terminal 4 — Spark: admissions + diagnosis + prescriptions
python spark/spark_admissions.py

# Terminal 5 — Spark: lab events
python spark/spark_lab.py

# Terminal 6 — Produce patients (run last)
python producer/receptionist_producer.py
