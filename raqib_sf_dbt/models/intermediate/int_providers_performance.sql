WITH providers AS (
    SELECT *
    FROM {{ ref('stg_providers') }}
),

admissions AS (
    SELECT *
    FROM {{ ref('stg_admissions') }}
),

diagnosis AS (
    SELECT *
    FROM {{ ref('stg_diagnosis') }}
),

lab_events AS (
    SELECT *
    FROM {{ ref('stg_lab_events') }}
),

prescriptions AS (
    SELECT *
    FROM {{ ref('stg_prescriptions') }}
),

-- =========================
-- ENCOUNTER METRICS
-- =========================
encounter_metrics AS (
    SELECT
        provider_id,

        COUNT(DISTINCT admission_id) AS total_encounters,
        COUNT(DISTINCT patient_id) AS unique_patients,

        AVG(total_cost) AS avg_encounter_cost,

        SUM(
            CASE 
                WHEN hospital_expire_flag = 1 THEN 1
                ELSE 0
            END
        ) * 1.0 / NULLIF(COUNT(*), 0) AS mortality_rate

    FROM admissions
    GROUP BY provider_id
),

-- =========================
-- DIAGNOSIS METRICS
-- =========================
diagnosis_metrics AS (
    SELECT
        provider_id,
        COUNT(*) AS total_diagnoses
    FROM diagnosis
    GROUP BY provider_id
),

-- =========================
-- LAB METRICS
-- =========================
lab_metrics AS (
    SELECT
        provider_id,
        COUNT(*) AS total_lab_orders
    FROM lab_events
    GROUP BY provider_id
),

-- =========================
-- PRESCRIPTION METRICS
-- =========================
prescription_metrics AS (
    SELECT
        provider_id,
        COUNT(*) AS total_prescriptions
    FROM prescriptions
    GROUP BY provider_id
)

-- =========================
-- FINAL MODEL
-- =========================
SELECT
    p.provider_id,

    p.provider_first_name,
    p.provider_last_name,
    p.provider_specialty,
    p.provider_city,
    p.provider_state_code,

    -- =====================
    -- CORE ACTIVITY
    -- =====================
    COALESCE(em.total_encounters, 0) AS total_encounters,
    COALESCE(em.unique_patients, 0) AS unique_patients,
    COALESCE(dm.total_diagnoses, 0) AS total_diagnoses,
    COALESCE(lm.total_lab_orders, 0) AS total_lab_orders,
    COALESCE(pm.total_prescriptions, 0) AS total_prescriptions,

    -- =====================
    -- PERFORMANCE METRICS
    -- =====================

    COALESCE(em.mortality_rate, 0) AS mortality_rate

FROM providers p

LEFT JOIN encounter_metrics em
    ON p.provider_id = em.provider_id

LEFT JOIN diagnosis_metrics dm
    ON p.provider_id = dm.provider_id

LEFT JOIN lab_metrics lm
    ON p.provider_id = lm.provider_id

LEFT JOIN prescription_metrics pm
    ON p.provider_id = pm.provider_id


