# ============================================================================
# POWERSHELL - Recherche insertion BR_DATA dans scripts SQL
# ============================================================================
# Date: 07/02/2026
# Objectif: Trouver tous les scripts SQL qui insèrent dans BR_DATA
# Usage: .\GREP_RECHERCHE_INSERTION_BR_DATA.ps1
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "1. RECHERCHE : Scripts SQL qui référencent BR_DATA" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Select-String -Path "*.sql" -Pattern "BR_DATA" -CaseSensitive | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "2. RECHERCHE : Scripts SQL avec INSERT INTO BR_DATA" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Select-String -Path "*.sql" -Pattern "INSERT.*BR_DATA" -CaseSensitive | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "3. RECHERCHE : Scripts SQL avec TA_RN_IMPORT_GESTION_JC" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Select-String -Path "*.sql" -Pattern "TA_RN_IMPORT_GESTION_JC" -CaseSensitive | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "4. RECHERCHE : Scripts qui référencent LES DEUX tables" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "Fichiers contenant TA_RN_IMPORT_GESTION_JC ET BR_DATA..." -ForegroundColor Yellow

$filesWithImport = Select-String -Path "*.sql" -Pattern "TA_RN_IMPORT_GESTION_JC" | Select-Object -ExpandProperty Path -Unique
$filesWithBoth = $filesWithImport | Where-Object {
    (Select-String -Path $_ -Pattern "BR_DATA" -Quiet)
}

foreach ($file in $filesWithBoth) {
    Write-Host "  → $file" -ForegroundColor Green
    Select-String -Path $file -Pattern "INSERT.*BR_DATA|TA_RN_IMPORT" | Format-Table -AutoSize
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "5. RECHERCHE : Scripts avec TYPE_RAPPRO" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Select-String -Path "*.sql" -Pattern "TYPE_RAPPRO" -CaseSensitive | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "6. RECHERCHE : Scripts avec TYPE_RAPPRO='B' (spécifiquement)" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Select-String -Path "*.sql" -Pattern "TYPE_RAPPRO.*=.*'B'" -CaseSensitive | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "7. RECHERCHE : Scripts avec COMPTE_ACCURATE (ID 394 ou 342)" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Select-String -Path "*.sql" -Pattern "(394|342).*COMPTE_ACCURATE|COMPTE_ACCURATE.*(394|342)" | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "8. LISTE : Tous les fichiers .sql dans le répertoire" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Get-ChildItem -Path . -Filter "*.sql" -Recurse | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "9. RECHERCHE : Package bodies (.pkb) qui référencent BR_DATA" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
if (Test-Path "*.pkb") {
    Select-String -Path "*.pkb" -Pattern "BR_DATA" -CaseSensitive | Format-Table -AutoSize
} else {
    Write-Host "  Aucun fichier .pkb trouvé" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "10. RECHERCHE : Procédures (.prc) qui référencent BR_DATA" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
if (Test-Path "*.prc") {
    Select-String -Path "*.prc" -Pattern "BR_DATA" -CaseSensitive | Format-Table -AutoSize
} else {
    Write-Host "  Aucun fichier .prc trouvé" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "11. RECHERCHE AVANCÉE : INSERT dans BR_DATA avec contexte" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Select-String -Path "*.sql" -Pattern "INSERT.*INTO.*BR_DATA" -Context 5,5 -CaseSensitive

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "12. RECHERCHE : Scripts avec DB_LINK" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Select-String -Path "*.sql" -Pattern "DB_LINK|@[A-Z0-9_]+" -CaseSensitive | Format-Table -AutoSize

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "RÉSUMÉ - COMMANDES POWERSHELL UTILES" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "# Recherche simple" -ForegroundColor Yellow
Write-Host 'Select-String -Path "*.sql" -Pattern "BR_DATA"' -ForegroundColor White
Write-Host ""
Write-Host "# Recherche avec contexte (5 lignes avant/après)" -ForegroundColor Yellow
Write-Host 'Select-String -Path "*.sql" -Pattern "INSERT.*BR_DATA" -Context 5,5' -ForegroundColor White
Write-Host ""
Write-Host "# Recherche case-insensitive" -ForegroundColor Yellow
Write-Host 'Select-String -Path "*.sql" -Pattern "br_data"' -ForegroundColor White
Write-Host ""
Write-Host "# Exporter les résultats dans un fichier" -ForegroundColor Yellow
Write-Host 'Select-String -Path "*.sql" -Pattern "BR_DATA" | Out-File resultats.txt' -ForegroundColor White
Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
