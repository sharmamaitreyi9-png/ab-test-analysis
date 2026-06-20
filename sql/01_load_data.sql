-- =============================================================
-- 01_load_data.sql
-- Loads the Cookie Cats A/B test dataset into DuckDB.
-- Source: https://www.kaggle.com/datasets/yufengsui/mobile-games-ab-testing
-- 90,189 users randomly assigned to two variants of a mobile game,
-- differing only in the level at which a progression gate appears
-- (gate_30 = control, gate_40 = treatment).
-- =============================================================

SET memory_limit = '2GB';

CREATE OR REPLACE TABLE cookie_cats AS
SELECT *
FROM read_csv_auto(
  'C:\Users\rajiv\projects\ab-test-analysis\data\cookie_cats.csv',
  header = true
);

-- Sanity checks
SELECT COUNT(*) AS row_count FROM cookie_cats;
SELECT * FROM cookie_cats LIMIT 5;
DESCRIBE cookie_cats;
