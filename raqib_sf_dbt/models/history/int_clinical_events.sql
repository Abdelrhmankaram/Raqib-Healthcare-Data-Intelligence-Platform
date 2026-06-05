WITH all_events AS (
    SELECT 
        admission_id, 
        patient_id, 
        'Diagnosis' AS event_type, 
        description AS event_name, 
        NULL::TIMESTAMP AS event_date,
        NULL::FLOAT AS cost,
        diagnosis_id::VARCHAR AS source_id,
        diagnosis_id::VARCHAR AS diagnosis_id 
    FROM {{ ref('stg_diagnosis') }}

    UNION ALL

    SELECT 
        le.admission_id, 
        le.patient_id, 
        'Lab' AS event_type, 
        le.test_name AS event_name, 
        le.lab_done_at AS event_date,
        le.cost,
        le.lab_event_id::VARCHAR AS source_id,
        NULL::VARCHAR AS diagnosis_id
    FROM {{ ref('int_lab_analysis') }} le

    UNION ALL

    SELECT 
        p.admission_id, 
        p.patient_id, 
        'Medication' AS event_type, 
        d.brand_name AS event_name, 
        p.prescribed_date AS event_date,
        NULL::FLOAT AS cost,
        p.prescription_id::VARCHAR AS source_id,
        NULL::VARCHAR AS diagnosis_id 
    FROM {{ ref('stg_prescriptions') }} p
    LEFT JOIN {{ ref('stg_drugs') }} d 
        ON p.drug_id = d.drug_id
),

events_with_date AS (
    SELECT
        ae.admission_id,
        ae.patient_id,
        ae.event_type,
        ae.event_name,
        ae.source_id,
        ae.cost,
        ae.diagnosis_id, 
        COALESCE(ae.event_date, e.admitted_at) AS event_date
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
    ]) }} AS event_key,

    admission_id,
    patient_id,
    event_type,
    event_name,
    event_date,
    COALESCE(cost, 0) AS event_cost,
    diagnosis_id 

FROM events_with_date