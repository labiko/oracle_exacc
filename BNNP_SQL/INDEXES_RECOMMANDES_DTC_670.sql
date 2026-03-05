-- ============================================================
-- RECOMMANDATIONS D'INDEX - Requete DTC 670 (BAATGS Gestion)
-- Sql_id : 7prpuy907rpz2
-- Date : 19/02/2026
--
-- OBJECTIF : Ameliorer les performances de la requete BAATGS
-- sans modification du code SQL existant
-- ============================================================

-- ============================================================
-- ETAPE 1 : VERIFICATION DES INDEX EXISTANTS
-- ============================================================
-- Executer ces requetes pour connaitre les index actuels

-- Index sur BR_DATA (table source de BRR_TRANSACTIONS)
SELECT
    i.INDEX_NAME,
    i.UNIQUENESS,
    LISTAGG(c.COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY c.COLUMN_POSITION) AS COLONNES
FROM ALL_INDEXES i
JOIN ALL_IND_COLUMNS c ON c.INDEX_NAME = i.INDEX_NAME AND c.TABLE_OWNER = i.OWNER
WHERE i.TABLE_NAME = 'BR_DATA'
GROUP BY i.INDEX_NAME, i.UNIQUENESS
ORDER BY i.INDEX_NAME;

-- Index sur BS_ACCTS
SELECT
    i.INDEX_NAME,
    i.UNIQUENESS,
    LISTAGG(c.COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY c.COLUMN_POSITION) AS COLONNES
FROM ALL_INDEXES i
JOIN ALL_IND_COLUMNS c ON c.INDEX_NAME = i.INDEX_NAME AND c.TABLE_OWNER = i.OWNER
WHERE i.TABLE_NAME = 'BS_ACCTS'
GROUP BY i.INDEX_NAME, i.UNIQUENESS
ORDER BY i.INDEX_NAME;

-- Index sur BRR_ACCOUNT_HIERARCHIES
SELECT
    i.INDEX_NAME,
    i.UNIQUENESS,
    LISTAGG(c.COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY c.COLUMN_POSITION) AS COLONNES
FROM ALL_INDEXES i
JOIN ALL_IND_COLUMNS c ON c.INDEX_NAME = i.INDEX_NAME AND c.TABLE_OWNER = i.OWNER
WHERE i.TABLE_NAME = 'BRR_ACCOUNT_HIERARCHIES'
GROUP BY i.INDEX_NAME, i.UNIQUENESS
ORDER BY i.INDEX_NAME;

-- Index sur BA_COMPTE_METHODE
SELECT
    i.INDEX_NAME,
    i.UNIQUENESS,
    LISTAGG(c.COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY c.COLUMN_POSITION) AS COLONNES
FROM ALL_INDEXES i
JOIN ALL_IND_COLUMNS c ON c.INDEX_NAME = i.INDEX_NAME AND c.TABLE_OWNER = i.OWNER
WHERE i.TABLE_NAME = 'BA_COMPTE_METHODE'
GROUP BY i.INDEX_NAME, i.UNIQUENESS
ORDER BY i.INDEX_NAME;


-- ============================================================
-- ETAPE 2 : INDEX RECOMMANDES
-- ============================================================
-- IMPORTANT : Verifier que ces index n'existent pas deja
-- avant de les creer (voir resultats ETAPE 1)

-- ------------------------------------------------------------
-- PRIORITE 1 : INDEX CRITIQUES (Impact majeur)
-- ------------------------------------------------------------

-- 1.1 Index composite sur BR_DATA pour le filtre STATE + DATE
-- Justification : La requete filtre sur STATE IN (3,4) et TRANS_DATE <= date_arrete
-- Cet index couvre le WHERE principal de la vue BRR_TRANSACTIONS
CREATE INDEX IDX_BR_DATA_STATE_DATE ON BR_DATA(STATE, TRANS_DATE);

-- 1.2 Index pour la sous-requete DC_MAX (correllee, executee pour chaque ligne RECONCILED)
-- Justification : SELECT MAX(TRANSACTION_DATE) avec GROUP BY REC_GROUP, ACCT_ID
-- C'est LA sous-requete la plus couteuse de la requete
CREATE INDEX IDX_BR_DATA_RECON_REF ON BR_DATA(REC_GROUP, ACCT_ID, TRANS_DATE);

-- 1.3 Index sur BRR_ACCOUNT_HIERARCHIES pour la jointure avec les niveaux
-- Justification : Jointures sur ACCOUNT_ID avec filtres sur LEVEL_02 et LEVEL_03
CREATE INDEX IDX_BRR_HIER_ACCT_LEVELS ON BRR_ACCOUNT_HIERARCHIES(ACCOUNT_ID, LEVEL_02_ACCOUNT_ID, LEVEL_03_ACCOUNT_ID);


-- ------------------------------------------------------------
-- PRIORITE 2 : INDEX IMPORTANTS (Impact significatif)
-- ------------------------------------------------------------

-- 2.1 Index sur BS_ACCTS pour les lookups par ACCT_NUM
-- Justification : Filtre WHERE B2.ACCT_NUM = 'GESTION' et operations RPAD sur B3.ACCT_NUM
CREATE INDEX IDX_BS_ACCTS_NUM ON BS_ACCTS(ACCT_NUM);

-- 2.2 Index sur BS_ACCTS pour les jointures par ACCT_ID
-- Justification : Multiples jointures sur ACCT_ID (hierarchie, groupe, compte principal)
CREATE INDEX IDX_BS_ACCTS_ID_GROUP ON BS_ACCTS(ACCT_ID, ACCT_GROUP);

-- 2.3 Index sur BA_COMPTE_METHODE pour la jointure
-- Justification : JOIN BA_COMPTE_METHODE CM ON CM.ACCOUNT_ID = A.ACCT_ID
CREATE INDEX IDX_BA_COMPTE_METHODE_ACCT ON BA_COMPTE_METHODE(ACCOUNT_ID);


-- ------------------------------------------------------------
-- PRIORITE 3 : INDEX SECONDAIRES (Optimisation fine)
-- ------------------------------------------------------------

-- 3.1 Index sur BA_CATEG_ANCIENNETE pour les jointures sur les bornes
-- Justification : Jointure sur BORNE_INF et BORNE_SUP pour calcul anciennete
CREATE INDEX IDX_BA_CATEG_ANC_BORNES ON BA_CATEG_ANCIENNETE(BORNE_INF, BORNE_SUP);

-- 3.2 Index sur BA_PILIERS_MONTANTS pour les jointures sur les bornes
-- Justification : Jointure sur BORNE_INF et BORNE_SUP pour calcul piliers
CREATE INDEX IDX_BA_PILIERS_BORNES ON BA_PILIERS_MONTANTS(BORNE_INF, BORNE_SUP);

-- 3.3 Index sur BA_METHODE_PROVISION pour les jointures
-- Justification : Jointure sur METHODE + BORNE_INF + BORNE_SUP
CREATE INDEX IDX_BA_METH_PROV_METHODE ON BA_METHODE_PROVISION(METHODE, BORNE_INF, BORNE_SUP);


-- ============================================================
-- ETAPE 3 : STATISTIQUES (A executer apres creation des index)
-- ============================================================
-- Mettre a jour les statistiques pour que l'optimiseur utilise les nouveaux index

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'BR_DATA',
        cascade => TRUE,
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
    );
END;
/

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'BS_ACCTS',
        cascade => TRUE,
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
    );
END;
/

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(
        ownname => USER,
        tabname => 'BRR_ACCOUNT_HIERARCHIES',
        cascade => TRUE,
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
    );
END;
/


-- ============================================================
-- ETAPE 4 : VERIFICATION POST-CREATION
-- ============================================================
-- Re-executer la requete ETAPE 1 pour verifier la creation

-- Verifier que les index sont utilises dans le plan d'execution
EXPLAIN PLAN FOR
SELECT /* sql_id: 7prpuy907rpz2 - TEST INDEX */
    COUNT(*)
FROM BR_DATA
WHERE STATE IN (3, 4)
  AND TRANS_DATE <= TO_DATE('28/02/2026', 'DD/MM/RRRR');

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


-- ============================================================
-- NOTES IMPORTANTES
-- ============================================================
--
-- 1. IMPACT ESPACE DISQUE :
--    - Estimer environ 20-30% de la taille de BR_DATA pour les 3 index Priorite 1
--    - Verifier l'espace disponible avant creation
--
-- 2. IMPACT PERFORMANCE INSERT/UPDATE :
--    - Les index ralentissent legerement les ecritures
--    - A evaluer si BR_DATA est tres sollicitee en ecriture
--
-- 3. ESTIMATION GAIN :
--    - Priorite 1 seule : 40-50% d'amelioration attendue
--    - Priorite 1 + 2   : 50-60% d'amelioration attendue
--    - Toutes priorites : 60-70% d'amelioration attendue
--
-- 4. TEST RECOMMANDE :
--    - Creer les index en RECETTE d'abord
--    - Comparer les temps d'execution avant/apres
--    - Valider en PRODUCTION si gain significatif
--
-- ============================================================
-- FIN DU SCRIPT
-- ============================================================
