WITH stg_admissions AS (
    SELECT * 
    FROM {{ ref('stg_admissions') }}
),
stg_patients AS (
    SELECT *
    FROM {{ ref('stg_patients') }}
),
stg_providers AS (
    SELECT *
    FROM {{ ref('stg_providers') }}
)



SELECT 

    {{ dbt_utils.generate_surrogate_key(['admission_id']) }} AS encounter_key,

    sa.admission_id,
    sa.patient_id,
    sa.provider_id,
    sa.admitted_in_timestamp,
    YEAR(sa.admitted_in_timestamp) AS encounter_year,
    MONTH(sa.admitted_in_timestamp) AS encounter_month,
    DAY_OF_WEEK(sa.admitted_in_timestamp) AS encounter_day_of_week,
        AS encounter_sequence_number
    sa.admitted_out_timestamp,
    DATEDIFF(
        'day',
        sa.admitted_in_timestamp,
        sa.admitted_out_timestamp
    ) AS stay_duration_days,
    DATEDIFF(
        'hour',
        sa.admitted_in_timestamp,
        sa.admitted_out_timestamp
    ) AS stay_duration_hours,
    sa.admission_type,
    sa.admission_location,
    sa.discharge_location,
    sa.insurance_type,
    sa.total_cost,
    sa.payer_coverage,
    ( sa.total_cost - sa.payer_coverage ) AS patient_out_of_pocket_cost,
    ( sa.payer_coverage / NULLIF(sa.total_cost, 0) ) AS coverage_percentage,
    sa.hospital_expire_flag,
    sa.primary_sdk,

    DATEDIFF(
        'year',
       sp.birthdate,
       CURRENT_DATE()
    ) AS age_at_admission,

    CONCAT_WS (
        ' ',
        spr.provider_name_prefix,
        spr.provider_first_name,
        spr.provider_last_name
    ) AS provider_full_name,

FROM stg_admissions sa
LEFT JOIN stg_patients sp ON sa.patient_id = sp.patient_id 
LEFT JOIN stg_providers spr ON sa.provider_id = spr.npi