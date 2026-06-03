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
    {{ dbt_utils.generate_surrogate_key(['stg_admissions.admission_id', 'stg_admissions.patient_id', 'stg_admissions.admitted_date', 'stg_admissions.admitted_time']) }} as admission_key,
    dim_patients.patient_key,
    dim_provider.provider_key,
    dim_admission_type.admission_type_key,
    admitted_date_key.date_key as admitted_date_key,
    admitted_time_key.time_key as admitted_time_key,
    discharged_date_key.date_key as discharged_date_key,
    discharged_time_key.time_key as discharged_time_key,
    admission_location_dim.location_key as admission_location_key,
    discharge_location_dim.location_key as discharge_location_key,
    stg_admissions.insurance_type,
    stg_admissions.total_cost,
    stg_admissions.payer_coverage,
    stg_admissions.hospital_expire_flag,
    stg_admissions.primary_sdk,
    {{ dbt.datediff(stg_admissions.admitted_date, stg_admissions.discharged_date, 'day') }} as length_of_stay_in_days

from stg_admissions

left join dim_patients 
    on stg_admissions.patient_id = dim_patients.patient_id

left join dim_provider 
    on stg_admissions.provider_id = dim_provider.provider_id

left join dim_admission_type 
    on lower(stg_admissions.admission_type) = lower(dim_admission_type.admission_type)

left join dim_location as admission_location_dim 
    on lower(stg_admissions.admission_location) = lower(admission_location_dim.location_name)

left join dim_location as discharge_location_dim 
    on lower(stg_admissions.discharge_location) = lower(discharge_location_dim.location_name)

left join dim_date as admitted_date_key 
    on cast(stg_admissions.admitted_date as date) = admitted_date_key.date_bk

left join dim_time as admitted_time_key 
    on stg_admissions.admitted_time = admitted_time_key.time_bk

left join dim_date as discharged_date_key 
    on cast(stg_admissions.discharged_date as date) = discharged_date_key.date_bk 

left join dim_time as discharged_time_key 
    on stg_admissions.discharged_time = discharged_time_key.time_bk