SELECT
    ce.event_key,
    ie.encounter_key,
    ce.patient_id,
    dp.patient_key,
    ce.event_type,
    ce.event_name,
    ce.event_date,
    ce.event_cost,
    dd.date_key  as event_date_key

FROM {{ ref('int_clinical_events') }} ce
LEFT JOIN {{ ref('int_encounters') }} ie
    ON ce.admission_id = ie.admission_id
LEFT JOIN {{ ref('dim_patients') }} dp
    ON ce.patient_id = dp.patient_id
LEFT JOIN {{ ref('dim_date') }} dd
    ON CAST(ce.event_date AS DATE) = dd.date_bk