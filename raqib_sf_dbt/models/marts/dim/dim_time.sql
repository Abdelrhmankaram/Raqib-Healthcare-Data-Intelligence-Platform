{{ config(materialized='table') }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['time_bk']) }} AS time_key,
    time_bk,
    hour,
    minute,
    second,
    time_of_day
FROM (
SELECT   
    TIMEADD(SECOND, SEQ4(), '00:00:00'::TIME) AS time_bk,
    
    HOUR(time_bk) AS hour,
    MINUTE(time_bk) AS minute,
    SECOND(time_bk) AS second,
    
    CASE 
        WHEN HOUR(time_bk) < 6 THEN 'Night'
        WHEN HOUR(time_bk) < 12 THEN 'Morning'
        WHEN HOUR(time_bk) < 18 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day

FROM TABLE(GENERATOR(ROWCOUNT => 86400))
)