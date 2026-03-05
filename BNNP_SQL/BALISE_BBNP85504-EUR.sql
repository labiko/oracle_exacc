-- ============================================================
-- COMPTE MODELE DE REFERENCE : BBNP85504-EUR
-- ============================================================
-- Date : 24/02/2026
-- Statut : MODELE PROPRE (24 balises GEST, sans doublons)
-- Remplace : BBNP40692-EUR (qui contenait des doublons)
-- ============================================================
-- Ce compte sert de reference pour copier les balises GEST
-- vers les autres comptes ACCURATE.
-- ============================================================

SET SERVEROUTPUT ON

-- VERIFICATION : Le compte modele existe ?
SELECT ID_COMPTE_ACCURATE, NUM_COMPTE_ACCURATE, NOM FROM TA_RN_COMPTE_ACCURATE
WHERE NUM_COMPTE_ACCURATE = 'BBNP85504-EUR';

-- VERIFICATION : 24 balises GEST (pas de doublons)
SELECT CA.NUM_COMPTE_ACCURATE, COUNT(*) AS NB_BALISES_GEST
FROM TA_RN_BALISE_PAR_COMPTE BPC
JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = BPC.ID_COMPTE_ACCURATE
JOIN TA_RN_BALISE B ON B.ID_BALISE = BPC.ID_BALISE
WHERE CA.NUM_COMPTE_ACCURATE = 'BBNP85504-EUR' AND B.TYPE_BALISE = 'GEST'
GROUP BY CA.NUM_COMPTE_ACCURATE;

-- LISTE COMPLETE des 24 balises GEST du modele
SELECT CA.NUM_COMPTE_ACCURATE, BPC.NUM_COL_FEEDER, B.NOM_BALISE, BPC.INDICATEUR_MANUEL_AUTO
FROM TA_RN_BALISE_PAR_COMPTE BPC
JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = BPC.ID_COMPTE_ACCURATE
JOIN TA_RN_BALISE B ON B.ID_BALISE = BPC.ID_BALISE
WHERE CA.NUM_COMPTE_ACCURATE = 'BBNP85504-EUR' AND B.TYPE_BALISE = 'GEST'
ORDER BY BPC.NUM_COL_FEEDER;

-- VERIFICATION : Pas de doublons (doit retourner 0 ligne)
SELECT B.NOM_BALISE, COUNT(*) AS NB_OCCURRENCES
FROM TA_RN_BALISE_PAR_COMPTE BPC
JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = BPC.ID_COMPTE_ACCURATE
JOIN TA_RN_BALISE B ON B.ID_BALISE = BPC.ID_BALISE
WHERE CA.NUM_COMPTE_ACCURATE = 'BBNP85504-EUR' AND B.TYPE_BALISE = 'GEST'
GROUP BY B.NOM_BALISE
HAVING COUNT(*) > 1;

-- ============================================================
-- NOTE : Pour copier ces balises vers un autre compte, utiliser :
-- BALISE_INSERTION_TEMPLATE.sql
-- ============================================================

