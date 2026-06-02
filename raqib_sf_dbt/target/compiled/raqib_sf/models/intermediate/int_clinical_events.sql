WITH  __dbt__cte__stg_admissions as (
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
),  __dbt__cte__stg_diagnosis as (
WITH raw_diagnosis AS (
    SELECT * 
    FROM raw.public.diagnosis
)

SELECT 
    diagnosis_id,
    patient_id,
    admission_id,
    provider_id,
    sub_domain_key,
    TRIM(REGEXP_REPLACE(description, '\\s*\\([^)]+\\)', '')) AS description,
    REGEXP_SUBSTR(description, '\\(([^)]+)\\)', 1, 1, 'e', 1) AS description_type,
    TRIM(SPLIT_PART(REGEXP_REPLACE(SPLIT_PART(sub_domain, ' – ', 2), '\\s*/\\s*', ' & '), ' & ', 1)) AS sub_domain_1,
    NULLIF(TRIM(SPLIT_PART(REGEXP_REPLACE(SPLIT_PART(sub_domain, ' – ', 2), '\\s*/\\s*', ' & '), ' & ', 2)), '') AS sub_domain_2
FROM raw_diagnosis
),  __dbt__cte__stg_lab_events as (
WITH raw_lab_events AS (

    SELECT *
    FROM raw.public.lab_events

)

SELECT
    lab_event_id,
    patient_id,
    admission_id,
    specimen_id,
    item_id,
    provider_id,
    CAST(done_datetime AS TIMESTAMP)    AS lab_done_at,
    CAST(stored_datetime AS TIMESTAMP)  AS lab_stored_at,
    TRY_CAST(value AS FLOAT) AS result_value,
    TRIM(measurement_unit) AS measurement_unit,
    TRY_CAST(range_lower AS FLOAT) AS range_lower,
    TRY_CAST(range_higher AS FLOAT) AS range_higher,
    TRIM(abnormal_flag) AS abnormal_flag,
    TRY_CAST(cost AS FLOAT) AS cost

FROM raw_lab_events 

--  CONVERT_TIMEZONE('UTC', done_datetime::TIMESTAMP_TZ)    AS lab_done_at,
--     CONVERT_TIMEZONE('UTC', stored_datetime::TIMESTAMP_TZ)  AS lab_stored_at,
),  __dbt__cte__stg_prescriptions as (
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
),  __dbt__cte__stg_services as (
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
),  __dbt__cte__stg_transfers as (
WITH raw_transfers AS (
    SELECT *
    FROM raw.public.transfers
)

SELECT 
    transfer_id,
    patient_id,
    from_department,
    to_department,
    (from_department = to_department) AS is_same_department_transfer,
    CAST(transfer_datetime AS TIMESTAMP) AS transfer_datetime,
    transfer_reason
    
FROM raw_transfers
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
), admissions AS (
    SELECT *
    FROM __dbt__cte__stg_admissions
),

diagnosis AS (
    SELECT *
    FROM __dbt__cte__stg_diagnosis
),

lab_events AS (
    SELECT *
    FROM __dbt__cte__stg_lab_events
),

prescriptions AS (
    SELECT *
    FROM __dbt__cte__stg_prescriptions
),

services AS (
    SELECT *
    FROM __dbt__cte__stg_services
),

transfers AS (
    SELECT *
    FROM __dbt__cte__stg_transfers
),

drugs AS (
    SELECT *
    FROM __dbt__cte__stg_drugs
),

-- =====================
-- DIAGNOSIS EVENTS
-- =====================

diagnosis_events AS (

    SELECT
        d.patient_id,
        d.admission_id,
        d.provider_id,

        a.admitted_in_timestamp AS event_timestamp,

        'DIAGNOSIS' AS event_type,

        d.description AS event_detail,

        COALESCE(
            d.sub_domain_1,
            d.sub_domain_2,
            'General'
        ) AS category,

        NULL AS numeric_value,
        NULL AS unit,

        NULL AS status_flag

    FROM diagnosis d

    LEFT JOIN admissions a
        ON d.admission_id = a.admission_id
),

-- =====================
-- LAB EVENTS
-- =====================

lab_timeline AS (

    SELECT
        patient_id,
        admission_id,
        provider_id,

        lab_done_at AS event_timestamp,

        'LAB' AS event_type,

        CONCAT(
            'Lab result: ',
            item_id
        ) AS event_detail,

        item_id AS category,

        result_value AS numeric_value,

        measurement_unit AS unit,

        abnormal_flag AS status_flag

    FROM lab_events
),

-- =====================
-- PRESCRIPTION EVENTS
-- =====================

prescription_events AS (

    SELECT
        p.patient_id,
        p.admission_id,
        p.provider_id,

        p.prescribed_date AS event_timestamp,

        'PRESCRIPTION' AS event_type,

        COALESCE(
            d.generic_name,
            d.brand_name
        ) AS event_detail,

        d.route AS category,

        NULL AS numeric_value,
        NULL AS unit,

        p.status AS status_flag

    FROM prescriptions p

    LEFT JOIN drugs d
        ON p.drug_id = d.drug_id
),

-- =====================
-- SERVICE EVENTS
-- =====================

service_events AS (

    SELECT
        s.patient_id,
        s.admission_id,

        NULL AS provider_id,

        a.admitted_in_timestamp AS event_timestamp,

        'SERVICE' AS event_type,

        s.service_name AS event_detail,

        s.category AS category,

        s.cost AS numeric_value,

        'USD' AS unit,

        NULL AS status_flag

    FROM services s

    LEFT JOIN admissions a
        ON s.admission_id = a.admission_id
),

-- =====================
-- TRANSFER EVENTS
-- =====================

transfer_events AS (

    SELECT
        patient_id,
        NULL AS admission_id,
        NULL AS provider_id,

        transfer_datetime AS event_timestamp,

        'TRANSFER' AS event_type,

        CONCAT(
            from_department,
            ' → ',
            to_department
        ) AS event_detail,

        transfer_reason AS category,

        NULL AS numeric_value,
        NULL AS unit,

        CASE
            WHEN is_same_department_transfer
                THEN 'SAME_DEPARTMENT'
            ELSE 'DEPARTMENT_CHANGE'
        END AS status_flag

    FROM transfers
)

SELECT * FROM diagnosis_events

UNION ALL

SELECT * FROM lab_timeline

UNION ALL

SELECT * FROM prescription_events

UNION ALL

SELECT * FROM service_events

UNION ALL

SELECT * FROM transfer_events