
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.not_null_emergency_contacts_emergency_contact_phone_number
    
      
    ) dbt_internal_test