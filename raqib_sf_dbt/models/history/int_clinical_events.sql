WITH all_events AS (
    SELECT 
        admission_id, 
        patient_id, 
        'Diagnosis'                                                      AS event_type, 
        description                                                      AS event_name, 
        NULL::TIMESTAMP                                                  AS event_date,
        NULL::FLOAT                                                      AS cost,
        diagnosis_id::VARCHAR                                            AS source_id
    FROM {{ ref('int_diagnosis') }}

    UNION ALL

    SELECT 
        admission_id, 
        patient_id, 
        'Lab'                                                            AS event_type, 
        test_name                                                        AS event_name, 
        lab_done_at                                                      AS event_date,
        cost,
        lab_event_id::VARCHAR                                            AS source_id
    FROM {{ ref('int_lab_analysis') }}

    UNION ALL

    SELECT 
        admission_id, 
        patient_id, 
        'Medication'                                                     AS event_type, 
        drug_name                                                        AS event_name, 
        prescription_date                                                AS event_date,
        NULL::FLOAT                                                      AS cost,
        prescription_id::VARCHAR                                         AS source_id
    FROM {{ ref('int_prescriptions') }}
),

events_with_date AS (
    SELECT
        ae.admission_id,
        ae.patient_id,
        ae.event_type,
        ae.event_name,
        ae.source_id,
        ae.cost,
        COALESCE(ae.event_date, e.admitted_at)                          AS event_date
    FROM all_events ae
    LEFT JOIN {{ ref('int_encounters') }} e 
        ON ae.admission_id = e.admission_id
)

SELECT
    {{ dbt_utils.generate_surrogate_key([
        'admission_id', 
        'event_type', 
        'event_date', 
        'event_name',
        'source_id'
    ]) }}                                                                AS event_key,

    admission_id,
    patient_id,
    event_type,
    event_name,
    event_date,
    COALESCE(cost, 0)                                                    AS event_cost

FROM events_with_date