WITH stg_providers AS (
        SELECT *
        FROM {{ ref('stg_providers') }}
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['provider_id']) }} AS provider_key,
    npi,
    provider_first_name,
    provider_last_name,
    provider_name_prefix,
    CONCAT_WS (
        ' ',
        provider_name_prefix,
        provider_first_name,
        provider_last_name
    ) AS provider_full_name,
    is_valid_prefix,
    provider_address,
    provider_city,
    provider_state_code,
    provider_country_code,
    provider_postal_code,
    provider_sex,
    provider_telephone_number,
    provider_enumeration_date,
    provider_join_date,
    DATEDIFF(
        'year',
        provider_join_date,
        CURRENT_DATE
    ) AS provider_tenure_years,
    is_valid_join_date,
    provider_specialty
FROM stg_providers