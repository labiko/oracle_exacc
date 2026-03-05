#!/bin/ksh
# ============================================================
# Script de correction GPG - Suppression octets parasites
# Date : 19/02/2026
# Usage : ./fix_gpg_prefix.ksh <fichier_gpg> <nb_octets_skip>
# ============================================================
# Ce script supprime les N premiers octets d'un fichier GPG
# corrompu et tente le dechiffrement
# ============================================================

# Verification des arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <fichier_gpg> <nb_octets_skip>"
    echo "Exemple: $0 ExtraitComptaGene.xml 2"
    exit 1
fi

FICHIER="$1"
SKIP="$2"
FICHIER_FIXED="${FICHIER%.xml}_FIXED.gpg"
FICHIER_OUTPUT="${FICHIER%.xml}_DECRYPTED.xml"

# Verification existence du fichier
if [ ! -f "$FICHIER" ]; then
    echo "ERREUR: Fichier '$FICHIER' introuvable"
    exit 1
fi

echo "============================================================"
echo "         FIX GPG - SUPPRESSION OCTETS PARASITES"
echo "============================================================"
echo "Fichier source   : $FICHIER"
echo "Octets a sauter  : $SKIP"
echo "Fichier corrige  : $FICHIER_FIXED"
echo "Fichier sortie   : $FICHIER_OUTPUT"
echo "============================================================"
echo ""

# Etape 1 : Afficher les octets qui seront supprimes
echo "[1/4] Octets qui seront supprimes :"
xxd -l $SKIP "$FICHIER"
echo ""

# Etape 2 : Creer le fichier corrige
echo "[2/4] Creation du fichier corrige..."
dd if="$FICHIER" bs=1 skip=$SKIP of="$FICHIER_FIXED" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "OK - Fichier $FICHIER_FIXED cree"
    echo "Taille originale : $(ls -lh "$FICHIER" | awk '{print $5}')"
    echo "Taille corrigee  : $(ls -lh "$FICHIER_FIXED" | awk '{print $5}')"
else
    echo "ERREUR lors de la creation du fichier corrige"
    exit 1
fi
echo ""

# Etape 3 : Verification du nouveau fichier
echo "[3/4] Verification du fichier corrige..."
echo "Nouveaux premiers octets :"
xxd "$FICHIER_FIXED" | head -2
echo ""

gpg --list-packets "$FICHIER_FIXED" 2>&1 | head -5
echo ""

# Etape 4 : Tentative de dechiffrement
echo "[4/4] Tentative de dechiffrement..."
gpg --decrypt "$FICHIER_FIXED" > "$FICHIER_OUTPUT" 2>&1

RESULT=$?
if [ $RESULT -eq 0 ]; then
    echo ""
    echo "============================================================"
    echo "SUCCES - Fichier dechiffre avec succes !"
    echo "============================================================"
    echo "Fichier de sortie : $FICHIER_OUTPUT"
    echo "Taille            : $(ls -lh "$FICHIER_OUTPUT" | awk '{print $5}')"
    echo ""
    echo "Apercu du contenu :"
    head -5 "$FICHIER_OUTPUT"
else
    echo ""
    echo "============================================================"
    echo "ECHEC - Le dechiffrement a echoue"
    echo "============================================================"
    echo "Causes possibles :"
    echo "  - Nombre d'octets a sauter incorrect"
    echo "  - Fichier corrompu (pas seulement au debut)"
    echo "  - Cle GPG manquante"
    echo ""
    echo "Essayez avec un autre nombre d'octets :"
    echo "  $0 $FICHIER 1"
    echo "  $0 $FICHIER 3"
    echo "  $0 $FICHIER 4"
fi
