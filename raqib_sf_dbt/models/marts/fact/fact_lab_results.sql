WITH lab_events AS (
    SELECT *
    FROM {{ ref('stg_lab_events') }}
),

specimen_types AS (
    SELECT *
    FROM {{ ref('stg_lab_specimen_types') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['lab_event_id']) }} AS lab_event_id,
    {{dbt_utils.generate_surrogate_key(['patient_id']) }} AS patient_id,
    {{dbt_utils.generate_surrogate_key(['admission_id']) }} AS admission_id,
    {{dbt_utils.generate_surrogate_key(['provider_id']) }} AS provider_id,

    {{dbt_utils.generate_surrogate_key(['specimen_id']) }} AS specimen_id,
    le.item_id,

    le.lab_done_at as done_date_at,
    le.lab_stored_at as stored_date_at,

    le.result_value,
    le.measurement_unit,

    le.range_lower,
    le.range_higher,

    le.abnormal_flag,

FROM lab_events le

LEFT JOIN specimen_types st
    ON le.item_id = st.item_id