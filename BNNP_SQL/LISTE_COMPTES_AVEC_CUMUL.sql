-- ============================================================================
-- LISTE DES COMPTES ACCURATE AVEC INDICATEUR CUMUL/DETAIL
-- ============================================================================
-- Auteur: Alpha DIALLO
-- Date: 09/02/2026
-- Description: Affiche tous les comptes avec une colonne indiquant
--              si le compte a un parametrage CUMUL ou DETAIL
-- ============================================================================

SET LINESIZE 500
SET PAGESIZE 200

-- ============================================================================
-- REQUETE PRINCIPALE - Liste des comptes avec indicateur CUMUL/DETAIL
-- ============================================================================

SELECT
    DISTINCT G3.ACCT_NUM||'-'||G2.ACCT_NUM||'-'||G1.ACCT_NUM AS GROUPEG,
    RCBS.ID_COMPTE_BANCAIRE_SYSTEME AS ID_CBS,
    RCA.FLAG_ACTIF,
    RCA.NUM_COMPTE_ACCURATE,
    -- ========================================
    -- NOUVELLE COLONNE: INDICATEUR CUMUL/DETAIL
    -- ========================================
    CASE
        WHEN EXISTS (
            SELECT 1 FROM EXP_RNAPA.TA_RN_CUMUL_MR CMR
            WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = RCBS.ID_COMPTE_BANCAIRE_SYSTEME
        ) THEN '[CUMUL]'
        ELSE '[DETAIL]'
    END AS MODE_EXPORT,
    -- Detail des regles de cumul si existantes
    (
        SELECT LISTAGG(P.CODE_PRODUIT || '+' || MR.CODE_MODE_REGLEMENT, ', ')
               WITHIN GROUP (ORDER BY P.CODE_PRODUIT)
        FROM EXP_RNAPA.TA_RN_CUMUL_MR CMR2
            JOIN EXP_RNAPA.TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR2.ID_PRODUIT
            JOIN EXP_RNAPA.TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR2.ID_MODE_REGLEMENT
        WHERE CMR2.ID_COMPTE_BANCAIRE_SYSTEME = RCBS.ID_COMPTE_BANCAIRE_SYSTEME
    ) AS REGLES_CUMUL,
    -- ========================================
    LISTAGG(DISTINCT RS.CODE, ',') AS Lst_CodeSociete,
    LISTAGG(DISTINCT RCC.Num_Compte_COMPTABLE, ',') AS lst_Cpt_COMPTABLE,
    BCI.SOCIETE,
    BCI.LIBELLE_COMPTE_COMPTABLE,
    RCA.NOM AS NomCompteACCURATE,
    RCA.TYPE_RAPPRO,
    BCM.METHODE,
    BCM.COMPTE_BANCAIRE,
    GCC.NUM_COMPTE_COMPTABLE AS NumCompteComptable,
    BANQUE,
    REPLACE(REPLACE(BCI.RIB,'/',''),' ','') AS RIB,
    BCI.RIB AS RIB_ACCURATE,
    RPB.ID_COMPTE_BANCAIRE,
    RPB.FLAG_ACTIF AS Banque_ACTIF,
    RCB.NOM AS NomCompteBancaire,
    RGA.ID_COMPTE_BANCAIRE_SYSTEME,
    RCBS.RIB AS RIB_CBS,
    RCBS.TIERS,
    RCBS.GENERATIONCONTREPARTIE,
    LISTAGG(DISTINCT ANM.ACCOUNT_NUMBER, ',') AS Lst_SousCompte,
    RD.ID_DEVISE,
    RD.CODE_ISO_DEVISE,
    BCI.ACCOUNT_ID,
    LISTAGG(DISTINCT RCA.ID_COMPTE_ACCURATE, ',') AS lst_ID_Cpt_ACCURATE,
    RCB.BRANCHCODE,
    RCB.BANKCODE,
    RCB.IDENTIFICATION
FROM EXP_RNAPA.TA_RN_COMPTE_ACCURATE RCA
    LEFT JOIN BANKREC.BS_ACCOUNT_NUMBER_MAP ANM ON (RCA.NUM_COMPTE_ACCURATE||'-CB' = ANM.ACCOUNT_NUMBER OR RCA.NUM_COMPTE_ACCURATE||'-ST' = ANM.ACCOUNT_NUMBER)
    LEFT JOIN EXP_RNAPA.TA_RN_BC_INFOS BCI ON RCA.NUM_COMPTE_ACCURATE = BCI.COMPTE_COMPTABLE
    LEFT JOIN EXP_RNAPA.TA_RN_COMPTA_ACCURATE CtaA ON CtaA.ID_COMPTE_ACCURATE = RCA.ID_COMPTE_ACCURATE
    LEFT JOIN EXP_RNAPA.TA_RN_PERIMETRE_COMPTA RPC ON RPC.ID_PERIMETRE_COMPTA = CtaA.ID_PERIMETRE_COMPTA
    LEFT JOIN EXP_RNAPA.TA_RN_BANQUE_ACCURATE RBA ON RBA.ID_COMPTE_ACCURATE = RCA.ID_COMPTE_ACCURATE
    LEFT JOIN EXP_RNAPA.TA_RN_PERIMETRE_BANQUE RPB ON RPB.ID_PERIMETRE_BANQUE = RBA.ID_PERIMETRE_BANQUE
    LEFT JOIN EXP_RNAPA.TA_RN_COMPTE_BANCAIRE RCB ON RCB.ID_COMPTE_BANCAIRE = RPB.ID_COMPTE_BANCAIRE
    LEFT JOIN EXP_RNAPA.TA_RN_COMPTE_COMPTABLE RCC ON RCC.ID_COMPTE_COMPTABLE = RPC.ID_COMPTE_COMPTABLE
    LEFT JOIN EXP_RNAPA.TA_RN_GESTION_ACCURATE RGA ON RGA.ID_COMPTE_ACCURATE = RCA.ID_COMPTE_ACCURATE
    LEFT JOIN EXP_RNAPA.TA_RN_COMPTE_BANCAIRE_SYSTEME RCBS ON RCBS.ID_COMPTE_BANCAIRE_SYSTEME = RGA.ID_COMPTE_BANCAIRE_SYSTEME
    LEFT JOIN EXP_RNAPA.TA_RN_SOCIETE RS ON RPC.ID_SOCIETE = RS.ID_SOCIETE
    LEFT JOIN EXP_RNAPA.TA_RN_DEVISE RD ON RPC.ID_DEVISE = RD.ID_DEVISE
    LEFT JOIN EXP_RNAPA.BA_COMPTE_METHODE BCM ON RCA.NUM_COMPTE_ACCURATE = BCM.COMPTE_COMPTABLE
    LEFT JOIN EXP_RNAPA.TA_RN_GEST_COMPTE_COMPTABLE GCC ON GCC.COMPTE_BANCAIRE = BCM.COMPTE_BANCAIRE
    LEFT JOIN BANKREC.BRR_ACCOUNTS A ON BCI.ACCOUNT_ID = A.ACCOUNT_ID
    LEFT JOIN BS_ACCTS G1 ON G1.ACCT_ID = A.ACCOUNT_GROUP
    LEFT JOIN BS_ACCTS G2 ON G2.ACCT_ID = G1.ACCT_GROUP
    LEFT JOIN BS_ACCTS G3 ON G3.ACCT_ID = G2.ACCT_GROUP
    LEFT JOIN BS_ACCTS G4 ON G4.ACCT_ID = G3.ACCT_GROUP
WHERE 1 = 1
    --AND RCB.IDENTIFICATION IN ('00016111832','00016107534')
GROUP BY
    (G3.ACCT_NUM||'-'||G2.ACCT_NUM||'-'||G1.ACCT_NUM, RCBS.ID_COMPTE_BANCAIRE_SYSTEME),
    BCI.ACCOUNT_ID,
    BCI.SOCIETE,
    RCA.NUM_COMPTE_ACCURATE,
    BCI.LIBELLE_COMPTE_COMPTABLE,
    BCM.METHODE,
    BCM.COMPTE_BANCAIRE,
    GCC.NUM_COMPTE_COMPTABLE,
    RD.ID_DEVISE,
    RD.CODE_ISO_DEVISE,
    BANQUE,
    REPLACE(REPLACE(BCI.RIB,'/',''),' ',''),
    BCI.RIB,
    RCB.BRANCHCODE,
    RCB.BANKCODE,
    RCB.IDENTIFICATION,
    RCA.NOM,
    RCA.FLAG_ACTIF,
    RCA.TYPE_RAPPRO,
    RPB.ID_COMPTE_BANCAIRE,
    RPB.FLAG_ACTIF,
    RCB.NOM,
    RGA.ID_COMPTE_BANCAIRE_SYSTEME,
    RCBS.RIB,
    RCBS.TIERS,
    RCBS.GENERATIONCONTREPARTIE
ORDER BY FLAG_ACTIF DESC, GROUPEG DESC, RCA.NUM_COMPTE_ACCURATE;


-- ============================================================================
-- ============================================================================
-- SCRIPT 2: SUPPRESSION DU PARAMETRAGE CUMUL
-- ============================================================================
-- ============================================================================
-- ATTENTION: Modifier ID_COMPTE_BANCAIRE_SYSTEME avant execution!
-- ============================================================================

/*
-- ============================================================================
-- SUPPRESSION CUMUL - A executer pour passer en mode DETAIL
-- ============================================================================
-- PARAMETRES A MODIFIER:
DEFINE ID_CBS = 352

-- Verification avant suppression
SELECT
    CMR.ID_COMPTE_BANCAIRE_SYSTEME,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    MR.LIBELLE
FROM TA_RN_CUMUL_MR CMR
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = &ID_CBS;

-- Suppression
DELETE FROM TA_RN_CUMUL_MR
WHERE ID_COMPTE_BANCAIRE_SYSTEME = &ID_CBS;

COMMIT;

-- Verification apres suppression (doit retourner 0 ligne)
SELECT COUNT(*) AS NB_REGLES_RESTANTES
FROM TA_RN_CUMUL_MR
WHERE ID_COMPTE_BANCAIRE_SYSTEME = &ID_CBS;
*/


-- ============================================================================
-- ============================================================================
-- SCRIPT 3: ROLLBACK - RECREER LE PARAMETRAGE CUMUL
-- ============================================================================
-- ============================================================================
-- ATTENTION: Modifier les parametres avant execution!
-- ============================================================================

/*
-- ============================================================================
-- ROLLBACK CUMUL - Recreer le parametrage cumul ALL+VO
-- ============================================================================
-- PARAMETRES A MODIFIER:
DEFINE ID_CBS = 352
DEFINE CODE_PRODUIT = 'ALL'
DEFINE CODE_MODE_REGLEMENT = 'VO'

-- Verification si la regle existe deja
SELECT COUNT(*) AS EXISTE_DEJA
FROM TA_RN_CUMUL_MR CMR
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = &ID_CBS
  AND P.CODE_PRODUIT = '&CODE_PRODUIT'
  AND MR.CODE_MODE_REGLEMENT = '&CODE_MODE_REGLEMENT';

-- Insertion de la regle de cumul
INSERT INTO TA_RN_CUMUL_MR (
    ID_COMPTE_BANCAIRE_SYSTEME,
    ID_MODE_REGLEMENT,
    ID_PRODUIT
)
SELECT
    &ID_CBS,
    (SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = '&CODE_MODE_REGLEMENT'),
    (SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = '&CODE_PRODUIT')
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM TA_RN_CUMUL_MR CMR
        JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
        JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
    WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = &ID_CBS
      AND P.CODE_PRODUIT = '&CODE_PRODUIT'
      AND MR.CODE_MODE_REGLEMENT = '&CODE_MODE_REGLEMENT'
);

COMMIT;

-- Verification apres insertion
SELECT
    CMR.ID_COMPTE_BANCAIRE_SYSTEME,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    '[OK] Regle de cumul creee' AS STATUT
FROM TA_RN_CUMUL_MR CMR
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = &ID_CBS;
*/


-- ============================================================================
-- AIDE MEMOIRE
-- ============================================================================
--
-- [CUMUL]  = Les transactions sont agregees par jour/mode
--            -> Vous ne verrez PAS les transactions individuelles dans BR_DATA
--            -> Vous verrez un montant CUMULE par jour
--
-- [DETAIL] = Les transactions sont exportees individuellement
--            -> Chaque transaction apparait dans BR_DATA
--
-- POUR PASSER DE CUMUL A DETAIL:
--   1. Identifier ID_COMPTE_BANCAIRE_SYSTEME avec la requete principale
--   2. Executer le SCRIPT 2 (Suppression)
--   3. Relancer le JOB d'import
--
-- POUR REVENIR EN CUMUL (ROLLBACK):
--   1. Executer le SCRIPT 3 (Rollback)
--
-- ============================================================================
