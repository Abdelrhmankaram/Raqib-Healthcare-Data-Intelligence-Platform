
    
    

with all_values as (

    select
        emergency_contact_bloodtype as value_field,
        count(*) as n_records

    from dev.dbt_dev_staging.stg_emergency_contacts
    group by emergency_contact_bloodtype

)

select *
from all_values
where value_field not in (
    'A+','AB+','B+','O+','O-','AB-','A-','B-'
)


