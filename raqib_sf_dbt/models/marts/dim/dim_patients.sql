with patients as (
    select
        *
    from {{ ref('stg_patients') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['patient_id']) }} AS patient_key,
    patient_id,
    ssn,
    full_name,
    birthdate,
    birth_year,
    deathdate,
    is_dead,
    blood_type,
    marital_status,
    Race,
    ethnicity,
    spoken_language,
    city
    
FROM patients
