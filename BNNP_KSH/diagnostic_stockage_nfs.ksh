#!/bin/ksh
# ============================================================
# Script de Diagnostic Stockage NFS/NAS
# ============================================================
# Date : 24/02/2026
# Usage : ./diagnostic_stockage_nfs.ksh [REPERTOIRE]
# Exemple : ./diagnostic_stockage_nfs.ksh /applis/08449-parna-p1
# ============================================================
# Ce script vérifie :
#   1. Type de filesystem (local vs NFS)
#   2. Point de montage
#   3. Serveur NAS source
#   4. Options de montage
#   5. Test d'écriture/lecture
# ============================================================

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Répertoire à analyser (par défaut ou paramètre)
if [ -n "$1" ]; then
    TARGET_DIR="$1"
else
    TARGET_DIR="/applis/08449-parna-p1"
fi

# Fonction de log
log_info() {
    echo "${BLUE}[INFO]${NC} $1"
}

log_ok() {
    echo "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo "${RED}[ERREUR]${NC} $1"
}

# ============================================================
# EN-TETE
# ============================================================
echo "============================================================"
echo "   DIAGNOSTIC STOCKAGE NFS/NAS"
echo "============================================================"
echo "Date      : $(date '+%d/%m/%Y %H:%M:%S')"
echo "Serveur   : $(hostname)"
echo "Repertoire: ${TARGET_DIR}"
echo "============================================================"
echo ""

# ============================================================
# ETAPE 1 : VERIFICATION EXISTENCE DU REPERTOIRE
# ============================================================
echo "${BLUE}[1/7] VERIFICATION EXISTENCE DU REPERTOIRE${NC}"
echo "------------------------------------------------------------"

if [ -d "$TARGET_DIR" ]; then
    log_ok "Le repertoire $TARGET_DIR existe"
    ls -ld "$TARGET_DIR"
else
    log_error "Le repertoire $TARGET_DIR n'existe pas"
    echo ""
    echo "Repertoires disponibles dans /applis/ :"
    ls -la /applis/ 2>/dev/null || echo "  /applis/ n'existe pas"
    exit 1
fi
echo ""

# ============================================================
# ETAPE 2 : TYPE DE FILESYSTEM
# ============================================================
echo "${BLUE}[2/7] TYPE DE FILESYSTEM${NC}"
echo "------------------------------------------------------------"

# Méthode 1 : df -T
FS_TYPE=$(df -T "$TARGET_DIR" 2>/dev/null | tail -1 | awk '{print $2}')
FS_SOURCE=$(df -T "$TARGET_DIR" 2>/dev/null | tail -1 | awk '{print $1}')
FS_MOUNT=$(df -T "$TARGET_DIR" 2>/dev/null | tail -1 | awk '{print $7}')

echo "Type filesystem : $FS_TYPE"
echo "Source          : $FS_SOURCE"
echo "Point de montage: $FS_MOUNT"

# Analyse du type
case "$FS_TYPE" in
    nfs|nfs4|nfs3)
        log_ok "STOCKAGE NFS DETECTE"
        echo "    → Le repertoire est sur un partage NFS"
        echo "    → Serveur NAS : $(echo $FS_SOURCE | cut -d: -f1)"
        echo "    → Export NFS  : $(echo $FS_SOURCE | cut -d: -f2)"
        IS_NFS="OUI"
        ;;
    cifs|smb)
        log_ok "STOCKAGE CIFS/SMB DETECTE"
        echo "    → Le repertoire est sur un partage Windows/Samba"
        IS_NFS="OUI (CIFS)"
        ;;
    ext4|ext3|xfs|btrfs)
        log_warn "STOCKAGE LOCAL DETECTE"
        echo "    → Le repertoire est sur un disque local"
        echo "    → Type: $FS_TYPE"
        IS_NFS="NON"
        ;;
    *)
        log_info "Type de filesystem: $FS_TYPE"
        IS_NFS="INCONNU"
        ;;
esac
echo ""

# ============================================================
# ETAPE 3 : DETAILS DU MONTAGE
# ============================================================
echo "${BLUE}[3/7] DETAILS DU MONTAGE${NC}"
echo "------------------------------------------------------------"

# Afficher le montage correspondant
echo "Montage actif :"
mount | grep -E "$FS_MOUNT|$TARGET_DIR" | head -3

echo ""
echo "Options de montage :"
mount | grep -E "$FS_MOUNT" | sed 's/.*(\(.*\))/\1/' | tr ',' '\n' | head -10
echo ""

# ============================================================
# ETAPE 4 : INFORMATIONS NFS DETAILLEES
# ============================================================
echo "${BLUE}[4/7] INFORMATIONS NFS DETAILLEES${NC}"
echo "------------------------------------------------------------"

if [ "$IS_NFS" = "OUI" ]; then
    # Extraire le serveur NAS
    NAS_SERVER=$(echo $FS_SOURCE | cut -d: -f1)

    echo "Serveur NAS     : $NAS_SERVER"

    # Test de connectivité
    if ping -c 1 -W 2 "$NAS_SERVER" > /dev/null 2>&1; then
        log_ok "Serveur NAS accessible (ping OK)"
    else
        log_warn "Ping vers $NAS_SERVER echoue (peut etre normal si ICMP bloque)"
    fi

    # Statistiques NFS (si nfsstat disponible)
    if command -v nfsstat > /dev/null 2>&1; then
        echo ""
        echo "Statistiques NFS (resume) :"
        nfsstat -c 2>/dev/null | head -10
    fi

    # Informations nfsiostat (si disponible)
    if command -v nfsiostat > /dev/null 2>&1; then
        echo ""
        echo "I/O NFS :"
        nfsiostat 1 1 2>/dev/null | head -15
    fi
else
    log_info "Pas de montage NFS detecte - etape ignoree"
fi
echo ""

# ============================================================
# ETAPE 5 : LISTE DES MONTAGES NFS SUR CE SERVEUR
# ============================================================
echo "${BLUE}[5/7] TOUS LES MONTAGES NFS SUR CE SERVEUR${NC}"
echo "------------------------------------------------------------"

NFS_MOUNTS=$(mount -t nfs,nfs4 2>/dev/null)
if [ -n "$NFS_MOUNTS" ]; then
    echo "$NFS_MOUNTS"
else
    log_info "Aucun montage NFS actif sur ce serveur"
fi
echo ""

# ============================================================
# ETAPE 6 : VERIFICATION FSTAB
# ============================================================
echo "${BLUE}[6/7] MONTAGES PERMANENTS (fstab)${NC}"
echo "------------------------------------------------------------"

if [ -f /etc/fstab ]; then
    echo "Montages NFS dans /etc/fstab :"
    grep -E "nfs|cifs" /etc/fstab 2>/dev/null | grep -v "^#" || echo "  Aucun montage NFS permanent"
else
    log_warn "/etc/fstab non accessible"
fi
echo ""

# ============================================================
# ETAPE 7 : TEST D'ECRITURE/LECTURE
# ============================================================
echo "${BLUE}[7/7] TEST D'ECRITURE/LECTURE${NC}"
echo "------------------------------------------------------------"

TEST_FILE="${TARGET_DIR}/test_nfs_diagnostic_$(hostname)_$$.txt"
TEST_CONTENT="Test NFS depuis $(hostname) - $(date)"

# Test d'écriture
echo "Test d'ecriture : $TEST_FILE"
if echo "$TEST_CONTENT" > "$TEST_FILE" 2>/dev/null; then
    log_ok "Ecriture reussie"

    # Test de lecture
    if [ -f "$TEST_FILE" ]; then
        READ_CONTENT=$(cat "$TEST_FILE" 2>/dev/null)
        if [ "$READ_CONTENT" = "$TEST_CONTENT" ]; then
            log_ok "Lecture reussie - contenu verifie"
        else
            log_warn "Lecture OK mais contenu different"
        fi
    fi

    # Nettoyage
    rm -f "$TEST_FILE" 2>/dev/null
    if [ ! -f "$TEST_FILE" ]; then
        log_ok "Suppression reussie"
    fi
else
    log_error "Echec de l'ecriture - verifier les permissions"
    ls -la "$TARGET_DIR" | head -5
fi
echo ""

# ============================================================
# RESUME
# ============================================================
echo "============================================================"
echo "   RESUME DU DIAGNOSTIC"
echo "============================================================"
echo ""
echo "Repertoire analyse : $TARGET_DIR"
echo "Type de stockage   : $FS_TYPE"
echo "Est NFS partage    : $IS_NFS"
echo "Source             : $FS_SOURCE"
echo "Point de montage   : $FS_MOUNT"
echo ""

if [ "$IS_NFS" = "OUI" ]; then
    echo "${GREEN}CONCLUSION : Ce repertoire est sur un stockage NFS partage.${NC}"
    echo ""
    echo "Le meme chemin ($TARGET_DIR) est accessible depuis :"
    echo "  - Le serveur BDD (pour UTL_FILE)"
    echo "  - Le serveur Applicatif (pour lire les fichiers)"
    echo ""
    echo "Les fichiers crees par UTL_FILE sont immediatement"
    echo "visibles sur tous les serveurs qui montent ce NFS."
else
    echo "${YELLOW}CONCLUSION : Ce repertoire est sur un stockage LOCAL.${NC}"
    echo ""
    echo "Les fichiers crees ici ne sont visibles que sur ce serveur."
    echo "Un mecanisme de transfert (SCP, SFTP, rsync) est necessaire"
    echo "pour les rendre accessibles ailleurs."
fi

echo ""
echo "============================================================"
echo "   FIN DU DIAGNOSTIC - $(date '+%H:%M:%S')"
echo "============================================================"
