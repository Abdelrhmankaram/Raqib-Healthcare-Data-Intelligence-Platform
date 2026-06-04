SELECT
    event_key,
    admission_id,
    patient_id,
    event_type,
    event_name,
    event_date,
    event_cost
FROM {{ ref('int_clinical_events') }}