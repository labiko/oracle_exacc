-- =====================================================
-- correction_BR_AUDIT_option.sql
-- Compte : 1906 (BBNP06492-EUR)
-- Periode : 202602 (Fevrier 2026)
-- =====================================================
-- *** ATTENTION : MODIFIER BR_AUDIT EST RISQUE ***
-- *** UTILISER EN DERNIER RECOURS UNIQUEMENT ***
--
-- CONTEXTE :
--   Le rollback du load 346241 a echoue partiellement.
--   Le load 346285 a utilise bfr_amt=2,55 au lieu de -0,11.
--
-- DONNEES BR_AUDIT ACTUELLES :
--   audit_id 3262 : type=15, load 346241, bfr_amt=-0,11, aft_amt=2,55
--   audit_id 3276 : type=15, load 346285, bfr_amt=2,55, aft_amt=5,21
--
-- CORRECTION A LA SOURCE :
--   Option A : Supprimer l'entree 3262 + Corriger 3276
--   Option B : Seulement corriger 3276 (bfr_amt et aft_amt)
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/correction_BR_AUDIT_option.sql
-- =====================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 50

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

PROMPT =====================================================
PROMPT *** ATTENTION : MODIFICATION BR_AUDIT ***
PROMPT *** RISQUE ELEVE - UTILISER EN DERNIER RECOURS ***
PROMPT =====================================================
SELECT SYSDATE, USER FROM DUAL;

-- =====================================================
-- ETAPE 1 : ETAT AVANT CORRECTION
-- =====================================================
PROMPT
PROMPT ===== DONNEES BR_AUDIT AVANT CORRECTION =====

SELECT AUDIT_ID, TYPE, TIMESTAMP, WHICHONE AS LOAD_ID,
       BFR_AMT, AFT_AMT, CS_FLAG
FROM BANKREC.BR_AUDIT
WHERE ACCT_ID = 1906
  AND WHICHONE IN (346241, 346285)
  AND TYPE IN (15, 16, 18)
ORDER BY TIMESTAMP;

-- =====================================================
-- ETAPE 2 : VERIFICATION BRD_EU_JC_SUMMARY
-- =====================================================
PROMPT
PROMPT ===== ETAT BRD_EU_JC_SUMMARY AVANT =====

SELECT PERIOD_JC, BAL_ST, DIFF
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 3 : CORRECTION BR_AUDIT
-- =====================================================
PROMPT
PROMPT ===== CORRECTION BR_AUDIT =====
PROMPT Option choisie : Corriger audit_id 3276 (bfr_amt, aft_amt)
PROMPT Ancienne valeur : bfr_amt=2,55, aft_amt=5,21
PROMPT Nouvelle valeur : bfr_amt=-0,11, aft_amt=2,55

-- Calculer le delta pour ajuster aft_amt
-- Le load 346285 a ajoute +2,66 EUR
-- Si bfr_amt passe de 2,55 a -0,11 (delta -2,66)
-- Alors aft_amt doit aussi baisser de -2,66 : 5,21 - 2,66 = 2,55

UPDATE BANKREC.BR_AUDIT
SET BFR_AMT = -0.11,
    AFT_AMT = 2.55
WHERE ACCT_ID = 1906
  AND AUDIT_ID = 3276
  AND TYPE = 15;

PROMPT Lignes modifiees BR_AUDIT :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 4 : CORRECTION BRD_EU_JC_SUMMARY (coherence)
-- =====================================================
PROMPT
PROMPT ===== CORRECTION BRD_EU_JC_SUMMARY =====

UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11,
    DIFF = 0
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT Lignes modifiees SUMMARY :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 5 : VERIFICATION APRES CORRECTION
-- =====================================================
PROMPT
PROMPT ===== DONNEES BR_AUDIT APRES CORRECTION =====

SELECT AUDIT_ID, TYPE, TIMESTAMP, WHICHONE AS LOAD_ID,
       BFR_AMT, AFT_AMT, CS_FLAG
FROM BANKREC.BR_AUDIT
WHERE ACCT_ID = 1906
  AND WHICHONE IN (346241, 346285)
  AND TYPE IN (15, 16, 18)
ORDER BY TIMESTAMP;

PROMPT
PROMPT ===== ETAT BRD_EU_JC_SUMMARY APRES =====

SELECT PERIOD_JC, BAL_ST, DIFF
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
PROMPT *** CORRECTION BR_AUDIT TERMINEE ***
PROMPT
PROMPT Valeurs corrigees :
PROMPT   BR_AUDIT 3276 : bfr_amt=-0,11, aft_amt=2,55
PROMPT   SUMMARY       : BAL_ST=-0,11, DIFF=0
PROMPT
PROMPT Pour ROLLBACK BR_AUDIT :
PROMPT   UPDATE BANKREC.BR_AUDIT
PROMPT   SET BFR_AMT = 2.55, AFT_AMT = 5.21
PROMPT   WHERE ACCT_ID = 1906 AND AUDIT_ID = 3276;
PROMPT
PROMPT Pour ROLLBACK SUMMARY :
PROMPT   UPDATE BANKREC.BRD_EU_JC_SUMMARY
PROMPT   SET BAL_ST = 5.21, DIFF = 5.32
PROMPT   WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
PROMPT   COMMIT;
PROMPT

SELECT SYSDATE FROM DUAL;
PROMPT =====================================================

EXIT SUCCESS;
