with __dbt__cte__stg_admissions as (
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
), __dbt__cte__stg_patients as (
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
), __dbt__cte__stg_providers as (
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
)
--EPHEMERAL-SELECT-WRAPPER-START
select * from (
WITH admissions AS (

    SELECT *
    FROM __dbt__cte__stg_admissions

),

patients AS (

    SELECT *
    FROM __dbt__cte__stg_patients

),

providers AS (

    SELECT *
    FROM __dbt__cte__stg_providers

),

base AS (

    SELECT
        md5(cast(coalesce(cast(admission_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS encounter_key,
        a.admission_id,
        a.patient_id,
        a.provider_id,

        a.primary_sdk,

        a.admitted_in_timestamp,
        a.admitted_out_timestamp,

        CASE
            WHEN a.admitted_out_timestamp IS NULL THEN TRUE
            ELSE FALSE
        END AS is_active_encounter,

        a.admission_type,
        a.admission_location,
        a.discharge_location,

        a.total_cost,
        a.payer_coverage,
        a.hospital_expire_flag,

        p.birthdate,

        pr.provider_specialty

    FROM admissions a

    LEFT JOIN patients p
        ON a.patient_id = p.patient_id

    LEFT JOIN providers pr
        ON a.provider_id = pr.provider_id

),

final AS (

    SELECT

        admission_id,
        patient_id,
        provider_id,
        encounter_key,
        primary_sdk,
        provider_specialty,
        admitted_in_timestamp AS admitted_at,
        admitted_out_timestamp AS discharged_at,

        is_active_encounter,

        DATEDIFF(
            'day',
            admitted_in_timestamp,
            COALESCE(
                admitted_out_timestamp,
                CURRENT_TIMESTAMP
            )
        ) AS length_of_stay_days,

        admission_type,
        admission_location,
        discharge_location,

        total_cost,

        payer_coverage,

        ROUND(
            payer_coverage
            / NULLIF(total_cost, 0) * 100,
            1
        ) AS coverage_percentage,

        total_cost - payer_coverage
            AS out_of_pocket_cost,

        DATEDIFF(
            'year',
            birthdate,
            admitted_in_timestamp
        ) AS age_at_admission,

        CASE
            WHEN age_at_admission < 12 THEN 'Child'
            WHEN age_at_admission BETWEEN 12 AND 17 THEN 'Teen'
            WHEN age_at_admission BETWEEN 18 AND 60 THEN 'Adult'
            ELSE 'Senior'
        END AS age_group,

        CASE
            WHEN hospital_expire_flag THEN 'Deceased'
            ELSE 'Alive'
        END AS discharge_status

    FROM base

)

SELECT *
FROM final
--EPHEMERAL-SELECT-WRAPPER-END
)