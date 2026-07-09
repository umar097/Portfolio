-- Intermediate: credible clocking candidates.
-- Starts from every mileage drop, then removes the data-quality artefacts
-- identified during analysis, leaving only plausible genuine rollbacks.

SELECT
    vehicle_id,
    test_date,
    make,
    model,
    postcode_area,
    prev_mileage,
    test_mileage,
    mileage_delta,
    first_use_date
FROM {{ ref('int_mileage_seq') }}
WHERE mileage_delta < 0                                              -- a genuine drop
  AND test_mileage >= 1000                                          -- remaining reading must be plausible (removes near-zero junk)
  AND mileage_delta <= -50                                          -- ignore trivial typos under 50 miles
  AND (100.0 * ABS(mileage_delta) / NULLIF(prev_mileage, 0)) <= 90  -- exclude near-total wipes (data corruption, not fraud)
  AND NOT (
        ROUND(prev_mileage::DOUBLE / NULLIF(test_mileage, 0), 2)
        BETWEEN 1.60 AND 1.62                                       -- exclude km/mile unit switches (1.609 conversion)
      )
  AND prev_mileage <= 300000                                        -- implausible prior reading = bad data
  AND ABS(mileage_delta) <= 200000                                  -- implausible rollback size = bad data
