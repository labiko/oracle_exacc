#!/usr/bin/ksh
FIC_IMP_GES="$(ls -1t $IN_APPLI/ExtraitReglement_Valide_RNA*.xml | tail -1l)"

# Copie du fichier dans le dossier archive
cp ${FIC_IMP_GES} ${ARCH_APPLI}
# Suppression du fichier
ME_REMOVE_FICUNIX ${FIC_IMP_GES}
