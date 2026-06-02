WITH patients AS (
    SELECT *
    FROM {{ ref('stg_patients') }}
),

admissions AS (
    SELECT *
    FROM {{ ref('stg_admissions') }}
),

diagnosis AS (
    SELECT *
    FROM {{ ref('stg_diagnosis') }}
),

prescriptions AS (
    SELECT *
    FROM {{ ref('stg_prescriptions') }}
),

lab_events AS (
    SELECT *
    FROM {{ ref('stg_lab_events') }}
),

emergency_contacts AS (
    SELECT *
    FROM {{ ref('stg_emergency_contacts') }}
),

-- =========================
-- ADMISSION METRICS
-- =========================
admission_metrics AS (
    SELECT
        patient_id,

        COUNT(DISTINCT admission_id) AS total_admissions,

        SUM(total_cost) AS lifetime_total_cost,

        MIN(admitted_in_timestamp) AS first_admission_date,
        MAX(admitted_in_timestamp) AS last_admission_date,

        AVG(DATEDIFF('day', admitted_in_timestamp, admitted_out_timestamp)) AS avg_length_of_stay

    FROM admissions
    GROUP BY patient_id
),

-- =========================
-- DIAGNOSIS METRICS
-- =========================
diagnosis_metrics AS (
    SELECT
        patient_id,
        COUNT(*) AS total_diagnoses,
        COUNT(DISTINCT description) AS distinct_diagnoses
    FROM diagnosis
    GROUP BY patient_id
),

-- =========================
-- PRESCRIPTION METRICS
-- =========================
med_metrics AS (
    SELECT
        patient_id,
        COUNT(*) AS total_prescriptions,
        COUNT(DISTINCT drug_id) AS distinct_drugs
    FROM prescriptions
    GROUP BY patient_id
),

-- =========================
-- LAB METRICS
-- =========================
lab_metrics AS (
    SELECT
        patient_id,

        COUNT(*) AS total_labs,

        SUM(CASE 
                WHEN TRY_CAST(result_value AS FLOAT) > range_higher 
                  OR TRY_CAST(result_value AS FLOAT) < range_lower 
                THEN 1 ELSE 0 
            END) AS abnormal_lab_count

    FROM lab_events
    GROUP BY patient_id
),

-- =========================
-- CURRENT STATUS LOGIC
-- =========================
latest_status AS (
    SELECT
        p.patient_id,

        CASE 
            WHEN p.deathdate IS NOT NULL THEN 'Deceased'
            WHEN a.total_admissions IS NULL THEN 'No Admissions'
            WHEN DATEDIFF('day', a.last_admission_date, CURRENT_DATE()) <= 90 THEN 'Recent'
            ELSE 'Active'
        END AS patient_status

    FROM patients p
    LEFT JOIN admission_metrics a
        ON p.patient_id = a.patient_id
)

-- =========================
-- FINAL MODEL
-- =========================
SELECT
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

    -- =====================
    -- LIFETIME METRICS
    -- =====================
    COALESCE(am.total_admissions, 0) AS total_admissions,
    COALESCE(am.lifetime_total_cost, 0) AS lifetime_total_cost,
    COALESCE(dm.total_diagnoses, 0) AS total_diagnoses,
    COALESCE(dm.distinct_diagnoses, 0) AS distinct_diagnoses,
    COALESCE(mm.total_prescriptions, 0) AS total_prescriptions,
    COALESCE(mm.distinct_drugs, 0) AS distinct_drugs,
    COALESCE(lm.abnormal_lab_count, 0) AS abnormal_lab_count,

    -- =====================
    -- TIME-BASED METRICS
    -- =====================
    am.first_admission_date,
    am.last_admission_date,

    -- =====================
    -- STATUS
    -- =====================
    ls.patient_status

FROM patients p

LEFT JOIN admission_metrics am
    ON p.patient_id = am.patient_id

LEFT JOIN diagnosis_metrics dm
    ON p.patient_id = dm.patient_id

LEFT JOIN med_metrics mm
    ON p.patient_id = mm.patient_id

LEFT JOIN lab_metrics lm
    ON p.patient_id = lm.patient_id

LEFT JOIN emergency_contacts ec
    ON p.patient_id = ec.patient_id

LEFT JOIN latest_status ls
    ON p.patient_id = ls.patient_id
