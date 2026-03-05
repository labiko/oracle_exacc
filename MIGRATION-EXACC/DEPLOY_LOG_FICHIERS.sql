-- ============================================================
-- DEPLOY_LOG_FICHIERS.sql
-- Script IDEMPOTENT - Peut etre execute plusieurs fois
-- Migration ExaCC - PARNA
-- ============================================================

SET SERVEROUTPUT ON

-- ============================================================
-- 1. CREER LA TABLE SI ELLE N'EXISTE PAS
-- ============================================================
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables WHERE table_name = 'LOG_FICHIERS_PACKAGES';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
        CREATE TABLE LOG_FICHIERS_PACKAGES (
            ID_LOG              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            SCHEMA_NAME         VARCHAR2(128),
            PACKAGE_NAME        VARCHAR2(128) NOT NULL,
            FUNCTION_NAME       VARCHAR2(128) NOT NULL,
            DIRECTORY_LOGIQUE   VARCHAR2(128),
            DIRECTORY_ORACLE    VARCHAR2(128),
            DIRECTORY_PATH      VARCHAR2(4000),
            FILE_NAME           VARCHAR2(500),
            FILE_MODE           VARCHAR2(10),
            CONTENU_APERCU      VARCHAR2(4000),
            NB_LIGNES           NUMBER,
            TAILLE_OCTETS       NUMBER,
            ID_CLOB             NUMBER,
            NOM_PARAM           VARCHAR2(255),
            STATUT              VARCHAR2(20) DEFAULT ''OK'',
            MESSAGE_ERREUR      VARCHAR2(4000),
            SESSION_USER        VARCHAR2(128) DEFAULT SYS_CONTEXT(''USERENV'', ''SESSION_USER''),
            MODULE              VARCHAR2(128) DEFAULT SYS_CONTEXT(''USERENV'', ''MODULE''),
            DATE_OPERATION      TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
            DB_NAME             VARCHAR2(128),
            INSTANCE_NAME       VARCHAR2(128),
            HOST_NAME           VARCHAR2(128),
            SERVICE_NAME        VARCHAR2(128),
            OS_USER             VARCHAR2(128),
            IP_ADDRESS          VARCHAR2(50),
            TERMINAL            VARCHAR2(128),
            SID                 NUMBER,
            SERIAL#             NUMBER
        )';
        DBMS_OUTPUT.PUT_LINE('[OK] Table LOG_FICHIERS_PACKAGES creee.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('[INFO] Table LOG_FICHIERS_PACKAGES existe deja.');
    END IF;
END;
/

-- ============================================================
-- 2. CREER LES INDEX SI ILS N'EXISTENT PAS
-- ============================================================
DECLARE
    PROCEDURE create_index_if_not_exists(p_index_name VARCHAR2, p_ddl VARCHAR2) IS
        v_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists FROM user_indexes WHERE index_name = p_index_name;
        IF v_exists = 0 THEN
            EXECUTE IMMEDIATE p_ddl;
            DBMS_OUTPUT.PUT_LINE('[OK] Index ' || p_index_name || ' cree.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[INFO] Index ' || p_index_name || ' existe deja.');
        END IF;
    END;
BEGIN
    create_index_if_not_exists('IDX_LOG_FICHIERS_DATE', 'CREATE INDEX IDX_LOG_FICHIERS_DATE ON LOG_FICHIERS_PACKAGES(DATE_OPERATION)');
    create_index_if_not_exists('IDX_LOG_FICHIERS_PKG', 'CREATE INDEX IDX_LOG_FICHIERS_PKG ON LOG_FICHIERS_PACKAGES(PACKAGE_NAME)');
    create_index_if_not_exists('IDX_LOG_FICHIERS_FUNC', 'CREATE INDEX IDX_LOG_FICHIERS_FUNC ON LOG_FICHIERS_PACKAGES(FUNCTION_NAME)');
END;
/

-- ============================================================
-- 3. CREER OU REMPLACER LA PROCEDURE SP_LOG_FICHIER
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

    -- Inserer le log
    INSERT INTO LOG_FICHIERS_PACKAGES (
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
-- 4. VERIFICATION FINALE
-- ============================================================
DECLARE
    v_table NUMBER;
    v_proc  NUMBER;
    v_idx   NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_table FROM user_tables WHERE table_name = 'LOG_FICHIERS_PACKAGES';
    SELECT COUNT(*) INTO v_proc FROM user_procedures WHERE object_name = 'SP_LOG_FICHIER';
    SELECT COUNT(*) INTO v_idx FROM user_indexes WHERE index_name LIKE 'IDX_LOG_FICHIERS%';

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('  DEPLOIEMENT TERMINE - RESUME');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('  Table LOG_FICHIERS_PACKAGES : ' || CASE WHEN v_table = 1 THEN 'OK' ELSE 'ERREUR' END);
    DBMS_OUTPUT.PUT_LINE('  Procedure SP_LOG_FICHIER  : ' || CASE WHEN v_proc = 1 THEN 'OK' ELSE 'ERREUR' END);
    DBMS_OUTPUT.PUT_LINE('  Index crees               : ' || v_idx || '/3');
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('  Prochaines etapes :');
    DBMS_OUTPUT.PUT_LINE('  1. Compiler PKG_TEC_FICHIERS_WITH_LOG.sql');
    DBMS_OUTPUT.PUT_LINE('  2. Compiler PKG_LOG_WITH_LOG.sql');
    DBMS_OUTPUT.PUT_LINE('  3. Lancer le traitement');
    DBMS_OUTPUT.PUT_LINE('  4. SELECT * FROM LOG_FICHIERS_PACKAGES ORDER BY DATE_OPERATION DESC;');
    DBMS_OUTPUT.PUT_LINE('');
END;
/

-- ============================================================
-- 5. TEST RAPIDE
-- ============================================================
BEGIN
    SP_LOG_FICHIER(
        p_package_name  => 'TEST_DEPLOY',
        p_function_name => 'VERIFICATION',
        p_statut        => 'OK'
    );
    DBMS_OUTPUT.PUT_LINE('[OK] Test SP_LOG_FICHIER reussi.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('[ERREUR] Test SP_LOG_FICHIER : ' || SQLERRM);
END;
/

-- Afficher le log de test
SELECT 'Log test : ' || FUNCTION_NAME || ' | DB: ' || NVL(DB_NAME, 'N/A') || ' | Host: ' || NVL(HOST_NAME, 'N/A') AS RESULTAT
FROM LOG_FICHIERS_PACKAGES
WHERE PACKAGE_NAME = 'TEST_DEPLOY'
ORDER BY DATE_OPERATION DESC
FETCH FIRST 1 ROWS ONLY;

-- ============================================================
-- FIN DU SCRIPT
-- ============================================================
