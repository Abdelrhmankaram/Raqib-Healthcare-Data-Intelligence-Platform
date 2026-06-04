with dim_diagnosis as (
    select * from {{ ref('stg_diagnosis') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['diagnosis_id', 'domain', 'sub_domain_key']) }} as diagnosis_key,
    diagnosis_id,
    description,
    description_type,
    sub_domain_key,
    domain,
    sub_domain
from dim_diagnosis