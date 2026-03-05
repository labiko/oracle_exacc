#!/bin/ksh
# ============================================================
# Script de diagnostic GPG - Analyse fichiers chiffres
# Date : 19/02/2026
# Usage : ./diagnostic_gpg.ksh <fichier_gpg>
# ============================================================
# Ce script permet de diagnostiquer si un fichier GPG est :
#   - Corrompu (octets parasites au debut)
#   - Chiffre avec une cle inconnue
#   - Tronque ou incomplet
# ============================================================

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verification des arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <fichier_gpg>"
    echo "Exemple: $0 ExtraitComptaGene_B1404071.xml"
    exit 1
fi

FICHIER="$1"

# Verification existence du fichier
if [ ! -f "$FICHIER" ]; then
    echo "${RED}ERREUR: Fichier '$FICHIER' introuvable${NC}"
    exit 1
fi

echo "============================================================"
echo "         DIAGNOSTIC GPG - $(date '+%d/%m/%Y %H:%M:%S')"
echo "============================================================"
echo "Fichier analyse : $FICHIER"
echo "Taille          : $(ls -lh "$FICHIER" | awk '{print $5}')"
echo "============================================================"
echo ""

# ============================================================
# ETAPE 1 : Verification des cles GPG disponibles
# ============================================================
echo "${BLUE}[1/6] CLES GPG DISPONIBLES${NC}"
echo "------------------------------------------------------------"
gpg --list-keys 2>/dev/null | head -20
echo ""
echo "Sous-cles de chiffrement :"
gpg --list-keys --keyid-format long 2>/dev/null | grep -E "^\s+[0-9A-F]{16}" | head -10
echo ""

# ============================================================
# ETAPE 2 : Analyse hexadecimale des premiers octets
# ============================================================
echo "${BLUE}[2/6] ANALYSE HEXADECIMALE (premiers 64 octets)${NC}"
echo "------------------------------------------------------------"
xxd "$FICHIER" | head -4
echo ""

# Verification de l'en-tete GPG standard
PREMIER_OCTET=$(xxd -p -l 1 "$FICHIER")
echo "Premier octet : 0x$PREMIER_OCTET"

if [ "$PREMIER_OCTET" = "85" ] || [ "$PREMIER_OCTET" = "84" ] || [ "$PREMIER_OCTET" = "c6" ]; then
    echo "${GREEN}En-tete GPG valide detecte${NC}"
else
    echo "${YELLOW}ATTENTION: En-tete non standard - possible corruption${NC}"
    echo "En-tete GPG attendu : 0x85, 0x84 ou 0xC6"
fi
echo ""

# ============================================================
# ETAPE 3 : Tentative de lecture des packets GPG
# ============================================================
echo "${BLUE}[3/6] LECTURE DES PACKETS GPG${NC}"
echo "------------------------------------------------------------"
gpg --list-packets "$FICHIER" 2>&1 | head -15

GPG_RESULT=$?
if [ $GPG_RESULT -ne 0 ]; then
    echo ""
    echo "${YELLOW}ATTENTION: Erreur lors de la lecture des packets${NC}"
fi
echo ""

# ============================================================
# ETAPE 4 : Test de dechiffrement (dry-run)
# ============================================================
echo "${BLUE}[4/6] TEST DE DECHIFFREMENT${NC}"
echo "------------------------------------------------------------"
gpg --decrypt "$FICHIER" 2>&1 | head -10

echo ""

# ============================================================
# ETAPE 5 : Test avec differents offsets (skip)
# ============================================================
echo "${BLUE}[5/6] TEST AVEC DIFFERENTS OFFSETS (skip octets)${NC}"
echo "------------------------------------------------------------"
echo "Test si des octets parasites sont presents au debut..."
echo ""

for skip in 0 1 2 3 4 5 10; do
    echo "--- Skip $skip octet(s) ---"
    RESULT=$(dd if="$FICHIER" bs=1 skip=$skip 2>/dev/null | gpg --list-packets 2>&1 | head -3)
    if echo "$RESULT" | grep -q "encrypted"; then
        echo "${GREEN}SUCCES avec skip=$skip${NC}"
        echo "$RESULT"
        echo ""
        echo "${GREEN}>>> SOLUTION: Utiliser 'dd if=$FICHIER bs=1 skip=$skip | gpg --decrypt > output.xml'${NC}"
        break
    else
        echo "Echec avec skip=$skip"
    fi
done
echo ""

# ============================================================
# ETAPE 6 : Verification de la fin du fichier
# ============================================================
echo "${BLUE}[6/6] VERIFICATION FIN DE FICHIER${NC}"
echo "------------------------------------------------------------"
echo "Derniers octets du fichier :"
xxd "$FICHIER" | tail -3
echo ""

# ============================================================
# RESUME ET RECOMMANDATIONS
# ============================================================
echo "============================================================"
echo "                    RESUME DIAGNOSTIC"
echo "============================================================"

# Verifier si le fichier est reconnu
if gpg --list-packets "$FICHIER" 2>&1 | grep -q "encrypted"; then
    echo "${GREEN}[OK] Fichier reconnu comme GPG${NC}"
    KEY_ID=$(gpg --list-packets "$FICHIER" 2>&1 | grep "keyid" | head -1 | awk '{print $NF}')
    echo "     Key ID : $KEY_ID"

    # Verifier si on a la cle
    if gpg --list-keys "$KEY_ID" 2>/dev/null | grep -q "$KEY_ID"; then
        echo "${GREEN}[OK] Cle disponible dans le trousseau${NC}"
    else
        echo "${RED}[ERREUR] Cle $KEY_ID non trouvee dans le trousseau${NC}"
        echo "     -> Importer la cle avec : gpg --import <fichier_cle>"
    fi
else
    echo "${RED}[ERREUR] Fichier non reconnu comme GPG valide${NC}"
    echo "     Causes possibles :"
    echo "     - Octets parasites au debut (essayer avec skip)"
    echo "     - Fichier corrompu ou tronque"
    echo "     - Ce n'est pas un fichier GPG"
fi

echo ""
echo "============================================================"
echo "FIN DU DIAGNOSTIC"
echo "============================================================"
