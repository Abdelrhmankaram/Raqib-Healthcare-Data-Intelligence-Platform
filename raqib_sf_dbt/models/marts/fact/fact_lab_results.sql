SELECT
    lr.lab_event_key,
    ie.encounter_key,
    dp.patient_key,
    dpr.provider_key,
    dst.specimen_type_key,
    dd.date_key AS lab_date_key,
    dt.time_key AS lab_time_key,

    lr.lab_done_at,
    lr.lab_stored_at,
    lr.test_name,
    lr.label_sub_type,
    lr.fluid,
    lr.category_type,
    lr.category_sub_type,
    lr.specialty_1,
    lr.specialty_2,
    lr.result_value,
    lr.measurement_unit,
    lr.range_lower,
    lr.range_higher,
    lr.abnormal_flag,
    lr.cost

FROM {{ ref('int_lab_analysis') }} lr
LEFT JOIN {{ ref('int_encounters') }} ie
    ON lr.admission_id = ie.admission_id
LEFT JOIN {{ ref('dim_patients') }} dp
    ON lr.patient_id = dp.patient_id
LEFT JOIN {{ ref('dim_provider') }} dpr
    ON lr.provider_id = dpr.provider_id
LEFT JOIN {{ ref('dim_lab_types') }} dst
    ON lr.item_id = dst.item_id
LEFT JOIN {{ ref('dim_date') }} dd
    ON CAST(lr.lab_done_at AS DATE) = dd.date_bk
LEFT JOIN {{ ref('dim_time') }} dt
    ON CAST(lr.lab_done_at AS TIME) = dt.time_bk