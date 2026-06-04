{{ config(materialized='incremental', unique_key='encounter_key') }}

SELECT
    ie.encounter_key,
    ie.admission_id,
    ie.patient_id,
    ie.provider_id,

    dp.patient_key,
    dpr.provider_key,
    dat.admission_type_key,
    dl_adm.location_key  as admission_location_key,
    dl_dis.location_key  as discharge_location_key,
    dd.date_key as admitted_date_key,
    dt.time_key as admitted_time_key,

    ie.primary_sdk,
    ie.provider_specialty,
    ie.admitted_at,
    ie.discharged_at,
    ie.is_active_encounter,
    ie.length_of_stay_days,
    ie.admission_type,
    ie.admission_location,
    ie.discharge_location,
    ie.total_cost,
    ie.payer_coverage,
    ie.coverage_percentage,
    ie.out_of_pocket_cost,
    ie.age_at_admission,
    ie.age_group,
    ie.discharge_status

FROM {{ ref('int_encounters') }} ie
LEFT JOIN {{ ref('dim_patients') }} dp
    ON ie.patient_id = dp.patient_id
LEFT JOIN {{ ref('dim_provider') }} dpr
    ON ie.provider_id = dpr.provider_id
LEFT JOIN {{ ref('dim_admission_type') }} dat
    ON ie.admission_type = dat.admission_type
LEFT JOIN {{ ref('dim_location') }} dl_adm
    ON ie.admission_location = dl_adm.location_name
LEFT JOIN {{ ref('dim_location') }} dl_dis
    ON ie.discharge_location = dl_dis.location_name
LEFT JOIN {{ ref('dim_date') }} dd
    ON CAST(ie.admitted_at AS DATE) = dd.date_bk
LEFT JOIN {{ ref('dim_time') }} dt
    ON CAST(ie.admitted_at AS TIME) = dt.time_bk

{% if is_incremental() %}
WHERE ie.admitted_at > (SELECT MAX(admitted_at) FROM {{ this }})
{% endif %}