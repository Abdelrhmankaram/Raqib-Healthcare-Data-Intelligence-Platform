from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import pandas as pd
import boto3
import psycopg2
import os
from dotenv import load_dotenv

load_dotenv()

def export_table_to_s3(table_name):
    # Connect to PostgreSQL
    conn = psycopg2.connect(
        host="dwh",
        port=5432,
        dbname=os.environ.get("DATABASE_DB_NAME_DESTINATION"),
        user=os.environ.get("DATABASE_USER_DESTINATION"),
        password=os.environ.get("DATABASE_PASSWORD_DESTINATION")
    )

    # Read yesterday's data
    yesterday = datetime.now() - timedelta(days=1)
    date_str = yesterday.strftime("%Y-%m-%d")

    df = pd.read_sql(
        f"SELECT * FROM {table_name} WHERE created_at::date = '{date_str}'",
        conn
    )
    conn.close()

    if df.empty:
        print(f"No data for {table_name} on {date_str}")
        return

    # Write to Parquet locally
    local_path = f"/tmp/{table_name}_{date_str}.parquet"
    df.to_parquet(local_path, index=False)

    # Upload to S3
    s3 = boto3.client("s3")
    s3_key = f"hospital/{table_name}/date={date_str}/{table_name}.parquet"
    s3.upload_file(local_path, os.environ.get("S3_BUCKET_NAME"), s3_key)
    print(f"Uploaded {table_name} to s3://{os.environ.get('S3_BUCKET_NAME')}/{s3_key}")

with DAG(
    dag_id="hospital_postgres_to_s3",
    start_date=datetime(2024, 1, 1),
    schedule_interval="@daily",
    catchup=False,
    default_args={"retries": 2, "retry_delay": timedelta(minutes=5)}
) as dag:

    export_admissions = PythonOperator(
        task_id="export_admissions",
        python_callable=export_table_to_s3,
        op_args=["admissions"]
    )

    export_diagnosis = PythonOperator(
        task_id="export_diagnosis",
        python_callable=export_table_to_s3,
        op_args=["diagnosis"]
    )

    export_admissions >> export_diagnosis