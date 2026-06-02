WITH  __dbt__cte__stg_providers as (
WITH raw_providers AS (
    SELECT * 
    FROM raw.public.providers
)

SELECT 
    npi AS provider_id,
    INITCAP(provider_first_name) AS provider_first_name,
    INITCAP(provider_last_name) AS provider_last_name,
    INITCAP(provider_name_prefix) AS provider_name_prefix,
    REGEXP_LIKE(provider_name_prefix, '\\.$') AS is_valid_prefix,
    INITCAP(provider_address) AS provider_address,
    INITCAP(provider_city) AS provider_city,
    TRIM(provider_state_code) AS provider_state_code,
    TRIM(provider_country_code) AS provider_country_code,
    provider_postal_code,
    CASE 
        WHEN provider_sex_code = 'M' OR provider_sex_code = 'm' THEN 'Male'
        WHEN provider_sex_code = 'F' OR provider_sex_code = 'f' THEN 'Female'
        ELSE 'Unknown'
    END AS provider_sex,
    provider_telephone_number,
    CAST(provider_enumeration_date AS DATE) AS provider_enumeration_date,
    CASE 
        WHEN CAST(provider_enumeration_date AS DATE) IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS is_valid_enumeration_date,
    CAST(provider_join_date AS DATE) AS provider_join_date,
    CASE 
        WHEN DATE(provider_join_date, 'YYYY-MM-DD') IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS is_valid_join_date,
    provider_specialty

FROM raw_providers
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
    CONVERT_TIMEZONE('UTC', done_datetime::TIMESTAMP_TZ)    AS lab_done_at,
    CONVERT_TIMEZONE('UTC', stored_datetime::TIMESTAMP_TZ)  AS lab_stored_at,
    TRY_CAST(value AS FLOAT) AS result_value,
    TRIM(measurement_unit) AS measurement_unit,
    TRY_CAST(range_lower AS FLOAT) AS range_lower,
    TRY_CAST(range_higher AS FLOAT) AS range_higher,
    TRIM(abnormal_flag) AS abnormal_flag,
    TRY_CAST(cost AS FLOAT) AS cost

FROM raw_lab_events
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
    prescribed_date,
    INITCAP(status) AS status
FROM raw_prescriptions
), providers AS (
    SELECT *
    FROM __dbt__cte__stg_providers
),

admissions AS (
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

-- =========================
-- ENCOUNTER METRICS
-- =========================
encounter_metrics AS (
    SELECT
        provider_id,

        COUNT(DISTINCT admission_id) AS total_encounters,
        COUNT(DISTINCT patient_id) AS unique_patients,

        AVG(total_cost) AS avg_encounter_cost,

        SUM(
            CASE 
                WHEN hospital_expire_flag = 1 THEN 1
                ELSE 0
            END
        ) * 1.0 / NULLIF(COUNT(*), 0) AS mortality_rate

    FROM admissions
    GROUP BY provider_id
),

-- =========================
-- DIAGNOSIS METRICS
-- =========================
diagnosis_metrics AS (
    SELECT
        provider_id,
        COUNT(*) AS total_diagnoses
    FROM diagnosis
    GROUP BY provider_id
),

-- =========================
-- LAB METRICS
-- =========================
lab_metrics AS (
    SELECT
        provider_id,
        COUNT(*) AS total_lab_orders
    FROM lab_events
    GROUP BY provider_id
),

-- =========================
-- PRESCRIPTION METRICS
-- =========================
prescription_metrics AS (
    SELECT
        provider_id,
        COUNT(*) AS total_prescriptions
    FROM prescriptions
    GROUP BY provider_id
)

-- =========================
-- FINAL MODEL
-- =========================
SELECT
    p.provider_id,

    p.provider_first_name,
    p.provider_last_name,
    p.provider_specialty,
    p.provider_city,
    p.provider_state_code,

    -- =====================
    -- CORE ACTIVITY
    -- =====================
    COALESCE(em.total_encounters, 0) AS total_encounters,
    COALESCE(em.unique_patients, 0) AS unique_patients,
    COALESCE(dm.total_diagnoses, 0) AS total_diagnoses,
    COALESCE(lm.total_lab_orders, 0) AS total_lab_orders,
    COALESCE(pm.total_prescriptions, 0) AS total_prescriptions,

    -- =====================
    -- PERFORMANCE METRICS
    -- =====================

    COALESCE(em.mortality_rate, 0) AS mortality_rate

FROM providers p

LEFT JOIN encounter_metrics em
    ON p.provider_id = em.provider_id

LEFT JOIN diagnosis_metrics dm
    ON p.provider_id = dm.provider_id

LEFT JOIN lab_metrics lm
    ON p.provider_id = lm.provider_id

LEFT JOIN prescription_metrics pm
    ON p.provider_id = pm.provider_id