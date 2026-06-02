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

SELECT
    md5(cast(coalesce(cast(transfer_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS transfer_key,
    *

FROM stg_transfers