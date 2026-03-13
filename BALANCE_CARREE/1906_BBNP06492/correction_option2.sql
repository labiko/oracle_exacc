-- =====================================================
-- correction_option2.sql
-- Compte : 1906 (BBNP06492-EUR)
-- Ecart  : 2,66 EUR
-- Methode: Suppression records + Correction BAL_ST (Option 2)
-- =====================================================
--
-- PRINCIPE :
-- 1. Supprimer les records orphelins 878/879 de BR_DATA et BRD_EU_JC_ITEMS
-- 2. Corriger BAL_ST de 5,21 a -0,11
--
-- ATTENTION : Cette option est plus risquee !
-- Executer rollback_ecart_solde.sql AVANT pour sauvegarder les INSERT
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/correction_option2.sql
-- =====================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 50

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

PROMPT =====================================================
PROMPT CORRECTION ECART BALANCE CARREE - Compte 1906
PROMPT Methode : Suppression records + Correction BAL_ST (Option 2)
PROMPT =====================================================
PROMPT
PROMPT *** ATTENTION : METHODE PLUS RISQUEE ***
PROMPT *** ASSUREZ-VOUS D'AVOIR SAUVEGARDE LES DONNEES ***
PROMPT
SELECT SYSDATE, USER, SYS_CONTEXT('USERENV','INSTANCE_NAME') AS SID FROM DUAL;

-- =====================================================
-- ETAPE 1 : VERIFICATION AVANT CORRECTION
-- =====================================================
PROMPT
PROMPT ===== ETAT AVANT CORRECTION =====

PROMPT
PROMPT --- BRD_EU_JC_SUMMARY (periode 202602) ---
SELECT PERIOD_JC, ACCT_ID, BAL_ST, DIFF
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT
PROMPT --- Records a supprimer dans BR_DATA ---
SELECT record_id, state, amount, cs_flag, pr_flag, load_id
FROM BANKREC.BR_DATA
WHERE acct_id = 1906 AND load_id = 346241;

PROMPT
PROMPT --- Records a supprimer dans BRD_EU_JC_ITEMS ---
SELECT period_jc, record_id, amount, load_id
FROM BANKREC.BRD_EU_JC_ITEMS
WHERE acct_id = 1906 AND load_id = 346241;

-- =====================================================
-- ETAPE 2 : SUPPRESSION DES RECORDS ORPHELINS
-- =====================================================
PROMPT
PROMPT ===== SUPPRESSION DES RECORDS ORPHELINS =====

PROMPT
PROMPT --- DELETE BR_DATA ---
DELETE FROM BANKREC.BR_DATA WHERE acct_id = 1906 AND load_id = 346241;
PROMPT Lignes supprimees BR_DATA :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

PROMPT
PROMPT --- DELETE BRD_EU_JC_ITEMS ---
DELETE FROM BANKREC.BRD_EU_JC_ITEMS WHERE acct_id = 1906 AND load_id = 346241;
PROMPT Lignes supprimees BRD_EU_JC_ITEMS :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 3 : CORRECTION BAL_ST
-- =====================================================
PROMPT
PROMPT ===== CORRECTION BAL_ST =====
PROMPT Modification BAL_ST : 5,21 -> -0,11

UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT Lignes modifiees :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 4 : VERIFICATION APRES CORRECTION
-- =====================================================
PROMPT
PROMPT ===== ETAT APRES CORRECTION =====

PROMPT
PROMPT --- BRD_EU_JC_SUMMARY (periode 202602) ---
SELECT
    PERIOD_JC,
    ACCT_ID,
    BAL_ST AS "BAL_ST (Bank)",
    DIFF AS "ECART"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT
PROMPT --- Verification BR_DATA (doit etre vide pour load_id=346241) ---
SELECT COUNT(*) AS nb_records FROM BANKREC.BR_DATA WHERE acct_id = 1906 AND load_id = 346241;

PROMPT
PROMPT --- Verification BRD_EU_JC_ITEMS (doit etre vide pour load_id=346241) ---
SELECT COUNT(*) AS nb_items FROM BANKREC.BRD_EU_JC_ITEMS WHERE acct_id = 1906 AND load_id = 346241;

-- =====================================================
-- ETAPE 5 : COMMIT
-- =====================================================
PROMPT
PROMPT =====================================================
PROMPT COMMIT FINAL
PROMPT =====================================================
COMMIT;

PROMPT
PROMPT *** CORRECTION TERMINEE (OPTION 2) ***
PROMPT
PROMPT Pour rollback, executer les INSERT sauvegardes puis :
PROMPT UPDATE BANKREC.BRD_EU_JC_SUMMARY SET BAL_ST = 5.21 WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
PROMPT
SELECT SYSDATE FROM DUAL;
PROMPT =====================================================

EXIT SUCCESS;
