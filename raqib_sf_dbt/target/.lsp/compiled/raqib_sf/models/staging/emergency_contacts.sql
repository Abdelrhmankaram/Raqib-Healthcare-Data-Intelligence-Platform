WITH raw_emergency_contacts AS (
    SELECT *
    FROM raw.public.emergency_contacts
)

SELECT
    "Patient_ID" AS patient_id,
    INITCAP("emergency_contact_name") AS emergency_contact_name,
    "emergency_contact_relationship" AS emergency_contact_relationship,
    "emergency_contact_bloodtype" AS emergency_contact_bloodtype,
    "emergency_contact_number" AS emergency_contact_phone_number,
    REGEXP_LIKE("emergency_contact_number", '^\\([0-9]{3}\\) [0-9]{3}-[0-9]{4}$') AS is_valid_phone_number
    
FROM raw_emergency_contacts