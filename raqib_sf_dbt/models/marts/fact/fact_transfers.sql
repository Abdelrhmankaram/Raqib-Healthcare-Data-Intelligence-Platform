SELECT
    {{ dbt_utils.generate_surrogate_key([
        't.transfer_id',
        't.patient_id',
        't.admission_id'
    ]) }}                                       AS transfer_key,

    t.transfer_id,
    dp.patient_key,
    ie.encounter_key,
    dd.date_key                                 AS transfer_date_key,
    dt.time_key                                 AS transfer_time_key,
    t.from_department,
    t.to_department,
    t.is_same_department_transfer,
    t.transfer_reason

FROM {{ ref('stg_transfers') }} t
LEFT JOIN {{ ref('dim_patients') }} dp
    ON t.patient_id = dp.patient_id
LEFT JOIN {{ ref('int_encounters') }} ie
    ON t.admission_id = ie.admission_id
LEFT JOIN {{ ref('dim_date') }} dd
    ON CAST(t.transfer_datetime AS DATE) = dd.date_bk
LEFT JOIN {{ ref('dim_time') }} dt
    ON CAST(t.transfer_datetime AS TIME) = dt.time_bk