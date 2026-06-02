WITH stg_drugs AS (
     SELECT * 
     from {{ ref('stg_drugs') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['drug_id']) }} AS drug_key,
    *
FROM stg_drugs