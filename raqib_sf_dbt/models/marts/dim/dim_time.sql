SELECT
    TIMEADD(SECOND, SEQ4(), '00:00:00'::TIME) AS time_key,
    
    HOUR(time_key) AS hour,
    MINUTE(time_key) AS minute,
    SECOND(time_key) AS second,
    
    CASE 
        WHEN HOUR(time_key) < 6 THEN 'Night'
        WHEN HOUR(time_key) < 12 THEN 'Morning'
        WHEN HOUR(time_key) < 18 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_of_day
FROM TABLE(GENERATOR(ROWCOUNT => 86400))