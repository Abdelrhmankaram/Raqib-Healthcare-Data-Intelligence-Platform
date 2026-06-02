WITH raw_diagnosis AS (
    SELECT * 
    FROM {{ source('raw', 'raw_diagnosis') }}
)

SELECT 
    diagnosis_id,
    patient_id,
    admission_id,
    provider_id,
    sub_domain_key,
    TRIM(REGEXP_REPLACE(description, '\\s*\\([^)]+\\)', '')) AS description,
    REGEXP_SUBSTR(description, '\\(([^)]+)\\)', 1, 1, 'e', 1) AS description_type,
    TRIM(SPLIT_PART(REGEXP_REPLACE(SPLIT_PART(sub_domain, ' – ', 2), '\\s*/\\s*', ' & '), ' & ', 1)) AS domain,
    NULLIF(TRIM(SPLIT_PART(REGEXP_REPLACE(SPLIT_PART(sub_domain, ' – ', 2), '\\s*/\\s*', ' & '), ' & ', 2)), '') AS sub_domain
FROM raw_diagnosis

