-- ============================================================
-- CORRECTION PKG_LOG - Buffer ORA-06502
-- Date : 19/02/2026
-- Problème : s_NomObjetAppelant VARCHAR2(25) trop court
-- Solution : Augmenter à VARCHAR2(128)
-- ============================================================

-- ============================================================
-- ETAPE 1 : IDENTIFIER LA LIGNE EXACTE A MODIFIER
-- ============================================================

-- Trouver la ligne avec la variable trop courte
SELECT LINE, TEXT
FROM ALL_SOURCE
WHERE OWNER = 'EXP_RNAPA'
  AND NAME = 'PKG_LOG'
  AND TYPE = 'PACKAGE BODY'
  AND TEXT LIKE '%s_NomObjetAppelant VARCHAR2(25)%';

-- Résultat attendu : une ligne avec le numéro (ex: ligne 795)


-- ============================================================
-- ETAPE 2 : VOIR LE CONTEXTE (10 lignes avant/après)
-- ============================================================

-- Remplacer XXX par le numéro de ligne trouvé à l'étape 1
-- Exemple : si ligne 795, mettre BETWEEN 785 AND 805

SELECT LINE, TEXT
FROM ALL_SOURCE
WHERE OWNER = 'EXP_RNAPA'
  AND NAME = 'PKG_LOG'
  AND TYPE = 'PACKAGE BODY'
  AND LINE BETWEEN 785 AND 810  -- Ajuster selon résultat étape 1
ORDER BY LINE;


-- ============================================================
-- ETAPE 3 : EXTRAIRE LE PACKAGE BODY COMPLET
-- ============================================================

-- Option A : Via SQL*Plus (recommandé)
-- Exécuter en SQL*Plus :
/*
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET HEADING OFF
SET FEEDBACK OFF

SPOOL PKG_LOG_BODY_BACKUP.sql

SELECT TEXT
FROM ALL_SOURCE
WHERE OWNER = 'EXP_RNAPA'
  AND NAME = 'PKG_LOG'
  AND TYPE = 'PACKAGE BODY'
ORDER BY LINE;

SPOOL OFF
*/

-- Option B : Via DBMS_METADATA (plus propre)
SELECT DBMS_METADATA.GET_DDL('PACKAGE_BODY', 'PKG_LOG', 'EXP_RNAPA')
FROM DUAL;


-- ============================================================
-- ETAPE 4 : MODIFICATION A EFFECTUER
-- ============================================================

/*
DANS LA FONCTION F_GET_CONTEXTE (environ ligne 780-800) :

CHERCHER :
---------
    s_NomObjetAppelant VARCHAR2(25):='';

REMPLACER PAR :
---------------
    s_NomObjetAppelant VARCHAR2(128):='';


EXPLICATION :
- La variable reçoit le nom complet de l'objet appelant
- Exemple : 'PKG_RNADEXTAUTO01.F_EXTRAIRE_BAATGS' = 37 caractères
- VARCHAR2(25) est trop court → ORA-06502
- VARCHAR2(128) permet des noms jusqu'à 128 caractères
*/


-- ============================================================
-- ETAPE 5 : RECOMPILER LE PACKAGE (après modification)
-- ============================================================

-- Une fois le code source modifié, exécuter :
-- CREATE OR REPLACE PACKAGE BODY EXP_RNAPA.PKG_LOG AS
-- ... (coller le code modifié)
-- /

-- Puis vérifier la compilation :
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM ALL_OBJECTS
WHERE OWNER = 'EXP_RNAPA'
  AND OBJECT_NAME = 'PKG_LOG';

-- Status doit être VALID


-- ============================================================
-- ETAPE 6 : VERIFICATION POST-CORRECTION
-- ============================================================

-- Vérifier que la modification a été appliquée
SELECT LINE, TEXT
FROM ALL_SOURCE
WHERE OWNER = 'EXP_RNAPA'
  AND NAME = 'PKG_LOG'
  AND TYPE = 'PACKAGE BODY'
  AND TEXT LIKE '%s_NomObjetAppelant VARCHAR2%';

-- Doit afficher : s_NomObjetAppelant VARCHAR2(128)


-- ============================================================
-- RESUME DES ETAPES
-- ============================================================

/*
1. BACKUP : Extraire le code actuel de PKG_LOG (ETAPE 3)
2. TROUVER : Localiser la ligne avec VARCHAR2(25) (ETAPE 1)
3. MODIFIER : Changer VARCHAR2(25) → VARCHAR2(128) dans le fichier
4. DEPLOYER : Exécuter CREATE OR REPLACE PACKAGE BODY (ETAPE 5)
5. VERIFIER : Contrôler le status VALID et la nouvelle taille (ETAPE 6)

ATTENTION :
- Faire un BACKUP avant modification
- Tester en RECETTE avant PRODUCTION
- Cette correction est MINEURE (cosmétique logs)
- Le problème CRITIQUE reste ORA-01555 (UNDO tablespace)
*/
