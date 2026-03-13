-- rollback_ecart_solde_JC_BBNP_06492.sql
-- Compte : 1906 (BBNP06492-EUR)
-- Ecart  : 2,66 EUR (initial) -> 5,32 EUR (apres mauvaise correction)
-- But    : Generer les INSERT pour les tables JC (rollback apres DELETE)
-- NOTE   : BR_DATA est gere par datapump_export.sh / datapump_import.sh
--
-- =====================================================
-- INSTRUCTIONS D'EXECUTION
-- =====================================================
-- AVANT le DELETE :
-- 1. Executer ce script pour generer les INSERT JC
-- 2. Copier/sauvegarder les INSERT generes (BRD_EU_JC_ITEMS, BRD_EU_JC_SUMMARY)
-- 3. Executer le DELETE + UPDATE BAL_ST (correction_definitive.sql)
-- 4. Si rollback necessaire : Executer les INSERT sauvegardes
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/rollback_ecart_solde.sql
-- =====================================================
-- VERSION 3.0 :
--   - BR_DATA supprime (gere par datapump)
--   - Genere INSERT pour BRD_EU_JC_ITEMS ET BRD_EU_JC_SUMMARY uniquement
--   - BRD_EU_JC_SUMMARY : Inclut DELETE avant INSERT (contrainte UNIQUE)
-- =====================================================

SET ECHO OFF
SET FEEDBACK OFF
SET HEADING OFF
SET PAGESIZE 0
SET LINESIZE 4000
SET TRIMSPOOL ON
SET LONG 100000

-- Force le point decimal (evite la virgule francaise)
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,';

PROMPT -- =====================================================
PROMPT -- INSERT generes pour rollback - Compte 1906, Load 346241
PROMPT -- Executez ce SELECT AVANT le DELETE pour sauvegarder les donnees
PROMPT -- VERSION 3.0 : Tables JC uniquement (BR_DATA via datapump)
PROMPT -- =====================================================
PROMPT

PROMPT -- =====================================================
PROMPT -- PARTIE 1 : INSERT BRD_EU_JC_ITEMS
PROMPT -- =====================================================
PROMPT -- Structure : PERIOD_JC, ACCT_ID, RECORD_ID, STATE, LOAD_ID,
PROMPT --             REC_GROUP, NUM_IN_GROUP, CS_FLAG, PR_FLAG, AMOUNT,
PROMPT --             REC_TIME, ORIG_ID, REFER_DATE
PROMPT -- =====================================================

SELECT
  'INSERT INTO BRD_EU_JC_ITEMS (PERIOD_JC,ACCT_ID,RECORD_ID,STATE,LOAD_ID,REC_GROUP,NUM_IN_GROUP,CS_FLAG,PR_FLAG,AMOUNT,REC_TIME,ORIG_ID,REFER_DATE) VALUES ('
  || '''' || PERIOD_JC || ''','
  || ACCT_ID || ','
  || RECORD_ID || ','
  || STATE || ','
  || LOAD_ID || ','
  || NVL(TO_CHAR(REC_GROUP), 'NULL') || ','
  || NVL(TO_CHAR(NUM_IN_GROUP), 'NULL') || ','
  || '''' || CS_FLAG || ''','
  || '''' || PR_FLAG || ''','
  || AMOUNT || ','
  || NVL2(REC_TIME, 'TO_DATE(''' || TO_CHAR(REC_TIME,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  || NVL(TO_CHAR(ORIG_ID), 'NULL') || ','
  || NVL2(REFER_DATE, 'TO_DATE(''' || TO_CHAR(REFER_DATE,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL')
  || ');' AS insert_stmt
FROM BRD_EU_JC_ITEMS
WHERE acct_id = 1906 AND load_id = 346241
ORDER BY PERIOD_JC DESC, RECORD_ID;

PROMPT
PROMPT -- =====================================================
PROMPT -- PARTIE 2 : INSERT BRD_EU_JC_SUMMARY
PROMPT -- =====================================================
PROMPT -- Structure : Toutes les colonnes de resume Balance Carree
PROMPT -- NOTE : Cette table a une contrainte UNIQUE sur (ACCT_ID, PERIOD_JC)
PROMPT --        Pour rollback : DELETE existant PUIS INSERT
PROMPT -- =====================================================

SELECT
  '-- DELETE existant avant INSERT :' || CHR(10) ||
  'DELETE FROM BRD_EU_JC_SUMMARY WHERE ACCT_ID = ' || ACCT_ID || ' AND PERIOD_JC = ''' || PERIOD_JC || ''';' || CHR(10) ||
  'INSERT INTO BRD_EU_JC_SUMMARY (PERIOD_JC,ACCT_ID,ACCT_NAME,BAL_ST,BAL_CB,SUM_ST_P,SUM_ST_R,SUM_CB_P,SUM_CB_R,DIFF) VALUES ('
  || '''' || PERIOD_JC || ''','
  || ACCT_ID || ','
  || NVL2(ACCT_NAME, '''' || REPLACE(ACCT_NAME,'''','''''') || '''', 'NULL') || ','
  || NVL(TO_CHAR(BAL_ST), 'NULL') || ','
  || NVL(TO_CHAR(BAL_CB), 'NULL') || ','
  || NVL(TO_CHAR(SUM_ST_P), 'NULL') || ','
  || NVL(TO_CHAR(SUM_ST_R), 'NULL') || ','
  || NVL(TO_CHAR(SUM_CB_P), 'NULL') || ','
  || NVL(TO_CHAR(SUM_CB_R), 'NULL') || ','
  || NVL(TO_CHAR(DIFF), 'NULL')
  || ');' AS insert_stmt
FROM BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

PROMPT
PROMPT -- =====================================================
PROMPT -- Fin des INSERT generes (BRD_EU_JC_ITEMS + BRD_EU_JC_SUMMARY)
PROMPT -- Pour BR_DATA : utiliser datapump_import.sh
PROMPT -- Executer ces INSERT puis COMMIT;
PROMPT -- =====================================================
