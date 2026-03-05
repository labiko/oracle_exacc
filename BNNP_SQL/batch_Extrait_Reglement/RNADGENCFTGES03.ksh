#!/usr/bin/ksh

FIC=`ls -rt ${OUT_APPLI}/ExtraitReglement_JC.txt* | tail -1l`
PARM=ExtraitReglement_JC.txt
REP_DST=/apps/accurate/data/gestion

if [ -n $FIC ]
then
sesu - accurate -c "cp -f ${FIC} ${REP_DST}/${PARM}"
 if [ $? -eq 0 ]
  then
   gzip $FIC
   mv -f ${FIC}.gz ${ARCH_APPLI}
 fi
exit $?
else
        echo "Pas de fichier $PARM a envoyer !!!"
        exit 202
fi
