with stg_addmissions as (
    select *
    from {{ ref('stg_admissions') }}
),
 dim_patients as (
    select *
    from {{ ref('dim_patients') }}
),
 dim_providers as (
    select *
    from {{ ref('dim_providers') }}
),
 dim_admission_type as (
    select *
    from {{ ref('dim_admission_type') }}
),
 dim_insurance_type as (
    select *
    from {{ ref('dim_insurance_type') }}
),
 dim_location as (
        select *
        from {{ ref('dim_location') }}
),
 dim_date as (
        select *
        from {{ ref('dim_date') }}
),
 dim_location as (
        select *
        from {{ ref('dim_location') }}
),
 dim_provider as (
        select *
        from {{ ref('dim_providers') }}
),
 dim_diagnosis as (
        select *
        from {{ ref('dim_diagnosis') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['admission_id', 'patient_id', 'admitted_in_timestamp']) }} as admission_key,
    admission_id,
    patient_id,
    provider_id,
    admission_type,
    admitted_in_timestamp,
    admitted_out_timestamp,
    admission_location,
    discharge_location,
    insurance_type,
    total_cost,
    payer_coverage,
    hospital_expire_flag,
    primary_sdk,



