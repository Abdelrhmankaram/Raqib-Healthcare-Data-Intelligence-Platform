with dim_admission_type as (
    select distinct admission_type as admission_type from {{ ref('stg_admissions') }}
)

select 
{{ dbt_utils.generate_surrogate_key(['admission_type']) }} as admission_type_Key,
*
from dim_admission_type