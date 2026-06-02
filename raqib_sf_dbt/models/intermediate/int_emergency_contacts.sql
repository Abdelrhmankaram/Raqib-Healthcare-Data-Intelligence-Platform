WITH emergency_contacts AS (
    SELECT *
    FROM {{ ref('stg_emergency_contacts') }}
),

patients AS (
    SELECT *
    FROM {{ ref('stg_patients') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['patient_id','emergency_contact_name','emergency_contact_phone_number']) }} AS emergency_contact_key,
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