#!/bin/bash
# =====================================================
# DATA PUMP - Import records orphelins compte 1906
# =====================================================
# A executer sur PROD apres transfert du fichier .dmp
# =====================================================

# Variables
DUMP_DIR="BALANCE_CARREE_DIR"
DUMP_PATH="/home/oracle/BALANCE_CARRE_ECART/datapump"
DUMP_FILE="br_data_1906_346241.dmp"
LOG_FILE="br_data_1906_346241_import.log"

echo "=========================================="
echo "Import Data Pump - Compte 1906, Load 346241"
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

# 3. Verifier que le fichier .dmp existe
if [ ! -f "${DUMP_PATH}/${DUMP_FILE}" ]; then
    echo "ERREUR: Fichier ${DUMP_PATH}/${DUMP_FILE} non trouve!"
    echo "Transferer le fichier depuis DEV avant d'executer ce script."
    exit 1
fi

# 4. Import en mode APPEND
echo "Lancement import..."
impdp "'/ as sysdba'" \
  directory=${DUMP_DIR} \
  dumpfile=${DUMP_FILE} \
  logfile=${LOG_FILE} \
  table_exists_action=APPEND

echo ""
echo "=========================================="
echo "Import termine."
echo "=========================================="

# 5. Afficher le nombre de lignes importees
echo ""
echo "Verification du nombre de lignes importees:"
grep -i "imported" ${DUMP_PATH}/${LOG_FILE} | grep "BR_DATA"

# 6. Verifier s'il y a eu des erreurs
echo ""
echo "Verification des erreurs:"
grep -i "error" ${DUMP_PATH}/${LOG_FILE} || echo "Aucune erreur."

echo ""
echo "Verifier avec: SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE acct_id=1906 AND load_id=346241;"
