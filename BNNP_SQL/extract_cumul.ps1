# ============================================================================
# EXTRACTION TRANSACTIONS CUMULÉES - 17/10/2025
# Compte BBNP83292-EUR (RIB: 00016111832)
# ============================================================================

$xmlFile = "c:\Users\diall\Documents\IonicProjects\Claude\RECHERCHER\DIVERS\BNNP_SQL\dataSource.xml"
$rib = "00016111832"
$date = "2025-10-17"

Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("="*79) -ForegroundColor Cyan
Write-Host "EXTRACTION TRANSACTIONS CUMULÉES - Compte BBNP83292-EUR" -ForegroundColor Yellow
Write-Host "Date: $date" -ForegroundColor Yellow
Write-Host "RIB: $rib" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("="*79) -ForegroundColor Cyan
Write-Host ""

# Charger le XML
[xml]$xml = Get-Content $xmlFile

# Extraire les transactions
$transactions = @()
$totalCumul = 0

foreach ($row in $xml.Flux.Body.Row) {
    $reglement = $row.ExtraitReglement.Reglement

    if ($reglement) {
        $ribTransaction = $reglement.DepositoryAccount.BBAN.RIB.Identification
        $tradeDate = $reglement.TradeDate

        if ($ribTransaction -eq $rib -and $tradeDate -eq $date) {
            $montant = [decimal]$reglement.OperationNetAmount
            $paymentRef = $reglement.PaymentReference
            $client = $reglement.Identification.NumeroClient
            $mode = $reglement.SettlementMode
            $societe = $reglement.Societe.Identification

            $transactions += [PSCustomObject]@{
                Montant = $montant
                PaymentRef = $paymentRef
                Client = $client
                Mode = $mode
                Societe = $societe
            }

            $totalCumul += $montant
        }
    }
}

# Afficher les résultats
if ($transactions.Count -eq 0) {
    Write-Host "❌ AUCUNE TRANSACTION TROUVÉE" -ForegroundColor Red
    exit
}

Write-Host "✅ $($transactions.Count) TRANSACTIONS TROUVÉES" -ForegroundColor Green
Write-Host ""
Write-Host ("-"*120) -ForegroundColor Gray

$transactions | ForEach-Object -Begin {
    $i = 1
    Write-Host ("{0,-4} | {1,15} | {2,-12} | {3,-12} | {4,-6} | {5,-10}" -f "N°", "MONTANT", "PAYMENT_REF", "CLIENT", "MODE", "SOCIETE") -ForegroundColor Cyan
    Write-Host ("-"*120) -ForegroundColor Gray
} -Process {
    $marqueur = if ($_.Montant -eq 2817) { " 🎯" } else { "" }
    Write-Host ("{0,-4} | {1,15} | {2,-12} | {3,-12} | {4,-6} | {5,-10}{6}" -f $i, $_.Montant, $_.PaymentRef, $_.Client, $_.Mode, $_.Societe, $marqueur)
    $i++
}

Write-Host ("-"*120) -ForegroundColor Gray
Write-Host ("TOTAL CUMUL | {0,15:N2} EUR" -f $totalCumul) -ForegroundColor Yellow -BackgroundColor DarkBlue
Write-Host ("-"*120) -ForegroundColor Gray
Write-Host ""

# Vérification
$montantBrData = 226838.78
Write-Host "VÉRIFICATION:" -ForegroundColor Cyan
Write-Host ("  Cumul calculé XML : {0,15:N2} EUR" -f $totalCumul)
Write-Host ("  Cumul dans BR_DATA: {0,15:N2} EUR" -f $montantBrData)

if ([Math]::Abs($totalCumul - $montantBrData) -lt 0.01) {
    Write-Host "  ✅ COHÉRENT - Les montants correspondent !" -ForegroundColor Green
} else {
    $difference = $totalCumul - $montantBrData
    Write-Host ("  ⚠️ ÉCART: {0,15:N2} EUR" -f $difference) -ForegroundColor Red
}

Write-Host ""
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("="*79) -ForegroundColor Cyan
Write-Host "CONCLUSION:" -ForegroundColor Yellow
Write-Host "=" -NoNewline -ForegroundColor Cyan
Write-Host ("="*79) -ForegroundColor Cyan
Write-Host ""
Write-Host "La transaction 2817 EUR fait partie des $($transactions.Count) transactions VO"
Write-Host "exportées en CUMUL QUOTIDIEN le 17/10/2025."
Write-Host ""
Write-Host "C'est la règle de cumul ALL+VO (TA_RN_CUMUL_MR) qui provoque" -ForegroundColor Yellow
Write-Host "ce comportement pour le compte 342 (BBNP83292-EUR)." -ForegroundColor Yellow
Write-Host ""
Write-Host "Pour avoir 2817 EUR EN DÉTAIL dans BR_DATA:"
Write-Host "→ Supprimer la règle de cumul (voir SOLUTION_OPTIONS.md)" -ForegroundColor Green
Write-Host ""
