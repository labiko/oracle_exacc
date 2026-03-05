#!/bin/ksh
# ============================================================
# Script GPG Auto-Fix - Tentative automatique de reparation
# Date : 19/02/2026
# Usage : Copier-coller dans le terminal, modifier FICHIER=
# ============================================================
# Ce script essaie automatiquement differents offsets (0 a 10)
# pour trouver et corriger les octets parasites
# ============================================================

# ============================================================
# PARAMETRAGE - MODIFIER ICI LE NOM DU FICHIER
# ============================================================
FICHIER="ExtraitComptaGene_B1404071_RNA_RNACPT22.xml"
# ============================================================

BASENAME=$(echo "$FICHIER" | sed 's/\.xml$//' | sed 's/\.gpg$//')
DIRNAME="."

# Verification existence du fichier
if [ ! -f "$FICHIER" ]; then
    echo "ERREUR: Fichier '$FICHIER' introuvable"
    exit 1
fi

echo "============================================================"
echo "         GPG AUTO-FIX - REPARATION AUTOMATIQUE"
echo "============================================================"
echo "Fichier : $FICHIER"
echo "Date    : $(date '+%d/%m/%Y %H:%M:%S')"
echo "============================================================"
echo ""

# Test avec differents offsets
FOUND=0
for skip in 0 1 2 3 4 5 6 7 8 9 10; do
    echo "Test avec skip=$skip octets..."

    # Creer fichier temporaire
    TEMP_FILE="/tmp/gpg_test_skip${skip}.gpg"
    dd if="$FICHIER" bs=1 skip=$skip of="$TEMP_FILE" 2>/dev/null

    # Tester si GPG reconnait le fichier
    if gpg --list-packets "$TEMP_FILE" 2>&1 | grep -q "encrypted"; then
        echo ""
        echo "============================================================"
        echo "SOLUTION TROUVEE : skip=$skip octets"
        echo "============================================================"
        echo ""

        # Afficher les octets parasites
        echo "Octets parasites detectes :"
        xxd -l $skip "$FICHIER"
        echo ""

        # Creer le fichier corrige
        FICHIER_FIXED="${BASENAME}_FIXED.gpg"
        cp "$TEMP_FILE" "$FICHIER_FIXED"
        echo "Fichier corrige cree : $FICHIER_FIXED"
        echo ""

        # Tenter le dechiffrement
        echo "Tentative de dechiffrement..."
        FICHIER_OUTPUT="${BASENAME}_DECRYPTED.xml"
        gpg --decrypt "$FICHIER_FIXED" > "$FICHIER_OUTPUT" 2>&1

        if [ $? -eq 0 ]; then
            echo ""
            echo "============================================================"
            echo "DECHIFFREMENT REUSSI !"
            echo "============================================================"
            echo "Fichier de sortie : $FICHIER_OUTPUT"
            echo "Taille            : $(ls -lh "$FICHIER_OUTPUT" | awk '{print $5}')"
            echo ""
            echo "Apercu :"
            head -5 "$FICHIER_OUTPUT"
            FOUND=1
        else
            echo ""
            echo "Le fichier est reconnu mais le dechiffrement a echoue"
            echo "Erreur GPG :"
            gpg --decrypt "$FICHIER_FIXED" 2>&1 | tail -5
        fi

        # Nettoyer
        rm -f "$TEMP_FILE"
        break
    fi

    rm -f "$TEMP_FILE"
done

if [ $FOUND -eq 0 ]; then
    echo ""
    echo "============================================================"
    echo "AUCUNE SOLUTION TROUVEE (skip 0-10)"
    echo "============================================================"
    echo ""
    echo "Causes possibles :"
    echo "  1. Ce n'est pas un fichier GPG valide"
    echo "  2. Le fichier est completement corrompu"
    echo "  3. Plus de 10 octets parasites au debut"
    echo ""
    echo "Actions recommandees :"
    echo "  - Verifier le format du fichier avec 'file $FICHIER'"
    echo "  - Demander le renvoi du fichier a l'emetteur"
    echo "  - Verifier les logs de transfert SFTP/FTP"
fi

echo ""
echo "============================================================"
echo "FIN DU TRAITEMENT"
echo "============================================================"
