with stg_services as (
    select * 
    from {{ ref('stg_services') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['service_id']) }} AS service_key,
    * 
from stg_services