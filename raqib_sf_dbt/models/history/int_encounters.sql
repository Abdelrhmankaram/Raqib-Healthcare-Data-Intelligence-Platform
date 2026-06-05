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
        {{ dbt_utils.generate_surrogate_key(['a.admission_id']) }}  AS encounter_key,
        a.admission_id,
        a.patient_id,
        a.provider_id,
        a.primary_sdk,
        a.admitted_at,
        a.discharged_at,

        CASE
            WHEN a.discharged_at IS NULL THEN TRUE
            ELSE FALSE
        END                                                         AS is_active_encounter,

        a.admission_type,
        a.admission_location,
        a.discharge_location,
        a.total_cost,
        a.payer_coverage,
        a.hospital_expire_flag,
        p.birthdate,
        pr.provider_specialty

    FROM admissions a
    LEFT JOIN patients p  ON a.patient_id  = p.patient_id
    LEFT JOIN providers pr ON a.provider_id = pr.provider_id
),

final AS (
    SELECT
        encounter_key,
        admission_id,
        patient_id,
        provider_id,
        primary_sdk,
        provider_specialty,

        admitted_at,
        discharged_at,
        is_active_encounter,

        DATEDIFF(
            'day',
            admitted_at,
            COALESCE(discharged_at, CURRENT_TIMESTAMP)
        )                                                           AS length_of_stay_days,

        admission_type,
        admission_location,
        discharge_location,

        total_cost,
        payer_coverage,

        ROUND(
            payer_coverage / NULLIF(total_cost, 0) * 100, 1
        )                                                           AS coverage_percentage,

        total_cost - payer_coverage                                 AS out_of_pocket_cost,

        DATEDIFF(
            'year',
            birthdate,
            admitted_at
        )                                                           AS age_at_admission,

        CASE
            WHEN DATEDIFF('year', birthdate, admitted_at) < 12
                THEN 'Child'
            WHEN DATEDIFF('year', birthdate, admitted_at) BETWEEN 12 AND 17
                THEN 'Teen'
            WHEN DATEDIFF('year', birthdate, admitted_at) BETWEEN 18 AND 60
                THEN 'Adult'
            ELSE 'Senior'
        END                                                         AS age_group,

        CASE
            WHEN hospital_expire_flag THEN 'Deceased'
            ELSE 'Alive'
        END                                                         AS discharge_status

    FROM base
)

SELECT *
FROM final