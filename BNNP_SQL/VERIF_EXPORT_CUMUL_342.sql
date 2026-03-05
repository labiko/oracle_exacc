-- ============================================================================
-- VÉRIFICATION CUMUL - Transaction 2817 dans TA_RN_EXPORT
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Vérifier si la transaction 2817 a été correctement cumulée
--           et exportée avec d'autres transactions VO du même jour
-- ============================================================================

SET LINESIZE 300
SET PAGESIZE 200

PROMPT ============================================================================
PROMPT VÉRIFICATION EXPORT CUMUL - Compte 342 (Transaction 2817 EUR)
PROMPT ============================================================================

PROMPT
PROMPT ============================================================================
PROMPT 1. CUMUL QUOTIDIEN dans TA_RN_EXPORT pour le compte 342
PROMPT ============================================================================

SELECT
    SOURCE,
    ACCNUM,
    ORAMT AS MONTANT_CUMUL,
    TRDAT AS DATE_TRADE,
    ORAMTCCY AS DEVISE,
    COMMENTAIRE,
    ID_CHARGEMENT,
    TO_CHAR(DT_INSERT, 'YYYY-MM-DD HH24:MI:SS') AS DATE_INSERTION
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ACCNUM LIKE '%83292%'  -- BBNP83292-EUR
  AND COMMENTAIRE LIKE '%cumul%'
ORDER BY TRDAT DESC, DT_INSERT DESC;

PROMPT
PROMPT Si vide → Le cumul n'a PAS été exporté (problème dans RNADGENEXPGES01.sql)
PROMPT Si présent → Le cumul a été exporté (vérifier si dans BR_DATA)
PROMPT

PROMPT ============================================================================
PROMPT 2. TOUTES LES TRANSACTIONS VO du jour pour le compte 342
PROMPT ============================================================================
PROMPT Somme des montants pour vérifier le montant du cumul attendu

SELECT
    TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD') AS DATE_TRADE,
    COUNT(*) AS NB_TRANSACTIONS_VO,
    SUM(TO_NUMBER(IG.OPERATIONNETAMOUNT)) AS SOMME_MONTANTS_VO,
    LISTAGG(IG.OPERATIONNETAMOUNT || ' (' || IG.PAYMENTREFERENCE || ')', ' + ')
        WITHIN GROUP (ORDER BY TO_NUMBER(IG.OPERATIONNETAMOUNT) DESC) AS DETAIL_MONTANTS
FROM TA_RN_IMPORT_GESTION IG
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
        ON CBS.RIBBANKCODE||CBS.RIBBRANCHCODE||CBS.RIBIDENTIFICATION||CBS.RIBCHECKDIGIT = IG.IDENTIFICATIONRIB
WHERE CBS.ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND IG.SETTLEMENTMODE = 'VO'
  AND IG.DATEVALUE >= TRUNC(SYSDATE) - 7  -- Derniers 7 jours
GROUP BY TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD')
ORDER BY 1 DESC;

PROMPT
PROMPT Le montant du cumul dans TA_RN_EXPORT doit correspondre à SOMME_MONTANTS_VO
PROMPT

PROMPT ============================================================================
PROMPT 3. DÉTAIL DES TRANSACTIONS VO CUMULÉES (Jour de 2817)
PROMPT ============================================================================

WITH jour_2817 AS (
    SELECT DISTINCT TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD') AS DATE_TRADE
    FROM TA_RN_IMPORT_GESTION IG
        JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
            ON CBS.RIBBANKCODE||CBS.RIBBRANCHCODE||CBS.RIBIDENTIFICATION||CBS.RIBCHECKDIGIT = IG.IDENTIFICATIONRIB
    WHERE CBS.ID_COMPTE_BANCAIRE_SYSTEME = 352
      AND IG.OPERATIONNETAMOUNT = '2817'
      AND ROWNUM = 1
)
SELECT
    IG.OPERATIONNETAMOUNT AS MONTANT,
    IG.PAYMENTREFERENCE,
    IG.NUMEROCLIENT AS CODE_CLIENT,
    IG.IDENTIFICATION AS CODE_SOCIETE,
    IG.SETTLEMENTMODE AS MODE,
    IG.TYPEREGLEMENT AS TYPE,
    IG.OPERATIONNETAMOUNTCURRENCY AS DEVISE,
    TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD HH24:MI:SS') AS DATE_TRANSACTION,
    CASE
        WHEN IG.OPERATIONNETAMOUNT = '2817' THEN '🎯 CIBLE'
        ELSE ''
    END AS MARQUEUR
FROM TA_RN_IMPORT_GESTION IG
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
        ON CBS.RIBBANKCODE||CBS.RIBBRANCHCODE||CBS.RIBIDENTIFICATION||CBS.RIBCHECKDIGIT = IG.IDENTIFICATIONRIB
    CROSS JOIN jour_2817 J
WHERE CBS.ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND IG.SETTLEMENTMODE = 'VO'
  AND TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD') = J.DATE_TRADE
ORDER BY TO_NUMBER(IG.OPERATIONNETAMOUNT) DESC;

PROMPT
PROMPT Toutes ces transactions doivent être incluses dans le cumul quotidien
PROMPT

PROMPT ============================================================================
PROMPT 4. VÉRIFICATION - Cumul dans BANKREC.BR_DATA ?
PROMPT ============================================================================

SELECT
    ACCNUM,
    ORAMT AS MONTANT,
    TRDAT AS DATE_TRADE,
    COMMENTAIRE,
    TO_CHAR(DT_INSERT, 'YYYY-MM-DD HH24:MI:SS') AS DATE_INSERTION
FROM BANKREC.BR_DATA
WHERE ACCNUM LIKE '%83292%'  -- BBNP83292-EUR
  AND TRDAT >= TRUNC(SYSDATE) - 7  -- Derniers 7 jours
ORDER BY TRDAT DESC, ORAMT DESC;

PROMPT
PROMPT Si cumul présent dans TA_RN_EXPORT mais absent de BR_DATA
PROMPT   → Problème APRÈS l'export (processus Oracle Bankrec)
PROMPT
PROMPT Si cumul présent dans les deux
PROMPT   → Le processus fonctionne correctement en mode CUMUL
PROMPT   → Pour avoir un export DÉTAIL, modifier TA_RN_CUMUL_MR
PROMPT

PROMPT ============================================================================
PROMPT 5. COMPARAISON - Montants TA_RN_EXPORT vs TA_RN_IMPORT_GESTION
PROMPT ============================================================================

WITH cumul_import AS (
    SELECT
        TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD') AS DATE_TRADE,
        SUM(TO_NUMBER(IG.OPERATIONNETAMOUNT)) AS SOMME_IMPORT
    FROM TA_RN_IMPORT_GESTION IG
        JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
            ON CBS.RIBBANKCODE||CBS.RIBBRANCHCODE||CBS.RIBIDENTIFICATION||CBS.RIBCHECKDIGIT = IG.IDENTIFICATIONRIB
    WHERE CBS.ID_COMPTE_BANCAIRE_SYSTEME = 352
      AND IG.SETTLEMENTMODE = 'VO'
      AND IG.DATEVALUE >= TRUNC(SYSDATE) - 7
    GROUP BY TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD')
),
cumul_export AS (
    SELECT
        TO_CHAR(TRDAT, 'YYYY-MM-DD') AS DATE_TRADE,
        TO_NUMBER(ORAMT) AS MONTANT_EXPORT
    FROM TA_RN_EXPORT
    WHERE SOURCE = 'GEST'
      AND ACCNUM LIKE '%83292%'
      AND COMMENTAIRE LIKE '%cumul%'
      AND TRDAT >= TRUNC(SYSDATE) - 7
)
SELECT
    COALESCE(I.DATE_TRADE, E.DATE_TRADE) AS DATE_TRADE,
    I.SOMME_IMPORT AS MONTANT_ATTENDU,
    E.MONTANT_EXPORT AS MONTANT_REEL,
    CASE
        WHEN I.SOMME_IMPORT = E.MONTANT_EXPORT THEN '✅ COHÉRENT'
        WHEN I.SOMME_IMPORT IS NULL THEN '⚠️ Import absent'
        WHEN E.MONTANT_EXPORT IS NULL THEN '❌ Export absent'
        ELSE '❌ INCOHÉRENT (écart: ' || TO_CHAR(I.SOMME_IMPORT - E.MONTANT_EXPORT) || ')'
    END AS STATUT
FROM cumul_import I
    FULL OUTER JOIN cumul_export E ON I.DATE_TRADE = E.DATE_TRADE
ORDER BY 1 DESC;

PROMPT
PROMPT Si INCOHÉRENT → Le cumul ne contient pas toutes les transactions VO
PROMPT

PROMPT ============================================================================
PROMPT 6. RÉSUMÉ - Diagnostic du Problème
PROMPT ============================================================================

SELECT
    'Transaction 2817 dans TA_RN_IMPORT_GESTION ?' AS VERIFICATION,
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END AS RESULTAT
FROM TA_RN_IMPORT_GESTION IG
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
        ON CBS.RIBBANKCODE||CBS.RIBBRANCHCODE||CBS.RIBIDENTIFICATION||CBS.RIBCHECKDIGIT = IG.IDENTIFICATIONRIB
WHERE CBS.ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND IG.OPERATIONNETAMOUNT = '2817'

UNION ALL

SELECT
    'Cumul VO dans TA_RN_EXPORT ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ACCNUM LIKE '%83292%'
  AND COMMENTAIRE LIKE '%cumul%'

UNION ALL

SELECT
    'Cumul VO dans BANKREC.BR_DATA ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅' ELSE 'NON ❌' END
FROM BANKREC.BR_DATA
WHERE ACCNUM LIKE '%83292%'
  AND TRDAT >= TRUNC(SYSDATE) - 7

UNION ALL

SELECT
    'Transaction 2817 en DÉTAIL dans TA_RN_EXPORT ?',
    CASE WHEN COUNT(*) > 0 THEN 'OUI ✅ (Pas de cumul)' ELSE 'NON ❌ (Mode cumul actif)' END
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ORAMT = '2817'
  AND COMMENTAIRE NOT LIKE '%cumul%'

UNION ALL

SELECT
    'Règle de cumul ALL+VO active pour compte 342 ?',
    CASE
        WHEN COUNT(*) > 0 THEN 'OUI ❌ (Transactions cumulées)'
        ELSE 'NON ✅ (Transactions en détail)'
    END
FROM TA_RN_GESTION_ACCURATE GA
    JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE GA.ID_COMPTE_ACCURATE = 342
  AND P.CODE_PRODUIT = 'ALL'
  AND MR.CODE_MODE_REGLEMENT = 'VO';

PROMPT
PROMPT ============================================================================
PROMPT INTERPRÉTATION
PROMPT ============================================================================
PROMPT
PROMPT SCÉNARIO A : 2817 dans IMPORT + Cumul dans EXPORT + Cumul dans BR_DATA
PROMPT   → ✅ Le processus fonctionne correctement en mode CUMUL
PROMPT   → 💡 Pour avoir 2817 EN DÉTAIL, supprimer la règle de cumul ALL+VO
PROMPT   → 📄 Voir SOLUTION_OPTIONS.md (OPTION A ou B)
PROMPT
PROMPT SCÉNARIO B : 2817 dans IMPORT + Cumul dans EXPORT + Cumul ABSENT de BR_DATA
PROMPT   → ❌ Problème APRÈS l'export (processus Oracle Bankrec)
PROMPT   → 💡 Investiguer le processus qui lit TA_RN_EXPORT pour alimenter BR_DATA
PROMPT
PROMPT SCÉNARIO C : 2817 dans IMPORT + Cumul ABSENT de EXPORT
PROMPT   → ❌ Problème dans le script RNADGENEXPGES01.sql
PROMPT   → 💡 Exécuter RNADGENEXPGES01_TRACE_COMPLETE.sql pour diagnostiquer
PROMPT   → 💡 Analyser les logs avec VERIF_LOGS_EXPGES01_TRACE.sql
PROMPT
PROMPT SCÉNARIO D : 2817 dans IMPORT + 2817 EN DÉTAIL dans EXPORT (pas de cumul)
PROMPT   → ✅ La règle de cumul a été supprimée avec succès
PROMPT   → ✅ Vérifier que 2817 apparaît dans BR_DATA
PROMPT
PROMPT ============================================================================
PROMPT ACTIONS RECOMMANDÉES
PROMPT ============================================================================
PROMPT
PROMPT 1. Analyser le RÉSULTAT de la section 6 ci-dessus
PROMPT 2. Consulter SOLUTION_OPTIONS.md pour choisir l'option appropriée
PROMPT 3. Si cumul correct mais besoin de détail → Appliquer OPTION A ou B
PROMPT 4. Si cumul absent → Exécuter RNADGENEXPGES01_TRACE_COMPLETE.sql
PROMPT
PROMPT ============================================================================
PROMPT FIN VÉRIFICATION
PROMPT ============================================================================
