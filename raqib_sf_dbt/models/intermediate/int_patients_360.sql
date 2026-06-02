with stg_patients as (
    select * 
    from {{ ref('stg_patients') }}
)

select 
    
    
from stg_patients