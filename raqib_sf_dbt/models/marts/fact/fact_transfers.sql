with fact_transfers as (
    select 
        "" as transfer_id,
        patient_id,
        provider_id,
        admission_id,
        transfer_date_key,

        from_department,
        to_department,
        from_room,
        to_room,
        transfer_reason
)