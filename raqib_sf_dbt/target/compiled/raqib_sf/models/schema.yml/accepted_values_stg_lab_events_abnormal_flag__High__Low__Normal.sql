
    
    

with all_values as (

    select
        abnormal_flag as value_field,
        count(*) as n_records

    from dev.dbt_dev_staging.stg_lab_events
    group by abnormal_flag

)

select *
from all_values
where value_field not in (
    'High','Low','Normal'
)


