__dbt__cte__stg_lab_specimen_types as (
WITH raw_lab_specimen_types AS (
    SELECT *
    FROM raw.public.lab_specimen_types
)

SELECT 
    itemid AS item_id,
    label,
    fluid,
    category,
    sub_domain_key,
    specialty
    
FROM raw_lab_specimen_types
)