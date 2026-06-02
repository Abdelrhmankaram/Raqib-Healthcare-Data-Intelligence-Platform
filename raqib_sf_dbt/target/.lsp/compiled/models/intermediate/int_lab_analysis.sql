with __dbt__cte__stg_lab_events as (
WITH raw_lab_events AS (

    SELECT *
    FROM raw.public.lab_events

)

SELECT
    lab_event_id,
    patient_id,
    admission_id,
    specimen_id,
    item_id,
    provider_id,
    CONVERT_TIMEZONE('UTC', done_datetime::TIMESTAMP_TZ)    AS lab_done_at,
    CONVERT_TIMEZONE('UTC', stored_datetime::TIMESTAMP_TZ)  AS lab_stored_at,
    TRY_CAST(value AS FLOAT) AS result_value,
    TRIM(measurement_unit) AS measurement_unit,
    TRY_CAST(range_lower AS FLOAT) AS range_lower,
    TRY_CAST(range_higher AS FLOAT) AS range_higher,
    TRIM(abnormal_flag) AS abnormal_flag,
    TRY_CAST(cost AS FLOAT) AS cost

FROM raw_lab_events 

), __dbt__cte__stg_lab_specimen_types as (
WITH raw_lab_specimen_types AS (
    SELECT *
    FROM raw.public.lab_specimen_types
)

SELECT 
    itemid AS item_id,
    CASE 
        WHEN CONTAINS(label, '(') THEN TRIM(SPLIT_PART(label, '(', 1))
        ELSE label
    END AS label,
    CASE 
        WHEN CONTAINS(label, '(') THEN TRIM(REPLACE(SPLIT_PART(label, '(', 2), ')', ''))
        ELSE NULL
    END AS label_sub_type,
    fluid,
    CASE 
        WHEN CONTAINS(category, '–') THEN TRIM(SPLIT_PART(category, '–', 1))
        ELSE category
    END AS category_type,
    CASE   
        WHEN CONTAINS(category, '–') THEN TRIM(SPLIT_PART(category, '–', 2))
        ELSE NULL
    END AS category_sub_type,
    sub_domain_key,
    TRIM(SPLIT_PART(REGEXP_REPLACE(specialty, '\\s*/\\s*', ' & '), ' & ', 1)) AS specialty_1,
    NULLIF(TRIM(SPLIT_PART(REGEXP_REPLACE(specialty, '\\s*/\\s*', ' & '), ' & ', 2)), '') AS specialty_2,
    
FROM raw_lab_specimen_types

)
--EPHEMERAL-SELECT-WRAPPER-START
select * from (
WITH lab_events AS (
    SELECT *
    FROM __dbt__cte__stg_lab_events
),

specimen_types AS (
    SELECT *
    FROM __dbt__cte__stg_lab_specimen_types
)

SELECT
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
--EPHEMERAL-SELECT-WRAPPER-END
)