with services as (
    select *
    from {{ ref('int_services') }}
)

select    service_key,
        service_name,
     service_sub_type,
     category, 
     from services
