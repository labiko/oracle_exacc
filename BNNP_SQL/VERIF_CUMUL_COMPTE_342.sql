-- ============================================================================
-- VÉRIFICATION CUMUL - Compte 342 (Transaction 2817 EUR)
-- ============================================================================

SET LINESIZE 300
SET PAGESIZE 200

PROMPT ============================================================================
PROMPT PARAMÉTRAGE CUMUL - Compte 342 (BBNP83292-EUR) - Transaction 2817 EUR
PROMPT ============================================================================

PROMPT
PROMPT 1. Informations du compte 342
PROMPT

SELECT
    CA.ID_COMPTE_ACCURATE,
    CA.NUM_COMPTE_ACCURATE,
    CBS.ID_COMPTE_BANCAIRE_SYSTEME AS ID_CBS,
    CBS.NUMERO AS NUM_CBS,
    CBS.RIBBANKCODE||CBS.RIBBRANCHCODE||CBS.RIBIDENTIFICATION||CBS.RIBCHECKDIGIT AS RIB_COMPLET,
    CA.TYPE_RAPPRO,
    CA.FLAG_ACTIF
FROM TA_RN_COMPTE_ACCURATE CA
    JOIN TA_RN_GESTION_ACCURATE GA ON GA.ID_COMPTE_ACCURATE = CA.ID_COMPTE_ACCURATE
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS ON CBS.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
WHERE CA.ID_COMPTE_ACCURATE = 342;

PROMPT

PROMPT ============================================================================
PROMPT 2. RÈGLES DE CUMUL pour le compte 342
PROMPT ============================================================================

SELECT
    CMR.ID_COMPTE_BANCAIRE_SYSTEME AS ID_CBS,
    CBS.NUMERO AS NUM_CBS,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    MR.LIBELLE AS LIBELLE_MODE,
    TO_CHAR(CMR.DT_INSERT, 'YYYY-MM-DD HH24:MI:SS') AS DATE_CREATION,
    '[KO] MODE CUMUL ACTIF' AS STATUT
FROM TA_RN_GESTION_ACCURATE GA
    JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS ON CBS.ID_COMPTE_BANCAIRE_SYSTEME = CMR.ID_COMPTE_BANCAIRE_SYSTEME
WHERE GA.ID_COMPTE_ACCURATE = 342
ORDER BY P.CODE_PRODUIT, MR.CODE_MODE_REGLEMENT;

PROMPT
PROMPT Si AUCUNE LIGNE -> Pas de regle de cumul [OK] (export en DETAIL)
PROMPT Si LIGNES AFFICHEES -> Regle(s) de cumul active(s) [KO] (export en CUMUL)
PROMPT
PROMPT Si CODE_PRODUIT = 'ALL' et CODE_MODE_REGLEMENT = 'VO'
PROMPT   → TOUTES les transactions VO seront CUMULÉES
PROMPT   → La transaction 2817 EUR (mode VO) sera dans un CUMUL QUOTIDIEN
PROMPT   → Elle N'APPARAÎTRA PAS individuellement dans BR_DATA
PROMPT

PROMPT ============================================================================
PROMPT 3. NOMBRE TOTAL de règles de cumul pour le compte 342
PROMPT ============================================================================

SELECT
    COUNT(*) AS NB_REGLES_CUMUL,
    CASE
        WHEN COUNT(*) = 0 THEN '[OK] AUCUNE REGLE - Export en DETAIL'
        WHEN COUNT(*) > 0 THEN '[KO] ' || COUNT(*) || ' REGLE(S) ACTIVE(S) - Export en CUMUL'
    END AS RESULTAT
FROM TA_RN_GESTION_ACCURATE GA
    JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
WHERE GA.ID_COMPTE_ACCURATE = 342;

PROMPT

PROMPT ============================================================================
PROMPT 4. VÉRIFICATION SPÉCIFIQUE - Règle ALL+VO (qui impacte 2817 EUR)
PROMPT ============================================================================

SELECT
    CASE
        WHEN COUNT(*) > 0 THEN '[KO] OUI - La regle ALL+VO EXISTE'
        ELSE '[OK] NON - Pas de regle ALL+VO'
    END AS REGLE_ALL_VO_EXISTE,
    CASE
        WHEN COUNT(*) > 0 THEN '[KO] Transaction 2817 sera CUMULEE (mode VO)'
        ELSE '[OK] Transaction 2817 sera exportee EN DETAIL'
    END AS IMPACT_SUR_2817
FROM TA_RN_GESTION_ACCURATE GA
    JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE GA.ID_COMPTE_ACCURATE = 342
  AND P.CODE_PRODUIT = 'ALL'
  AND MR.CODE_MODE_REGLEMENT = 'VO';

PROMPT

PROMPT ============================================================================
PROMPT FIN VÉRIFICATION - Compte 342
PROMPT ============================================================================
