__dbt__cte__stg_providers as (
WITH raw_providers AS (
    SELECT * 
    FROM raw.public.providers
)

SELECT 
    npi AS provider_id,
    INITCAP(provider_first_name) AS provider_first_name,
    INITCAP(provider_last_name) AS provider_last_name,
    INITCAP(provider_name_prefix) AS provider_name_prefix,
    REGEXP_LIKE(provider_name_prefix, '\\.$') AS is_valid_prefix,
    INITCAP(provider_address) AS provider_address,
    INITCAP(provider_city) AS provider_city,
    TRIM(provider_state_code) AS provider_state_code,
    TRIM(provider_country_code) AS provider_country_code,
    provider_postal_code,
    CASE 
        WHEN provider_sex_code = 'M' OR provider_sex_code = 'm' THEN 'Male'
        WHEN provider_sex_code = 'F' OR provider_sex_code = 'f' THEN 'Female'
        ELSE 'Unknown'
    END AS provider_sex,
    provider_telephone_number,
    CAST(provider_enumeration_date AS DATE) AS provider_enumeration_date,
    CASE 
        WHEN CAST(provider_enumeration_date AS DATE) IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS is_valid_enumeration_date,
    CAST(provider_join_date AS DATE) AS provider_join_date,
    CASE 
        WHEN DATE(provider_join_date, 'YYYY-MM-DD') IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS is_valid_join_date,
    provider_specialty

FROM raw_providers
)