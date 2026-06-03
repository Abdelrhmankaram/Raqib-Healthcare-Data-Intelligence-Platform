with patients as (
    select 
    patient_id,
    healthcare_expenses,
    healthcare_coverage,
    income_usd 
    from {{ ref('stg_patients') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['patient_id']) }} as patient_key,    
    healthcare_expenses,
    healthcare_coverage,
    income_usd  
from patients