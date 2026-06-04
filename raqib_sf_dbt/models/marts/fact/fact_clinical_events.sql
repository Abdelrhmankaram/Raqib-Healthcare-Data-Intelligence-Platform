{{ config(unique_key='event_key') }}

SELECT
    ce.event_key,
    ie.encounter_key,
    dp.patient_key,
    dd.date_key AS event_date_key,
    ddx.diagnosis_key,
    ce.event_type,
    ce.event_name,
    ce.event_date,
    ce.event_cost

FROM {{ ref('int_clinical_events') }} ce
LEFT JOIN {{ ref('int_encounters') }} ie
    ON ce.admission_id = ie.admission_id
LEFT JOIN {{ ref('dim_patients') }} dp
    ON ce.patient_id = dp.patient_id
LEFT JOIN {{ ref('dim_date') }} dd
    ON CAST(ce.event_date AS DATE) = dd.date_bk
LEFT JOIN {{ ref('dim_diagnosis') }} ddx  
    ON ce.diagnosis_id = ddx.diagnosis_id

    {% if is_incremental() %}
    WHERE ce.event_date > (SELECT MAX(event_date) FROM {{ this }})
    {% endif %}