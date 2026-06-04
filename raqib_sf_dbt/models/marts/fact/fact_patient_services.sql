{{ config(materialized='incremental', unique_key='service_key') }}

WITH services AS (
    SELECT *
    FROM {{ ref('stg_services') }}
    WHERE rn = 1
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['s.service_id', 's.patient_id', 's.admission_id']) }} AS service_key,
    dp.patient_key,
    ie.encounter_key,
    dse.service_dim_key,
    s.cost,
    s.service_duration_in_minutes

FROM services s
LEFT JOIN {{ ref('dim_patients') }} dp
    ON s.patient_id = dp.patient_id
LEFT JOIN {{ ref('int_encounters') }} ie
    ON s.admission_id = ie.admission_id
LEFT JOIN {{ ref('dim_services') }} dse
    ON s.service_id = dse.service_id

{% if is_incremental() %}
  WHERE {{ dbt_utils.generate_surrogate_key(['s.service_id', 's.patient_id', 's.admission_id']) }} 
        NOT IN (SELECT service_key FROM {{ this }})
{% endif %}