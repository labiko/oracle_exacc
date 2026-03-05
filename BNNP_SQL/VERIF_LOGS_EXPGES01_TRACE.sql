-- ============================================================================
-- VÉRIFICATION DES LOGS - RNADGENEXPGES01_TRACE_COMPLETE.sql
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Analyser les logs après exécution de RNADGENEXPGES01_TRACE_COMPLETE.sql
-- ============================================================================

SET LINESIZE 300
SET PAGESIZE 200

PROMPT ============================================================================
PROMPT 1. RÉSUMÉ DES LOGS PAR ÉTAPE
PROMPT ============================================================================

SELECT
    ETAPE,
    TYPE_LOG,
    COUNT(*) AS NB_LOGS,
    MIN(TO_CHAR(DT_EXECUTION, 'HH24:MI:SS')) AS HEURE_DEBUT,
    MAX(TO_CHAR(DT_EXECUTION, 'HH24:MI:SS')) AS HEURE_FIN
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
GROUP BY ETAPE, TYPE_LOG
ORDER BY ETAPE, TYPE_LOG;

PROMPT
PROMPT ============================================================================
PROMPT 2. RECHERCHE DES TRANSACTIONS 22.36 ET 2817 DANS LE XML
PROMPT ============================================================================

SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    TYPE_LOG,
    MESSAGE,
    SUBSTR(VALEUR_EXTRAITE, 1, 100) AS VALEUR
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND (MESSAGE LIKE '%22.36%DANS LE XML%' OR MESSAGE LIKE '%2817%DANS LE XML%')
ORDER BY DT_EXECUTION;

PROMPT
PROMPT Si aucune ligne → Les transactions ne sont pas dans le XML source ❌
PROMPT

PROMPT ============================================================================
PROMPT 3. INSERTION DES TRANSACTIONS 22.36 ET 2817 DANS TA_RN_IMPORT_GESTION
PROMPT ============================================================================

SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    TYPE_LOG,
    MESSAGE,
    NOM_BALISE,
    SUBSTR(VALEUR_EXTRAITE, 1, 150) AS VALEUR
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND MESSAGE LIKE '%TRANSACTION CIBLE%INSEREE%'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT Si vide → Les transactions n'ont pas été insérées dans TA_RN_IMPORT_GESTION ❌
PROMPT

PROMPT ============================================================================
PROMPT 4. TOTAL DE TRANSACTIONS INSÉRÉES
PROMPT ============================================================================

SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    MESSAGE,
    VALEUR_EXTRAITE
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND MESSAGE LIKE '%COMMIT final%'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 5. TEST EXISTS - COMPTES DANS TA_RN_GESTION_ACCURATE
PROMPT ============================================================================
PROMPT CRITIQUE : Vérifie si les comptes 394 et 342 sont trouvés

SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    TYPE_LOG,
    NOM_BALISE,
    SUBSTR(VALEUR_EXTRAITE, 1, 200) AS INFO_COMPTE
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND (MESSAGE LIKE '%Test EXISTS TA_RN_GESTION_ACCURATE%'
       OR MESSAGE LIKE '%NON trouve dans TA_RN_GESTION_ACCURATE%')
ORDER BY DT_EXECUTION;

PROMPT
PROMPT Si "NON trouve" pour compte 342 → ROOT CAUSE TROUVÉE ❌
PROMPT Le compte 342 n'est pas paramétré dans TA_RN_GESTION_ACCURATE
PROMPT

PROMPT ============================================================================
PROMPT 6. INSERTIONS DANS TA_RN_EXPORT
PROMPT ============================================================================

SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    TYPE_LOG,
    NOM_BALISE,
    VALEUR_EXTRAITE
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND MESSAGE LIKE '%INSERT dans TA_RN_EXPORT%'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT 7. ERREURS ET WARNINGS
PROMPT ============================================================================

SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    TYPE_LOG,
    ETAPE,
    MESSAGE,
    VALEUR_EXTRAITE,
    CODE_ERREUR,
    SUBSTR(STACK_TRACE, 1, 200) AS STACK_TRACE
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND TYPE_LOG IN ('WARNING', 'ERROR')
ORDER BY DT_EXECUTION;

PROMPT
PROMPT Si aucune erreur → Bon signe ✅
PROMPT

PROMPT ============================================================================
PROMPT 8. VÉRIFICATION DES DONNÉES - TA_RN_IMPORT_GESTION
PROMPT ============================================================================

SELECT
    ID_CHARGEMENT_GESTION,
    OPERATIONNETAMOUNT,
    PAYMENTREFERENCE,
    NUMEROCLIENT,
    IDENTIFICATIONRIB,
    SETTLEMENTMODE,
    OPERATIONNETAMOUNTCURRENCY
FROM TA_RN_IMPORT_GESTION
WHERE OPERATIONNETAMOUNT IN ('22.36', '2817')
ORDER BY OPERATIONNETAMOUNT;

PROMPT
PROMPT ============================================================================
PROMPT 9. VÉRIFICATION DES DONNÉES - TA_RN_EXPORT
PROMPT ============================================================================

SELECT
    ID_CHARGEMENT,
    SOURCE,
    ACCNUM,
    ORAMT,
    TRDAT,
    ORAMTCCY
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ORAMT IN ('22.36', '2817')
ORDER BY ORAMT;

PROMPT
PROMPT Si seulement 22.36 → Problème avec le traitement de 2817 ❌
PROMPT

PROMPT ============================================================================
PROMPT 10. DIAGNOSTIC FINAL
PROMPT ============================================================================

SELECT
    '22.36 dans XML ?' AS VERIFICATION,
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END AS RESULTAT
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND MESSAGE LIKE '%22.36%TROUVEE dans le XML%'

UNION ALL

SELECT
    '2817 dans XML ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND MESSAGE LIKE '%2817%TROUVEE dans le XML%'

UNION ALL

SELECT
    '22.36 inseree dans TA_RN_IMPORT_GESTION ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END
FROM TA_RN_IMPORT_GESTION
WHERE OPERATIONNETAMOUNT = '22.36'

UNION ALL

SELECT
    '2817 inseree dans TA_RN_IMPORT_GESTION ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END
FROM TA_RN_IMPORT_GESTION
WHERE OPERATIONNETAMOUNT = '2817'

UNION ALL

SELECT
    '22.36 dans TA_RN_EXPORT ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST' AND ORAMT = '22.36'

UNION ALL

SELECT
    '2817 dans TA_RN_EXPORT ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST' AND ORAMT = '2817'

UNION ALL

SELECT
    'Compte 394 dans TA_RN_GESTION_ACCURATE ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND VALEUR_EXTRAITE LIKE '394 %transactions%'

UNION ALL

SELECT
    'Compte 342 dans TA_RN_GESTION_ACCURATE ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND VALEUR_EXTRAITE LIKE '342 %transactions%';

PROMPT
PROMPT ============================================================================
PROMPT FIN VÉRIFICATION
PROMPT ============================================================================
PROMPT
PROMPT INTERPRÉTATION :
PROMPT - Si 22.36 et 2817 dans XML mais seulement 22.36 dans TA_RN_EXPORT :
PROMPT   → Problème dans le traitement TA_RN_GESTION_ACCURATE ou filtres exclusion
PROMPT
PROMPT - Si compte 342 NON trouvé dans TA_RN_GESTION_ACCURATE :
PROMPT   → ROOT CAUSE : Paramétrage manquant
PROMPT   → Action : Exécuter @VERIF_GESTION_ACCURATE_394_342.sql
PROMPT
PROMPT - Si les deux comptes trouvés mais 2817 pas dans TA_RN_EXPORT :
PROMPT   → Filtre d'exclusion actif (SOCIETE, DEVISE, MODE_REGLEMENT, etc.)
PROMPT   → Action : Analyser les logs étape 32
PROMPT
PROMPT ============================================================================
