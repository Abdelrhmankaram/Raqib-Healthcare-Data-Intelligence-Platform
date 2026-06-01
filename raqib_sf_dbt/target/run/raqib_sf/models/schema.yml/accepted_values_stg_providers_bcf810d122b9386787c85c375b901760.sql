
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.accepted_values_stg_providers_bcf810d122b9386787c85c375b901760
    
      
    ) dbt_internal_test