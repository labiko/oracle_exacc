##############################################
# Script PowerShell : PAIN-Auto-Processor.ps1
# Traitement automatique de fichiers PAIN.001 / PAIN.008
# - Detection automatique du namespace
# - Recherche automatique du fichier XML
# - Export CSV par PmtInf
##############################################

##############################################
# Configuration du chemin de base
##############################################
$BASE_DIR = "C:\DISQUED\TEMP\PAIN-TRANSFORMER"

##############################################
# Demande du numero de ticket
##############################################
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  PAIN Auto Processor" -ForegroundColor Cyan
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

# Verifier que le dossier ticket existe
if (-not (Test-Path $ticketDir)) {
    Write-Host "ERREUR : Le dossier '$ticketDir' n'existe pas" -ForegroundColor Red
    exit 1
}

##############################################
# Recherche du fichier PAIN dans le dossier ticket
##############################################
Write-Host ""
Write-Host "Recherche du fichier PAIN dans : $ticketDir" -ForegroundColor Yellow

# Chercher en priorite pain08*.xml
$painFile = Get-ChildItem -Path $ticketDir -Filter "pain08*.xml" -File | Select-Object -First 1

# Sinon chercher pain01*.xml
if (-not $painFile) {
    $painFile = Get-ChildItem -Path $ticketDir -Filter "pain01*.xml" -File | Select-Object -First 1
}

# Sinon prendre le .xml le plus recent
if (-not $painFile) {
    $painFile = Get-ChildItem -Path $ticketDir -Filter "*.xml" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

# Verifier qu'un fichier a ete trouve
if (-not $painFile) {
    Write-Host "ERREUR : Aucun fichier XML trouve dans $ticketDir" -ForegroundColor Red
    exit 1
}

Write-Host "Fichier trouve : $($painFile.Name)" -ForegroundColor Green

##############################################
# Creation du repertoire de sortie OUTPUT
##############################################
$outputDir = Join-Path $ticketDir "OUTPUT"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
Write-Host "Repertoire de sortie : $outputDir" -ForegroundColor Green
Write-Host ""

##############################################
# Chargement du XML
##############################################
Write-Host "Chargement du fichier XML..." -ForegroundColor Yellow
$xml = New-Object System.Xml.XmlDocument
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
$nsmgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$nsmgr.AddNamespace("ns", $nsUri)

##############################################
# Detection du type PAIN depuis le namespace
##############################################
if ($nsUri -like "*pain.001*") {
    # PAIN.001 - Initiation de paiement (Credit Transfer)
    $initNode = "CstmrCdtTrfInitn"
    $txTag = "CdtTrfTxInf"
    Write-Host "Type PAIN detecte : PAIN.001 (Virement)" -ForegroundColor Cyan
}
elseif ($nsUri -like "*pain.008*") {
    # PAIN.008 - Prelevements (Direct Debit)
    $initNode = "CstmrDrctDbtInitn"
    $txTag = "DrctDbtTxInf"
    Write-Host "Type PAIN detecte : PAIN.008 (Prelevement)" -ForegroundColor Cyan
}
else {
    Write-Host "ERREUR : Namespace non supporte" -ForegroundColor Red
    Write-Host "Le namespace doit contenir 'pain.001' ou 'pain.008'" -ForegroundColor Red
    Write-Host "Namespace trouve : $nsUri" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

##############################################
# Compteurs globaux
##############################################
$total_pmtinf = 0
$total_transactions = 0

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

Write-Host "Traitement de $($payment_infos.Count) bloc(s) PmtInf..." -ForegroundColor Yellow
Write-Host ""

##############################################
# Fonction utilitaire
# - Retourne le texte d'un noeud XML
# - Retourne une valeur par defaut si absent
##############################################
function Get-NodeText {
    param(
        $Node,
        [string]$Path,
        $NsMgr,
        [string]$Default = ""
    )

    $n = $Node.SelectSingleNode($Path, $NsMgr)
    if ($n) {
        return $n.InnerText.Trim()
    } else {
        return $Default
    }
}

##############################################
# Traitement de chaque bloc PmtInf
##############################################
foreach ($payment_info in $payment_infos) {

    ##############################################
    # Infos du bloc PmtInf
    ##############################################
    $pmtinf_id = Get-NodeText $payment_info "ns:PmtInfId" $nsmgr "UNKNOWN"
    $pmtmtd = Get-NodeText $payment_info "ns:PmtMtd" $nsmgr ""
    $nb_of_txs = Get-NodeText $payment_info "ns:NbOfTxs" $nsmgr "0"
    $ctrl_sum = Get-NodeText $payment_info "ns:CtrlSum" $nsmgr "0"

    $transactions = @()
    $total_pmtinf++

    ##############################################
    # Recuperation des transactions
    ##############################################
    $tx_nodes = $payment_info.SelectNodes(".//ns:$txTag", $nsmgr)

    foreach ($tx in $tx_nodes) {

        ##############################################
        # Reference de transaction
        ##############################################
        $end_to_end_id = Get-NodeText $tx "ns:PmtId/ns:EndToEndId" $nsmgr ""

        ##############################################
        # Montant et devise
        ##############################################
        $amount_node = $tx.SelectSingleNode(".//ns:InstdAmt", $nsmgr)
        if ($amount_node) {
            $amount = $amount_node.InnerText -replace '\.', ','
            $currency = $amount_node.GetAttribute("Ccy")
        } else {
            $amount = ""
            $currency = "EUR"
        }

        ##############################################
        # Debiteur
        ##############################################
        $debtor_name = Get-NodeText $tx "ns:Dbtr/ns:Nm" $nsmgr ""
        $debtor_iban = Get-NodeText $tx "ns:DbtrAcct/ns:Id/ns:IBAN" $nsmgr ""

        ##############################################
        # Creancier
        ##############################################
        $creditor_name = Get-NodeText $tx "ns:Cdtr/ns:Nm" $nsmgr ""
        $creditor_iban = Get-NodeText $tx "ns:CdtrAcct/ns:Id/ns:IBAN" $nsmgr ""

        ##############################################
        # Reference de remise
        ##############################################
        $remittance_info = Get-NodeText $tx "ns:RmtInf/ns:Ustrd" $nsmgr ""

        ##############################################
        # Construction de la ligne CSV
        ##############################################
        $transactions += [pscustomobject]@{
            PmtInfId              = $pmtinf_id
            "Reference Paiement"  = $end_to_end_id
            Montant               = $amount
            Devise                = $currency
            Debiteur              = $debtor_name
            "IBAN Debiteur"       = $debtor_iban
            Creancier             = $creditor_name
            "IBAN Creancier"      = $creditor_iban
            "Reference Remise"    = $remittance_info
        }
    }

    ##############################################
    # Export CSV pour ce PmtInf
    ##############################################
    $total_transactions += $transactions.Count

    if ($transactions.Count -gt 0) {
        $output_file = Join-Path $outputDir "$pmtinf_id-$pmtmtd-$nb_of_txs-$ctrl_sum.csv"
        $transactions | Export-Csv -Path $output_file -NoTypeInformation -Encoding Default -Delimiter ";"

        $fileName = Split-Path $output_file -Leaf
        Write-Host "[OK] $($transactions.Count) transaction(s) -> $fileName" -ForegroundColor Green
    }
}

##############################################
# Resume final
##############################################
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  TRAITEMENT TERMINE" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Ticket              : $ticket" -ForegroundColor White
Write-Host "Fichier source      : $($painFile.FullName)" -ForegroundColor White
Write-Host "Repertoire sortie   : $outputDir" -ForegroundColor White
Write-Host "Blocs PmtInf        : $total_pmtinf" -ForegroundColor White
Write-Host "Transactions totales: $total_transactions" -ForegroundColor White
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

##############################################
# COMMANDE POUR LANCER LE SCRIPT
##############################################
#
# METHODE 1 (RECOMMANDEE) - Depuis CMD ou PowerShell :
# cd C:\DISQUED\TEMP\PAIN-TRANSFORMER
# powershell.exe -File ".\PAIN-Auto-Processor.ps1"
#
# METHODE 2 - Depuis PowerShell uniquement (avec l'operateur & ou .) :
# cd C:\DISQUED\TEMP\PAIN-TRANSFORMER
# & ".\PAIN-Auto-Processor.ps1"
#
# METHODE 3 - Clic droit dans l'Explorateur Windows :
# Clic droit sur le fichier -> "Executer avec PowerShell"
#
# Le script vous demandera ensuite le numero de ticket (ex: AER_ITFIN-12345)
##############################################
