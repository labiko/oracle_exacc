-- ============================================================================
-- ANALYSE CODE PKG_BR_PURGE - Recherche de la logique d'insertion
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Analyser le package PKG_BR_PURGE (227 références à BR_DATA)
-- ============================================================================

PROMPT ============================================================================
PROMPT 1. RECHERCHE INSERT...SELECT dans PKG_BR_PURGE
PROMPT ============================================================================

SELECT
    OWNER,
    NAME,
    TYPE,
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'PKG_BR_PURGE'
  AND TYPE = 'PACKAGE BODY'
  AND (
      UPPER(TEXT) LIKE '%INSERT%'
      OR UPPER(TEXT) LIKE '%SELECT%'
  )
ORDER BY LINE;

PROMPT
PROMPT ============================================================================
PROMPT 2. RECHERCHE références à TA_RN_IMPORT_GESTION_JC dans PKG_BR_PURGE
PROMPT ============================================================================

SELECT
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'PKG_BR_PURGE'
  AND TYPE = 'PACKAGE BODY'
  AND UPPER(TEXT) LIKE '%TA_RN_%'
ORDER BY LINE;

PROMPT
PROMPT ============================================================================
PROMPT 3. RECHERCHE références à COMPTE_ACCURATE dans PKG_BR_PURGE
PROMPT ============================================================================

SELECT
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'PKG_BR_PURGE'
  AND TYPE = 'PACKAGE BODY'
  AND UPPER(TEXT) LIKE '%COMPTE_ACCURATE%'
ORDER BY LINE;

PROMPT
PROMPT ============================================================================
PROMPT 4. RECHERCHE références à TYPE_RAPPRO dans PKG_BR_PURGE
PROMPT ============================================================================

SELECT
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'PKG_BR_PURGE'
  AND TYPE = 'PACKAGE BODY'
  AND UPPER(TEXT) LIKE '%TYPE_RAPPRO%'
ORDER BY LINE;

PROMPT
PROMPT ============================================================================
PROMPT 5. RECHERCHE INSERT dans BR_DATA (pas BR_DATA_TEMP) - PKG_BR_PURGE
PROMPT ============================================================================

SELECT
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'PKG_BR_PURGE'
  AND TYPE = 'PACKAGE BODY'
  AND UPPER(TEXT) LIKE '%INSERT%BR_DATA%'
  AND UPPER(TEXT) NOT LIKE '%BR_DATA_TEMP%'
ORDER BY LINE;

PROMPT
PROMPT ============================================================================
PROMPT 6. MÊME ANALYSE POUR BRT_FILTERED_ITEM (49 références)
PROMPT ============================================================================

SELECT
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'BRT_FILTERED_ITEM'
  AND TYPE = 'PACKAGE BODY'
  AND (
      UPPER(TEXT) LIKE '%INSERT%BR_DATA%'
      OR UPPER(TEXT) LIKE '%TA_RN_%'
      OR UPPER(TEXT) LIKE '%COMPTE_ACCURATE%'
  )
ORDER BY LINE;

PROMPT
PROMPT ============================================================================
PROMPT 7. MÊME ANALYSE POUR PKG_NXGCRT_SUBMISSION (42 références)
PROMPT ============================================================================

SELECT
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'PKG_NXGCRT_SUBMISSION'
  AND TYPE = 'PACKAGE BODY'
  AND (
      UPPER(TEXT) LIKE '%INSERT%BR_DATA%'
      OR UPPER(TEXT) LIKE '%TA_RN_%'
      OR UPPER(TEXT) LIKE '%COMPTE_ACCURATE%'
  )
ORDER BY LINE;

PROMPT
PROMPT ============================================================================
PROMPT 8. CHERCHER TOUS LES PACKAGES QUI LISENT TA_RN_IMPORT ET ÉCRIVENT BR_DATA
PROMPT ============================================================================

-- Trouver les packages qui contiennent les DEUX tables
SELECT DISTINCT
    A.OWNER,
    A.NAME AS PACKAGE_NAME,
    A.TYPE,
    COUNT(DISTINCT B.LINE) AS NB_REF_TA_RN,
    COUNT(DISTINCT C.LINE) AS NB_REF_BR_DATA
FROM DBA_SOURCE A
    LEFT JOIN DBA_SOURCE B ON B.OWNER = A.OWNER
                           AND B.NAME = A.NAME
                           AND B.TYPE = A.TYPE
                           AND UPPER(B.TEXT) LIKE '%TA_RN_IMPORT_GESTION_JC%'
    LEFT JOIN DBA_SOURCE C ON C.OWNER = A.OWNER
                           AND C.NAME = A.NAME
                           AND C.TYPE = A.TYPE
                           AND UPPER(C.TEXT) LIKE '%BR_DATA%'
WHERE A.TYPE IN ('PACKAGE BODY', 'PROCEDURE')
  AND A.OWNER IN ('BANKREC', 'EXP_RNAPA')
  AND (B.LINE IS NOT NULL OR C.LINE IS NOT NULL)
GROUP BY A.OWNER, A.NAME, A.TYPE
HAVING COUNT(DISTINCT B.LINE) > 0 AND COUNT(DISTINCT C.LINE) > 0
ORDER BY NB_REF_BR_DATA DESC;

PROMPT
PROMPT ============================================================================
PROMPT 9. CHERCHER PROCÉDURES DANS EXP_RNAPA QUI ÉCRIVENT DANS BR_DATA
PROMPT ============================================================================

SELECT
    NAME,
    TYPE,
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'EXP_RNAPA'
  AND TYPE IN ('PACKAGE BODY', 'PROCEDURE')
  AND UPPER(TEXT) LIKE '%BR_DATA%'
ORDER BY NAME, LINE;

PROMPT
PROMPT ============================================================================
PROMPT 10. VÉRIFIER S'IL EXISTE UN SYNONYME BR_DATA DANS EXP_RNAPA
PROMPT ============================================================================

SELECT
    OWNER,
    SYNONYM_NAME,
    TABLE_OWNER,
    TABLE_NAME,
    DB_LINK
FROM DBA_SYNONYMS
WHERE (SYNONYM_NAME = 'BR_DATA' OR TABLE_NAME = 'BR_DATA')
  AND OWNER IN ('EXP_RNAPA', 'PUBLIC', 'BANKREC')
ORDER BY OWNER, SYNONYM_NAME;

PROMPT
PROMPT ============================================================================
PROMPT RÉSUMÉ
PROMPT ============================================================================
PROMPT Ce script recherche :
PROMPT 1. Le code source des 3 packages principaux (PKG_BR_PURGE, BRT_FILTERED_ITEM, PKG_NXGCRT_SUBMISSION)
PROMPT 2. Les packages qui lisent TA_RN_IMPORT_GESTION_JC ET écrivent dans BR_DATA
PROMPT 3. Les procédures dans EXP_RNAPA qui écrivent dans BR_DATA
PROMPT 4. Les synonymes qui permettent l'accès à BR_DATA depuis d'autres schémas
PROMPT
PROMPT OBJECTIF : Identifier le code exact qui insère 22.36 mais pas 2817
PROMPT ============================================================================
