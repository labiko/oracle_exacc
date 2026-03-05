-- ============================================================================
-- PURGE AVANT TEST - Nettoyage complet avant relance
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Purger toutes les données avant de relancer le test
-- ============================================================================

SET SERVEROUTPUT ON

PROMPT ============================================================================
PROMPT PURGE DES DONNÉES AVANT TEST
PROMPT ============================================================================

-- Vérification des tables avant purge
PROMPT
PROMPT État AVANT purge:
PROMPT ----------------

SELECT 'TA_RN_IMPORT_GESTION_JC' AS TABLE_NAME, COUNT(*) AS NB_LIGNES
FROM TA_RN_IMPORT_GESTION_JC
UNION ALL
SELECT 'TA_RN_EXPORT_JC' AS TABLE_NAME, COUNT(*) AS NB_LIGNES
FROM TA_RN_EXPORT_JC
UNION ALL
SELECT 'TA_RN_LOG_EXECUTION' AS TABLE_NAME, COUNT(*) AS NB_LIGNES
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE IN ('PR_RN_IMPORT_GESTION_JC', 'PR_RN_IMPORT_GESTION_JC_TRACE')
UNION ALL
SELECT 'TW_EXPORT_GEST_JC' AS TABLE_NAME, COUNT(*) AS NB_LIGNES
FROM TW_EXPORT_GEST_JC;

PROMPT
PROMPT Purge en cours...
PROMPT

-- Purge de TA_RN_IMPORT_GESTION_JC
DECLARE
    v_count NUMBER;
BEGIN
    DELETE FROM TA_RN_IMPORT_GESTION_JC;
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ TA_RN_IMPORT_GESTION_JC: ' || v_count || ' lignes supprimées');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ Erreur purge TA_RN_IMPORT_GESTION_JC: ' || SQLERRM);
END;
/

-- Purge de TA_RN_EXPORT_JC (seulement les lignes du test)
DECLARE
    v_count NUMBER;
BEGIN
    DELETE FROM TA_RN_EXPORT_JC WHERE SOURCE = 'GEST';
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ TA_RN_EXPORT_JC: ' || v_count || ' lignes supprimées');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ Erreur purge TA_RN_EXPORT_JC: ' || SQLERRM);
END;
/

-- Purge des logs de la procédure
DECLARE
    v_count NUMBER;
BEGIN
    DELETE FROM TA_RN_LOG_EXECUTION
    WHERE NOM_PROCEDURE IN ('PR_RN_IMPORT_GESTION_JC', 'PR_RN_IMPORT_GESTION_JC_TRACE');
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ TA_RN_LOG_EXECUTION: ' || v_count || ' lignes supprimées');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ Erreur purge TA_RN_LOG_EXECUTION: ' || SQLERRM);
END;
/

-- Purge de TW_EXPORT_GEST_JC
DECLARE
    v_count NUMBER;
BEGIN
    DELETE FROM TW_EXPORT_GEST_JC;
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ TW_EXPORT_GEST_JC: ' || v_count || ' lignes supprimées');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('❌ Erreur purge TW_EXPORT_GEST_JC: ' || SQLERRM);
END;
/

-- Vérification après purge
PROMPT
PROMPT État APRÈS purge:
PROMPT -----------------

SELECT 'TA_RN_IMPORT_GESTION_JC' AS TABLE_NAME, COUNT(*) AS NB_LIGNES
FROM TA_RN_IMPORT_GESTION_JC
UNION ALL
SELECT 'TA_RN_EXPORT_JC' AS TABLE_NAME, COUNT(*) AS NB_LIGNES
FROM TA_RN_EXPORT_JC
UNION ALL
SELECT 'TA_RN_LOG_EXECUTION' AS TABLE_NAME, COUNT(*) AS NB_LIGNES
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE IN ('PR_RN_IMPORT_GESTION_JC', 'PR_RN_IMPORT_GESTION_JC_TRACE')
UNION ALL
SELECT 'TW_EXPORT_GEST_JC' AS TABLE_NAME, COUNT(*) AS NB_LIGNES
FROM TW_EXPORT_GEST_JC;

PROMPT
PROMPT ============================================================================
PROMPT PURGE TERMINÉE - Vous pouvez relancer l'import
PROMPT ============================================================================
