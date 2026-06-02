with emergency_contacts as (
    select * 
    from {{ ref('int_emergency_contacts') }}
)

SELECT
    *
    FROM emergency_contacts


    