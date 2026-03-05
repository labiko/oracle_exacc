-- ============================================================================
-- VÉRIFICATION HISTORIQUE - Règle de cumul en PRODUCTION
-- ============================================================================
-- Objectif: Déterminer si la règle de cumul ALL+VO est récente ou ancienne
--           pour savoir si c'est une erreur de test ou un paramétrage voulu
-- ============================================================================

SET LINESIZE 300
SET PAGESIZE 200

PROMPT ============================================================================
PROMPT HISTORIQUE - Règle de cumul pour compte 342 en PRODUCTION
PROMPT ============================================================================

PROMPT
PROMPT 1. La règle de cumul actuelle
PROMPT

SELECT
    CMR.ID_COMPTE_BANCAIRE_SYSTEME,
    CBS.NUMERO AS NUM_CBS,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    MR.LIBELLE,
    TO_CHAR(CMR.DT_INSERT, 'YYYY-MM-DD HH24:MI:SS') AS DATE_CREATION,
    TO_CHAR(CMR.DT_UPDATE, 'YYYY-MM-DD HH24:MI:SS') AS DATE_MODIFICATION
FROM TA_RN_CUMUL_MR CMR
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS ON CBS.ID_COMPTE_BANCAIRE_SYSTEME = CMR.ID_COMPTE_BANCAIRE_SYSTEME
WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND P.CODE_PRODUIT = 'ALL'
  AND MR.CODE_MODE_REGLEMENT = 'VO';

PROMPT
PROMPT Si DATE_CREATION récente (derniers jours/semaines) → Possiblement une erreur de test
PROMPT Si DATE_CREATION ancienne (plusieurs mois) → Paramétrage fonctionnel voulu
PROMPT

PROMPT ============================================================================
PROMPT 2. Historique des exports CUMUL pour le compte 342
PROMPT ============================================================================
PROMPT Vérifier si des cumuls ont déjà été exportés (preuve d'utilisation)

SELECT
    TO_CHAR(TRDAT, 'YYYY-MM') AS MOIS,
    COUNT(*) AS NB_CUMULS_EXPORTES,
    MIN(TO_CHAR(TRDAT, 'YYYY-MM-DD')) AS PREMIER_CUMUL,
    MAX(TO_CHAR(TRDAT, 'YYYY-MM-DD')) AS DERNIER_CUMUL,
    SUM(TO_NUMBER(ORAMT)) AS TOTAL_MONTANTS
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ACCNUM LIKE '%83292%'
  AND COMMENTAIRE LIKE '%cumul%'
GROUP BY TO_CHAR(TRDAT, 'YYYY-MM')
ORDER BY 1 DESC;

PROMPT
PROMPT Si plusieurs mois de cumuls → La règle est utilisée depuis longtemps (fonctionnel)
PROMPT Si aucun cumul ou seulement récent → Possiblement créée par erreur
PROMPT

PROMPT ============================================================================
PROMPT 3. Derniers exports CUMUL détaillés (10 derniers)
PROMPT ============================================================================

SELECT
    ACCNUM,
    ORAMT AS MONTANT_CUMUL,
    TRDAT AS DATE_TRADE,
    COMMENTAIRE,
    TO_CHAR(DT_INSERT, 'YYYY-MM-DD HH24:MI:SS') AS DATE_INSERTION,
    ID_CHARGEMENT
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ACCNUM LIKE '%83292%'
  AND COMMENTAIRE LIKE '%cumul%'
ORDER BY TRDAT DESC, DT_INSERT DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT

PROMPT ============================================================================
PROMPT 4. Y a-t-il des exports EN DÉTAIL pour ce compte ?
PROMPT ============================================================================
PROMPT Si OUI → La règle de cumul n'existait pas avant ou ne s'appliquait pas

SELECT
    TO_CHAR(TRDAT, 'YYYY-MM') AS MOIS,
    COUNT(*) AS NB_EXPORTS_DETAIL,
    MIN(TO_CHAR(TRDAT, 'YYYY-MM-DD')) AS PREMIER_EXPORT,
    MAX(TO_CHAR(TRDAT, 'YYYY-MM-DD')) AS DERNIER_EXPORT
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ACCNUM LIKE '%83292%'
  AND (COMMENTAIRE IS NULL OR COMMENTAIRE NOT LIKE '%cumul%')
GROUP BY TO_CHAR(TRDAT, 'YYYY-MM')
ORDER BY 1 DESC;

PROMPT
PROMPT Si exports DÉTAIL dans le passé puis CUMUL maintenant
PROMPT   → La règle a été ajoutée RÉCEMMENT (changement de comportement)
PROMPT
PROMPT Si toujours en CUMUL
PROMPT   → La règle existe depuis le début (paramétrage d'origine)
PROMPT

PROMPT ============================================================================
PROMPT 5. Autres comptes avec la même règle ALL+VO
PROMPT ============================================================================
PROMPT Vérifier si d'autres comptes ont cette règle (pattern habituel ou exception)

SELECT
    CMR.ID_COMPTE_BANCAIRE_SYSTEME,
    CBS.NUMERO AS NUM_CBS,
    GA.ID_COMPTE_ACCURATE,
    CA.NUM_COMPTE_ACCURATE,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT
FROM TA_RN_CUMUL_MR CMR
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS ON CBS.ID_COMPTE_BANCAIRE_SYSTEME = CMR.ID_COMPTE_BANCAIRE_SYSTEME
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
    LEFT JOIN TA_RN_GESTION_ACCURATE GA ON GA.ID_COMPTE_BANCAIRE_SYSTEME = CBS.ID_COMPTE_BANCAIRE_SYSTEME
    LEFT JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = GA.ID_COMPTE_ACCURATE
WHERE P.CODE_PRODUIT = 'ALL'
  AND MR.CODE_MODE_REGLEMENT = 'VO'
ORDER BY CMR.ID_COMPTE_BANCAIRE_SYSTEME;

PROMPT
PROMPT Si seulement le compte 342 → Exception (possiblement erreur de test)
PROMPT Si plusieurs comptes → Pattern habituel (paramétrage fonctionnel)
PROMPT

PROMPT ============================================================================
PROMPT 6. DIAGNOSTIC - La règle est-elle une erreur ?
PROMPT ============================================================================

WITH historique_cumul AS (
    SELECT
        COUNT(*) AS nb_cumuls,
        MIN(TRDAT) AS premier_cumul,
        MAX(TRDAT) AS dernier_cumul
    FROM TA_RN_EXPORT
    WHERE SOURCE = 'GEST'
      AND ACCNUM LIKE '%83292%'
      AND COMMENTAIRE LIKE '%cumul%'
),
historique_detail AS (
    SELECT
        COUNT(*) AS nb_details,
        MIN(TRDAT) AS premier_detail,
        MAX(TRDAT) AS dernier_detail
    FROM TA_RN_EXPORT
    WHERE SOURCE = 'GEST'
      AND ACCNUM LIKE '%83292%'
      AND (COMMENTAIRE IS NULL OR COMMENTAIRE NOT LIKE '%cumul%')
),
autres_comptes_cumul AS (
    SELECT COUNT(DISTINCT CMR.ID_COMPTE_BANCAIRE_SYSTEME) AS nb_autres_comptes
    FROM TA_RN_CUMUL_MR CMR
        JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
        JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
    WHERE P.CODE_PRODUIT = 'ALL'
      AND MR.CODE_MODE_REGLEMENT = 'VO'
      AND CMR.ID_COMPTE_BANCAIRE_SYSTEME != 352
)
SELECT
    CASE
        WHEN HC.nb_cumuls = 0 THEN '⚠️ AUCUN CUMUL JAMAIS EXPORTÉ'
        WHEN HC.nb_cumuls > 0 AND TRUNC(HC.premier_cumul) >= TRUNC(SYSDATE) - 30 THEN '⚠️ CUMULS RÉCENTS (moins de 30 jours)'
        WHEN HC.nb_cumuls > 0 AND TRUNC(HC.premier_cumul) < TRUNC(SYSDATE) - 30 THEN '✅ CUMULS ANCIENS (plus de 30 jours)'
    END AS STATUT_CUMULS,
    HC.nb_cumuls AS NB_CUMULS_EXPORTES,
    TO_CHAR(HC.premier_cumul, 'YYYY-MM-DD') AS PREMIER_CUMUL,
    TO_CHAR(HC.dernier_cumul, 'YYYY-MM-DD') AS DERNIER_CUMUL,
    HD.nb_details AS NB_DETAILS_EXPORTES,
    TO_CHAR(HD.premier_detail, 'YYYY-MM-DD') AS PREMIER_DETAIL,
    TO_CHAR(HD.dernier_detail, 'YYYY-MM-DD') AS DERNIER_DETAIL,
    ACC.nb_autres_comptes AS NB_AUTRES_COMPTES_ALL_VO,
    CASE
        WHEN HC.nb_cumuls = 0 THEN '🚨 RÈGLE PROBABLEMENT CRÉÉE PAR ERREUR (jamais utilisée)'
        WHEN HC.nb_cumuls > 0 AND TRUNC(HC.premier_cumul) >= TRUNC(SYSDATE) - 30 THEN '⚠️ RÈGLE RÉCENTE (vérifier si test ou fonctionnel)'
        WHEN HC.nb_cumuls > 0 AND TRUNC(HC.premier_cumul) < TRUNC(SYSDATE) - 30 AND ACC.nb_autres_comptes = 0 THEN '⚠️ RÈGLE ANCIENNE mais SEUL compte avec ALL+VO (suspect)'
        WHEN HC.nb_cumuls > 0 AND TRUNC(HC.premier_cumul) < TRUNC(SYSDATE) - 30 AND ACC.nb_autres_comptes > 0 THEN '✅ RÈGLE FONCTIONNELLE (ancienne et pattern habituel)'
        ELSE '❓ INDÉTERMINÉ'
    END AS CONCLUSION
FROM historique_cumul HC
    CROSS JOIN historique_detail HD
    CROSS JOIN autres_comptes_cumul ACC;

PROMPT
PROMPT ============================================================================
PROMPT INTERPRÉTATION
PROMPT ============================================================================
PROMPT
PROMPT CAS 1: AUCUN CUMUL JAMAIS EXPORTÉ
PROMPT   → La règle a été créée mais JAMAIS utilisée
PROMPT   → TRÈS PROBABLEMENT une erreur de test
PROMPT   → ACTION: Supprimer la règle (OPTION A)
PROMPT
PROMPT CAS 2: CUMULS RÉCENTS (< 30 jours)
PROMPT   → La règle est nouvelle
PROMPT   → POSSIBLEMENT créée lors de tests en recette puis déployée par erreur
PROMPT   → ACTION: Vérifier avec l'équipe fonctionnelle avant suppression
PROMPT
PROMPT CAS 3: CUMULS ANCIENS (> 30 jours) + SEUL compte avec ALL+VO
PROMPT   → La règle existe depuis longtemps MAIS pas de pattern habituel
PROMPT   → SUSPECT (pourquoi seulement ce compte ?)
PROMPT   → ACTION: Vérifier la raison métier de cette exception
PROMPT
PROMPT CAS 4: CUMULS ANCIENS + Plusieurs comptes avec ALL+VO
PROMPT   → La règle fait partie du paramétrage habituel
PROMPT   → FONCTIONNEL (comportement voulu)
PROMPT   → ACTION: Si le métier veut du détail, créer une évolution
PROMPT
PROMPT CAS 5: Exports DÉTAIL dans le passé puis CUMUL maintenant
PROMPT   → Changement de comportement récent
PROMPT   → La règle a été AJOUTÉE récemment
PROMPT   → ACTION: Identifier QUAND et POURQUOI le changement
PROMPT
PROMPT ============================================================================
PROMPT FIN VÉRIFICATION HISTORIQUE
PROMPT ============================================================================
