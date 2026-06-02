with stg_services as (
    select * 
    from {{ ref('stg_services') }}
)

select 
    * 
from stg_services