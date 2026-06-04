WITH patients AS (
    SELECT
        patient_id,
        healthcare_expenses,
        healthcare_coverage,
        income_usd
    FROM {{ ref('stg_patients') }}
),

encounter_finances AS (
    SELECT
        patient_id,
        SUM(total_cost)          AS total_admissions_cost,
        SUM(payer_coverage)      AS total_payer_coverage,
        SUM(out_of_pocket_cost)  AS total_out_of_pocket,
        AVG(coverage_percentage) AS avg_coverage_percentage
    FROM {{ ref('int_encounters') }}
    GROUP BY patient_id
)

SELECT
    {{ dbt_utils.generate_surrogate_key(['p.patient_id']) }} AS patient_key,
    p.patient_id,
    p.healthcare_expenses,
    p.healthcare_coverage,
    p.income_usd,
    COALESCE(ef.total_admissions_cost, 0)    AS total_admissions_cost,
    COALESCE(ef.total_payer_coverage, 0)     AS total_payer_coverage,
    COALESCE(ef.total_out_of_pocket, 0)      AS total_out_of_pocket,
    COALESCE(ef.avg_coverage_percentage, 0)  AS avg_coverage_percentage
FROM patients p
LEFT JOIN encounter_finances ef ON p.patient_id = ef.patient_id