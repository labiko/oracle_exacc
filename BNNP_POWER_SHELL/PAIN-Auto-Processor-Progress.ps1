##############################################
# Script PowerShell : PAIN-Auto-Processor-Progress.ps1
# Version avec affichage de progression en temps reel
# Traitement automatique de fichiers PAIN.001 / PAIN.008
##############################################

##############################################
# Configuration
##############################################
$BASE_DIR = "C:\DISQUED\TEMP\PAIN-TRANSFORMER"
$PROGRESS_INTERVAL = 500  # Afficher progression toutes les N transactions

##############################################
# Demande du numero de ticket
##############################################
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  PAIN Auto Processor (Progress)" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$ticket = Read-Host "Entrez le numero de ticket (ex: AER_ITFIN-12345)"

if ([string]::IsNullOrWhiteSpace($ticket)) {
    Write-Host "ERREUR : Numero de ticket requis" -ForegroundColor Red
    exit 1
}

##############################################
# Construction du chemin du dossier ticket
##############################################
$ticketDir = Join-Path $BASE_DIR $ticket

if (-not (Test-Path $ticketDir -PathType Container)) {
    Write-Host "ERREUR : Le dossier '$ticketDir' n'existe pas" -ForegroundColor Red
    exit 1
}

##############################################
# Recherche du fichier PAIN
##############################################
Write-Host "`nRecherche du fichier PAIN dans : $ticketDir" -ForegroundColor Yellow

$painFile = Get-ChildItem -Path $ticketDir -Filter "pain08*.xml" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $painFile) {
    $painFile = Get-ChildItem -Path $ticketDir -Filter "pain01*.xml" -File -ErrorAction SilentlyContinue | Select-Object -First 1
}
if (-not $painFile) {
    $painFile = Get-ChildItem -Path $ticketDir -Filter "*.xml" -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

if (-not $painFile) {
    Write-Host "ERREUR : Aucun fichier XML trouve dans $ticketDir" -ForegroundColor Red
    exit 1
}

Write-Host "Fichier trouve : $($painFile.Name)" -ForegroundColor Green

##############################################
# Creation du repertoire de sortie
##############################################
$outputDir = Join-Path $ticketDir "OUTPUT"
$null = New-Item -ItemType Directory -Path $outputDir -Force
Write-Host "Repertoire de sortie : $outputDir`n" -ForegroundColor Green

##############################################
# Chargement du XML
##############################################
Write-Host "Chargement du fichier XML..." -ForegroundColor Yellow
$loadStart = Get-Date

$xml = [System.Xml.XmlDocument]::new()
$xml.PreserveWhitespace = $false

try {
    $xml.Load($painFile.FullName)
} catch {
    Write-Host "ERREUR : Impossible de charger le fichier XML" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

$loadTime = (Get-Date) - $loadStart
Write-Host "XML charge en $($loadTime.TotalSeconds.ToString('F2')) secondes" -ForegroundColor Green

##############################################
# Detection namespace
##############################################
$nsUri = $xml.DocumentElement.NamespaceURI

if ([string]::IsNullOrWhiteSpace($nsUri)) {
    Write-Host "ERREUR : Aucun namespace trouve" -ForegroundColor Red
    exit 1
}

Write-Host "Namespace : $nsUri" -ForegroundColor Green

$nsmgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
$nsmgr.AddNamespace("ns", $nsUri)

##############################################
# Detection du type PAIN
##############################################
switch -Wildcard ($nsUri) {
    "*pain.001*" {
        $initNode = "CstmrCdtTrfInitn"
        $txTag = "CdtTrfTxInf"
        Write-Host "Type : PAIN.001 (Virement)" -ForegroundColor Cyan
    }
    "*pain.008*" {
        $initNode = "CstmrDrctDbtInitn"
        $txTag = "DrctDbtTxInf"
        Write-Host "Type : PAIN.008 (Prelevement)" -ForegroundColor Cyan
    }
    default {
        Write-Host "ERREUR : Namespace non supporte" -ForegroundColor Red
        exit 1
    }
}

##############################################
# Compteurs globaux
##############################################
[int]$total_pmtinf = 0
[int]$total_transactions = 0
$scriptStart = Get-Date

##############################################
# Recuperation des blocs PmtInf
##############################################
$root = $xml.SelectSingleNode("//ns:$initNode", $nsmgr)
if (-not $root) {
    Write-Host "ERREUR : Noeud racine '$initNode' introuvable" -ForegroundColor Red
    exit 1
}

$payment_infos = $root.SelectNodes(".//ns:PmtInf", $nsmgr)
$pmtInfCount = $payment_infos.Count

if ($pmtInfCount -eq 0) {
    Write-Host "ATTENTION : Aucun bloc PmtInf trouve" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host "  DEBUT TRAITEMENT : $pmtInfCount bloc(s) PmtInf" -ForegroundColor Magenta
Write-Host "=============================================" -ForegroundColor Magenta
Write-Host ""

##############################################
# Traitement de chaque bloc PmtInf
##############################################
[int]$pmtInfIndex = 0

foreach ($payment_info in $payment_infos) {

    $pmtInfIndex++
    $blockStart = Get-Date

    ##############################################
    # Infos du bloc PmtInf
    ##############################################
    $node = $payment_info.SelectSingleNode("ns:PmtInfId", $nsmgr)
    $pmtinf_id = if ($node) { $node.InnerText.Trim() } else { "UNKNOWN" }

    $node = $payment_info.SelectSingleNode("ns:PmtMtd", $nsmgr)
    $pmtmtd = if ($node) { $node.InnerText.Trim() } else { "" }

    $node = $payment_info.SelectSingleNode("ns:NbOfTxs", $nsmgr)
    $nb_of_txs = if ($node) { $node.InnerText.Trim() } else { "0" }

    $node = $payment_info.SelectSingleNode("ns:CtrlSum", $nsmgr)
    $ctrl_sum = if ($node) { $node.InnerText.Trim() } else { "0" }

    $total_pmtinf++

    ##############################################
    # Affichage debut du bloc
    ##############################################
    Write-Host "[$pmtInfIndex/$pmtInfCount] Bloc: $pmtinf_id ($nb_of_txs transactions attendues)" -ForegroundColor Yellow

    ##############################################
    # Collection des transactions
    ##############################################
    $transactions = [System.Collections.Generic.List[PSCustomObject]]::new()
    $tx_nodes = $payment_info.SelectNodes(".//ns:$txTag", $nsmgr)
    $txTotal = $tx_nodes.Count
    [int]$txProcessed = 0

    ##############################################
    # Boucle de traitement avec progression
    ##############################################
    foreach ($tx in $tx_nodes) {

        $txProcessed++

        # Reference de transaction
        $node = $tx.SelectSingleNode("ns:PmtId/ns:EndToEndId", $nsmgr)
        $end_to_end_id = if ($node) { $node.InnerText.Trim() } else { "" }

        # Montant et devise
        $amount_node = $tx.SelectSingleNode(".//ns:InstdAmt", $nsmgr)
        if ($amount_node) {
            $amount = $amount_node.InnerText -replace '\.', ','
            $currency = $amount_node.GetAttribute("Ccy")
        } else {
            $amount = ""
            $currency = "EUR"
        }

        # Debiteur
        $node = $tx.SelectSingleNode("ns:Dbtr/ns:Nm", $nsmgr)
        $debtor_name = if ($node) { $node.InnerText.Trim() } else { "" }

        $node = $tx.SelectSingleNode("ns:DbtrAcct/ns:Id/ns:IBAN", $nsmgr)
        $debtor_iban = if ($node) { $node.InnerText.Trim() } else { "" }

        # Creancier
        $node = $tx.SelectSingleNode("ns:Cdtr/ns:Nm", $nsmgr)
        $creditor_name = if ($node) { $node.InnerText.Trim() } else { "" }

        $node = $tx.SelectSingleNode("ns:CdtrAcct/ns:Id/ns:IBAN", $nsmgr)
        $creditor_iban = if ($node) { $node.InnerText.Trim() } else { "" }

        # Reference de remise
        $node = $tx.SelectSingleNode("ns:RmtInf/ns:Ustrd", $nsmgr)
        $remittance_info = if ($node) { $node.InnerText.Trim() } else { "" }

        # Ajout a la collection
        $transactions.Add([PSCustomObject]@{
            PmtInfId              = $pmtinf_id
            "Reference Paiement"  = $end_to_end_id
            Montant               = $amount
            Devise                = $currency
            Debiteur              = $debtor_name
            "IBAN Debiteur"       = $debtor_iban
            Creancier             = $creditor_name
            "IBAN Creancier"      = $creditor_iban
            "Reference Remise"    = $remittance_info
        })

        ##############################################
        # Affichage progression (toutes les N transactions)
        ##############################################
        if ($txProcessed % $PROGRESS_INTERVAL -eq 0) {
            $percent = [math]::Round(($txProcessed / $txTotal) * 100, 1)
            $elapsed = ((Get-Date) - $blockStart).TotalSeconds
            $speed = [math]::Round($txProcessed / $elapsed, 0)
            $remaining = if ($speed -gt 0) { [math]::Round(($txTotal - $txProcessed) / $speed, 0) } else { "?" }

            Write-Host "    -> $txProcessed / $txTotal ($percent%) | Vitesse: $speed tx/s | Reste: ~${remaining}s" -ForegroundColor DarkGray

            # Barre de progression PowerShell
            Write-Progress -Activity "Bloc $pmtInfIndex/$pmtInfCount : $pmtinf_id" `
                           -Status "$txProcessed / $txTotal transactions ($percent%)" `
                           -PercentComplete $percent `
                           -CurrentOperation "Vitesse: $speed tx/s - Temps restant: ~${remaining}s"
        }
    }

    # Fermer la barre de progression pour ce bloc
    Write-Progress -Activity "Bloc $pmtInfIndex/$pmtInfCount : $pmtinf_id" -Completed

    ##############################################
    # Export CSV
    ##############################################
    $txCount = $transactions.Count
    $total_transactions += $txCount
    $blockTime = ((Get-Date) - $blockStart).TotalSeconds

    if ($txCount -gt 0) {
        $output_file = Join-Path $outputDir "$pmtinf_id-$pmtmtd-$nb_of_txs-$ctrl_sum.csv"
        $transactions | Export-Csv -Path $output_file -NoTypeInformation -Encoding Default -Delimiter ";"

        $fileName = Split-Path $output_file -Leaf
        Write-Host "[OK] $txCount transaction(s) en $($blockTime.ToString('F1'))s -> $fileName" -ForegroundColor Green
    }

    Write-Host ""
}

##############################################
# Resume final
##############################################
$totalTime = ((Get-Date) - $scriptStart).TotalSeconds
$avgSpeed = if ($totalTime -gt 0) { [math]::Round($total_transactions / $totalTime, 0) } else { 0 }

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  TRAITEMENT TERMINE" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Ticket              : $ticket" -ForegroundColor White
Write-Host "Fichier source      : $($painFile.FullName)" -ForegroundColor White
Write-Host "Repertoire sortie   : $outputDir" -ForegroundColor White
Write-Host "---------------------------------------------" -ForegroundColor DarkGray
Write-Host "Blocs PmtInf        : $total_pmtinf" -ForegroundColor White
Write-Host "Transactions totales: $total_transactions" -ForegroundColor White
Write-Host "Temps total         : $($totalTime.ToString('F1')) secondes" -ForegroundColor White
Write-Host "Vitesse moyenne     : $avgSpeed tx/s" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
