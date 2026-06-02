WITH raw_lab_events AS (

    SELECT *
    FROM {{ source('raw', 'raw_lab_events') }}

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

