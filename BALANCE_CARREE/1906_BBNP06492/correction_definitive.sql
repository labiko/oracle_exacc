-- =====================================================
-- correction_definitive.sql
-- Compte : 1906 (BBNP06492-EUR)
-- Ecart  : 2,66 EUR
-- Methode: Option 2 - DELETE records + Correction BAL_ST
-- =====================================================
--
-- PROCEDURE COMPLETE :
-- 1. Supprimer les records orphelins de BR_DATA et BRD_EU_JC_ITEMS
-- 2. Corriger BAL_ST dans BRD_EU_JC_SUMMARY
--
-- FORMULE :
-- Apres DELETE, DIFF double (ex: 2,66 -> 5,32)
-- BAL_ST_nouveau = BAL_ST_actuel - DIFF_actuel
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/correction_definitive.sql
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
PROMPT Methode : Option 2 (DELETE + Correction BAL_ST)
PROMPT =====================================================
SELECT SYSDATE, USER, SYS_CONTEXT('USERENV','INSTANCE_NAME') AS SID FROM DUAL;

-- =====================================================
-- ETAPE 1 : VERIFICATION AVANT CORRECTION
-- =====================================================
PROMPT
PROMPT ===== ETAT AVANT CORRECTION =====

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
PROMPT --- Records orphelins dans BR_DATA (load_id=346241) ---
SELECT record_id, state, amount, cs_flag, pr_flag, load_id
FROM BANKREC.BR_DATA
WHERE acct_id = 1906 AND load_id = 346241;

PROMPT
PROMPT --- Nombre de records orphelins ---
SELECT COUNT(*) AS nb_records FROM BANKREC.BR_DATA WHERE acct_id = 1906 AND load_id = 346241;

-- =====================================================
-- ETAPE 2 : SAUVEGARDE (pour rollback si necessaire)
-- =====================================================
PROMPT
PROMPT ===== SAUVEGARDE POUR ROLLBACK =====

PROMPT Valeurs actuelles :
SELECT 'BAL_ST actuel : ' || BAL_ST || ', DIFF actuel : ' || DIFF AS info
FROM BANKREC.BRD_EU_JC_SUMMARY WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT
PROMPT Pour ROLLBACK complet, executer dans cet ordre :
PROMPT 1. Les INSERT BR_DATA generes par rollback_ecart_solde.sql
PROMPT 2. UPDATE BANKREC.BRD_EU_JC_SUMMARY SET BAL_ST = 5.21 WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
PROMPT 3. COMMIT;

-- =====================================================
-- ETAPE 3 : SUPPRESSION DES RECORDS ORPHELINS
-- =====================================================
PROMPT
PROMPT ===== SUPPRESSION DES RECORDS ORPHELINS =====

PROMPT
PROMPT --- DELETE BR_DATA (load_id=346241) ---
DELETE FROM BANKREC.BR_DATA WHERE acct_id = 1906 AND load_id = 346241;
PROMPT Lignes supprimees dans BR_DATA :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

PROMPT
PROMPT --- DELETE BRD_EU_JC_ITEMS (load_id=346241) ---
DELETE FROM BANKREC.BRD_EU_JC_ITEMS WHERE acct_id = 1906 AND load_id = 346241;
PROMPT Lignes supprimees dans BRD_EU_JC_ITEMS :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 4 : VERIFICATION APRES DELETE (DIFF a double)
-- =====================================================
PROMPT
PROMPT ===== VERIFICATION APRES DELETE =====
PROMPT (L ecart devrait avoir DOUBLE - c est normal)

SELECT
    PERIOD_JC,
    ACCT_ID,
    BAL_ST AS "BAL_ST (inchange)",
    DIFF AS "ECART (double)",
    BAL_ST - DIFF AS "BAL_ST cible"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

-- =====================================================
-- ETAPE 5 : CORRECTION BAL_ST
-- =====================================================
PROMPT
PROMPT ===== CORRECTION BAL_ST =====
PROMPT Formule : BAL_ST = BAL_ST - DIFF

UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = BAL_ST - DIFF
WHERE ACCT_ID = 1906
  AND PERIOD_JC = '202602'
  AND DIFF != 0;

PROMPT Lignes modifiees :
SELECT SQL%ROWCOUNT AS nb_lignes FROM DUAL;

-- =====================================================
-- ETAPE 6 : VERIFICATION FINALE
-- =====================================================
PROMPT
PROMPT ===== VERIFICATION FINALE =====

SELECT
    PERIOD_JC,
    ACCT_ID,
    BAL_ST AS "BAL_ST (nouveau)",
    DIFF AS "ECART (devrait etre 0)"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT
PROMPT --- Verification records supprimes ---
SELECT
    (SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE acct_id = 1906 AND load_id = 346241) AS "BR_DATA restant",
    (SELECT COUNT(*) FROM BANKREC.BRD_EU_JC_ITEMS WHERE acct_id = 1906 AND load_id = 346241) AS "JC_ITEMS restant"
FROM DUAL;

-- =====================================================
-- ETAPE 7 : COMMIT
-- =====================================================
PROMPT
PROMPT =====================================================
PROMPT COMMIT FINAL
PROMPT =====================================================
COMMIT;

PROMPT
PROMPT *** CORRECTION TERMINEE ***
PROMPT
PROMPT Verifier que :
PROMPT   1. DIFF = 0 (ou tres proche)
PROMPT   2. Aucun record dans BR_DATA/BRD_EU_JC_ITEMS pour load_id=346241
PROMPT   3. L interface Balance Carree affiche 0 ecart
PROMPT
PROMPT Pour ROLLBACK :
PROMPT   1. Executer les INSERT de rollback_ecart_solde.sql
PROMPT   2. UPDATE BAL_ST = 5.21
PROMPT   3. COMMIT
PROMPT
SELECT SYSDATE FROM DUAL;
PROMPT =====================================================

EXIT SUCCESS;
