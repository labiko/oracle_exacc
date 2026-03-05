-- ============================================================================
-- VÉRIFICATION PARAMÉTRAGE GESTION_JC - Comptes 394 vs 342
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Vérifier si le compte 394 (22.36) est paramétré mais pas le 342 (2817)
-- ============================================================================

PROMPT ============================================================================
PROMPT ÉTAPE 1 : Vérification du paramétrage des comptes 394 et 342
PROMPT ============================================================================

SELECT
    RGJ.ID_COMPTE_ACCURATE,
    RCA.NUM_COMPTE_ACCURATE,
    RCA.NOM AS NOM_COMPTE_ACCURATE,
    RCA.TYPE_RAPPRO,
    RCA.FLAG_ACTIF,
    RP.ID_PRODUIT,
    RP.CODE_PRODUIT,
    RP.LIBELLE AS LIBELLE_PRODUIT,
    RMR.ID_MODE_REGLEMENT,
    RMR.CODE_MODE_REGLEMENT,
    RMR.LIBELLE AS LIBELLE_MODE_REGLEMENT
FROM TA_RN_GESTION_JC RGJ
    JOIN TA_RN_COMPTE_ACCURATE RCA ON RCA.ID_COMPTE_ACCURATE = RGJ.ID_COMPTE_ACCURATE
    JOIN TA_RN_PRODUIT RP ON RP.ID_PRODUIT = RGJ.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT RMR ON RMR.ID_MODE_REGLEMENT = RGJ.ID_MODE_REGLEMENT
WHERE RGJ.ID_COMPTE_ACCURATE IN (394, 342)
ORDER BY RGJ.ID_COMPTE_ACCURATE;

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 2 : Vérification de TOUS les comptes accurate avec TYPE_RAPPRO='B'
PROMPT ============================================================================
PROMPT (pour voir si d'autres comptes TYPE_RAPPRO=B sont paramétrés)

SELECT
    RGJ.ID_COMPTE_ACCURATE,
    RCA.NUM_COMPTE_ACCURATE,
    RCA.NOM,
    RCA.TYPE_RAPPRO,
    RCA.FLAG_ACTIF,
    RP.CODE_PRODUIT,
    RMR.CODE_MODE_REGLEMENT
FROM TA_RN_GESTION_JC RGJ
    JOIN TA_RN_COMPTE_ACCURATE RCA ON RCA.ID_COMPTE_ACCURATE = RGJ.ID_COMPTE_ACCURATE
    JOIN TA_RN_PRODUIT RP ON RP.ID_PRODUIT = RGJ.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT RMR ON RMR.ID_MODE_REGLEMENT = RGJ.ID_MODE_REGLEMENT
WHERE RCA.TYPE_RAPPRO = 'B'
ORDER BY RCA.NUM_COMPTE_ACCURATE;

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 3 : Liste complète des comptes accurate (394 et 342)
PROMPT ============================================================================

SELECT
    ID_COMPTE_ACCURATE,
    NUM_COMPTE_ACCURATE,
    NOM,
    FLAG_ACTIF,
    TYPE_RAPPRO,
    CASE
        WHEN TYPE_RAPPRO = 'J' THEN 'Traité par RNADGENJUCGES01.sql'
        WHEN TYPE_RAPPRO = 'B' THEN 'NON traité par RNADGENJUCGES01.sql (TYPE_RAPPRO=B)'
        ELSE 'Type inconnu'
    END AS TRAITEMENT
FROM TA_RN_COMPTE_ACCURATE
WHERE ID_COMPTE_ACCURATE IN (394, 342)
ORDER BY ID_COMPTE_ACCURATE;

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 4 : Vérifier si TYPE_RAPPRO='B' a un traitement spécifique
PROMPT ============================================================================
PROMPT Chercher les packages qui filtrent par TYPE_RAPPRO='B'

SELECT DISTINCT
    OWNER,
    NAME AS PACKAGE_NAME,
    TYPE,
    'Référence TYPE_RAPPRO=B' AS Info
FROM DBA_SOURCE
WHERE UPPER(TEXT) LIKE '%TYPE_RAPPRO%'
  AND UPPER(TEXT) LIKE '%''B''%'
  AND TYPE IN ('PACKAGE BODY', 'PROCEDURE')
ORDER BY OWNER, NAME;

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 5 : Chercher les packages qui traitent TYPE_RAPPRO (tous types)
PROMPT ============================================================================

SELECT
    OWNER,
    NAME,
    TYPE,
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE UPPER(TEXT) LIKE '%TYPE_RAPPRO%'
  AND TYPE IN ('PACKAGE BODY', 'PROCEDURE')
  AND OWNER IN ('BANKREC', 'EXP_RNAPA')
ORDER BY OWNER, NAME, LINE;

PROMPT
PROMPT ============================================================================
PROMPT RÉSUMÉ DIAGNOSTIC
PROMPT ============================================================================
PROMPT SI RÉSULTAT ÉTAPE 1 :
PROMPT   - 394 présent, 342 absent → Le filtrage se fait par GESTION_JC
PROMPT   - Les deux absents → Autre logique (package spécifique TYPE_RAPPRO=B)
PROMPT   - Les deux présents → Problème ailleurs (autre critère de filtrage)
PROMPT
PROMPT SI RÉSULTAT ÉTAPE 4-5 :
PROMPT   - Packages trouvés → Analyser le code de ces packages
PROMPT   - Aucun package → Vérifier processus externe ou jobs scheduler
PROMPT ============================================================================
