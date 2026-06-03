with stg_providers as (
    select *
    from {{ ref('stg_providers') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['provider_id', 'provider_full_name', 'provider_specialty']) }} as provider_key,
    *
    
from stg_providers
