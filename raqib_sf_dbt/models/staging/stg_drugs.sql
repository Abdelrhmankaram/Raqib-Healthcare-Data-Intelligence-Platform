with raw_drugs as (
    select * 
    from {{ source('raw', 'drugs') }}
)

select 
    case 
        when brand_name is not null then initcap(brand_name)
        when brand_name is null and generic_name like 'Atropine Sulfate Injection%' then 'AtroPen'
        when brand_name is null and generic_name like 'Midazolam Injection%' then 'Versed'
    end as brand_name,
    initcap(generic_name) as generic_name,
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