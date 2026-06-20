-- =============================================================
-- 03_headline_metrics.sql
-- Per-arm summary of retention and engagement metrics:
--   * retention_1: returned on day 1
--   * retention_7: returned on day 7
--   * sum_gamerounds: total rounds in the 14-day observation window
-- =============================================================

SELECT
  version,
  COUNT(*)                                                                       AS users,
  ROUND(100.0 * COUNT(CASE WHEN retention_1 = TRUE THEN 1 END) / COUNT(*), 4)    AS retention_1_pct,
  ROUND(100.0 * COUNT(CASE WHEN retention_7 = TRUE THEN 1 END) / COUNT(*), 4)    AS retention_7_pct,
  ROUND(AVG(sum_gamerounds), 2)                                                  AS avg_gamerounds,
  ROUND(MEDIAN(sum_gamerounds), 2)                                               AS median_gamerounds,
  MAX(sum_gamerounds)                                                            AS max_gamerounds
FROM cookie_cats
GROUP BY version
ORDER BY version;
