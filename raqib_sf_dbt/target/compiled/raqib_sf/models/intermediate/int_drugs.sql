WITH  __dbt__cte__stg_drugs as (
with raw_drugs as (
    select * 
    from raw.public.drugs
)

select 
    drug_id,
    case 
        when brand_name is not null then initcap(brand_name)
        when brand_name is null and generic_name like 'Atropine Sulfate Injection%' then 'AtroPen'
        when brand_name is null and generic_name like 'Midazolam Injection%' then 'Versed'
    end as brand_name,
    case 
        when generic_name is not null then initcap(generic_name) 
        when generic_name is null then brand_name
    end as generic_name,
    initcap(route) as route,
    indications,
    dosage,
    contraindications,
    side_effects,
    warnings,
    has_contraindications,
    has_side_effects
    
from raw_drugs
where not (
    generic_name = 'Tadalafil'
    AND brand_name is null
)
), stg_drugs AS (
     SELECT * 
     from __dbt__cte__stg_drugs
)

SELECT *
FROM stg_drugs