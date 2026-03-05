-- ============================================================================
-- VÉRIFICATION RAPIDE - Règle de cumul pour compte 342
-- ============================================================================

SET LINESIZE 200
SET PAGESIZE 100

PROMPT ============================================================================
PROMPT VÉRIFICATION RAPIDE - Pourquoi 2817 n'est pas dans BR_DATA ?
PROMPT ============================================================================

PROMPT
PROMPT 1. Y a-t-il une règle de cumul pour le compte 342 ?
PROMPT

SELECT
    'Compte 342 (BBNP83292-EUR)' AS COMPTE,
    CBS.ID_COMPTE_BANCAIRE_SYSTEME AS ID_CBS,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    CASE
        WHEN CMR.ID_MODE_REGLEMENT IS NOT NULL THEN '[KO] OUI - MODE CUMUL ACTIF'
        ELSE '[OK] NON - Export en DETAIL'
    END AS STATUT
FROM TA_RN_GESTION_ACCURATE GA
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
        ON CBS.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
    LEFT JOIN TA_RN_CUMUL_MR CMR
        ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = CBS.ID_COMPTE_BANCAIRE_SYSTEME
    LEFT JOIN TA_RN_PRODUIT P
        ON P.ID_PRODUIT = CMR.ID_PRODUIT
    LEFT JOIN TA_RN_MODE_REGLEMENT MR
        ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE GA.ID_COMPTE_ACCURATE = 342;

PROMPT
PROMPT Si MODE CUMUL ACTIF → C'est la ROOT CAUSE !
PROMPT   → La transaction 2817 est CUMULÉE avec d'autres transactions VO
PROMPT   → Elle n'apparaît PAS individuellement dans BR_DATA
PROMPT

PROMPT ============================================================================
PROMPT 2. Comparaison avec le compte 394 (qui fonctionne)
PROMPT ============================================================================

SELECT
    'Compte 394 (BNPP05492-EUR)' AS COMPTE,
    CBS.ID_COMPTE_BANCAIRE_SYSTEME AS ID_CBS,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    CASE
        WHEN CMR.ID_MODE_REGLEMENT IS NOT NULL THEN '[KO] MODE CUMUL ACTIF'
        ELSE '[OK] PAS DE CUMUL - Export en DETAIL'
    END AS STATUT
FROM TA_RN_GESTION_ACCURATE GA
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
        ON CBS.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
    LEFT JOIN TA_RN_CUMUL_MR CMR
        ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = CBS.ID_COMPTE_BANCAIRE_SYSTEME
    LEFT JOIN TA_RN_PRODUIT P
        ON P.ID_PRODUIT = CMR.ID_PRODUIT
    LEFT JOIN TA_RN_MODE_REGLEMENT MR
        ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE GA.ID_COMPTE_ACCURATE = 394;

PROMPT
PROMPT ============================================================================
PROMPT CONCLUSION
PROMPT ============================================================================
PROMPT
PROMPT Si compte 342 a MODE CUMUL ACTIF et compte 394 n'en a pas
PROMPT   → C'EST LA DIFFÉRENCE qui explique pourquoi:
PROMPT      - 22.36 EUR apparait EN DETAIL dans BR_DATA [OK]
PROMPT      - 2817 EUR n'apparait PAS en detail (seulement dans le CUMUL) [KO]
PROMPT
PROMPT SOLUTION: Supprimer la règle de cumul pour le compte 342
PROMPT   → Voir SOLUTION_OPTIONS.md
PROMPT
PROMPT ============================================================================
