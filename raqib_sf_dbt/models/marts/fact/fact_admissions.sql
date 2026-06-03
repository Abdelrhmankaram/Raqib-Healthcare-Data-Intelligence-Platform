with stg_admissions as (
    select *
    from {{ ref('stg_admissions') }}
),
dim_patients as (
    select *
    from {{ ref('dim_patients') }}
),
dim_provider as (
    select *
    from {{ ref('dim_provider') }}
),
dim_admission_type as (
    select *
    from {{ ref('dim_admission_type') }}
),
dim_insurance as (
    select *
    from {{ ref('dim_insurance') }}
),
dim_location as (
    select *
    from {{ ref('dim_location') }}
),
dim_date as (
    select *
    from {{ ref('dim_date') }}
),
dim_time as (
    select *
    from {{ ref('dim_time') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['admission_id', 'patient_id', 'admitted_in_timestamp']) }} as admission_key,
    stg_admissions.admission_id,
    dim_patients.patient_key,
    dim_provider.provider_key,
    dim_admission_type.admission_type_key,
    dim_insurance.insurance_key,
    dim_date.date_key as admitted_date_key,
    dim_time.time_key as admitted_time_key,
    dim_date.date_key as discharged_date_key,
    dim_time.time_key as discharged_time_key,
    admission_location_dim.location_key as admission_location_key,
    discharge_location_dim.location_key as discharge_location_key,
    stg_admissions.admitted_in_timestamp,
    stg_admissions.admitted_out_timestamp,
    stg_admissions.total_cost,
    stg_admissions.payer_coverage,
    stg_admissions.hospital_expire_flag,
    stg_admissions.primary_sdk,
    datediff(day, stg_admissions.admitted_in_timestamp, stg_admissions.admitted_out_timestamp) as length_of_stay

from stg_admissions

left join dim_patients on stg_admissions.patient_id = dim_patients.patient_id

left join dim_provider on stg_admissions.provider_id = dim_provider.provider_id

left join dim_admission_type on lower(stg_admissions.admission_type) = lower(dim_admission_type.admission_type)

left join dim_insurance on stg_admissions.insurance_type = dim_insurance.insurance_type
    and stg_admissions.payer_coverage = dim_insurance.payer_coverage

left join dim_location as admission_location_dim on lower(stg_admissions.admission_location) = lower(admission_location_dim.location_name)

left join dim_location as discharge_location_dim on lower(stg_admissions.discharge_location) = lower(discharge_location_dim.location_name)

left join dim_date on cast(stg_admissions.admitted_in_timestamp as date) = dim_date.date_key

left join dim_time on cast(stg_admissions.admitted_in_timestamp as time) = dim_time.time_key