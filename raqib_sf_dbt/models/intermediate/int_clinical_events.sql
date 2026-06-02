-- تجميع كل الevents في جدول واحد
WITH all_events AS (
    SELECT 
        admission_id, 
        patient_id, 
        'Diagnosis' AS event_type, 
        description AS event_name, 
        diagnosis_date AS event_date,
        NULL AS cost
    FROM {{ ref('int_diagnosis') }}

    UNION ALL

    SELECT 
        admission_id, 
        patient_id, 
        'Lab' AS event_type, 
        test_name AS event_name, 
        lab_done_at AS event_date,
        cost
    FROM {{ ref('int_lab_analysis') }}

    UNION ALL

    SELECT 
        admission_id, 
        patient_id, 
        'Medication' AS event_type, 
        drug_name AS event_name, 
        prescription_date AS event_date,
        NULL AS cost
    FROM {{ ref('int_prescriptions') }}
)

SELECT 
    e.admission_id,
    e.patient_id,
    COALESCE(ev.event_type, 'Routine/No Activity') AS event_type,
    COALESCE(ev.event_name, 'Observation') AS event_name,
    COALESCE(ev.event_date, e.admitted_at) AS event_date,
    COALESCE(ev.cost, 0) AS event_cost
FROM {{ ref('int_encounters') }} e
LEFT JOIN all_events ev ON e.admission_id = ev.admission_id
ORDER BY e.admitted_at DESC, ev.event_date DESC