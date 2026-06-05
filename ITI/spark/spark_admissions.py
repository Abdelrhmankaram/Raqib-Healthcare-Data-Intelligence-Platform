import json
from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType, StructField,
    StringType, DoubleType, BooleanType,
)

# ─── Config ───────────────────────────────────────────────────────────────────
BOOTSTRAP_SERVERS = "broker-1:29092,broker-2:29092,broker-3:29092"
TOPIC_ADMISSIONS = "admissions-topic"

POSTGRES_URL = "jdbc:postgresql://dwh:5432/postgres"
POSTGRES_USER = "kafka_admin"
POSTGRES_PASS = "kafka_admin_password"
SPARK_TRIGGER_SECONDS = "10 seconds"
SPARK_CHECKPOINT_DIR = "/tmp/spark-checkpoints"

# ─── Schemas ──────────────────────────────────────────────────────────────────

ADMISSION_SCHEMA = StructType([
    StructField("Admission_ID", StringType(), True),
    StructField("Patient_ID", StringType(), True),
    StructField("Provider_ID", StringType(), True),
    StructField("Admission_DateTime_In", StringType(), True),
    StructField("Admission_DateTime_Out", StringType(), True),
    StructField("Admission_Type", StringType(), True),
    StructField("Admission_Location", StringType(), True),
    StructField("Discharge_Location", StringType(), True),
    StructField("Insurance_Type", StringType(), True),
    StructField("Total_Cost", DoubleType(), True),
    StructField("Payer_Coverage", DoubleType(), True),
    StructField("Hospital_Expire_Flag", BooleanType(), True),
])

DIAGNOSIS_SCHEMA = StructType([
    StructField("Diagnosis_ID", StringType(), True),
    StructField("Patient_ID", StringType(), True),
    StructField("Admission_ID", StringType(), True),
    StructField("Provider_ID", StringType(), True),
    StructField("Description", StringType(), True),
    StructField("Sub_Domain_Key", StringType(), True),
    StructField("Speciality", StringType(), True),
    StructField("Sub_Domain", StringType(), True),
])

PRESCRIPTION_SCHEMA = StructType([
    StructField("Prescription_ID", StringType(), True),
    StructField("Patient_ID", StringType(), True),
    StructField("Admission_ID", StringType(), True),
    StructField("Provider_ID", StringType(), True),
    StructField("Drug_ID", StringType(), True),
    StructField("Prescribed_Date", StringType(), True),
    StructField("Status", StringType(), True),
])

TRANSFER_SCHEMA = StructType([
    StructField("Transfer_ID", StringType(), True),
    StructField("Patient_ID", StringType(), True),
    StructField("Provider_ID", StringType(), True),
    StructField("From_Department", StringType(), True),
    StructField("To_Department", StringType(), True),
    StructField("From_Room", StringType(), True),
    StructField("To_Room", StringType(), True),
    StructField("Transfer_DateTime", StringType(), True),
    StructField("Transfer_Reason", StringType(), True),
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
        print(f"[SPARK] batch_id={batch_id} — empty, skipping")
        return

    rows = batch_df.collect()
    print(f"[SPARK] batch_id={batch_id} rows={len(rows)}")

    admissions = []
    diagnoses = []
    prescriptions = []
    transfers = []  # only filled when message came from 2nd doctor

    for row in rows:
        try:
            data = json.loads(row["value"])

            # ── Admission ──────────────────────────────────────────────────────
            adm = data.get("admission", {})
            admissions.append({
                "Admission_ID": str(adm.get("admission_id") or ""),
                "Patient_ID": str(adm.get("patient_id") or ""),
                "Provider_ID": str(adm.get("provider_id") or ""),
                "Admission_DateTime_In": adm.get("admission_datetime_in") or None,
                "Admission_DateTime_Out": adm.get("admission_datetime_out") or None,
                "Admission_Type": str(adm.get("admission_type") or ""),
                "Admission_Location": str(adm.get("admission_location") or ""),
                "Discharge_Location": str(adm.get("discharge_location") or ""),
                "Insurance_Type": str(adm.get("insurance_type") or ""),
                "Total_Cost": float(adm.get("total_cost") or 0.0),
                "Payer_Coverage": float(adm.get("payer_coverage") or 0.0),
                "Hospital_Expire_Flag": bool(adm.get("hospital_expire_flag") or False),
            })

            # ── Diagnosis ──────────────────────────────────────────────────────
            diag = data.get("diagnosis", {})
            diagnoses.append({
                "Diagnosis_ID": str(diag.get("diagnosis_id") or ""),
                "Patient_ID": str(diag.get("patient_id") or ""),
                "Admission_ID": str(diag.get("admission_id") or ""),
                "Provider_ID": str(diag.get("provider_id") or ""),
                "Description": str(diag.get("description") or ""),
                "Sub_Domain_Key": str(diag.get("sub_domain_key") or ""),
                "Speciality": str(diag.get("speciality") or ""),
                "Sub_Domain": str(diag.get("sub_domain") or ""),
            })

            # ── Prescriptions ──────────────────────────────────────────────────
            for rx in data.get("prescriptions", []):
                prescriptions.append({
                    "Prescription_ID": str(rx.get("prescription_id") or ""),
                    "Patient_ID": str(rx.get("patient_id") or ""),
                    "Admission_ID": str(rx.get("admission_id") or ""),
                    "Provider_ID": str(rx.get("provider_id") or ""),
                    "Drug_ID": str(rx.get("drug_id") or ""),
                    "Prescribed_Date": str(rx.get("prescribed_date") or ""),
                    "Status": str(rx.get("status") or ""),
                })

            # ── Transfer (only present if message from 2nd doctor) ─────────────
            # Check: if transfer_data key exists in the message, it came via
            # second doctor path — write the Transfers table too
            tr = data.get("transfer_data")
            if tr:
                transfers.append({
                    "Transfer_ID": str(tr.get("transfer_id") or ""),
                    "Patient_ID": str(tr.get("patient_id") or ""),
                    "Provider_ID": str(tr.get("from_provider_id") or ""),
                    "From_Department": str(tr.get("from_department") or ""),
                    "To_Department": str(tr.get("to_department") or ""),
                    "From_Room": str(tr.get("from_room") or ""),
                    "To_Room": str(tr.get("to_room") or ""),
                    "Transfer_DateTime": str(tr.get("transfer_datetime") or ""),
                    "Transfer_Reason": str(tr.get("transfer_reason") or ""),
                })

        except Exception as e:
            print(f"[SPARK] ERROR parsing row: {e}")
            continue

    spark = SparkSession.getActiveSession()

    # ── Write Admissions ──
    if admissions:
        try:
            write_to_postgres(
                spark.createDataFrame(admissions, schema=ADMISSION_SCHEMA),
                "Admissions"
            )
            print(f"[SPARK] ✓ wrote {len(admissions)} admissions")
        except Exception as e:
            print(f"[SPARK] ERROR writing admissions: {e}")

    # ── Write Diagnoses ──
    if diagnoses:
        try:
            write_to_postgres(
                spark.createDataFrame(diagnoses, schema=DIAGNOSIS_SCHEMA),
                "Diagnosis"
            )
            print(f"[SPARK] ✓ wrote {len(diagnoses)} diagnoses")
        except Exception as e:
            print(f"[SPARK] ERROR writing diagnoses: {e}")

    # ── Write Prescriptions ──
    if prescriptions:
        try:
            write_to_postgres(
                spark.createDataFrame(prescriptions, schema=PRESCRIPTION_SCHEMA),
                "Prescriptions"
            )
            print(f"[SPARK] ✓ wrote {len(prescriptions)} prescriptions")
        except Exception as e:
            print(f"[SPARK] ERROR writing prescriptions: {e}")

    # ── Write Transfers (only if came from 2nd doctor) ──
    if transfers:
        try:
            write_to_postgres(
                spark.createDataFrame(transfers, schema=TRANSFER_SCHEMA),
                "Transfers"
            )
            print(f"[SPARK] ✓ wrote {len(transfers)} transfers")
        except Exception as e:
            print(f"[SPARK] ERROR writing transfers: {e}")


# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    spark = SparkSession.builder \
        .appName("HospitalAdmissionsStream") \
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
        .option("subscribe", TOPIC_ADMISSIONS) \
        .option("startingOffsets", "earliest") \
        .option("maxOffsetsPerTrigger", 100) \
        .load() \
        .selectExpr("CAST(value AS STRING) as value")

    query = raw.writeStream \
        .foreachBatch(process_batch) \
        .trigger(processingTime=SPARK_TRIGGER_SECONDS) \
        .option("checkpointLocation", f"{SPARK_CHECKPOINT_DIR}/admissions") \
        .start()

    print(f"[SPARK] Admissions stream started — trigger={SPARK_TRIGGER_SECONDS}")
    query.awaitTermination()


if __name__ == "__main__":
    main()