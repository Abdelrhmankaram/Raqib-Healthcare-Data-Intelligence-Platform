with dim_admission_type as (
    select distinct admission_type as Admission_Type from {{ ref('stg_admissions') }}
)

select 
{{ dbt_utils.generate_surrogate_key(['Admission_Type']) }} as Admission_Key,
*
from dim_admission_type