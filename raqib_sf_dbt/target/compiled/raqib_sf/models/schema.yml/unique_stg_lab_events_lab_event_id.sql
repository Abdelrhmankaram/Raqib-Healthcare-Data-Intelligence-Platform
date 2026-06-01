
    
    

select
    lab_event_id as unique_field,
    count(*) as n_records

from dev.dbt_dev_staging.stg_lab_events
where lab_event_id is not null
group by lab_event_id
having count(*) > 1


