from cosmos import DbtDag, ProjectConfig, ProfileConfig, ExecutionConfig, RenderConfig
from cosmos.profiles import SnowflakeEncryptedPrivateKeyPemProfileMapping
from cosmos.constants import LoadMode
from datetime import datetime
from airflow.models import Variable

private_key = Variable.get("snowflake_private_key")

profile_config = ProfileConfig(
    profile_name="raqib_sf",
    target_name="dev",
    profile_mapping=SnowflakeEncryptedPrivateKeyPemProfileMapping(
        conn_id="Raqib_Snowflake",
        profile_args={
            "database": "DEV",
            "schema": "dbt_dev",
            "warehouse": "RAQIB_WH",
            "role": "RAQIB_ROLE",
            "private_key_passphrase": "q",
            "private_key": private_key
        }
    )
)

dbt_dag = DbtDag(
    dag_id="raqib_snowflake_pipeline",
    project_config=ProjectConfig(
        dbt_project_path="/usr/local/airflow/raqib_sf_dbt"  
    ),
    profile_config=profile_config,
    execution_config=ExecutionConfig(
        dbt_executable_path="/usr/local/bin/dbt"
    ),
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False
)