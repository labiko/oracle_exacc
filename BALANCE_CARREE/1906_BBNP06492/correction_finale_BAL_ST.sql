-- =====================================================
-- correction_finale_BAL_ST.sql
-- Compte : 1906 (BBNP06492-EUR)
-- Periode : 202602 (Fevrier 2026)
-- =====================================================
-- CONTEXTE :
--   - Rollback load 346241 a echoue partiellement (25/02/2026)
--   - Records orphelins 878/879 supprimes de BR_DATA et JC_ITEMS
--   - Batch a recalcule SUM_ST_P/SUM_ST_R (correct)
--   - BAL_ST reste a 5,21 (lu depuis BR_AUDIT type=15, aft_amt=5,21)
--   - DIFF = 5,32 (double car BAL_ST pas ajuste)
--
-- ROOT CAUSE (BR_AUDIT) :
--   audit_id 3262 : type=15, load 346241, bfr_amt=-0,11, aft_amt=2,55
--   audit_id 3276 : type=15, load 346285, bfr_amt=2,55, aft_amt=5,21
--   Le load 346285 a pris bfr_amt=2,55 (FAUX) au lieu de -0,11
--
-- SOLUTION :
--   Corriger BAL_ST = -0,11 (valeur avant load 346241)
--   Le batch recalculera DIFF = 0 au prochain passage
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/correction_finale_BAL_ST.sql
-- =====================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 50

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

PROMPT =====================================================
PROMPT CORRECTION FINALE BAL_ST - Compte 1906, Periode 202602
PROMPT =====================================================
SELECT SYSDATE, USER FROM DUAL;

-- =====================================================
-- ETAPE 1 : ETAT AVANT CORRECTION
-- =====================================================
PROMPT
PROMPT ===== ETAT AVANT CORRECTION =====

SELECT
    PERIOD_JC,
    ACCT_ID,
    BAL_ST AS "BAL_ST (actuel)",
    SUM_ST_P,
    SUM_ST_R,
    DIFF AS "DIFF (actuel)",
    BAL_ST - DIFF AS "BAL_ST cible"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 2 : CORRECTION BAL_ST + DIFF
-- =====================================================
PROMPT
PROMPT ===== CORRECTION BAL_ST + DIFF =====
PROMPT Formule : BAL_ST = BAL_ST - DIFF, DIFF = 0
PROMPT BAL_ST cible = 5,21 - 5,32 = -0,11

UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = BAL_ST - DIFF,
    DIFF = 0
WHERE ACCT_ID = 1906
  AND PERIOD_JC = '202602'
  AND DIFF != 0;

PROMPT Lignes modifiees :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 3 : VERIFICATION APRES CORRECTION
-- =====================================================
PROMPT
PROMPT ===== ETAT APRES CORRECTION =====

SELECT
    PERIOD_JC,
    ACCT_ID,
    BAL_ST AS "BAL_ST (nouveau)",
    SUM_ST_P,
    SUM_ST_R,
    DIFF AS "DIFF (nouveau)"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 4 : VERIFICATION CALCUL DIFF
-- =====================================================
PROMPT
PROMPT ===== VERIFICATION FORMULE DIFF =====

SELECT
    PERIOD_JC,
    BAL_ST,
    SUM_ST_P,
    SUM_ST_R,
    BAL_CB,
    SUM_CB_P,
    SUM_CB_R,
    DIFF AS "DIFF_STOCKE",
    (BAL_ST - (SUM_ST_P + SUM_ST_R)) + (BAL_CB - (SUM_CB_P + SUM_CB_R)) AS "DIFF_CALCULE"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 5 : COMMIT
-- =====================================================
PROMPT
PROMPT =====================================================
COMMIT;
PROMPT COMMIT effectue
PROMPT =====================================================

PROMPT
PROMPT *** CORRECTION TERMINEE ***
PROMPT
PROMPT Verifier que :
PROMPT   1. BAL_ST = -0,11
PROMPT   2. DIFF_STOCKE = 0
PROMPT   3. DIFF_CALCULE = 0 (ou tres proche)
PROMPT   4. L'interface Balance Carree affiche 0 ecart
PROMPT
PROMPT Le batch nightly recalculera DIFF = 0 automatiquement
PROMPT car BAL_ST = -0,11 est maintenant correct.
PROMPT
PROMPT Pour ROLLBACK :
PROMPT   UPDATE BANKREC.BRD_EU_JC_SUMMARY
PROMPT   SET BAL_ST = 5.21, DIFF = 5.32
PROMPT   WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
PROMPT   COMMIT;
PROMPT
SELECT SYSDATE FROM DUAL;
PROMPT =====================================================

EXIT SUCCESS;
