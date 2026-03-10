#!/bin/ksh
# =======================================================================
# Script d'analyse XML - Cote ACCURATE
# Genere un fichier de controle a partir du XML recu
# pour comparaison avec le fichier de controle CODA
# =======================================================================
#
# LANCEMENT :
#   ./Analyse_ExtraitComptaGene_RNA_RNACPT22.ksh
#   ./Analyse_ExtraitComptaGene_RNA_RNACPT22.ksh fichier.xml
#
# UTILISATION :
#   Sans argument : Analyse le dernier fichier ExtraitComptaGene_*.xml
#   Avec argument : Analyse le fichier XML specifie
#
# SORTIE :
#   /tmp/CODA_ExtraitComptaGene_controle_<nom_fichier_xml>_YYYYMMDD_HHMMSS.txt
#
# =======================================================================

# Repertoire courant
REP_COURANT=$(dirname "$0")
cd "$REP_COURANT" 2>/dev/null || REP_COURANT="."

# =======================================================================
# Determination du fichier XML a analyser
# =======================================================================

if [ -n "$1" ]; then
    # Fichier passe en argument
    FICHIER_XML="$1"
else
    # Dernier fichier au format ExtraitComptaGene_*.xml
    FICHIER_XML=$(ls -t ExtraitComptaGene_*.xml 2>/dev/null | head -1)

    if [ -z "$FICHIER_XML" ]; then
        echo "ERREUR: Aucun fichier ExtraitComptaGene_*.xml trouve dans le repertoire courant"
        echo "Usage: $0 [fichier.xml]"
        exit 1
    fi
fi

# Verifier que le fichier existe
if [ ! -f "$FICHIER_XML" ]; then
    echo "ERREUR: Fichier non trouve: $FICHIER_XML"
    exit 1
fi

# =======================================================================
# Extraction des informations du XML
# =======================================================================

# Dates du StatementPeriod (conversion format ISO vers format CODA)
DATE_DEBUT=$(grep -o '<FromDateTime>[^<]*</FromDateTime>' "$FICHIER_XML" | head -1 | sed 's/<[^>]*>//g' | sed 's/T/ /')
DATE_FIN=$(grep -o '<ToDateTime>[^<]*</ToDateTime>' "$FICHIER_XML" | head -1 | sed 's/<[^>]*>//g' | sed 's/T/ /')

# Nombre de mouvements comptables
NB_MOUVEMENTS=$(grep -c '<MouvementComptable>' "$FICHIER_XML")

# Nombre de documents comptables
NB_DOCUMENTS=$(grep -c '<DocumentComptable>' "$FICHIER_XML")

# Nombre de societes (Statement)
NB_SOCIETES=$(grep -c '<Statement>' "$FICHIER_XML")

# Total des montants OperationAmount
TOTAL_VALUEDOC=$(grep -o '<OperationAmount[^>]*>[^<]*</OperationAmount>' "$FICHIER_XML" | \
    sed 's/<[^>]*>//g' | \
    awk '{sum += $1} END {printf "%.2f", sum}')

# Total des montants HomeAmount
TOTAL_VALUEHOME=$(grep -o '<HomeAmount[^>]*>[^<]*</HomeAmount>' "$FICHIER_XML" | \
    sed 's/<[^>]*>//g' | \
    awk '{sum += $1} END {printf "%.2f", sum}')

# =======================================================================
# Verification structure XML
# =======================================================================

STRUCTURE_OK="OK"

# Verifier balise ouvrante Flux
if ! head -10 "$FICHIER_XML" | grep -q "<Flux>"; then
    STRUCTURE_OK="ERREUR - Balise <Flux> manquante"
fi

# Verifier balise fermante Flux
if ! tail -10 "$FICHIER_XML" | grep -q "</Flux>"; then
    STRUCTURE_OK="ERREUR - Balise </Flux> manquante - FICHIER INCOMPLET"
fi

# Coherence des balises MouvementComptable
NB_OPEN_MVT=$(grep -c '<MouvementComptable>' "$FICHIER_XML")
NB_CLOSE_MVT=$(grep -c '</MouvementComptable>' "$FICHIER_XML")
if [ "$NB_OPEN_MVT" -ne "$NB_CLOSE_MVT" ]; then
    STRUCTURE_OK="ERREUR - Balises MouvementComptable incoherentes ($NB_OPEN_MVT ouvertes, $NB_CLOSE_MVT fermees)"
fi

# =======================================================================
# Generation du fichier de controle (meme format que CODA)
# =======================================================================

# Horodatage pour le nom du fichier (format identique au SQL)
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
# Extraction du nom du fichier XML (sans chemin ni extension)
NOM_XML=$(basename "$FICHIER_XML" .xml)
FICHIER_CTRL="/tmp/CODA_ExtraitComptaGene_controle_${NOM_XML}_${TIMESTAMP}.txt"

# Contenu du fichier de controle
{
    echo "# Fichier de controle - Extrait Compta CODA"
    echo "# Source: Analyse XML ($FICHIER_XML)"
    echo "#"
    echo "DATE_DEBUT=${DATE_DEBUT}"
    echo "DATE_FIN=${DATE_FIN}"
    echo "DATE_GENERATION=$(date '+%Y-%m-%d %H:%M:%S')"
    echo "#"
    echo "NB_MOUVEMENTS=${NB_MOUVEMENTS}"
    echo "NB_DOCUMENTS=${NB_DOCUMENTS}"
    echo "NB_SOCIETES=${NB_SOCIETES}"
    echo "TOTAL_VALUEDOC=${TOTAL_VALUEDOC}"
    echo "TOTAL_VALUEHOME=${TOTAL_VALUEHOME}"
} | tee "$FICHIER_CTRL"

echo ""
echo "Fichier de controle genere: $FICHIER_CTRL"

# =======================================================================
# Code retour
# =======================================================================

if [ "$STRUCTURE_OK" = "OK" ]; then
    exit 0
else
    exit 1
fi
