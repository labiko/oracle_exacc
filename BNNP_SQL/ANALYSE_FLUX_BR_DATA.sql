-- ============================================================================
-- ANALYSE FLUX BR_DATA - Comment les données arrivent dans BR_DATA
-- ============================================================================
-- Date: 07/02/2026
-- ============================================================================

-- ============================================================================
-- ÉTAPE 1 : Vérifier si BR_DATA_TEMP existe
-- ============================================================================

SELECT
    'BR_DATA_TEMP' AS Table_Name,
    NUM_ROWS,
    LAST_ANALYZED
FROM ALL_TABLES
WHERE OWNER = 'BANKREC'
  AND TABLE_NAME = 'BR_DATA_TEMP';

-- ============================================================================
-- ÉTAPE 2 : Chercher les packages qui transfèrent de TEMP vers BR_DATA
-- ============================================================================

-- Recherche des INSERT...SELECT de BR_DATA_TEMP vers BR_DATA
SELECT
    OWNER,
    NAME AS PACKAGE_NAME,
    TYPE,
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE UPPER(TEXT) LIKE '%INSERT%BR_DATA%'
  AND UPPER(TEXT) LIKE '%BR_DATA_TEMP%'
  AND OWNER = 'BANKREC'
ORDER BY NAME, LINE;

-- ============================================================================
-- ÉTAPE 3 : Analyser les packages avec le plus de références
-- ============================================================================

-- 3.1. PKG_BR_PURGE (227 références - le plus suspect!)
SELECT
    NAME,
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'PKG_BR_PURGE'
  AND TYPE = 'PACKAGE BODY'
  AND (UPPER(TEXT) LIKE '%INSERT%BR_DATA%'
    OR UPPER(TEXT) LIKE '%BR_DATA_TEMP%')
ORDER BY LINE;

-- 3.2. BRT_FILTERED_ITEM (49 références)
SELECT
    NAME,
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'BRT_FILTERED_ITEM'
  AND TYPE = 'PACKAGE BODY'
  AND (UPPER(TEXT) LIKE '%INSERT%BR_DATA%'
    OR UPPER(TEXT) LIKE '%SELECT%BR_DATA%')
ORDER BY LINE;

-- 3.3. PKG_NXGCRT_SUBMISSION (42 références)
SELECT
    NAME,
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'PKG_NXGCRT_SUBMISSION'
  AND TYPE = 'PACKAGE BODY'
  AND (UPPER(TEXT) LIKE '%INSERT%BR_DATA%'
    OR UPPER(TEXT) LIKE '%BR_DATA_TEMP%')
ORDER BY LINE;

-- ============================================================================
-- ÉTAPE 4 : Chercher les JOBs/Schedulers qui appellent ces packages
-- ============================================================================

SELECT
    JOB_NAME,
    JOB_ACTION,
    ENABLED,
    STATE,
    LAST_START_DATE,
    NEXT_RUN_DATE
FROM DBA_SCHEDULER_JOBS
WHERE JOB_ACTION LIKE '%PKG_BR_PURGE%'
   OR JOB_ACTION LIKE '%BRT_FILTERED%'
   OR JOB_ACTION LIKE '%PKG_NXGCRT%'
ORDER BY LAST_START_DATE DESC;

-- ============================================================================
-- ÉTAPE 5 : Comparer BR_DATA_TEMP et BR_DATA pour nos transactions
-- ============================================================================

-- Voir si 22.36 et 2817 sont dans BR_DATA_TEMP
SELECT
    'BR_DATA_TEMP' AS Source,
    COUNT(*) AS NB_LIGNES
FROM BANKREC.BR_DATA_TEMP
WHERE AMOUNT IN (22.36, 2817, -22.36, -2817);

-- Voir si 22.36 et 2817 sont dans BR_DATA
SELECT
    'BR_DATA' AS Source,
    COUNT(*) AS NB_LIGNES
FROM BANKREC.BR_DATA
WHERE AMOUNT IN (22.36, 2817, -22.36, -2817);

-- ============================================================================
-- ÉTAPE 6 : Chercher les procédures qui manipulent AMOUNT = 22.36 ou 2817
-- ============================================================================

-- Voir les détails dans BR_DATA_TEMP
SELECT
    ACCT_ID,
    AMOUNT,
    NARRATIVE,
    TRANS_DATE,
    VALUE_DATE
FROM BANKREC.BR_DATA_TEMP
WHERE AMOUNT IN (22.36, 2817)
ORDER BY AMOUNT DESC;

-- Voir les détails dans BR_DATA
SELECT
    ACCT_ID,
    AMOUNT,
    NARRATIVE,
    TRANS_DATE,
    VALUE_DATE,
    CREATED_DATE
FROM BANKREC.BR_DATA
WHERE AMOUNT IN (22.36, 2817)
ORDER BY AMOUNT DESC;

-- ============================================================================
-- RÉSUMÉ : Hypothèse du flux
-- ============================================================================
/*
HYPOTHÈSE :
-----------
1. Les données XML sont importées dans une table intermédiaire (TA_RN_IMPORT_GESTION_JC)
2. Un script PL/SQL (RNADGENJUCGES01.sql) filtre et insère dans TA_RN_EXPORT_JC
3. Un autre processus transfert de TA_RN_EXPORT_JC vers BR_DATA_TEMP
4. Un package BANKREC (PKG_BR_PURGE? BRT_FILTERED_ITEM?) transfert de BR_DATA_TEMP vers BR_DATA

VÉRIFICATION :
--------------
- Vérifier si TA_RN_EXPORT_JC est vide mais BR_DATA contient 22.36
- Cela suggère un autre chemin d'import

ACTIONS :
---------
1. Exécuter ce script complet
2. Vérifier les résultats de l'étape 2 (transfert TEMP → BR_DATA)
3. Analyser le contenu de PKG_BR_PURGE et BRT_FILTERED_ITEM
*/
