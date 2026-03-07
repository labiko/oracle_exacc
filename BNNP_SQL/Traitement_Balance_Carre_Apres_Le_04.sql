-- ============================================================
-- Traitement_Balance_Carre_Apres_Le_04.sql
-- Insertion des items JC pour la periode 202603
-- Transactions avec trans_date < 2026-04-01
-- ============================================================

SET SERVEROUTPUT ON

-- ============================================================
-- COMPTE 1919
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1919
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1919 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1919
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1915 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1915
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1915 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1915
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1915 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1915
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1915
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1829 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1829
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1829
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1531 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1531
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1531
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1531 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1531
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1531 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1531
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1893 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1893
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1893 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1893
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1893 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1893
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1893
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1827 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1827
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1827
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1827 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1827
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1827 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1827
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1906 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1906
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1906
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1906 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1906
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1906 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1906
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1903 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1903
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1903 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1903
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1903 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1903
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1903
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 969 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 969
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 969 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 969
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 969 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 969
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 969
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 912 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 912
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 912
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 912 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 912
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 912 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 912
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1851 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1851
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1851
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1851 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1851
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1851 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1851
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 913 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 913
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 913
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 913 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 913
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 913 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 913
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1911 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1911
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1911 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1911
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1911 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1911
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1911
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1019 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1019
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1019 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1019
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1019 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1019
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1019
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1907 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1907
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1907
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1907 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1907
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1907 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1907
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1022 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1022
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1022
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1022 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1022
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1022 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1022
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1895 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1895
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1895
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1895 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1895
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1895 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1895
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 914 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 914
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 914
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 914 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 914
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 914 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 914
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 943 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 943
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 943
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 943 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 943
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 943 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 943
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1821 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1821
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1821 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1821
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1821 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1821
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1821
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1853 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1853
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1853
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1853 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1853
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1853 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1853
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 915 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 915
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 915 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 915
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 915 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 915
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 915
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 916 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 916
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 916 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 916
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 916 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 916
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 916
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1803 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1803
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1803 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1803
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1803 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1803
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1803
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1857 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1857
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1857 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1857
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1857 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1857
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1857
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1908 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1908
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1908
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1908 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1908
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1908 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1908
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 917 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 917
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 917 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 917
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 917 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 917
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 917
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1020 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1020
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1020 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1020
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1020 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1020
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1020
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1021 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1021
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1021
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1021 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1021
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1021 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1021
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1835 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1835
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1835 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1835
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1835 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1835
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1835
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1143 - State 3
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, null as rec_time, d.orig_id, d.trans_date
FROM BR_DATA d
WHERE d.acct_id = 1143
  AND NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1143
    AND i.record_id = d.record_id)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMPTE 1143 - State 4
-- ============================================================
INSERT INTO BRD_EU_JC_ITEMS
(period_JC, acct_id, record_id, state, load_id, rec_group, num_in_group, cs_flag, pr_flag, amount, rec_time, orig_id, refer_date)
SELECT /*+ NO_QUERY_TRANSFORMATION */
  '202603' as period_JC, d.acct_id, d.record_id,
  d.state, d.load_id, d.rec_group, d.num_in_grp, d.cs_flag,
  d.pr_flag, d.amount, rec_ts.rec_time, rec_ts.orig_id, d.trans_date
FROM (
  SELECT a.orig_id,
    MAX(a.timestamp) as rec_time, MAX(a.record_id) AS record_id
  FROM BR_AUDIT a
  WHERE a.acct_id = 1143
    AND a.type = 0
    AND a.bfr_state != 0
    AND a.aft_state = 4
    AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
  GROUP BY a.orig_id) rec_ts
JOIN BR_DATA d
 ON (d.acct_id = 1143 AND
     d.record_id = rec_ts.record_id AND
     d.state = 4)
WHERE NOT EXISTS (SELECT '1'
  FROM BRD_EU_JC_ITEMS i
  WHERE i.PERIOD_JC = '202603'
    AND i.acct_id = 1143
    AND i.record_id = d.record_id)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- COMMIT FINAL
-- ============================================================
COMMIT;

-- Verification
SELECT acct_id, COUNT(*) AS nb_records
FROM BRD_EU_JC_ITEMS
WHERE period_JC = '202603'
GROUP BY acct_id
ORDER BY acct_id;
