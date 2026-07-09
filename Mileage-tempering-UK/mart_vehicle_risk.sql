-- Mart: final scored output, one row per credible clocking event.
-- Risk score (0-100) is transparent and rules-based:
--   70% weight on the PROPORTION of mileage erased (pct_erased)
--   30% weight on the ABSOLUTE miles removed (capped at 150k so outliers can't dominate)
-- A transparent score is deliberate: a flag can always be justified in plain terms.

SELECT
    vehicle_id,
    make,
    model,
    postcode_area,
    prev_mileage,
    test_mileage,
    mileage_delta,
    ABS(mileage_delta) AS miles_removed,
    ROUND(100.0 * ABS(mileage_delta) / NULLIF(prev_mileage, 0), 1) AS pct_erased,
    ROUND(
        LEAST(
            100,
            (100.0 * ABS(mileage_delta) / NULLIF(prev_mileage, 0)) * 0.7
            + (LEAST(ABS(mileage_delta), 150000) / 150000.0 * 30)
        ),
        1
    ) AS risk_score
FROM {{ ref('int_clocking_events') }}
ORDER BY risk_score DESC, miles_removed DESC
