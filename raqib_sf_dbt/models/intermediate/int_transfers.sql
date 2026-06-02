with stg_transfers as (
    select * 
    from {{ ref('stg_transfers') }}
)

select 
    *

from stg_transfers