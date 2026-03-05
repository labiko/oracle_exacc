#!/bin/ksh
# ============================================================
# DIAGNOSTIC GPG COMPLET - Analyse sans modification
# Date : 19/02/2026
# Usage : Copier-coller dans le terminal (meme dossier que le fichier)
# ============================================================

# ============================================================
# PARAMETRAGE - MODIFIER ICI LE NOM DU FICHIER
# ============================================================
FICHIER="ExtraitComptaGene_B1404071_RNA_RNACPT22.xml"
# ============================================================

echo "============================================================"
echo "         DIAGNOSTIC GPG COMPLET"
echo "============================================================"
echo "Fichier : $FICHIER"
echo "Date    : $(date '+%d/%m/%Y %H:%M:%S')"
echo "============================================================"
echo ""

# --- 1. INFO FICHIER ---
echo "=== 1. INFORMATIONS FICHIER ==="
ls -la "$FICHIER"
file "$FICHIER"
echo ""

# --- 2. CLES GPG DISPONIBLES ---
echo "=== 2. CLES GPG DISPONIBLES SUR LE SERVEUR ==="
gpg --list-keys --keyid-format long 2>/dev/null
echo ""
echo "--- Cles secretes ---"
gpg --list-secret-keys --keyid-format long 2>/dev/null
echo ""

# --- 3. ANALYSE HEXADECIMALE ---
echo "=== 3. ANALYSE HEXADECIMALE (premiers 64 octets) ==="
xxd "$FICHIER" | head -4
echo ""
echo "--- Derniers octets (fin de fichier) ---"
xxd "$FICHIER" | tail -3
echo ""

# --- 4. VERIFICATION EN-TETE GPG ---
echo "=== 4. VERIFICATION EN-TETE GPG ==="
PREMIER_OCTET=$(xxd -p -l 1 "$FICHIER")
echo "Premier octet : 0x$PREMIER_OCTET"
if [ "$PREMIER_OCTET" = "85" ] || [ "$PREMIER_OCTET" = "84" ] || [ "$PREMIER_OCTET" = "c6" ]; then
    echo "RESULTAT: En-tete GPG VALIDE"
else
    echo "RESULTAT: En-tete NON STANDARD (possible corruption ou octets parasites)"
    echo "En-tetes GPG attendus : 0x85, 0x84 ou 0xC6"
fi
echo ""

# --- 5. LECTURE PACKETS GPG ---
echo "=== 5. LECTURE PACKETS GPG ==="
gpg --list-packets "$FICHIER" 2>&1
echo ""

# --- 6. TENTATIVE DECHIFFREMENT (sans ecrire de fichier) ---
echo "=== 6. TENTATIVE DE DECHIFFREMENT ==="
gpg --decrypt "$FICHIER" 2>&1 | head -20
echo ""

# --- 7. TEST AVEC DIFFERENTS SKIP ---
echo "=== 7. TEST AVEC DIFFERENTS OFFSETS (skip 0-5) ==="
for skip in 0 1 2 3 4 5; do
    echo "--- Skip $skip octet(s) ---"
    dd if="$FICHIER" bs=1 skip=$skip 2>/dev/null | gpg --list-packets 2>&1 | head -3
done
echo ""

# --- 8. COMPARAISON AVEC AUTRES FICHIERS ---
echo "=== 8. AUTRES FICHIERS SIMILAIRES (meme pattern) ==="
ls -la $(echo "$FICHIER" | sed 's/_[^_]*$//')* 2>/dev/null || echo "Aucun autre fichier similaire"
echo ""

# --- RESUME ---
echo "============================================================"
echo "                    RESUME DIAGNOSTIC"
echo "============================================================"
echo ""
echo "1. Fichier         : $FICHIER"
echo "2. Taille          : $(ls -lh "$FICHIER" | awk '{print $5}')"
echo "3. Premier octet   : 0x$PREMIER_OCTET"
echo ""

# Determiner le statut
if gpg --list-packets "$FICHIER" 2>&1 | grep -q "encrypted"; then
    KEY_ID=$(gpg --list-packets "$FICHIER" 2>&1 | grep "keyid" | awk '{print $NF}' | head -1)
    echo "4. Statut GPG      : FICHIER RECONNU"
    echo "5. Key ID          : $KEY_ID"

    # Verifier si on a la cle
    if gpg --list-secret-keys "$KEY_ID" 2>/dev/null | grep -q "$KEY_ID"; then
        echo "6. Cle disponible  : OUI"
    else
        echo "6. Cle disponible  : NON (cle $KEY_ID manquante)"
    fi
else
    echo "4. Statut GPG      : FICHIER NON RECONNU"

    # Tester si un skip fonctionne
    for skip in 1 2 3 4 5; do
        if dd if="$FICHIER" bs=1 skip=$skip 2>/dev/null | gpg --list-packets 2>&1 | grep -q "encrypted"; then
            echo "5. Solution        : skip=$skip octets parasites au debut"
            echo "   Commande fix    : dd if=$FICHIER bs=1 skip=$skip | gpg --decrypt > output.xml"
            break
        fi
    done
fi

echo ""
echo "============================================================"
echo "FIN DIAGNOSTIC"
echo "============================================================"
