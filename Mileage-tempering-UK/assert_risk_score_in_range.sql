-- Business-rule assertion: every risk score must fall within the valid 0-100 range.
-- A dbt test passes when it returns zero rows; any row here is a violation.

SELECT
    vehicle_id,
    risk_score
FROM {{ ref('mart_vehicle_risk') }}
WHERE risk_score < 0
   OR risk_score > 100
