-- ============================================================
-- Analyse_Compte_1906.sql
-- Analyse des montants pour le compte 1906 - Periode Fevrier 2026
-- ============================================================

SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 100

-- ============================================================
-- 1. INFOS COMPTE 1906
-- ============================================================
SELECT acct_id, acct_name, acct_num, ccy_code
FROM BS_ACCTS
WHERE acct_id = 1906;

-- ============================================================
-- 2. DONNEES DEJA PRESENTES DANS BRD_EU_JC_ITEMS (periode 202602)
-- ============================================================
SELECT
    period_JC,
    acct_id,
    record_id,
    state,
    amount,
    refer_date,
    rec_time,
    orig_id
FROM BRD_EU_JC_ITEMS
WHERE acct_id = 1906
  AND period_JC = '202602'
ORDER BY refer_date, record_id;

-- ============================================================
-- 3. ANALYSE STATE 4 - Ecritures reconciliees (avec audit)
--    Montants qui seraient inseres pour periode 202603
-- ============================================================
SELECT
    '202603' as period_JC,
    d.acct_id,
    d.record_id,
    d.state,
    d.load_id,
    d.rec_group,
    d.num_in_grp,
    d.cs_flag,
    d.pr_flag,
    d.amount,
    rec_ts.rec_time,
    rec_ts.orig_id,
    d.trans_date as refer_date
FROM (
    SELECT a.orig_id,
        MAX(a.timestamp) as rec_time,
        MAX(a.record_id) AS record_id
    FROM BR_AUDIT a
    WHERE a.acct_id = 1906
      AND a.type = 0
      AND a.bfr_state != 0
      AND a.aft_state = 4
      AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
    GROUP BY a.orig_id
) rec_ts
JOIN BR_DATA d
    ON (d.acct_id = 1906
    AND d.record_id = rec_ts.record_id
    AND d.state = 4)
WHERE NOT EXISTS (
    SELECT '1'
    FROM BRD_EU_JC_ITEMS i
    WHERE i.PERIOD_JC = '202603'
      AND i.acct_id = 1906
      AND i.record_id = d.record_id
)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD')
ORDER BY d.trans_date, d.record_id;

-- ============================================================
-- 4. ANALYSE STATE 3 - Ecritures en suspens
--    Montants qui seraient inseres pour periode 202603
-- ============================================================
SELECT
    '202603' as period_JC,
    d.acct_id,
    d.record_id,
    d.state,
    d.load_id,
    d.rec_group,
    d.num_in_grp,
    d.cs_flag,
    d.pr_flag,
    d.amount,
    null as rec_time,
    d.orig_id,
    d.trans_date as refer_date
FROM BR_DATA d
WHERE d.acct_id = 1906
  AND NOT EXISTS (
    SELECT '1'
    FROM BRD_EU_JC_ITEMS i
    WHERE i.PERIOD_JC = '202603'
      AND i.acct_id = 1906
      AND i.record_id = d.record_id
)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD')
ORDER BY d.trans_date, d.record_id;

-- ============================================================
-- 5. TOTAUX PAR STATE - Fevrier 2026
-- ============================================================
PROMPT
PROMPT ========== TOTAUX STATE 4 (Reconciliees) ==========

SELECT
    COUNT(*) as NB_LIGNES,
    SUM(d.amount) as TOTAL_AMOUNT,
    SUM(CASE WHEN d.amount > 0 THEN d.amount ELSE 0 END) as TOTAL_CREDIT,
    SUM(CASE WHEN d.amount < 0 THEN d.amount ELSE 0 END) as TOTAL_DEBIT
FROM (
    SELECT a.orig_id,
        MAX(a.timestamp) as rec_time,
        MAX(a.record_id) AS record_id
    FROM BR_AUDIT a
    WHERE a.acct_id = 1906
      AND a.type = 0
      AND a.bfr_state != 0
      AND a.aft_state = 4
      AND a.timestamp > ADD_MONTHS(TO_DATE('2026-04-01', 'YYYY-MM-DD'), -1) - 1
    GROUP BY a.orig_id
) rec_ts
JOIN BR_DATA d
    ON (d.acct_id = 1906
    AND d.record_id = rec_ts.record_id
    AND d.state = 4)
WHERE NOT EXISTS (
    SELECT '1'
    FROM BRD_EU_JC_ITEMS i
    WHERE i.PERIOD_JC = '202603'
      AND i.acct_id = 1906
      AND i.record_id = d.record_id
)
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

PROMPT
PROMPT ========== TOTAUX STATE 3 (En suspens) ==========

SELECT
    COUNT(*) as NB_LIGNES,
    SUM(d.amount) as TOTAL_AMOUNT,
    SUM(CASE WHEN d.amount > 0 THEN d.amount ELSE 0 END) as TOTAL_CREDIT,
    SUM(CASE WHEN d.amount < 0 THEN d.amount ELSE 0 END) as TOTAL_DEBIT
FROM BR_DATA d
WHERE d.acct_id = 1906
  AND NOT EXISTS (
    SELECT '1'
    FROM BRD_EU_JC_ITEMS i
    WHERE i.PERIOD_JC = '202603'
      AND i.acct_id = 1906
      AND i.record_id = d.record_id
)
AND d.state = 3
AND d.trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD');

-- ============================================================
-- 6. DETAIL BR_DATA - Toutes les lignes du compte 1906 (Fev 2026)
-- ============================================================
PROMPT
PROMPT ========== DETAIL BR_DATA - COMPTE 1906 (trans_date < 2026-04-01) ==========

SELECT
    record_id,
    state,
    CASE state
        WHEN 0 THEN 'NEW'
        WHEN 1 THEN 'LOADED'
        WHEN 2 THEN 'MATCHED'
        WHEN 3 THEN 'SUSPENS'
        WHEN 4 THEN 'RECONCILED'
        WHEN 5 THEN 'DELETED'
        ELSE TO_CHAR(state)
    END as state_desc,
    amount,
    trans_date,
    load_id,
    orig_id,
    rec_group
FROM BR_DATA
WHERE acct_id = 1906
  AND trans_date >= TO_DATE('2026-02-01', 'YYYY-MM-DD')
  AND trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD')
ORDER BY trans_date, record_id;

-- ============================================================
-- 7. HISTORIQUE AUDIT - Actions sur le compte 1906 (Fev-Mars 2026)
-- ============================================================
PROMPT
PROMPT ========== HISTORIQUE BR_AUDIT - COMPTE 1906 ==========

SELECT
    audit_id,
    record_id,
    orig_id,
    bfr_state,
    aft_state,
    type,
    timestamp,
    CASE
        WHEN bfr_state = 3 AND aft_state = 4 THEN 'RECONCILIATION'
        WHEN bfr_state = 4 AND aft_state = 3 THEN 'ROLLBACK'
        WHEN bfr_state = 0 AND aft_state = 1 THEN 'LOAD'
        ELSE 'OTHER'
    END as action_type
FROM BR_AUDIT
WHERE acct_id = 1906
  AND timestamp >= TO_DATE('2026-02-01', 'YYYY-MM-DD')
  AND timestamp < TO_DATE('2026-04-01', 'YYYY-MM-DD')
ORDER BY timestamp DESC;

-- ============================================================
-- 8. RECHERCHE ROLLBACK - Lignes passees de state 4 a 3
-- ============================================================
PROMPT
PROMPT ========== ROLLBACKS DETECTES - COMPTE 1906 ==========

SELECT
    a.audit_id,
    a.record_id,
    a.orig_id,
    a.bfr_state as "AVANT",
    a.aft_state as "APRES",
    a.timestamp as "DATE_ROLLBACK",
    d.amount,
    d.trans_date
FROM BR_AUDIT a
LEFT JOIN BR_DATA d ON (d.acct_id = a.acct_id AND d.record_id = a.record_id)
WHERE a.acct_id = 1906
  AND a.bfr_state = 4
  AND a.aft_state = 3
  AND a.timestamp >= TO_DATE('2026-02-01', 'YYYY-MM-DD')
ORDER BY a.timestamp DESC;

-- ============================================================
-- 9. SOLDE TOTAL PAR STATE
-- ============================================================
PROMPT
PROMPT ========== SOLDE PAR STATE - COMPTE 1906 ==========

SELECT
    state,
    CASE state
        WHEN 0 THEN 'NEW'
        WHEN 1 THEN 'LOADED'
        WHEN 2 THEN 'MATCHED'
        WHEN 3 THEN 'SUSPENS'
        WHEN 4 THEN 'RECONCILED'
        WHEN 5 THEN 'DELETED'
        ELSE TO_CHAR(state)
    END as state_desc,
    COUNT(*) as NB_LIGNES,
    SUM(amount) as TOTAL_AMOUNT
FROM BR_DATA
WHERE acct_id = 1906
  AND trans_date < TO_DATE('2026-04-01', 'YYYY-MM-DD')
GROUP BY state
ORDER BY state;

-- ============================================================
-- FIN DU SCRIPT
-- ============================================================
