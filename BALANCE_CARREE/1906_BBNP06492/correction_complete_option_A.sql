-- =====================================================
-- correction_complete_option_A.sql
-- Compte : 1906 (BBNP06492-EUR)
-- Periode : 202602 (Fevrier 2026)
-- =====================================================
-- CONTEXTE :
--   - Records orphelins 878/879 supprimes de BR_DATA et BRD_EU_JC_ITEMS
--   - BAL_ST et DIFF corriges mais SUM_ST_P/SUM_ST_R pas mis a jour
--   - Application affiche encore l'ecart car SUMMARY incoherent
--
-- SOLUTION :
--   Mettre a jour TOUTES les colonnes de BRD_EU_JC_SUMMARY
--   pour refleter l'etat sans les records orphelins
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/correction_complete_option_A.sql
-- =====================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 50

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

PROMPT =====================================================
PROMPT CORRECTION COMPLETE OPTION A - Compte 1906
PROMPT Alignement de TOUTES les colonnes BRD_EU_JC_SUMMARY
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
    BAL_ST AS "BAL_ST",
    SUM_ST_P AS "SUM_ST_P",
    SUM_ST_R AS "SUM_ST_R",
    DIFF AS "DIFF"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 2 : VERIFICATION JC_ITEMS (records orphelins supprimes?)
-- =====================================================
PROMPT
PROMPT ===== VERIFICATION JC_ITEMS - Records load_id=346241 =====

SELECT COUNT(*) AS "NB_RECORDS_ORPHELINS"
FROM BANKREC.BRD_EU_JC_ITEMS
WHERE ACCT_ID = 1906 AND LOAD_ID = 346241;

-- =====================================================
-- ETAPE 3 : CORRECTION COMPLETE
-- =====================================================
PROMPT
PROMPT ===== CORRECTION COMPLETE =====
PROMPT BAL_ST   : -0,11 (solde avant load 346241)
PROMPT SUM_ST_P : -120360,00 (sans record 878 = 248800,25)
PROMPT SUM_ST_R : 31499539,00 (sans record 879 = 248802,91)
PROMPT DIFF     : 0

UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11,
    SUM_ST_P = -120360.00,
    SUM_ST_R = 31499539.00,
    DIFF = 0
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT Lignes modifiees :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 4 : VERIFICATION APRES CORRECTION
-- =====================================================
PROMPT
PROMPT ===== ETAT APRES CORRECTION =====

SELECT
    PERIOD_JC,
    ACCT_ID,
    BAL_ST AS "BAL_ST",
    SUM_ST_P AS "SUM_ST_P",
    SUM_ST_R AS "SUM_ST_R",
    DIFF AS "DIFF"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 5 : VERIFICATION CALCUL DIFF
-- =====================================================
PROMPT
PROMPT ===== VERIFICATION CALCUL DIFF =====

SELECT
    PERIOD_JC,
    BAL_ST,
    SUM_ST_P,
    SUM_ST_R,
    BAL_CB,
    SUM_CB_P,
    SUM_CB_R,
    DIFF AS "DIFF_STOCKE",
    (BAL_ST - (SUM_ST_P + SUM_ST_R)) AS "SUM_REC_ST",
    (BAL_CB - (SUM_CB_P + SUM_CB_R)) AS "SUM_REC_CB",
    (BAL_ST - (SUM_ST_P + SUM_ST_R)) + (BAL_CB - (SUM_CB_P + SUM_CB_R)) AS "DIFF_CALCULE"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 6 : COMMIT
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
PROMPT   1. DIFF_STOCKE = 0
PROMPT   2. DIFF_CALCULE = 0 (ou tres proche)
PROMPT   3. L'interface Balance Carree affiche 0 ecart
PROMPT
PROMPT Pour ROLLBACK :
PROMPT   UPDATE BANKREC.BRD_EU_JC_SUMMARY
PROMPT   SET BAL_ST = 5.21, SUM_ST_P = -369160.25, SUM_ST_R = 31748341.91, DIFF = 2.66
PROMPT   WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
PROMPT   COMMIT;
PROMPT
SELECT SYSDATE FROM DUAL;
PROMPT =====================================================

EXIT SUCCESS;
