# Detecting Odometer Fraud in UK MOT Data

**Analysing ~85 million MOT test records (2024–2025) to identify suspected vehicle mileage tampering and separate genuine fraud signals from data-quality noise.**

Data source: DVSA MOT testing data (anonymised). Contains public sector information licensed under the Open Government Licence v3.0. 
Links: 
https://edh-dvsa-data-gov-uk-files-prod.s3.eu-west-1.amazonaws.com/dft_test_result_extracts_2025.zip
https://edh-dvsa-data-gov-uk-files-prod.s3.eu-west-1.amazonaws.com/dft_test_result_extracts_2024.zip

---

## Summary

Odometer fraud or "clocking", is the practice of winding back a vehicle's recorded mileage to inflate its resale value. The UK MOT test records an odometer reading at every test, so a vehicle's mileage history should only ever increase. Any recorded decrease is physically impossible and is a potential indicator of tampering.

This project builds an end-to-end pipeline over two full years of DVSA MOT data (~85 million test records) to detect these anomalies, then applies a series of data-quality filters to distinguish credible clocking candidates from the far larger volume of readings that only *look* like rollbacks but are actually data errors. The output is a transparent, rules-based risk score ranking suspected vehicles, surfaced through a Power BI dashboard.

**Headline finding:** of ~476,000 raw mileage decreases found across 48 million consecutive test pairs, roughly three-quarters turned out to be explainable data-quality issues (missing readings, typos, unit-conversion errors). After filtering, around **121,000 vehicles** remained as credible clocking candidates, with an average rollback of ~19,500 miles (about 20% of the recorded reading).

The emphasis throughout is on honest measurement: these are *suspected* cases identified from anomaly patterns, not confirmed fraud. Individual cases would require verification.

---

## Key results

| Stage | Count | Notes |
|---|---|---|
| Records ingested (2024 + 2025) | ~85,365,000 | Two full years of DVSA MOT tests |
| Consecutive test pairs analysed | 48,431,021 | One row per vehicle transition between tests |
| Raw mileage decreases ("drops") | 476,590 | 0.98% of all transitions |
| — Zero / missing readings | 300,789 (63%) | Largest single cause; not fraud |
| — Trivial typos (<50 mi) | 34,205 | Data-entry error |
| — Kilometre/mile unit switches | 12,964 | Confirmed by a spike at the 1.61 conversion ratio |
| — Implausible junk values | 1,267 | Bad records |
| **Credible clocking candidates** | **121,340 events / 121,109 vehicles** | Survive all data-quality filters |
| Average rollback | ~19,462 miles (19.9% of reading) | Realistic, partial rollbacks — not total wipes |

---

## The analytical story

The value of this project is less in "counting the drops" and more in the reasoning used to decide which drops are real. Four findings shaped the pipeline:

**1. Cross-year identity had to be proven before it could be trusted.** The multi-year analysis depends on the anonymised `vehicle_id` referring to the same physical vehicle across annual data releases. Rather than assume this, it was tested: of 30.49 million vehicles appearing in both years, 100% had consistent make, model, and first-use date. Only then was the cross-year join built.

**2. Missing readings, not fraud, are the dominant anomaly.** 63% of all apparent rollbacks were vehicles whose later reading was recorded as zero. A make-level breakdown confirmed these were spread proportionally across the whole fleet (Ford, Vauxhall, VW… in order of market share), indicating random data-entry gaps rather than any structural cause. This is the single most important data-quality finding.

**3. Kilometre/mile confusion is real and detectable.** UK MOTs are recorded in miles by default, but kilometres is a permitted option (common for imported vehicles). When a vehicle's history switches units, it produces a false "drop" of a specific magnitude. Plotting the ratio of consecutive readings revealed a sharp spike at exactly 1.61 — the km-to-mile conversion factor — proving the effect was present and quantifying it (~13,000 cases). The pattern was found in the data first, then explained with domain knowledge.

**4. Extreme values signal bad data, not extreme fraud.** Early versions of the risk score ranked "total wipe" rollbacks (mileage dropping to near-zero) at the top. These are not fraud — no one clocks a 180,000-mile van down to 96 miles, as it would be instantly detectable. Genuine clocking is *partial*: a large but believable rollback that leaves a plausible remaining reading. Recognising that threshold-tuning alone cannot perfectly separate fraud from error — and documenting that limitation — was the honest conclusion rather than forcing a falsely clean result.

---

## Risk scoring

Each credible candidate is scored 0–100 using a transparent, rules-based formula rather than a black-box model. The score is driven 70% by the *proportion* of mileage erased and 30% by the *absolute* miles removed, capped to prevent single outliers from dominating.

A transparent score is a deliberate choice: a fraud or data-quality team must be able to justify why a vehicle was flagged. "This vehicle had 40% of its mileage removed, so it scored 82" is defensible in a way that a model probability is not.

---

## Technical implementation

**Pipeline:** raw CSV extracts → DuckDB → dbt (staging → intermediate → mart) → Power BI.

**Data engineering.** Two years of monthly CSV extracts (~85M rows) were loaded into DuckDB. The raw files required explicit handling of format inconsistencies between months — non-standard quote and escape characters, and varying newline conventions — which auto-detection could not resolve. Loading used an all-text-then-cast strategy (`TRY_CAST`) so malformed values became NULLs rather than failing the load. An out-of-memory failure on the 85M-row window sort was handled with a memory limit and disk-spill configuration.

**Transformation (dbt).** The analysis is structured as four dbt models:

- `stg_tests` — both years unioned and typed
- `int_mileage_seq` — consecutive test pairs per vehicle, with the mileage delta derived via a `LAG` window function partitioned by `vehicle_id`
- `int_clocking_events` — data-quality filters applied (unit-switch exclusion, plausibility bounds, floors on remaining mileage)
- `mart_vehicle_risk` — the final scored output

dbt resolves the model dependencies automatically and generates a lineage graph documenting the flow from raw to mart.

**Data quality (dbt tests).** Eight tests run against the pipeline, including two custom business-rule assertions written as SQL:

- every clocking event must have a genuinely negative mileage delta
- every risk score must fall within 0–100

plus `not_null` checks on key columns across all models. All pass.

**Visualisation (Power BI).** A single-page dashboard built in Power BI Desktop (DAX measures) presents the funnel from raw anomalies to credible candidates, headline metrics, and breakdowns by make and region.

---

## Tools

DuckDB · dbt (dbt-duckdb) · SQL · Power BI Desktop 

---

## Repository structure

```
mot_clocking/
├── Dashboard
├── models/
│   ├── stg_tests.sql
│   ├── int_mileage_seq.sql
│   ├── int_clocking_events.sql
│   ├── mart_vehicle_risk.sql
│   └── schema.yml
├── tests/
│   ├── assert_mileage_delta_negative.sql
│   └── assert_risk_score_in_range.sql
└── dbt_project.yml
```

---

## Limitations and honest framing

- These are **suspected** rollbacks identified from anomaly patterns, not confirmed fraud. Any individual case would require manual verification.
- Regional counts largely reflect vehicle population density rather than differing rates of fraud; they are not "clocking hotspots".
- The data-quality thresholds (e.g. unit-switch ratio band, plausibility caps, remaining-mileage floor) are defensible judgement calls, not exact boundaries. Fraud and data error genuinely overlap, and no fixed threshold cleanly separates them.
- The scatter and single-vehicle views are illustrative of the pattern, not exhaustive plots of every flagged vehicle.

## Possible extensions

- Add further years to lengthen per-vehicle histories and strengthen the score.
- Add a "mileage recovery" signal: a genuine rollback stays low, whereas a data error often self-corrects at the next test. This tests the pattern over time rather than a single drop.
