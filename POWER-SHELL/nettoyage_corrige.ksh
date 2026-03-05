#!/bin/ksh
#===============================================================================
#
#   SCRIPT DE NETTOYAGE - SERVEUR PARNA
#
#   Description : Supprime les fichiers et repertoires obsoletes
#                 (contenant 'old' ou 'backup' dans leur nom)
#                 ainsi que des fichiers specifiques identifies comme inutiles.
#
#   Usage:
#       Mode test (dry-run) : ./nettoyage_corrige.ksh -n
#       Mode reel           : ./nettoyage_corrige.ksh
#
#   Auteur : Alpha Diallo
#   Date   : 2025-01-26
#   Version: 2.0 (version corrigee)
#
#===============================================================================

#-------------------------------------------------------------------------------
# CONFIGURATION
#-------------------------------------------------------------------------------

# Repertoire de base de l'application
APP_BASE="/applis/04688-parna-r1"

# Fichier de log avec horodatage
LOG_FILE="${APP_BASE}/logs/nettoyage_$(date '+%Y%m%d_%H%M%S').log"

# Mode dry-run (0 = execution reelle, 1 = simulation)
DRY_RUN=0

# Compteurs pour le rapport final
COUNT_FILES_DELETED=0
COUNT_DIRS_DELETED=0
COUNT_ERRORS=0

#-------------------------------------------------------------------------------
# GESTION DES OPTIONS
#-------------------------------------------------------------------------------

print_usage() {
    echo "Usage: $0 [-n] [-h]"
    echo ""
    echo "Options:"
    echo "  -n    Mode dry-run (simulation sans suppression)"
    echo "  -h    Affiche cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 -n    # Test : affiche ce qui serait supprime"
    echo "  $0       # Execution reelle du nettoyage"
}

while getopts "nh" opt; do
    case "$opt" in
        n) DRY_RUN=1 ;;
        h) print_usage; exit 0 ;;
        *) print_usage; exit 1 ;;
    esac
done
shift $((OPTIND-1))

#-------------------------------------------------------------------------------
# FONCTIONS UTILITAIRES
#-------------------------------------------------------------------------------

# Fonction de logging
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] $1"
    echo "$message" | tee -a "$LOG_FILE"
}

# Fonction de logging pour les erreurs
log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [ERREUR] $1"
    echo "$message" | tee -a "$LOG_FILE" >&2
    ((COUNT_ERRORS++))
}

# Fonction de logging pour les succes
log_success() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] [OK] $1"
    echo "$message" | tee -a "$LOG_FILE"
}

# Separateur visuel dans les logs
log_separator() {
    echo "------------------------------------------------------------" | tee -a "$LOG_FILE"
}

#-------------------------------------------------------------------------------
# FONCTION WRAPPER POUR rm (avec support dry-run)
#-------------------------------------------------------------------------------

do_rm() {
    local target="$1"

    # Verifier que la cible n'est pas vide
    if [[ -z "$target" ]]; then
        return 0
    fi

    # Verifier que la cible existe
    if [[ ! -e "$target" && ! -L "$target" ]]; then
        log_message "[SKIP] N'existe pas: $target"
        return 0
    fi

    # Mode dry-run : simulation uniquement
    if [[ $DRY_RUN -eq 1 ]]; then
        if [[ -d "$target" ]]; then
            log_message "[DRY-RUN] Supprimerait repertoire: $target"
        else
            log_message "[DRY-RUN] Supprimerait fichier: $target"
        fi
        return 0
    fi

    # Mode reel : suppression effective
    if [[ -d "$target" ]]; then
        # Suppression de repertoire
        if rm -rf "$target" 2>/dev/null; then
            log_success "Repertoire supprime: $target"
            ((COUNT_DIRS_DELETED++))
        else
            log_error "Echec suppression repertoire: $target"
        fi
    else
        # Suppression de fichier
        if rm -f "$target" 2>/dev/null; then
            log_success "Fichier supprime: $target"
            ((COUNT_FILES_DELETED++))
        else
            log_error "Echec suppression fichier: $target"
        fi
    fi
}

# Fonction pour supprimer avec pattern (glob)
do_rm_pattern() {
    local pattern="$1"
    local base_dir=$(dirname "$pattern")
    local file_pattern=$(basename "$pattern")

    if [[ ! -d "$base_dir" ]]; then
        log_message "[SKIP] Repertoire n'existe pas: $base_dir"
        return 0
    fi

    # Utiliser find pour les patterns avec wildcards
    find "$base_dir" -maxdepth 1 -name "$file_pattern" 2>/dev/null | while read -r file; do
        do_rm "$file"
    done
}

#-------------------------------------------------------------------------------
# INITIALISATION
#-------------------------------------------------------------------------------

# Creer le repertoire de logs s'il n'existe pas
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

# Initialiser le fichier de log
: > "$LOG_FILE"

#-------------------------------------------------------------------------------
# DEBUT DU SCRIPT
#-------------------------------------------------------------------------------

log_separator
log_message "DEBUT DU SCRIPT DE NETTOYAGE"
log_separator

if [[ $DRY_RUN -eq 1 ]]; then
    log_message ">>> MODE DRY-RUN ACTIVE - Aucune suppression ne sera effectuee <<<"
else
    log_message ">>> MODE REEL - Les fichiers seront supprimes <<<"
fi

log_message "Repertoire de travail: $(pwd)"
log_message "Utilisateur: $(whoami)"
log_message "Date: $(date)"
log_separator

#-------------------------------------------------------------------------------
# PHASE 1 : RECHERCHE DES FICHIERS/REPERTOIRES CONTENANT 'old' OU 'backup'
#-------------------------------------------------------------------------------

log_message ""
log_message "=== PHASE 1 : Recherche des composants 'old' et 'backup' ==="
log_message ""

# Aller dans le repertoire de base
cd "$APP_BASE" || {
    log_error "Impossible d'acceder au repertoire: $APP_BASE"
    exit 1
}

# Recherche des fichiers contenant 'old' (insensible a la casse)
FICHIERS_OLD=$(find . -type f -iname "*old*" 2>/dev/null)

# Recherche des repertoires contenant 'old' (CORRIGE: -type d au lieu de -type f)
DIRS_OLD=$(find . -type d -iname "*old*" 2>/dev/null)

# Recherche des fichiers contenant 'backup' (insensible a la casse)
FICHIERS_BACKUP=$(find . -type f -iname "*backup*" 2>/dev/null)

# Recherche des repertoires contenant 'backup' (CORRIGE: -type d au lieu de -type f)
DIRS_BACKUP=$(find . -type d -iname "*backup*" 2>/dev/null)

# Afficher les resultats de la recherche
if [[ -n "$FICHIERS_OLD" || -n "$DIRS_OLD" || -n "$FICHIERS_BACKUP" || -n "$DIRS_BACKUP" ]]; then

    log_message "Composants trouves avec 'old' et 'backup':"
    log_separator

    if [[ -n "$FICHIERS_OLD" ]]; then
        log_message ""
        log_message ">>> Fichiers contenant 'old' <<<"
        echo "$FICHIERS_OLD" | while read -r f; do
            [[ -n "$f" ]] && log_message "  - $f"
        done
    fi

    if [[ -n "$DIRS_OLD" ]]; then
        log_message ""
        log_message ">>> Repertoires contenant 'old' <<<"
        echo "$DIRS_OLD" | while read -r d; do
            [[ -n "$d" ]] && log_message "  - $d"
        done
    fi

    if [[ -n "$FICHIERS_BACKUP" ]]; then
        log_message ""
        log_message ">>> Fichiers contenant 'backup' <<<"
        echo "$FICHIERS_BACKUP" | while read -r f; do
            [[ -n "$f" ]] && log_message "  - $f"
        done
    fi

    if [[ -n "$DIRS_BACKUP" ]]; then
        log_message ""
        log_message ">>> Repertoires contenant 'backup' <<<"
        echo "$DIRS_BACKUP" | while read -r d; do
            [[ -n "$d" ]] && log_message "  - $d"
        done
    fi

    log_separator
    log_message ""
    log_message "Demarrage du nettoyage Phase 1..."
    log_message ""

    # Supprimer les fichiers 'old'
    if [[ -n "$FICHIERS_OLD" ]]; then
        echo "$FICHIERS_OLD" | while IFS= read -r f; do
            [[ -n "$f" ]] && do_rm "$f"
        done
    fi

    # Supprimer les fichiers 'backup'
    if [[ -n "$FICHIERS_BACKUP" ]]; then
        echo "$FICHIERS_BACKUP" | while IFS= read -r f; do
            [[ -n "$f" ]] && do_rm "$f"
        done
    fi

    # Supprimer les repertoires 'old' (du plus profond au moins profond)
    if [[ -n "$DIRS_OLD" ]]; then
        echo "$DIRS_OLD" | sort -r | while IFS= read -r d; do
            [[ -n "$d" ]] && do_rm "$d"
        done
    fi

    # Supprimer les repertoires 'backup' (du plus profond au moins profond)
    if [[ -n "$DIRS_BACKUP" ]]; then
        echo "$DIRS_BACKUP" | sort -r | while IFS= read -r d; do
            [[ -n "$d" ]] && do_rm "$d"
        done
    fi

else
    log_message "Aucun composant avec 'old' ou 'backup' trouve dans $APP_BASE"
fi

#-------------------------------------------------------------------------------
# PHASE 2 : NETTOYAGE DES REPERTOIRES DE BACKUP SPECIFIQUES
#-------------------------------------------------------------------------------

log_message ""
log_message "=== PHASE 2 : Nettoyage des repertoires de backup (SGF-83470-MAJ CODE AP) ==="
log_message ""

cd /applis || {
    log_error "Impossible d'acceder au repertoire: /applis"
    exit 1
}

# Liste des repertoires de backup a supprimer
BACKUP_DIRS="08449-parna-r1_backup 04688-parna-r1-backup"

for DIR in $BACKUP_DIRS; do
    if [[ -d "$DIR" ]]; then
        log_message "Repertoire '$DIR' trouve"
        do_rm "/applis/$DIR"
    else
        log_message "Repertoire '$DIR' n'existe pas - OK"
    fi
done

#-------------------------------------------------------------------------------
# PHASE 3 : NETTOYAGE DES FICHIERS ET REPERTOIRES SPECIFIQUES
#-------------------------------------------------------------------------------

log_message ""
log_message "=== PHASE 3 : Nettoyage des fichiers et repertoires specifiques ==="
log_message ""

# Liste des elements a supprimer (repertoires)
log_message "-- Repertoires de delivery et logs anciens --"
do_rm "/applis/delivery/08449-parna-r1"
do_rm "/applis/package_old"
do_rm "/applis/logs/08449-parna-r1"

# Fichiers de logs specifiques
log_message ""
log_message "-- Fichiers de logs specifiques --"
do_rm "/applis/logs/checkDayIntegration_20251217.log"

# Archives et backups
log_message ""
log_message "-- Archives et backups --"
do_rm_pattern "/applis/04688-parna-r1/archive/*zip.bkp_appli.zip"
do_rm "/applis/04688-parna-r1/conf/RNAD-BCEF/bin/SCTASK0461646.zip"

# Repertoires temporaires (vider le contenu)
log_message ""
log_message "-- Nettoyage des repertoires temporaires --"
do_rm "/applis/04688-parna-r1/temp/aparnar1"
do_rm_pattern "/applis/04688-parna-r1/in/*"
do_rm_pattern "/applis/04688-parna-r1/tmp/*"

# Scripts de test et versions obsoletes
log_message ""
log_message "-- Scripts de test et versions obsoletes --"
SCRIPTS_TO_DELETE="
gestion-logs-v3.0.sh
gestion-logs-vJ.sh
gestion-logs-v4.0.sh
test1.sh
test2.sh
test4.sh
SCRIPT.sh
test.sh
test-test.sh
"

for script in $SCRIPTS_TO_DELETE; do
    do_rm "/applis/04688-parna-r1/soft/bin/$script"
done

# Scripts SQL obsoletes
log_message ""
log_message "-- Scripts SQL obsoletes --"
do_rm "/applis/04688-parna-r1/soft/oracle/sql/RNADGENJUCGES01.sql_OLD_16032023"
do_rm "/applis/04688-parna-r1/soft/oracle/sql/RNADGENIMPBAN01.sql_20032023"
do_rm "/applis/04688-parna-r1/soft/oracle/sql/DTCEXTACCTIG.sql_13_07_2023"

#-------------------------------------------------------------------------------
# RAPPORT FINAL
#-------------------------------------------------------------------------------

log_message ""
log_separator
log_message "FIN DU SCRIPT DE NETTOYAGE"
log_separator
log_message ""
log_message "=== RAPPORT FINAL ==="
log_message ""

if [[ $DRY_RUN -eq 1 ]]; then
    log_message "Mode: DRY-RUN (simulation)"
    log_message ">>> Aucun fichier n'a ete supprime <<<"
else
    log_message "Mode: REEL"
    log_message "Fichiers supprimes    : $COUNT_FILES_DELETED"
    log_message "Repertoires supprimes : $COUNT_DIRS_DELETED"
    log_message "Erreurs rencontrees   : $COUNT_ERRORS"
fi

log_message ""
log_message "Fichier de log: $LOG_FILE"
log_separator

# Code de sortie
if [[ $COUNT_ERRORS -gt 0 ]]; then
    log_error "Le script s'est termine avec $COUNT_ERRORS erreur(s)"
    exit 1
else
    log_success "Le script s'est termine avec succes"
    exit 0
fi
