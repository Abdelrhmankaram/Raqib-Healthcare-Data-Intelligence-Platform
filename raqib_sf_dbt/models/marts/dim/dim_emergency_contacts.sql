with emergency_contacts as (
    select * 
    from {{ ref('stg_emergency_contacts') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['patient_id','emergency_contact_name']) }} AS contact_key,
    *
FROM emergency_contacts


    