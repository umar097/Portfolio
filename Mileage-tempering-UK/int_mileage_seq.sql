-- Intermediate: consecutive test pairs per vehicle.
-- For each test, LAG fetches the previous test's mileage (within the same
-- vehicle, ordered by date), and the delta is the change between them.
-- A negative delta means the odometer went down between tests -- the clocking signal.

SELECT
    vehicle_id,
    test_date,
    completed_date,
    test_mileage,
    make,
    model,
    postcode_area,
    first_use_date,
    LAG(test_mileage) OVER (
        PARTITION BY vehicle_id
        ORDER BY test_date, completed_date
    ) AS prev_mileage,
    test_mileage - LAG(test_mileage) OVER (
        PARTITION BY vehicle_id
        ORDER BY test_date, completed_date
    ) AS mileage_delta
FROM {{ ref('stg_tests') }}
QUALIFY prev_mileage IS NOT NULL   -- keep only rows that have a prior reading
