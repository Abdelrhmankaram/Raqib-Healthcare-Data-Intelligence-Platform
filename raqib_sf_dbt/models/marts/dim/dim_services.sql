with services as (
    select *
    from {{ ref('stg_services') }}
)

select    
    {{ dbt_utils.generate_surrogate_key(['service_id']) }} AS service_dim_key,
    service_name,
    service_sub_type,
    category 
from services
