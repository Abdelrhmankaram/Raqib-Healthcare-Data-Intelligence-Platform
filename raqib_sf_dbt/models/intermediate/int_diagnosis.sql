with stg_diagnosis as (
    select * 
    from {{ ref('stg_diagnosis') }}
)

select 
    {{ dbt_utils.surrogate_key(['diagnosis_id']) }} AS diagnosis_key,
    diagnosis_id,
    patient_id,
    admission_id,
    provider_id,
    description,
    sub_domain_1,
    sub_domain_2,
    sub_domain_key

from stg_diagnosis