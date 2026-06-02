WITH raw_prescriptions AS (
    SELECT *
    FROM raw.public.prescriptions 

SELECT 
    prescription_id,
    patient_id,
    admission_id,
    provider_id,
    drug_id,
    prescribed_date,
    INITCAP(status) AS status
FROM raw_prescriptions