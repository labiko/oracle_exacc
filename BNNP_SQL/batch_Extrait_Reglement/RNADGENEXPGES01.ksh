#!/bin/ksh
. $SOFT_APPLI/bin/DTCEXETRTLIB01.ksh

#set -x
FIC_IMP_GEST=`ls -1t $IN_APPLI/ExtraitReglement_Valide_RNA*xml|tail -1`
ID_DEC_GST="431-GEST"
ID_DEC_GDT="432-GDT"
NOM_PARAM_GST="FIC_EXP_GEST"
NOM_PARAM_GDT="FIC_EXP_GDT"
RAW_TABLE="TX_REGLT_GEST"

ORACLE_PW=$(PC_PASSWD_INSORA $ORACLE_INST $ORACLE_USER_RAPPRO)

if [ -z $FIC_IMP_GEST ]
then
   echo "No ExtraitReglement_Valide_RNA*xml found. Exiting."
   exit 1
fi

if file "$FIC_IMP_GEST" | grep -q "text"; then
    echo "traitement fichier $FIC_IMP_GEST"
else
    # creation de 2 fichiers videz pour la continuite du process
    echo "" > ${OUT_APPLI}/ExtraitReglement.txt.291231000000
    echo "" > ${OUT_APPLI}/ExtraitReglement_RapCtl.txt.291231000000
    AfficherMessage "*** Fichier crypte ou illisible : $FIC_IMP_GEST, il sera bloque dans le IN + creation de fichier vide a integrer***"
    exit 0
fi

FN=`basename $FIC_IMP_GEST .xml`

#Build CTL file from template
cat $SOFT_APPLI/oracle/ctl/$RAW_TABLE.tmpl > $TEMP_APPLI/$RAW_TABLE.ctl
echo $FIC_IMP_GEST >> $TEMP_APPLI/$RAW_TABLE.ctl

sqlldr $ORACLE_USER_RAPPRO/$ORACLE_PW@$ORACLE_INST "direct=y" CONTROL="$TEMP_APPLI/$RAW_TABLE.ctl" BAD="$DBBAD_APPLI/$FN.bad" LOG="$DBLOG_APPLI/$FN.log" SILENT=\(HEADER, FEEDBACK\) DISCARD="$DBBAD_APPLI/$FN.dsc"

CR=$?
if [ $CR -ne 0 ]
then
  echo "SQL Loader error occurred while loading $FN.xml. Exiting."
  exit 1
fi

#Remove CTL file
rm -f $TEMP_APPLI/$RAW_TABLE.ctl

XXEXESQLORA01.ksh -n $0 -u $ORACLE_USER_RAPPRO -c $ORACLE_INST RNADGENEXPGES01.sql

#Recuperation du CLOB pour le fichier ExtraitComptaGene_CL.txt
RecupCLOBDefaut "$ORACLE_INST" "$ORACLE_USER_RAPPRO" "$ID_DEC_GST" "$NOM_PARAM_GST" "-deletefile Y"

if [ $? -ne $CR_OK ]; then
    AfficherMessage "Recuperation du fichier ExtraitReglement.txt a echoue."
	exit 1
fi

#Recuperation du CLOB pour le fichier ExtraitComptaGene_JC.txt
RecupCLOBDefaut "$ORACLE_INST" "$ORACLE_USER_RAPPRO" "$ID_DEC_GDT" "$NOM_PARAM_GDT" "-deletefile Y"

if [ $? -ne $CR_OK ]; then
    AfficherMessage "Recuperation du fichier ExtraitReglement_RapCtl a echoue."
	exit 1
fi

OUT_FIC_EXPORT_GEST=`ls -1t $OUT_APPLI/ExtraitReglement.txt*|head -1`
OUT_FIC_EXPORT_GDT=`ls -1t $OUT_APPLI/ExtraitReglement_RapCtl.txt*|head -1`

AfficherMessage "*** Fichiers $OUT_FIC_EXPORT_GEST et $OUT_FIC_EXPORT_GDT generes avec succes. ***"
exit 0
