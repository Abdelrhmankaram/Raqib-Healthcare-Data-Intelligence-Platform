WITH raw_services AS (
    SELECT *
    FROM raw.public.services
)

SELECT 
    patient_id,
    admission_id,
    service_id,
    REGEXP_LIKE(service_id, '^SVC[0-9]+$') AS is_valid_service_id,
    CASE 
        WHEN CONTAINS(service_name, '–') 
        THEN TRIM(SPLIT_PART(service_name, '–', 1))
        WHEN CONTAINS(service_name, '(')
        THEN TRIM(SPLIT_PART(service_name, '(', 1))
        ELSE service_name 
    END AS service_name,

    CASE 
        WHEN CONTAINS(service_name, '–')
        THEN TRIM(SPLIT_PART(service_name, '–', 2))
        WHEN CONTAINS(service_name, '(')
        THEN TRIM(REPLACE(SPLIT_PART(service_name, '(', 2), ')', ''))
        ELSE NULL
    END AS service_sub_type,
    INITCAP(category) AS category,
    TRY_CAST(cost AS FLOAT) AS cost,
    duration AS service_duration_in_minutes
    
FROM raw_services