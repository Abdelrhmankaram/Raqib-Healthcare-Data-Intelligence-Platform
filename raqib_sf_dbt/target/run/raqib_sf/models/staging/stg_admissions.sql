
  create or replace   view dev.dbt_dev_staging.stg_admissions
  
  
  
  
  as (
    WITH raw_admissions AS (
    SELECT * 
    FROM raw.public.admissions
)

SELECT 
    admission_id,
    patient_id,
    admission_provider_id                                       AS provider_id,
    CAST(ADMISSION_DATETIME_IN AS TIMESTAMP)                    AS admitted_at,
    CAST(ADMISSION_DATETIME_OUT AS TIMESTAMP)                   AS discharged_at,
    UPPER(LEFT(admission_type, 1)) 
        || LOWER(SUBSTR(admission_type, 2))                     AS admission_type,
    admission_location,
    discharge_location,
    INITCAP(insurance_type)                                     AS insurance_type,
    total_cost,
    payer_coverage,
    hospital_expire_flag,
    primary_sdk
FROM raw_admissions
  );

