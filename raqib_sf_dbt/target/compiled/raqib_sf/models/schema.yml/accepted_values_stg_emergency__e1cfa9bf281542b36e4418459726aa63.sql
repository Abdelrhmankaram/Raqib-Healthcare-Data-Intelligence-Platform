
    
    

with all_values as (

    select
        is_valid_phone_number as value_field,
        count(*) as n_records

    from dev.dbt_dev_staging.stg_emergency_contacts
    group by is_valid_phone_number

)

select *
from all_values
where value_field not in (
    'True','False'
)


