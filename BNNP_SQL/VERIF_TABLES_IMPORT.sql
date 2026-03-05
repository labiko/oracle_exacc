-- ============================================================================
-- VÉRIFICATION - Dans quelle table sont les transactions ?
-- ============================================================================

SET LINESIZE 200
SET PAGESIZE 100

PROMPT ============================================================================
PROMPT Vérification de la présence des transactions 22.36 et 2817
PROMPT ============================================================================

PROMPT
PROMPT 1. Dans TA_RN_IMPORT_GESTION_JC ?
PROMPT ----------------------------------------------------------------------------

SELECT COUNT(*) AS "22.36 dans IMPORT_GESTION_JC"
FROM TA_RN_IMPORT_GESTION_JC
WHERE OPERATIONNETAMOUNT = '22.36';

SELECT COUNT(*) AS "2817 dans IMPORT_GESTION_JC"
FROM TA_RN_IMPORT_GESTION_JC
WHERE OPERATIONNETAMOUNT = '2817';

PROMPT
PROMPT 2. Dans TA_RN_IMPORT_GESTION (sans JC) ?
PROMPT ----------------------------------------------------------------------------

SELECT COUNT(*) AS "22.36 dans IMPORT_GESTION"
FROM TA_RN_IMPORT_GESTION
WHERE OPERATIONNETAMOUNT = '22.36';

SELECT COUNT(*) AS "2817 dans IMPORT_GESTION"
FROM TA_RN_IMPORT_GESTION
WHERE OPERATIONNETAMOUNT = '2817';

PROMPT
PROMPT 3. Dans BANKREC.BR_DATA ?
PROMPT ----------------------------------------------------------------------------

SELECT COUNT(*) AS "22.36 dans BR_DATA"
FROM BANKREC.BR_DATA
WHERE ORAMT = '22.36';

SELECT COUNT(*) AS "2817 dans BR_DATA"
FROM BANKREC.BR_DATA
WHERE ORAMT = '2817';

PROMPT
PROMPT ============================================================================
PROMPT INTERPRÉTATION
PROMPT ============================================================================
PROMPT
PROMPT Si 22.36 est dans BR_DATA mais pas dans TA_RN_IMPORT_GESTION :
PROMPT   → Il a été inséré par un AUTRE processus (pas RNADGENEXPGES01.sql)
PROMPT
PROMPT Si 22.36 est dans TA_RN_IMPORT_GESTION_JC :
PROMPT   → C'est le résultat de notre test avec RNADGENJUCGES01_TRACE_COMPLETE.sql
PROMPT   → Mais RNADGENEXPGES01.sql ne traite PAS cette table !
PROMPT
PROMPT ============================================================================
