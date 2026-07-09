-- Staging: both years of MOT test records unioned and typed.
-- Reads from the pre-loaded raw tables (tests_2024, tests_2025) built during ingestion.

SELECT
    vehicle_id,
    test_date,
    completed_date,
    test_mileage,
    make,
    model,
    postcode_area,
    first_use_date
FROM tests_2024

UNION ALL

SELECT
    vehicle_id,
    test_date,
    completed_date,
    test_mileage,
    make,
    model,
    postcode_area,
    first_use_date
FROM tests_2025
