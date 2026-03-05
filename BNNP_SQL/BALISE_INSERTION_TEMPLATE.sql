-- ============================================================
-- TEMPLATE INSERTION BALISES PAR COMPTE
-- ============================================================
-- Script de reference pour insertion de balises GEST
-- Compte modele : BBNP85504-EUR (propre, sans doublons)
-- ============================================================
-- Date : 24/02/2026 (MAJ modele)
-- Usage : Copier ce template et remplacer le compte cible
-- ============================================================

-- ============================================================
-- VARIABLES A MODIFIER
-- ============================================================
-- Remplacer 'BBNP_CIBLE' par le numero du compte cible
-- Exemple : BBNP35004-EUR, BBNP95204-EUR, etc.
-- ============================================================

DEFINE COMPTE_CIBLE = 'BBNP_CIBLE-EUR'
DEFINE COMPTE_MODELE = 'BBNP85504-EUR'

-- ============================================================
-- ETAPE 1 : VERIFICATION PRE-INSERTION
-- ============================================================
PROMPT ============================================================
PROMPT VERIFICATION PRE-INSERTION pour &COMPTE_CIBLE
PROMPT ============================================================

-- 1.1 Verifier que le compte cible existe
PROMPT [1/4] Verification existence compte cible...
SELECT
    ID_COMPTE_ACCURATE,
    NUM_COMPTE_ACCURATE,
    NOM,
    FLAG_ACTIF,
    TYPE_RAPPRO
FROM TA_RN_COMPTE_ACCURATE
WHERE NUM_COMPTE_ACCURATE = '&COMPTE_CIBLE';

-- 1.2 Verifier les balises actuelles du compte cible
PROMPT [2/4] Balises actuelles du compte cible...
SELECT
    BPC.ID_COMPTE_ACCURATE,
    CA.NUM_COMPTE_ACCURATE,
    BPC.NUM_COL_FEEDER,
    BPC.ID_BALISE,
    B.NOM_BALISE,
    B.TYPE_BALISE,
    BPC.INDICATEUR_MANUEL_AUTO
FROM TA_RN_BALISE_PAR_COMPTE BPC
JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = BPC.ID_COMPTE_ACCURATE
JOIN TA_RN_BALISE B ON B.ID_BALISE = BPC.ID_BALISE
WHERE CA.NUM_COMPTE_ACCURATE = '&COMPTE_CIBLE'
ORDER BY BPC.NUM_COL_FEEDER;

-- 1.3 Verifier les balises du compte modele (ce qui sera copie)
PROMPT [3/4] Balises du compte modele (a copier)...
SELECT
    BPC.ID_COMPTE_ACCURATE,
    CA.NUM_COMPTE_ACCURATE,
    BPC.NUM_COL_FEEDER,
    BPC.ID_BALISE,
    B.NOM_BALISE,
    B.TYPE_BALISE,
    BPC.INDICATEUR_MANUEL_AUTO
FROM TA_RN_BALISE_PAR_COMPTE BPC
JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = BPC.ID_COMPTE_ACCURATE
JOIN TA_RN_BALISE B ON B.ID_BALISE = BPC.ID_BALISE
WHERE CA.NUM_COMPTE_ACCURATE = '&COMPTE_MODELE'
  AND B.TYPE_BALISE = 'GEST'
ORDER BY BPC.NUM_COL_FEEDER;

-- 1.4 Preview des lignes qui seront inserees
PROMPT [4/4] Preview insertion (lignes a inserer)...
SELECT
    '&COMPTE_CIBLE' AS COMPTE_CIBLE,
    BalRef.NUM_COL_FEEDER,
    BalRef.ID_BALISE,
    B.NOM_BALISE,
    BalRef.INDICATEUR_MANUEL_AUTO
FROM TA_RN_BALISE_PAR_COMPTE BalRef
JOIN TA_RN_BALISE B ON B.ID_BALISE = BalRef.ID_BALISE
LEFT JOIN TA_RN_BALISE_PAR_COMPTE Balise1
    ON Balise1.NUM_COL_FEEDER = BalRef.NUM_COL_FEEDER
    AND Balise1.ID_BALISE = BalRef.ID_BALISE
    AND Balise1.INDICATEUR_MANUEL_AUTO = BalRef.INDICATEUR_MANUEL_AUTO
    AND Balise1.ID_COMPTE_ACCURATE IN (
        SELECT ID_COMPTE_ACCURATE FROM TA_RN_COMPTE_ACCURATE
        WHERE NUM_COMPTE_ACCURATE = '&COMPTE_CIBLE'
    )
WHERE BalRef.ID_COMPTE_ACCURATE IN (
    SELECT ID_COMPTE_ACCURATE FROM TA_RN_COMPTE_ACCURATE
    WHERE NUM_COMPTE_ACCURATE = '&COMPTE_MODELE'
)
AND BalRef.ID_BALISE IN (
    SELECT ID_BALISE FROM TA_RN_BALISE WHERE TYPE_BALISE = 'GEST'
)
AND Balise1.NUM_COL_FEEDER IS NULL
ORDER BY BalRef.NUM_COL_FEEDER;

PROMPT ============================================================
PROMPT Si OK, executer ETAPE 2 (INSERTION)
PROMPT ============================================================

-- ============================================================
-- ETAPE 2 : INSERTION
-- ============================================================
/*
-- DECOMMENTER POUR EXECUTER L'INSERTION

INSERT INTO TA_RN_BALISE_PAR_COMPTE (
    ID_COMPTE_ACCURATE,
    NUM_COL_FEEDER,
    ID_BALISE,
    INDICATEUR_MANUEL_AUTO
)
SELECT
    (SELECT ID_COMPTE_ACCURATE FROM TA_RN_COMPTE_ACCURATE
     WHERE NUM_COMPTE_ACCURATE = '&COMPTE_CIBLE') AS ID_COMPTE_ACCURATE,
    BalRef.NUM_COL_FEEDER,
    BalRef.ID_BALISE,
    BalRef.INDICATEUR_MANUEL_AUTO
FROM TA_RN_BALISE_PAR_COMPTE BalRef
LEFT JOIN TA_RN_BALISE_PAR_COMPTE Balise1
    ON Balise1.NUM_COL_FEEDER = BalRef.NUM_COL_FEEDER
    AND Balise1.ID_BALISE = BalRef.ID_BALISE
    AND Balise1.INDICATEUR_MANUEL_AUTO = BalRef.INDICATEUR_MANUEL_AUTO
    AND Balise1.ID_COMPTE_ACCURATE IN (
        SELECT ID_COMPTE_ACCURATE FROM TA_RN_COMPTE_ACCURATE
        WHERE NUM_COMPTE_ACCURATE = '&COMPTE_CIBLE'
    )
WHERE BalRef.ID_COMPTE_ACCURATE IN (
    SELECT ID_COMPTE_ACCURATE FROM TA_RN_COMPTE_ACCURATE
    WHERE NUM_COMPTE_ACCURATE = '&COMPTE_MODELE'
)
AND BalRef.ID_BALISE IN (
    SELECT ID_BALISE FROM TA_RN_BALISE WHERE TYPE_BALISE = 'GEST'
)
AND Balise1.NUM_COL_FEEDER IS NULL;

COMMIT;

PROMPT Insertion terminee pour &COMPTE_CIBLE
*/

-- ============================================================
-- ETAPE 3 : VERIFICATION POST-INSERTION
-- ============================================================
/*
PROMPT ============================================================
PROMPT VERIFICATION POST-INSERTION pour &COMPTE_CIBLE
PROMPT ============================================================

SELECT
    BPC.ID_COMPTE_ACCURATE,
    CA.NUM_COMPTE_ACCURATE,
    BPC.NUM_COL_FEEDER,
    BPC.ID_BALISE,
    B.NOM_BALISE,
    B.TYPE_BALISE,
    BPC.INDICATEUR_MANUEL_AUTO
FROM TA_RN_BALISE_PAR_COMPTE BPC
JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = BPC.ID_COMPTE_ACCURATE
JOIN TA_RN_BALISE B ON B.ID_BALISE = BPC.ID_BALISE
WHERE CA.NUM_COMPTE_ACCURATE = '&COMPTE_CIBLE'
ORDER BY BPC.NUM_COL_FEEDER;
*/

-- ============================================================
-- ROLLBACK (si necessaire)
-- ============================================================
/*
DELETE FROM TA_RN_BALISE_PAR_COMPTE
WHERE ID_COMPTE_ACCURATE IN (
    SELECT ID_COMPTE_ACCURATE FROM TA_RN_COMPTE_ACCURATE
    WHERE NUM_COMPTE_ACCURATE = '&COMPTE_CIBLE'
)
AND ID_BALISE IN (
    SELECT ID_BALISE FROM TA_RN_BALISE WHERE TYPE_BALISE = 'GEST'
);
COMMIT;
*/
