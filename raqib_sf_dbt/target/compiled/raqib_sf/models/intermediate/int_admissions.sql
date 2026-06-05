WITH stg_admissions AS (
    SELECT * 
    FROM dev.dbt_dev_staging.stg_admissions
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
    DATEDIFF(
        'hour',
        admitted_in_timestamp,
        admitted_out_timestamp
    ) AS stay_duation_hours,
    admission_location,
    discharge_location,
    insurance_type,
    total_cost,
    payer_coverage,
    total_cost - payer_coverage AS patient_out_of_pocket_cost,
    hospital_expire_flag


FROM stg_admissions