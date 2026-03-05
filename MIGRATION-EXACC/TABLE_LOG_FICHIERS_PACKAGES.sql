-- ============================================================
-- TABLE DE LOGS POUR LES PACKAGES UTL_FILE
-- Migration ExaCC - PARNA
-- Date : 25/02/2026
-- ============================================================
-- OBJECTIF : Tracer les fichiers manipules par les packages :
--   - PKG_TEC_FICHIERS (F_ECRIRECSV_CLOB_SILENTLY, F_GET_DIR, etc.)
--   - PKG_DTC
--   - PKG_LOG
--   - PKG_BR_PURGE
--   - PKG_BR_RECONCILIATION_SIGNOFF
-- ============================================================
-- NOTE : Ce script est IDEMPOTENT (peut etre execute plusieurs fois)
-- ============================================================

-- ============================================================
-- 0. DROP DES OBJETS EXISTANTS (si existent)
-- ============================================================

-- Drop des vues
BEGIN EXECUTE IMMEDIATE 'DROP VIEW V_LOG_FICHIERS_RESUME'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW V_LOG_FICHIERS_PAR_DIRECTORY'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW V_LOG_FICHIERS_RECENT'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW V_LOG_FICHIERS_ERREURS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW V_LOG_MAPPING_DIRECTORIES'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW V_LOG_FICHIERS_SERVEUR'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW V_LOG_FICHIERS_PAR_SERVEUR'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Drop des procedures
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE SP_LOG_FICHIER'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP PROCEDURE SP_PURGE_LOG_FICHIERS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Drop de la table (ATTENTION: supprime les donnees!)
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TA_LOG_FICHIERS_UTL PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- 1. TABLE DE LOGS
-- ============================================================
CREATE TABLE TA_LOG_FICHIERS_UTL (
    ID_LOG              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Contexte appelant
    SCHEMA_NAME         VARCHAR2(128),              -- EXP_RNAPA, BANKREC
    PACKAGE_NAME        VARCHAR2(128) NOT NULL,     -- PKG_TEC_FICHIERS, PKG_DTC, etc.
    FUNCTION_NAME       VARCHAR2(128) NOT NULL,     -- F_ECRIRECSV_CLOB_SILENTLY, F_GET_DIR, etc.

    -- Informations fichier
    DIRECTORY_LOGIQUE   VARCHAR2(128),              -- Nom logique : OUT_APPLI, IN_APPLI, etc.
    DIRECTORY_ORACLE    VARCHAR2(128),              -- Directory Oracle : DIR_OUT_RNA, DIR_IN_RNA, etc.
    DIRECTORY_PATH      VARCHAR2(4000),             -- Chemin physique : /applis/08449-parna-p1/out
    FILE_NAME           VARCHAR2(500),              -- Nom du fichier
    FILE_MODE           VARCHAR2(10),               -- R=Read, W=Write, A=Append

    -- Donnees traitees (optionnel - pour debug)
    CONTENU_APERCU      VARCHAR2(4000),             -- Apercu des premieres lignes (truncated)
    NB_LIGNES           NUMBER,                     -- Nombre de lignes lues/ecrites
    TAILLE_OCTETS       NUMBER,                     -- Taille du fichier/CLOB

    -- Parametres specifiques PKG_TEC_FICHIERS
    ID_CLOB             NUMBER,                     -- ID dans TA_CLOB (si applicable)
    NOM_PARAM           VARCHAR2(255),              -- Parametre passe a la fonction

    -- Statut
    STATUT              VARCHAR2(20) DEFAULT 'OK',  -- OK, ERROR, WARNING
    MESSAGE_ERREUR      VARCHAR2(4000),             -- Message d'erreur si echec

    -- Audit
    SESSION_USER        VARCHAR2(128) DEFAULT SYS_CONTEXT('USERENV', 'SESSION_USER'),
    MODULE              VARCHAR2(128) DEFAULT SYS_CONTEXT('USERENV', 'MODULE'),
    DATE_OPERATION      TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,

    -- Informations Serveur (NOUVEAU)
    DB_NAME             VARCHAR2(128),              -- Nom de la base de donnees
    INSTANCE_NAME       VARCHAR2(128),              -- Nom de l'instance Oracle
    HOST_NAME           VARCHAR2(128),              -- Hostname du serveur
    SERVICE_NAME        VARCHAR2(128),              -- Service Oracle utilise
    OS_USER             VARCHAR2(128),              -- User OS qui a lance le process
    IP_ADDRESS          VARCHAR2(50),               -- Adresse IP du client
    TERMINAL            VARCHAR2(128),              -- Terminal du client
    SID                 NUMBER,                     -- Session ID Oracle
    SERIAL#             NUMBER                      -- Serial# de la session
);

-- Index
CREATE INDEX IDX_LOG_FICHIERS_DATE ON TA_LOG_FICHIERS_UTL(DATE_OPERATION);
CREATE INDEX IDX_LOG_FICHIERS_PKG ON TA_LOG_FICHIERS_UTL(PACKAGE_NAME);
CREATE INDEX IDX_LOG_FICHIERS_FUNC ON TA_LOG_FICHIERS_UTL(FUNCTION_NAME);
CREATE INDEX IDX_LOG_FICHIERS_FILE ON TA_LOG_FICHIERS_UTL(FILE_NAME);
CREATE INDEX IDX_LOG_FICHIERS_DIR ON TA_LOG_FICHIERS_UTL(DIRECTORY_ORACLE);

-- Commentaires
COMMENT ON TABLE TA_LOG_FICHIERS_UTL IS 'Logs des operations fichiers des packages UTL_FILE - Migration ExaCC';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.DIRECTORY_LOGIQUE IS 'Nom logique passe aux fonctions : OUT_APPLI, IN_APPLI, TEMP_APPLI, LOG_APPLI, ARCH_APPLI';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.DIRECTORY_ORACLE IS 'Directory Oracle resolu : DIR_OUT_RNA, DIR_IN_RNA, DIR_TEMP_RNA, DIR_LOG_RNA, DIR_ARCH_RNA';

-- ============================================================
-- 2. PROCEDURE DE LOG (AUTONOMOUS - ne bloque pas le traitement)
-- ============================================================
CREATE OR REPLACE PROCEDURE SP_LOG_FICHIER (
    p_schema_name       IN VARCHAR2 DEFAULT NULL,
    p_package_name      IN VARCHAR2,
    p_function_name     IN VARCHAR2,
    p_directory_logique IN VARCHAR2 DEFAULT NULL,
    p_directory_oracle  IN VARCHAR2 DEFAULT NULL,
    p_file_name         IN VARCHAR2 DEFAULT NULL,
    p_file_mode         IN VARCHAR2 DEFAULT NULL,
    p_contenu_apercu    IN VARCHAR2 DEFAULT NULL,
    p_nb_lignes         IN NUMBER   DEFAULT NULL,
    p_taille_octets     IN NUMBER   DEFAULT NULL,
    p_id_clob           IN NUMBER   DEFAULT NULL,
    p_nom_param         IN VARCHAR2 DEFAULT NULL,
    p_statut            IN VARCHAR2 DEFAULT 'OK',
    p_message_erreur    IN VARCHAR2 DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_directory_path VARCHAR2(4000);
    v_db_name        VARCHAR2(128);
    v_sid            NUMBER;
    v_serial         NUMBER;
BEGIN
    -- Recuperer le chemin physique si directory_oracle fourni
    IF p_directory_oracle IS NOT NULL THEN
        BEGIN
            SELECT directory_path INTO v_directory_path
            FROM all_directories
            WHERE directory_name = UPPER(p_directory_oracle);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_directory_path := '[DIRECTORY NON TROUVE]';
        END;
    END IF;

    -- Recuperer le nom de la base de donnees
    BEGIN
        SELECT name INTO v_db_name FROM v$database;
    EXCEPTION
        WHEN OTHERS THEN
            v_db_name := SYS_CONTEXT('USERENV', 'DB_NAME');
    END;

    -- Recuperer SID et SERIAL# de la session courante
    BEGIN
        SELECT sid, serial# INTO v_sid, v_serial
        FROM v$session
        WHERE audsid = SYS_CONTEXT('USERENV', 'SESSIONID');
    EXCEPTION
        WHEN OTHERS THEN
            v_sid := NULL;
            v_serial := NULL;
    END;

    INSERT INTO TA_LOG_FICHIERS_UTL (
        SCHEMA_NAME,
        PACKAGE_NAME,
        FUNCTION_NAME,
        DIRECTORY_LOGIQUE,
        DIRECTORY_ORACLE,
        DIRECTORY_PATH,
        FILE_NAME,
        FILE_MODE,
        CONTENU_APERCU,
        NB_LIGNES,
        TAILLE_OCTETS,
        ID_CLOB,
        NOM_PARAM,
        STATUT,
        MESSAGE_ERREUR,
        -- Informations Serveur
        DB_NAME,
        INSTANCE_NAME,
        HOST_NAME,
        SERVICE_NAME,
        OS_USER,
        IP_ADDRESS,
        TERMINAL,
        SID,
        SERIAL#
    ) VALUES (
        NVL(p_schema_name, SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA')),
        UPPER(p_package_name),
        UPPER(p_function_name),
        UPPER(p_directory_logique),
        UPPER(p_directory_oracle),
        v_directory_path,
        p_file_name,
        UPPER(p_file_mode),
        SUBSTR(p_contenu_apercu, 1, 4000),
        p_nb_lignes,
        p_taille_octets,
        p_id_clob,
        p_nom_param,
        UPPER(p_statut),
        SUBSTR(p_message_erreur, 1, 4000),
        -- Informations Serveur (capture automatique)
        v_db_name,
        SYS_CONTEXT('USERENV', 'INSTANCE_NAME'),
        SYS_CONTEXT('USERENV', 'SERVER_HOST'),
        SYS_CONTEXT('USERENV', 'SERVICE_NAME'),
        SYS_CONTEXT('USERENV', 'OS_USER'),
        SYS_CONTEXT('USERENV', 'IP_ADDRESS'),
        SYS_CONTEXT('USERENV', 'TERMINAL'),
        v_sid,
        v_serial
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Ne jamais bloquer le traitement principal
        ROLLBACK;
END SP_LOG_FICHIER;
/

-- ============================================================
-- 3. EXEMPLES D'INTEGRATION DANS LES PACKAGES
-- ============================================================

/*
================================================================================
EXEMPLE 1 : PKG_TEC_FICHIERS.F_GET_DIR
--------------------------------------------------------------------------------
Cette fonction traduit les noms logiques (OUT_APPLI) en directories Oracle (DIR_OUT_RNA)

AVANT (code actuel) :
    FUNCTION F_GET_DIR(s_Dir IN VARCHAR2) RETURN VARCHAR2 IS
        s_CodeAppli VARCHAR2(10);
        s_DirComplet VARCHAR2(100);
    BEGIN
        s_CodeAppli := PKG_TEC_GLOBAL.s_CODE_APPLI;
        CASE s_Dir
            WHEN 'OUT_APPLI'  THEN s_DirComplet := 'DIR_OUT_'  || s_CodeAppli;
            WHEN 'IN_APPLI'   THEN s_DirComplet := 'DIR_IN_'   || s_CodeAppli;
            WHEN 'TEMP_APPLI' THEN s_DirComplet := 'DIR_TEMP_' || s_CodeAppli;
            WHEN 'LOG_APPLI'  THEN s_DirComplet := 'DIR_LOG_'  || s_CodeAppli;
            WHEN 'ARCH_APPLI' THEN s_DirComplet := 'DIR_ARCH_' || s_CodeAppli;
        END CASE;
        RETURN s_DirComplet;
    END F_GET_DIR;

APRES (avec log) :
    FUNCTION F_GET_DIR(s_Dir IN VARCHAR2) RETURN VARCHAR2 IS
        s_CodeAppli VARCHAR2(10);
        s_DirComplet VARCHAR2(100);
    BEGIN
        s_CodeAppli := PKG_TEC_GLOBAL.s_CODE_APPLI;
        CASE s_Dir
            WHEN 'OUT_APPLI'  THEN s_DirComplet := 'DIR_OUT_'  || s_CodeAppli;
            WHEN 'IN_APPLI'   THEN s_DirComplet := 'DIR_IN_'   || s_CodeAppli;
            WHEN 'TEMP_APPLI' THEN s_DirComplet := 'DIR_TEMP_' || s_CodeAppli;
            WHEN 'LOG_APPLI'  THEN s_DirComplet := 'DIR_LOG_'  || s_CodeAppli;
            WHEN 'ARCH_APPLI' THEN s_DirComplet := 'DIR_ARCH_' || s_CodeAppli;
        END CASE;

        -- *** LOG AJOUTE ***
        SP_LOG_FICHIER(
            p_package_name      => 'PKG_TEC_FICHIERS',
            p_function_name     => 'F_GET_DIR',
            p_directory_logique => s_Dir,
            p_directory_oracle  => s_DirComplet
        );

        RETURN s_DirComplet;
    END F_GET_DIR;

================================================================================
EXEMPLE 2 : PKG_TEC_FICHIERS.F_ECRIRECSV_CLOB_SILENTLY
--------------------------------------------------------------------------------
Cette fonction ecrit un CLOB dans un fichier via UTL_FILE

AJOUTER AU DEBUT DE LA FONCTION :
    -- *** LOG DEBUT ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_ECRIRECSV_CLOB_SILENTLY',
        p_directory_oracle  => p_directory,
        p_file_name         => p_filename,
        p_file_mode         => 'W',
        p_id_clob           => p_id_clob,
        p_nom_param         => p_nom_param,
        p_taille_octets     => DBMS_LOB.GETLENGTH(p_clob_content),
        p_statut            => 'DEBUT'
    );

AJOUTER A LA FIN (succes) :
    -- *** LOG FIN ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_ECRIRECSV_CLOB_SILENTLY',
        p_directory_oracle  => p_directory,
        p_file_name         => p_filename,
        p_file_mode         => 'W',
        p_nb_lignes         => v_nb_lignes,
        p_taille_octets     => DBMS_LOB.GETLENGTH(p_clob_content),
        p_statut            => 'OK'
    );

AJOUTER DANS LE BLOC EXCEPTION :
    -- *** LOG ERREUR ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_ECRIRECSV_CLOB_SILENTLY',
        p_directory_oracle  => p_directory,
        p_file_name         => p_filename,
        p_statut            => 'ERROR',
        p_message_erreur    => SQLERRM
    );

================================================================================
EXEMPLE 3 : PKG_DTC - Lecture de fichier
--------------------------------------------------------------------------------

AJOUTER APRES UTL_FILE.GET_LINE :
    UTL_FILE.GET_LINE(v_file_handle, v_line);
    v_nb_lignes := v_nb_lignes + 1;

    -- *** LOG APERCU (uniquement premiere ligne) ***
    IF v_nb_lignes = 1 THEN
        SP_LOG_FICHIER(
            p_package_name      => 'PKG_DTC',
            p_function_name     => 'PROCEDURE_LECTURE',
            p_directory_oracle  => v_directory,
            p_file_name         => v_filename,
            p_file_mode         => 'R',
            p_contenu_apercu    => SUBSTR(v_line, 1, 500),
            p_statut            => 'LECTURE'
        );
    END IF;

================================================================================
EXEMPLE 4 : PKG_LOG - Ecriture de logs
--------------------------------------------------------------------------------

AJOUTER APRES UTL_FILE.PUT_LINE :
    UTL_FILE.PUT_LINE(v_file_handle, p_message);

    -- *** LOG ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_LOG',
        p_function_name     => 'WRITE_LOG',
        p_directory_oracle  => 'DIR_LOG_RNA',
        p_file_name         => v_log_filename,
        p_file_mode         => 'A',
        p_contenu_apercu    => SUBSTR(p_message, 1, 500)
    );
*/

-- ============================================================
-- 4. VUES D'ANALYSE
-- ============================================================

-- Vue : Resume par package/fonction
CREATE OR REPLACE VIEW V_LOG_FICHIERS_RESUME AS
SELECT
    PACKAGE_NAME,
    FUNCTION_NAME,
    COUNT(*) AS NB_APPELS,
    COUNT(DISTINCT FILE_NAME) AS NB_FICHIERS,
    COUNT(DISTINCT DIRECTORY_ORACLE) AS NB_DIRECTORIES,
    SUM(CASE WHEN STATUT = 'ERROR' THEN 1 ELSE 0 END) AS NB_ERREURS,
    MIN(DATE_OPERATION) AS PREMIER_APPEL,
    MAX(DATE_OPERATION) AS DERNIER_APPEL
FROM TA_LOG_FICHIERS_UTL
GROUP BY PACKAGE_NAME, FUNCTION_NAME
ORDER BY NB_APPELS DESC;

-- Vue : Fichiers par directory
CREATE OR REPLACE VIEW V_LOG_FICHIERS_PAR_DIRECTORY AS
SELECT
    DIRECTORY_LOGIQUE,
    DIRECTORY_ORACLE,
    DIRECTORY_PATH,
    COUNT(DISTINCT FILE_NAME) AS NB_FICHIERS,
    COUNT(*) AS NB_OPERATIONS,
    SUM(NVL(TAILLE_OCTETS, 0)) AS TOTAL_OCTETS,
    LISTAGG(DISTINCT FILE_NAME, ', ') WITHIN GROUP (ORDER BY FILE_NAME) AS LISTE_FICHIERS
FROM TA_LOG_FICHIERS_UTL
WHERE FILE_NAME IS NOT NULL
GROUP BY DIRECTORY_LOGIQUE, DIRECTORY_ORACLE, DIRECTORY_PATH
ORDER BY NB_OPERATIONS DESC;

-- Vue : Derniers fichiers traites (avec infos serveur)
CREATE OR REPLACE VIEW V_LOG_FICHIERS_RECENT AS
SELECT
    DATE_OPERATION,
    PACKAGE_NAME,
    FUNCTION_NAME,
    DIRECTORY_ORACLE,
    FILE_NAME,
    FILE_MODE,
    NB_LIGNES,
    TAILLE_OCTETS,
    STATUT,
    MESSAGE_ERREUR,
    -- Infos serveur
    DB_NAME,
    HOST_NAME,
    INSTANCE_NAME,
    SERVICE_NAME,
    OS_USER,
    SID,
    SERIAL#
FROM TA_LOG_FICHIERS_UTL
ORDER BY DATE_OPERATION DESC
FETCH FIRST 100 ROWS ONLY;

-- Vue : Erreurs
CREATE OR REPLACE VIEW V_LOG_FICHIERS_ERREURS AS
SELECT
    DATE_OPERATION,
    PACKAGE_NAME,
    FUNCTION_NAME,
    DIRECTORY_ORACLE,
    FILE_NAME,
    MESSAGE_ERREUR,
    SESSION_USER,
    MODULE
FROM TA_LOG_FICHIERS_UTL
WHERE STATUT = 'ERROR'
ORDER BY DATE_OPERATION DESC;

-- Vue : Mapping directories utilises
CREATE OR REPLACE VIEW V_LOG_MAPPING_DIRECTORIES AS
SELECT DISTINCT
    DIRECTORY_LOGIQUE,
    DIRECTORY_ORACLE,
    DIRECTORY_PATH,
    COUNT(*) AS NB_UTILISATIONS
FROM TA_LOG_FICHIERS_UTL
WHERE DIRECTORY_ORACLE IS NOT NULL
GROUP BY DIRECTORY_LOGIQUE, DIRECTORY_ORACLE, DIRECTORY_PATH
ORDER BY NB_UTILISATIONS DESC;

-- Vue : Informations serveur et contexte (NOUVEAU)
CREATE OR REPLACE VIEW V_LOG_FICHIERS_SERVEUR AS
SELECT
    DATE_OPERATION,
    DB_NAME,
    INSTANCE_NAME,
    HOST_NAME,
    SERVICE_NAME,
    SCHEMA_NAME,
    SESSION_USER,
    OS_USER,
    IP_ADDRESS,
    TERMINAL,
    SID,
    SERIAL#,
    MODULE,
    PACKAGE_NAME,
    FUNCTION_NAME,
    FILE_NAME,
    STATUT
FROM TA_LOG_FICHIERS_UTL
ORDER BY DATE_OPERATION DESC;

-- Vue : Resume par serveur/instance
CREATE OR REPLACE VIEW V_LOG_FICHIERS_PAR_SERVEUR AS
SELECT
    DB_NAME,
    INSTANCE_NAME,
    HOST_NAME,
    COUNT(*) AS NB_OPERATIONS,
    COUNT(DISTINCT FILE_NAME) AS NB_FICHIERS,
    COUNT(DISTINCT SESSION_USER) AS NB_USERS,
    SUM(CASE WHEN STATUT = 'ERROR' THEN 1 ELSE 0 END) AS NB_ERREURS,
    MIN(DATE_OPERATION) AS PREMIERE_OP,
    MAX(DATE_OPERATION) AS DERNIERE_OP
FROM TA_LOG_FICHIERS_UTL
GROUP BY DB_NAME, INSTANCE_NAME, HOST_NAME
ORDER BY NB_OPERATIONS DESC;

-- ============================================================
-- 5. PURGE
-- ============================================================
CREATE OR REPLACE PROCEDURE SP_PURGE_LOG_FICHIERS (
    p_retention_jours IN NUMBER DEFAULT 30
) IS
    v_nb_supprimes NUMBER;
BEGIN
    DELETE FROM TA_LOG_FICHIERS_UTL
    WHERE DATE_OPERATION < SYSTIMESTAMP - p_retention_jours;

    v_nb_supprimes := SQL%ROWCOUNT;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Purge terminee : ' || v_nb_supprimes || ' lignes supprimees');
END SP_PURGE_LOG_FICHIERS;
/

-- ============================================================
-- 6. SCRIPT ALTER TABLE (si table existe deja)
-- ============================================================
/*
-- Executer ces commandes si la table TA_LOG_FICHIERS_UTL existe deja :

ALTER TABLE TA_LOG_FICHIERS_UTL ADD (
    DB_NAME             VARCHAR2(128),
    INSTANCE_NAME       VARCHAR2(128),
    HOST_NAME           VARCHAR2(128),
    SERVICE_NAME        VARCHAR2(128),
    OS_USER             VARCHAR2(128),
    IP_ADDRESS          VARCHAR2(50),
    TERMINAL            VARCHAR2(128),
    SID                 NUMBER,
    SERIAL#             NUMBER
);

COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.DB_NAME IS 'Nom de la base de donnees Oracle';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.INSTANCE_NAME IS 'Nom de l instance Oracle';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.HOST_NAME IS 'Hostname du serveur de base de donnees';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.SERVICE_NAME IS 'Service Oracle utilise pour la connexion';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.OS_USER IS 'Utilisateur OS qui a lance le processus';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.IP_ADDRESS IS 'Adresse IP du client';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.TERMINAL IS 'Identifiant du terminal client';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.SID IS 'Session ID Oracle';
COMMENT ON COLUMN TA_LOG_FICHIERS_UTL.SERIAL# IS 'Serial number de la session Oracle';

-- Index optionnel sur HOST_NAME
CREATE INDEX IDX_LOG_FICHIERS_HOST ON TA_LOG_FICHIERS_UTL(HOST_NAME);
*/

-- ============================================================
-- 8. GRANTS (adapter selon schemas)
-- ============================================================
-- GRANT INSERT, SELECT ON TA_LOG_FICHIERS_UTL TO EXP_RNAPA;
-- GRANT INSERT, SELECT ON TA_LOG_FICHIERS_UTL TO BANKREC;
-- GRANT EXECUTE ON SP_LOG_FICHIER TO EXP_RNAPA;
-- GRANT EXECUTE ON SP_LOG_FICHIER TO BANKREC;
-- Pour acceder v$database et v$session :
-- GRANT SELECT ON v_$database TO EXP_RNAPA;
-- GRANT SELECT ON v_$session TO EXP_RNAPA;

-- ============================================================
-- 9. REQUETES D'ANALYSE UTILES
-- ============================================================
/*

-- Quels fichiers sont manipules par PKG_TEC_FICHIERS ?
SELECT DISTINCT FILE_NAME, DIRECTORY_ORACLE, FILE_MODE, COUNT(*) AS NB_FOIS
FROM TA_LOG_FICHIERS_UTL
WHERE PACKAGE_NAME = 'PKG_TEC_FICHIERS'
GROUP BY FILE_NAME, DIRECTORY_ORACLE, FILE_MODE
ORDER BY NB_FOIS DESC;

-- Quelles fonctions utilisent OUT_APPLI ?
SELECT PACKAGE_NAME, FUNCTION_NAME, COUNT(*)
FROM TA_LOG_FICHIERS_UTL
WHERE DIRECTORY_LOGIQUE = 'OUT_APPLI'
GROUP BY PACKAGE_NAME, FUNCTION_NAME;

-- Taille totale des fichiers ecrits par directory
SELECT DIRECTORY_ORACLE, SUM(TAILLE_OCTETS)/1024/1024 AS TAILLE_MB
FROM TA_LOG_FICHIERS_UTL
WHERE FILE_MODE = 'W'
GROUP BY DIRECTORY_ORACLE;

-- Activite par jour
SELECT TRUNC(DATE_OPERATION) AS JOUR,
       PACKAGE_NAME,
       COUNT(*) AS NB_OPERATIONS
FROM TA_LOG_FICHIERS_UTL
GROUP BY TRUNC(DATE_OPERATION), PACKAGE_NAME
ORDER BY JOUR DESC, NB_OPERATIONS DESC;

-- ========================================
-- REQUETES INFORMATIONS SERVEUR (NOUVEAU)
-- ========================================

-- Dernieres operations avec infos serveur completes
SELECT
    TO_CHAR(DATE_OPERATION, 'DD/MM HH24:MI:SS') AS DATE_OP,
    DB_NAME,
    HOST_NAME,
    INSTANCE_NAME,
    SESSION_USER,
    OS_USER,
    FILE_NAME,
    STATUT
FROM TA_LOG_FICHIERS_UTL
ORDER BY DATE_OPERATION DESC
FETCH FIRST 20 ROWS ONLY;

-- Operations par serveur/instance
SELECT
    DB_NAME,
    HOST_NAME,
    INSTANCE_NAME,
    COUNT(*) AS NB_OPS,
    COUNT(DISTINCT FILE_NAME) AS NB_FICHIERS,
    SUM(CASE WHEN STATUT='ERROR' THEN 1 ELSE 0 END) AS NB_ERREURS
FROM TA_LOG_FICHIERS_UTL
GROUP BY DB_NAME, HOST_NAME, INSTANCE_NAME;

-- Sessions actives (qui ont ecrit des fichiers)
SELECT
    SESSION_USER,
    OS_USER,
    IP_ADDRESS,
    TERMINAL,
    SID,
    SERIAL#,
    COUNT(*) AS NB_FICHIERS,
    MAX(DATE_OPERATION) AS DERNIERE_ACTIVITE
FROM TA_LOG_FICHIERS_UTL
WHERE DATE_OPERATION > SYSDATE - 1
GROUP BY SESSION_USER, OS_USER, IP_ADDRESS, TERMINAL, SID, SERIAL#
ORDER BY DERNIERE_ACTIVITE DESC;

-- Verifier sur quel serveur on est
SELECT
    (SELECT name FROM v$database) AS DB_NAME,
    SYS_CONTEXT('USERENV', 'INSTANCE_NAME') AS INSTANCE,
    SYS_CONTEXT('USERENV', 'SERVER_HOST') AS HOST,
    SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS SERVICE
FROM DUAL;

*/

-- ============================================================
-- 10. VERIFICATION ET MESSAGE DE FIN
-- ============================================================
SET SERVEROUTPUT ON

DECLARE
    v_table_exists   NUMBER;
    v_proc_exists    NUMBER;
    v_view_count     NUMBER;
BEGIN
    -- Verifier la table
    SELECT COUNT(*) INTO v_table_exists
    FROM user_tables WHERE table_name = 'TA_LOG_FICHIERS_UTL';

    -- Verifier la procedure
    SELECT COUNT(*) INTO v_proc_exists
    FROM user_procedures WHERE object_name = 'SP_LOG_FICHIER';

    -- Compter les vues
    SELECT COUNT(*) INTO v_view_count
    FROM user_views WHERE view_name LIKE 'V_LOG_FICHIERS%';

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('  DEPLOIEMENT TABLE_LOG_FICHIERS_PACKAGES.sql TERMINE');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  Table TA_LOG_FICHIERS_UTL : ' || CASE WHEN v_table_exists = 1 THEN 'OK' ELSE 'ERREUR' END);
    DBMS_OUTPUT.PUT_LINE('  Procedure SP_LOG_FICHIER  : ' || CASE WHEN v_proc_exists = 1 THEN 'OK' ELSE 'ERREUR' END);
    DBMS_OUTPUT.PUT_LINE('  Vues creees               : ' || v_view_count || '/7');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  Colonnes serveur ajoutees :');
    DBMS_OUTPUT.PUT_LINE('    - DB_NAME, INSTANCE_NAME, HOST_NAME');
    DBMS_OUTPUT.PUT_LINE('    - SERVICE_NAME, OS_USER, IP_ADDRESS');
    DBMS_OUTPUT.PUT_LINE('    - TERMINAL, SID, SERIAL#');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  Ce script est IDEMPOTENT (peut etre re-execute)');
    DBMS_OUTPUT.PUT_LINE('============================================================');
END;
/

-- Test rapide de la procedure
BEGIN
    SP_LOG_FICHIER(
        p_package_name  => 'TEST',
        p_function_name => 'DEPLOY_CHECK',
        p_statut        => 'OK'
    );
    DBMS_OUTPUT.PUT_LINE('Test SP_LOG_FICHIER : OK');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Test SP_LOG_FICHIER : ERREUR - ' || SQLERRM);
END;
/

-- Afficher le log de test
SELECT 'Test log cree: ' || FILE_NAME || ' | DB: ' || DB_NAME || ' | Host: ' || HOST_NAME AS TEST_RESULT
FROM TA_LOG_FICHIERS_UTL
WHERE FUNCTION_NAME = 'DEPLOY_CHECK'
ORDER BY DATE_OPERATION DESC
FETCH FIRST 1 ROWS ONLY;

-- ============================================================
-- FIN DU SCRIPT
-- ============================================================
