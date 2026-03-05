-- ============================================================================
-- VÉRIFICATION MODE CUMUL - Transaction 2817
-- ============================================================================
-- ROOT CAUSE: Le compte 342 a un mode cumul actif pour ALL+VO
-- ============================================================================

SET LINESIZE 300
SET PAGESIZE 200

PROMPT ============================================================================
PROMPT MODE CUMUL - Compte 342 (Transaction 2817)
PROMPT ============================================================================

PROMPT
PROMPT 1. Paramétrage du mode cumul
PROMPT ============================================================================

SELECT
    CMR.ID_COMPTE_BANCAIRE_SYSTEME,
    CBS.NUMERO AS NUM_CBS,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    MR.LIBELLE
FROM TA_RN_CUMUL_MR CMR
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS ON CBS.ID_COMPTE_BANCAIRE_SYSTEME = CMR.ID_COMPTE_BANCAIRE_SYSTEME
WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = 352;

PROMPT
PROMPT Si CODE_PRODUIT='ALL' et CODE_MODE='VO' → 2817 sera CUMULÉE ❌
PROMPT

PROMPT ============================================================================
PROMPT 2. Recherche du cumul dans TA_RN_EXPORT
PROMPT ============================================================================
PROMPT La transaction 2817 doit être dans un CUMUL QUOTIDIEN

SELECT
    SOURCE,
    ACCNUM,
    ORAMT AS MONTANT_CUMUL,
    TRDAT AS DATE_TRADE,
    ORAMTCCY AS DEVISE,
    COMMENTAIRE,
    ID_CHARGEMENT
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ACCNUM = 'BBNP83292-EUR'
  AND COMMENTAIRE LIKE '%cumul%'
ORDER BY TRDAT DESC;

PROMPT
PROMPT Le montant doit être la SOMME de toutes les transactions VO du jour
PROMPT (incluant 2817 + autres transactions VO)
PROMPT

PROMPT ============================================================================
PROMPT 3. SOLUTION - Désactiver le mode cumul pour le compte 342
PROMPT ============================================================================
PROMPT
PROMPT Pour exporter 2817 EN DÉTAIL, il faut supprimer la règle de cumul:
PROMPT
PROMPT DELETE FROM TA_RN_CUMUL_MR
PROMPT WHERE ID_COMPTE_BANCAIRE_SYSTEME = 352
PROMPT   AND ID_PRODUIT = (SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = 'ALL')
PROMPT   AND ID_MODE_REGLEMENT = (SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'VO');
PROMPT COMMIT;
PROMPT
PROMPT OU créer une exclusion pour le produit spécifique 90141615:
PROMPT
PROMPT -- Option: Changer ALL en liste spécifique excluant 90141615
PROMPT

PROMPT ============================================================================
PROMPT 4. COMPARAISON - Compte 394 vs 342
PROMPT ============================================================================

SELECT
    'Compte 394 (22.36)' AS COMPTE,
    'Pas de mode cumul' AS STATUT,
    'Export EN DÉTAIL ✅' AS RESULTAT
FROM DUAL

UNION ALL

SELECT
    'Compte 342 (2817)' AS COMPTE,
    'Mode cumul ALL+VO actif' AS STATUT,
    'Export en CUMUL ❌' AS RESULTAT
FROM DUAL;

PROMPT
PROMPT ============================================================================
PROMPT FIN VÉRIFICATION MODE CUMUL
PROMPT ============================================================================
