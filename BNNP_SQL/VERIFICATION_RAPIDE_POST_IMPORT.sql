-- ============================================================================
-- VERIFICATION RAPIDE POST-IMPORT - 22.36 vs 2817
-- ============================================================================
-- Date: 07/02/2026
-- A exécuter IMMÉDIATEMENT après RNADGENJUCGES01_TRACE_COMPLETE.sql
-- ============================================================================

SET LINESIZE 250
SET PAGESIZE 100

PROMPT ============================================================================
PROMPT VÉRIFICATION RAPIDE - Résultats clés
PROMPT ============================================================================

PROMPT
PROMPT 1️⃣  LES DEUX TRANSACTIONS SONT-ELLES DANS TA_RN_IMPORT_GESTION_JC ?
PROMPT ----------------------------------------------------------------------------

SELECT
    'TA_RN_IMPORT_GESTION_JC' AS TABLE_NAME,
    OPERATIONNETAMOUNT AS MONTANT,
    PAYMENTREFERENCE,
    NUMEROCLIENT,
    SETTLEMENTMODE,
    IDENTIFICATIONRIB,
    'OUI ✅' AS STATUT
FROM TA_RN_IMPORT_GESTION_JC
WHERE OPERATIONNETAMOUNT IN ('22.36', '2817')
ORDER BY OPERATIONNETAMOUNT DESC;

PROMPT
PROMPT Si les 2 lignes apparaissent → Les deux sont bien insérées
PROMPT Si 1 seule ligne → Une des transactions n'a pas été insérée
PROMPT Si 0 ligne → Aucune transaction insérée - problème majeur
PROMPT

PROMPT 2️⃣  LES DEUX TRANSACTIONS SONT-ELLES DANS TA_RN_EXPORT_JC ?
PROMPT ----------------------------------------------------------------------------

SELECT
    'TA_RN_EXPORT_JC' AS TABLE_NAME,
    ORAMT AS MONTANT,
    INTREF AS PAYMENTREFERENCE,
    USER3 AS NUMEROCLIENT,
    ACCNUM AS NUM_COMPTE_ACCURATE,
    'OUI ✅' AS STATUT
FROM TA_RN_EXPORT_JC
WHERE ORAMT IN ('22.36', '2817')
ORDER BY ORAMT DESC;

PROMPT
PROMPT Si les 2 lignes apparaissent → Les deux passent le filtre TA_RN_GESTION_JC ✅
PROMPT Si seulement 22.36 → 2817 est BLOQUÉE par le filtre ❌
PROMPT Si 0 ligne → Les deux sont bloquées
PROMPT

PROMPT 3️⃣  QUELS SONT LES COMPTES ACCURATE ASSOCIÉS ?
PROMPT ----------------------------------------------------------------------------

SELECT
    'Transaction ' || IMP.OPERATIONNETAMOUNT AS TRANSACTION,
    IMP.IDENTIFICATIONRIB AS RIB,
    CB.ID_COMPTE_BANCAIRE,
    CA.ID_COMPTE_ACCURATE,
    CA.NUM_COMPTE_ACCURATE,
    CA.NOM AS NOM_COMPTE,
    CA.TYPE_RAPPRO,
    CA.FLAG_ACTIF AS COMPTE_ACTIF
FROM TA_RN_IMPORT_GESTION_JC IMP
    LEFT JOIN TA_RN_COMPTE_BANCAIRE CB ON CB.IDENTIFICATION = IMP.IDENTIFICATIONRIB
    LEFT JOIN TA_RN_PERIMETRE_BANQUE PB ON PB.ID_COMPTE_BANCAIRE = CB.ID_COMPTE_BANCAIRE
    LEFT JOIN TA_RN_BANQUE_ACCURATE BA ON BA.ID_PERIMETRE_BANQUE = PB.ID_PERIMETRE_BANQUE
    LEFT JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = BA.ID_COMPTE_ACCURATE
WHERE IMP.OPERATIONNETAMOUNT IN ('22.36', '2817')
ORDER BY IMP.OPERATIONNETAMOUNT DESC;

PROMPT
PROMPT Notez bien les ID_COMPTE_ACCURATE pour la vérification suivante
PROMPT

PROMPT 4️⃣  CES COMPTES ACCURATE SONT-ILS PARAMÉTRÉS DANS TA_RN_GESTION_JC ?
PROMPT ----------------------------------------------------------------------------

WITH comptes_transactions AS (
    SELECT DISTINCT CA.ID_COMPTE_ACCURATE, CA.NUM_COMPTE_ACCURATE
    FROM TA_RN_IMPORT_GESTION_JC IMP
        JOIN TA_RN_COMPTE_BANCAIRE CB ON CB.IDENTIFICATION = IMP.IDENTIFICATIONRIB
        JOIN TA_RN_PERIMETRE_BANQUE PB ON PB.ID_COMPTE_BANCAIRE = CB.ID_COMPTE_BANCAIRE
        JOIN TA_RN_BANQUE_ACCURATE BA ON BA.ID_PERIMETRE_BANQUE = PB.ID_PERIMETRE_BANQUE
        JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = BA.ID_COMPTE_ACCURATE
    WHERE IMP.OPERATIONNETAMOUNT IN ('22.36', '2817')
)
SELECT
    CT.ID_COMPTE_ACCURATE,
    CT.NUM_COMPTE_ACCURATE,
    CASE WHEN GJ.ID_COMPTE_ACCURATE IS NOT NULL THEN 'OUI ✅' ELSE 'NON ❌' END AS PARAMETRE_DANS_GESTION_JC,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT
FROM comptes_transactions CT
    LEFT JOIN TA_RN_GESTION_JC GJ ON GJ.ID_COMPTE_ACCURATE = CT.ID_COMPTE_ACCURATE
    LEFT JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = GJ.ID_PRODUIT
    LEFT JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = GJ.ID_MODE_REGLEMENT
ORDER BY CT.ID_COMPTE_ACCURATE;

PROMPT
PROMPT Si un compte affiche "NON ❌" → C'EST LE PROBLÈME ! Ce compte doit être ajouté
PROMPT

PROMPT 5️⃣  RÉSUMÉ DES LOGS (Messages clés)
PROMPT ----------------------------------------------------------------------------

SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS') AS HEURE,
    CASE
        WHEN MESSAGE LIKE '%22.36%' THEN '22.36'
        WHEN MESSAGE LIKE '%2817%' THEN '2817'
        ELSE 'AUTRE'
    END AS TRANSACTION,
    TYPE_LOG,
    SUBSTR(MESSAGE, 1, 80) AS MESSAGE_COURT
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
  AND (MESSAGE LIKE '%CIBLE%' OR MESSAGE LIKE '%TROUVEE%' OR MESSAGE LIKE '%NON TROUVEE%')
ORDER BY DT_EXECUTION;

PROMPT
PROMPT 6️⃣  TEST EXISTS - Combien de transactions pour chaque compte ?
PROMPT ----------------------------------------------------------------------------

SELECT
    SUBSTR(VALEUR_EXTRAITE, 1, 5) AS ID_COMPTE,
    CASE
        WHEN VALEUR_EXTRAITE LIKE '%0 transactions%' THEN '❌ BLOQUÉ'
        ELSE '✅ PASSE'
    END AS STATUT,
    VALEUR_EXTRAITE AS DETAILS
FROM TA_RN_LOG_EXECUTION
WHERE MESSAGE = 'Test EXISTS TA_RN_GESTION_JC pour compte accurate'
  AND NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
ORDER BY DT_EXECUTION;

PROMPT
PROMPT ============================================================================
PROMPT DIAGNOSTIC FINAL
PROMPT ============================================================================

PROMPT
PROMPT Compteurs finaux:
PROMPT -----------------

SELECT
    (SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '22.36') AS "22.36 dans IMPORT",
    (SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '2817') AS "2817 dans IMPORT",
    (SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT = '22.36') AS "22.36 dans EXPORT",
    (SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT = '2817') AS "2817 dans EXPORT"
FROM DUAL;

PROMPT
PROMPT ============================================================================
PROMPT INTERPRÉTATION
PROMPT ============================================================================
PROMPT
PROMPT Scénario A: Les deux dans IMPORT (1, 1) mais seulement 22.36 dans EXPORT (1, 0)
PROMPT   → Le compte accurate de 2817 n'est PAS paramétré dans TA_RN_GESTION_JC
PROMPT   → SOLUTION : Voir section 4 ci-dessus, ajouter le compte manquant
PROMPT
PROMPT Scénario B: Aucune dans IMPORT (0, 0)
PROMPT   → Les transactions ne sont pas dans le fichier XML source
PROMPT   → Vérifier le fichier XML chargé dans TX_REGLT_GEST
PROMPT
PROMPT Scénario C: Seulement 22.36 dans IMPORT (1, 0)
PROMPT   → 2817 a planté lors de l'insertion (erreur SQL, contrainte)
PROMPT   → Vérifier les logs d'erreur (section 5)
PROMPT
PROMPT ============================================================================
PROMPT FIN VÉRIFICATION RAPIDE
PROMPT ============================================================================
