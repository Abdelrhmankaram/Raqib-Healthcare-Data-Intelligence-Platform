WITH stg_prescriptions AS (
    SELECT *
    FROM {{ ref('stg_prescriptions') }}
)

SELECT *
FROM stg_prescriptions