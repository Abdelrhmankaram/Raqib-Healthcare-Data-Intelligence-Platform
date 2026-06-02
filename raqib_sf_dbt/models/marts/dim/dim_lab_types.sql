with stg_lab_specimen_types as (
    select *
    from {{ ref('stg_lab_specimen_types') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['item_id', 'label', 'category']) }} AS specimen_type_key,
    *

from stg_lab_specimen_types