
    
    

with all_values as (

    select
        is_valid_enumeration_date as value_field,
        count(*) as n_records

    from dev.dbt_dev_staging.stg_providers
    group by is_valid_enumeration_date

)

select *
from all_values
where value_field not in (
    'True','False'
)


