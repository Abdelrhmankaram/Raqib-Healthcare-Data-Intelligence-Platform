with raw_drugs as (
    select * 
    from {{ source('raw', 'raw_drugs') }}
)

select 
    drug_id,
    case 
        when brand_name is not null then initcap(brand_name)
        when brand_name is null and generic_name ilike 'Atropine Sulfate Injection%' then 'AtroPen'
        when brand_name is null and generic_name ilike 'Midazolam Injection%' then 'Versed'
        when brand_name is null and generic_name = 'Tadalafil' then 'Cialis'
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