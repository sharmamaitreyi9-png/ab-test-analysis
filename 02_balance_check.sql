-- =============================================================
-- 02_balance_check.sql
-- Sample Ratio Mismatch (SRM) check.
-- Confirms allocation between control and treatment is balanced
-- enough to interpret downstream metrics. A skewed split would
-- invalidate the experiment.
-- =============================================================

SELECT
  version,
  COUNT(*) AS users,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM cookie_cats
GROUP BY version
ORDER BY version;
