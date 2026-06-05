import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import json
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType, StructField,
    StringType, FloatType, TimestampType
)

# ─── Config ───────────────────────────────────────────────────────────────────
BOOTSTRAP_SERVERS     = "broker-1:29092,broker-2:29092,broker-3:29092"
TOPIC_PATIENTS    = "patients-topic"       # Receptionist → Doctor
TOPIC_ADMISSIONS  = "admissions-topic"     # Doctor (Path A) → Spark
TOPIC_TRANSFERS   = "transfers-topic"      # Doctor (Path B) → 2nd Doctor
TOPIC_LAB_RESULTS = "lab-results-topic"   # Lab consumer → Spark
POSTGRES_URL          = "jdbc:postgresql://dwh:5432/hospital"
POSTGRES_USER         = "dwh_admin"
POSTGRES_PASS         = "dwh123"
SPARK_TRIGGER_SECONDS = "10 seconds"
SPARK_CHECKPOINT_DIR  = "/tmp/spark-checkpoints"

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import json
from decimal import Decimal, InvalidOperation
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType, StructField,
    StringType, DecimalType, BooleanType
)



LAB_SCHEMA = StructType([
    StructField("lab_event_id",    StringType(),       False),
    StructField("patient_id",      StringType(),       True),
    StructField("admission_id",    StringType(),       True),
    StructField("specimen_id",     StringType(),       True),
    StructField("item_id",         StringType(),       True),
    StructField("provider_id",     StringType(),       True),
    StructField("done_datetime",   StringType(),       True),
    StructField("stored_datetime", StringType(),       True),
    StructField("value",           StringType(),       True),
    StructField("measurement_unit",StringType(),       True),
    StructField("range_lower",     DecimalType(10,4),  True),  # ← Decimal
    StructField("range_higher",    DecimalType(10,4),  True),  # ← Decimal
    StructField("abnormal_flag",   StringType(),       True),
])


def to_decimal(val):
    """Convert any numeric value safely to Decimal for Spark DecimalType."""
    if val is None:
        return None
    try:
        return Decimal(str(val))
    except InvalidOperation:
        return None


def write_to_postgres(df, table: str):
    df.write \
        .format("jdbc") \
        .option("url",      POSTGRES_URL) \
        .option("dbtable",  table) \
        .option("user",     POSTGRES_USER) \
        .option("password", POSTGRES_PASS) \
        .option("driver",   "org.postgresql.Driver") \
        .mode("append") \
        .save()


def process_batch(batch_df, batch_id):
    if batch_df.isEmpty():
        return

    rows       = batch_df.collect()
    lab_events = []

    for row in rows:
        try:
            data = json.loads(row["value"])
        except (json.JSONDecodeError, TypeError) as e:
            print(f"[SPARK LAB] Skipping malformed message: {e}")
            continue

        if data.get("event_type") != "LAB_RESULT":
            continue

        data.pop("event_type", None)

        # ✅ Convert floats/strings → Decimal for range columns
        data["range_lower"]  = to_decimal(data.get("range_lower"))
        data["range_higher"] = to_decimal(data.get("range_higher"))

        # ✅ Normalize abnormal_flag → string "true"/"false"
        flag = data.get("abnormal_flag")
        data["abnormal_flag"] = str(flag).lower() if flag is not None else "false"

        lab_events.append(data)

    if not lab_events:
        print(f"[SPARK LAB] batch_id={batch_id} — no LAB_RESULT events, skipping")
        return

    spark  = SparkSession.getActiveSession()
    lab_df = spark.createDataFrame(lab_events, schema=LAB_SCHEMA)
    write_to_postgres(lab_df, "public.lab_events")
    print(f"[SPARK LAB] batch_id={batch_id} wrote {len(lab_events)} lab events ✓")


def main():
    spark = SparkSession.builder \
        .appName("HospitalLabStream") \
        .config("spark.jars.packages",
                "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0,"
                "org.postgresql:postgresql:42.7.1") \
        .getOrCreate()

    spark.sparkContext.setLogLevel("WARN")

    raw = spark.readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", BOOTSTRAP_SERVERS) \
        .option("subscribe",               TOPIC_LAB_RESULTS) \
        .option("startingOffsets",         "earliest") \
        .option("maxOffsetsPerTrigger",    200) \
        .load() \
        .selectExpr("CAST(value AS STRING) as value")

    query = raw.writeStream \
        .foreachBatch(process_batch) \
        .trigger(processingTime=SPARK_TRIGGER_SECONDS) \
        .option("checkpointLocation", f"{SPARK_CHECKPOINT_DIR}/lab") \
        .start()

    print(f"[SPARK LAB] Lab stream started — trigger={SPARK_TRIGGER_SECONDS}")
    query.awaitTermination()


if __name__ == "__main__":
    main()