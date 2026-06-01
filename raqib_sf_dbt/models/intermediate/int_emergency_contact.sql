with stg_emergency_contact as (
    select * 
    from {{ ref('stg_emergency_contact') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['patient_id', 'emergency_contact_name', 'emergency_contact_relationship']) }} AS emergency_contact_key,
    *
    
from stg_emergency_contact