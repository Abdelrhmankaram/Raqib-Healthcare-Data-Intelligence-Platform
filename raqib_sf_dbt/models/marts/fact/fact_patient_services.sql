with fact_patient_services as (
    select
        "" as service_key,
        p.patient_key,
        a.admission_key,

        s.cost,
        s.service_duration_in_minutes
    from
        {{ ref('stg_services') }} as s
    left join
        {{ ref('dim_patient') }} as p
            on p.patient_id = s.patient_id
    left join 
        {{ ref('fact_admissions') }} as a
            on a.admission_id = s.admission_id
)