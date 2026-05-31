
    
    

with  __dbt__cte__emergency_contacts as (
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
), all_values as (

    select
        emergency_contact_bloodtype as value_field,
        count(*) as n_records

    from __dbt__cte__emergency_contacts
    group by emergency_contact_bloodtype

)

select *
from all_values
where value_field not in (
    'A+','AB+','B+','O+','O-','AB-','A-','B-'
)


