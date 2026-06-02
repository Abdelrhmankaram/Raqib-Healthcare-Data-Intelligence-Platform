with  __dbt__cte__stg_transfers as (
WITH raw_transfers AS (
    SELECT *
    FROM raw.public.transfers
)

SELECT 
    transfer_id,
    patient_id,
    from_department,
    to_department,
    (from_department = to_department) AS is_same_department_transfer,
    CAST(transfer_datetime AS TIMESTAMP) AS transfer_datetime,
    transfer_reason
    
FROM raw_transfers
), stg_transfers as (
    select * 
    from __dbt__cte__stg_transfers
)

select 
    *

from stg_transfers