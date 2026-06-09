from snowflake.connector import connect
from constants import SNOWFLAKE_CONFIG

# Extract account identifier from full hostname if needed
server_url = SNOWFLAKE_CONFIG["server_url"]
if ".snowflakecomputing.com" in server_url:
    account = server_url.split(".snowflakecomputing.com")[0]
else:
    account = server_url

conn = connect(
            account=account,
            user=SNOWFLAKE_CONFIG["username"],
            password=SNOWFLAKE_CONFIG["password"],
            warehouse=SNOWFLAKE_CONFIG["warehouse"],
            database=SNOWFLAKE_CONFIG["database"],
            schema=SNOWFLAKE_CONFIG["schema"],
        )

cursor = conn.cursor()
        # Adjust the query to match your Snowflake schema
query = f"""
SELECT *
FROM PROD.DBT_DEV_MARTS.DIM_PATIENTS
WHERE patient_key = '59e711d152de7bec7304a8c2ecaf9f0f'
LIMIT 1
"""
cursor.execute(query)
result = cursor.fetchone()

print(result)