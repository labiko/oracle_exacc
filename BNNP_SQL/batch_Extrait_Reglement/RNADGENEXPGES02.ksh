#!/bin/ksh

. $SOFT_APPLI/bin/DTCEXETRTLIB01.ksh

#set -x
FIC_IMP_GEST=`ls -1t $IN_APPLI/ExtraitReglement_Valide_RNA*xml|tail -1`
ID_DEC_GEST_JC="433-GEST-JC"
NOM_PARAM_GEST_JC="FIC_GEST_JC"
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
    # creation du fichier JC vide pour la continuite du process
    echo "" > ${OUT_APPLI}/ExtraitReglement_JC.txt.291231000000
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

XXEXESQLORA01.ksh -n $0 -u $ORACLE_USER_RAPPRO -c $ORACLE_INST RNADGENJUCGES01.sql

#Recuperation du CLOB pour le fichier ExtraitComptaGene_JC.txt
RecupCLOBDefaut "$ORACLE_INST" "$ORACLE_USER_RAPPRO" "$ID_DEC_GEST_JC" "$NOM_PARAM_GEST_JC" "-deletefile Y"

if [ $? -ne $CR_OK ]; then
    AfficherMessage "Recuperation du fichier ExtraitReglement_JC.txt a echoue."
	exit 1
fi

OUT_FIC_EXPORT_GEST_JC=`ls -1t $OUT_APPLI/ExtraitReglement_JC.txt*|head -1`

AfficherMessage "*** Fichier $OUT_FIC_EXPORT_GEST_JC genere avec succes. ***"
exit 0
