{{ config(unique_key='provider_key') }}

WITH stg_providers AS (
    SELECT *
    FROM {{ ref('stg_providers') }}
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['provider_id', 'provider_full_name', 'provider_specialty']) }} AS provider_key,
    *
FROM stg_providers

    {% if is_incremental() %}
        WHERE {{ dbt_utils.generate_surrogate_key(['provider_id', 'provider_full_name', 'provider_specialty']) }} NOT IN (SELECT provider_key FROM {{ this }})
    {% endif %}