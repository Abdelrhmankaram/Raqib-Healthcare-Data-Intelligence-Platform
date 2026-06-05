# config/config.py
# All Kafka broker and topic settings in one place.
# Change only here — every other file imports from this module.

BOOTSTRAP_SERVERS = "localhost:9092,localhost:9093,localhost:9094"

# ─── Topics ───────────────────────────────────────────────────────────────────
TOPIC_PATIENTS    = "patients-topic"       # Receptionist → Doctor
TOPIC_ADMISSIONS  = "admissions-topic"     # Doctor (Path A) → Spark
TOPIC_TRANSFERS   = "transfers-topic"      # Doctor (Path B) → 2nd Doctor
TOPIC_LAB_RESULTS = "lab-results-topic"   # Lab consumer → Spark

# ─── Producer defaults ────────────────────────────────────────────────────────
PRODUCER_CONFIG = {
    "bootstrap.servers":  BOOTSTRAP_SERVERS,
    "acks":               "all",
    "retries":            5,
    "retry.backoff.ms":   300,
    "linger.ms":          20,
    "batch.size":         16384,
    "compression.type":   "lz4",
    "enable.idempotence": True,
}

# ─── Consumer defaults ────────────────────────────────────────────────────────
def consumer_config(group_id: str) -> dict:
    return {
        "bootstrap.servers":  BOOTSTRAP_SERVERS,
        "group.id":           group_id,
        "auto.offset.reset":  "earliest",
        "enable.auto.commit": False,      # manual commit after processing
    }

# ─── Spark ────────────────────────────────────────────────────────────────────
POSTGRES_URL  = "jdbc:postgresql://localhost:5432/hospital"
POSTGRES_USER = "admin"
POSTGRES_PASS = "dwh123"
SPARK_TRIGGER_SECONDS = "10 seconds"
SPARK_CHECKPOINT_DIR  = "/tmp/spark-checkpoints"
