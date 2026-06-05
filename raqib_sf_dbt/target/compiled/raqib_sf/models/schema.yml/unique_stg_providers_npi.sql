
    
    

select
    npi as unique_field,
    count(*) as n_records

from dev.dbt_dev_staging.stg_providers
where npi is not null
group by npi
having count(*) > 1


