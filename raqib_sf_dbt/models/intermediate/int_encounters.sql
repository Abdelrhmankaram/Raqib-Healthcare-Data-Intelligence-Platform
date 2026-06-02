WITH admissions AS (

    SELECT *
    FROM {{ ref('stg_admissions') }}

),

patients AS (

    SELECT *
    FROM {{ ref('stg_patients') }}

),

providers AS (

    SELECT *
    FROM {{ ref('stg_providers') }}

),

base AS (

    SELECT
        a.admission_id,
        a.patient_id,
        a.provider_id,

        a.primary_sdk,

        a.admitted_in_timestamp,
        a.admitted_out_timestamp,

        CASE
            WHEN a.admitted_out_timestamp IS NULL THEN TRUE
            ELSE FALSE
        END AS is_active_encounter,

        a.admission_type,
        a.admission_location,
        a.discharge_location,

        a.total_cost,
        a.payer_coverage,
        a.hospital_expire_flag,

        p.birthdate,

        pr.provider_specialty

    FROM admissions a

    LEFT JOIN patients p
        ON a.patient_id = p.patient_id

    LEFT JOIN providers pr
        ON a.provider_id = pr.provider_id

),

final AS (

    SELECT

        -- Business Keys
        admission_id,
        patient_id,
        provider_id,

        -- Clinical Context
        primary_sdk,
        provider_specialty,

        -- Encounter Timing
        admitted_in_timestamp AS admitted_at,
        admitted_out_timestamp AS discharged_at,

        is_active_encounter,

        DATEDIFF(
            'day',
            admitted_in_timestamp,
            COALESCE(
                admitted_out_timestamp,
                CURRENT_TIMESTAMP
            )
        ) AS length_of_stay_days,

        -- Admission Details
        admission_type,
        admission_location,
        discharge_location,

        -- Financial Metrics
        total_cost,

        payer_coverage,

        ROUND(
            payer_coverage
            / NULLIF(total_cost, 0) * 100,
            1
        ) AS coverage_percentage,

        total_cost - payer_coverage
            AS out_of_pocket_cost,

        -- Patient Age at Encounter
        DATEDIFF(
            'year',
            birthdate,
            admitted_in_timestamp
        ) AS age_at_admission,

        CASE
            WHEN age_at_admission < 12 THEN 'Child'
            WHEN age_at_admission BETWEEN 12 AND 17 THEN 'Teen'
            WHEN age_at_admission BETWEEN 18 AND 60 THEN 'Adult'
            ELSE 'Senior'
        END AS age_group,

        -- Encounter Outcome
        CASE
            WHEN hospital_expire_flag THEN 'Deceased'
            ELSE 'Alive'
        END AS discharge_status

    FROM base

)

SELECT *
FROM final