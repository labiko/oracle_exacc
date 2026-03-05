-- ============================================================================
-- CHERCHER LE LIEN ENTRE TA_RN_IMPORT_GESTION_JC ET BR_DATA
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Trouver quel code insère dans BR_DATA depuis TA_RN_IMPORT_GESTION_JC
-- ============================================================================

-- ============================================================================
-- 1. Chercher les packages qui référencent LES DEUX tables
-- ============================================================================

-- Packages qui mentionnent TA_RN_IMPORT_GESTION_JC
SELECT
    'Packages avec TA_RN_IMPORT_GESTION_JC' AS Info,
    OWNER,
    NAME,
    TYPE,
    COUNT(*) AS NB_REF
FROM DBA_SOURCE
WHERE UPPER(TEXT) LIKE '%TA_RN_IMPORT_GESTION_JC%'
  AND TYPE IN ('PACKAGE BODY', 'PROCEDURE', 'FUNCTION')
GROUP BY OWNER, NAME, TYPE
ORDER BY NB_REF DESC;

-- ============================================================================
-- 2. Chercher les packages qui référencent TA_RN_ ET BR_DATA
-- ============================================================================

SELECT DISTINCT
    A.OWNER,
    A.NAME AS PACKAGE_NAME,
    A.TYPE,
    'REF: TA_RN_ + BR_DATA' AS Info
FROM DBA_SOURCE A
WHERE A.TYPE IN ('PACKAGE BODY', 'PROCEDURE')
  AND EXISTS (
    SELECT 1 FROM DBA_SOURCE B
    WHERE B.OWNER = A.OWNER
      AND B.NAME = A.NAME
      AND B.TYPE = A.TYPE
      AND UPPER(B.TEXT) LIKE '%TA_RN_%'
  )
  AND EXISTS (
    SELECT 1 FROM DBA_SOURCE C
    WHERE C.OWNER = A.OWNER
      AND C.NAME = A.NAME
      AND C.TYPE = A.TYPE
      AND UPPER(C.TEXT) LIKE '%BR_DATA%'
  )
ORDER BY A.OWNER, A.NAME;

-- ============================================================================
-- 3. Chercher dans le schéma EXP_RNAPA (propriétaire des tables TA_RN_)
-- ============================================================================

SELECT
    OWNER,
    NAME,
    TYPE,
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'EXP_RNAPA'
  AND TYPE IN ('PACKAGE BODY', 'PROCEDURE')
  AND UPPER(TEXT) LIKE '%BR_DATA%'
ORDER BY NAME, LINE;

-- ============================================================================
-- 4. Chercher les DB LINKS entre schémas
-- ============================================================================

SELECT
    OWNER,
    DB_LINK,
    USERNAME,
    HOST
FROM DBA_DB_LINKS
WHERE OWNER IN ('EXP_RNAPA', 'BANKREC', USER)
ORDER BY OWNER;

-- ============================================================================
-- 5. Chercher les synonymes qui pointent vers BR_DATA
-- ============================================================================

SELECT
    OWNER,
    SYNONYM_NAME,
    TABLE_OWNER,
    TABLE_NAME
FROM DBA_SYNONYMS
WHERE TABLE_NAME = 'BR_DATA'
   OR SYNONYM_NAME = 'BR_DATA'
ORDER BY OWNER;

-- ============================================================================
-- 6. Chercher les vues qui joignent TA_RN_ et BR_DATA
-- ============================================================================

SELECT
    OWNER,
    VIEW_NAME,
    TEXT
FROM DBA_VIEWS
WHERE (UPPER(TEXT) LIKE '%TA_RN_%' AND UPPER(TEXT) LIKE '%BR_DATA%')
   OR VIEW_NAME LIKE '%BR_DATA%'
   OR VIEW_NAME LIKE '%TA_RN_%'
ORDER BY OWNER, VIEW_NAME;

-- ============================================================================
-- 7. Lister TOUS les objets du schéma EXP_RNAPA de type procédure/package
-- ============================================================================

SELECT
    OBJECT_TYPE,
    OBJECT_NAME,
    STATUS,
    LAST_DDL_TIME
FROM DBA_OBJECTS
WHERE OWNER = 'EXP_RNAPA'
  AND OBJECT_TYPE IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION')
  AND OBJECT_NAME LIKE '%GESTION%'
ORDER BY LAST_DDL_TIME DESC;

-- ============================================================================
-- RÉSUMÉ
-- ============================================================================
/*
HYPOTHÈSE RÉVISÉE :
-------------------
Puisque :
- TA_RN_IMPORT_GESTION_JC contient les 2 transactions
- TA_RN_EXPORT_JC est vide (TYPE_RAPPRO='B' bloque)
- BR_DATA contient uniquement 22.36

Alors il existe FORCÉMENT un autre processus qui :
1. Lit directement depuis TA_RN_IMPORT_GESTION_JC
2. Insère dans BR_DATA (schéma BANKREC)
3. Applique un filtre différent qui laisse passer 22.36 mais bloque 2817

Ce processus peut être :
- Un package dans EXP_RNAPA qui a un synonyme/DB link vers BANKREC.BR_DATA
- Un package dans BANKREC qui lit EXP_RNAPA.TA_RN_IMPORT_GESTION_JC via DB link
- Un job scheduler qui appelle une procédure
- Une application Java/externe qui lit l'une et écrit dans l'autre
*/
