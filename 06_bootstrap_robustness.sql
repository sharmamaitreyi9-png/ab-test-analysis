-- =============================================================
-- 06_bootstrap_robustness.sql
-- Bootstrap robustness check on the Day 7 retention lift.
-- Resamples the population ~1000 times (each ~80% of users via
-- RANDOM() filter) and recomputes the lift. Confirms whether the
-- analytical z-test result is driven by outliers or robust.
-- =============================================================

WITH bootstrap_samples AS (
  SELECT
    seq.bootstrap_id,
    cc.version,
    cc.retention_7
  FROM cookie_cats cc
  CROSS JOIN (SELECT UNNEST(GENERATE_SERIES(1, 1000)) AS bootstrap_id) seq
  WHERE RANDOM() < 0.8
),
boot_stats AS (
  SELECT
    bootstrap_id,
    100.0 * COUNT(CASE WHEN version = 'gate_40' AND retention_7 = TRUE THEN 1 END)
           / NULLIF(COUNT(CASE WHEN version = 'gate_40' THEN 1 END), 0)
    -
    100.0 * COUNT(CASE WHEN version = 'gate_30' AND retention_7 = TRUE THEN 1 END)
           / NULLIF(COUNT(CASE WHEN version = 'gate_30' THEN 1 END), 0)
      AS lift_pp
  FROM bootstrap_samples
  GROUP BY bootstrap_id
)
SELECT
  COUNT(*)                                        AS n_samples,
  ROUND(AVG(lift_pp), 4)                          AS mean_lift_pp,
  ROUND(STDDEV(lift_pp), 4)                       AS stddev_lift_pp,
  ROUND(QUANTILE_CONT(lift_pp, 0.025), 4)         AS lift_pp_p2_5,
  ROUND(QUANTILE_CONT(lift_pp, 0.975), 4)         AS lift_pp_p97_5,
  100.0 * COUNT(CASE WHEN lift_pp >= 0 THEN 1 END) / COUNT(*) AS pct_runs_positive_or_zero
FROM boot_stats;
