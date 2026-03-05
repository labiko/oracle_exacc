-- ============================================================================
-- TRACER PAYMENTREFERENCE - Où sont insérés 22.36 vs 2817 ?
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Utiliser PAYMENTREFERENCE (identifiant unique) pour tracer
--           dans quelle table 22.36 est inséré mais pas 2817
-- ============================================================================

PROMPT ============================================================================
PROMPT ÉTAPE 1 : Récupérer les PAYMENTREFERENCE des deux transactions
PROMPT ============================================================================

-- Transaction 22.36
SELECT
    '22.36' AS Transaction,
    PAYMENTREFERENCE,
    NUMEROCLIENT,
    SETTLEMENTMODE,
    OPERATIONNETAMOUNT,
    BENEFICIARYNAME,
    IDENTIFICATIONRIB,
    COMMENTAIRE
FROM TA_RN_IMPORT_GESTION_JC
WHERE OPERATIONNETAMOUNT = '22.36'
  AND ROWNUM = 1;

PROMPT

-- Transaction 2817
SELECT
    '2817' AS Transaction,
    PAYMENTREFERENCE,
    NUMEROCLIENT,
    SETTLEMENTMODE,
    OPERATIONNETAMOUNT,
    BENEFICIARYNAME,
    IDENTIFICATIONRIB,
    COMMENTAIRE
FROM TA_RN_IMPORT_GESTION_JC
WHERE OPERATIONNETAMOUNT = '2817'
  AND ROWNUM = 1;

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 2 : Chercher PAYMENTREFERENCE dans TA_RN_EXPORT_JC
PROMPT ============================================================================
PROMPT (Cette table devrait être vide selon nos analyses précédentes)

-- Chercher 22.36 dans TA_RN_EXPORT_JC
SELECT
    'TA_RN_EXPORT_JC - 22.36' AS Table_Transaction,
    COUNT(*) AS NB_LIGNES,
    MAX(PAYMT) AS PAYMT,
    MAX(RECPT) AS RECPT,
    MAX(ORAMT) AS ORAMT
FROM TA_RN_EXPORT_JC
WHERE EXISTS (
    SELECT 1
    FROM TA_RN_IMPORT_GESTION_JC T
    WHERE T.OPERATIONNETAMOUNT = '22.36'
      AND T.PAYMENTREFERENCE = TA_RN_EXPORT_JC.INTREF
      AND ROWNUM = 1
);

PROMPT

-- Chercher 2817 dans TA_RN_EXPORT_JC
SELECT
    'TA_RN_EXPORT_JC - 2817' AS Table_Transaction,
    COUNT(*) AS NB_LIGNES,
    MAX(PAYMT) AS PAYMT,
    MAX(RECPT) AS RECPT,
    MAX(ORAMT) AS ORAMT
FROM TA_RN_EXPORT_JC
WHERE EXISTS (
    SELECT 1
    FROM TA_RN_IMPORT_GESTION_JC T
    WHERE T.OPERATIONNETAMOUNT = '2817'
      AND T.PAYMENTREFERENCE = TA_RN_EXPORT_JC.INTREF
      AND ROWNUM = 1
);

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 3 : Chercher PAYMENTREFERENCE dans TW_EXPORT_GEST_JC
PROMPT ============================================================================
PROMPT (Table de travail utilisée dans RNADGENJUCGES01.sql ligne 1083)

-- Vérifier si la table existe
SELECT
    'TW_EXPORT_GEST_JC' AS TABLE_NAME,
    NUM_ROWS,
    LAST_ANALYZED
FROM ALL_TABLES
WHERE TABLE_NAME = 'TW_EXPORT_GEST_JC'
  AND OWNER = USER;

PROMPT

-- Si la table existe, chercher les données
-- NOTE: Structure inconnue, adapter si besoin
SELECT
    'TW_EXPORT_GEST_JC - Contenu' AS Info,
    T.*
FROM TW_EXPORT_GEST_JC T
WHERE ROWNUM <= 10;

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 4 : Chercher dans BANKREC.BR_DATA par montant ET référence
PROMPT ============================================================================

-- Chercher 22.36 dans BR_DATA
SELECT
    'BR_DATA - 22.36' AS Table_Transaction,
    COUNT(*) AS NB_LIGNES,
    MAX(ACCT_ID) AS ACCT_ID,
    MAX(AMOUNT) AS AMOUNT,
    MAX(INTL_REF) AS INTL_REF,
    MAX(EXTL_REF) AS EXTL_REF,
    MAX(SUBSTR(NARRATIVE, 1, 50)) AS NARRATIVE_DEBUT
FROM BANKREC.BR_DATA
WHERE AMOUNT IN (22.36, -22.36);

PROMPT

-- Vérifier si INTL_REF ou EXTL_REF correspond au PAYMENTREFERENCE
SELECT
    'BR_DATA - Vérif PAYMENTREFERENCE 22.36' AS Info,
    BD.ACCT_ID,
    BD.AMOUNT,
    BD.INTL_REF,
    BD.EXTL_REF,
    IM.PAYMENTREFERENCE,
    CASE
        WHEN BD.INTL_REF = IM.PAYMENTREFERENCE THEN 'MATCH INTL_REF'
        WHEN BD.EXTL_REF = IM.PAYMENTREFERENCE THEN 'MATCH EXTL_REF'
        ELSE 'PAS DE MATCH'
    END AS CORRESPONDANCE
FROM BANKREC.BR_DATA BD,
     TA_RN_IMPORT_GESTION_JC IM
WHERE BD.AMOUNT IN (22.36, -22.36)
  AND IM.OPERATIONNETAMOUNT = '22.36'
  AND ROWNUM = 1;

PROMPT

-- Chercher 2817 dans BR_DATA
SELECT
    'BR_DATA - 2817' AS Table_Transaction,
    COUNT(*) AS NB_LIGNES
FROM BANKREC.BR_DATA
WHERE AMOUNT IN (2817, -2817);

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 5 : Chercher dans TOUTES les tables avec une colonne AMOUNT
PROMPT ============================================================================

-- Lister toutes les tables ayant une colonne AMOUNT
SELECT
    TABLE_NAME,
    OWNER,
    NUM_ROWS
FROM ALL_TAB_COLUMNS ATC
    JOIN ALL_TABLES AT ON AT.TABLE_NAME = ATC.TABLE_NAME AND AT.OWNER = ATC.OWNER
WHERE ATC.COLUMN_NAME = 'AMOUNT'
  AND ATC.OWNER IN ('BANKREC', 'EXP_RNAPA', USER)
ORDER BY NUM_ROWS DESC NULLS LAST;

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 6 : Recherche dynamique du PAYMENTREFERENCE dans toutes les tables
PROMPT ============================================================================
PROMPT Cette section génère des requêtes SQL à exécuter manuellement

-- Générer des requêtes pour chaque table contenant une colonne texte
-- qui pourrait contenir le PAYMENTREFERENCE

DECLARE
    v_paymentref_22 VARCHAR2(128);
    v_paymentref_2817 VARCHAR2(128);
    v_sql VARCHAR2(4000);
    v_count NUMBER;

BEGIN
    -- Récupérer les PAYMENTREFERENCE
    BEGIN
        SELECT PAYMENTREFERENCE INTO v_paymentref_22
        FROM TA_RN_IMPORT_GESTION_JC
        WHERE OPERATIONNETAMOUNT = '22.36' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_paymentref_22 := NULL;
    END;

    BEGIN
        SELECT PAYMENTREFERENCE INTO v_paymentref_2817
        FROM TA_RN_IMPORT_GESTION_JC
        WHERE OPERATIONNETAMOUNT = '2817' AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_paymentref_2817 := NULL;
    END;

    DBMS_OUTPUT.PUT_LINE('PAYMENTREFERENCE 22.36  : ' || v_paymentref_22);
    DBMS_OUTPUT.PUT_LINE('PAYMENTREFERENCE 2817   : ' || v_paymentref_2817);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('-- Recherche dans les tables candidates:');
    DBMS_OUTPUT.PUT_LINE('');

    -- Chercher dans toutes les tables ayant des colonnes VARCHAR2 susceptibles
    FOR rec IN (
        SELECT DISTINCT TABLE_NAME, OWNER
        FROM ALL_TAB_COLUMNS
        WHERE OWNER IN ('BANKREC', 'EXP_RNAPA', USER)
          AND DATA_TYPE IN ('VARCHAR2', 'CHAR')
          AND TABLE_NAME LIKE '%BR_%' OR TABLE_NAME LIKE '%TA_RN_%'
        ORDER BY TABLE_NAME
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('-- Table: ' || rec.OWNER || '.' || rec.TABLE_NAME);

        -- Pour chaque colonne texte de la table
        FOR col IN (
            SELECT COLUMN_NAME
            FROM ALL_TAB_COLUMNS
            WHERE TABLE_NAME = rec.TABLE_NAME
              AND OWNER = rec.OWNER
              AND DATA_TYPE IN ('VARCHAR2', 'CHAR')
              AND COLUMN_NAME NOT IN ('OWNER', 'CREATED_BY', 'MODIFIED_BY')
            ORDER BY COLUMN_ID
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('SELECT ''' || rec.TABLE_NAME || '.' || col.COLUMN_NAME ||
                               ''' AS SOURCE, COUNT(*) FROM ' || rec.OWNER || '.' || rec.TABLE_NAME ||
                               ' WHERE ' || col.COLUMN_NAME || ' IN (''' || v_paymentref_22 ||
                               ''', ''' || v_paymentref_2817 || ''');');
        END LOOP;
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
END;
/

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 7 : Vérification spécifique des tables du flux d'intégration
PROMPT ============================================================================

-- Tables identifiées dans RNADGENJUCGES01.sql:
-- 1. TA_RN_IMPORT_GESTION_JC (import XML)
-- 2. TA_RN_EXPORT_JC (export vers Accurate)
-- 3. TW_EXPORT_GEST_JC (table de travail)

-- Compter les occurrences dans chaque table
WITH paymentref AS (
    SELECT
        '22.36' AS montant,
        PAYMENTREFERENCE
    FROM TA_RN_IMPORT_GESTION_JC
    WHERE OPERATIONNETAMOUNT = '22.36'
      AND ROWNUM = 1
    UNION ALL
    SELECT
        '2817' AS montant,
        PAYMENTREFERENCE
    FROM TA_RN_IMPORT_GESTION_JC
    WHERE OPERATIONNETAMOUNT = '2817'
      AND ROWNUM = 1
)
SELECT
    PR.montant,
    PR.PAYMENTREFERENCE,
    'TA_RN_IMPORT_GESTION_JC' AS table_name,
    (SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC T
     WHERE T.PAYMENTREFERENCE = PR.PAYMENTREFERENCE) AS nb_lignes
FROM paymentref PR
ORDER BY PR.montant DESC;

PROMPT
PROMPT ============================================================================
PROMPT ÉTAPE 8 : RÉSUMÉ - Comparaison présence dans les tables
PROMPT ============================================================================

-- Créer une vue synthétique de la présence de chaque transaction
SELECT
    'TA_RN_IMPORT_GESTION_JC' AS Table_Name,
    (SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '22.36') AS Transaction_22_36,
    (SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '2817') AS Transaction_2817,
    CASE
        WHEN (SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '22.36') > 0
         AND (SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '2817') > 0
        THEN 'LES DEUX PRÉSENTES'
        WHEN (SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '22.36') > 0
        THEN 'SEULEMENT 22.36'
        WHEN (SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '2817') > 0
        THEN 'SEULEMENT 2817'
        ELSE 'AUCUNE'
    END AS Statut
FROM DUAL

UNION ALL

SELECT
    'TA_RN_EXPORT_JC' AS Table_Name,
    (SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT = '22.36') AS Transaction_22_36,
    (SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT = '2817') AS Transaction_2817,
    CASE
        WHEN (SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT = '22.36') > 0
         AND (SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT = '2817') > 0
        THEN 'LES DEUX PRÉSENTES'
        WHEN (SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT = '22.36') > 0
        THEN 'SEULEMENT 22.36'
        WHEN (SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT = '2817') > 0
        THEN 'SEULEMENT 2817'
        ELSE 'AUCUNE'
    END AS Statut
FROM DUAL

UNION ALL

SELECT
    'BANKREC.BR_DATA' AS Table_Name,
    (SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE AMOUNT IN (22.36, -22.36)) AS Transaction_22_36,
    (SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE AMOUNT IN (2817, -2817)) AS Transaction_2817,
    CASE
        WHEN (SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE AMOUNT IN (22.36, -22.36)) > 0
         AND (SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE AMOUNT IN (2817, -2817)) > 0
        THEN 'LES DEUX PRÉSENTES'
        WHEN (SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE AMOUNT IN (22.36, -22.36)) > 0
        THEN '✅ SEULEMENT 22.36 - PROBLÈME ICI!'
        WHEN (SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE AMOUNT IN (2817, -2817)) > 0
        THEN 'SEULEMENT 2817'
        ELSE 'AUCUNE'
    END AS Statut
FROM DUAL;

PROMPT
PROMPT ============================================================================
PROMPT CONCLUSION
PROMPT ============================================================================
PROMPT Si BR_DATA contient SEULEMENT 22.36, cela signifie que :
PROMPT 1. Le filtrage se fait AVANT l'insertion dans BR_DATA
PROMPT 2. Le critère de filtrage doit être cherché dans :
PROMPT    - La condition WHERE du INSERT INTO BR_DATA
PROMPT    - Le paramétrage de TA_RN_GESTION_JC (compte accurate 394 vs 342)
PROMPT    - Un package PL/SQL qui lit IMPORT et écrit dans BR_DATA
PROMPT
PROMPT Utilisez le PAYMENTREFERENCE pour tracer exactement où 22.36 arrive
PROMPT mais où 2817 est bloqué.
PROMPT ============================================================================
