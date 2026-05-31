
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.accepted_values_emergency_cont_958653ea746f4e5fd4084f9f4edcc825
    
      
    ) dbt_internal_test