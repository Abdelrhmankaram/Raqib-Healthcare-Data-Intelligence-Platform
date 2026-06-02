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
    SELECT * FROM __dbt__cte__stg_patients
),

encounters AS (
    SELECT * FROM dev.dbt_dev_intermediate.int_encounters
),

clinical_events AS (
    SELECT * FROM dev.dbt_dev_intermediate.int_clinical_events
),

emergency_contacts AS (
    SELECT * FROM __dbt__cte__stg_emergency_contacts
),


admission_metrics AS (
    SELECT
        patient_id,
        COUNT(DISTINCT admission_id) AS total_admissions,
        SUM(total_cost) AS lifetime_total_cost,
        MIN(admitted_at) AS first_admission_date,
        MAX(admitted_at) AS last_admission_date,
        AVG(length_of_stay_days) AS avg_length_of_stay
    FROM encounters
    GROUP BY patient_id
),

clinical_metrics AS (
    SELECT
        patient_id,
        COUNT(CASE WHEN event_type = 'Diagnosis' THEN 1 END) AS total_diagnoses,
        COUNT(CASE WHEN event_type = 'Lab' THEN 1 END) AS total_labs,
        COUNT(CASE WHEN event_type = 'Medication' THEN 1 END) AS total_prescriptions
    FROM clinical_events
    GROUP BY patient_id
),

latest_status AS (
    SELECT
        patient_id,
        CASE 
            WHEN MAX(CASE WHEN discharge_status = 'Deceased' THEN 1 ELSE 0 END) = 1 THEN 'Deceased'
            WHEN MAX(admitted_at) IS NULL THEN 'No Admissions'
            WHEN DATEDIFF('day', MAX(admitted_at), CURRENT_DATE()) <= 90 THEN 'Recent'
            ELSE 'Active'
        END AS patient_status
    FROM encounters
    GROUP BY patient_id
)

SELECT
    md5(cast(coalesce(cast(p.patient_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS patient_360_key,
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

    COALESCE(am.total_admissions, 0) AS total_admissions,
    COALESCE(am.lifetime_total_cost, 0) AS lifetime_total_cost,
    COALESCE(cm.total_diagnoses, 0) AS total_diagnoses,
    COALESCE(cm.total_prescriptions, 0) AS total_prescriptions,
    COALESCE(cm.total_labs, 0) AS total_labs,

    am.first_admission_date,
    am.last_admission_date,
    ls.patient_status

FROM patients p
LEFT JOIN admission_metrics am ON p.patient_id = am.patient_id
LEFT JOIN clinical_metrics cm ON p.patient_id = cm.patient_id
LEFT JOIN emergency_contacts ec ON p.patient_id = ec.patient_id
LEFT JOIN latest_status ls ON p.patient_id = ls.patient_id