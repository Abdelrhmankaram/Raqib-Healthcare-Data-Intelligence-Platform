with stg_prescriptions as (
    select * 
    from {{ ref('stg_prescriptions') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['prescription_id']) }} AS prescription_key,
    *

from stg_prescriptions