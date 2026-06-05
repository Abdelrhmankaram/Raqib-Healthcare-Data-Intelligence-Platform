WITH  __dbt__cte__stg_emergency_contacts as (
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
),  __dbt__cte__stg_patients as (
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
), emergency_contacts AS (
    SELECT *
    FROM __dbt__cte__stg_emergency_contacts
),

patients AS (
    SELECT *
    FROM __dbt__cte__stg_patients
)

SELECT
    md5(cast(coalesce(cast(p.patient_id as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ec.emergency_contact_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(ec.emergency_contact_phone_number as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS emergency_contact_key,
    ec.patient_id,

    p.full_name,
    p.birthdate,
    p.gender,
    p.blood_type,

    ec.emergency_contact_name,
    ec.emergency_contact_relationship,
    ec.emergency_contact_bloodtype,
    ec.emergency_contact_phone_number

FROM emergency_contacts ec

LEFT JOIN patients p
    ON ec.patient_id = p.patient_id