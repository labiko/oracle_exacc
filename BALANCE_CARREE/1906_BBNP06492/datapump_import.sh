#!/bin/bash
# =====================================================
# DATA PUMP - Import BR_DATA compte 1906
# =====================================================
# Importe uniquement BR_DATA (records orphelins)
# Les tables JC sont gerees par rollback_ecart_solde.sql
#
# A executer APRES la correction si rollback necessaire
# =====================================================

# Variables
ACCT_ID=1906
LOAD_ID=346241

DUMP_DIR="BALANCE_CARREE_DIR"
DUMP_PATH="/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/datapump"
DUMP_FILE="br_data_${ACCT_ID}_${LOAD_ID}.dmp"
LOG_FILE="br_data_${ACCT_ID}_${LOAD_ID}_import.log"

echo "=========================================="
echo "Import Data Pump - Compte ${ACCT_ID}"
echo "Load: ${LOAD_ID}"
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

# =====================================================
# 4. Import BR_DATA
# =====================================================
echo ""
echo "=== Import BR_DATA ==="
impdp "'/ as sysdba'" \
  directory=${DUMP_DIR} \
  dumpfile=${DUMP_FILE} \
  logfile=${LOG_FILE} \
  table_exists_action=APPEND

echo "Lignes importees BR_DATA:"
grep -i "imported" ${DUMP_PATH}/${LOG_FILE} | grep "BR_DATA"

# =====================================================
# Resume
# =====================================================
echo ""
echo "=========================================="
echo "Import termine."
echo "=========================================="

# Verification
echo ""
echo "Verification des donnees restaurees:"
sqlplus -S '/ as sysdba' <<EOF
SET LINESIZE 200
SELECT COUNT(*) AS "NB_LIGNES_BR_DATA"
FROM BANKREC.BR_DATA WHERE acct_id=${ACCT_ID} AND load_id=${LOAD_ID};
EXIT;
EOF

echo ""
echo "Pour les tables JC, executer les INSERT generes par rollback_ecart_solde.sql"

