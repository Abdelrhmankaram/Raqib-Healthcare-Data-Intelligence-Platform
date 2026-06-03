with fact_transfers as (
    select
        {{ dbt_utils.generate_surrogate_key(['p.patient_key', 'pv.provider_key', 'a.admission_key']) }} as transfer_key, 
        t.transfer_id,
        p.patient_key,
        pv.provider_key,
        a.admission_key,
        d.date_time_key,

        t.from_department,
        t.to_department,
        t.transfer_reason
    from
        {{ ref('stg_transfers') }} as t
    left join 
        {{ ref('dim_patients') }} as p
            on p.patient_id = t.patient_id
    left join {{ ref('dim_provider') }} as pv
            on t.provider_id = pv.provider_id
    left join {{ ref('fact_admissions') }} as a
            on a.admission_id = t.admission_id
    left join {{ ref('dim_date') }} as d
            on cast(t.transfer_date_key AS DATE) = d.full_date;
)

select * from fact_transfers