WITH prescriptions AS (
    SELECT *
    FROM {{ ref('stg_prescriptions') }}
),

drugs AS (
    SELECT *
    FROM {{ ref('stg_drugs') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['prescription_id']) }}  AS prescription_key,
    p.prescription_id,
    p.patient_id,
    p.admission_id,
    p.provider_id,
    p.drug_id,
    d.brand_name AS drug_name,
    p.prescribed_date                                            AS prescription_date,
    p.status
FROM prescriptions p
LEFT JOIN drugs d ON p.drug_id = d.drug_id