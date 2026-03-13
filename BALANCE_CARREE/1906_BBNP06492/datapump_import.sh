#!/bin/bash
# =====================================================
# DATA PUMP - Import complet compte 1906
# =====================================================
# Importe les 3 tables pour rollback complet :
#   1. BR_DATA (records orphelins)
#   2. BRD_EU_JC_ITEMS (items Balance Carree)
#   3. BRD_EU_JC_SUMMARY (resume avec BAL_ST)
#
# A executer APRES la correction si rollback necessaire
# =====================================================

# Variables
ACCT_ID=1906
LOAD_ID=346241
PERIOD_JC="202602"

DUMP_DIR="BALANCE_CARREE_DIR"
DUMP_PATH="/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/datapump"

echo "=========================================="
echo "Import Data Pump - Compte ${ACCT_ID}"
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
# 3. Import BR_DATA
# =====================================================
echo ""
echo "=== Import 1/3 : BR_DATA ==="
DUMP_FILE="br_data_${ACCT_ID}_${LOAD_ID}.dmp"
LOG_FILE="br_data_${ACCT_ID}_${LOAD_ID}_import.log"

if [ ! -f "${DUMP_PATH}/${DUMP_FILE}" ]; then
    echo "ATTENTION: Fichier ${DUMP_FILE} non trouve - SKIP"
else
    impdp "'/ as sysdba'" \
      directory=${DUMP_DIR} \
      dumpfile=${DUMP_FILE} \
      logfile=${LOG_FILE} \
      table_exists_action=APPEND

    echo "Lignes importees BR_DATA:"
    grep -i "imported" ${DUMP_PATH}/${LOG_FILE} | grep "BR_DATA"
fi

# =====================================================
# 4. Import BRD_EU_JC_ITEMS
# =====================================================
echo ""
echo "=== Import 2/3 : BRD_EU_JC_ITEMS ==="
DUMP_FILE="jc_items_${ACCT_ID}_${LOAD_ID}.dmp"
LOG_FILE="jc_items_${ACCT_ID}_${LOAD_ID}_import.log"

if [ ! -f "${DUMP_PATH}/${DUMP_FILE}" ]; then
    echo "ATTENTION: Fichier ${DUMP_FILE} non trouve - SKIP"
else
    impdp "'/ as sysdba'" \
      directory=${DUMP_DIR} \
      dumpfile=${DUMP_FILE} \
      logfile=${LOG_FILE} \
      table_exists_action=APPEND

    echo "Lignes importees BRD_EU_JC_ITEMS:"
    grep -i "imported" ${DUMP_PATH}/${LOG_FILE} | grep "JC_ITEMS"
fi

# =====================================================
# 5. Import BRD_EU_JC_SUMMARY
# =====================================================
echo ""
echo "=== Import 3/3 : BRD_EU_JC_SUMMARY ==="
DUMP_FILE="jc_summary_${ACCT_ID}_${PERIOD_JC}.dmp"
LOG_FILE="jc_summary_${ACCT_ID}_${PERIOD_JC}_import.log"

if [ ! -f "${DUMP_PATH}/${DUMP_FILE}" ]; then
    echo "ATTENTION: Fichier ${DUMP_FILE} non trouve - SKIP"
else
    # Pour JC_SUMMARY, on doit d'abord supprimer la ligne existante
    echo "Suppression ligne existante dans BRD_EU_JC_SUMMARY..."
    sqlplus -S '/ as sysdba' <<EOF
DELETE FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = ${ACCT_ID} AND PERIOD_JC = '${PERIOD_JC}';
COMMIT;
EXIT;
EOF

    impdp "'/ as sysdba'" \
      directory=${DUMP_DIR} \
      dumpfile=${DUMP_FILE} \
      logfile=${LOG_FILE} \
      table_exists_action=APPEND

    echo "Lignes importees BRD_EU_JC_SUMMARY:"
    grep -i "imported" ${DUMP_PATH}/${LOG_FILE} | grep "JC_SUMMARY"
fi

# =====================================================
# Resume
# =====================================================
echo ""
echo "=========================================="
echo "Import termine."
echo "=========================================="
echo ""
echo "Verification des donnees restaurees:"
sqlplus -S '/ as sysdba' <<EOF
SET LINESIZE 200
SELECT 'BR_DATA' AS "TABLE", COUNT(*) AS "NB_LIGNES"
FROM BANKREC.BR_DATA WHERE acct_id=${ACCT_ID} AND load_id=${LOAD_ID}
UNION ALL
SELECT 'BRD_EU_JC_ITEMS', COUNT(*)
FROM BANKREC.BRD_EU_JC_ITEMS WHERE acct_id=${ACCT_ID} AND load_id=${LOAD_ID}
UNION ALL
SELECT 'BRD_EU_JC_SUMMARY', COUNT(*)
FROM BANKREC.BRD_EU_JC_SUMMARY WHERE acct_id=${ACCT_ID} AND period_jc='${PERIOD_JC}';

PROMPT
PROMPT Verification ecart Balance Carree:
SELECT PERIOD_JC, ACCT_ID, BAL_ST, DIFF AS "ECART"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = ${ACCT_ID} AND PERIOD_JC = '${PERIOD_JC}';
EXIT;
EOF

echo ""
echo "Rollback complet effectue."

