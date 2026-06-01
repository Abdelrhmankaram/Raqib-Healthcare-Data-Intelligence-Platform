
    
    

with all_values as (

    select
        provider_sex as value_field,
        count(*) as n_records

    from dev.dbt_dev_staging.stg_providers
    group by provider_sex

)

select *
from all_values
where value_field not in (
    'Female','Male','Unknown'
)


