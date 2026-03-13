-- =====================================================
-- correction_BR_AUDIT_DEFINITIVE.sql
-- Compte : 1906 (BBNP06492-EUR)
-- Periode : 202602 (Fevrier 2026)
-- =====================================================
-- *** SCRIPT PRINCIPAL - SOLUTION DEFINITIVE ***
--
-- CONTEXTE :
--   Le rollback du load 346241 a echoue partiellement (25/02/2026).
--   Le load 346285 a utilise bfr_amt=2,55 au lieu de -0,11.
--   Des fichiers sont charges QUOTIDIENNEMENT sur ce compte.
--   => La correction SUMMARY seule serait ecrasee au prochain load !
--
-- DONNEES BR_AUDIT A CORRIGER :
--   audit_id 3276 : type=15, load 346285
--   AVANT  : bfr_amt=2,55, aft_amt=5,21
--   APRES  : bfr_amt=-0,11, aft_amt=2,55
--
-- SOLUTION :
--   1. Corriger BR_AUDIT (source permanente)
--   2. Corriger SUMMARY (effet immediat)
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/correction_BR_AUDIT_DEFINITIVE.sql
-- =====================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 50

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

PROMPT =====================================================
PROMPT CORRECTION DEFINITIVE BR_AUDIT - Compte 1906
PROMPT Solution permanente pour ecart Balance Carree
PROMPT =====================================================
SELECT SYSDATE, USER FROM DUAL;

-- =====================================================
-- ETAPE 1 : ETAT AVANT CORRECTION
-- =====================================================
PROMPT
PROMPT ===== BR_AUDIT AVANT CORRECTION =====

SELECT AUDIT_ID, TYPE, TO_CHAR(TIMESTAMP, 'DD/MM/YY HH24:MI') AS TS,
       WHICHONE AS LOAD_ID, BFR_AMT, AFT_AMT, CS_FLAG
FROM BANKREC.BR_AUDIT
WHERE ACCT_ID = 1906
  AND WHICHONE IN (346241, 346285)
  AND TYPE = 15
ORDER BY TIMESTAMP;

PROMPT
PROMPT ===== BRD_EU_JC_SUMMARY AVANT CORRECTION =====

SELECT PERIOD_JC, ACCT_ID, BAL_ST, DIFF
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 2 : CORRECTION BR_AUDIT (SOURCE)
-- =====================================================
PROMPT
PROMPT ===== CORRECTION BR_AUDIT =====
PROMPT audit_id 3276 : bfr_amt 2,55 -> -0,11 / aft_amt 5,21 -> 2,55

UPDATE BANKREC.BR_AUDIT
SET BFR_AMT = -0.11,
    AFT_AMT = 2.55
WHERE ACCT_ID = 1906
  AND AUDIT_ID = 3276
  AND TYPE = 15;

PROMPT Lignes BR_AUDIT modifiees :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 3 : CORRECTION BRD_EU_JC_SUMMARY (EFFET IMMEDIAT)
-- =====================================================
PROMPT
PROMPT ===== CORRECTION BRD_EU_JC_SUMMARY =====
PROMPT BAL_ST : 5,21 -> -0,11 / DIFF : 5,32 -> 0

UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11,
    DIFF = 0
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT Lignes SUMMARY modifiees :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 4 : VERIFICATION APRES CORRECTION
-- =====================================================
PROMPT
PROMPT ===== BR_AUDIT APRES CORRECTION =====

SELECT AUDIT_ID, TYPE, TO_CHAR(TIMESTAMP, 'DD/MM/YY HH24:MI') AS TS,
       WHICHONE AS LOAD_ID, BFR_AMT, AFT_AMT, CS_FLAG
FROM BANKREC.BR_AUDIT
WHERE ACCT_ID = 1906
  AND WHICHONE IN (346241, 346285)
  AND TYPE = 15
ORDER BY TIMESTAMP;

PROMPT
PROMPT ===== BRD_EU_JC_SUMMARY APRES CORRECTION =====

SELECT PERIOD_JC, ACCT_ID, BAL_ST, DIFF
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
PROMPT *** CORRECTION DEFINITIVE TERMINEE ***
PROMPT
PROMPT Valeurs corrigees :
PROMPT   BR_AUDIT 3276 : bfr_amt=-0,11, aft_amt=2,55
PROMPT   SUMMARY       : BAL_ST=-0,11, DIFF=0
PROMPT
PROMPT Le prochain fichier charge utilisera la bonne base (-0,11)
PROMPT L'ecart ne reapparaitra PLUS.
PROMPT
PROMPT =====================================================
PROMPT Pour ROLLBACK (si necessaire) :
PROMPT =====================================================
PROMPT UPDATE BANKREC.BR_AUDIT
PROMPT SET BFR_AMT = 2.55, AFT_AMT = 5.21
PROMPT WHERE ACCT_ID = 1906 AND AUDIT_ID = 3276;
PROMPT
PROMPT UPDATE BANKREC.BRD_EU_JC_SUMMARY
PROMPT SET BAL_ST = 5.21, DIFF = 5.32
PROMPT WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
PROMPT COMMIT;
PROMPT =====================================================

SELECT SYSDATE FROM DUAL;

EXIT SUCCESS;
