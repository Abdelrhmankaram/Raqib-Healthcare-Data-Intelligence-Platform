
  create or replace   view dev.dbt_dev_intermediate.int_patients_360
  
  
  
  
  as (
    WITH  __dbt__cte__stg_patients as (
WITH raw_patients AS (
    SELECT *
    FROM raw.public.patients
)

SELECT 
    patient_id,
    ssn,
    INITCAP(first_name || ' ' || last_name) AS full_name,
    birthdate::DATE AS birthdate,
    YEAR(birthdate::DATE) AS birth_year,
    deathdate::DATE AS deathdate,
    CASE 
        WHEN deathdate IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS is_dead,
    blood_type,
    CASE 
        WHEN marital = 'S' THEN 'Single'
        WHEN marital = 'M' THEN 'Married'
        WHEN marital = 'D' THEN 'Divorced'
        WHEN marital = 'W' THEN 'Widowed'
    END AS marital_status,
    INITCAP(REPLACE(race, '/', ' / ')) AS race,
    CASE
        WHEN UPPER(TRIM(ethnicity)) IN ('HISPANIC', 'HISPANIC OR LATINO')
            THEN 'Hispanic or Latino'
        WHEN UPPER(TRIM(ethnicity)) IN ('NONHISPANIC', 'NOT HISPANIC OR LATINO')
            THEN 'Not Hispanic or Latino'
        ELSE 'Unknown'
    END AS ethnicity,
    CASE 
        WHEN gender = 'F' THEN 'Female'
        WHEN gender = 'M' THEN 'Male'
        ELSE 'Unknown'
    END AS gender,
    INITCAP(language) AS spoken_language,
    INITCAP(TRIM(SPLIT_PART(birthplace, ',', 1))) AS birth_city,
    CASE UPPER(TRIM(SPLIT_PART(birthplace, ',',2)))
    WHEN 'CT' THEN 'Connecticut'
    WHEN 'ME' THEN 'Maine'
    WHEN 'MA' THEN 'Massachusetts'
    WHEN 'NH' THEN 'New Hampshire'
    WHEN 'RI' THEN 'Rhode Island'
    WHEN 'VT' THEN 'Vermont'
    WHEN 'NY' THEN 'New York'
    END AS birth_state,
    address,
    INITCAP(city) AS city,
    CASE UPPER(TRIM(country))
        WHEN 'US' THEN 'United States'
        WHEN 'UK' THEN 'United Kingdom' 
    END AS country,
    CAST(healthcare_expenses AS FLOAT) AS healthcare_expenses,
    CAST(healthcare_coverage AS FLOAT) AS healthcare_coverage,
    income AS income_usd
  
FROM raw_patients
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
),  __dbt__cte__stg_emergency_contacts as (
WITH raw_emergency_contacts AS (
    SELECT *
    FROM raw.public.emergency_contacts
)

SELECT
    Patient_ID AS patient_id,
    INITCAP(emergency_contact_name) AS emergency_contact_name,
    emergency_contact_relationship,
    emergency_contact_bloodtype,
    emergency_contact_number AS emergency_contact_phone_number,
    REGEXP_LIKE(emergency_contact_number, '^\\([0-9]{3}\\) [0-9]{3}-[0-9]{4}$') AS is_valid_phone_number
    
FROM raw_emergency_contacts
), patients AS (
    SELECT *
    FROM __dbt__cte__stg_patients
),

admissions AS (
    SELECT *
    FROM __dbt__cte__stg_admissions
),

diagnosis AS (
    SELECT *
    FROM __dbt__cte__stg_diagnosis
),

prescriptions AS (
    SELECT *
    FROM __dbt__cte__stg_prescriptions
),

lab_events AS (
    SELECT *
    FROM __dbt__cte__stg_lab_events
),

emergency_contacts AS (
    SELECT *
    FROM __dbt__cte__stg_emergency_contacts
),

-- =========================
-- ADMISSION METRICS
-- =========================
admission_metrics AS (
    SELECT
        patient_id,

        COUNT(DISTINCT admission_id) AS total_admissions,

        SUM(total_cost) AS lifetime_total_cost,

        MIN(admitted_in_timestamp) AS first_admission_date,
        MAX(admitted_in_timestamp) AS last_admission_date,

        AVG(DATEDIFF('day', admitted_in_timestamp, admitted_out_timestamp)) AS avg_length_of_stay

    FROM admissions
    GROUP BY patient_id
),

-- =========================
-- DIAGNOSIS METRICS
-- =========================
diagnosis_metrics AS (
    SELECT
        patient_id,
        COUNT(*) AS total_diagnoses,
        COUNT(DISTINCT description) AS distinct_diagnoses
    FROM diagnosis
    GROUP BY patient_id
),

-- =========================
-- PRESCRIPTION METRICS
-- =========================
med_metrics AS (
    SELECT
        patient_id,
        COUNT(*) AS total_prescriptions,
        COUNT(DISTINCT drug_id) AS distinct_drugs
    FROM prescriptions
    GROUP BY patient_id
),

-- =========================
-- LAB METRICS
-- =========================
lab_metrics AS (
    SELECT
        patient_id,

        COUNT(*) AS total_labs,

        SUM(CASE 
                WHEN TRY_CAST(result_value AS FLOAT) > range_higher 
                  OR TRY_CAST(result_value AS FLOAT) < range_lower 
                THEN 1 ELSE 0 
            END) AS abnormal_lab_count

    FROM lab_events
    GROUP BY patient_id
),

-- =========================
-- CURRENT STATUS LOGIC
-- =========================
latest_status AS (
    SELECT
        p.patient_id,

        CASE 
            WHEN p.deathdate IS NOT NULL THEN 'Deceased'
            WHEN a.total_admissions IS NULL THEN 'No Admissions'
            WHEN DATEDIFF('day', a.last_admission_date, CURRENT_DATE()) <= 90 THEN 'Recent'
            ELSE 'Active'
        END AS patient_status

    FROM patients p
    LEFT JOIN admission_metrics a
        ON p.patient_id = a.patient_id
)

-- =========================
-- FINAL MODEL
-- =========================
SELECT
    p.patient_id,
    p.full_name,
    p.gender,
    p.birthdate,
    p.blood_type,
    p.marital_status,
    p.ethnicity,
    p.race,
    p.income_usd,

    ec.emergency_contact_name,
    ec.emergency_contact_phone_number,

    -- =====================
    -- LIFETIME METRICS
    -- =====================
    COALESCE(am.total_admissions, 0) AS total_admissions,
    COALESCE(am.lifetime_total_cost, 0) AS lifetime_total_cost,
    COALESCE(dm.total_diagnoses, 0) AS total_diagnoses,
    COALESCE(dm.distinct_diagnoses, 0) AS distinct_diagnoses,
    COALESCE(mm.total_prescriptions, 0) AS total_prescriptions,
    COALESCE(mm.distinct_drugs, 0) AS distinct_drugs,
    COALESCE(lm.abnormal_lab_count, 0) AS abnormal_lab_count,

    -- =====================
    -- TIME-BASED METRICS
    -- =====================
    am.first_admission_date,
    am.last_admission_date,

    -- =====================
    -- STATUS
    -- =====================
    ls.patient_status

FROM patients p

LEFT JOIN admission_metrics am
    ON p.patient_id = am.patient_id

LEFT JOIN diagnosis_metrics dm
    ON p.patient_id = dm.patient_id

LEFT JOIN med_metrics mm
    ON p.patient_id = mm.patient_id

LEFT JOIN lab_metrics lm
    ON p.patient_id = lm.patient_id

LEFT JOIN emergency_contacts ec
    ON p.patient_id = ec.patient_id

LEFT JOIN latest_status ls
    ON p.patient_id = ls.patient_id
  );

