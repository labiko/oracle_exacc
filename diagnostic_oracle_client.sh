#!/bin/bash
# =============================================================================
# SCRIPT DE DIAGNOSTIC - Utilisation du Client Oracle
# =============================================================================
# Usage: chmod +x diagnostic_oracle_client.sh && ./diagnostic_oracle_client.sh
# Ou copier-coller directement dans le terminal
# =============================================================================

ORACLE_PATH="/apps/oracle/19000/cli64"
LOG_FILE="/tmp/diagnostic_oracle_$(date +%Y%m%d_%H%M%S).log"

echo "============================================================================="
echo " DIAGNOSTIC UTILISATION CLIENT ORACLE"
echo " Date: $(date)"
echo " Chemin analyse: $ORACLE_PATH"
echo " Log: $LOG_FILE"
echo "============================================================================="
echo ""

# Fonction pour logger
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "=== 1. INFORMATIONS SYSTEME ==="
log "Hostname: $(hostname)"
log "User: $(whoami)"
log "Date: $(date)"
log ""

log "=== 2. VARIABLES ORACLE ACTUELLES ==="
env | grep -i oracle | tee -a "$LOG_FILE"
log ""
log "ORACLE_HOME actuel: ${ORACLE_HOME:-NON DEFINI}"
log "TNS_ADMIN actuel: ${TNS_ADMIN:-NON DEFINI}"
log "PATH Oracle: $(echo $PATH | tr ':' '\n' | grep -i oracle)"
log ""

log "=== 3. INSTALLATIONS SQLPLUS TROUVEES ==="
find /apps /opt /usr -name "sqlplus" -type f 2>/dev/null | tee -a "$LOG_FILE"
log ""

log "=== 4. SQLPLUS PAR DEFAUT ==="
log "which sqlplus: $(which sqlplus 2>/dev/null || echo 'NON TROUVE')"
log "Version: $(sqlplus -V 2>/dev/null | head -1 || echo 'ERREUR')"
log ""

log "=== 5. DERNIERE UTILISATION DES BINAIRES ORACLE ==="
if [ -f "$ORACLE_PATH/bin/sqlplus" ]; then
    log "--- sqlplus ---"
    stat "$ORACLE_PATH/bin/sqlplus" 2>/dev/null | grep -E "Access|Modify|Change" | tee -a "$LOG_FILE"
fi
if [ -f "$ORACLE_PATH/bin/sqlldr" ]; then
    log "--- sqlldr ---"
    stat "$ORACLE_PATH/bin/sqlldr" 2>/dev/null | grep -E "Access|Modify|Change" | tee -a "$LOG_FILE"
fi
if [ -f "$ORACLE_PATH/bin/tnsping" ]; then
    log "--- tnsping ---"
    stat "$ORACLE_PATH/bin/tnsping" 2>/dev/null | grep -E "Access|Modify|Change" | tee -a "$LOG_FILE"
fi
log ""

log "=== 6. PROCESSUS ACTIFS UTILISANT CE CLIENT ==="
lsof +D "$ORACLE_PATH" 2>/dev/null | head -30 | tee -a "$LOG_FILE"
if [ $? -ne 0 ] || [ -z "$(lsof +D "$ORACLE_PATH" 2>/dev/null)" ]; then
    log "Aucun processus actif trouve utilisant $ORACLE_PATH"
fi
log ""

log "=== 7. SCRIPTS KSH/SH REFERENCANT CE CHEMIN ==="
log "Recherche en cours (peut prendre du temps)..."
SCRIPTS_FOUND=$(find /home /apps /opt /var 2>/dev/null -type f \( -name "*.ksh" -o -name "*.sh" \) -exec grep -l "$ORACLE_PATH" {} \; 2>/dev/null | head -50)
if [ -n "$SCRIPTS_FOUND" ]; then
    echo "$SCRIPTS_FOUND" | tee -a "$LOG_FILE"
    log ""
    log "Nombre de scripts trouves: $(echo "$SCRIPTS_FOUND" | wc -l)"
else
    log "Aucun script trouve referencant $ORACLE_PATH"
fi
log ""

log "=== 8. SCRIPTS UTILISANT SQLPLUS (sans chemin specifique) ==="
log "Recherche en cours..."
SQLPLUS_SCRIPTS=$(find /home /apps /opt 2>/dev/null -type f \( -name "*.ksh" -o -name "*.sh" \) -exec grep -l "sqlplus" {} \; 2>/dev/null | head -30)
if [ -n "$SQLPLUS_SCRIPTS" ]; then
    echo "$SQLPLUS_SCRIPTS" | tee -a "$LOG_FILE"
    log ""
    log "Nombre de scripts utilisant sqlplus: $(echo "$SQLPLUS_SCRIPTS" | wc -l)"
else
    log "Aucun script utilisant sqlplus trouve"
fi
log ""

log "=== 9. ORACLE_HOME DANS LES SCRIPTS ==="
log "Recherche des ORACLE_HOME definis dans les scripts..."
find /home /apps /opt 2>/dev/null -type f \( -name "*.ksh" -o -name "*.sh" \) -exec grep -h "ORACLE_HOME=" {} \; 2>/dev/null | sort -u | head -20 | tee -a "$LOG_FILE"
log ""

log "=== 10. CRONTABS UTILISANT ORACLE ==="
log "--- Crontab utilisateur courant ---"
crontab -l 2>/dev/null | grep -iE "oracle|sqlplus|sqlldr" | tee -a "$LOG_FILE"
log ""
log "--- Crontabs systeme ---"
grep -rh "sqlplus\|$ORACLE_PATH" /etc/cron* /var/spool/cron/* 2>/dev/null | head -20 | tee -a "$LOG_FILE"
log ""

log "=== 11. PROFILS UTILISATEURS AVEC CE CHEMIN ==="
grep -r "$ORACLE_PATH" /home/*/.profile /home/*/.bashrc /home/*/.kshrc /home/*/.bash_profile 2>/dev/null | tee -a "$LOG_FILE"
grep -r "$ORACLE_PATH" /etc/profile /etc/bashrc /etc/profile.d/* 2>/dev/null | tee -a "$LOG_FILE"
log ""

log "=== 12. FICHIERS TNS ==="
if [ -d "$ORACLE_PATH/network/admin" ]; then
    log "--- tnsnames.ora ---"
    ls -la "$ORACLE_PATH/network/admin/tnsnames.ora" 2>/dev/null | tee -a "$LOG_FILE"
    log "--- sqlnet.ora ---"
    ls -la "$ORACLE_PATH/network/admin/sqlnet.ora" 2>/dev/null | tee -a "$LOG_FILE"
fi
log ""

log "=== 13. RESUME ==="
log ""
log "Client Oracle analyse: $ORACLE_PATH"
log "Sqlplus par defaut:    $(which sqlplus 2>/dev/null)"
log ""

# Verifier si c'est le meme
DEFAULT_SQLPLUS=$(which sqlplus 2>/dev/null)
if [ "$DEFAULT_SQLPLUS" = "$ORACLE_PATH/bin/sqlplus" ]; then
    log ">>> CE CLIENT EST LE CLIENT PAR DEFAUT DU SYSTEME <<<"
else
    log ">>> CE CLIENT N'EST PAS LE CLIENT PAR DEFAUT <<<"
    log ">>> Client par defaut: $DEFAULT_SQLPLUS"
fi
log ""

log "============================================================================="
log " FIN DU DIAGNOSTIC"
log " Resultats complets dans: $LOG_FILE"
log "============================================================================="
