with insurance as (
    select *
    from {{ ref('stg_admissions') }}
)
select 
    dbt_utils.surrogate_key([ 'insurance_type', 'payer_coverage']) AS insurance_key,
    insurance_type,
    payer_coverage

from insurance