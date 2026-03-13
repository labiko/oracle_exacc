#!/bin/bash
# =====================================================
# DATA PUMP - Export records orphelins compte 1906
# =====================================================
# A executer sur DEV en tant que oracle ou avec droits DBA
#
# 1. Executer ce script sur DEV
# 2. Transferer le fichier .dmp vers PROD
# 3. Executer datapump_import_1906.sh sur PROD
# =====================================================

# Variables
DUMP_DIR="BALANCE_CARREE_DIR"
DUMP_PATH="/home/oracle/BALANCE_CARRE_ECART/datapump"
DUMP_FILE="br_data_1906_346241.dmp"
LOG_FILE="br_data_1906_346241_export.log"

echo "=========================================="
echo "Export Data Pump - Compte 1906, Load 346241"
echo "=========================================="

# 1. Creer le repertoire physique si necessaire
echo "Creation repertoire: ${DUMP_PATH}"
mkdir -p ${DUMP_PATH}
chmod 755 ${DUMP_PATH}

# 2. Creer le DIRECTORY Oracle
echo "Creation DIRECTORY Oracle: ${DUMP_DIR}"
sqlplus -S '/ as sysdba' <<EOF
CREATE OR REPLACE DIRECTORY ${DUMP_DIR} AS '${DUMP_PATH}';
GRANT READ, WRITE ON DIRECTORY ${DUMP_DIR} TO PUBLIC;
EXIT;
EOF

# 3. Export avec filtre
echo "Lancement export..."
expdp "'/ as sysdba'" \
  directory=${DUMP_DIR} \
  dumpfile=${DUMP_FILE} \
  logfile=${LOG_FILE} \
  tables=BANKREC.BR_DATA \
  query="\"WHERE acct_id=1906 AND load_id=346241\""

echo ""
echo "=========================================="
echo "Export termine."
echo "Fichier: ${DUMP_PATH}/${DUMP_FILE}"
echo "=========================================="

# 4. Afficher le nombre de lignes exportees
echo ""
echo "Verification du nombre de lignes exportees:"
grep -i "exported" ${DUMP_PATH}/${LOG_FILE} | grep "BR_DATA"

echo ""
echo "Transferer ce fichier vers PROD puis executer l'import."
