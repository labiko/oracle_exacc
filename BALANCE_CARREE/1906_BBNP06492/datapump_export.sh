#!/bin/bash
# =====================================================
# DATA PUMP - Export BR_DATA compte 1906
# =====================================================
# Exporte uniquement BR_DATA (records orphelins)
# Les tables JC sont gerees par rollback_ecart_solde.sql
#
# A executer AVANT la correction pour sauvegarder les donnees
# =====================================================

# Variables
ACCT_ID=1906
LOAD_ID=346241

DUMP_DIR="BALANCE_CARREE_DIR"
DUMP_PATH="/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/datapump"

echo "=========================================="
echo "Export Data Pump - Compte ${ACCT_ID}"
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

# =====================================================
# 3. Export BR_DATA
# =====================================================
echo ""
echo "=== Export BR_DATA ==="
expdp "'/ as sysdba'" \
  directory=${DUMP_DIR} \
  dumpfile=br_data_${ACCT_ID}_${LOAD_ID}.dmp \
  logfile=br_data_${ACCT_ID}_${LOAD_ID}_export.log \
  tables=BANKREC.BR_DATA \
  query="\"WHERE acct_id=${ACCT_ID} AND load_id=${LOAD_ID}\""

echo "Lignes exportees BR_DATA:"
grep -i "exported" ${DUMP_PATH}/br_data_${ACCT_ID}_${LOAD_ID}_export.log | grep "BR_DATA"

# =====================================================
# Resume
# =====================================================
echo ""
echo "=========================================="
echo "Export termine."
echo "=========================================="
echo "Fichier cree: ${DUMP_PATH}/br_data_${ACCT_ID}_${LOAD_ID}.dmp"
echo ""
echo "Pour les tables JC, executer: rollback_ecart_solde.sql"
echo "Pour restaurer BR_DATA: datapump_import.sh"

