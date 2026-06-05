from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

DBT_PROJECT_DIR = "/usr/local/airflow/raqib_sf_dbt"
DBT_PROFILES_DIR = "/usr/local/airflow/raqib_sf_dbt"

with DAG(
    dag_id="raqib_snowflake_pipeline",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
) as dag:

    dbt_debug = BashOperator(
        task_id="dbt_debug",
        bash_command=f"""
        cd {DBT_PROJECT_DIR} && 
        dbt debug --profiles-dir {DBT_PROFILES_DIR} || true
        """
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"""
        cd {DBT_PROJECT_DIR}
        dbt run --profiles-dir {DBT_PROFILES_DIR}
        """
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"""
        cd {DBT_PROJECT_DIR}
        dbt test --profiles-dir {DBT_PROFILES_DIR}
        """
    )

    dbt_debug >> dbt_run >> dbt_test