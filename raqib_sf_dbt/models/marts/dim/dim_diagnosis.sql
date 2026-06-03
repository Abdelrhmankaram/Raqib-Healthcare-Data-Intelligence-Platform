with dim_diagnosis as (
    select * from {{ ref('stg_diagnosis') }}
)

select 
    {{ dbt_utils.create_surrogate_key(['diagnosis_id', 'sub_domain_1', 'sub_domain_key']) }} as diagnosis_key,
    description,
    description_type,
    sub_domain_key
    domain,
    sub_domain
from dim_diagnosis