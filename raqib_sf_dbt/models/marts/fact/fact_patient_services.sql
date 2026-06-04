WITH services AS (
    SELECT *
    FROM {{ ref('stg_services') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['s.service_id', 's.patient_id', 's.admission_id']) }} AS service_key,
    dp.patient_key,
    ie.encounter_key,
    s.service_id,
    s.patient_id,
    s.admission_id,
    s.cost,
    s.service_duration_in_minutes
FROM services s
LEFT JOIN {{ ref('dim_patients') }} dp ON s.patient_id = dp.patient_id
LEFT JOIN {{ ref('int_encounters') }} ie ON s.admission_id = ie.admission_id