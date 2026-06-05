WITH lab_events AS (
    SELECT *
    FROM {{ ref('stg_lab_events') }}
),

specimen_types AS (
    SELECT *
    FROM {{ ref('stg_lab_specimen_types') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['lab_event_id']) }} AS lab_event_key,
    le.lab_event_id,
    le.patient_id,
    le.admission_id,
    le.provider_id,
    le.specimen_id,
    le.item_id,
    le.lab_done_at,
    le.lab_stored_at,

    st.label AS test_name,
    st.label_sub_type,
    st.fluid,
    st.category_type,
    st.category_sub_type,
    st.specialty_1,
    st.specialty_2,

    le.result_value,
    le.measurement_unit,

    le.range_lower,
    le.range_higher,

    le.abnormal_flag,

    le.cost

FROM lab_events le

LEFT JOIN specimen_types st
    ON le.item_id = st.item_id