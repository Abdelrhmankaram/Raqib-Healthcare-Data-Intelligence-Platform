__dbt__cte__stg_providers as (
with raw_providers as (
    select * 
    from raw.public.providers
)

select 
    npi,
    initcap(provider_first_name) as provider_first_name,
    initcap(provider_last_name) as provider_last_name,
    initcap(provider_name_prefix) as provider_name_prefix,
    regexp_like(provider_name_prefix, '%.') as is_valid_prefix,
    initcap(provider_address) as provider_address,
    initcap(provider_city) as provider_city,
    trim(provider_state_code) as provider_state_code,
    trim(provider_country_code) as provider_country_code,
    provider_postal_code,
    case 
        when provider_sex_code = 'M' or provider_sex_code = 'm' then 'Male'
        when provider_sex_code = 'F' or provider_sex_code = 'f' then 'Female'
        else 'Unknown'
    end as provider_sex,
    provider_telephone_number,
    cast(provider_enumeration_date as date) as provider_enumeration_date,
    case 
        when TRY_TO_DATE(provider_enumeration_date, 'YYYY-MM-DD') is not null then TRUE
        else FALSE
    end as is_valid_enumeration_date,
    cast(provider_join_date as date) as provider_join_date,
    case 
        when TRY_TO_DATE(provider_join_date, 'YYYY-MM-DD') is not null then TRUE
        else FALSE
    end as is_valid_join_date,
    provider_specialty

from raw_providers
)