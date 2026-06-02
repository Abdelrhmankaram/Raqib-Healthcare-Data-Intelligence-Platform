WITH  __dbt__cte__stg_prescriptions as (
WITH raw_prescriptions AS (
    SELECT *
    FROM raw.public.prescriptions 
)
SELECT 
    prescription_id,
    patient_id,
    admission_id,
    provider_id,
    drug_id,
    prescribed_date,
    INITCAP(status) AS status
FROM raw_prescriptions
), stg_prescriptions AS (
    SELECT *
    FROM __dbt__cte__stg_prescriptions
)

SELECT *
FROM stg_prescriptions