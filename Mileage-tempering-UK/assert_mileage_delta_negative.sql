-- Business-rule assertion: every clocking event must be a genuine mileage drop.
-- A dbt test passes when it returns zero rows; any row here is a violation.

SELECT
    vehicle_id,
    mileage_delta
FROM {{ ref('int_clocking_events') }}
WHERE mileage_delta >= 0
