with raw_prescriptions as (
    select *
    from raw.public.prescriptions
)

select 
    prescription_id,
    patient_id,
    admission_id,
    provider_id,
    drug_id,
    prescribed_date,
    initcap(status)
from raw_prescriptions