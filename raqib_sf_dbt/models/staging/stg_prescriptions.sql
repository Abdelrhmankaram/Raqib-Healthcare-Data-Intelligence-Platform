WITH raw_prescriptions AS (
    SELECT *
    FROM {{ source('raw', 'raw_prescriptions') }} 
)
SELECT 
    prescription_id,
    patient_id,
    admission_id,
    provider_id,
    drug_id,
    CAST(prescribed_date AS TIMESTAMP) AS prescribed_date,
    INITCAP(status) AS status
FROM raw_prescriptions

