__dbt__cte__stg_transfers as (
WITH raw_transfers AS (
    SELECT *
    FROM raw.public.transfers
)

SELECT 
    transfer_id,
    patient_id,
    provider_id,
    from_department,
    to_department,
    (from_department = to_department) AS is_same_department_transfer,
    from_room,
    to_room,
    (from_room = to_room) AS is_same_room_transfer,
    REGEXP_LIKE(from_room, '^R[0-9]+$') AND REGEXP_LIKE(to_room, '^R[0-9]+$') AS is_valid_room,
    CAST(transfer_datetime AS TIMESTAMP) AS transfer_datetime,
    transfer_reason
    
FROM raw_transfers


)