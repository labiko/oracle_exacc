##############################################
# Script PowerShell : PAIN-Auto-Processor-Optimized.ps1
# Version optimisee pour performance
# Traitement automatique de fichiers PAIN.001 / PAIN.008
##############################################

##############################################
# Configuration du chemin de base
##############################################
$BASE_DIR = "C:\DISQUED\TEMP\PAIN-TRANSFORMER"

##############################################
# Demande du numero de ticket
##############################################
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  PAIN Auto Processor (Optimized)" -ForegroundColor Cyan
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
# Recherche du fichier PAIN dans le dossier ticket
##############################################
Write-Host "`nRecherche du fichier PAIN dans : $ticketDir" -ForegroundColor Yellow

# Recherche optimisee avec priorite
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
# Creation du repertoire de sortie OUTPUT
##############################################
$outputDir = Join-Path $ticketDir "OUTPUT"
$null = New-Item -ItemType Directory -Path $outputDir -Force
Write-Host "Repertoire de sortie : $outputDir`n" -ForegroundColor Green

##############################################
# Chargement du XML (optimise avec XmlReader settings)
##############################################
Write-Host "Chargement du fichier XML..." -ForegroundColor Yellow

$xml = [System.Xml.XmlDocument]::new()
$xml.PreserveWhitespace = $false

try {
    $xml.Load($painFile.FullName)
} catch {
    Write-Host "ERREUR : Impossible de charger le fichier XML" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

##############################################
# Detection automatique du namespace
##############################################
$nsUri = $xml.DocumentElement.NamespaceURI

if ([string]::IsNullOrWhiteSpace($nsUri)) {
    Write-Host "ERREUR : Aucun namespace trouve dans le fichier XML" -ForegroundColor Red
    exit 1
}

Write-Host "Namespace detecte : $nsUri" -ForegroundColor Green

##############################################
# Gestion du namespace XML
##############################################
$nsmgr = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
$nsmgr.AddNamespace("ns", $nsUri)

##############################################
# Detection du type PAIN depuis le namespace
##############################################
switch -Wildcard ($nsUri) {
    "*pain.001*" {
        $initNode = "CstmrCdtTrfInitn"
        $txTag = "CdtTrfTxInf"
        Write-Host "Type PAIN detecte : PAIN.001 (Virement)" -ForegroundColor Cyan
    }
    "*pain.008*" {
        $initNode = "CstmrDrctDbtInitn"
        $txTag = "DrctDbtTxInf"
        Write-Host "Type PAIN detecte : PAIN.008 (Prelevement)" -ForegroundColor Cyan
    }
    default {
        Write-Host "ERREUR : Namespace non supporte" -ForegroundColor Red
        Write-Host "Namespace trouve : $nsUri" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""

##############################################
# Compteurs globaux
##############################################
[int]$total_pmtinf = 0
[int]$total_transactions = 0

##############################################
# Collection globale pour fichier consolide
##############################################
$allTransactions = [System.Collections.Generic.List[PSCustomObject]]::new()

##############################################
# Recuperation du noeud racine PAIN
##############################################
$root = $xml.SelectSingleNode("//ns:$initNode", $nsmgr)
if (-not $root) {
    Write-Host "ERREUR : Noeud racine '$initNode' introuvable" -ForegroundColor Red
    exit 1
}

##############################################
# Recuperation des blocs PmtInf
##############################################
$payment_infos = $root.SelectNodes(".//ns:PmtInf", $nsmgr)

if ($payment_infos.Count -eq 0) {
    Write-Host "ATTENTION : Aucun bloc PmtInf trouve" -ForegroundColor Yellow
    exit 0
}

Write-Host "Traitement de $($payment_infos.Count) bloc(s) PmtInf...`n" -ForegroundColor Yellow

##############################################
# Traitement de chaque bloc PmtInf
##############################################
foreach ($payment_info in $payment_infos) {

    ##############################################
    # Infos du bloc PmtInf (inline pour performance)
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
    # OPTIMISATION : Utiliser ArrayList au lieu de +=
    ##############################################
    $transactions = [System.Collections.Generic.List[PSCustomObject]]::new()

    ##############################################
    # Recuperation des transactions
    ##############################################
    $tx_nodes = $payment_info.SelectNodes(".//ns:$txTag", $nsmgr)

    foreach ($tx in $tx_nodes) {

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

        ##############################################
        # OPTIMISATION : Add() au lieu de +=
        ##############################################
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
    }

    ##############################################
    # Export CSV pour ce PmtInf
    ##############################################
    $txCount = $transactions.Count
    $total_transactions += $txCount

    if ($txCount -gt 0) {
        $output_file = Join-Path $outputDir "$pmtinf_id-$pmtmtd-$nb_of_txs-$ctrl_sum.csv"

        # OPTIMISATION : Export direct sans variable intermediaire
        $transactions | Export-Csv -Path $output_file -NoTypeInformation -Encoding Default -Delimiter ";"

        # Ajouter a la collection globale pour le fichier consolide
        $allTransactions.AddRange($transactions)

        Write-Host "[OK] $txCount transaction(s) -> $(Split-Path $output_file -Leaf)" -ForegroundColor Green
    }
}

##############################################
# Ajout colonne "Reference Nettoyee" pour le fichier consolide
##############################################
Write-Host ""
Write-Host "Ajout de la colonne 'Reference Nettoyee'..." -ForegroundColor Yellow

foreach ($tx in $allTransactions) {
    $refPaiement = $tx."Reference Paiement"

    if ($refPaiement -match '^\S+\s+') {
        # Format 2 : "S 008798830           0925000390"
        # Supprimer 1er caractere + espaces, garder 1er groupe de chiffres
        $refNettoyee = ($refPaiement -replace '^[A-Za-z]\s+', '') -replace '\s+.*$', ''
    } else {
        # Format 1 : "SI05000005601742851230092511P025418"
        $refNettoyee = ""
    }

    $tx | Add-Member -NotePropertyName "Reference Nettoyee" -NotePropertyValue $refNettoyee -Force
}

##############################################
# Export du fichier consolide (toutes les transactions)
##############################################
if ($allTransactions.Count -gt 0) {
    $consolidatedFile = Join-Path $outputDir "CONSOLIDATED_ALL_TRANSACTIONS.csv"
    $allTransactions | Export-Csv -Path $consolidatedFile -NoTypeInformation -Encoding Default -Delimiter ";"
    Write-Host ""
    Write-Host "[CONSOLIDE] $($allTransactions.Count) transaction(s) -> CONSOLIDATED_ALL_TRANSACTIONS.csv" -ForegroundColor Magenta
}

##############################################
# Resume final
##############################################
Write-Host @"

=====================================
  TRAITEMENT TERMINE
=====================================
Ticket              : $ticket
Fichier source      : $($painFile.FullName)
Repertoire sortie   : $outputDir
Blocs PmtInf        : $total_pmtinf
Transactions totales: $total_transactions
Fichier consolide   : CONSOLIDATED_ALL_TRANSACTIONS.csv
=====================================

"@ -ForegroundColor Cyan

##############################################
# COMMANDE POUR LANCER LE SCRIPT
##############################################
#
# powershell.exe -File ".\PAIN-Auto-Processor-Optimized.ps1"
#
##############################################
