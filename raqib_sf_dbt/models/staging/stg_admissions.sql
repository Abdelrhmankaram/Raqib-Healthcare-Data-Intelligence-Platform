WITH raw_admissions AS (
    SELECT * 
    FROM {{ source('raw', 'raw_admissions') }}
)

SELECT 
    admission_id,
    patient_id,
    provider_id,
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



-- SELECT 
--     admission_id,
--     patient_id,
--     admission_provider_id AS provider_id,
--     primary_sdk AS primary_sub_domain_key,
--     TRY_CAST(admission_datetime_in AS TIMESTAMP) AS admitted_in_timestamp,
--     TRY_CAST(admission_datetime_out AS TIMESTAMP) AS admitted_out_timestamp,
--     upper(LEFT(admission_type, 1)) || LOWER(SUBSTR(admission_type, 2)) AS admission_type,
--     admission_location,
--     discharge_location,
--     INITCAP(insurance_type) AS insurance_type,
--     TRY_CAST(total_cost AS FLOAT) AS total_cost,
--     TRY_CAST(payer_coverage AS FLOAT) AS payer_coverage,
--     hospital_expire_flag

-- FROM RAW.PUBLIC.ADMISSIONS


