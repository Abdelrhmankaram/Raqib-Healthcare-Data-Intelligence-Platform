WITH raw_lab_events AS (

    SELECT *
    FROM {{ sourece('raw', 'raw_lab_events') }}

),
renamed_cols AS (

    SELECT 
        lab_event_id,
        patient_id,
        admission_id,
        specimen_id,
        item_id,
        done_datetime AS lab_done_at,
        stored_datetime AS lab_stored_at,
        value AS result_value,
        measurement_unit,
        range_lower,
        range_higher,
        abnormal_flag

    FROM raw_lab_events

)

SELECT
    lab_event_id,
    patient_id,
    admission_id,
    specimen_id,
    item_id,
    TRY_CAST(lab_done_at AS TIMESTAMP) AS lab_done_at,
    TRY_CAST(lab_stored_at AS TIMESTAMP) AS lab_stored_at,
    result_value,
    TRIM(measurement_unit) AS measurement_unit,
    TRY_CAST(range_lower AS FLOAT) AS range_lower,
    TRY_CAST(range_higher AS FLOAT) AS range_higher,
    TRIM(abnormal_flag) AS abnormal_flag     

FROM renamed_cols

