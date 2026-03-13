-- rollback_ecart_solde_JC_BBNP_06492.sql
-- Compte : 1906 (BBNP06492-EUR)
-- Ecart  : 2,66 EUR (initial) -> 5,32 EUR (apres mauvaise correction)
-- But    : Generer les INSERT pour pouvoir rollback apres DELETE
-- IMPORTANT : EXP_RNAPA.BR_DATA est un SYNONYME vers BANKREC.BR_DATA (meme table)
--
-- =====================================================
-- INSTRUCTIONS D'EXECUTION
-- =====================================================
-- AVANT le DELETE :
-- 1. Executer ce script pour generer les INSERT
-- 2. Copier/sauvegarder les INSERT generes (BR_DATA ET BRD_EU_JC_ITEMS)
-- 3. Executer le DELETE
-- 4. Si rollback necessaire : Executer les INSERT sauvegardes
--
-- Connexion : sesu - oracle
-- Commande  : sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/rollback_ecart_solde_JC_BBNP_06492.sql
-- =====================================================
-- VERSION 2.3 :
--   - Genere INSERT pour BR_DATA ET BRD_EU_JC_ITEMS
--   - BRD_EU_JC_ITEMS : Structure corrigee (13 colonnes seulement)
--   - CHR() au lieu de UNISTR() pour eviter problemes encodage
--   - RTRIM sur TRANS_TYPE (peut contenir espaces != NULL)
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
PROMPT -- VERSION 2.3 : Genere INSERT pour BR_DATA ET BRD_EU_JC_ITEMS
PROMPT -- =====================================================
PROMPT
PROMPT -- =====================================================
PROMPT -- PARTIE 1 : INSERT BR_DATA
PROMPT -- =====================================================

-- Fonction helper pour convertir les codes ASCIISTR en CHR()
-- \00E9 -> ' || CHR(233) || '  (e accent aigu)
-- \00E8 -> ' || CHR(232) || '  (e accent grave)
-- \00E0 -> ' || CHR(224) || '  (a accent grave)
-- \00E7 -> ' || CHR(231) || '  (c cedille)
-- \00F9 -> ' || CHR(249) || '  (u accent grave)
-- \00EA -> ' || CHR(234) || '  (e accent circonflexe)
-- \00EE -> ' || CHR(238) || '  (i accent circonflexe)
-- \00F4 -> ' || CHR(244) || '  (o accent circonflexe)
-- \00FB -> ' || CHR(251) || '  (u accent circonflexe)
-- \00E2 -> ' || CHR(226) || '  (a accent circonflexe)

SELECT
  'INSERT INTO BR_DATA (ACCT_ID,RECORD_ID,STATE,CS_FLAG,PR_FLAG,PP_FLAG,TRANS_DATE,VALUE_DATE,NARRATIVE,INTL_REF,EXTL_REF,AMOUNT,TRANS_TYPE,USER_ONE,USER_TWO,USER_THREE,USER_FOUR,USER_FIVE,USER_SIX,UPD_TIME,REC_GROUP,ORIG_CCY,NUM_NOTES,NOTE_GROUP,ORIG_ID,NOTE_ADD,WF_STATUS,WF_REF,CREATEDBY,RECMETHOD,DEPARTMENT,LASTAUDIT,SUB_ACCT,LOCK_FLG,ALT_AMT,NUM_IN_GRP,PASS_ID,FLAG_A,FLAG_B,FLAG_C,FLAG_D,FLAG_E,FLAG_F,FLAG_G,FLAG_H,QUANTITY,USER_DEC_A,UNITPRICE,USERDATE_A,USERDATE_B,USER_SEVEN,USER_EIGHT,PERIOD,LAST_NOTE_TEXT,LAST_NOTE_USER,IS_UNDER_INV,USER_NINE,USER_TEN,USER_ELEVEN,USER_TWELVE,USER_THIRTEEN,USER_FOURTEEN,USER_FIFTEEN,USER_SIXTEEN,USERDATE_C,USERDATE_D,USER_DEC_B,USER_DEC_C,USER_DEC_D,LOAD_ID,DIFF_REF,CREATED_DATE,CYCLE_DATE,CYCLE_NAME,CERTIFICATION_STATE) VALUES ('
  || ACCT_ID || ','
  || RECORD_ID || ','
  || '''' || STATE || ''','
  || '''' || CS_FLAG || ''','
  || NVL2(PR_FLAG, '''' || PR_FLAG || '''', 'NULL') || ','
  || NVL2(PP_FLAG, '''' || PP_FLAG || '''', 'NULL') || ','
  || NVL2(TRANS_DATE, 'TO_DATE(''' || TO_CHAR(TRANS_DATE,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  || NVL2(VALUE_DATE, 'TO_DATE(''' || TO_CHAR(VALUE_DATE,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  -- NARRATIVE : Conversion ASCIISTR -> CHR() pour les accents
  || NVL2(NARRATIVE, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(REPLACE(RTRIM(NARRATIVE),'''','''''')),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(INTL_REF, '''' || INTL_REF || '''', 'NULL') || ','
  || NVL2(EXTL_REF, '''' || EXTL_REF || '''', 'NULL') || ','
  || NVL(TO_CHAR(AMOUNT), 'NULL') || ','
  -- TRANS_TYPE : RTRIM pour gerer les espaces (qui ne sont pas NULL)
  || NVL2(RTRIM(TRANS_TYPE), '''' || RTRIM(TRANS_TYPE) || '''', 'NULL') || ','
  -- USER_ONE a USER_SIX : Conversion ASCIISTR -> CHR()
  || NVL2(USER_ONE, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_ONE),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_TWO, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_TWO),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_THREE, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_THREE),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_FOUR, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_FOUR),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_FIVE, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_FIVE),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_SIX, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_SIX),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(UPD_TIME, 'TO_DATE(''' || TO_CHAR(UPD_TIME,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  || NVL(TO_CHAR(REC_GROUP), 'NULL') || ','
  || NVL2(ORIG_CCY, '''' || ORIG_CCY || '''', 'NULL') || ','
  || NVL(TO_CHAR(NUM_NOTES), 'NULL') || ','
  || NVL(TO_CHAR(NOTE_GROUP), 'NULL') || ','
  || NVL(TO_CHAR(ORIG_ID), 'NULL') || ','
  || NVL2(NOTE_ADD, 'TO_DATE(''' || TO_CHAR(NOTE_ADD,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  || NVL2(WF_STATUS, '''' || WF_STATUS || '''', 'NULL') || ','
  || NVL2(WF_REF, '''' || RTRIM(WF_REF) || '''', 'NULL') || ','
  || NVL(TO_CHAR(CREATEDBY), 'NULL') || ','
  || NVL2(RECMETHOD, '''' || RECMETHOD || '''', 'NULL') || ','
  || NVL2(DEPARTMENT, '''' || DEPARTMENT || '''', 'NULL') || ','
  || NVL(TO_CHAR(LASTAUDIT), 'NULL') || ','
  || NVL2(SUB_ACCT, '''' || SUB_ACCT || '''', 'NULL') || ','
  || NVL2(LOCK_FLG, '''' || LOCK_FLG || '''', 'NULL') || ','
  || NVL(TO_CHAR(ALT_AMT), 'NULL') || ','
  || NVL(TO_CHAR(NUM_IN_GRP), 'NULL') || ','
  || NVL(TO_CHAR(PASS_ID), 'NULL') || ','
  || NVL2(FLAG_A, '''' || FLAG_A || '''', 'NULL') || ','
  || NVL2(FLAG_B, '''' || FLAG_B || '''', 'NULL') || ','
  || NVL2(FLAG_C, '''' || FLAG_C || '''', 'NULL') || ','
  || NVL2(FLAG_D, '''' || FLAG_D || '''', 'NULL') || ','
  || NVL2(FLAG_E, '''' || FLAG_E || '''', 'NULL') || ','
  || NVL2(FLAG_F, '''' || FLAG_F || '''', 'NULL') || ','
  || NVL2(FLAG_G, '''' || FLAG_G || '''', 'NULL') || ','
  || NVL2(FLAG_H, '''' || FLAG_H || '''', 'NULL') || ','
  || NVL(TO_CHAR(QUANTITY), 'NULL') || ','
  || NVL(TO_CHAR(USER_DEC_A), 'NULL') || ','
  || NVL(TO_CHAR(UNITPRICE), 'NULL') || ','
  || NVL2(USERDATE_A, 'TO_DATE(''' || TO_CHAR(USERDATE_A,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  || NVL2(USERDATE_B, 'TO_DATE(''' || TO_CHAR(USERDATE_B,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  -- USER_SEVEN a USER_SIXTEEN : Conversion ASCIISTR -> CHR()
  || NVL2(USER_SEVEN, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_SEVEN),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_EIGHT, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_EIGHT),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(PERIOD, '''' || PERIOD || '''', 'NULL') || ','
  -- LAST_NOTE_TEXT : Conversion ASCIISTR -> CHR()
  || NVL2(LAST_NOTE_TEXT, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(REPLACE(RTRIM(LAST_NOTE_TEXT),'''','''''')),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(LAST_NOTE_USER, '''' || LAST_NOTE_USER || '''', 'NULL') || ','
  || NVL2(IS_UNDER_INV, '''' || IS_UNDER_INV || '''', 'NULL') || ','
  -- USER_NINE a USER_SIXTEEN : Conversion ASCIISTR -> CHR()
  || NVL2(USER_NINE, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_NINE),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_TEN, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_TEN),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_ELEVEN, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_ELEVEN),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_TWELVE, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_TWELVE),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_THIRTEEN, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_THIRTEEN),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_FOURTEEN, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_FOURTEEN),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_FIFTEEN, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_FIFTEEN),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USER_SIXTEEN, '''' || REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
       ASCIISTR(SUBSTRB(REPLACE(RTRIM(USER_SIXTEEN),'''',''''''),1,25)),
       '\00E9',''''' || CHR(233) || '''),
       '\00E8',''''' || CHR(232) || '''),
       '\00E0',''''' || CHR(224) || '''),
       '\00E7',''''' || CHR(231) || '''),
       '\00F9',''''' || CHR(249) || '''),
       '\00EA',''''' || CHR(234) || '''),
       '\00EE',''''' || CHR(238) || '''),
       '\00F4',''''' || CHR(244) || '''),
       '\00FB',''''' || CHR(251) || '''),
       '\00E2',''''' || CHR(226) || ''') || '''', 'NULL') || ','
  || NVL2(USERDATE_C, 'TO_DATE(''' || TO_CHAR(USERDATE_C,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  || NVL2(USERDATE_D, 'TO_DATE(''' || TO_CHAR(USERDATE_D,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  || NVL(TO_CHAR(USER_DEC_B), 'NULL') || ','
  || NVL(TO_CHAR(USER_DEC_C), 'NULL') || ','
  || NVL(TO_CHAR(USER_DEC_D), 'NULL') || ','
  || LOAD_ID || ','
  || NVL2(DIFF_REF, '''' || DIFF_REF || '''', 'NULL') || ','
  || NVL2(CREATED_DATE, 'TO_DATE(''' || TO_CHAR(CREATED_DATE,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  || NVL2(CYCLE_DATE, 'TO_DATE(''' || TO_CHAR(CYCLE_DATE,'YYYY-MM-DD HH24:MI:SS') || ''',''YYYY-MM-DD HH24:MI:SS'')', 'NULL') || ','
  || NVL2(CYCLE_NAME, '''' || CYCLE_NAME || '''', 'NULL') || ','
  || NVL2(CERTIFICATION_STATE, '''' || CERTIFICATION_STATE || '''', 'NULL')
  || ');' AS insert_stmt
FROM BR_DATA
WHERE acct_id = 1906 AND load_id = 346241;

PROMPT
PROMPT -- Fin des INSERT BR_DATA
PROMPT

PROMPT -- =====================================================
PROMPT -- PARTIE 2 : INSERT BRD_EU_JC_ITEMS
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
PROMPT -- Fin des INSERT generes (BR_DATA + BRD_EU_JC_ITEMS)
PROMPT -- Executer ces INSERT puis COMMIT;
PROMPT -- =====================================================
