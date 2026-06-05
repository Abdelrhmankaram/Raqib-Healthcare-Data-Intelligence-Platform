
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.not_null_stg_lab_events_lab_event_id
    
      
    ) dbt_internal_test