WITH raw_admissions AS (
    SELECT * 
    FROM raw.public.admissions
)

SELECT 
    admission_id,
    patient_id,
    admission_provider_id AS provider_id,
    TRY_CAST(raw_admissions.ADMISSION_DATETIME_IN AS DATE) as admitted_date,
    TRY_CAST(raw_admissions.ADMISSION_DATETIME_IN AS TIME) as admitted_time,
    TRY_CAST(raw_admissions.ADMISSION_DATETIME_out AS DATE) as discharged_date,  
    TRY_CAST(raw_admissions.ADMISSION_DATETIME_out AS TIME) as discharged_time,
    UPPER(LEFT(admission_type, 1)) || LOWER(SUBSTR(admission_type, 2)) AS admission_type,
    admission_location,
    discharge_location,
    INITCAP(insurance_type) AS insurance_type,
    total_cost,
    payer_coverage,
    hospital_expire_flag,
    primary_sdk

FROM raw_admissions