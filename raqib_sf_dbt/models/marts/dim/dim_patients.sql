{{ config(unique_key='patient_key') }}

WITH patients AS (
    SELECT * FROM {{ ref('stg_patients') }}
),
emergency_contacts AS (
    SELECT * FROM {{ ref('stg_emergency_contacts') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['p.patient_id']) }} AS patient_key,
    p.patient_id,
    p.ssn,
    p.full_name,
    p.birthdate,
    p.birth_year,
    p.deathdate,
    p.is_dead,
    p.blood_type,
    p.marital_status,
    p.Race,
    p.ethnicity,
    p.spoken_language,
    p.city,
    ec.emergency_contact_name,
    ec.emergency_contact_phone_number
FROM patients p
LEFT JOIN emergency_contacts ec 
    ON p.patient_id = ec.patient_id


    {% if is_incremental() %}
        WHERE p.patient_id NOT IN (SELECT patient_id FROM {{ this }})
        {% endif %}