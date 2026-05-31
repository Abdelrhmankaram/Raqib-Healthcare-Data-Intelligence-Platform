with raw_admissions as (
    select * 
    from {{ source('raw', 'raw_admissions') }}
)

select 
    admission_id,
    patient_id,
    try_cast(admission_datetime_in as timestamp) as admitted_in_timestamp,
    try_cast(admission_datetime_out as timestamp) as admitted_out_timestamp,
    upper(LEFT(admission_type, 1)) || lower(substr(admission_type, 2)) as admission_type,
    admission_provider_id as provider_id,
    admission_location,
    discharge_location,
    initcap(insurance_type) as insurance_type,
    total_cost,
    payer_coverage,
    hospital_expire_flag

from raw_admissions
