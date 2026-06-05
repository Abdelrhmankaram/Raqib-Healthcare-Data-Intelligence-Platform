
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from dev.dbt_dev__test_failures.accepted_values_stg_emergency__aa28b9ed11ddb231eaf72be10de000e8
    
      
    ) dbt_internal_test