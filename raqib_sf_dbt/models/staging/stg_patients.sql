with raw_patients as (
    select *
    from {{ source('raw', 'raw_patients') }}
)

select 
    patient_id,
    initcap(first_name || ' ' || last_name) as full_name,
    try_to_date(birthdate) as birthdate,
    year(try_to_date(birthdate)) as birth_year,
    case 
        when deathdate is not null then true
        else false
    end as is_dead,
    try_to_date(deathdate) as deathdate,
    ssn,
    blood_type,
    case 
        when marital = 'S' then 'Single'
        when marital = 'M' then 'Married'
        when marital = 'D' then 'Divorced'
        when marital = 'W' then 'Widowed'
    end as marital_status,
    initcap(replace(race, '/', ' / ')) AS race,
    case
        when upper(trim(ethnicity)) in ('HISPANIC', 'HISPANIC OR LATINO')
            then 'Hispanic or Latino'
        when upper(trim(ethnicity)) in ('NONHISPANIC', 'NOT HISPANIC OR LATINO')
            then 'Not Hispanic or Latino'
        else 'Unknown'
    end as ethnicity,
    case 
        when gender = 'F' then 'Female'
        when gender = 'M' then 'Male'
        else 'Unknown'
    end as gender,
    initcap(language) as spoken_language,
    trim(regexp_replace(regexp_replace(birthplace, ',', ''), '\\s+\\S+$', '')) AS birth_city,
    address,
    initcap(city) as city,
    initcap(country) as country,
    healthcare_expenses,
    healthcare_coverage,
    income as income_usd
  
from raw_patients