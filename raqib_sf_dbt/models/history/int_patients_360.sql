{{ config(enabled=false) }}

WITH patients AS (
    SELECT * FROM {{ ref('stg_patients') }}
),

encounters AS (
    SELECT * FROM {{ ref('int_encounters') }}
),

clinical_events AS (
    SELECT * FROM {{ ref('int_clinical_events') }}
),

emergency_contacts AS (
    SELECT * FROM {{ ref('stg_emergency_contacts') }}
),


admission_metrics AS (
    SELECT
        patient_id,
        COUNT(DISTINCT admission_id) AS total_admissions,
        SUM(total_cost) AS lifetime_total_cost,
        MIN(admitted_at) AS first_admission_date,
        MAX(admitted_at) AS last_admission_date,
        AVG(length_of_stay_days) AS avg_length_of_stay
    FROM encounters
    GROUP BY patient_id
),

clinical_metrics AS (
    SELECT
        patient_id,
        COUNT(CASE WHEN event_type = 'Diagnosis' THEN 1 END) AS total_diagnoses,
        COUNT(CASE WHEN event_type = 'Lab' THEN 1 END) AS total_labs,
        COUNT(CASE WHEN event_type = 'Medication' THEN 1 END) AS total_prescriptions
    FROM clinical_events
    GROUP BY patient_id
),

latest_status AS (
    SELECT
        patient_id,
        CASE 
            WHEN MAX(CASE WHEN discharge_status = 'Deceased' THEN 1 ELSE 0 END) = 1 THEN 'Deceased'
            WHEN MAX(admitted_at) IS NULL THEN 'No Admissions'
            WHEN DATEDIFF('day', MAX(admitted_at), CURRENT_DATE()) <= 90 THEN 'Recent'
            ELSE 'Active'
        END AS patient_status
    FROM encounters
    GROUP BY patient_id
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['p.patient_id']) }} AS patient_360_key,
    p.patient_id,
    p.full_name,
    p.gender,
    p.birthdate,
    p.blood_type,
    p.marital_status,
    p.ethnicity,
    p.race,
    p.income_usd,

    ec.emergency_contact_name,
    ec.emergency_contact_phone_number,

    COALESCE(am.total_admissions, 0) AS total_admissions,
    COALESCE(am.lifetime_total_cost, 0) AS lifetime_total_cost,
    COALESCE(cm.total_diagnoses, 0) AS total_diagnoses,
    COALESCE(cm.total_prescriptions, 0) AS total_prescriptions,
    COALESCE(cm.total_labs, 0) AS total_labs,

    am.first_admission_date,
    am.last_admission_date,
    ls.patient_status

FROM patients p
LEFT JOIN admission_metrics am ON p.patient_id = am.patient_id
LEFT JOIN clinical_metrics cm ON p.patient_id = cm.patient_id
LEFT JOIN emergency_contacts ec ON p.patient_id = ec.patient_id
LEFT JOIN latest_status ls ON p.patient_id = ls.patient_id