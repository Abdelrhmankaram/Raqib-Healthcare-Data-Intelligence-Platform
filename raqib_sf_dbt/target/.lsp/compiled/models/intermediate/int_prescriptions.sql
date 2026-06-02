with __dbt__cte__stg_prescriptions as (
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
    CAST(prescribed_date AS TIMESTAMP) AS prescribed_date,
    INITCAP(status) AS status
FROM raw_prescriptions

), __dbt__cte__stg_drugs as (
with raw_drugs as (
    select * 
    from raw.public.drugs
)

select 
    drug_id,
    case 
        when brand_name is not null then initcap(brand_name)
        when brand_name is null and generic_name ilike 'Atropine Sulfate Injection%' then 'AtroPen'
        when brand_name is null and generic_name ilike 'Midazolam Injection%' then 'Versed'
        when brand_name is null and generic_name = 'Tadalafil' then 'Cialis'
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
)
--EPHEMERAL-SELECT-WRAPPER-START
select * from (
WITH prescriptions AS (
    SELECT *
    FROM __dbt__cte__stg_prescriptions
),

drugs AS (
    SELECT *
    FROM __dbt__cte__stg_drugs
)

SELECT
    md5(cast(coalesce(cast(p.prescription_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT))  AS prescription_key,
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
--EPHEMERAL-SELECT-WRAPPER-END
)