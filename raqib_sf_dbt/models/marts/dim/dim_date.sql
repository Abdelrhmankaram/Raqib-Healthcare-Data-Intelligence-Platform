{{ config(materialized='table') }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['date_bk']) }} AS date_key,
    date_bk,
    year,
    month,
    month_name,
    day_name, 
    is_weekend 
FROM (
SELECT
    DATEADD(DAY, SEQ4(), '2000-01-01'::DATE) AS date_bk,
    
    YEAR(date_bk) AS year,
    MONTH(date_bk) AS month,
    MONTHNAME(date_bk) AS month_name,
    DAYNAME(date_bk) AS day_name,
    
    CASE 
        WHEN DAYOFWEEKISO(date_bk) IN (6, 7) THEN 1 
        ELSE 0 
    END AS is_weekend
FROM TABLE(GENERATOR(ROWCOUNT => 10000))
WHERE date_bk <= '2026-12-31'::DATE
)