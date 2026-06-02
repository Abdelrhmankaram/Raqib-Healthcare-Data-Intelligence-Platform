WITH stg_drugs AS (
     SELECT * 
     from {{ ref('stg_drugs') }}
)

SELECT *
FROM stg_drugs