WITH raw_lab_specimen_types AS (
    SELECT *
    FROM {{ source('raw', 'raw_lab_specimen_types') }}
)

SELECT 
    itemid AS item_id,
    CASE 
        WHEN CONTAINS(label, '(') THEN TRIM(SPLIT_PART(label, '(', 1))
        ELSE label
    END AS label,
    CASE 
        WHEN CONTAINS(label, '(') THEN TRIM(REPLACE(SPLIT_PART(label, '(', 2), ')', ''))
        ELSE NULL
    END AS label_sub_type,
    fluid,
    CASE 
        WHEN CONTAINS(category, '–') THEN TRIM(SPLIT_PART(category, '–', 1))
        ELSE category
    END AS category_type,
    CASE   
        WHEN CONTAINS(category, '–') THEN TRIM(SPLIT_PART(category, '–', 2))
        ELSE NULL
    END AS category_sub_type,
    sub_domain_key,
    TRIM(SPLIT_PART(REGEXP_REPLACE(specialty, '\\s*/\\s*', ' & '), ' & ', 1)) AS specialty_1,
    NULLIF(TRIM(SPLIT_PART(REGEXP_REPLACE(specialty, '\\s*/\\s*', ' & '), ' & ', 2)), '') AS specialty_2,
    
FROM raw_lab_specimen_types

