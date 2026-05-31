
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.accepted_values_emergency_cont_85868add8ba9d96a326ae036898efd1e
    
      
    ) dbt_internal_test