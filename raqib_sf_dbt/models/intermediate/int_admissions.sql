WITH stg_admissions AS (
    SELECT * 
    FROM {{ ref('stg_admissions') }}
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['admission_id']) }} AS admission_key,
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