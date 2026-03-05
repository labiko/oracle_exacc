# ============================================================================
# CHERCHER INSERT DANS SCRIPTS SQL - Identifier les tables cibles
# ============================================================================
# Date: 07/02/2026
# Objectif: Trouver tous les INSERT dans les scripts SQL d'intégration
# Usage: .\CHERCHER_INSERT_DANS_SCRIPTS.ps1
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "RECHERCHE DES INSERT DANS LES SCRIPTS SQL D'INTÉGRATION" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Définir les scripts d'intégration à analyser
$scripts = @(
    "RNADGENJUCGES01.sql",
    "RNADGENJUCGES01_WITH_LOGS.sql"
)

$allInserts = @()

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "Analyse de $script..." -ForegroundColor Yellow
        Write-Host "---------------------------------------------------" -ForegroundColor Gray

        # Chercher INSERT INTO
        $insertLines = Select-String -Path $script -Pattern "INSERT\s+INTO\s+(\w+)" -AllMatches

        foreach ($line in $insertLines) {
            # Extraire le nom de la table
            if ($line.Line -match "INSERT\s+INTO\s+([A-Z_0-9\.]+)") {
                $tableName = $matches[1]

                $insertInfo = [PSCustomObject]@{
                    Script = $script
                    Ligne = $line.LineNumber
                    Table = $tableName
                    Contexte = $line.Line.Trim()
                }

                $allInserts += $insertInfo

                Write-Host "  Ligne $($line.LineNumber): INSERT INTO $tableName" -ForegroundColor Green
            }
        }
        Write-Host ""
    } else {
        Write-Host "⚠️  Fichier non trouvé: $script" -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "RÉSUMÉ DES TABLES CIBLES" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan

# Grouper par table
$groupedTables = $allInserts | Group-Object -Property Table | Sort-Object Name

foreach ($group in $groupedTables) {
    Write-Host ""
    Write-Host "📊 TABLE: $($group.Name)" -ForegroundColor Yellow
    Write-Host "   Nombre d'insertions: $($group.Count)" -ForegroundColor White

    foreach ($insert in $group.Group) {
        Write-Host "   → $($insert.Script):$($insert.Ligne)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "RECHERCHE SPÉCIFIQUE: INSERT avec AMOUNT ou PAYMENTREFERENCE" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "Dans $script :" -ForegroundColor Yellow

        # Chercher les INSERT qui mentionnent AMOUNT ou PAYMENTREFERENCE
        $amountInserts = Select-String -Path $script -Pattern "INSERT.*AMOUNT|INSERT.*PAYMENTREFERENCE" -Context 2,5

        if ($amountInserts) {
            foreach ($match in $amountInserts) {
                Write-Host "  Ligne $($match.LineNumber):" -ForegroundColor Green
                Write-Host "    $($match.Line)" -ForegroundColor White
                Write-Host ""
            }
        } else {
            Write-Host "  Aucune insertion de AMOUNT ou PAYMENTREFERENCE trouvée" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "RECHERCHE: Références à BR_DATA" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($script in $scripts) {
    if (Test-Path $script) {
        $brDataRefs = Select-String -Path $script -Pattern "BR_DATA" -Context 1,3

        if ($brDataRefs) {
            Write-Host "Dans $script : $($brDataRefs.Count) références" -ForegroundColor Yellow
            foreach ($ref in $brDataRefs) {
                Write-Host "  Ligne $($ref.LineNumber): $($ref.Line.Trim())" -ForegroundColor White
            }
        } else {
            Write-Host "$script : Aucune référence à BR_DATA" -ForegroundColor Gray
        }
        Write-Host ""
    }
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "EXPORT DES RÉSULTATS" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green

# Exporter dans un fichier CSV
$csvPath = "INSERT_ANALYSIS_RESULTS.csv"
$allInserts | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Résultats exportés dans: $csvPath" -ForegroundColor Yellow

# Créer un rapport texte
$reportPath = "INSERT_ANALYSIS_REPORT.txt"
$report = @"
============================================================================
RAPPORT D'ANALYSE DES INSERT - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
============================================================================

TABLES CIBLES IDENTIFIÉES:
--------------------------
$($groupedTables | ForEach-Object { "- $($_.Name) ($($_.Count) insertions)" } | Out-String)

DÉTAIL PAR SCRIPT:
------------------
$($allInserts | ForEach-Object { "$($_.Script):$($_.Ligne) → $($_.Table)" } | Out-String)

PROCHAINES ÉTAPES:
------------------
1. Exécuter TRACER_PAYMENTREFERENCE_22.36_vs_2817.sql pour tracer les données
2. Vérifier dans quelle table le PAYMENTREFERENCE de 22.36 est présent mais pas celui de 2817
3. Analyser la condition WHERE du INSERT dans cette table

HYPOTHÈSE:
----------
Si 22.36 est dans BR_DATA mais pas 2817, le filtrage se fait soit :
- Dans la condition WHERE du INSERT INTO BR_DATA
- Via un paramétrage dans TA_RN_GESTION_JC (compte accurate)
- Dans un package PL/SQL intermédiaire

============================================================================
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Rapport détaillé créé: $reportPath" -ForegroundColor Yellow

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Green
Write-Host "ANALYSE TERMINÉE ✅" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
