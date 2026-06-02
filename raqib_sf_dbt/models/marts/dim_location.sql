with dim_location as (
    select distinct admission_type as Location_Name from {{ ref('stg_admissions') }}
    union
    select distinct discharge_location from {{ ref('stg_admissions') }}
)

select 
{{ dbt_utils.generate_surrogate_key(['Location_Name']) }} as Location_Key,
*
from dim_location