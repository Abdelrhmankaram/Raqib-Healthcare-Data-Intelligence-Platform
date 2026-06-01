with stg_drugs as (
     select * 
     from {{ ref('stg_drugs') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['brand_name', 'generic_name', 'route']) }} as drug_key,
    *

from stg_drugs