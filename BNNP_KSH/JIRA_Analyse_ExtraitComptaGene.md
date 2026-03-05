# Script Analyse XML ExtraitComptaGene - Documentation JIRA

---

## Format JIRA (copier-coller directement)

```
h2. 📋 Script d'analyse XML - Côté ACCURATE

{panel:title=🎯 Objectif|borderStyle=solid|borderColor=#0052CC|bgColor=#F4F5F7}
Génère un fichier de contrôle à partir du XML reçu pour comparaison avec le fichier CODA.
{panel}

h3. 🚀 Utilisation

{code:bash}
# Sans argument : analyse le dernier fichier ExtraitComptaGene_*.xml
./Analyse_ExtraitComptaGene_RNA_RNACPT22.ksh

# Avec argument : analyse le fichier XML spécifié
./Analyse_ExtraitComptaGene_RNA_RNACPT22.ksh fichier.xml
{code}

h3. 📤 Sortie

{noformat}
/tmp/CODA_ExtraitComptaGene_controle_<nom_fichier>_YYYYMMDD_HHMMSS.txt
{noformat}

h3. 📊 Données extraites

||Champ||Description||
|DATE_DEBUT|Période de début (FromDateTime)|
|DATE_FIN|Période de fin (ToDateTime)|
|NB_MOUVEMENTS|Nombre de balises <MouvementComptable>|
|NB_DOCUMENTS|Nombre de balises <DocumentComptable>|
|NB_SOCIETES|Nombre de balises <Statement>|
|TOTAL_VALUEDOC|Somme des <OperationAmount>|
|TOTAL_VALUEHOME|Somme des <HomeAmount>|

h3. ✅ Contrôles effectués

* Présence balise {noformat}<Flux>{noformat} ouvrante
* Présence balise {noformat}</Flux>{noformat} fermante
* Cohérence des balises {noformat}<MouvementComptable>{noformat}

h3. 🔢 Codes retour

||Code||Signification||
|0|Succès - Structure XML valide|
|1|Erreur - Structure XML invalide ou fichier incomplet|

----

h3. 📜 Script complet

{code:bash|title=Analyse_ExtraitComptaGene_RNA_RNACPT22.ksh|collapse=true}
#!/bin/ksh
# =======================================================================
# Script d'analyse XML - Cote ACCURATE
# Genere un fichier de controle a partir du XML recu
# pour comparaison avec le fichier de controle CODA
# =======================================================================

# Repertoire courant
REP_COURANT=$(dirname "$0")
cd "$REP_COURANT" 2>/dev/null || REP_COURANT="."

# =======================================================================
# Determination du fichier XML a analyser
# =======================================================================

if [ -n "$1" ]; then
    FICHIER_XML="$1"
else
    FICHIER_XML=$(ls -t ExtraitComptaGene_*.xml 2>/dev/null | head -1)
    if [ -z "$FICHIER_XML" ]; then
        echo "ERREUR: Aucun fichier ExtraitComptaGene_*.xml trouve"
        exit 1
    fi
fi

[ ! -f "$FICHIER_XML" ] && echo "ERREUR: Fichier non trouve: $FICHIER_XML" && exit 1

# =======================================================================
# Extraction des informations du XML
# =======================================================================

DATE_DEBUT=$(grep -o '<FromDateTime>[^<]*</FromDateTime>' "$FICHIER_XML" | head -1 | sed 's/<[^>]*>//g' | sed 's/T/ /')
DATE_FIN=$(grep -o '<ToDateTime>[^<]*</ToDateTime>' "$FICHIER_XML" | head -1 | sed 's/<[^>]*>//g' | sed 's/T/ /')
NB_MOUVEMENTS=$(grep -c '<MouvementComptable>' "$FICHIER_XML")
NB_DOCUMENTS=$(grep -c '<DocumentComptable>' "$FICHIER_XML")
NB_SOCIETES=$(grep -c '<Statement>' "$FICHIER_XML")

TOTAL_VALUEDOC=$(grep -o '<OperationAmount[^>]*>[^<]*</OperationAmount>' "$FICHIER_XML" | \
    sed 's/<[^>]*>//g' | awk '{sum += $1} END {printf "%.2f", sum}')

TOTAL_VALUEHOME=$(grep -o '<HomeAmount[^>]*>[^<]*</HomeAmount>' "$FICHIER_XML" | \
    sed 's/<[^>]*>//g' | awk '{sum += $1} END {printf "%.2f", sum}')

# =======================================================================
# Verification structure XML
# =======================================================================

STRUCTURE_OK="OK"
head -10 "$FICHIER_XML" | grep -q "<Flux>" || STRUCTURE_OK="ERREUR - Balise <Flux> manquante"
tail -10 "$FICHIER_XML" | grep -q "</Flux>" || STRUCTURE_OK="ERREUR - Balise </Flux> manquante"

NB_OPEN_MVT=$(grep -c '<MouvementComptable>' "$FICHIER_XML")
NB_CLOSE_MVT=$(grep -c '</MouvementComptable>' "$FICHIER_XML")
[ "$NB_OPEN_MVT" -ne "$NB_CLOSE_MVT" ] && STRUCTURE_OK="ERREUR - Balises incoherentes"

# =======================================================================
# Generation du fichier de controle
# =======================================================================

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
NOM_XML=$(basename "$FICHIER_XML" .xml)
FICHIER_CTRL="/tmp/CODA_ExtraitComptaGene_controle_${NOM_XML}_${TIMESTAMP}.txt"

{
    echo "# Fichier de controle - Extrait Compta CODA"
    echo "DATE_DEBUT=${DATE_DEBUT}"
    echo "DATE_FIN=${DATE_FIN}"
    echo "DATE_GENERATION=$(date '+%Y-%m-%d %H:%M:%S')"
    echo "NB_MOUVEMENTS=${NB_MOUVEMENTS}"
    echo "NB_DOCUMENTS=${NB_DOCUMENTS}"
    echo "NB_SOCIETES=${NB_SOCIETES}"
    echo "TOTAL_VALUEDOC=${TOTAL_VALUEDOC}"
    echo "TOTAL_VALUEHOME=${TOTAL_VALUEHOME}"
} | tee "$FICHIER_CTRL"

echo "Fichier genere: $FICHIER_CTRL"

[ "$STRUCTURE_OK" = "OK" ] && exit 0 || exit 1
{code}
```

---

## Version Markdown GitHub/GitLab

### 📋 Script d'analyse XML - Côté ACCURATE

> **Objectif** : Génère un fichier de contrôle à partir du XML reçu pour comparaison avec CODA.

#### 🚀 Utilisation

```bash
# Sans argument : analyse le dernier fichier
./Analyse_ExtraitComptaGene_RNA_RNACPT22.ksh

# Avec argument
./Analyse_ExtraitComptaGene_RNA_RNACPT22.ksh fichier.xml
```

#### 📤 Sortie

```
/tmp/CODA_ExtraitComptaGene_controle_<nom>_YYYYMMDD_HHMMSS.txt
```

#### 📊 Données extraites

| Champ | Description |
|-------|-------------|
| `DATE_DEBUT` | Période de début |
| `DATE_FIN` | Période de fin |
| `NB_MOUVEMENTS` | Nombre `<MouvementComptable>` |
| `NB_DOCUMENTS` | Nombre `<DocumentComptable>` |
| `NB_SOCIETES` | Nombre `<Statement>` |
| `TOTAL_VALUEDOC` | Somme `<OperationAmount>` |
| `TOTAL_VALUEHOME` | Somme `<HomeAmount>` |

#### 🔢 Codes retour

| Code | Signification |
|------|---------------|
| `0` | ✅ Succès |
| `1` | ❌ Erreur structure XML |

---

## Version Confluence

```
h2. Script Analyse XML ExtraitComptaGene

{info:title=Objectif}
Génère un fichier de contrôle côté ACCURATE pour comparaison avec CODA.
{info}

{tip:title=Utilisation}
{code:bash}
./Analyse_ExtraitComptaGene_RNA_RNACPT22.ksh [fichier.xml]
{code}
{tip}

{warning:title=Codes retour}
* *0* = Succès
* *1* = Erreur XML
{warning}
```
