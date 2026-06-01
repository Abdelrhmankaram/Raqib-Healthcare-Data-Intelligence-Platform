with stg_lab_events AS (
    SELECT *
    FROM {{ ref('stg_lab_events') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['lab_event_id']) }} AS lab_event_key,
    *
FROM stg_lab_events