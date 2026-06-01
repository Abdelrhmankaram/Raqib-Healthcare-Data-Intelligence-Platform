
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.unique_stg_providers_npi
    
      
    ) dbt_internal_test