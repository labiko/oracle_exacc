-- ============================================================================
-- COMPARAISON CUMUL - Compte 342 vs Compte 394
-- ============================================================================
-- Objectif: Voir CÔTE À CÔTE la différence de paramétrage cumul
-- ============================================================================

SET LINESIZE 300
SET PAGESIZE 200

PROMPT ============================================================================
PROMPT COMPARAISON PARAMÉTRAGE CUMUL - 342 (2817 EUR) vs 394 (22.36 EUR)
PROMPT ============================================================================

PROMPT
PROMPT 1. Informations des comptes
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
WHERE CA.ID_COMPTE_ACCURATE IN (342, 394)
ORDER BY CA.ID_COMPTE_ACCURATE;

PROMPT

PROMPT ============================================================================
PROMPT 2. RÈGLES DE CUMUL - Comparaison
PROMPT ============================================================================

SELECT
    CASE
        WHEN GA.ID_COMPTE_ACCURATE = 342 THEN '342 (2817 EUR)'
        WHEN GA.ID_COMPTE_ACCURATE = 394 THEN '394 (22.36 EUR)'
    END AS COMPTE,
    CMR.ID_COMPTE_BANCAIRE_SYSTEME AS ID_CBS,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    MR.LIBELLE AS LIBELLE_MODE,
    '[KO] MODE CUMUL ACTIF' AS STATUT
FROM TA_RN_GESTION_ACCURATE GA
    JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE GA.ID_COMPTE_ACCURATE IN (342, 394)
ORDER BY GA.ID_COMPTE_ACCURATE, P.CODE_PRODUIT, MR.CODE_MODE_REGLEMENT;

PROMPT
PROMPT Si AUCUNE LIGNE affichee -> Les deux comptes N'ONT PAS de regle de cumul [OK]
PROMPT Si seulement 342 affiche -> SEUL le compte 342 a une regle de cumul [KO]
PROMPT Si les deux affichés → Les deux comptes ont des règles de cumul
PROMPT

PROMPT ============================================================================
PROMPT 3. NOMBRE DE RÈGLES - Comparaison
PROMPT ============================================================================

SELECT
    '342 (2817 EUR)' AS COMPTE,
    COUNT(*) AS NB_REGLES_CUMUL,
    CASE
        WHEN COUNT(*) = 0 THEN '[OK] AUCUNE - Export DETAIL'
        ELSE '[KO] ' || COUNT(*) || ' REGLE(S) - Export CUMUL'
    END AS STATUT
FROM TA_RN_GESTION_ACCURATE GA
    LEFT JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
WHERE GA.ID_COMPTE_ACCURATE = 342

UNION ALL

SELECT
    '394 (22.36 EUR)' AS COMPTE,
    COUNT(*) AS NB_REGLES_CUMUL,
    CASE
        WHEN COUNT(*) = 0 THEN '[OK] AUCUNE - Export DETAIL'
        ELSE '[KO] ' || COUNT(*) || ' REGLE(S) - Export CUMUL'
    END AS STATUT
FROM TA_RN_GESTION_ACCURATE GA
    LEFT JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
WHERE GA.ID_COMPTE_ACCURATE = 394

ORDER BY 1;

PROMPT

PROMPT ============================================================================
PROMPT 4. RÈGLE ALL+VO SPÉCIFIQUE (qui impacte les transactions VO)
PROMPT ============================================================================

SELECT
    '342 (2817 EUR)' AS COMPTE,
    CASE
        WHEN COUNT(*) > 0 THEN '[KO] OUI'
        ELSE '[OK] NON'
    END AS REGLE_ALL_VO,
    CASE
        WHEN COUNT(*) > 0 THEN '[KO] Transaction 2817 CUMULEE'
        ELSE '[OK] Transaction 2817 en DETAIL'
    END AS IMPACT
FROM TA_RN_GESTION_ACCURATE GA
    LEFT JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
    LEFT JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    LEFT JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE GA.ID_COMPTE_ACCURATE = 342
  AND (P.CODE_PRODUIT = 'ALL' OR P.CODE_PRODUIT IS NULL)
  AND (MR.CODE_MODE_REGLEMENT = 'VO' OR MR.CODE_MODE_REGLEMENT IS NULL)

UNION ALL

SELECT
    '394 (22.36 EUR)' AS COMPTE,
    CASE
        WHEN COUNT(*) > 0 THEN '[KO] OUI'
        ELSE '[OK] NON'
    END AS REGLE_ALL_VO,
    CASE
        WHEN COUNT(*) > 0 THEN '[KO] Transaction 22.36 CUMULEE'
        ELSE '[OK] Transaction 22.36 en DETAIL'
    END AS IMPACT
FROM TA_RN_GESTION_ACCURATE GA
    LEFT JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
    LEFT JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    LEFT JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE GA.ID_COMPTE_ACCURATE = 394
  AND (P.CODE_PRODUIT = 'ALL' OR P.CODE_PRODUIT IS NULL)
  AND (MR.CODE_MODE_REGLEMENT = 'VO' OR MR.CODE_MODE_REGLEMENT IS NULL)

ORDER BY 1;

PROMPT

PROMPT ============================================================================
PROMPT 5. RÉSUMÉ - Pourquoi 2817 n'apparaît pas et 22.36 oui ?
PROMPT ============================================================================

WITH cumul_342 AS (
    SELECT COUNT(*) AS nb_regles
    FROM TA_RN_GESTION_ACCURATE GA
        JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
        JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
        JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
    WHERE GA.ID_COMPTE_ACCURATE = 342
      AND P.CODE_PRODUIT = 'ALL'
      AND MR.CODE_MODE_REGLEMENT = 'VO'
),
cumul_394 AS (
    SELECT COUNT(*) AS nb_regles
    FROM TA_RN_GESTION_ACCURATE GA
        JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
        JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
        JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
    WHERE GA.ID_COMPTE_ACCURATE = 394
      AND P.CODE_PRODUIT = 'ALL'
      AND MR.CODE_MODE_REGLEMENT = 'VO'
)
SELECT
    'Compte 342 (2817 EUR)' AS COMPTE,
    C342.nb_regles AS NB_REGLES_ALL_VO,
    CASE
        WHEN C342.nb_regles > 0 THEN '❌ CUMULÉE avec autres VO'
        ELSE '✅ Exportée EN DÉTAIL'
    END AS EXPORT_TYPE,
    CASE
        WHEN C342.nb_regles > 0 THEN '❌ PAS VISIBLE individuellement dans BR_DATA'
        ELSE '✅ Visible individuellement dans BR_DATA'
    END AS RESULTAT_BR_DATA
FROM cumul_342 C342

UNION ALL

SELECT
    'Compte 394 (22.36 EUR)' AS COMPTE,
    C394.nb_regles AS NB_REGLES_ALL_VO,
    CASE
        WHEN C394.nb_regles > 0 THEN '❌ CUMULÉE avec autres VO'
        ELSE '✅ Exportée EN DÉTAIL'
    END AS EXPORT_TYPE,
    CASE
        WHEN C394.nb_regles > 0 THEN '❌ PAS VISIBLE individuellement dans BR_DATA'
        ELSE '✅ Visible individuellement dans BR_DATA'
    END AS RESULTAT_BR_DATA
FROM cumul_394 C394

ORDER BY 1;

PROMPT
PROMPT ============================================================================
PROMPT CONCLUSION
PROMPT ============================================================================
PROMPT
PROMPT Si compte 342 a 1 règle ALL+VO et compte 394 a 0 règle
PROMPT   → 🎯 ROOT CAUSE CONFIRMÉE !
PROMPT   → Le compte 342 cumule TOUTES les transactions VO
PROMPT   → La transaction 2817 EUR est dans un CUMUL QUOTIDIEN
PROMPT   → Elle N'APPARAÎT PAS individuellement dans BR_DATA
PROMPT
PROMPT   → Le compte 394 N'A PAS de règle de cumul
PROMPT   → La transaction 22.36 EUR est exportée EN DÉTAIL
PROMPT   → Elle APPARAÎT individuellement dans BR_DATA
PROMPT
PROMPT SOLUTION: Supprimer la règle ALL+VO pour le compte 342
PROMPT   → Voir SOLUTION_OPTIONS.md OPTION A
PROMPT
PROMPT ============================================================================
PROMPT FIN COMPARAISON
PROMPT ============================================================================
