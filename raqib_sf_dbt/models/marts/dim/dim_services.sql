with services as (

    select
        service_id,
        service_name,
        service_sub_type,
        category,
        row_number() over (
            partition by service_id
            order by service_name asc
        ) as rn
    from {{ ref('stg_services') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['service_id']) }} as service_dim_key,
    service_id,
    service_name,
    service_sub_type,
    category
from services
where rn = 1

{% if is_incremental() %}
    and {{ dbt_utils.generate_surrogate_key(['service_id']) }} not in (select service_dim_key from {{ this }})
{% endif %}

