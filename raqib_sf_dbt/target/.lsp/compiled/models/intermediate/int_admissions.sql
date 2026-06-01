with __dbt__cte__stg_admissions as (
WITH raw_admissions AS (
    SELECT * 
    FROM raw.public.admissions
)

SELECT 
    admission_id,
    patient_id,
    TRY_CAST(admission_datetime_in AS TIMESTAMP) AS admitted_in_timestamp,
    TRY_CAST(admission_datetime_out AS TIMESTAMP) AS admitted_out_timestamp,
    upper(LEFT(admission_type, 1)) || LOWER(SUBSTR(admission_type, 2)) AS admission_type,
    admission_provider_id AS provider_id,
    admission_location,
    discharge_location,
    INITCAP(insurance_type) AS insurance_type,
    total_cost,
    payer_coverage,
    hospital_expire_flag

FROM raw_admissions
)
--EPHEMERAL-SELECT-WRAPPER-START
select * from (
WITH stg_admissions AS (
    SELECT * 
    FROM __dbt__cte__stg_admissions
)

SELECT 
    admission_id,
    patient_id,
    provider_id,
    admitted_in_timestamp,
    admitted_out_timestamp,
    DATEDIFF(
        'day',
        admitted_in_timestamp,
        admitted_out_timestamp
    ) AS stay_duration_days,
    admission_type,
    DATEDIFF(
        'hour',
        admitted_in_timestamp,
        admitted_out_timestamp
    ) AS stay_duration_hours,
    admission_location,
    discharge_location,
    insurance_type,
    total_cost,
    payer_coverage,
    total_cost - payer_coverage AS patient_out_of_pocket_cost,
    hospital_expire_flag


FROM stg_admissions
--EPHEMERAL-SELECT-WRAPPER-END
)