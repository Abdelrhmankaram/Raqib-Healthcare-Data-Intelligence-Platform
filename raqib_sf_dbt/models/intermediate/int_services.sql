with stg_services as (
    select * 
    from {{ ref('stg_services') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['service_id']) }} AS service_key,
    * 
FROM stg_services