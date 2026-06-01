
  create or replace   view dev.dbt_dev_intermediate.int_providers
  
  
  
  
  as (
    WITH stg_providers AS (
        SELECT *
        FROM dev.dbt_dev_staging.stg_providers
)

SELECT 
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
  );

