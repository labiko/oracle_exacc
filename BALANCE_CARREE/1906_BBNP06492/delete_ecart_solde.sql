-- delete_ecart_solde_JC_BBNP_06492.sql
-- Compte : 1906 (BBNP06492-EUR)
-- Ecart  : 2,66 EUR (initial) -> 5,32 EUR (apres mauvaise correction)
-- Cause  : Records orphelins load_id 346241 (rollback 25/02/2026)
--
-- =====================================================
-- VERSION 2.0 : Suppression dans BR_DATA ET BRD_EU_JC_ITEMS
-- =====================================================
-- IMPORTANT : Les records orphelins sont dans DEUX tables :
--   1. BR_DATA : les transactions elles-memes
--   2. BRD_EU_JC_ITEMS : les items de la Balance Carree (2 periodes)
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/delete_ecart_solde_JC_BBNP_06492.sql
-- =====================================================

SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
SET LINESIZE 200
SET PAGESIZE 50

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

PROMPT =====================================================
PROMPT Debut execution - DELETE Compte 1906 (VERSION 2.0)
PROMPT =====================================================
SELECT SYSDATE, USER, SYS_CONTEXT('USERENV','INSTANCE_NAME') AS SID FROM DUAL;
PROMPT
PROMPT *** TRANSACTION UNIQUE - ROLLBACK EN CAS D ECHEC ***
PROMPT

-- =====================================================
-- VERIFICATION AVANT DELETE - BR_DATA
-- =====================================================
PROMPT
PROMPT ===== Verification BR_DATA avant DELETE =====

PROMPT Nombre de lignes a supprimer dans BR_DATA :
SELECT COUNT(*) AS nb_br_data_avant FROM BANKREC.BR_DATA WHERE acct_id = 1906 AND load_id = 346241;

PROMPT Detail des lignes BR_DATA :
SELECT record_id, state, amount, cs_flag, trans_date, load_id
FROM BANKREC.BR_DATA
WHERE acct_id = 1906 AND load_id = 346241;

-- =====================================================
-- VERIFICATION AVANT DELETE - BRD_EU_JC_ITEMS
-- =====================================================
PROMPT
PROMPT ===== Verification BRD_EU_JC_ITEMS avant DELETE =====

PROMPT Nombre de lignes a supprimer dans BRD_EU_JC_ITEMS :
SELECT COUNT(*) AS nb_jc_items_avant FROM BANKREC.BRD_EU_JC_ITEMS WHERE acct_id = 1906 AND load_id = 346241;

PROMPT Detail des lignes BRD_EU_JC_ITEMS (par periode) :
SELECT period_jc, record_id, state, amount, cs_flag, trans_date, load_id
FROM BANKREC.BRD_EU_JC_ITEMS
WHERE acct_id = 1906 AND load_id = 346241
ORDER BY period_jc DESC, record_id;

-- =====================================================
-- EXECUTION DES DELETE
-- =====================================================
PROMPT
PROMPT ===== Execution du DELETE BR_DATA =====
DELETE FROM BANKREC.BR_DATA WHERE acct_id = 1906 AND load_id = 346241;

PROMPT Verification apres DELETE BR_DATA :
SELECT COUNT(*) AS nb_br_data_apres FROM BANKREC.BR_DATA WHERE acct_id = 1906 AND load_id = 346241;

PROMPT
PROMPT ===== Execution du DELETE BRD_EU_JC_ITEMS =====
DELETE FROM BANKREC.BRD_EU_JC_ITEMS WHERE acct_id = 1906 AND load_id = 346241;

PROMPT Verification apres DELETE BRD_EU_JC_ITEMS :
SELECT COUNT(*) AS nb_jc_items_apres FROM BANKREC.BRD_EU_JC_ITEMS WHERE acct_id = 1906 AND load_id = 346241;

-- =====================================================
-- COMMIT FINAL
-- =====================================================
PROMPT
PROMPT =====================================================
PROMPT COMMIT FINAL
PROMPT =====================================================
COMMIT;

PROMPT
PROMPT *** TRANSACTION VALIDEE ***
PROMPT
PROMPT Resume :
PROMPT - BR_DATA : records 878, 879 supprimes
PROMPT - BRD_EU_JC_ITEMS : records 878, 879 supprimes (periodes 202602 et 202603)
PROMPT - Ecart Balance Carree devrait etre corrige
PROMPT
SELECT SYSDATE FROM DUAL;
PROMPT =====================================================

EXIT SUCCESS;
