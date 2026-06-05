import json
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType, StructField,
    StringType, DoubleType,
)

# ─── Config ───────────────────────────────────────────────────────────────────
BOOTSTRAP_SERVERS = "broker-1:29092,broker-2:29092,broker-3:29092"
TOPIC_PATIENTS = "patients-topic"

POSTGRES_URL = "jdbc:postgresql://dwh:5432/postgres"
POSTGRES_USER = "kafka_admin"
POSTGRES_PASS = "kafka_admin_password"
SPARK_TRIGGER_SECONDS = "10 seconds"
SPARK_CHECKPOINT_DIR = "/tmp/spark-checkpoints"

# ─── Schema ───────────────────────────────────────────────────────────────────

PATIENT_SCHEMA = StructType([
    StructField("Patient_ID", StringType(), True),
    StructField("SSN", StringType(), True),
    StructField("First_Name", StringType(), True),
    StructField("Last_Name", StringType(), True),
    StructField("Birth_Date", StringType(), True),
    StructField("Death_Date", StringType(), True),
    StructField("Blood_Type", StringType(), True),
    StructField("Martial_State", StringType(), True),
    StructField("Race", StringType(), True),
    StructField("Ethnicity", StringType(), True),
    StructField("Gender", StringType(), True),
    StructField("Language", StringType(), True),
    StructField("Birth_Place", StringType(), True),
    StructField("Address", StringType(), True),
    StructField("City", StringType(), True),
    StructField("Country", StringType(), True),
    StructField("HealthCare_Expenses", DoubleType(), True),
    StructField("HealthCare_Coverage", DoubleType(), True),
    StructField("Income", DoubleType(), True),
])


# ─── Postgres Writer ──────────────────────────────────────────────────────────

def write_to_postgres(df, table: str):
    df.write \
        .format("jdbc") \
        .option("url", POSTGRES_URL) \
        .option("dbtable", table) \
        .option("user", POSTGRES_USER) \
        .option("password", POSTGRES_PASS) \
        .option("driver", "org.postgresql.Driver") \
        .mode("append") \
        .save()


# ─── foreachBatch Handler ─────────────────────────────────────────────────────

def process_batch(batch_df, batch_id):
    if batch_df.isEmpty():
        print(f"[SPARK PATIENTS] batch_id={batch_id} — empty, skipping")
        return

    rows = batch_df.collect()
    print(f"[SPARK PATIENTS] batch_id={batch_id} rows={len(rows)}")

    patients = []

    for row in rows:
        try:
            p = json.loads(row["value"])

            patients.append({
                "Patient_ID": str(p.get("patient_id") or ""),
                "SSN": str(p.get("ssn") or ""),
                "First_Name": str(p.get("first_name") or ""),
                "Last_Name": str(p.get("last_name") or ""),
                "Birth_Date": str(p.get("birth_date") or ""),
                "Death_Date": str(p.get("death_date") or ""),
                "Blood_Type": str(p.get("blood_type") or ""),
                "Martial_State": str(p.get("martial_state") or ""),
                "Race": str(p.get("race") or ""),
                "Ethnicity": str(p.get("ethnicity") or ""),
                "Gender": str(p.get("gender") or ""),
                "Language": str(p.get("language") or ""),
                "Birth_Place": str(p.get("birth_place") or ""),
                "Address": str(p.get("address") or ""),
                "City": str(p.get("city") or ""),
                "Country": str(p.get("country") or ""),
                "HealthCare_Expenses": float(p.get("healthcare_expenses") or 0.0),
                "HealthCare_Coverage": float(p.get("healthcare_coverage") or 0.0),
                "Income": float(p.get("income") or 0.0),
            })

        except Exception as e:
            print(f"[SPARK PATIENTS] ERROR parsing row: {e}")
            continue

    if patients:
        try:
            spark = SparkSession.getActiveSession()
            pat_df = spark.createDataFrame(patients, schema=PATIENT_SCHEMA)
            write_to_postgres(pat_df, "Patients")
            print(f"[SPARK PATIENTS] ✓ wrote {len(patients)} patients")
        except Exception as e:
            print(f"[SPARK PATIENTS] ERROR writing patients: {e}")


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    spark = SparkSession.builder \
        .appName("HospitalPatientsStream") \
        .config(
        "spark.jars.packages",
        "org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0,"
        "org.postgresql:postgresql:42.7.1"
    ) \
        .getOrCreate()

    spark.sparkContext.setLogLevel("WARN")

    raw = spark.readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", BOOTSTRAP_SERVERS) \
        .option("subscribe", TOPIC_PATIENTS) \
        .option("startingOffsets", "earliest") \
        .option("maxOffsetsPerTrigger", 100) \
        .load() \
        .selectExpr("CAST(value AS STRING) as value")

    query = raw.writeStream \
        .foreachBatch(process_batch) \
        .trigger(processingTime=SPARK_TRIGGER_SECONDS) \
        .option("checkpointLocation", f"{SPARK_CHECKPOINT_DIR}/patients") \
        .start()

    print(f"[SPARK PATIENTS] Patients stream started — trigger={SPARK_TRIGGER_SECONDS}")
    query.awaitTermination()


if __name__ == "__main__":
    main()