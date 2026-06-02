"""Snowflake database interactions for patient data queries."""
import streamlit as st

try:
    from snowflake.connector import connect
    SNOWFLAKE_AVAILABLE = True
except ImportError:
    SNOWFLAKE_AVAILABLE = False
    connect = None

from constants import SNOWFLAKE_CONFIG


def get_snowflake_connection():
    """Create and return a Snowflake connection."""
    if not SNOWFLAKE_AVAILABLE:
        st.error("Snowflake connector not available")
        return None
    
    try:
        conn = connect(
            account=SNOWFLAKE_CONFIG["account"],
            user=SNOWFLAKE_CONFIG["user"],
            password=SNOWFLAKE_CONFIG["password"],
            warehouse=SNOWFLAKE_CONFIG["warehouse"],
            database=SNOWFLAKE_CONFIG["database"],
            schema=SNOWFLAKE_CONFIG["schema"],
        )
        return conn
    except Exception as e:
        st.error(f"Snowflake connection error: {e}")
        return None


def query_patient_data(patient_id: str) -> dict | None:
    """Query patient data from Snowflake by patient ID."""
    conn = get_snowflake_connection()
    if not conn:
        return None

    try:
        cursor = conn.cursor()
        # Adjust the query to match your Snowflake schema
        query = f"""
        SELECT *
        FROM patients
        WHERE patient_id = '{patient_id}'
        LIMIT 1
        """
        cursor.execute(query)
        result = cursor.fetchone()
        
        if result:
            # Get column names before closing connection
            columns = [desc[0] for desc in cursor.description]
            cursor.close()
            conn.close()
            return dict(zip(columns, result))
        
        cursor.close()
        conn.close()
        return None
    except Exception as e:
        st.error(f"Query error: {e}")
        return None


def search_patients(search_term: str, field: str = "patient_name") -> list[dict]:
    """Search for patients by name or other field."""
    conn = get_snowflake_connection()
    if not conn:
        return []

    try:
        cursor = conn.cursor()
        query = f"""
        SELECT patient_id, patient_name, date_of_birth
        FROM patients
        WHERE {field} ILIKE '%{search_term}%'
        LIMIT 20
        """
        cursor.execute(query)
        results = cursor.fetchall()
        
        if results:
            # Get column names before closing connection
            columns = [desc[0] for desc in cursor.description]
            cursor.close()
            conn.close()
            return [dict(zip(columns, row)) for row in results]
        
        cursor.close()
        conn.close()
        return []
    except Exception as e:
        st.error(f"Search error: {e}")
        return []
