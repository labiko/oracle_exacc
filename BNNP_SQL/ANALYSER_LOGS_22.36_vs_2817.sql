-- ============================================================================
-- ANALYSER LOGS - Comparaison 22.36 vs 2817
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Analyser les logs pour comparer le traitement de 22.36 vs 2817
-- ============================================================================

SET LINESIZE 200
SET PAGESIZE 1000

PROMPT ============================================================================
PROMPT 1. RECHERCHE DES TRANSACTIONS CIBLES DANS LES LOGS
PROMPT ============================================================================

SELECT
    TO_CHAR(DT_EXECUTION, 'DD/MM/YYYY HH24:MI:SS') AS DATE_LOG,
    TYPE_LOG,
    NOM_BALISE,
    VALEUR_EXTRAITE,
    MESSAGE,
    ETAPE
FROM TA_RN_LOG_EXECUTION
WHERE (VALEUR_EXTRAITE LIKE '%22.36%'
       OR VALEUR_EXTRAITE LIKE '%2817%'
       OR MESSAGE LIKE '%22.36%'
       OR MESSAGE LIKE '%2817%'
       OR MESSAGE LIKE '%CIBLE%')
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 2. VÉRIFICATION SI 22.36 ET 2817 SONT DANS LE XML
PROMPT ============================================================================

SELECT
    CASE
        WHEN MESSAGE LIKE '%22.36%' THEN '22.36'
        WHEN MESSAGE LIKE '%2817%' THEN '2817'
    END AS TRANSACTION,
    TYPE_LOG,
    MESSAGE,
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS') AS HEURE
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE LIKE '%TROUVEE dans le XML%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 3. VÉRIFICATION SI 22.36 ET 2817 SONT INSÉRÉS DANS TA_RN_IMPORT_GESTION_JC
PROMPT ============================================================================

SELECT
    CASE
        WHEN VALEUR_EXTRAITE LIKE '%22.36%' THEN '✅ 22.36'
        WHEN VALEUR_EXTRAITE LIKE '%2817%' THEN '✅ 2817'
    END AS TRANSACTION,
    SUBSTR(VALEUR_EXTRAITE, 1, 150) AS DETAILS,
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS') AS HEURE_INSERT
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE = 'Transaction inseree dans TA_RN_IMPORT_GESTION_JC'
  AND (VALEUR_EXTRAITE LIKE '%22.36%' OR VALEUR_EXTRAITE LIKE '%2817%')
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 4. VÉRIFICATION DES COMMIT
PROMPT ============================================================================

SELECT
    TO_CHAR(DT_EXECUTION, 'DD/MM/YYYY HH24:MI:SS') AS DATE_COMMIT,
    TYPE_LOG,
    MESSAGE,
    VALEUR_EXTRAITE
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE LIKE '%COMMIT%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 5. ANALYSE DU TEST EXISTS POUR CHAQUE COMPTE ACCURATE
PROMPT ============================================================================

SELECT
    SUBSTR(VALEUR_EXTRAITE, 1, 10) AS ID_COMPTE,
    SUBSTR(VALEUR_EXTRAITE, INSTR(VALEUR_EXTRAITE, '(') + 1,
           INSTR(VALEUR_EXTRAITE, ')') - INSTR(VALEUR_EXTRAITE, '(') - 1) AS NUM_COMPTE,
    SUBSTR(VALEUR_EXTRAITE, INSTR(VALEUR_EXTRAITE, '-') + 2) AS NB_TRANSACTIONS,
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS') AS HEURE
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE = 'Test EXISTS TA_RN_GESTION_JC pour compte accurate'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 6. COMPTES QUI ONT DES TRANSACTIONS À INSÉRER
PROMPT ============================================================================

SELECT
    SUBSTR(VALEUR_EXTRAITE, 1, 10) AS ID_COMPTE,
    VALEUR_EXTRAITE AS DETAILS_COMPLET
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE = 'Test EXISTS TA_RN_GESTION_JC pour compte accurate'
  AND VALEUR_EXTRAITE NOT LIKE '%0 transactions%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 7. COMPTES AVEC 0 TRANSACTIONS (BLOQUÉS)
PROMPT ============================================================================

SELECT
    SUBSTR(VALEUR_EXTRAITE, 1, 10) AS ID_COMPTE,
    VALEUR_EXTRAITE AS DETAILS_COMPLET
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE = 'Test EXISTS TA_RN_GESTION_JC pour compte accurate'
  AND VALEUR_EXTRAITE LIKE '%0 transactions%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 8. INSERTIONS RÉELLES DANS TA_RN_EXPORT_JC
PROMPT ============================================================================

SELECT
    SUBSTR(VALEUR_EXTRAITE, 1, 10) AS ID_COMPTE,
    VALEUR_EXTRAITE AS DETAILS_COMPLET,
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS') AS HEURE
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE LIKE '%INSERT dans TA_RN_EXPORT_JC complete%'
  AND VALEUR_EXTRAITE NOT LIKE '%0 lignes%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 9. ERREURS ET WARNINGS
PROMPT ============================================================================

SELECT
    TO_CHAR(DT_EXECUTION, 'DD/MM/YYYY HH24:MI:SS') AS DATE_LOG,
    TYPE_LOG,
    NOM_BALISE,
    VALEUR_EXTRAITE,
    MESSAGE,
    CODE_ERREUR
FROM TA_RN_LOG_EXECUTION
WHERE TYPE_LOG IN ('ERROR', 'EXCEPTION', 'WARNING')
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 10. RÉSUMÉ GLOBAL
PROMPT ============================================================================

SELECT
    'Total lignes XML' AS METRIQUE,
    SUBSTR(VALEUR_EXTRAITE, 1, 20) AS VALEUR
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE = 'Nombre de lignes XML chargees'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'

UNION ALL

SELECT
    'Transactions inserees dans IMPORT' AS METRIQUE,
    SUBSTR(VALEUR_EXTRAITE, INSTR(VALEUR_EXTRAITE, ':') + 2) AS VALEUR
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE LIKE '%Total final%transactions%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'

UNION ALL

SELECT
    '22.36 trouvée dans XML?' AS METRIQUE,
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END AS VALEUR
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE LIKE '%22.36 TROUVEE dans le XML%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'

UNION ALL

SELECT
    '2817 trouvée dans XML?' AS METRIQUE,
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END AS VALEUR
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE LIKE '%2817 TROUVEE dans le XML%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'

UNION ALL

SELECT
    '22.36 insérée dans IMPORT?' AS METRIQUE,
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END AS VALEUR
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE = 'Transaction inseree dans TA_RN_IMPORT_GESTION_JC'
  AND VALEUR_EXTRAITE LIKE '%22.36%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'

UNION ALL

SELECT
    '2817 insérée dans IMPORT?' AS METRIQUE,
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END AS VALEUR
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE = 'Transaction inseree dans TA_RN_IMPORT_GESTION_JC'
  AND VALEUR_EXTRAITE LIKE '%2817%'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE';

PROMPT
PROMPT ============================================================================
PROMPT FIN DE L'ANALYSE
PROMPT ============================================================================
