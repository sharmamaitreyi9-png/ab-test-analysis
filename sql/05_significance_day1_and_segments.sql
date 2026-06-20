-- =============================================================
-- 05_significance_day1_and_segments.sql
-- Two parts:
--   (A) Same two-proportion z-test for Day 1 retention.
--   (B) Engagement segmentation: how the gate change shifts the
--       distribution of users across engagement tiers.
-- =============================================================

-- (A) Day 1 retention significance ------------------------------
WITH stats AS (
  SELECT
    SUM(CASE WHEN version = 'gate_30' THEN 1 ELSE 0 END)                                 AS n_control,
    SUM(CASE WHEN version = 'gate_40' THEN 1 ELSE 0 END)                                 AS n_treatment,
    SUM(CASE WHEN version = 'gate_30' AND retention_1 = TRUE THEN 1 ELSE 0 END)          AS x_control,
    SUM(CASE WHEN version = 'gate_40' AND retention_1 = TRUE THEN 1 ELSE 0 END)          AS x_treatment
  FROM cookie_cats
),
calc AS (
  SELECT
    n_control, n_treatment,
    1.0 * x_control                            / n_control                 AS p_control,
    1.0 * x_treatment                          / n_treatment               AS p_treatment,
    1.0 * (x_control + x_treatment)            / (n_control + n_treatment) AS p_pooled
  FROM stats
),
zscore AS (
  SELECT
    p_control, p_treatment,
    p_treatment - p_control                                                 AS abs_lift,
    100.0 * (p_treatment - p_control) / p_control                           AS rel_lift_pct,
    (p_treatment - p_control)
      / SQRT(p_pooled * (1 - p_pooled) * (1.0/n_control + 1.0/n_treatment)) AS z_stat,
    SQRT(p_control*(1-p_control)/n_control + p_treatment*(1-p_treatment)/n_treatment) AS se_diff
  FROM calc
)
SELECT
  'Day 1'                              AS metric,
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

-- (B) Engagement segmentation -----------------------------------
WITH segmented AS (
  SELECT
    version,
    CASE
      WHEN sum_gamerounds = 0                          THEN '1_never_played'
      WHEN sum_gamerounds BETWEEN 1   AND 10           THEN '2_low'
      WHEN sum_gamerounds BETWEEN 11  AND 50           THEN '3_medium'
      WHEN sum_gamerounds BETWEEN 51  AND 200          THEN '4_high'
      ELSE                                                  '5_power'
    END AS engagement_segment
  FROM cookie_cats
)
SELECT
  engagement_segment,
  COUNT(CASE WHEN version = 'gate_30' THEN 1 END) AS users_gate_30,
  COUNT(CASE WHEN version = 'gate_40' THEN 1 END) AS users_gate_40,
  ROUND(100.0 * COUNT(CASE WHEN version = 'gate_30' THEN 1 END)
        / SUM(COUNT(CASE WHEN version = 'gate_30' THEN 1 END)) OVER (), 2) AS pct_of_gate_30,
  ROUND(100.0 * COUNT(CASE WHEN version = 'gate_40' THEN 1 END)
        / SUM(COUNT(CASE WHEN version = 'gate_40' THEN 1 END)) OVER (), 2) AS pct_of_gate_40
FROM segmented
GROUP BY engagement_segment
ORDER BY engagement_segment;
