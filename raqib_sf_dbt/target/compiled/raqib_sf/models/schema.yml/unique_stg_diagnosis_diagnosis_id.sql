
    
    

select
    diagnosis_id as unique_field,
    count(*) as n_records

from dev.dbt_dev_staging.stg_diagnosis
where diagnosis_id is not null
group by diagnosis_id
having count(*) > 1


