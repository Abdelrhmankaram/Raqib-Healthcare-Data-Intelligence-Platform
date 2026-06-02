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

        -- Keys
        admission_id,
        patient_id,
        provider_id,
        primary_sdk,

        -- Provider
        provider_specialty,

        -- Admission timestamps
        admitted_in_timestamp,
        admitted_out_timestamp,

        -- Date attributes
        YEAR(admitted_in_timestamp) AS encounter_year,
        TRIM(TO_CHAR(admitted_in_timestamp, 'Mon')) AS encounter_month,
        TRIM(TO_CHAR(admitted_in_timestamp, 'DY')) AS encounter_day_of_week,

        -- Length of stay
        DATEDIFF(
            'day',
            admitted_in_timestamp,
            admitted_out_timestamp
        ) AS stay_duration_days,

        DATEDIFF(
            'hour',
            admitted_in_timestamp,
            admitted_out_timestamp
        ) AS stay_duration_hours,

        -- Admission details
        admission_type,
        admission_location,
        discharge_location,

        -- Financial metrics
        total_cost,
        payer_coverage,

        TO_VARCHAR(
            ROUND(payer_coverage / NULLIF(total_cost, 0) * 100, 1) || '%'
        ) AS coverage_percentage,

        total_cost - payer_coverage
            AS patient_out_of_pocket_cost,

        -- Patient age at encounter
        DATEDIFF(
            'year',
            birthdate,
            admitted_in_timestamp
        ) AS age_at_admission,

        CASE
            WHEN hospital_expire_flag
            THEN 'Deceased'
            ELSE 'Alive'
        END AS discharge_status

    FROM base

),

final_with_age_group AS (

    SELECT

        *,

        CASE
            WHEN age_at_admission < 12 THEN 'Child'
            WHEN age_at_admission BETWEEN 12 AND 17 THEN 'Teen'
            WHEN age_at_admission BETWEEN 18 AND 60 THEN 'Adult'
            ELSE 'Senior'
        END AS age_group

    FROM final

)

SELECT *
FROM final_with_age_group