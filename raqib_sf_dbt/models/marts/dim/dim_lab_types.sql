WITH stg_lab_specimen_types AS (
    SELECT *
    FROM {{ ref('stg_lab_specimen_types') }}
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['item_id', 'label', 'category_type']) }} AS specimen_type_key,
    item_id,
    label,
    label_sub_type,
    fluid,
    category_type,
    category_sub_type,
    sub_domain_key,
    specialty_1,
    specialty_2
FROM stg_lab_specimen_types