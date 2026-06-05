
  create or replace   view dev.dbt_dev_intermediate.int_medication_history
  
  
  
  
  as (
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
),  __dbt__cte__stg_drugs as (
with raw_drugs as (
    select * 
    from raw.public.drugs
)

select 
    drug_id,
    case 
        when brand_name is not null then initcap(brand_name)
        when brand_name is null and generic_name like 'Atropine Sulfate Injection%' then 'AtroPen'
        when brand_name is null and generic_name like 'Midazolam Injection%' then 'Versed'
    end as brand_name,
    case 
        when generic_name is not null then initcap(generic_name) 
        when generic_name is null then brand_name
    end as generic_name,
    initcap(route) as route,
    indications,
    dosage,
    contraindications,
    side_effects,
    warnings,
    has_contraindications,
    has_side_effects
    
from raw_drugs
where not (
    generic_name = 'Tadalafil'
    AND brand_name is null
)
),  __dbt__cte__stg_admissions as (
WITH raw_admissions AS (
    SELECT * 
    FROM raw.public.admissions
)

SELECT 
    admission_id,
    patient_id,
    admission_provider_id AS provider_id,
    CAST(admission_datetime_in AS TIMESTAMP) AS admitted_in_timestamp,
    CAST(admission_datetime_out AS TIMESTAMP) AS admitted_out_timestamp,
    UPPER(LEFT(admission_type, 1)) || LOWER(SUBSTR(admission_type, 2)) AS admission_type,
    admission_location,
    discharge_location,
    INITCAP(insurance_type) AS insurance_type,
    total_cost,
    payer_coverage,
    hospital_expire_flag,
    primary_sdk

FROM raw_admissions
), prescriptions AS (
    SELECT *
    FROM __dbt__cte__stg_prescriptions
),

drugs AS (
    SELECT *
    FROM __dbt__cte__stg_drugs
),

admissions AS (
    SELECT *
    FROM __dbt__cte__stg_admissions
)

SELECT
    p.prescription_id,
    p.patient_id,
    p.admission_id,
    p.provider_id,
    p.drug_id,

    p.prescribed_date,
    p.status AS prescription_status,

    -- =====================================
    -- DRUG DETAILS
    -- =====================================
    d.brand_name,
    d.generic_name,
    d.route,
    d.dosage,
    d.indications,

    d.has_contraindications,
    d.contraindications,

    d.has_side_effects,
    d.side_effects,

    d.warnings,

    -- =====================================
    -- ENCOUNTER CONTEXT
    -- =====================================
    a.admitted_in_timestamp,
    a.admitted_out_timestamp,
    a.admission_type,

    -- =====================================
    -- INPATIENT / OUTPATIENT
    -- =====================================
    CASE
        WHEN p.admission_id IS NOT NULL
        THEN TRUE
        ELSE FALSE
    END AS is_inpatient_prescription,

    -- =====================================
    -- MEDICATION RISK
    -- =====================================
    CASE
        WHEN d.has_contraindications
            AND d.has_side_effects
        THEN 'HIGH'

        WHEN d.has_contraindications
            OR d.has_side_effects
        THEN 'MEDIUM'

        ELSE 'LOW'
    END AS medication_risk_level,

    -- =====================================
    -- HUMAN-READABLE SUMMARY
    -- Useful for RAG
    -- =====================================
    CONCAT(
        COALESCE(d.generic_name, d.brand_name),
        ' prescribed ',
        COALESCE(d.dosage, ''),
        CASE
            WHEN d.route IS NOT NULL
            THEN CONCAT(' via ', LOWER(d.route))
            ELSE ''
        END
    ) AS medication_summary

FROM prescriptions p

LEFT JOIN drugs d
    ON p.drug_id = d.drug_id

LEFT JOIN admissions a
    ON p.admission_id = a.admission_id
  );

