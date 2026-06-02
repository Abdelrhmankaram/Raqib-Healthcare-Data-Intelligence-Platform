with stg_transfers as (
    select * 
    from {{ ref('stg_transfers') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['transfer_id']) }} AS transfer_key,
    *

FROM stg_transfers