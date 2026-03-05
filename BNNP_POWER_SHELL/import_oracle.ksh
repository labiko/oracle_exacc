#!/bin/ksh
# ============================================================
# Script d'import Oracle - Schemas ACCURATE
# Date : 24/02/2026
# Usage : su - oracle puis ./import_oracle.ksh [PROD|QUAL|DEV] [SCHEMA] [DUMP_NAME]
# Exemple : ./import_oracle.ksh QUAL BANKREC exp_bankrec_QUAL_18_02_2026.dmpdp
# ============================================================
# OPTIMISE : DROP SCHEMA + IMPORT FRAIS (60-80% plus rapide)
# - Sauvegarde des grants avant DROP
# - PARALLEL=4 pour import multi-thread
# - TRANSFORM=DISABLE_ARCHIVE_LOGGING:Y pour eviter redo log
# ============================================================

# Verification parametres
if [ $# -lt 3 ]; then
    echo "ERREUR: Parametres manquants"
    echo "Usage: ./import_oracle.ksh [PROD|QUAL|DEV] [SCHEMA] [DUMP_NAME]"
    echo ""
    echo "Parametres:"
    echo "  ENV       : PROD, QUAL ou DEV"
    echo "  SCHEMA    : BANKREC ou EXP_RNAPA"
    echo "  DUMP_NAME : Nom du fichier dump (ex: exp_bankrec_QUAL_18_02_2026.dmpdp)"
    echo ""
    echo "Exemple:"
    echo "  ./import_oracle.ksh QUAL BANKREC exp_bankrec_QUAL_18_02_2026.dmpdp"
    echo "  ./import_oracle.ksh DEV BANKREC exp_bankrec_DEV_18_02_2026.dmpdp"
    exit 1
fi

ENV=$1
SCHEMA=$2
DUMP_NAME=$3

# Configuration des repertoires selon l'environnement
if [ "$ENV" = "PROD" ]; then
    IMPORT_DIR_BANKREC="/apps/oracle/exp/P08449AP1"
    IMPORT_DIR_EXP_RNAPA="/apps/oracle/exp/P08449BP1"
elif [ "$ENV" = "QUAL" ]; then
    IMPORT_DIR_BANKREC="/apps/oracle/exp/Q08449AP1"
    IMPORT_DIR_EXP_RNAPA="/apps/oracle/exp/Q08449BP1"
elif [ "$ENV" = "DEV" ]; then
    IMPORT_DIR_BANKREC="/apps/oracle/exp/D08449AP1"
    IMPORT_DIR_EXP_RNAPA="/apps/oracle/exp/D08449BP1"
else
    echo "ERREUR: Environnement invalide. Utiliser PROD, QUAL ou DEV"
    exit 1
fi

# Configuration
DATE_IMPORT=$(date +%d_%m_%Y_%H%M%S)
DUMP_USER="USER_ACCURATE_DUMP"
DUMP_PWD="sopra_moa300589"
LOG_FILE="/home/oracle/import_${ENV}_${SCHEMA}_${DATE_IMPORT}.log"

echo "=== DEBUT IMPORT ${ENV} : $(date) ===" | tee -a $LOG_FILE
echo "Environnement : ${ENV}" | tee -a $LOG_FILE
echo "Schema        : ${SCHEMA}" | tee -a $LOG_FILE
echo "Dump          : ${DUMP_NAME}" | tee -a $LOG_FILE

# Etape 1 : Recherche du dump dans les repertoires
echo "[1/5] Recherche du dump ${DUMP_NAME}..." | tee -a $LOG_FILE

DUMP_PATH=""
DIRECTORY_NAME=""

# Recherche dans le repertoire BANKREC
if [ -f "${IMPORT_DIR_BANKREC}/${DUMP_NAME}" ]; then
    DUMP_PATH="${IMPORT_DIR_BANKREC}/${DUMP_NAME}"
    DIRECTORY_NAME="export_bankrec"
    echo "   Dump trouve dans : ${IMPORT_DIR_BANKREC}/" | tee -a $LOG_FILE
fi

# Recherche dans le repertoire EXP_RNAPA
if [ -f "${IMPORT_DIR_EXP_RNAPA}/${DUMP_NAME}" ]; then
    DUMP_PATH="${IMPORT_DIR_EXP_RNAPA}/${DUMP_NAME}"
    DIRECTORY_NAME="export_exp_rnapa"
    echo "   Dump trouve dans : ${IMPORT_DIR_EXP_RNAPA}/" | tee -a $LOG_FILE
fi

# Verification si dump trouve
if [ -z "$DUMP_PATH" ]; then
    echo "ERREUR: Dump ${DUMP_NAME} non trouve dans :" | tee -a $LOG_FILE
    echo "  - ${IMPORT_DIR_BANKREC}/" | tee -a $LOG_FILE
    echo "  - ${IMPORT_DIR_EXP_RNAPA}/" | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
    echo "Fichiers disponibles dans ${IMPORT_DIR_BANKREC}:" | tee -a $LOG_FILE
    ls -lh ${IMPORT_DIR_BANKREC}/*.dmpdp 2>/dev/null | tee -a $LOG_FILE
    echo "" | tee -a $LOG_FILE
    echo "Fichiers disponibles dans ${IMPORT_DIR_EXP_RNAPA}:" | tee -a $LOG_FILE
    ls -lh ${IMPORT_DIR_EXP_RNAPA}/*.dmpdp 2>/dev/null | tee -a $LOG_FILE
    exit 1
fi

echo "   Dump path : ${DUMP_PATH}" | tee -a $LOG_FILE
echo "   Directory : ${DIRECTORY_NAME}" | tee -a $LOG_FILE
echo "   Taille    : $(ls -lh ${DUMP_PATH} | awk '{print $5}')" | tee -a $LOG_FILE

# Etape 2 : Configuration Oracle (user, grants, directory)
echo "[2/5] Configuration Oracle (user, grants, directory)..." | tee -a $LOG_FILE

sqlplus -S / as sysdba <<EOF | tee -a $LOG_FILE
SET SERVEROUTPUT ON
SET ECHO ON

-- Suppression user si existe deja
BEGIN
    EXECUTE IMMEDIATE 'DROP USER ${DUMP_USER} CASCADE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Creation user
CREATE USER ${DUMP_USER} IDENTIFIED BY ${DUMP_PWD};

-- Grants
GRANT connect, create table, create view, unlimited tablespace TO ${DUMP_USER};
GRANT create any directory, resource TO ${DUMP_USER};
GRANT exp_full_database, imp_full_database TO ${DUMP_USER};

-- Directory import BANKREC
CREATE OR REPLACE DIRECTORY export_bankrec AS '${IMPORT_DIR_BANKREC}';
GRANT read, write ON DIRECTORY export_bankrec TO ${DUMP_USER};

-- Directory import EXP_RNAPA
CREATE OR REPLACE DIRECTORY export_exp_rnapa AS '${IMPORT_DIR_EXP_RNAPA}';
GRANT read, write ON DIRECTORY export_exp_rnapa TO ${DUMP_USER};

-- Verification
SELECT username, account_status FROM dba_users WHERE username = '${DUMP_USER}';
SELECT directory_name, directory_path FROM dba_directories WHERE directory_name LIKE 'EXPORT%';

PROMPT === CONFIGURATION TERMINEE ===
EXIT;
EOF

# Etape 3 : DROP SCHEMA existant (pour import frais et rapide)
echo "[3/6] DROP SCHEMA ${SCHEMA} (si existe)..." | tee -a $LOG_FILE

sqlplus -S / as sysdba <<EOF | tee -a $LOG_FILE
SET SERVEROUTPUT ON

-- Sauvegarde des grants avant suppression
PROMPT === Sauvegarde grants ${SCHEMA} ===
SPOOL /home/oracle/grants_${SCHEMA}_${ENV}_backup.sql
SELECT 'GRANT ' || privilege || ' ON ' || owner || '.' || table_name || ' TO ' || grantee || ';'
FROM dba_tab_privs WHERE owner = '${SCHEMA}';
SELECT 'GRANT ' || privilege || ' TO ' || grantee || ';'
FROM dba_sys_privs WHERE grantee = '${SCHEMA}';
SPOOL OFF

-- DROP SCHEMA
PROMPT === DROP USER ${SCHEMA} CASCADE ===
BEGIN
    EXECUTE IMMEDIATE 'DROP USER ${SCHEMA} CASCADE';
    DBMS_OUTPUT.PUT_LINE('Schema ${SCHEMA} supprime avec succes');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Schema ${SCHEMA} n''existait pas ou erreur: ' || SQLERRM);
END;
/

EXIT;
EOF

# Etape 4 : Import du schema (frais, sans TABLE_EXISTS_ACTION)
echo "[4/6] Import schema ${SCHEMA} depuis ${DUMP_NAME}..." | tee -a $LOG_FILE

impdp ${DUMP_USER}/${DUMP_PWD} \
    SCHEMAS=${SCHEMA} \
    DIRECTORY=${DIRECTORY_NAME} \
    DUMPFILE=${DUMP_NAME} \
    LOGFILE=imp_${SCHEMA}_${ENV}_${DATE_IMPORT}.log \
    PARALLEL=4 \
    TRANSFORM=DISABLE_ARCHIVE_LOGGING:Y 2>&1 | tee -a $LOG_FILE

# Verification import
if [ $? -eq 0 ]; then
    echo "   Import ${SCHEMA} : OK" | tee -a $LOG_FILE
else
    echo "   Import ${SCHEMA} : ERREUR" | tee -a $LOG_FILE
fi

# Etape 5 : Verification import
echo "[5/6] Verification import ${SCHEMA}..." | tee -a $LOG_FILE

sqlplus -S / as sysdba <<EOF | tee -a $LOG_FILE
SET LINESIZE 200
SET PAGESIZE 100

PROMPT === Objets importes dans ${SCHEMA} ===
SELECT object_type, COUNT(*) AS nb_objets
FROM dba_objects
WHERE owner = '${SCHEMA}'
GROUP BY object_type
ORDER BY object_type;

PROMPT === Tables principales ===
SELECT table_name, num_rows
FROM dba_tables
WHERE owner = '${SCHEMA}'
ORDER BY table_name;

EXIT;
EOF

# Etape 6 : Suppression du user temporaire
echo "[6/6] Suppression user ${DUMP_USER}..." | tee -a $LOG_FILE
sqlplus -S / as sysdba <<EOF | tee -a $LOG_FILE
DROP USER ${DUMP_USER} CASCADE;
PROMPT User ${DUMP_USER} supprime.
EXIT;
EOF

echo "" | tee -a $LOG_FILE
echo "=== FIN IMPORT ${ENV} : $(date) ===" | tee -a $LOG_FILE
echo "Log complet : $LOG_FILE"
echo "Schema importe : ${SCHEMA}"
echo "Dump utilise : ${DUMP_PATH}"
