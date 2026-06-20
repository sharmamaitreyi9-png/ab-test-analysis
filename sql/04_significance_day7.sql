-- =============================================================
-- 04_significance_day7.sql
-- Two-proportion z-test on Day 7 retention.
-- Computes z-statistic, classifies significance, and reports the
-- 95% confidence interval on the absolute lift in percentage points.
-- Implemented in pure SQL so the test is fully auditable.
-- =============================================================

WITH stats AS (
  SELECT
    SUM(CASE WHEN version = 'gate_30' THEN 1 ELSE 0 END)                                 AS n_control,
    SUM(CASE WHEN version = 'gate_40' THEN 1 ELSE 0 END)                                 AS n_treatment,
    SUM(CASE WHEN version = 'gate_30' AND retention_7 = TRUE THEN 1 ELSE 0 END)          AS x_control,
    SUM(CASE WHEN version = 'gate_40' AND retention_7 = TRUE THEN 1 ELSE 0 END)          AS x_treatment
  FROM cookie_cats
),
calc AS (
  SELECT
    n_control, n_treatment, x_control, x_treatment,
    1.0 * x_control                            / n_control                  AS p_control,
    1.0 * x_treatment                          / n_treatment                AS p_treatment,
    1.0 * (x_control + x_treatment)            / (n_control + n_treatment)  AS p_pooled
  FROM stats
),
zscore AS (
  SELECT
    p_control, p_treatment,
    p_treatment - p_control                                                  AS abs_lift,
    100.0 * (p_treatment - p_control) / p_control                            AS rel_lift_pct,
    (p_treatment - p_control)
      / SQRT(p_pooled * (1 - p_pooled) * (1.0/n_control + 1.0/n_treatment))  AS z_stat,
    SQRT(p_control*(1-p_control)/n_control + p_treatment*(1-p_treatment)/n_treatment) AS se_diff
  FROM calc
)
SELECT
  ROUND(p_control * 100, 4)            AS p_control_pct,
  ROUND(p_treatment * 100, 4)          AS p_treatment_pct,
  ROUND(abs_lift * 100, 4)             AS abs_lift_pp,
  ROUND(rel_lift_pct, 2)               AS rel_lift_pct,
  ROUND(z_stat, 4)                     AS z_stat,
  CASE
    WHEN ABS(z_stat) > 2.576 THEN 'Significant at 99% (p<0.01)'
    WHEN ABS(z_stat) > 1.96  THEN 'Significant at 95% (p<0.05)'
    WHEN ABS(z_stat) > 1.645 THEN 'Significant at 90% (p<0.10)'
    ELSE                          'Not significant'
  END                                  AS significance,
  ROUND((abs_lift - 1.96 * se_diff) * 100, 4) AS ci_low_95_pp,
  ROUND((abs_lift + 1.96 * se_diff) * 100, 4) AS ci_high_95_pp
FROM zscore;
