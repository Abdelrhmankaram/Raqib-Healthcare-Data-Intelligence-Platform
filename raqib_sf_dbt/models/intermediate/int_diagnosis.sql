with stg_diagnosis as (
    select * 
    from {{ ref('stg_diagnosis') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['diagnosis_id']) }} AS diagnosis_key,
    *

from stg_diagnosis