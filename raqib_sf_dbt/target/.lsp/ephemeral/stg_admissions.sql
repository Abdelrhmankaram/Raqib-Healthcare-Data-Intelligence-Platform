__dbt__cte__stg_admissions as (
WITH raw_admissions AS (
    SELECT * 
    FROM raw.public.admissions
)

SELECT 
    admission_id,
    patient_id,
    admission_provider_id AS provider_id,
    stg_admissions.admitted_in_timestamp::date as admitted_date,
    stg_admissions.admitted_in_timestamp::time as admitted_time,
    stg_admissions.admitted_out_timestamp::date as discharged_date,  
    stg_admissions.admitted_out_timestamp::time as discharged_time,
    UPPER(LEFT(admission_type, 1)) || LOWER(SUBSTR(admission_type, 2)) AS admission_type,
    admission_location,
    discharge_location,
    INITCAP(insurance_type) AS insurance_type,
    total_cost,
    payer_coverage,
    hospital_expire_flag,
    primary_sdk

FROM raw_admissions
)