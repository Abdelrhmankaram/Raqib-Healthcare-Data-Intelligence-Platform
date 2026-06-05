
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.accepted_values_stg_lab_events_abnormal_flag__High__Low__Normal
    
      
    ) dbt_internal_test