-- =====================================================
-- CORRECTION_GENERIQUE.sql
-- Script generique pour corriger les ecarts Balance Carree
-- =====================================================
--
-- PRINCIPE :
-- L'ecart (DIFF) est cause par un BAL_ST (solde Bank) incorrect.
-- Pour corriger : BAL_ST_nouveau = BAL_ST_actuel - DIFF_actuel
--
-- UTILISATION :
-- 1. Modifier les variables ACCT_ID et PERIOD_JC ci-dessous
-- 2. Executer le script
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/CORRECTION_GENERIQUE.sql
-- =====================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 50

-- =====================================================
-- VARIABLES A MODIFIER
-- =====================================================
DEFINE V_ACCT_ID = 1906
DEFINE V_PERIOD_JC = '202602'
-- =====================================================

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

PROMPT =====================================================
PROMPT CORRECTION GENERIQUE ECART BALANCE CARREE
PROMPT Compte : &V_ACCT_ID
PROMPT Periode : &V_PERIOD_JC
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
    ACCT_NAME,
    BAL_ST AS "BAL_ST (actuel)",
    DIFF AS "ECART (actuel)",
    BAL_ST - DIFF AS "BAL_ST (cible)"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = &V_ACCT_ID AND PERIOD_JC = &V_PERIOD_JC;

-- =====================================================
-- ETAPE 2 : CORRECTION BAL_ST
-- =====================================================
PROMPT
PROMPT ===== CORRECTION BAL_ST =====
PROMPT Formule : BAL_ST_nouveau = BAL_ST_actuel - DIFF

UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = BAL_ST - DIFF
WHERE ACCT_ID = &V_ACCT_ID
  AND PERIOD_JC = &V_PERIOD_JC
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
    DIFF AS "ECART (nouveau)"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = &V_ACCT_ID AND PERIOD_JC = &V_PERIOD_JC;

-- =====================================================
-- ETAPE 4 : RECALCUL DIFF POUR VERIFICATION
-- =====================================================
PROMPT
PROMPT ===== VERIFICATION CALCUL =====

SELECT
    'SUM_REC_ST' AS calcul,
    BAL_ST - (SUM_ST_P + SUM_ST_R) AS valeur
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = &V_ACCT_ID AND PERIOD_JC = &V_PERIOD_JC
UNION ALL
SELECT
    'SUM_REC_CB',
    BAL_CB - (SUM_CB_P + SUM_CB_R)
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = &V_ACCT_ID AND PERIOD_JC = &V_PERIOD_JC
UNION ALL
SELECT
    'DIFF_RECALCULE',
    (BAL_ST - (SUM_ST_P + SUM_ST_R)) + (BAL_CB - (SUM_CB_P + SUM_CB_R))
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = &V_ACCT_ID AND PERIOD_JC = &V_PERIOD_JC;

-- =====================================================
-- COMMIT
-- =====================================================
PROMPT
PROMPT =====================================================
COMMIT;

PROMPT
PROMPT *** CORRECTION TERMINEE ***
PROMPT DIFF devrait etre 0 (ou tres proche de 0)
PROMPT
PROMPT Pour ROLLBACK :
PROMPT UPDATE BANKREC.BRD_EU_JC_SUMMARY SET BAL_ST = BAL_ST + <ANCIEN_DIFF> WHERE ACCT_ID = &V_ACCT_ID AND PERIOD_JC = &V_PERIOD_JC;
PROMPT

EXIT SUCCESS;
