WITH DateRange AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS Offset
    FROM TABLE(GENERATOR(ROWCOUNT => 50000))
),
Dates AS (
    SELECT
        DATEADD(DAY, Offset, '2015-01-01'::DATE) AS Date_Val
    FROM DateRange
)

SELECT
    TO_NUMBER(TO_CHAR(Date_Val, 'YYYYMMDD')) AS DATE_KEY,
    Date_Val AS FULL_DATE,

    DAY(Date_Val) AS DAY,
    MONTH(Date_Val) AS MONTH,
    MONTHNAME(Date_Val) AS MONTH_NAME,

    QUARTER(Date_Val) AS QUARTER,
    YEAR(Date_Val) AS YEAR,

    WEEKOFYEAR(Date_Val) AS WEEK_NUMBER,

    /* Day number within week (Monday=1 ... Sunday=7) */
    DAYOFWEEKISO(Date_Val) AS DAY_NUMBER,

    CASE DAYNAME(Date_Val)
        WHEN 'Mon' THEN 'Monday'
        WHEN 'Tue' THEN 'Tuesday'
        WHEN 'Wed' THEN 'Wednesday'
        WHEN 'Thu' THEN 'Thursday'
        WHEN 'Fri' THEN 'Friday'
        WHEN 'Sat' THEN 'Saturday'
        WHEN 'Sun' THEN 'Sunday'
    END AS DAY_NAME,

    CASE
        WHEN DAYOFWEEKISO(Date_Val) IN (6, 7) THEN 1
        ELSE 0
    END AS IS_WEEKEND

FROM Dates
WHERE Date_Val <= '2026-12-31'::DATE
ORDER BY DATE_KEY