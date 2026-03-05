-- ============================================================
-- TABLE DE LOGS UTL_FILE - Migration ExaCC PARNA
-- Date : 25/02/2026
-- Description : Trace toutes les opérations fichiers UTL_FILE
-- ============================================================

-- ============================================================
-- 1. TABLE PRINCIPALE DE LOGS
-- ============================================================
CREATE TABLE TA_UTL_FILE_LOG (
    ID_LOG              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Informations fichier
    DIRECTORY_NAME      VARCHAR2(128)   NOT NULL,   -- Directory Oracle (DIR_IN_RNA, DIR_OUT_RNA, etc.)
    DIRECTORY_PATH      VARCHAR2(4000),             -- Chemin physique résolu
    FILE_NAME           VARCHAR2(255)   NOT NULL,   -- Nom du fichier
    FILE_MODE           VARCHAR2(10),               -- Mode : R (read), W (write), A (append)

    -- Opération
    OPERATION           VARCHAR2(30)    NOT NULL,   -- FOPEN, FCLOSE, PUT_LINE, GET_LINE, FRENAME, etc.
    OPERATION_STATUS    VARCHAR2(10)    DEFAULT 'SUCCESS', -- SUCCESS, ERROR, WARNING
    ERROR_CODE          VARCHAR2(30),               -- Code erreur Oracle si échec
    ERROR_MESSAGE       VARCHAR2(4000),             -- Message erreur détaillé

    -- Contexte
    PACKAGE_NAME        VARCHAR2(128),              -- Package appelant
    PROCEDURE_NAME      VARCHAR2(128),              -- Procédure/Fonction appelante
    LINE_NUMBER         NUMBER,                     -- Ligne dans le code source

    -- Métriques
    BYTES_PROCESSED     NUMBER,                     -- Taille traitée (octets)
    LINES_PROCESSED     NUMBER,                     -- Nombre de lignes lues/écrites
    DURATION_MS         NUMBER,                     -- Durée de l'opération (ms)

    -- Audit
    SESSION_USER        VARCHAR2(128)   DEFAULT SYS_CONTEXT('USERENV', 'SESSION_USER'),
    OS_USER             VARCHAR2(128)   DEFAULT SYS_CONTEXT('USERENV', 'OS_USER'),
    CLIENT_HOST         VARCHAR2(128)   DEFAULT SYS_CONTEXT('USERENV', 'HOST'),
    MODULE_NAME         VARCHAR2(128)   DEFAULT SYS_CONTEXT('USERENV', 'MODULE'),
    ACTION_NAME         VARCHAR2(128)   DEFAULT SYS_CONTEXT('USERENV', 'ACTION'),

    -- Timestamps
    DATE_CREATION       TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,

    -- Migration ExaCC
    IS_OCI_STORAGE      CHAR(1)         DEFAULT 'N', -- O=Object Storage OCI, N=Filesystem local
    OCI_BUCKET_NAME     VARCHAR2(256),              -- Nom du bucket si OCI
    OCI_OBJECT_URL      VARCHAR2(4000)              -- URL Object Storage si OCI
);

-- Index pour performances
CREATE INDEX IDX_UTL_FILE_LOG_DATE ON TA_UTL_FILE_LOG(DATE_CREATION);
CREATE INDEX IDX_UTL_FILE_LOG_DIR ON TA_UTL_FILE_LOG(DIRECTORY_NAME);
CREATE INDEX IDX_UTL_FILE_LOG_FILE ON TA_UTL_FILE_LOG(FILE_NAME);
CREATE INDEX IDX_UTL_FILE_LOG_OP ON TA_UTL_FILE_LOG(OPERATION);
CREATE INDEX IDX_UTL_FILE_LOG_STATUS ON TA_UTL_FILE_LOG(OPERATION_STATUS);
CREATE INDEX IDX_UTL_FILE_LOG_PKG ON TA_UTL_FILE_LOG(PACKAGE_NAME);

-- Commentaires
COMMENT ON TABLE TA_UTL_FILE_LOG IS 'Table de logs pour tracer toutes les opérations UTL_FILE - Migration ExaCC';
COMMENT ON COLUMN TA_UTL_FILE_LOG.DIRECTORY_NAME IS 'Directory Oracle : DIR_IN_RNA, DIR_OUT_RNA, DIR_ARCH_RNA, DIR_LOG_RNA, DIR_TEMP_RNA, IN_APPLI_DIR';
COMMENT ON COLUMN TA_UTL_FILE_LOG.OPERATION IS 'Opération UTL_FILE : FOPEN, FCLOSE, PUT_LINE, GET_LINE, PUT, NEW_LINE, FFLUSH, FRENAME, FCOPY, FGETATTR, FREMOVE';
COMMENT ON COLUMN TA_UTL_FILE_LOG.IS_OCI_STORAGE IS 'Indicateur stockage : O=Object Storage OCI, N=Filesystem local (NFS/ext4)';

-- ============================================================
-- 2. SEQUENCE (si Oracle < 12c sans IDENTITY)
-- ============================================================
-- CREATE SEQUENCE SEQ_UTL_FILE_LOG START WITH 1 INCREMENT BY 1 NOCACHE;

-- ============================================================
-- 3. PROCEDURE DE LOG (appelée par UTL_FILE_WRAPPER)
-- ============================================================
CREATE OR REPLACE PROCEDURE SP_LOG_UTL_FILE_OPERATION (
    p_directory_name    IN VARCHAR2,
    p_file_name         IN VARCHAR2,
    p_file_mode         IN VARCHAR2 DEFAULT NULL,
    p_operation         IN VARCHAR2,
    p_operation_status  IN VARCHAR2 DEFAULT 'SUCCESS',
    p_error_code        IN VARCHAR2 DEFAULT NULL,
    p_error_message     IN VARCHAR2 DEFAULT NULL,
    p_package_name      IN VARCHAR2 DEFAULT NULL,
    p_procedure_name    IN VARCHAR2 DEFAULT NULL,
    p_line_number       IN NUMBER   DEFAULT NULL,
    p_bytes_processed   IN NUMBER   DEFAULT NULL,
    p_lines_processed   IN NUMBER   DEFAULT NULL,
    p_duration_ms       IN NUMBER   DEFAULT NULL,
    p_is_oci_storage    IN CHAR     DEFAULT 'N',
    p_oci_bucket_name   IN VARCHAR2 DEFAULT NULL,
    p_oci_object_url    IN VARCHAR2 DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_directory_path VARCHAR2(4000);
BEGIN
    -- Récupérer le chemin physique du directory
    BEGIN
        SELECT directory_path INTO v_directory_path
        FROM all_directories
        WHERE directory_name = UPPER(p_directory_name);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_directory_path := '[DIRECTORY NOT FOUND]';
    END;

    INSERT INTO TA_UTL_FILE_LOG (
        DIRECTORY_NAME,
        DIRECTORY_PATH,
        FILE_NAME,
        FILE_MODE,
        OPERATION,
        OPERATION_STATUS,
        ERROR_CODE,
        ERROR_MESSAGE,
        PACKAGE_NAME,
        PROCEDURE_NAME,
        LINE_NUMBER,
        BYTES_PROCESSED,
        LINES_PROCESSED,
        DURATION_MS,
        IS_OCI_STORAGE,
        OCI_BUCKET_NAME,
        OCI_OBJECT_URL
    ) VALUES (
        UPPER(p_directory_name),
        v_directory_path,
        p_file_name,
        UPPER(p_file_mode),
        UPPER(p_operation),
        UPPER(p_operation_status),
        p_error_code,
        p_error_message,
        UPPER(p_package_name),
        UPPER(p_procedure_name),
        p_line_number,
        p_bytes_processed,
        p_lines_processed,
        p_duration_ms,
        p_is_oci_storage,
        p_oci_bucket_name,
        p_oci_object_url
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Ne jamais bloquer le traitement principal en cas d'erreur de log
        ROLLBACK;
END SP_LOG_UTL_FILE_OPERATION;
/

-- ============================================================
-- 4. VUES D'ANALYSE
-- ============================================================

-- Vue : Synthèse par directory
CREATE OR REPLACE VIEW V_UTL_FILE_LOG_BY_DIRECTORY AS
SELECT
    DIRECTORY_NAME,
    DIRECTORY_PATH,
    COUNT(*) AS NB_OPERATIONS,
    COUNT(DISTINCT FILE_NAME) AS NB_FICHIERS_UNIQUES,
    SUM(CASE WHEN OPERATION = 'FOPEN' AND FILE_MODE = 'R' THEN 1 ELSE 0 END) AS NB_LECTURES,
    SUM(CASE WHEN OPERATION = 'FOPEN' AND FILE_MODE IN ('W', 'A') THEN 1 ELSE 0 END) AS NB_ECRITURES,
    SUM(CASE WHEN OPERATION_STATUS = 'ERROR' THEN 1 ELSE 0 END) AS NB_ERREURS,
    SUM(NVL(BYTES_PROCESSED, 0)) AS TOTAL_BYTES,
    MIN(DATE_CREATION) AS PREMIERE_OPERATION,
    MAX(DATE_CREATION) AS DERNIERE_OPERATION
FROM TA_UTL_FILE_LOG
GROUP BY DIRECTORY_NAME, DIRECTORY_PATH
ORDER BY NB_OPERATIONS DESC;

-- Vue : Synthèse par package appelant
CREATE OR REPLACE VIEW V_UTL_FILE_LOG_BY_PACKAGE AS
SELECT
    PACKAGE_NAME,
    PROCEDURE_NAME,
    COUNT(*) AS NB_OPERATIONS,
    COUNT(DISTINCT DIRECTORY_NAME) AS NB_DIRECTORIES,
    COUNT(DISTINCT FILE_NAME) AS NB_FICHIERS_UNIQUES,
    SUM(CASE WHEN OPERATION_STATUS = 'ERROR' THEN 1 ELSE 0 END) AS NB_ERREURS,
    ROUND(AVG(DURATION_MS), 2) AS AVG_DURATION_MS,
    MIN(DATE_CREATION) AS PREMIERE_OPERATION,
    MAX(DATE_CREATION) AS DERNIERE_OPERATION
FROM TA_UTL_FILE_LOG
GROUP BY PACKAGE_NAME, PROCEDURE_NAME
ORDER BY NB_OPERATIONS DESC;

-- Vue : Fichiers les plus utilisés
CREATE OR REPLACE VIEW V_UTL_FILE_LOG_TOP_FILES AS
SELECT
    DIRECTORY_NAME,
    FILE_NAME,
    COUNT(*) AS NB_OPERATIONS,
    COUNT(DISTINCT OPERATION) AS NB_TYPES_OPERATIONS,
    SUM(CASE WHEN OPERATION_STATUS = 'ERROR' THEN 1 ELSE 0 END) AS NB_ERREURS,
    SUM(NVL(BYTES_PROCESSED, 0)) AS TOTAL_BYTES,
    SUM(NVL(LINES_PROCESSED, 0)) AS TOTAL_LINES,
    MIN(DATE_CREATION) AS PREMIERE_OPERATION,
    MAX(DATE_CREATION) AS DERNIERE_OPERATION
FROM TA_UTL_FILE_LOG
GROUP BY DIRECTORY_NAME, FILE_NAME
ORDER BY NB_OPERATIONS DESC;

-- Vue : Erreurs récentes
CREATE OR REPLACE VIEW V_UTL_FILE_LOG_ERRORS AS
SELECT
    DATE_CREATION,
    DIRECTORY_NAME,
    FILE_NAME,
    OPERATION,
    ERROR_CODE,
    ERROR_MESSAGE,
    PACKAGE_NAME,
    PROCEDURE_NAME,
    SESSION_USER
FROM TA_UTL_FILE_LOG
WHERE OPERATION_STATUS = 'ERROR'
ORDER BY DATE_CREATION DESC;

-- Vue : Statistiques journalières
CREATE OR REPLACE VIEW V_UTL_FILE_LOG_DAILY_STATS AS
SELECT
    TRUNC(DATE_CREATION) AS JOUR,
    COUNT(*) AS NB_OPERATIONS,
    COUNT(DISTINCT FILE_NAME) AS NB_FICHIERS,
    SUM(CASE WHEN OPERATION = 'FOPEN' THEN 1 ELSE 0 END) AS NB_FOPEN,
    SUM(CASE WHEN OPERATION = 'FCLOSE' THEN 1 ELSE 0 END) AS NB_FCLOSE,
    SUM(CASE WHEN OPERATION = 'PUT_LINE' THEN 1 ELSE 0 END) AS NB_PUT_LINE,
    SUM(CASE WHEN OPERATION = 'GET_LINE' THEN 1 ELSE 0 END) AS NB_GET_LINE,
    SUM(CASE WHEN OPERATION_STATUS = 'ERROR' THEN 1 ELSE 0 END) AS NB_ERREURS,
    SUM(NVL(BYTES_PROCESSED, 0)) AS TOTAL_BYTES,
    ROUND(AVG(DURATION_MS), 2) AS AVG_DURATION_MS
FROM TA_UTL_FILE_LOG
GROUP BY TRUNC(DATE_CREATION)
ORDER BY JOUR DESC;

-- Vue : Comparaison Filesystem vs OCI
CREATE OR REPLACE VIEW V_UTL_FILE_LOG_FS_VS_OCI AS
SELECT
    CASE WHEN IS_OCI_STORAGE = 'O' THEN 'Object Storage OCI' ELSE 'Filesystem Local' END AS STORAGE_TYPE,
    COUNT(*) AS NB_OPERATIONS,
    COUNT(DISTINCT FILE_NAME) AS NB_FICHIERS,
    ROUND(AVG(DURATION_MS), 2) AS AVG_DURATION_MS,
    SUM(NVL(BYTES_PROCESSED, 0)) AS TOTAL_BYTES,
    SUM(CASE WHEN OPERATION_STATUS = 'ERROR' THEN 1 ELSE 0 END) AS NB_ERREURS
FROM TA_UTL_FILE_LOG
GROUP BY IS_OCI_STORAGE;

-- ============================================================
-- 5. PURGE AUTOMATIQUE (optionnel)
-- ============================================================
CREATE OR REPLACE PROCEDURE SP_PURGE_UTL_FILE_LOG (
    p_retention_days IN NUMBER DEFAULT 90
) IS
    v_count NUMBER;
BEGIN
    DELETE FROM TA_UTL_FILE_LOG
    WHERE DATE_CREATION < SYSTIMESTAMP - p_retention_days;

    v_count := SQL%ROWCOUNT;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Purge terminée : ' || v_count || ' lignes supprimées (rétention ' || p_retention_days || ' jours)');
END SP_PURGE_UTL_FILE_LOG;
/

-- ============================================================
-- 6. GRANTS
-- ============================================================
-- Adapter selon vos schémas applicatifs
-- GRANT INSERT, SELECT ON TA_UTL_FILE_LOG TO RNAPPL;
-- GRANT EXECUTE ON SP_LOG_UTL_FILE_OPERATION TO RNAPPL;
-- GRANT SELECT ON V_UTL_FILE_LOG_BY_DIRECTORY TO RNAPPL;
-- GRANT SELECT ON V_UTL_FILE_LOG_BY_PACKAGE TO RNAPPL;
-- GRANT SELECT ON V_UTL_FILE_LOG_TOP_FILES TO RNAPPL;
-- GRANT SELECT ON V_UTL_FILE_LOG_ERRORS TO RNAPPL;
-- GRANT SELECT ON V_UTL_FILE_LOG_DAILY_STATS TO RNAPPL;
-- GRANT SELECT ON V_UTL_FILE_LOG_FS_VS_OCI TO RNAPPL;

-- ============================================================
-- 7. EXEMPLES D'UTILISATION
-- ============================================================
/*
-- Appel depuis UTL_FILE_WRAPPER après un FOPEN :
SP_LOG_UTL_FILE_OPERATION(
    p_directory_name  => 'DIR_IN_RNA',
    p_file_name       => 'ExtraitReglement_20260225.xml',
    p_file_mode       => 'R',
    p_operation       => 'FOPEN',
    p_package_name    => 'PKG_TEC_FICHIERS',
    p_procedure_name  => 'LectureFichierExterne'
);

-- Appel après une erreur :
SP_LOG_UTL_FILE_OPERATION(
    p_directory_name    => 'DIR_OUT_RNA',
    p_file_name         => 'export_failed.csv',
    p_file_mode         => 'W',
    p_operation         => 'FOPEN',
    p_operation_status  => 'ERROR',
    p_error_code        => 'UTL_FILE.INVALID_PATH',
    p_error_message     => 'Le chemin spécifié est invalide',
    p_package_name      => 'PKG_DTC'
);

-- Requêtes d'analyse :
SELECT * FROM V_UTL_FILE_LOG_BY_DIRECTORY;
SELECT * FROM V_UTL_FILE_LOG_BY_PACKAGE;
SELECT * FROM V_UTL_FILE_LOG_ERRORS WHERE DATE_CREATION > SYSDATE - 1;
SELECT * FROM V_UTL_FILE_LOG_DAILY_STATS;
*/
