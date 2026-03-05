#!/bin/bash
# ============================================================
# Script de backup Oracle - Schemas ACCURATE
# Schemas exportes : BANKREC, EXP_RNAPA
# Date : 18/02/2026
# Usage : su - oracle puis ./backup_oracle.sh [PROD|QUAL]
# ============================================================

# Configuration Environnement
ENV=${1:-QUAL}  # Par defaut QUAL si non specifie

if [ "$ENV" = "PROD" ]; then
    EXPORT_DIR_BANKREC="/apps/oracle/exp/P08449AP1"
    EXPORT_DIR_EXP_RNAPA="/apps/oracle/exp/P08449BP1"
elif [ "$ENV" = "QUAL" ]; then
    EXPORT_DIR_BANKREC="/apps/oracle/exp/Q08449AP1"
    EXPORT_DIR_EXP_RNAPA="/apps/oracle/exp/Q08449BP1"
else
    echo "ERREUR: Environnement invalide. Utiliser PROD ou QUAL"
    echo "Usage: ./backup_oracle.sh [PROD|QUAL]"
    exit 1
fi

# Configuration
DATE_BACKUP=$(date +%d_%m_%Y)
DUMP_USER="USER_ACCURATE_DUMP"
DUMP_PWD="sopra_moa300589"
LOG_FILE="/home/oracle/backup_${ENV}_${DATE_BACKUP}.log"

echo "=== DEBUT BACKUP ${ENV} : $(date) ===" | tee -a $LOG_FILE
echo "Environnement : ${ENV}" | tee -a $LOG_FILE
echo "Directory BANKREC : ${EXPORT_DIR_BANKREC}" | tee -a $LOG_FILE
echo "Directory EXP_RNAPA : ${EXPORT_DIR_EXP_RNAPA}" | tee -a $LOG_FILE

# Etape 1 : Creer les repertoires et permissions
echo "[1/7] Creation repertoires export..." | tee -a $LOG_FILE
mkdir -p $EXPORT_DIR_BANKREC
mkdir -p $EXPORT_DIR_EXP_RNAPA
chmod 777 $EXPORT_DIR_BANKREC
chmod 777 $EXPORT_DIR_EXP_RNAPA

# Etape 2 : Executer les commandes SQL (creation user, grants, directory)
echo "[2/7] Configuration Oracle (user, grants, directory)..." | tee -a $LOG_FILE

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

-- Directory export BANKREC
CREATE OR REPLACE DIRECTORY export_bankrec AS '${EXPORT_DIR_BANKREC}';
GRANT read, write ON DIRECTORY export_bankrec TO ${DUMP_USER};

-- Directory export EXP_RNAPA
CREATE OR REPLACE DIRECTORY export_exp_rnapa AS '${EXPORT_DIR_EXP_RNAPA}';
GRANT read, write ON DIRECTORY export_exp_rnapa TO ${DUMP_USER};

-- Verification
SELECT username, account_status FROM dba_users WHERE username = '${DUMP_USER}';
SELECT directory_name, directory_path FROM dba_directories WHERE directory_name LIKE 'EXPORT%';

PROMPT === CONFIGURATION TERMINEE ===
EXIT;
EOF

# Etape 3 : Export schema ACCURATE - BANKREC
echo "[3/7] Export schema ACCURATE BANKREC vers ${EXPORT_DIR_BANKREC}..." | tee -a $LOG_FILE
expdp ${DUMP_USER}/${DUMP_PWD} \
    SCHEMAS=BANKREC \
    DIRECTORY=export_bankrec \
    DUMPFILE=exp_bankrec_${ENV}_${DATE_BACKUP}.dmpdp \
    LOGFILE=exp_bankrec_${ENV}_${DATE_BACKUP}.log 2>&1 | tee -a $LOG_FILE

# Verification export BANKREC
if [ $? -eq 0 ]; then
    echo "   Export BANKREC : OK" | tee -a $LOG_FILE
else
    echo "   Export BANKREC : ERREUR" | tee -a $LOG_FILE
fi

# Etape 4 : Export schema EXP_RNAPA
echo "[4/7] Export schema EXP_RNAPA vers ${EXPORT_DIR_EXP_RNAPA}..." | tee -a $LOG_FILE
expdp ${DUMP_USER}/${DUMP_PWD} \
    SCHEMAS=EXP_RNAPA \
    DIRECTORY=export_exp_rnapa \
    DUMPFILE=exp_rnapa_${ENV}_${DATE_BACKUP}.dmpdp \
    LOGFILE=exp_rnapa_${ENV}_${DATE_BACKUP}.log 2>&1 | tee -a $LOG_FILE

# Verification export EXP_RNAPA
if [ $? -eq 0 ]; then
    echo "   Export EXP_RNAPA : OK" | tee -a $LOG_FILE
else
    echo "   Export EXP_RNAPA : ERREUR" | tee -a $LOG_FILE
fi

# Etape 5 : Resume - Verification fichiers generes
echo "[5/7] Verification fichiers ACCURATE generes..." | tee -a $LOG_FILE
echo "--- BANKREC (${EXPORT_DIR_BANKREC}) ---" | tee -a $LOG_FILE
ls -lh ${EXPORT_DIR_BANKREC}/exp_bankrec_${ENV}_${DATE_BACKUP}.* 2>/dev/null | tee -a $LOG_FILE
echo "--- EXP_RNAPA (${EXPORT_DIR_EXP_RNAPA}) ---" | tee -a $LOG_FILE
ls -lh ${EXPORT_DIR_EXP_RNAPA}/exp_rnapa_${ENV}_${DATE_BACKUP}.* 2>/dev/null | tee -a $LOG_FILE

# Etape 6 : Regroupement des dumps dans le repertoire BANKREC
# PROD: /apps/oracle/exp/P08449AP1 | QUAL: /apps/oracle/exp/Q08449AP1
DEST_DIR="${EXPORT_DIR_BANKREC}"
echo "[6/7] Regroupement des dumps vers ${DEST_DIR}..." | tee -a $LOG_FILE

# BANKREC est deja dans le bon repertoire
echo "   BANKREC deja present dans ${DEST_DIR}/" | tee -a $LOG_FILE

# Deplacer les fichiers EXP_RNAPA vers le repertoire BANKREC
mv ${EXPORT_DIR_EXP_RNAPA}/exp_rnapa_${ENV}_${DATE_BACKUP}.dmpdp ${DEST_DIR}/
mv ${EXPORT_DIR_EXP_RNAPA}/exp_rnapa_${ENV}_${DATE_BACKUP}.log ${DEST_DIR}/
echo "   EXP_RNAPA deplace vers ${DEST_DIR}/" | tee -a $LOG_FILE

# Donner les droits 777 sur les deux dumps
chmod 777 ${DEST_DIR}/exp_bankrec_${ENV}_${DATE_BACKUP}.dmpdp
chmod 777 ${DEST_DIR}/exp_rnapa_${ENV}_${DATE_BACKUP}.dmpdp
echo "   Permissions 777 appliquees sur les dumps" | tee -a $LOG_FILE

# Verification des fichiers regroupes
echo "--- Fichiers dans ${DEST_DIR} ---" | tee -a $LOG_FILE
ls -lh ${DEST_DIR}/exp_*_${ENV}_${DATE_BACKUP}.* 2>/dev/null | tee -a $LOG_FILE

# Etape 7 : Compression des dumps
echo "[7/8] Compression des dumps avec gzip..." | tee -a $LOG_FILE
echo "   Compression BANKREC..." | tee -a $LOG_FILE
gzip -v ${DEST_DIR}/exp_bankrec_${ENV}_${DATE_BACKUP}.dmpdp 2>&1 | tee -a $LOG_FILE
echo "   Compression EXP_RNAPA..." | tee -a $LOG_FILE
gzip -v ${DEST_DIR}/exp_rnapa_${ENV}_${DATE_BACKUP}.dmpdp 2>&1 | tee -a $LOG_FILE

# Verification fichiers compresses
echo "--- Fichiers compresses ---" | tee -a $LOG_FILE
ls -lh ${DEST_DIR}/exp_*_${ENV}_${DATE_BACKUP}.dmpdp.gz 2>/dev/null | tee -a $LOG_FILE

# Etape 8 : Suppression du user temporaire
echo "[8/8] Suppression user ${DUMP_USER}..." | tee -a $LOG_FILE
sqlplus -S / as sysdba <<EOF | tee -a $LOG_FILE
DROP USER ${DUMP_USER} CASCADE;
PROMPT User ${DUMP_USER} supprime.
EXIT;
EOF

echo "" | tee -a $LOG_FILE
echo "=== FIN BACKUP ${ENV} : $(date) ===" | tee -a $LOG_FILE
echo "Log complet : $LOG_FILE"
echo "Dumps compresses dans : ${DEST_DIR}/"
echo "  - exp_bankrec_${ENV}_${DATE_BACKUP}.dmpdp.gz"
echo "  - exp_rnapa_${ENV}_${DATE_BACKUP}.dmpdp.gz"
