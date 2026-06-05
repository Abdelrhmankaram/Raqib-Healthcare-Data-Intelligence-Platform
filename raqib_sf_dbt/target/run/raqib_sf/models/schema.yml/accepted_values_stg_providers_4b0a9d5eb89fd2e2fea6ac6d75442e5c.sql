
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.accepted_values_stg_providers_4b0a9d5eb89fd2e2fea6ac6d75442e5c
    
      
    ) dbt_internal_test