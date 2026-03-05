#!/bin/bash
# ============================================================================
# GREP - Recherche insertion BR_DATA dans scripts SQL
# ============================================================================
# Date: 07/02/2026
# Objectif: Trouver tous les scripts SQL qui insèrent dans BR_DATA
# ============================================================================

echo "============================================================================"
echo "1. RECHERCHE : Scripts SQL qui référencent BR_DATA"
echo "============================================================================"
grep -rn "BR_DATA" . --include="*.sql" --color=always

echo ""
echo "============================================================================"
echo "2. RECHERCHE : Scripts SQL avec INSERT INTO BR_DATA"
echo "============================================================================"
grep -rn "INSERT.*BR_DATA" . --include="*.sql" --color=always

echo ""
echo "============================================================================"
echo "3. RECHERCHE : Scripts SQL avec TA_RN_IMPORT_GESTION_JC"
echo "============================================================================"
grep -rn "TA_RN_IMPORT_GESTION_JC" . --include="*.sql" --color=always

echo ""
echo "============================================================================"
echo "4. RECHERCHE : Scripts qui référencent LES DEUX tables"
echo "============================================================================"
echo "Recherche de fichiers contenant TA_RN_IMPORT_GESTION_JC ET BR_DATA..."
grep -l "TA_RN_IMPORT_GESTION_JC" *.sql 2>/dev/null | xargs grep -l "BR_DATA" 2>/dev/null

echo ""
echo "============================================================================"
echo "5. RECHERCHE : Scripts avec TYPE_RAPPRO"
echo "============================================================================"
grep -rn "TYPE_RAPPRO" . --include="*.sql" --color=always

echo ""
echo "============================================================================"
echo "6. RECHERCHE : Scripts avec TYPE_RAPPRO='B' (spécifiquement)"
echo "============================================================================"
grep -rn "TYPE_RAPPRO.*[=].*'B'" . --include="*.sql" --color=always

echo ""
echo "============================================================================"
echo "7. RECHERCHE : Scripts avec COMPTE_ACCURATE (ID 394 ou 342)"
echo "============================================================================"
grep -rn -E "(394|342).*COMPTE_ACCURATE|COMPTE_ACCURATE.*(394|342)" . --include="*.sql" --color=always

echo ""
echo "============================================================================"
echo "8. LISTE : Tous les fichiers .sql dans le répertoire"
echo "============================================================================"
find . -name "*.sql" -type f | sort

echo ""
echo "============================================================================"
echo "9. RECHERCHE : Package bodies (.pkb) qui référencent BR_DATA"
echo "============================================================================"
grep -rn "BR_DATA" . --include="*.pkb" --color=always 2>/dev/null

echo ""
echo "============================================================================"
echo "10. RECHERCHE : Procédures (.prc) qui référencent BR_DATA"
echo "============================================================================"
grep -rn "BR_DATA" . --include="*.prc" --color=always 2>/dev/null

echo ""
echo "============================================================================"
echo "11. RECHERCHE AVANCÉE : INSERT dans BR_DATA avec contexte (5 lignes)"
echo "============================================================================"
grep -rn -A 5 -B 5 "INSERT.*INTO.*BR_DATA" . --include="*.sql" --color=always

echo ""
echo "============================================================================"
echo "12. RECHERCHE : Scripts avec DB_LINK"
echo "============================================================================"
grep -rn "DB_LINK\|@[A-Z0-9_]*" . --include="*.sql" --color=always

echo ""
echo "============================================================================"
echo "RÉSUMÉ"
echo "============================================================================"
echo "Pour exécuter ces commandes individuellement :"
echo ""
echo "  # Recherche simple"
echo "  grep -rn 'BR_DATA' . --include='*.sql'"
echo ""
echo "  # Recherche avec contexte"
echo "  grep -rn -A 10 -B 10 'INSERT.*BR_DATA' . --include='*.sql'"
echo ""
echo "  # Recherche dans fichiers spécifiques"
echo "  grep -l 'TA_RN_IMPORT_GESTION_JC' *.sql | xargs grep -n 'BR_DATA'"
echo ""
echo "  # Recherche case-insensitive"
echo "  grep -rni 'br_data' . --include='*.sql'"
echo ""
echo "============================================================================"
