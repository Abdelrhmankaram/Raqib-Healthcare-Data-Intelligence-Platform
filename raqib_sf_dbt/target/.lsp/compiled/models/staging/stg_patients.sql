WITH raw_patients AS (
    SELECT *
    FROM raw.public.patients
)

SELECT 
    patient_id,
    ssn,
    INITCAP(first_name || ' ' || last_name) AS full_name,
    TRY_TO_DATE(birthdate) AS birthdate,
    YEAR(TRY_TO_DATE(birthdate)) AS birth_year,
    TRY_TO_DATE(deathdate) AS deathdate,
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
    TRIM(REGEXP_REPLACE(REGEXP_REPLACE(birthplace, ',', ''), '\\s+\\S+$', '')) AS birth_city,
    address,
    INITCAP(city) AS city,
    INITCAP(country) AS country,
    TRY_CAST(healthcare_expenses AS FLOAT) AS healthcare_expenses,
    TRY_CAST(healthcare_coverage AS FLOAT) AS healthcare_coverage,
    income AS income_usd
  
FROM raw_patients