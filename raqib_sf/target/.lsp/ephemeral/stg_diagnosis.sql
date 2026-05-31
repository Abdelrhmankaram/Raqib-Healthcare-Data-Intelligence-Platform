__dbt__cte__stg_diagnosis as (
with raw_diagnosis as (
    select * 
    from raw.public.diagnosis
)

select 
    diagnosis_id,
    patient_id,
    admission_id,
    provider_id,
    admission_id,
    provider_id,
    TRIM(REGEXP_REPLACE(description, '\\s*\\([^)]+\\)', '')) as description,
    REGEXP_SUBSTR(description, '\\(([^)]+)\\)', 1, 1, 'e', 1) AS description_type,
    TRIM(SPLIT_PART(REGEXP_REPLACE(specialty, '\\s*/\\s*', ' & '), ' & ', 1)) AS specialty_1,
    NULLIF(TRIM(SPLIT_PART(REGEXP_REPLACE(specialty, '\\s*/\\s*', ' & '), ' & ', 2)), '') AS specialty_2,
    TRIM(SPLIT_PART(REGEXP_REPLACE(SPLIT_PART(sub_domain, ' – ', 2), '\\s*/\\s*', ' & '), ' & ', 1)) AS sub_domain_1,
    NULLIF(TRIM(SPLIT_PART(REGEXP_REPLACE(SPLIT_PART(sub_domain, ' – ', 2), '\\s*/\\s*', ' & '), ' & ', 2)), '') AS sub_domain_2,
    sub_domain_key
from raw_diagnosis
)