
    
    

select
    item_id as unique_field,
    count(*) as n_records

from dev.dbt_dev_staging.stg_lab_specimen_types
where item_id is not null
group by item_id
having count(*) > 1


