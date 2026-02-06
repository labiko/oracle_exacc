-- =============================================================================
-- SCRIPT DE MAPPING DIRECTORIES UTL_FILE → OCI OBJECT STORAGE
-- =============================================================================
-- Application: PARNA (08449-parna-p1)
-- Date: [Date d'exécution]
-- DBA: [Nom du DBA]
-- =============================================================================

-- IMPORTANT : Remplacer les variables suivantes avant exécution :
-- [REGION]     : Région OCI (ex: eu-paris-1)
-- [NAMESPACE]  : Namespace Object Storage fourni par l'équipe OCI
-- [SCHEMA]     : Schéma Oracle propriétaire de la table de mapping

-- =============================================================================
-- ÉTAPE 1 : Créer la table de mapping (si pas encore créée)
-- =============================================================================

CREATE TABLE [SCHEMA].UTL_FILE_DIRECTORY_MAPPING (
    directory_name   VARCHAR2(128) PRIMARY KEY,
    object_uri       VARCHAR2(1000) NOT NULL,
    credential_name  VARCHAR2(128) DEFAULT 'OCI_CREDENTIAL',
    created_date     DATE DEFAULT SYSDATE,
    comments         VARCHAR2(500)
);

COMMENT ON TABLE [SCHEMA].UTL_FILE_DIRECTORY_MAPPING IS 'Mapping entre directories Oracle UTL_FILE et Object Storage OCI';
COMMENT ON COLUMN [SCHEMA].UTL_FILE_DIRECTORY_MAPPING.directory_name IS 'Nom du directory Oracle (ex: DIR_ARCH_RNA)';
COMMENT ON COLUMN [SCHEMA].UTL_FILE_DIRECTORY_MAPPING.object_uri IS 'URI complet Object Storage OCI';
COMMENT ON COLUMN [SCHEMA].UTL_FILE_DIRECTORY_MAPPING.credential_name IS 'Nom du credential DBMS_CLOUD à utiliser';

-- =============================================================================
-- ÉTAPE 2 : Insérer les 6 mappings identifiés lors de l'audit
-- =============================================================================

-- Mapping 1/6 : DIR_ARCH_RNA
INSERT INTO [SCHEMA].UTL_FILE_DIRECTORY_MAPPING
    (directory_name, object_uri, credential_name, comments)
VALUES (
    'DIR_ARCH_RNA',
    'https://objectstorage.[REGION].oraclecloud.com/n/[NAMESPACE]/b/parna-exacc-files/o/archive/',
    'OCI_CREDENTIAL',
    'Répertoire archive - /applis/08449-parna-p1/archive'
);

-- Mapping 2/6 : DIR_IN_RNA
INSERT INTO [SCHEMA].UTL_FILE_DIRECTORY_MAPPING
    (directory_name, object_uri, credential_name, comments)
VALUES (
    'DIR_IN_RNA',
    'https://objectstorage.[REGION].oraclecloud.com/n/[NAMESPACE]/b/parna-exacc-files/o/in/',
    'OCI_CREDENTIAL',
    'Répertoire entrant - /applis/08449-parna-p1/in'
);

-- Mapping 3/6 : DIR_LOG_RNA
INSERT INTO [SCHEMA].UTL_FILE_DIRECTORY_MAPPING
    (directory_name, object_uri, credential_name, comments)
VALUES (
    'DIR_LOG_RNA',
    'https://objectstorage.[REGION].oraclecloud.com/n/[NAMESPACE]/b/parna-exacc-files/o/logs/',
    'OCI_CREDENTIAL',
    'Répertoire logs - /applis/logs/08449-parna-p1'
);

-- Mapping 4/6 : DIR_OUT_RNA
INSERT INTO [SCHEMA].UTL_FILE_DIRECTORY_MAPPING
    (directory_name, object_uri, credential_name, comments)
VALUES (
    'DIR_OUT_RNA',
    'https://objectstorage.[REGION].oraclecloud.com/n/[NAMESPACE]/b/parna-exacc-files/o/out/',
    'OCI_CREDENTIAL',
    'Répertoire sortant - /applis/08449-parna-p1/out'
);

-- Mapping 5/6 : DIR_TEMP_RNA
INSERT INTO [SCHEMA].UTL_FILE_DIRECTORY_MAPPING
    (directory_name, object_uri, credential_name, comments)
VALUES (
    'DIR_TEMP_RNA',
    'https://objectstorage.[REGION].oraclecloud.com/n/[NAMESPACE]/b/parna-exacc-files/o/temp/',
    'OCI_CREDENTIAL',
    'Répertoire temporaire - /applis/08449-parna-p1/temp'
);

-- Mapping 6/6 : IN_APPLI_DIR
INSERT INTO [SCHEMA].UTL_FILE_DIRECTORY_MAPPING
    (directory_name, object_uri, credential_name, comments)
VALUES (
    'IN_APPLI_DIR',
    'https://objectstorage.[REGION].oraclecloud.com/n/[NAMESPACE]/b/parna-exacc-files/o/in/',
    'OCI_CREDENTIAL',
    'Répertoire entrant application - /applis/08449-parna-p1/in/'
);

COMMIT;

-- =============================================================================
-- ÉTAPE 3 : Vérifier les mappings insérés
-- =============================================================================

SELECT
    directory_name AS "Directory Oracle",
    object_uri AS "URI Object Storage",
    credential_name AS "Credential",
    TO_CHAR(created_date, 'DD/MM/YYYY HH24:MI:SS') AS "Date création",
    comments AS "Commentaire"
FROM [SCHEMA].UTL_FILE_DIRECTORY_MAPPING
ORDER BY directory_name;

-- =============================================================================
-- RÉSULTAT ATTENDU : 6 lignes
-- =============================================================================
-- DIR_ARCH_RNA   | https://objectstorage.[REGION]... | OCI_CREDENTIAL | ...
-- DIR_IN_RNA     | https://objectstorage.[REGION]... | OCI_CREDENTIAL | ...
-- DIR_LOG_RNA    | https://objectstorage.[REGION]... | OCI_CREDENTIAL | ...
-- DIR_OUT_RNA    | https://objectstorage.[REGION]... | OCI_CREDENTIAL | ...
-- DIR_TEMP_RNA   | https://objectstorage.[REGION]... | OCI_CREDENTIAL | ...
-- IN_APPLI_DIR   | https://objectstorage.[REGION]... | OCI_CREDENTIAL | ...
-- =============================================================================

-- =============================================================================
-- ÉTAPE 4 : Créer un synonyme public (optionnel, pour faciliter l'accès)
-- =============================================================================

CREATE PUBLIC SYNONYM UTL_FILE_DIRECTORY_MAPPING FOR [SCHEMA].UTL_FILE_DIRECTORY_MAPPING;

-- =============================================================================
-- FIN DU SCRIPT
-- =============================================================================
