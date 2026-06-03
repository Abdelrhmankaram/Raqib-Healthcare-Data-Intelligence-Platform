SELECT
    DATEADD(DAY, SEQ4(), '2000-01-01'::DATE) AS date_key,
    
    YEAR(date_key) AS year,
    MONTH(date_key) AS month,
    MONTHNAME(date_key) AS month_name,
    DAYNAME(date_key) AS day_name,
    
    CASE 
        WHEN DAYOFWEEKISO(date_key) IN (6, 7) THEN 1 
        ELSE 0 
    END AS is_weekend
FROM TABLE(GENERATOR(ROWCOUNT => 10000)) 
WHERE date_key <= '2026-12-31'::DATE