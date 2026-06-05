
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.accepted_values_stg_emergency__e1cfa9bf281542b36e4418459726aa63
    
      
    ) dbt_internal_test