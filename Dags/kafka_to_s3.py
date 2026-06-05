from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta
import pandas as pd
import boto3
import psycopg2
import snowflake.connector
import os
from dotenv import load_dotenv
from sqlalchemy import create_engine

load_dotenv()

def export_table_to_s3(table_name):
    engine = create_engine(
        "postgresql+psycopg2://kafka_admin:kafka_admin_password@dwh:5432/postgres"
    )
    today = datetime.now().strftime("%Y-%m-%d")
    
    df = pd.read_sql(
        f"SELECT * FROM {table_name} WHERE created_at::date = '{today}'",
        engine
    )
    
    if df.empty:
        print(f"No data for {table_name} on {today}")
        return
    
    local_path = f"/tmp/{table_name}_{today}.parquet"
    df.to_parquet(local_path, index=False)
    
    s3 = boto3.client(
        "s3",
        region_name="eu-west-3"
    )
    s3_key = f"hospital/{table_name}/date={today}/{table_name}.parquet"
    s3.upload_file(local_path, "raqib-streaming-pipeline-raw-bucket", s3_key)
    print(f"Uploaded to s3://raqib-streaming-pipeline-raw-bucket/{s3_key}")


def load_s3_to_snowflake(table_name):
    today = datetime.now().strftime("%Y-%m-%d")
    s3_path = f"s3://raqib-streaming-pipeline-raw-bucket/hospital/{table_name}/date={today}/"
    
    aws_key = os.getenv("AWS_ACCESS_KEY_ID")
    aws_secret = os.getenv("AWS_SECRET_ACCESS_KEY")
    
    conn = snowflake.connector.connect(
        user=os.getenv("SNOWFLAKE_USER"),
        password=os.getenv("SNOWFLAKE_PASSWORD"),
        account=os.getenv("SNOWFLAKE_ACCOUNT"),
        warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
        database=os.getenv("SNOWFLAKE_DATABASE"),
        schema=os.getenv("SNOWFLAKE_SCHEMA")
    )
    conn.cursor().execute(f"""
        COPY INTO {table_name.upper()}
        FROM '{s3_path}'
        CREDENTIALS = (AWS_KEY_ID='{aws_key}' AWS_SECRET_KEY='{aws_secret}')
        FILE_FORMAT = (TYPE=PARQUET)
        MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
        ON_ERROR = CONTINUE;
    """)
    conn.close()

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
    export_lab_events = PythonOperator(
        task_id="export_lab_events",
        python_callable=export_table_to_s3,
        op_args=["lab_events"]
    )
    export_patients = PythonOperator(
        task_id="export_patients",
        python_callable=export_table_to_s3,
        op_args=["patients"]
    )
    export_prescriptions = PythonOperator(
        task_id="export_prescriptions",
        python_callable=export_table_to_s3,
        op_args=["prescriptions"]
    )
    export_transfers = PythonOperator(
        task_id="export_transfers",
        python_callable=export_table_to_s3,
        op_args=["transfers"]
    )
    load_admissions_snowflake = PythonOperator(
        task_id="load_admissions_snowflake",
        python_callable=load_s3_to_snowflake,
        op_args=["admissions"]
    )
    load_diagnosis_snowflake = PythonOperator(
        task_id="load_diagnosis_snowflake",
        python_callable=load_s3_to_snowflake,
        op_args=["diagnosis"]
    )
    load_lab_events_snowflake = PythonOperator(
        task_id="load_lab_events_snowflake",
        python_callable=load_s3_to_snowflake,
        op_args=["lab_events"]
    )
    load_patients_snowflake = PythonOperator(
        task_id="load_patients_snowflake",
        python_callable=load_s3_to_snowflake,
        op_args=["patients"]
    )
    load_prescriptions_snowflake = PythonOperator(
        task_id="load_prescriptions_snowflake",
        python_callable=load_s3_to_snowflake,
        op_args=["prescriptions"]
    )
    load_transfers_snowflake = PythonOperator(
        task_id="load_transfers_snowflake",
        python_callable=load_s3_to_snowflake,
        op_args=["transfers"]
    )

    export_admissions >> load_admissions_snowflake
    export_diagnosis >> load_diagnosis_snowflake
    export_lab_events >> load_lab_events_snowflake
    export_patients >> load_patients_snowflake 
    export_prescriptions >> load_prescriptions_snowflake
    export_transfers >> load_transfers_snowflake