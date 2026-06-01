with stg_transfers as (
    select * 
    from {{ ref('stg_transfers') }}
)

select 
    {{ dbt_utils.generate_surrogate_key(['transfer_id']) }} AS transfer_key,
    *

from stg_transfers