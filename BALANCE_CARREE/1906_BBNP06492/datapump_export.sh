#!/bin/bash
# =====================================================
# DATA PUMP - Export complet compte 1906
# =====================================================
# Exporte les 3 tables necessaires pour rollback complet :
#   1. BR_DATA (records orphelins)
#   2. BRD_EU_JC_ITEMS (items Balance Carree)
#   3. BRD_EU_JC_SUMMARY (resume avec BAL_ST)
#
# A executer AVANT la correction pour sauvegarder les donnees
# =====================================================

# Variables
ACCT_ID=1906
LOAD_ID=346241
PERIOD_JC="202602"

DUMP_DIR="BALANCE_CARREE_DIR"
DUMP_PATH="/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/datapump"

echo "=========================================="
echo "Export Data Pump - Compte ${ACCT_ID}"
echo "Load: ${LOAD_ID}, Periode: ${PERIOD_JC}"
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
echo "=== Export 1/3 : BR_DATA ==="
expdp "'/ as sysdba'" \
  directory=${DUMP_DIR} \
  dumpfile=br_data_${ACCT_ID}_${LOAD_ID}.dmp \
  logfile=br_data_${ACCT_ID}_${LOAD_ID}_export.log \
  tables=BANKREC.BR_DATA \
  query="\"WHERE acct_id=${ACCT_ID} AND load_id=${LOAD_ID}\""

echo "Lignes exportees BR_DATA:"
grep -i "exported" ${DUMP_PATH}/br_data_${ACCT_ID}_${LOAD_ID}_export.log | grep "BR_DATA"

# =====================================================
# 4. Export BRD_EU_JC_ITEMS
# =====================================================
echo ""
echo "=== Export 2/3 : BRD_EU_JC_ITEMS ==="
expdp "'/ as sysdba'" \
  directory=${DUMP_DIR} \
  dumpfile=jc_items_${ACCT_ID}_${LOAD_ID}.dmp \
  logfile=jc_items_${ACCT_ID}_${LOAD_ID}_export.log \
  tables=BANKREC.BRD_EU_JC_ITEMS \
  query="\"WHERE acct_id=${ACCT_ID} AND load_id=${LOAD_ID}\""

echo "Lignes exportees BRD_EU_JC_ITEMS:"
grep -i "exported" ${DUMP_PATH}/jc_items_${ACCT_ID}_${LOAD_ID}_export.log | grep "JC_ITEMS"

# =====================================================
# 5. Export BRD_EU_JC_SUMMARY
# =====================================================
echo ""
echo "=== Export 3/3 : BRD_EU_JC_SUMMARY ==="
expdp "'/ as sysdba'" \
  directory=${DUMP_DIR} \
  dumpfile=jc_summary_${ACCT_ID}_${PERIOD_JC}.dmp \
  logfile=jc_summary_${ACCT_ID}_${PERIOD_JC}_export.log \
  tables=BANKREC.BRD_EU_JC_SUMMARY \
  query="\"WHERE acct_id=${ACCT_ID} AND period_jc='${PERIOD_JC}'\""

echo "Lignes exportees BRD_EU_JC_SUMMARY:"
grep -i "exported" ${DUMP_PATH}/jc_summary_${ACCT_ID}_${PERIOD_JC}_export.log | grep "JC_SUMMARY"

# =====================================================
# Resume
# =====================================================
echo ""
echo "=========================================="
echo "Export termine."
echo "=========================================="
echo "Fichiers crees dans ${DUMP_PATH}:"
ls -la ${DUMP_PATH}/*.dmp 2>/dev/null
echo ""
echo "Pour restaurer, executer datapump_import.sh"
