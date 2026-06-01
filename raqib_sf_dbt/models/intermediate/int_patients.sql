with stg_patients as (
    select * 
    from {{ ref('stg_patients') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['patient_id']) }} AS patient_key,
    *
    
from stg_patients