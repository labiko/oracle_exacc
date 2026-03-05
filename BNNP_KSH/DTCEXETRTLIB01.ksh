#$SOFT_APPLI/bin/DTCEXETRTLIB01.ksh

#!/usr/bin/ksh

#@(#) ========================================================================
#@(#) SCRIPT : DTCEXETRTLIB.ksh
#@(#) OBJET  : Librairie de fonctions pour l'execution d'un traitement PL/SQL
#@(#) AUTEUR : D. VAREILLE (EIC)
#@(#) ------------------------------------------------------------------------
#@(#) PARAMETRES :
#@(#) ------------------------------------------------------------------------
#@(#) DATE        AUTEUR        MODIFICATION
#@(#) 15/11/2006  D. VAREILLE   Creation du script
#@(#) 17/08/2007  D. VAREILLE   Evolution fonction EnvoyerMail
#@(#) 30/11/2007  FRA           Creation EnvoyerMailCRE
#@(#) 22/05/2008  FRA           Gestion fichier flag en cours
#@(#) 22/08/2008  DVA           Modif fonction ExecScriptSQL :
#@(#)                           modification des parametres d'appel
#@(#)                           du XXEXESQLORA01.ksh
#@(#) 03/09/2008  DVA           Modif fonction EnvoyerMailCRE pour gerer
#@(#)                           les differents code resultats de traitements
#@(#) 15/10/2008  FAU           Ajout GetIdDelenchementEnCours
#@(#)                           Maj EnvoiMail pour envoi fichier en corps (option)
#@(#) 23/01/2009  FAU    V 1.1  MAJ CopieFicEnv (-c flag) pour DAS2
#@(#) 24/04/2009  FAU           Ajout fonction ExecScriptSQLPlus,EcrireLogPlus
#@(#) ========================================================================

# ============================================================================
# CONSTANTES GLOBALES
# ============================================================================

# Marqueur d'erreur
TAG_ERREUR="@#ANOMALIE#@"

# Code retour : succes
CR_OK=0

# Code retour : Warning technique
CR_WARNING=201

# Code retour : Erreur technique bloquante
CR_KO=202

# Code retour : Erreur technique critique
CR_KO_CRITIQUE=203

# Code retour : Erreur fonctionnelle bloquante
CR_KO_FONCTIONNEL=204

# Code retour SQL : succes
CR_SQL_OK=0

# Code retour SQL : echec technique
CR_SQL_KO=202

# Code retour SQL : echec fonctionnel
CR_SQL_KO_FCT=204

# Code retour : erreur fonctionnelle bloquante
# Dans ce cas, les codes retournes doivent etre positif :
# 1, 2, 3, ... 199 (max)

# Code resultat DTC : succes
CR_DTC_OK="OK"

# Code resultat DTC : echec
CR_DTC_KO="KO"

# Environnements
ENV_DEV="D"
ENV_INT="I"
ENV_REC="R"
ENV_PROD="P"

# ============================================================================
# FONCTION
# ============================================================================

#---------------------------------------------------------------------------
# Fonction AfficherMessage <Message texte quelconque>
#---------------------------------------------------------------------------
function AfficherMessage
{
    # Afficher les parametres
    echo "$*"
}

#---------------------------------------------------------------------------
# Fonction AfficherAnomalie <Message explicitant l'anomalie !>
#---------------------------------------------------------------------------
function AfficherAnomalie
{
    # Afficher le message d'anomalie
    AfficherMessage "    ==> [$(date +'%d/%m/%Y %H:%M:%S') - ${TAG_ERREUR}] ${1} !"

    # retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction AvecErreur <Texte contenant potentiellement le tag d'erreur>
#---------------------------------------------------------------------------
function AvecErreur
{
    # Variables locales
    AE_TRUE="TRUE"  # if [ <chaine non vide>  ] => VRAI
    AE_FALSE=""     # if [ <chaine vide>      ] => FAUX

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction AvecErreur : parametre manquant"
        AfficherAnomalie "Usage : AvecErreur <Texte contenant potentiellement le tag d'erreur>"
        return $CR_KO
    fi

    if [ -z "$1" ]; then
        printf "$AE_FALSE"
        return 1
    fi

    # Rechercher le tag d'erreur dans le texte passe en parametre
    # Remarque : le fonction egrep renvoi :
    # - 0 si le tag d'erreur est trouve
    # - 1 si le tag d'erreur est absent
    echo "$1" | egrep -q "${TAG_ERREUR}"
    AE_CR=$?

    # Si le tag d'erreur est trouve
    if [ $AE_CR -eq 0 ]; then
        printf "$AE_TRUE"
    else
        printf "$AE_FALSE"
    fi

    # Retourner le resultat de la recherche du tag d'erreur
    return "$AE_CR"

}

#---------------------------------------------------------------------------
# Fonction AfficherInfo <texte du message a afficher>
#---------------------------------------------------------------------------
function AfficherInfo
{

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction AfficherInfo : parametre manquant"
        AfficherAnomalie "Usage : AfficherInfo <texte du message a afficher>"
        return $CR_KO
    fi

    # Afficher le message
    AfficherMessage " "
    AfficherMessage "    --> ${1}"
    AfficherMessage " "

    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction AfficherTitre <libelle du titre (en majuscule)>
#---------------------------------------------------------------------------
function AfficherTitre
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction AfficherTitre : parametre manquant"
        AfficherAnomalie "Usage : AfficherTitre <libelle du titre en majuscules>"
        return $CR_KO
    fi

    # Afficher le titre
    AfficherMessage " "
    AfficherMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    AfficherMessage " [X] ${1}"
    AfficherMessage "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    AfficherMessage " "

    # Retourner le succes du traitement
    return $CR_OK
}


#---------------------------------------------------------------------------
# Fonction AfficherEnteteTrait <Nom du traitement>
#---------------------------------------------------------------------------
function AfficherEnteteTrait
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction AfficherEnteteTrait : parametre manquant"
        AfficherAnomalie "Usage : AfficherEnteteTrait <Nom traitement>"
        return $CR_KO
    fi

    # Memoriser les parametres
    AET_NOM_TRAIT="$1"

    AfficherMessage ""
    AfficherMessage "========================================================================"
    AfficherMessage "EXECUTION DU TRAITEMENT PL/SQL [${AET_NOM_TRAIT}]"
    date
    AfficherMessage "========================================================================"
    AfficherMessage ""

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction AfficherFinTrait <NomTraitement> <Code retour> [<Message texte facultatif>]
#---------------------------------------------------------------------------
function AfficherFinTrait
{

    # Controler les parametres
    if [ $# -lt 2 ]; then
        AfficherAnomalie "Fonction AfficherFinTrait : parametre manquant"
        AfficherAnomalie "Usage : AfficherFinTrait <NomTraitement> <Code retour> [<Message texte facultatif>]"
        return $CR_KO
    fi

    # Memoriser les parametres
    AFT_NOM_TRAIT="$1"
    AFT_CODE_RET="$2"
    if [ $# -gt 2 ]; then
        shift
        shift
        AFT_MESSAGE_COMPLEMENTAIRE="$*"
    fi

    # Selon le code retour
    AFT_MESSAGE_FIN=""
    case $AFT_CODE_RET in
        $CR_OK)
            AFT_MESSAGE_FIN="SUCCES"
            ;;
        $CR_WARNING)
            AFT_MESSAGE_FIN="SUCCES PARTIEL (WARNING TECHNIQUE)"
            ;;
        $CR_KO)
            AFT_MESSAGE_FIN="ECHEC (ERREUR TECHNIQUE BLOQUANTE)"
            ;;
        $CR_KO_FONCTIONNEL)
            AFT_MESSAGE_FIN="ECHEC (ERREUR FONCTIONNELLE BLOQUANTE)"
            ;;
        $CR_KO_CRITIQUE)
            AFT_MESSAGE_FIN="ECHEC (ERREUR TECHNIQUE CRITIQUE)"
            ;;
        *)
            AfficherAnomalie "Fonction AfficherFinTrait : Parametre 'Code retour' invalide"
            AFT_MESSAGE_FIN="ECHEC (ERREUR TECHNIQUE BLOQUANTE)"
            ;;
    esac

    # Afficher un message de fin de traitement
    AfficherMessage ""
    AfficherMessage "==============================================================================="
    if [ -n "$AFT_MESSAGE_COMPLEMENTAIRE" ]; then
        AfficherMessage "$AFT_MESSAGE_COMPLEMENTAIRE"
    fi
    AfficherMessage "FIN TRAITEMENT [${AFT_NOM_TRAIT}] - $AFT_MESSAGE_FIN - CR=$AFT_CODE_RET - $(date)"
    AfficherMessage "==============================================================================="
    AfficherMessage ""

    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction FormaterNomTraitement <Nom traitement>
#---------------------------------------------------------------------------
function FormaterNomTraitement
{

    # Variables locales
    typeset -u FNT_NOM_TRAIT=""

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction FormaterNomTraitement : parametre manquant"
        AfficherAnomalie "Usage : FormaterNomTraitement <Nom traitement>"
        return $CR_KO
    fi

    # Formater le nom du traitement en :
    # - eliminant les espaces
    # - formattant en majuscules
    # - eliminant l'éventuelle présence de l'extension .ksh ou d'un chemin
    FNT_NOM_TRAIT="$1"
    FNT_NOM_TRAIT="$(echo "$FNT_NOM_TRAIT" | tr -d ' ')"
    FNT_NOM_TRAIT="$(basename "$FNT_NOM_TRAIT" .KSH)"

    # Afficher le nom du traitement formate
    print "$FNT_NOM_TRAIT"

    # retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction ControlerNomTraitement <Nom traitement>
#---------------------------------------------------------------------------
function ControlerNomTraitement
{
#    # Variables locales
#    typeset -u CNT_NOM_TRAIT=""
#    CNT_FORMAT_TRAIT="AACCCOOOOOOpp"
#    CNT_CODE_APPLI=""
#    CNT_CODE_APPLI_TRAIT=""
#
#    # Controler les parametres
#    if [ $# -ne 1 ]; then
#        AfficherAnomalie "Fonction ControlerNomTraitement : parametre manquant"
#        AfficherAnomalie "Usage : ControlerNomTraitement <Nom traitement>"
#        return $CR_KO
#    fi
#
#    # Memoriser le parametre
#    CNT_NOM_TRAIT="$1"
#
#    # Remarque :
#    # Selon le document "Recommandations et Normes pour les ETUDES.doc"
#    # un nom de traitement est suppose avoir le format suivant "AACCCOOOOOOpp"
#    # avec :
#    # AA     : Code applicatif
#    # CCC    : type de traitement (MAJ : mise a jour, DEL : delete...)
#    # OOOOOO : libelle libre entre 3 et 6 caracteres specifiques du traitement
#    # pp     : numero de sequence du traitement
#
#    # Verifier que le nom de traitement est renseigne
#    if [ -z "${CNT_NOM_TRAIT}" ]; then
#        AfficherAnomalie "Fonction ControlerNomTraitement : Nom de traitement non renseigne"
#        return $CR_KO
#    fi
#
#    # Verifier que le nom du traitement ne depasse pas le nombre de caracteres
#    # du format recommande pour les noms de traitement
#    if [ ${#CNT_NOM_TRAIT} -gt ${#CNT_FORMAT_TRAIT} ]; then
#        AfficherAnomalie "Fonction ControlerNomTraitement : Nom de traitement [${CNT_NOM_TRAIT}] trop long (ne respecte pas le format [${CNT_FORMAT_TRAIT}])"
#        return $CR_KO
#    fi
#
#    # Verifier que les deux premier caractere du nom de traitement
#    # correspondent au code application
#    CNT_CODE_APPLI="$CODE_APPLI"
#    CNT_CODE_APPLI_TRAIT="$(echo "$CNT_NOM_TRAIT" | cut -c 1-2)"
#    if [ "$CNT_CODE_APPLI_TRAIT" != "$CNT_CODE_APPLI" ]; then
#        AfficherAnomalie "Fonction ControlerNomTraitement : le traitement [${CNT_NOM_TRAIT}] n'appartient pas au code applicatif [${CNT_CODE_APPLI}]"
#        return $CR_KO
#    fi

    # retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction FormaterNomBase <Nom base>
#---------------------------------------------------------------------------
function FormaterNomBase
{

    # Variables locales
    typeset -u FNB_NOM_BASE=""

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction FormaterNomBase : parametre manquant"
        AfficherAnomalie "Usage : FormaterNomBase <Nom base>"
        return $CR_KO
    fi

    # Formater le nom de la base en :
    # - eliminant les espaces
    # - formatant en majuscules
    FNB_NOM_BASE="$(echo "$1" | tr -d ' ')"

    # Afficher le nom de la base formate
    print "$FNB_NOM_BASE"

    # retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction ControlerNomBase <Nom Base>
#---------------------------------------------------------------------------
function ControlerNomBase
{
#    # Variables locales
#    typeset -u CNB_NOM_BASE=""
#    CNB_SITE="PA"
#
#    # Controler les parametres
#    if [ $# -ne 1 ]; then
#        AfficherAnomalie "Fonction ControlerNomBase : parametre manquant"
#        AfficherAnomalie "Usage : ControlerNomBase <Nom Base>"
#        return $CR_KO
#    fi
#
#    # Memoriser le parametre
#    CNB_NOM_BASE="$1"
#
#    # Verifier que le nom de la base est renseigne
#    if [ -z "$CNB_NOM_BASE" ]; then
#        AfficherAnomalie "Fonction ControlerNomBase : Nom de base est non renseignee"
#        return $CR_KO
#    fi
#
#    # Remarque :
#    # un nom de base de donnee est suppose commencer par deux caracteres
#    # indiquant le site
#
#    # Verifier que le nom de la base est compatible avec le site PA
#    if [ "$(echo "${CNB_NOM_BASE}" | cut -c 1-2)" != "${CNB_SITE}" ]; then
#        AfficherAnomalie "Fonction ControlerNomBase : Nom de base [${CNB_NOM_BASE}] n'appartient pas au site [${CNB_SITE}]"
#        return $CR_KO
#    fi

    # retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction ControlerNomUser <Nom User>
#---------------------------------------------------------------------------
function ControlerNomUser
{
    # Variables locales
    typeset -u CNU_NOM_USER=""
    CNB_PREFIXE_USER="EXP_"

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction ControlerNomUser : parametre manquant"
        AfficherAnomalie "Usage : ControlerNomUser <Nom User>"
        return $CR_KO
    fi

    # Memoriser le parametre
    CNU_NOM_USER="$1"

    # Verifier que le nom du user est bien renseigne
    if [ -z "${CNU_NOM_USER}" ]; then
        AfficherAnomalie "Fonction ControlerNomUser : Nom user non renseigne"
        return $CR_KO
    fi

    # Verifier que le nom du user commence bien par le prefixe attendu
    if [ "$(echo "${CNU_NOM_USER}" | cut -c 1-4)" != "${CNB_PREFIXE_USER}" ]; then
        AfficherAnomalie "Fonction ControlerNomUser : Nom user [${CNU_NOM_USER}] ne commence pas par le prefixe [${CNB_PREFIXE_USER}]"
        return $CR_KO
    fi

    # retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction FormaterModeDeclench <Mode de declenchement du traitement>
#---------------------------------------------------------------------------
function FormaterModeDeclench
{

    # Variables locales
    typeset -u FMD_MODE_DECLENCH=""

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction FormaterModeDeclench : parametre manquant"
        AfficherAnomalie "Usage : FormaterModeDeclench <Mode de declenchement du traitement>"
        return $CR_KO
    fi

    # Formater le nom de la base en :
    # - eliminant les espaces
    # - formatant en majuscules
    FMD_MODE_DECLENCH="$(echo "$1" | tr -d ' ')"

    # Afficher le nom de la base formate
    print "$FMD_MODE_DECLENCH"

    # retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction ControlerModeExec <Mode de declenchement du traitement>
#---------------------------------------------------------------------------
function ControlerModeExec
{
    # Variables locales
    typeset -u CMD_MODE_DECLENCH=""

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction ControlerModeExec : parametre manquant"
        AfficherAnomalie "Usage : ControlerModeExec <Mode de declenchement du traitement>"
        return $CR_KO
    fi

    # Memoriser le parametre
    CMD_MODE_DECLENCH="$1"

    # Verifier que le mode de declenchement
    # correspond a une des valeurs suivantes :
    # USER
    # AUTO
    echo $CMD_MODE_DECLENCH | egrep -q "(USER|AUTO)"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction ControlerModeExec : Mode de declenchement [${CMD_MODE_DECLENCH}] non valide"
        return $CR_KO
    fi

    # retourner le succes du traitement
    return $CR_OK
}


#---------------------------------------------------------------------------
# Fonction GetEnvironnement
#---------------------------------------------------------------------------

function GetEnvironnement
{
    # Afficher l'environnement
	if [ $ENVIRONNEMENT = "Q" ] || [ $ENVIRONNEMENT = "X" ]; then
			printf "R"
			return $CR_OK
	fi
    printf "$ENVIRONNEMENT"

    return $CR_OK
}

#------------------------------------------------------------------------------------------
# Fonction ExecScriptSQL <Nom base> <Nom User> <Nom Fichier SQL> <Parametres du script SQL>
#------------------------------------------------------------------------------------------
function ExecScriptSQL
{
    # Controler les parametres
    if [ $# -lt 3 ]; then
        AfficherAnomalie "Fonction ExecScriptSQL : parametre manquant"
        AfficherAnomalie "Usage : ExecScriptSQL <Nom base> <Nom User> <Nom Fichier SQL> <Parametres du script SQL>"
        return $CR_KO
    fi

    # Memoriser les parametres
    ESS_NOM_BASE="$1"
    ESS_NOM_USER="$2"
    ESS_NOM_FIC_SQL="$3"
    shift; shift; shift
    ESS_PARAM_FIC_SQL="$*"


    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    #ESS_ORACLE_SID_OLD="$ORACLE_SID"
    export ORACLE_SID="$ESS_NOM_BASE"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # Afficher le contexte d'execution du script SQL
    AfficherInfo "Base d'execution  : [${ORACLE_SID}]"
    AfficherInfo "Schema utilise    : [${ESS_NOM_USER}]"
    AfficherInfo "Script SQL        : [${ESS_NOM_FIC_SQL}]"
    AfficherInfo "Parametres script : [${ESS_PARAM_FIC_SQL}]"

    # Executer le script
    AfficherInfo "Debut du script PL/SQL : $(date)"

    # <MODIF> DVA - 11/08/08 - 1.01
    #         Modification des parametres d'appel du XXEXESQLORA01.ksh
    #         - suppression du parametre -e
    # <MODIF> JHI 04/05/2009 EVSIF
    #         remplacement de l'option -b par -c pour acces base a distance
    #         en fonction du parametre nom base :
    #         si oracle sid alors on est en local -> -b
    #         si tns alors on est en accès distant -> -c

    # Si on trouve ".WORLD" dans l'ORACLE_SID on est en mode distant
    #if [[ ! -n ${ORACLE_SID#*.WORLD} ]] ; then
        ESS_LOC_DIST="-c ${ORACLE_SID}"
    #else
        # Sinon on est en mode local
    #    ESS_LOC_DIST="-b ${ORACLE_SID}"
    #fi

    echo "XXEXESQLORA01.ksh "
    echo "    -n $ESS_NOM_FIC_SQL"
    echo "    $ESS_LOC_DIST "
    #echo "    -e "
    echo "    -u $ESS_NOM_USER "
    echo "    $ESS_NOM_FIC_SQL "
    echo "    $ESS_PARAM_FIC_SQL"

    #XXEXESQLORA01.ksh \
    #    -n "$ESS_NOM_FIC_SQL" \
    #    -b "$ORACLE_SID" \
    #    -e \
    #    -u "$ESS_NOM_USER" \
    #    "$ESS_NOM_FIC_SQL" \
    #    "$ESS_PARAM_FIC_SQL"

    XXEXESQLORA01.ksh \
        -n "$ESS_NOM_FIC_SQL" \
        "$ESS_LOC_DIST" \
        -u "$ESS_NOM_USER" \
        "$ESS_NOM_FIC_SQL" \
        "$ESS_PARAM_FIC_SQL"
    ESS_CR_XXEXESQLORA01=$?

    # </MODIF>

    AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$ESS_CR_XXEXESQLORA01)"

    # Restaurer la base de donnee courante initiale
    #export ORACLE_SID="$ESS_ORACLE_SID_OLD"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # retourner le resultat du traitement
    return "$ESS_CR_XXEXESQLORA01"
}

#---------------------------------------------------------------------------
# Fonction ExecScriptSQLPlus <Nom base> <Nom User> <Nom Fichier SQL> <Parametres du script SQL>
#---------------------------------------------------------------------------
function ExecScriptSQLPlus
{
    # Controler les parametres
    if [ $# -lt 3 ]; then
        AfficherAnomalie "Fonction ExecScriptSQLPlus : parametre manquant"
        AfficherAnomalie "Usage : ExecScriptSQLPlus <Nom base> <Nom User> <Nom Fichier SQL> <Parametres du script SQL>"
        return $CR_KO
    fi

    # Memoriser les parametres
    ESSP_NOM_BASE="$1"
    ESSP_NOM_USER="$2"
    ESSP_NOM_FIC_SQL="$3"
    shift; shift; shift
    ESSP_PARAM_FIC_SQL="$*"


    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    ESSP_ORACLE_SID_OLD="$ORACLE_SID"

    #ESSP_NOM_BASE est au format chaine complete 'nombase-serveur'
    ORACLE_SID=$(echo $ESSP_NOM_BASE | awk -F'-' '{print $1}')

    eval $(PC_ENV_INSORA "$ORACLE_SID")

    # Afficher le contexte d'execution du script SQL
    AfficherInfo "Base d'execution  : [${ORACLE_SID}]"
    AfficherInfo "Schema utilise    : [${ESSP_NOM_USER}]"
    AfficherInfo "Script SQL        : [${ESSP_NOM_FIC_SQL}]"
    AfficherInfo "Parametres script : [${ESSP_PARAM_FIC_SQL}]"

    # Executer le script
    AfficherInfo "Debut du script PL/SQL : $(date)"


    echo " sqlplus "
    echo "    $ESSP_NOM_FIC_SQL"
    echo "     $ORACLE_SID "
    echo "     $ESSP_NOM_BASE "
    echo "     $ESSP_NOM_USER "
    echo "    $ESSP_NOM_FIC_SQL "
    echo "    $ESSP_PARAM_FIC_SQL"


    ESSP_NOM="$(find $DBORA_APPLI -name $(basename $ESSP_NOM_FIC_SQL))"
    if [ "$(echo "$ESSP_NOM" | wc -w)" -eq 1 ] ; then
       ESSP_NOM_FIC_SQL=$ESSP_NOM
    else
       AfficherAnomalie"Fonction ExecScriptSQLPlus : Fichier script [$ESSP_NOM_FIC_SQL] introuvable"
       return $CR_KO
    fi

    ORAPASS=$(PC_PASSWD_INSORA $ORACLE_SID $ESSP_NOM_USER)
    if [ $? -eq 0 ]; then
       ESSP_COMMAND="sqlplus -s $ESSP_NOM_USER/$ORAPASS@$ESSP_NOM_BASE"
       AfficherInfo "Execution commande : $ESSP_COMMAND"
    else
       AfficherAnomalie"Fonction ExecScriptSQLPlus : Mot de passe non trouve pour user [$ESSP_NOM_USER] "
       return $CR_KO
    fi

    #Execution du script
$ESSP_COMMAND <<EOF
      @$ESSP_NOM_FIC_SQL $ESSP_PARAM_FIC_SQL
	  exit
EOF

    ESSP_CR_XXEXESQLPLUS=$?

    AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$ESSP_CR_XXEXESQLPLUS)"

    # Restaurer la base de donnee courante initiale
    export ORACLE_SID="$ESSP_ORACLE_SID_OLD"
    eval $(PC_ENV_INSORA "$ORACLE_SID")

    # retourner le resultat du traitement
    return "$ESSP_CR_XXEXESQLORA01"
}

#-------------------------------------------------------------------------------------------
# Fonction ExecSQLLoader <Nom base>
#                        <Nom User>
#                        <Nom Table>
#                        <Fichier dat a charger>
#                        <Fichier de controle>
#                        <NoTruncate> (pour desactiver le truncate par defaut)
#                        <ArgSqlldrSup> (liste des arguments supplementaires separes pas un espace)
#                                       (ex : "direct=y rows=all")
#-------------------------------------------------------------------------------------------
function ExecSQLLoader
{
    # Controler les parametres
    if [ $# -lt 5 ]; then
        AfficherAnomalie "Fonction ExecSQLLoader : parametre manquant"
        AfficherAnomalie "Usage : ExecSQLLoader <Nom base> <Nom User> <Nom Table> <Fichier dat a charger> <Fichier de controle> [<NoTruncate> <ArgSqlldrSup>]"
        return $CR_KO
    fi

    # Memoriser les parametres
    ESL_NOM_BASE="$1"
    ESL_NOM_USER="$2"
    ESL_NOM_TABLE="$3"
    ESL_FIC_DAT="$4"
    ESL_FIC_CTL="$5"
    ESL_TRUNCATE="$6"
    ESL_ARGSQLLDRSUP="$7"

    # Afficher le contexte d'execution du script SQL
    AfficherInfo "Base d'execution  :           [${ESL_NOM_BASE}]"
    AfficherInfo "Schema utilise    :           [${ESL_NOM_USER}]"
    AfficherInfo "Nom de(s) table(s) cible(s) : [${ESL_NOM_TABLE}]"
    AfficherInfo "Fichier dat :                 [${ESL_FIC_DAT}]"
    AfficherInfo "Fichier ctl :                 [${ESL_FIC_CTL}]"

    # Executer le script
    AfficherInfo "Debut du script PL/SQL : $(date)"

    # Si truncate est vide alors on effectue un truncate, sinon non
    if [ -z "$ESL_TRUNCATE" ]; then
        echo "XXLOATABORA01.ksh "
        echo "    -T"
        echo "    -D"
        echo "    -d"
        echo "    -o ${ESL_NOM_BASE}"
        echo "    -u ${ESL_NOM_USER} ${ESL_NOM_TABLE} ${ESL_FIC_DAT} ${ESL_FIC_CTL}"
        echo "     $ESL_ARGSQLLDRSUP"

        # sleep 60
        XXLOATABORA01.ksh -T -D -d -o "$ESL_NOM_BASE" -u "$ESL_NOM_USER" "$ESL_NOM_TABLE" "$ESL_FIC_DAT" "$ESL_FIC_CTL" "$ESL_ARGSQLLDRSUP"
    else
        echo "XXLOATABORA01.ksh "
        echo "    -D"
        echo "    -d"
        echo "    -o ${ESL_NOM_BASE}"
        echo "    -u ${ESL_NOM_USER} ${ESL_NOM_TABLE} ${ESL_FIC_DAT} ${ESL_FIC_CTL}"
        echo "     $ESL_ARGSQLLDRSUP"

        sleep 60
        XXLOATABORA01.ksh -D -d -o "$ESL_NOM_BASE" -u "$ESL_NOM_USER" "$ESL_NOM_TABLE" "$ESL_FIC_DAT" "$ESL_FIC_CTL" "$ESL_ARGSQLLDRSUP"
    fi
        ESL_CR_XXLOATABORA01=$?

    AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$ESL_CR_XXLOATABORA01)"

    # retourner le resultat du traitement
    return "$ESL_CR_XXLOATABORA01"
}

#---------------------------------------------------------------------------
# Fonction GetRepFichierFlag
#---------------------------------------------------------------------------
function GetRepFichierFlag
{
    # Fixer le repertoire du fichier FLAG de declenchement de la chaine
    # au repertoire temporaire associe a l'application courante
    GRFF_REP_FIC_FLAG="${TEMP_APPLI}"

    # Verifier l'existence du repertoire
    if [ ! -d $GRFF_REP_FIC_FLAG ]; then
        AfficherAnomalie"Fonction GetRepFichierFlag : Repertoire du fichier de declenchement [$GRFF_REP_FIC_FLAG] introuvable"
        return $CR_KO
    fi

    # Afficher le repertoire du fichier flag
    print "${GRFF_REP_FIC_FLAG}"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetDebNomFichierFlag <Nom de la chaine>
#---------------------------------------------------------------------------
function GetDebNomFichierFlag
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetDebNomFichierFlag : parametre manquant"
        AfficherAnomalie "Usage : GetDebNomFichierFlag <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GDNFF_NOM_CHAINE="$1"

    # Afficher le debut du nom du fichier flag = nom de la chaine en parametre
    print "$GDNFF_NOM_CHAINE"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetFichierFlag <Nom de la chaine>
#---------------------------------------------------------------------------
function GetFichierFlag
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetFichierFlag : parametre manquant"
        AfficherAnomalie "Usage : GetFichierFlag <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GFF_NOM_CHAINE="$1"

    # Lire le repertoire du fichier FLAG de declenchement du traitement
    GFF_REP_FIC_FLAG="$(GetRepFichierFlag)"
    if [ "$(AvecErreur "$GFF_REP_FIC_FLAG")" ]; then
        AfficherMessage "$GFF_REP_FIC_FLAG"
        AfficherAnomalie "Fonction GetFichierFlag : Impossible de determiner le repertoire du fichier de declenchement"
        return $CR_KO
    fi

    # Construire le debut du nom du fichier FLAG de declenchement
    GFF_DEBUT_NOM_FIC_FLAG="$(GetDebNomFichierFlag "$GFF_NOM_CHAINE")"
    if [ $(AvecErreur "$GFF_DEBUT_NOM_FIC_FLAG") ]; then
        AfficherMessage "$GFF_DEBUT_NOM_FIC_FLAG"
        AfficherAnomalie "Fonction GetFichierFlag : Impossible de determiner le debut du nom du fichier de declenchement"
        return $CR_KO
    fi

    # Rechercher le fichier FLAG de declenchement et afficher son nom complet
    # Format du nom complet du fichier :
    # <Repertoire fichier flag>/<Nom du traitement>.flag (ancienne norme)
    # ou
    # <Repertoire fichier flag>/<Nom du traitement>_<Id. declenchement>.flag (nouvelle norme)
    # Dans ce dernier cas, il peut y avoir plusieurs fichiers flag
    # dans le repertoire. Il faut donc choisir le plus recent
    if [ ! -r ${GFF_REP_FIC_FLAG}/${GFF_DEBUT_NOM_FIC_FLAG}*.flag  ]; then
        AfficherAnomalie "Fonction GetFichierFlag : Fichier de declenchement [${GFF_REP_FIC_FLAG}/${GFF_DEBUT_NOM_FIC_FLAG}\*.flag] introuvable !"
        AfficherAnomalie "Fonction GetFichierFlag : Liste des fichiers flag existant : $(ls -tr ${GFF_REP_FIC_FLAG}/${GFF_DEBUT_NOM_FIC_FLAG}*.flag)"
        return $CR_KO
    fi
    GFF_FIC_FLAG_NOM_COMPLET="$(ls -tr ${GFF_REP_FIC_FLAG}/${GFF_DEBUT_NOM_FIC_FLAG}*.flag | head -1)"
    print "$GFF_FIC_FLAG_NOM_COMPLET"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetFichierFlagEnCours <Nom de la chaine>
#---------------------------------------------------------------------------
function GetFichierFlagEnCours
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetFichierFlagEnCours : parametre manquant"
        AfficherAnomalie "Usage : GetFichierFlagEnCours <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GFFEC_NOM_CHAINE="$1"

    # Lire le repertoire du fichier FLAG de declenchement du traitement
    GFFEC_REP_FIC_FLAG="$(GetRepFichierFlag)"
    if [ "$(AvecErreur "$GFFEC_REP_FIC_FLAG")" ]; then
        AfficherMessage "$GFFEC_REP_FIC_FLAG"
        AfficherAnomalie "Fonction GetFichierFlagEnCours : Impossible de determiner le repertoire du fichier de declenchement"
        return $CR_KO
    fi

    # Construire le debut du nom du fichier FLAG de declenchement
    GFFEC_DEBUT_NOM_FIC_FLAG="$(GetDebNomFichierFlag "$GFFEC_NOM_CHAINE")"
    if [ $(AvecErreur "$GFFEC_DEBUT_NOM_FIC_FLAG") ]; then
        AfficherMessage "$GFFEC_DEBUT_NOM_FIC_FLAG"
        AfficherAnomalie "Fonction GetFichierFlagEnCours : Impossible de determiner le debut du nom du fichier de declenchement"
        return $CR_KO
    fi

    # Rechercher le fichier encours qui a servi au declenchement et afficher son nom complet
    # Format du nom complet du fichier :
    # <Repertoire fichier flag>/<Nom du traitement>_<Id. declenchement>.encours (nouvelle norme)
    # Dans ce dernier cas, il peut y avoir plusieurs fichiers flag
    # dans le repertoire. Il faut donc choisir le plus recent
    if [ ! -r ${GFFEC_REP_FIC_FLAG}/${GFFEC_DEBUT_NOM_FIC_FLAG}*.encours  ]; then
        AfficherAnomalie "Fonction GetFichierFlagEnCours : Fichier de declenchement [${GFFEC_REP_FIC_FLAG}/${GFFEC_DEBUT_NOM_FIC_FLAG}\*.encours] introuvable !"
        AfficherAnomalie "Fonction GetFichierFlagEnCours : Liste des fichiers de declenchement existants : $(ls -tr ${GFFEC_REP_FIC_FLAG}/${GFFEC_DEBUT_NOM_FIC_FLAG}*.encours)"
        return $CR_WARNING
    fi
    GFFEC_FIC_FLAG_NOM_COMPLET="$(ls -tr ${GFFEC_REP_FIC_FLAG}/${GFFEC_DEBUT_NOM_FIC_FLAG}*.encours | head -1)"
    print "$GFFEC_FIC_FLAG_NOM_COMPLET"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction CreerFicFlag <Nom de la chaine> <Identifiant de declenchement>
#---------------------------------------------------------------------------
function CreerFicFlag
{
    # Controler les parametres
    if [ $# -ne 2 ]; then
        AfficherAnomalie "Fonction CreerFicFlag : parametre(s) manquant(s)"
        AfficherAnomalie "Usage : CreerFicFlag <Nom de la chaine> <Identifiant de declenchement>"
        return $CR_KO
    fi

    # Memoriser le parametre
    CFF_NOM_CHAINE="$1"
    CFF_ID_DEC="$2"

    # Determiner l'emplacement et le nom du fichier FLAG de declenchement
    # de la chaine
    CFF_REP_FIC_FLAG="$(GetRepFichierFlag "$CFF_NOM_CHAINE")"
    if [ "$(AvecErreur "$CFF_REP_FIC_FLAG")" ]; then
        AfficherMessage "$CFF_REP_FIC_FLAG"
        AfficherAnomalie "Fonction CreerFicFlag : Repertoire d'ecriture du fichier de declenchement indetermine"
        return $CR_KO
    fi

    # Verifier l'existence du répertoire
    # et les droits d'ecriture dans le repertoire
    if [ ! -r $CFF_REP_FIC_FLAG ]; then
        AfficherAnomalie "Fonction CreerFicFlag : Repertoire d'ecriture du fichier inexistant ou interdit a la lecture"
        return $CR_KO
    fi

    # Construire le nom du fichier flag
    CFF_NOM_FIC_FLAG="${CFF_REP_FIC_FLAG}/${CFF_NOM_TRAIT}_${CFF_ID_DEC}.flag"

    # Creer le fichier de declenchement
    # - en le nommant comme suit : <nom chaine>_<Id declenchement>.flag
    # - en le completant avant l'identifiant de declenchement (1ere ligne)
    echo "$CFF_ID_DEC" > "$CFF_NOM_FIC_FLAG"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction CreerFicFlagVide <Nom de la chaine>
#---------------------------------------------------------------------------
function CreerFicFlagVide
{
    # Controler le parametre
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction CreerFicFlagVide : parametre manquant"
        AfficherAnomalie "Usage : CreerFicFlagVide <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    CFFV_NOM_CHAINE="$1"

    # Determiner l'emplacement et le nom du fichier FLAG de declenchement
    # de la chaine
    CFFV_REP_FIC_FLAG="$(GetRepFichierFlag "$CFFV_NOM_CHAINE")"
    if [ "$(AvecErreur "$CFFV_REP_FIC_FLAG")" ]; then
        AfficherMessage "$CFFV_REP_FIC_FLAG"
        AfficherAnomalie "Fonction CreerFicFlagVide : Repertoire d'ecriture du fichier de declenchement indetermine"
        return $CR_KO
    fi

    # Verifier l'existence du répertoire
    # et les droits d'ecriture dans le repertoire
    if [ ! -r $CFFV_REP_FIC_FLAG ]; then
        AfficherAnomalie "Fonction CreerFicFlagVide : Repertoire d'ecriture du fichier inexistant ou interdit a la lecture"
        return $CR_KO
    fi

    # Construire le nom du fichier flag
    CFFV_NOM_FIC_FLAG="${CFFV_REP_FIC_FLAG}/${CFFV_NOM_TRAIT}.flag"

    # Creer le fichier FLAG
    # - en le nommant comme suit : <nom chaine>.flag
    # - en attribuant les droits d'ecriture au compte unix Oracle
    #   qui mettra a jour le fichier ulterieurement
    > "$CFFV_NOM_FIC_FLAG"
    chmod 664 "$CFFV_NOM_FIC_FLAG"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction SupprimerFicFlag <Nom de la chaine>
#---------------------------------------------------------------------------
function SupprimerFicFlag
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction SupprimerFicFlag : parametre manquant"
        AfficherAnomalie "Usage : SupprimerFicFlag <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    SFF_NOM_CHAINE="$1"

    # Determiner l'emplacement et le nom du fichier FLAG de declenchement
    # de la chaine
    SFF_FIC_FLAG="$(GetFichierFlagEnCours "$SFF_NOM_CHAINE")"
    if [ "$(AvecErreur "$SFF_FIC_FLAG")" ]; then
        AfficherMessage "$SFF_FIC_FLAG"
        AfficherAnomalie "Fonction SupprimerFicFlag : Fichier de declenchement introuvable"
        return $CR_WARNING
    else
        AfficherMessage "Succes suppression ${SFF_FIC_FLAG}"
    fi

    # Supprimer le fichier
    rm -f "$SFF_FIC_FLAG"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetIdDeclenchement <Nom de la chaine>
#---------------------------------------------------------------------------
function GetIdDeclenchement
{

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetIdDeclenchement : parametre manquant"
        AfficherAnomalie "Usage : GetIdDeclenchement <Nom du traitement>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GID_NOM_CHAINE="$1"

    # Determiner l'emplacement et le nom du fichier FLAG de declenchement
    # de la chaine
    GID_FIC_FLAG="$(GetFichierFlag "$GID_NOM_CHAINE")"
    if [ "$(AvecErreur "$GID_FIC_FLAG")" ]; then
        AfficherMessage "$GID_FIC_FLAG"
        AfficherAnomalie "Fonction GetIdDeclenchement : Impossible d'acceder au fichier de declenchement"
        return $CR_KO
    fi

    # Lire l'identifiant de declenchement DTC
    # sur la 1ere ligne du fichier FLAG
    GID_NUM_DECLENCH="$(cat "$GID_FIC_FLAG" | tr -d '\15\32' | sed -n 1p)"

    # Afficher l'identifiant de declenchement
    printf "$GID_NUM_DECLENCH"

    # Retourner le succes du traitement
    return $CR_OK
}
#---------------------------------------------------------------------------
# Fonction GetIdDeclenchementEncours <Nom de la chaine>
#     <ADD /> FAU - 15/10/08 - 1.02
#---------------------------------------------------------------------------
function GetIdDeclenchementEncours
{

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetIdDeclenchementEncours : parametre manquant"
        AfficherAnomalie "Usage : GetIdDeclenchementEncours <Nom du traitement>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GIDC_NOM_CHAINE="$1"

    # Determiner l'emplacement et le nom du fichier FLAG de declenchement
    # de la chaine
    GIDC_FIC_FLAG="$(GetFichierFlagEnCours "$GIDC_NOM_CHAINE")"
    if [ "$(AvecErreur "$GIDC_FIC_FLAG")" ]; then
        AfficherMessage "$GIDC_FIC_FLAG"
        AfficherAnomalie "Fonction GetIdDeclenchementEncours : Impossible d'acceder au fichier de declenchement"
        return $CR_KO
    fi

    # Lire l'identifiant de declenchement DTC
    # sur la 1ere ligne du fichier FLAG
    GIDC_NUM_DECLENCH="$(cat "$GIDC_FIC_FLAG" | tr -d '\15\32' | sed -n 1p)"

    # Afficher l'identifiant de declenchement
    printf "$GIDC_NUM_DECLENCH"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetScriptSQL <Nom Traitement>
#---------------------------------------------------------------------------
function GetScriptSQL
{

    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetScriptSQL : parametre manquant"
        AfficherAnomalie "Usage : GetScriptSQL <Nom du traitement>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GSS_NOM_TRAIT="$1"

    # Construire le nom du fichier script SQL a executer
    # selon le format <nom du traitement ksh courant (sans extension)>.sql
    GSS_SCRIPT_SQL="$(basename "$GSS_NOM_TRAIT" .ksh).sql"

    # Afficher le nom du fichier script SQL
    print "$GSS_SCRIPT_SQL"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetXMLVal <chaine xml> <Nom balise a lire>
#---------------------------------------------------------------------------
function GetXMLVal
{

    # Controler les parametres
    if [ $# -ne 2 ]; then
        AfficherAnomalie "Fonction GetXMLVal : parametre(s) manquant(s)"
        AfficherAnomalie "Usage : GetXMLVal <chaine xml> <Nom balise a lire>"
        return $CR_KO
    fi

    # Memoriser les parametres
    GXV_XML="$1"
    GXV_BALISE="$2"

    # ATTENTION : IL FAUT RESPECTER LA CASSE DU NOM DE LA BALISE !!

    # Nom de la balise
    typeset -u GXV_BALISE_MIN="$GXV_BALISE"
    typeset -l GXV_BALISE_MAJ="$GXV_BALISE"

    # Extraire la valeur de la balise de la chaine XML
    # a partir du nom de la balise
    printf "$(echo "$GXV_XML" | \
             grep "<$GXV_BALISE>.*<.$GXV_BALISE>" | \
             sed -e "s/^.*<$GXV_BALISE/<$GXV_BALISE/" | \
             cut -f2 -d">"| \
             cut -f1 -d"<")"

    # Retourner le succes du traitement
    return $CR_OK
}

#-------------------------------------------------------------------------------
# Fonction SetXMLVal <chaine xml> <Nom balise a mettre a jour> <Nouvelle valeur>
#-------------------------------------------------------------------------------
function SetXMLVal
{

    # Controler les parametres
    if [ $# -ne 3 ]; then
        AfficherAnomalie "Fonction SetXMLVal : parametre(s) manquant(s)"
        AfficherAnomalie "Usage : SetXMLVal <chaine xml> <Nom balise a mettre a jour> <Nouvelle valeur>"
        return $CR_KO
    fi

    # Memoriser les parametres
    SXV_XML="$1"
    SXV_BALISE="$2"
    SXV_VAL="$3"

    # ATTENTION : IL FAUT RESPECTER LA CASSE DU NOM DE LA BALISE !!

    # Si la balise a mettre a jour existe dans la chaine XML

    echo "$SXV_XML" | grep -s -e "^.*<$SXV_BALISE>.*<\/$SXV_BALISE>.*$" > /dev/null
    if [ $? -eq 0 ]; then

        # Mettre a jour la valeur de la balise de la chaine XML
        # a partir du nom de la balise et de sa valeur en parametre
        printf "$(echo "$SXV_XML" | \
                 sed -e "s/\(^.*<${SXV_BALISE}>\).*\(<\/${SXV_BALISE}>.*$\)/\1${SXV_VAL}\2/")"

    # Sinon
    else
        # Ajouter la balise et sa valeur a la fin de la chaine XML
        # a partir du nom de la balise et de sa valeur en parametre
        printf "${SXV_XML}<$SXV_BALISE>${SXV_VAL}</$SXV_BALISE>"

    fi

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction SetInfoTrait -i <InfoTrait>
#                       -t <Nom Traitement>
#                       -c <Nom Chaine>
#                       -x <Id. Exec>
#                       -m <Mode Exec>
#                       -u <Id User>
#                       -r <Role User>
#                       -e <Environnement (D,R,P)>
#---------------------------------------------------------------------------
function SetInfoTrait
{

    # Declaration des variables
    typeset -i FLAG_NOM_TRAIT=0
    typeset -i FLAG_NOM_CHAINE=0
    typeset -i FLAG_ID_EXEC=0
    typeset -i FLAG_MODE_EXEC=0
    typeset -i FLAG_ID_USER=0
    typeset -i FLAG_ROLE_USER=0
    typeset -i FLAG_ENVIRONNEMENT=0

    # Lecture des parametres
    while getopts i:t:c:x:m:u:r:e: OPTION
    do
        case "$OPTION" in
           i) SIT_PARAM_INFO_TRAIT="$OPTARG"
              ;;
           t) SIT_PARAM_NOM_TRAIT="$OPTARG"
              FLAG_NOM_TRAIT=1
              ;;
           c) SIT_PARAM_NOM_CHAINE="$OPTARG"
              FLAG_NOM_CHAINE=1
              ;;
           x) SIT_PARAM_ID_EXEC="$OPTARG"
              FLAG_ID_EXEC=1
              ;;
           m) SIT_PARAM_MODE_EXEC="$OPTARG"
              FLAG_MODE_EXEC=1
              ;;
           u) SIT_PARAM_ID_USER="$OPTARG"
              FLAG_ID_USER=1
              ;;
           r) SIT_PARAM_ROLE_USER="$OPTARG"
              FLAG_ROLE_USER=1
              ;;
           e) typeset -u SIT_PARAM_ENVIRONNEMENT="$OPTARG"
              FLAG_ENVIRONNEMENT=1
              ;;
           ?) AfficherAnomalie "Option inconnue"
              AfficherAnomalie "Usage : SetInfoTrait -i <InfoTrait> <-t Nom Traitement> <-c Nom Chaine> <-x Id. Exec> <-m Mode Exec> <-u Id User> <-r Role User> <-i Rep In> <-e Environnement (D,R,P)>"
              return $CR_KO
              ;;
        esac
    done

    # Memoriser les parametres
    SIT_INFO_TRAIT="$SIT_PARAM_INFO_TRAIT"
    SIT_NOM_TRAIT="$SIT_PARAM_NOM_TRAIT"
    SIT_NOM_CHAINE="$SIT_PARAM_NOM_CHAINE"
    SIT_ID_EXEC="$SIT_PARAM_ID_EXEC"
    SIT_MODE_EXEC="$SIT_PARAM_MODE_EXEC"
    SIT_ID_USER="$SIT_PARAM_ID_USER"
    SIT_ROLE_USER="$SIT_PARAM_ROLE_USER"
    typeset -u SIT_ENVIRONNEMENT="$SIT_PARAM_ENVIRONNEMENT"

    # Mettre a jour l'InfoTrait a partir des parametres du traitement
    if [ $FLAG_NOM_TRAIT -eq 1 ]; then
        SIT_INFO_TRAIT="$(SetXMLVal "$SIT_INFO_TRAIT" "NomTraitement" "$SIT_NOM_TRAIT")"
        if [ "$(AvecErreur "$SIT_INFO_TRAIT")" ]; then
            AfficherMessage "$SIT_INFO_TRAIT"
            return $CR_KO
        fi
    fi

    if [ $FLAG_NOM_CHAINE -eq 1 ]; then
        SIT_INFO_TRAIT="$(SetXMLVal "$SIT_INFO_TRAIT" "NomChaine" "$SIT_NOM_CHAINE")"
        if [ "$(AvecErreur "$SIT_INFO_TRAIT")" ]; then
            AfficherMessage "$SIT_INFO_TRAIT"
            return $CR_KO
        fi
    fi

    if [ $FLAG_ID_EXEC -eq 1 ]; then
        SIT_INFO_TRAIT="$(SetXMLVal "$SIT_INFO_TRAIT" "IdExec" "$SIT_ID_EXEC")"
        if [ "$(AvecErreur "$SIT_INFO_TRAIT")" ]; then
            AfficherMessage "$SIT_INFO_TRAIT"
            return $CR_KO
        fi
    fi

    if [ $FLAG_MODE_EXEC -eq 1 ]; then
        SIT_INFO_TRAIT="$(SetXMLVal "$SIT_INFO_TRAIT" "ModeExec" "$SIT_MODE_EXEC")"
        if [ "$(AvecErreur "$SIT_INFO_TRAIT")" ]; then
            AfficherMessage "$SIT_INFO_TRAIT"
            return $CR_KO
        fi
    fi

    if [ $FLAG_ID_USER -eq 1 ]; then
        SIT_INFO_TRAIT="$(SetXMLVal "$SIT_INFO_TRAIT" "IdUser" "$SIT_ID_USER")"
        if [ "$(AvecErreur "$SIT_INFO_TRAIT")" ]; then
            AfficherMessage "$SIT_INFO_TRAIT"
            return $CR_KO
        fi
    fi

    if [ $FLAG_ROLE_USER -eq 1 ]; then
        SIT_INFO_TRAIT="$(SetXMLVal "$SIT_INFO_TRAIT" "RoleUser" "$SIT_ROLE_USER")"
        if [ "$(AvecErreur "$SIT_INFO_TRAIT")" ]; then
            AfficherMessage "$SIT_INFO_TRAIT"
            return $CR_KO
        fi
    fi

    if [ $FLAG_ENVIRONNEMENT -eq 1 ]; then
        SIT_INFO_TRAIT="$(SetXMLVal "$SIT_INFO_TRAIT" "Environnement" "$SIT_ENVIRONNEMENT")"
        if [ "$(AvecErreur "$SIT_INFO_TRAIT")" ]; then
            AfficherMessage "$SIT_INFO_TRAIT"
            return $CR_KO
        fi
    fi

    # Afficher les informations sur le traitement"$SIT_INFO_TRAIT"
    printf "$SIT_INFO_TRAIT"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction ExecTraitPLSQL -i <InfoTrait> -b <Nom base> -u <Nom user base>
#---------------------------------------------------------------------------
function ExecTraitPLSQL
{

    typeset -i ETP_NB_PARAMS=0

    # Lecture des parametres
    while getopts i:b:u: OPTION
    do
        case "$OPTION" in
           i) ETP_PARAM_INFO_TRAIT="$OPTARG"
              ETP_NB_PARAMS=ETP_NB_PARAMS+1
              ;;
           b) ETP_PARAM_NOM_BASE="$OPTARG"
              ETP_NB_PARAMS=ETP_NB_PARAMS+1
              ;;
           u) ETP_PARAM_NOM_USER="$OPTARG"
              ETP_NB_PARAMS=ETP_NB_PARAMS+1
              ;;
           ?) AfficherAnomalie "Fonction ExecTraitPLSQL : Option inconnue"
              AfficherAnomalie "Usage : ExecTraitPLSQL -i <InfoTrait> -b <Nom base> -u <Nom user base>"
              return $CR_KO
              ;;
        esac
    done

    # Controler les parametres
    if [ $ETP_NB_PARAMS -ne 3 ]; then
        AfficherAnomalie "Fonction ExecTraitPLSQL : parametre(s) manquant(s)"
        AfficherAnomalie "Usage : ExecTraitPLSQL -i <InfoTrait> -b <Nom base> -u <Nom user base>"
        return $CR_KO
    fi

    # Memoriser le nom de la base de donnees
    ETP_NOM_BASE="$(FormaterNomBase "$ETP_PARAM_NOM_BASE")"
    if [ "$(AvecErreur "$ETP_NOM_BASE")" ]; then
        AfficherMessage "$ETP_NOM_BASE"
        AfficherAnomalie "Usage : ExecTraitPLSQL -i <InfoTrait> -b <Nom base> -u <Nom user base>"
        return $CR_KO
    fi

    # Controler le nom de la base
    ControlerNomBase "$ETP_NOM_BASE"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Usage : ExecTraitPLSQL -i <InfoTrait> -b <Nom base> -u <Nom user base>"
        return $CR_KO
    fi

    # Memoriser le nom de l'utilisateur de la base de donnees
    ETP_NOM_USER="$ETP_PARAM_NOM_USER"

    # Controler le nom de la base
    ControlerNomUser "$ETP_NOM_USER"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Usage : ExecTraitPLSQL -i <InfoTrait> -b <Nom base> -u <Nom user base>"
        return $CR_KO
    fi

    # Memoriser les informations sur le traitement
    ETP_INFO_TRAIT="$ETP_PARAM_INFO_TRAIT"

    # Verifier la presence du nom du traitement
    # indispensable pour trouver le nom du package a executer dans Oracle
    ETP_NOM_TRAIT=$(GetXMLVal "$ETP_INFO_TRAIT" "NomTraitement")
    if [ -z "$ETP_NOM_TRAIT" ]; then
        AfficherAnomalie "Fonction ExecTraitPLSQL : NomTraitement non renseigne dans InfoTrait"
        return $CR_KO
    fi

    # Verifier la presence de l'identifiant de declenchement dans InfoTrait
    # obligatoire notamment pour toute operation liee a DTC
    ETP_ID_EXEC=$(GetXMLVal "$ETP_INFO_TRAIT" "IdExec")
    if [ -z "$ETP_ID_EXEC" ]; then
        AfficherInfo "Fonction ExecTraitPLSQL : IdExec non renseigne dans InfoTrait"
        return $CR_KO
    fi

    # Afficher la valeur des parametres
    AfficherInfo "Nom du traitement a executer    : [${ETP_NOM_TRAIT}]"
    AfficherInfo "Identifiant d'execution         : [${ETP_ID_EXEC}]"
    AfficherInfo "Nom de la base de donnees       : [${ETP_NOM_BASE}]"
    AfficherInfo "Nom de l'utilisateur de la base : [${ETP_NOM_USER}]"
    AfficherInfo "chaine InfoTrait  		  : [${ETP_INFO_TRAIT}]"
    AfficherInfo "---------------------------------------------------"

    # Fixer le nom du fichier de script anonyme PL/SQL
    # correspondant a l'execution d'un traitement
    # sous la forme d'une procedure stockee dans la base Oracle
    ETP_FIC_SQL="DTCEXETRTSQL01.sql"

    # Lancer le script SQL
    ExecScriptSQL "$ETP_NOM_BASE" "$ETP_NOM_USER" "$ETP_FIC_SQL" "'$ETP_INFO_TRAIT'"
    ETP_CR=$?

    # Afficher le code retour du traitement SQL
    AfficherInfo "Code retour du traitement SQL   : [${ETP_CR}]"

    # Retourner le resultat traitement SQL
    return $ETP_CR
}

#---------------------------------------------------------------------------
# Fonction GetRepFichierInfo
#---------------------------------------------------------------------------
function GetRepFichierInfo
{
    # Fixer le repertoire du fichier INFO de parametre de la chaine
    # au repertoire temporaire associe a l'application courante
    GRFI_REP_FIC_INFO="${TEMP_APPLI}"

    # Verifier l'existence du repertoire
    if [ ! -d $GRFI_REP_FIC_INFO ]; then
        AfficherAnomalie"Fonction GetRepFichierInfo : Repertoire du fichier de parametre [${GRFI_REP_FIC_INFO}] introuvable"
        return $CR_KO
    fi

    # Afficher le repertoire du fichier info
    printf "${GRFI_REP_FIC_INFO}"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetDebNomFichierInfo <Nom de la chaine>
#---------------------------------------------------------------------------
function GetDebNomFichierInfo
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetDebNomFichierInfo : parametre manquant"
        AfficherAnomalie "Usage : GetDebNomFichierInfo <Nom du traitement>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GDNFI_NOM_CHAINE="$1"

    # Afficher le debut du nom du fichier INFO = nom de la chaine en parametre
    printf "$GDNFI_NOM_CHAINE"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetFichierInfo <Nom de la chaine>
#---------------------------------------------------------------------------
function GetFichierInfo
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetFichierInfo : parametre manquant"
        AfficherAnomalie "Usage : GetFichierInfo <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GFI_NOM_CHAINE="$1"

    # Lire le repertoire du fichier INFO de parametre de la chaine
    GFI_REP_FIC_INFO="$(GetRepFichierInfo)"
    if [ "$(AvecErreur "$GFI_REP_FIC_INFO")" ]; then
        AfficherMessage "$GFI_REP_FIC_INFO"
        AfficherAnomalie "Fonction GetFichierInfo : Impossible de determiner le repertoire du fichier de parametre de la chaine"
        return $CR_KO
    fi

    # Construire le debut du nom du fichier INFO de parametre de la chaine
    GFI_DEBUT_NOM_FIC_INFO="$(GetDebNomFichierInfo "$GFI_NOM_CHAINE")"
    if [ $(AvecErreur "$GFI_DEBUT_NOM_FIC_INFO") ]; then
        AfficherMessage "$GFI_DEBUT_NOM_FIC_INFO"
        AfficherAnomalie "Fonction GetFichierInfo : Impossible de determiner le debut du nom du fichier de parametre de la chaine"
        return $CR_KO
    fi

    # Rechercher le fichier INFO de parametre de la chaine et afficher son nom complet
    # Format du nom complet du fichier :
    # <Repertoire fichier info>/<Nom de la chaine>.info (ancienne norme)
    # ou
    # <Repertoire fichier info>/<Nom de la chaine>_<date/heure>.info (nouvelle norme)
    # Dans ce dernier cas, il peut y avoir plusieurs fichiers info
    # dans le repertoire. Il faut donc choisir le plus recent
    if [ ! -r ${GFI_REP_FIC_INFO}/${GFI_DEBUT_NOM_FIC_INFO}*.info  ]; then
        AfficherAnomalie "Fonction GetFichierInfo : Fichier de parametre de la chaine [${GFI_REP_FIC_INFO}/${GFI_DEBUT_NOM_FIC_INFO}\*.info] introuvable !"
        AfficherAnomalie "Fonction GetFichierInfo : Liste des fichiers parametres de la chaine existants : $(ls -tr ${GFI_REP_FIC_INFO}/${GFI_DEBUT_NOM_FIC_INFO}*.info)"
        return $CR_KO
    fi
    GFI_FIC_INFO_NOM_COMPLET="$(ls -tr ${GFI_REP_FIC_INFO}/${GFI_DEBUT_NOM_FIC_INFO}*.info | head -1)"
    print "$GFI_FIC_INFO_NOM_COMPLET"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction SupprimerFicInfo <Nom de la chaine>
#---------------------------------------------------------------------------
function SupprimerFicInfo
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction SupprimerFicInfo : parametre manquant"
        AfficherAnomalie "Usage : SupprimerFicInfo <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    SFI_NOM_CHAINE="$1"

    # Determiner l'emplacement et le nom du fichier INFO de parametre de la chaine
    SFI_FIC_INFO="$(GetFichierInfo "$SFI_NOM_CHAINE")"
    if [ "$(AvecErreur "$SFI_FIC_INFO")" ]; then
        AfficherMessage "$SFI_FIC_INFO"
        AfficherAnomalie "Fonction SupprimerFicInfo : Fichier de parametre de la chaine introuvable"
        return $CR_KO
    fi

    # Supprimer le fichier
    rm -f "$SFI_FIC_INFO"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction LireFicInfo <Nom de la chaine> <Nom du parametre>
#---------------------------------------------------------------------------
function LireFicInfo
{

    # Controler les parametres
    if [ $# -ne 2 ]; then
        AfficherAnomalie "Fonction LireFicInfo : parametre manquant"
        AfficherAnomalie "Usage : LireFicInfo <Nom de la chaine> <Nom du parametre>"
        return $CR_KO
    fi

    # Memoriser les parametres
    LFI_NOM_CHAINE="$1"
    LFI_NOM_PARAM="$2"

    # Determiner l'emplacement et le nom du fichier INFO de parametre de la chaine
    LFI_FIC_INFO="$(GetFichierInfo "$LFI_NOM_CHAINE")"
    if [ "$(AvecErreur "$LFI_FIC_INFO")" ]; then
        AfficherMessage "$LFI_FIC_INFO"
        AfficherAnomalie "Fonction LireFicInfo : Impossible d'acceder au fichier de parametre de la chaine"
        return $CR_KO
    fi

    # Lire le parametre du fichier INFO
    LFI_VAL_PARAM=$(grep -e "[ ]*${LFI_NOM_PARAM}[ ]*;" "$LFI_FIC_INFO" | cut -d";" -f2)

    # Afficher l'identifiant de declenchement
    printf "$LFI_VAL_PARAM"

    # Retourner le succes du traitement
    return $CR_OK
}

#--------------------------------------------------------------------------------
# Fonction MajFicInfo <Nom de la chaine> <Nom du parametre> <Valeur du parametre>
#--------------------------------------------------------------------------------
function MajFicInfo
{

    # Controler les parametres
    if [ $# -ne 3 ]; then
        AfficherAnomalie "Fonction MajFicInfo : parametre manquant"
        AfficherAnomalie "Usage : MajFicInfo <Nom de la chaine> <Nom du parametre> <Valeur du parametre>"
        return $CR_KO
    fi

    # Memoriser les parametres
    MFI_NOM_CHAINE="$1"
    MFI_NOM_PARAM="$2"
    MFI_VAL_PARAM="$3"

    # Determiner l'emplacement et le nom du fichier INFO de parametre de la chaine
    MFI_FIC_INFO="$(GetFichierInfo "$MFI_NOM_CHAINE")"
    if [ "$(AvecErreur "$MFI_FIC_INFO")" ]; then
        AfficherMessage "$MFI_FIC_INFO"
        AfficherAnomalie "Fonction MajFicInfo : Impossible d'acceder au fichier de parametre de la chaine"
        return $CR_KO
    fi

    ChangerDroitFicOracle "$MFI_FIC_INFO"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction MajFicInfo : Impossible de changer les droits du fichier Info"
        return $CR_KO
    fi

    # Recherche du parametre dans le fichier INFO
    MFI_VAL_PARAM_OLD="$(LireFicInfo "$MFI_NOM_CHAINE" "$MFI_NOM_PARAM")"
    if [ "$(AvecErreur "$MFI_VAL_PARAM_OLD")" ]; then
        AfficherMessage "$MFI_VAL_PARAM_OLD"
        AfficherAnomalie "Fonction MajFicInfo : Impossible d'acceder au parametre [${MFI_NOM_PARAM}] du fichier de parametre de la chaine"
        return $CR_KO
    fi

    if [ ! -z "$MFI_VAL_PARAM_OLD" ]; then
        # s'il existe on le met à jour
        grep -v "${MFI_NOM_PARAM};" "$MFI_FIC_INFO" > "${MFI_FIC_INFO}.tmp"
        rm -f "$MFI_FIC_INFO"
        mv "${MFI_FIC_INFO}.tmp" "$MFI_FIC_INFO"
        echo "${MFI_NOM_PARAM};${MFI_VAL_PARAM}" >> "$MFI_FIC_INFO"
    else
        # sinon on l'ajoute à la fin du fichier
        echo "${MFI_NOM_PARAM};${MFI_VAL_PARAM}" >> "$MFI_FIC_INFO"
    fi

    ChangerDroitFicOracle "$MFI_FIC_INFO"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction MajFicInfo : Impossible de changer les droits du fichier Info"
        return $CR_KO
    fi

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction CreerFicInfo <Nom de la chaine>
#---------------------------------------------------------------------------
function CreerFicInfo
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction CreerFicInfo : parametre manquant"
        AfficherAnomalie "Usage : CreerFicInfo <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    CFI_NOM_CHAINE="$1"

    # Determiner l'emplacement et le nom du fichier INFO de parametre de la chaine
    CFI_REP_FIC_INFO="$(GetRepFichierInfo "$CFI_NOM_CHAINE")"
    if [ "$(AvecErreur "$CFI_REP_FIC_INFO")" ]; then
        AfficherMessage "$CFI_REP_FIC_INFO"
        AfficherAnomalie "Fonction CreerFicInfo : Repertoire d'ecriture du fichier de parametre de la chaine indetermine"
        return $CR_KO
    fi

    # Verifier l'existence du répertoire
    # et les droits d'ecriture dans le repertoire
    if [ ! -w "$CFI_REP_FIC_INFO" ]; then
        AfficherAnomalie "Fonction CreerFicInfo : Repertoire d'ecriture du fichier inexistant ou interdit a l'ecriture"
        return $CR_KO
    fi

    # Construire le nom du fichier info
    CFI_NOM_FIC_INFO="${CFI_REP_FIC_INFO}/${CFI_NOM_CHAINE}.info"

    # Supprimer le fichier info s'il existe deja
    rm -f "$CFI_NOM_FIC_INFO"

    # Creer le fichier INFO
    # - en le nommant comme suit : <nom chaine>.info
    # - en attribuant les droits d'ecriture au compte unix Oracle
    #   qui mettra a jour le fichier ulterieurement
    > "$CFI_NOM_FIC_INFO"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction CreerFicInfo : impossible de creer le fichier INFO [${CFI_NOM_FIC_INFO}]"
        return $CR_KO
    fi
    chmod 664 "$CFI_NOM_FIC_INFO"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction CreerFicInfo : impossible de modifier les droits du fichier INFO [${CFI_NOM_FIC_INFO}]"
        return $CR_KO
    fi

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetRepFichierParam
#---------------------------------------------------------------------------
function GetRepFichierParam
{
    # Fixer le repertoire du fichier Param de parametre de la chaine
    # au repertoire temporaire associe a l'application courante
    GRFP_REP_FIC_PARAM="${TEMP_APPLI}"

    # Verifier l'existence du repertoire
    if [ ! -d $GRFP_REP_FIC_PARAM ]; then
        AfficherAnomalie"Fonction GetRepFichierParam : Repertoire du fichier de parametre [${GRFI_REP_FIC_PARAM}] introuvable"
        return $CR_KO
    fi

    # Afficher le repertoire du fichier Param
    printf "${GRFP_REP_FIC_PARAM}"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetDebNomFichierParam <Nom de la chaine>
#---------------------------------------------------------------------------
function GetDebNomFichierParam
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetDebNomFichierParam : parametre manquant"
        AfficherAnomalie "Usage : GetDebNomFichierParam <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GDNFP_NOM_CHAINE="$1"

    # Afficher le debut du nom du fichier Param = nom de la chaine en parametre
    printf "$GDNFP_NOM_CHAINE"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetFichierParam <Nom de la chaine>
#---------------------------------------------------------------------------
function GetFichierParam
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetFichierParam : parametre manquant"
        AfficherAnomalie "Usage : GetFichierParam <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GFP_NOM_CHAINE="$1"

    # Lire le repertoire du fichier Param de parametre de la chaine
    GFP_REP_FIC_PARAM="$(GetRepFichierParam)"
    if [ "$(AvecErreur "$GFP_REP_FIC_PARAM")" ]; then
        AfficherMessage "$GFP_REP_FIC_PARAM"
        AfficherAnomalie "Fonction GetFichierParam : Impossible de determiner le repertoire du fichier de parametre de la chaine"
        return $CR_KO
    fi

    # Construire le debut du nom du fichier Param de parametre de la chaine
    GFP_DEBUT_NOM_FIC_PARAM="$(GetDebNomFichierParam "$GFP_NOM_CHAINE")"
    if [ $(AvecErreur "$GFP_DEBUT_NOM_FIC_PARAM") ]; then
        AfficherMessage "$GFP_DEBUT_NOM_FIC_PARAM"
        AfficherAnomalie "Fonction GetFichierParam : Impossible de determiner le debut du nom du fichier de parametre de la chaine"
        return $CR_KO
    fi

    # Rechercher le fichier Param de parametre de la chaine et afficher son nom complet
    # Format du nom complet du fichier :
    # <Repertoire fichier Param>/<Nom de la chaine>.Param (ancienne norme)
    # ou
    # <Repertoire fichier Param>/<Nom de la chaine>_<date/heure>.Param (nouvelle norme)
    # Dans ce dernier cas, il peut y avoir plusieurs fichiers Param
    # dans le repertoire. Il faut donc choisir le plus recent
    if [ -r ${GFP_REP_FIC_PARAM}/${GFP_DEBUT_NOM_FIC_PARAM}*.dtc  ]; then
        GFP_FIC_PARAM_NOM_COMPLET="$(ls -tr ${GFP_REP_FIC_PARAM}/${GFP_DEBUT_NOM_FIC_PARAM}*.dtc | head -1)"
    fi
    print "$GFP_FIC_PARAM_NOM_COMPLET"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction SupprimerFicParam <Nom de la chaine>
#---------------------------------------------------------------------------
function SupprimerFicParam
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction SupprimerFicParam : parametre manquant"
        AfficherAnomalie "Usage : SupprimerFicParam <Nom de la chaine>"
        return $CR_KO
    fi

    # Memoriser le parametre
    SFP_NOM_CHAINE="$1"

    # Determiner l'emplacement et le nom du fichier Param de parametre de la chaine
    SFP_FIC_PARAM="$(GetFichierParam "$SFP_NOM_CHAINE")"
    if [ "$(AvecErreur "$SFP_FIC_PARAM")" ]; then
        AfficherMessage "$SFP_FIC_PARAM"
        AfficherAnomalie "Fonction SupprimerFicParam : Fichier de parametre de la chaine introuvable"
        return $CR_KO
    fi

    # Supprimer le fichier
    rm -f "$SFP_FIC_PARAM"

    # Retourner le succes du traitement
    return $CR_OK
}

#--------------------------------------------------------------------------------
# Fonction SetDebutTrt <Nom de la chaine> <Nom du traitement> <Nom base> <Nom user base>
#--------------------------------------------------------------------------------
function SetDebutTrt
{

    # Syntaxe d'appel de la fonction
    SDT_USAGE="Usage : SetDebutTrt <Nom de la chaine> <Nom du traitement> <Nom base> <Nom user base>"

    # Controler les parametres
    if [ $# -ne 4 ]; then
        AfficherAnomalie "Fonction SetDebutTrt : parametre manquant"
        AfficherAnomalie "$SDT_USAGE"
        return $CR_KO
    fi

    # Memoriser les parametres
    SDT_NOM_CHAINE="$1"
    SDT_NOM_TRAIT="$2"
    SDT_NOM_BASE="$3"
    SDT_NOM_USER="$4"
    #SDT_PARAM_CON="$5"

    # Formater le nom de la chaine
    SDT_NOM_CHAINE="$(FormaterNomTraitement "$SDT_NOM_CHAINE")"
    if [ "$(AvecErreur "$SDT_NOM_CHAINE")" ]; then
        AfficherMessage "$SDT_NOM_CHAINE"
        AfficherAnomalie "$SDT_USAGE"
        return $CR_KO
    fi

    # Controler le nom de la chaine
    ControlerNomTraitement "$SDT_NOM_CHAINE"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$SDT_USAGE"
        return $CR_KO
    fi

    # Formater le nom du traitement
    SDT_NOM_TRAIT="$(FormaterNomTraitement "$SDT_NOM_TRAIT")"
    if [ "$(AvecErreur "$SDT_NOM_TRAIT")" ]; then
        AfficherMessage "$SDT_NOM_TRAIT"
        AfficherAnomalie "$SDT_USAGE"
        return $CR_KO
    fi

    # Controler le nom du traitement
    ControlerNomTraitement "$SDT_NOM_TRAIT"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$SDT_USAGE"
        return $CR_KO
    fi

    # Determiner l'emplacement et le nom du fichier INFO de parametre de la chaine
    #SDT_FIC_INFO="$(GetFichierInfo $SDT_NOM_CHAINE)"
    #if [ "$(AvecErreur "$SDT_FIC_INFO")" ]; then
    #    AfficherMessage "$SDT_FIC_INFO"
    #    AfficherAnomalie "Fonction SetDebutTrt : Impossible d'acceder au fichier de parametre de la chaine"
    #    return $CR_KO
    #fi

    # Recuperer l'InfoTrait existant

    LireTInfo "$SDT_NOM_CHAINE" "InfoTrait" "$SDT_NOM_BASE" "$SDT_NOM_USER" "SDT_INFOTRAIT_OLD"

    if [ "$(AvecErreur "$SDT_INFOTRAIT_OLD")" ]; then
        AfficherMessage "$SDT_INFOTRAIT_OLD"
        AfficherAnomalie "Fonction SetDebutTrt : Impossible de recuperer l'InfoTrait existant du fichier de parametre de la chaine"
        return $CR_KO
    fi

    # Mettre à jour l'InfoTrait
    SDT_INFOTRAIT="$(SetInfoTrait -i "$SDT_INFOTRAIT_OLD" -t "$SDT_NOM_TRAIT")"
    if [ "$(AvecErreur "$SDT_INFOTRAIT")" ]; then
        AfficherMessage "$SDT_INFOTRAIT"
        AfficherAnomalie "Fonction SetDebutTrt : Impossible de mettre a jour l'InfoTrait"
        return $CR_KO
    fi

    # Mettre à jour le fichier INFO
  #  MajFicInfo "$SDT_NOM_CHAINE" "InfoTrait" "$SDT_INFOTRAIT"
  #  if [ $? -ne $CR_OK ]; then
  #      AfficherMessage "$SDT_INFOTRAIT"
  #      AfficherAnomalie "Fonction SetDebutTrt : Impossible de mettre a jour l'InfoTrait dans le fichier [${SDT_NOM_CHAINE}.info]"
  #      return $CR_KO
  #  fi

    # Mettre à jour la table T_INFO
    MajTInfo "$SDT_NOM_CHAINE" "InfoTrait" "$SDT_INFOTRAIT" "$SDT_NOM_BASE" "$SDT_NOM_USER" >> /dev/null
    if [ $? -ne $CR_OK ]; then
        AfficherMessage "$SDT_INFOTRAIT"
        AfficherAnomalie "Fonction SetDebutTrt : Impossible de mettre a jour l'InfoTrait dans la table T_INFO"
        return $CR_KO
    fi

    # Afficher le nouvel InfoTrait
    printf "$SDT_INFOTRAIT"

    # Retourner le succes du traitement
    return $CR_OK

}

#---------------------------------------------------------------------------
# Fonction SetDebChaine -c <Nom chaine> -b <Nom base> -u <Nom user base>
#---------------------------------------------------------------------------
function SetDebChaine
{

    # Usage de la fonction
    SDC_USAGE="Usage : SetDebChaine -c <Nom chaine> -b <Nom base> -u <Nom user base> "

    # Lecture des parametres
    typeset -i NB_PARAM=0
    while getopts c:b:u: OPTION
    do
        case "$OPTION" in
           c) SDC_PARAM_NOM_CHAINE="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           b) SDC_PARAM_NOM_BASE="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           u) SDC_PARAM_NOM_USER="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           ?) AfficherAnomalie "Fonction SetDebChaine : Option inconnue"
              AfficherAnomalie "$SDC_USAGE"
              return $CR_KO
              ;;
        esac
    done

    # Controler les parametres
    if [ $NB_PARAM -ne 3 ]; then
        AfficherAnomalie "Fonction SetDebChaine : parametre(s) manquant(s)"
        AfficherAnomalie "$SDC_USAGE"
        return $CR_KO
    fi

    # Memoriser le nom de la base de donnees
    SDC_NOM_BASE="$(FormaterNomBase "$SDC_PARAM_NOM_BASE")"
    if [ "$(AvecErreur "$SDC_NOM_BASE")" ]; then
        AfficherMessage "$SDC_NOM_BASE"
        AfficherAnomalie "$SDC_USAGE"
        return $CR_KO
    fi

    # Controler le nom de la base
    ControlerNomBase "$SDC_NOM_BASE"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$SDC_USAGE"
        return $CR_KO
    fi

    # Memoriser le nom de l'utilisateur de la base de donnees
    SDC_NOM_USER="$SDC_PARAM_NOM_USER"

    # Controler le nom de l'utilisateur
   # ControlerNomUser "$SDC_NOM_USER"
   # if [ $? -ne $CR_OK ]; then
   #     AfficherAnomalie "$SDC_USAGE"
   #     return $CR_KO
   # fi

    # Memoriser le nom de la chaine
    SDC_NOM_CHAINE="$(FormaterNomTraitement "$SDC_PARAM_NOM_CHAINE")"
    if [ "$(AvecErreur "$SDC_NOM_CHAINE")" ]; then
        AfficherMessage "$SDC_NOM_CHAINE"
        AfficherAnomalie "$SDC_USAGE"
        return $CR_KO
    fi

    # Controler le nom de la chaine
    # Remarque : une chaine porte le nom du 1er traitement qui la compose
    ControlerNomTraitement "$SDC_NOM_CHAINE"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$SDC_USAGE"
        return $CR_KO
    fi

    # Le nom du premier traitement est le meme que le nom de la chaine par convention
    SDC_NOM_TRAIT="$SDC_NOM_CHAINE"

    # Afficher la valeur des parametres
    AfficherInfo "Nom de la chaine de traitement  : [${SDC_NOM_CHAINE}]"
    AfficherInfo "Nom de la base de donnees       : [${SDC_NOM_BASE}]"
    AfficherInfo "Nom de l'utilisateur de la base : [${SDC_NOM_USER}]"

    # Initialiser InfoTrait a partir des parametres
    SDC_INFO_TRAIT="$(SetInfoTrait -t "$SDC_NOM_TRAIT")"
    if [ "$(AvecErreur "$SDC_INFO_TRAIT")" ]; then
        AfficherMessage "$SDC_INFO_TRAIT"
        AfficherAnomalie "Fonction SetDebChaine : Erreur lors de la construction d'InfoTrait : ajout du nom de traitement [${SDC_NOM_TRAIT}]"
        return $CR_KO
    fi

    SDC_INFO_TRAIT="$(SetInfoTrait -i "$SDC_INFO_TRAIT" -c "$SDC_NOM_CHAINE")"
    if [ "$(AvecErreur "$SDC_INFO_TRAIT")" ]; then
        AfficherMessage "$SDC_INFO_TRAIT"
        AfficherAnomalie "Fonction SetDebChaine : Erreur lors de la construction d'InfoTrait : ajout du nom de la chaine [${SDC_NOM_CHAINE}]"
        return $CR_KO
    fi

    SDC_INFO_TRAIT="$(SetInfoTrait -i "$SDC_INFO_TRAIT" -r "DTC")"
    if [ "$(AvecErreur "$SDC_INFO_TRAIT")" ]; then
        AfficherMessage "$SDC_INFO_TRAIT"
        AfficherAnomalie "Fonction SetDebChaine : Erreur lors de la construction d'InfoTrait : ajout du nom du user [${SDC_NOM_CHAINE}]"
        return $CR_KO
    fi

    # Lire l'identifiant d'execution (ou de declenchement)
    # sur la 1er ligne du fichier flag genere par DTC
    # et qui porte le meme nom que celui de la chaine
    #RLE
    #SDC_ID_EXEC="$(GetIdDeclenchement "$SDC_NOM_CHAINE")"
    #GetIdDeclenchementTable "$SDC_NOM_CHAINE" "$SDC_NOM_BASE" "$SDC_NOM_USER" "SDC_ID_EXEC"
    GetIdDeclenchementEncoursTable "$SDC_NOM_CHAINE" "$SDC_NOM_BASE" "$SDC_NOM_USER" "SDC_ID_EXEC"

  #  if [ "$?" ]; then
  #      AfficherMessage "$SDC_ID_EXEC"
  #      AfficherAnomalie "Fonction SetDebChaine : Erreur lors de la lecture de l'id. d'execution de la chaine [${SDC_NOM_CHAINE}] dans la table flag"
  #      return $CR_KO
  #  fi

    #SDC_ID_EXEC="$GIDT_NUM_DECLENCH"
    #/RLE


    # Si l'identifiant de declenchement n'est pas renseigne

    if [ -z "$SDC_ID_EXEC" ]; then
        AfficherAnomalie "Fonction SetDebChaine : Identifiant de declenchement de la chaine [${SDC_NOM_CHAINE}] non renseigne"
        return $CR_KO
    fi

#RLE
        # Recuperer le nom complet du fichier flag
#    SDC_FIC_FLAG="$(GetFichierFlag "$SDC_NOM_CHAINE")"

#    if [ "$(AvecErreur "$SDC_FIC_FLAG")" ]; then
#        AfficherAnomalie "Fonction SetDebChaine : Erreur lors de la recuperation du nom du fichier FLAG de la chaine [${SDC_NOM_CHAINE}]"
#        AfficherMessage "$SDC_FIC_FLAG"
#        return $CR_WARNING
#    fi

#    ChangerDroitFicOracle "$SDC_FIC_FLAG"

     # Renommer le fichier flag en fichier .encours
#    SDC_FIC_FLAG_BASE="$(basename $SDC_FIC_FLAG .flag)"

#    SDC_DIR_FLAG="$(dirname $SDC_FIC_FLAG)"

#   SDC_FIC_ENCOURS="${SDC_DIR_FLAG}/${SDC_FIC_FLAG_BASE}.encours"

#    mv "$SDC_FIC_FLAG" "${SDC_FIC_ENCOURS}"

#    if [ $? -ne $CR_OK ]; then
#       AfficherAnomalie "Fonction SetDebChaine : Erreur lors du renommage du fichier FLAG de la chaine [${SDC_NOM_CHAINE}]"
#    else
#       AfficherMessage "Succes Renommage du fihier flag ${SDC_FIC_FLAG} en ${SDC_FIC_ENCOURS}"
#    fi
# /RLE

    # Afficher l'identifiant de declenchement
    AfficherInfo "Id. d'execution du traitement   : [${SDC_ID_EXEC}]"

    # Mettre a jour InfoTrait avec l'identifiant d'execution
    SDC_INFO_TRAIT="$(SetInfoTrait -i "$SDC_INFO_TRAIT" -x "$SDC_ID_EXEC")"
    if [ "$(AvecErreur "$SDC_INFO_TRAIT")" ]; then
        AfficherMessage "$SDC_INFO_TRAIT"
        AfficherAnomalie "Fonction SetDebChaine : Erreur lors de la construction d'InfoTrait : ajout de l'identifiant d'execution [${SDC_ID_EXEC}]"
        return $CR_KO
    fi

    # Rechercher l'environnement technique (D,R,P)
    SDC_ENVIRONNEMENT="$(GetEnvironnement)"
    if [ "$(AvecErreur "$SDC_ENVIRONNEMENT")" ]; then
        AfficherMessage "$SDC_ENVIRONNEMENT"
        AfficherAnomalie "Fonction SetDebChaine : Erreur lors de la lecture de l'environnement technique d'execution de la chaine [${SDC_NOM_CHAINE}]"
        return $CR_KO
    fi

    # Mettre a jour InfoTrait avec l'environnement technique
    SDC_INFO_TRAIT="$(SetInfoTrait -i "$SDC_INFO_TRAIT" -e "$SDC_ENVIRONNEMENT")"
    if [ "$(AvecErreur "$SDC_INFO_TRAIT")" ]; then
        AfficherMessage "$SDC_INFO_TRAIT"
        AfficherAnomalie "Fonction SetDebChaine : Erreur lors de la construction d'InfoTrait : ajout de l'environnement [${SDC_ENVIRONNEMENT}]"
        return $CR_KO
    fi

    # Fixer le nom du fichier de script anonyme PL/SQL a lancer
    # pour initialiser le traitement
    SDC_FIC_SQL="DTCEXETRTDEB01.sql"

    # MODIF TEMPORAIRE
    # Delai pour attendre l'ecriture des donnees dans les tables de DTC
    sleep 10

echo "ExecScriptSQL "$SDC_NOM_BASE" "$SDC_NOM_USER" "$SDC_FIC_SQL" "$SDC_INFO_TRAIT" "

    # Lancer le script SQL
    ExecScriptSQL "$SDC_NOM_BASE" "$SDC_NOM_USER" "$SDC_FIC_SQL" "'$SDC_INFO_TRAIT'"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction SetDebChaine : Erreur lors de l'execution du script SQL [${SDC_FIC_SQL}]"
        return $CR_KO
    fi

 #RLE
    # SDC_FIC_INFO="$(LireTInfo "$SDC_NOM_CHAINE")"
   # if [ "$(AvecErreur "$SDC_FIC_INFO")" ]; then
   #     AfficherMessage "$SDC_FIC_INFO"
   #     return $CR_KO
   #  fi
 #/RLE

#RLE
    #ChangerDroitFicOracle "$SDC_FIC_INFO"
#/RLE

    # Afficher InfoTrait

    printf "$SDC_INFO_TRAIT"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction SetFinChaine -i <InfoTrait>
#                       -r <Resultat traitement>
#                       -b <Nom base>
#                       -u <Nom user base>
#---------------------------------------------------------------------------
function SetFinChaine
{

    # Usage de la fonction
    SFC_USAGE="Usage : SetFinChaine -i <InfoTrait> -r <Resultat Chaine> -b <Nom base> -u <Nom user base> "

    # Lecture des parametres
    typeset -i NB_PARAM=0
    while getopts i:r:b:u: OPTION
    do
        case "$OPTION" in
           i) SFC_PARAM_INFO_TRAIT="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           r) SFC_PARAM_RES_CHAINE="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           b) SFC_PARAM_NOM_BASE="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           u) SFC_PARAM_NOM_USER="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           ?) AfficherAnomalie "Fonction SetFinChaine: Option inconnue"
              AfficherAnomalie "$SFC_USAGE"
              return $CR_KO
              ;;
        esac
    done

    # Controler les parametres
    if [ $NB_PARAM -ne 4 ]; then
        AfficherAnomalie "Fonction SetFinChaine : parametre(s) manquant(s)"
        AfficherAnomalie "$SFC_USAGE"
        return $CR_KO
    fi

    # Memoriser le nom de la base de donnees
    SFC_NOM_BASE="$(FormaterNomBase "$SFC_PARAM_NOM_BASE")"
    if [ "$(AvecErreur "$SFC_NOM_BASE")" ]; then
        AfficherMessage "$SFC_NOM_BASE"
        AfficherAnomalie "$SFC_USAGE"
        return $CR_KO
    fi

    # Controler le nom de la base
    ControlerNomBase "$SFC_NOM_BASE"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$SFC_USAGE"
        return $CR_KO
    fi

    # Memoriser le nom de l'utilisateur de la base de donnees
    SFC_NOM_USER="$SFC_PARAM_NOM_USER"

    # Controler le nom de la base
    ControlerNomUser "$SFC_NOM_USER"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$SFC_USAGE"
        return $CR_KO
    fi

    # Memoriser l'InfoTrait
    SFC_INFO_TRAIT="$SFC_PARAM_INFO_TRAIT"

    # Memoriser le resultat du traitement
    # en le formatant le resultat en majuscules
    typeset -u SFC_RES_CHAINE="$(echo "$SFC_PARAM_RES_CHAINE" | tr -d ' ')"

    # Fixer le nom du fichier de script anonyme PL/SQL a lancer
    # pour terminer le traitement
    SFC_FIC_SQL="DTCEXETRTFIN01.sql"

    # Lancer le script SQL
    ExecScriptSQL "$SFC_NOM_BASE" "$SFC_NOM_USER" "$SFC_FIC_SQL" "'$SFC_INFO_TRAIT'" "'$SFC_RES_CHAINE'"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction SetFinChaine : Erreur lors de l'execution du script SQL [${SFC_FIC_SQL}]"
        return $CR_KO
    fi

    # Si resultat OK
    if [ "$SFC_RES_CHAINE" = "OK" ]; then

        # Recuperer le nom de la chaine
        SFC_NOM_CHAINE="$(GetXMLVal "$SFC_INFO_TRAIT" "NomChaine")"

        # Controler le nom de la chaine
        ControlerNomTraitement "$SFC_NOM_CHAINE"
        if [ $? -ne $CR_OK ]; then
            AfficherAnomalie "Fonction SetFinChaine : Erreur lors de la recuperation du nom de la chaine [${SFC_NOM_CHAINE}]"
            return $CR_KO
        fi

        # Supprimer fichier flag
#        SupprimerFicFlag "$SFC_NOM_CHAINE"
#        if [ $? -ne $CR_OK ]; then
#            AfficherAnomalie "Fonction SetFinChaine : Erreur lors de la suppression du fichier FLAG de la chaine [${SFC_NOM_CHAINE}]"
#            return $CR_WARNING
#        fi

        # Supprimer fichier Info
        # FRA : 30/11/07 On garde le fichier info
#        SupprimerFicInfo "$SFC_NOM_CHAINE"
#        if [ $? -ne $CR_OK ]; then
#            AfficherAnomalie "Fonction SetFinChaine : Erreur lors de la suppression du fichier INFO de la chaine [${SFC_NOM_CHAINE}]"
#            return $CR_KO
#        else
#            AfficherMessage "$SFC_NOM_CHAINE : Suppression fichier INFO OK"
#        fi

    else

    # Si resultat KO

        # Recuperer le nom de la chaine
        SFC_NOM_CHAINE="$(GetXMLVal "$SFC_INFO_TRAIT" "NomChaine")"

        # Controler le nom de la chaine
        ControlerNomTraitement "$SFC_NOM_CHAINE"
        if [ $? -ne $CR_OK ]; then
            AfficherAnomalie "Fonction SetFinChaine : Erreur lors de la recuperation du nom de la chaine [${SFC_NOM_CHAINE}]"
            return $CR_KO
        fi

        # Recuperer le nom complet du fichier flag
#        SFC_FIC_FLAG="$(GetFichierFlagEnCours "$SFC_NOM_CHAINE")"
#        if [ "$(AvecErreur "$SFC_FIC_FLAG")" ]; then
#            AfficherAnomalie "Fonction SetFinChaine : Erreur lors de la recuperation du nom du fichier FLAG de la chaine [${SFC_NOM_CHAINE}]"
#            AfficherMessage "$SFC_FIC_FLAG"
#            return $CR_KO
#        fi

        # Renommer le fichier flag
#        mv "$SFC_FIC_FLAG" "${SFC_FIC_FLAG}.save"
#        if [ $? -ne $CR_OK ]; then
#            AfficherAnomalie "Fonction SetFinChaine : Erreur lors du renommage du fichier FLAG de la chaine [${SFC_NOM_CHAINE}]"
#            return $CR_WARNING
#        fi
    fi

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------------------------
# Fonction EcrireLog <InfoTrait>
#                    <Type de message>
#                    <Message>
#                    <Code d'erreur>
#                    <Nom fonction>
#                    <Nom base>
#                    <Nom user base>
#---------------------------------------------------------------------------------------------
function EcrireLog
{
    # Usage de la fonction
    EL_USAGE="Usage : EcrireLog <InfoTrait> <Type de message> <Message> <Code d'erreur> <Nom fonction> <Nom base> <Nom user base>"

    # Controler les parametres
    if [ $# -ne 7 ]; then
        AfficherAnomalie "Fonction EcrireLog : parametre(s) manquant(s)"
        AfficherAnomalie "$EL_USAGE"
        return $CR_KO
    fi

    # Memoriser l'InfoTrait
    EL_INFO_TRAIT="$1"

    # Memoriser le type de message
    EL_TYPE_MSG="$2"

    # Memoriser le message
    EL_MSG="$(echo $3 | sed "s/'/''/g")"
    #EL_MSG="$(echo $3 | sed "s/'/''''/g")"

    # Memoriser le code d'erreur
    EL_CODE_ERR="$4"

    # Memoriser le nom de la fonction
    EL_NOM_FONCTION="$5"

    # Memoriser le nom de la base de donnees
    EL_NOM_BASE="$(FormaterNomBase "$6")"
    if [ "$(AvecErreur "$EL_NOM_BASE")" ]; then
        AfficherMessage "$EL_NOM_BASE"
        AfficherAnomalie "$EL_USAGE"
        return $CR_KO
    fi

    # Controler le nom de la base
    ControlerNomBase "$EL_NOM_BASE"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$EL_USAGE"
        return $CR_KO
    fi

    # Memoriser le nom de l'utilisateur de la base de donnees
    EL_NOM_USER="$7"

    # Controler le nom de l'utilisateur
    ControlerNomUser "$EL_NOM_USER"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$EL_USAGE"
        return $CR_KO
    fi

    # Fixer le nom du fichier de script anonyme PL/SQL a lancer
    # pour ecrire un message de log
    EL_FIC_SQL="DTCEXETRTLOG01.sql"

    # Lancer le script SQL
    ExecScriptSQL "$EL_NOM_BASE" "$EL_NOM_USER" "$EL_FIC_SQL" "'$EL_INFO_TRAIT'" "'$EL_TYPE_MSG'" "'$EL_MSG'" "'$EL_CODE_ERR'" "'$EL_NOM_FONCTION'"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction EcrireLog : Erreur lors de l'execution du script SQL [${EL_FIC_SQL}]"
        return $CR_KO
    fi

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------------------------
# Fonction EcrireLogPlus <InfoTrait>
#                    <Type de message>
#                    <Message>
#                    <Code d'erreur>
#                    <Nom fonction>
#                    <Nom base>
#                    <Nom user base>
#---------------------------------------------------------------------------------------------
function EcrireLogPlus
{
    # Usage de la fonction
    ELP_USAGE="Usage : EcrireLogPlus <InfoTrait> <Type de message> <Message> <Code d'erreur> <Nom fonction> <Nom base> <Nom user base>"

    # Controler les parametres
    if [ $# -ne 7 ]; then
        AfficherAnomalie "Fonction EcrireLog : parametre(s) manquant(s)"
        AfficherAnomalie "$ELP_USAGE"
        return $CR_KO
    fi

    # Memoriser l'InfoTrait
    ELP_INFO_TRAIT="$1"

    # Memoriser le type de message
    ELP_TYPE_MSG="$2"

    # Memoriser le message
    ELP_MSG="$(echo $3 | sed "s/'/''/g")"

    # Memoriser le code d'erreur
    ELP_CODE_ERR="$4"

    # Memoriser le nom de la fonction
    ELP_NOM_FONCTION="$5"

    # Memoriser le nom de la base de donnees
    ELP_NOM_BASE="$(FormaterNomBase "$6")"
    if [ "$(AvecErreur "$ELP_NOM_BASE")" ]; then
        AfficherMessage "$ELP_NOM_BASE"
        AfficherAnomalie "$ELP_USAGE"
        return $CR_KO
    fi

    # Controler le nom de la base
    ControlerNomBase "$ELP_NOM_BASE"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$ELP_USAGE"
        return $CR_KO
    fi

    # Memoriser le nom de l'utilisateur de la base de donnees
    ELP_NOM_USER="$7"

    # Controler le nom de l'utilisateur
    ControlerNomUser "$ELP_NOM_USER"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$ELP_USAGE"
        return $CR_KO
    fi

    # Fixer le nom du fichier de script anonyme PL/SQL a lancer
    # pour ecrire un message de log
    ELP_FIC_SQL="DTCEXETRTLOG01.sql"

    # Lancer le script SQL
    ExecScriptSQLPlus "$ELP_NOM_BASE" "$ELP_NOM_USER" "$ELP_FIC_SQL" "'$ELP_INFO_TRAIT'" "'$ELP_TYPE_MSG'" "'$ELP_MSG'" "'$ELP_CODE_ERR'" "'$ELP_NOM_FONCTION'"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction EcrireLog : Erreur lors de l'execution du script SQL [${ELP_FIC_SQL}]"
        return $CR_KO
    fi

    # Retourner le succes du traitement
    return $CR_OK
}

##---------------------------------------------------------------------------------------------
## Fonction DeclencherChaine <Nom de la chaine>
##                           <Nom de l'utilisateur>
##                           <Nom base>
##                           <Nom user base>
##---------------------------------------------------------------------------------------------
#function DeclencherChaine
#{
#    # Usage de la fonction
#    DEC_USAGE="Usage : DeclencherChaine <Nom de la chaine> <Nom de l'utilisateur> <Nom base> <Nom user base>"
#
#    # Controler les parametres
#    if [ $# -ne 4 ]; then
#        AfficherAnomalie "Fonction DeclencherChaine : parametre(s) manquant(s)"
#        AfficherAnomalie "$DEC_USAGE"
#        return $CR_KO
#    fi
#
#    # Memoriser le nom de la chaine
#    DEC_NOM_CHAINE="$1"
#
#    # Controler le nom de la chaine
#    ControlerNomTraitement "$DEC_NOM_CHAINE"
#    if [ $? -ne $CR_OK ]; then
#        AfficherAnomalie "$DEC_USAGE"
#        return $CR_KO
#    fi
#
#    # Memoriser le nom de l'utilisateur
#    DEC_NOM_UTILISATEUR="$2"
#
#    # Memoriser le nom de la base de donnees
#    DEC_NOM_BASE="$(FormaterNomBase "$3")"
#    if [ "$(AvecErreur "$DEC_NOM_BASE")" ]; then
#        AfficherMessage "$DEC_NOM_BASE"
#        AfficherAnomalie "$DEC_USAGE"
#        return $CR_KO
#    fi
#
#    # Controler le nom de la base
#    ControlerNomBase "$DEC_NOM_BASE"
#    if [ $? -ne $CR_OK ]; then
#        AfficherAnomalie "$DEC_USAGE"
#        return $CR_KO
#    fi
#
#    # Memoriser le nom de l'utilisateur de la base de donnees
#    DEC_NOM_USER="$4"
#
#    # Controler le nom de l'utilisateur
#    ControlerNomUser "$DEC_NOM_USER"
#    if [ $? -ne $CR_OK ]; then
#        AfficherAnomalie "$DEC_USAGE"
#        return $CR_KO
#    fi
#
#    # Generer l'InfoTrait avec le nom de la chaine
#    DEC_INFO_TRAIT=$(SetInfoTrait -c "$DEC_NOM_CHAINE")
#
#    # Fixer le nom du fichier de script anonyme PL/SQL a lancer
#    # pour ecrire un message de log
#    DEC_FIC_SQL="DTCEXETRTDEC01.sql"
#
#    # On recherche si un fichier de parametre *.dtc existe pour la chaine
#    DEC_NOM_FIC_PARAM_COMPLET="$(GetFichierParam "$DEC_NOM_CHAINE")"
#    if [ "$(AvecErreur "$DEC_NOM_FIC_PARAM_COMPLET")" ]; then
#        AfficherMessage "$DEC_NOM_FIC_PARAM_COMPLET"
#        return $CR_KO
#    fi
#    DEC_NOM_FIC_PARAM="$(basename $DEC_NOM_FIC_PARAM_COMPLET)"
#
#    DEC_DIR_NOM_FIC_PARAM="$(GetRepFichierParam)"
#    if [ "$(AvecErreur "$DEC_DIR_NOM_FIC_PARAM")" ]; then
#        AfficherMessage "$DEC_DIR_NOM_FIC_PARAM"
#        return $CR_KO
#    fi
#
#    # Lancer le script SQL
#    ExecScriptSQL "$DEC_NOM_BASE" "$DEC_NOM_USER" "$DEC_FIC_SQL" "'$DEC_INFO_TRAIT'" "'$DEC_NOM_UTILISATEUR'" "'$DEC_NOM_FIC_PARAM'" "'$DEC_DIR_NOM_FIC_PARAM'"
#    if [ $? -ne $CR_OK ]; then
#        AfficherAnomalie "Fonction DeclencherChaine : Erreur lors de l'execution du script SQL [${DEC_FIC_SQL}]"
#        return $CR_KO
#    fi
#
#    # On supprime le fichier .dtc ayant servi au declenchement automatique
#    SupprimerFicParam "$DEC_NOM_CHAINE"
#    if [ $? -ne $CR_OK ]; then
#        AfficherAnomalie "Fonction DeclencherChaine : Erreur lors de la suppression du fichier param de la chaine [${DEC_NOM_CHAINE}]"
#        return $CR_KO
#    fi
#
#    # Recuperer le nom complet du fichier flag
#    DEC_FIC_FLAG="$(GetFichierFlag "$DEC_NOM_CHAINE")"
#    if [ "$(AvecErreur "$DEC_FIC_FLAG")" ]; then
#        AfficherMessage "$DEC_FIC_FLAG"
#        return $CR_KO
#    fi
#
#    # Re-attribuer au compte applicatif la propriete du fichier flag
#    # genere par Oracle
#    ChangerDroitFicOracle "$DEC_FIC_FLAG"
#    if [ $? -ne $CR_OK ]; then
#        AfficherAnomalie "Fonction DeclencherChaine : Erreur lors de la re-attribution de la propriete du fichier flag [${DEC_FIC_FLAG}] au compte applicatif"
#        return $CR_KO
#    fi
#
#    # Retourner le succes du traitement
#    return $CR_OK
#}

#---------------------------------------------------------------------------------------------
# Fonction DeclencherChaine <Nom de la chaine>
#                           <Nom de l'utilisateur>
#                           <Liste des parametres de la chaine>
#                           <Nom user base>
#                           <Nom base>
#							<Statut du declenchement>
#---------------------------------------------------------------------------------------------
function DeclencherChaine
{
    # Usage de la fonction
    DEC_USAGE="Usage : DeclencherChaine <Nom de la chaine> <Nom de l'utilisateur> <Liste des parametres de la chaine> <Nom base> <Nom user base> <Statut du declenchement>"

    # Controler les parametres
    if [ $# -ne 6 ]; then
        AfficherAnomalie "Fonction DeclencherChaine : parametre(s) manquant(s)"
        AfficherAnomalie "$DEC_USAGE"
        return $CR_KO
    fi

    # Memoriser le nom de la chaine
    DEC_NOM_CHAINE="$1"

    # Memoriser le nom de l'utilisateur
    DEC_NOM_UTILISATEUR="$2"

    # Memoriser la liste des parametres
    DEC_PARAM_CHAINE="$3"

    # Memoriser le nom de la base de donnees
    DEC_NOM_BASE="$(FormaterNomBase "$4")"
    if [ "$(AvecErreur "$DEC_NOM_BASE")" ]; then
        AfficherMessage "$DEC_NOM_BASE"
        AfficherAnomalie "$DEC_USAGE"
        return $CR_KO
    fi

    # Memoriser le nom de l'utilisateur de la base de donnees
    DEC_NOM_USER="$5"

	# Memoriser le statut du declenchement
	DEC_STATUT_DEC="$6"

    # Fixer le nom du fichier de script anonyme PL/SQL a lancer
    # pour ecrire un message de log
    DEC_FIC_SQL="DTCEXETRTDEC01.sql"

    # Lancer le script SQL
    ExecScriptSQL "$DEC_NOM_BASE" "$DEC_NOM_USER" "$DEC_FIC_SQL" "'$DEC_NOM_CHAINE'" "'$DEC_NOM_UTILISATEUR'" "'${DEC_STATUT_DEC};${DEC_PARAM_CHAINE}'"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction DeclencherChaine : Erreur lors de l'execution du script SQL [${DEC_FIC_SQL}]"
        return $CR_KO
    fi

    # Retourner le succes du traitement
    return $CR_OK
}

#--------------------------------------------------------
# Fonction ChangerDroitFicOracle <Nom complet du fichier>
#--------------------------------------------------------
function ChangerDroitFicOracle
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction ChangerDroitFicOracle : parametre manquant"
        AfficherAnomalie "Usage : ChangerDroitFicOracle <Nom du fichier>"
        return $CR_KO
    fi

    # Memoriser le nom du fichier
    CDFO_NOM_FIC="$1"

    # Lorsqu'un fichier est genere par oracle le groupe n'a pas les droits de lecture
    # Afin de pouvoir ecrire dans ce fichier via unix on le recopie et on le renomme

    cat "$CDFO_NOM_FIC" > "${CDFO_NOM_FIC}.tmp"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction ChangerDroitFicOracle : Erreur lors de la recopie du fichier [${CDFO_NOM_FIC}] vers [${CDFO_NOM_FIC}.tmp] (cat)"
        return $CR_KO
    fi

    touch -r "$CDFO_NOM_FIC" "${CDFO_NOM_FIC}.tmp"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction ChangerDroitFicOracle : Erreur lors de la recopie du fichier [${CDFO_NOM_FIC}] vers [${CDFO_NOM_FIC}.tmp] (touch)"
        return $CR_KO
    fi

    rm -f "$CDFO_NOM_FIC"

    mv "${CDFO_NOM_FIC}.tmp" "$CDFO_NOM_FIC"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction ChangerDroitFicOracle : Erreur lors de la reaffectation des droits du fichier [${CDFO_NOM_FIC}]"
        return $CR_KO
    fi

    chmod 664 "$CDFO_NOM_FIC"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction ChangerDroitFicOracle : Erreur lors de l'attribution du droit d'ecriture au groupe pour le fichier [${CDFO_NOM_FIC}]"
        return $CR_KO
    fi

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------------
# Fonction EnvoyerMail -c <Nom de la chaine>
#                      -d <Liste des destinataires>
#                      -s [<Sujet du mail>]
#                      -f [<Nom complet du fichier piece jointe>]
#                      -n le fichier est envoye en corps de message
#---------------------------------------------------------------------------------
function EnvoyerMail
{
    # Lecture des parametres
    typeset -i NB_PARAM=0
    while getopts c:d:s:f:n OPTION
    do
        case "$OPTION" in
           c) EM_NOM_CHAINE="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           d) EM_LISTE_EMAIL="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           s) EM_SUJET="$OPTARG"
              ;;
           f) EM_NOM_FIC="$OPTARG"
              ;;
    # <ADD> FAU - 15/10/08 - 1.02
           n) EM_NFLAG=true
              ;;
    # </ADD> FAU - 15/10/08 - 1.02
           ?) AfficherAnomalie "Fonction EnvoyerMail : Option inconnue"
              AfficherAnomalie "EnvoyerMail <Nom de la chaine> <Liste d'email> [<Sujet du mail>] [<Nom complet du fichier piece jointe>]"
              return "$CR_KO"
              ;;
        esac
    done

    # Controler les parametres
    if [ $NB_PARAM -ne 2 ]; then
        AfficherAnomalie "Fonction EnvoyerMail : parametre(s) manquant(s)"
        AfficherAnomalie "EnvoyerMail <Nom de la chaine> <Liste d'email> [<Sujet du mail>] [<Nom complet du fichier piece jointe>]"
        return "$CR_KO"
    fi

    # Controler le nom de la chaine
    ControlerNomTraitement "$EM_NOM_CHAINE"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction EnvoyerMail : Nom de la chaine ["${EM_NOM_CHAINE}"] incorrect."
        return "$CR_KO"
    fi

    # Controler le sujet du mail
    if [ -z "${EM_SUJET}" -a -n "${EM_NOM_FIC}" ]; then
        AfficherAnomalie "Fonction EnvoyerMail : Sujet du mail vide !"
        return "$CR_KO"
    fi


    # On teste si le fichier piece jointe existe
    if [ ! -r $EM_NOM_FIC ]; then
        AfficherAnomalie "Fonction EnvoyerMail : Le fichier piece jointe ["${EM_NOM_FIC}"] n'existe pas !"
        return "$CR_KO"
    fi

    # Envoi du mail
    # <MAJ> FAU - 15/10/08 - 1.02
    AfficherMessage "EnvoyerMail : ${EM_NOM_FIC} ${EM_SUJET}  ${EM_DESTINATAIRES}"
    if $EM_NFLAG ; then
       XXSNDMAIL01.ksh  "$EM_NOM_FIC" "$EM_SUJET" "$EM_LISTE_EMAIL"
    else
       XXSNDMAIL01.ksh -j "$EM_NOM_FIC" "$EM_SUJET" "$EM_LISTE_EMAIL"
    fi
    # </MAJ> FAU - 15/10/08 - 1.02
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction EnvoyerMail : Echec de l'envoi du mail"
        return "$CR_KO"
    fi
    # Retourner le succes du traitement
    return "$CR_OK"
}

#---------------------------------------------------------------------------------
# Fonction EnvoyerMailCRE -c <Nom de la chaine>
#                         -s <Sujet métier du mail>
#                         -f [<Nom complet du fichier piece jointe>]
#                         -r <Résultat du traitement>
#                         -n le fichier est envoye en corps de message
#---------------------------------------------------------------------------------
function EnvoyerMailCRE
{
    # Lecture des parametres

    typeset -i NB_PARAM=0
    while getopts c:s:f:r:n OPTION
    do
        case "$OPTION" in
           c) EMC_NOM_CHAINE="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           s) EMC_SUJET_METIER="$OPTARG"
              ;;
           f) EMC_NOM_FIC="$OPTARG"
              ;;
           r) EMC_RESULT_DTC="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           n) EMC_NFLAG=true
              ;;
           ?) AfficherAnomalie "Fonction EnvoyerMailCRE : Option inconnue"
              AfficherAnomalie "EnvoyerMailCRE <Nom de la chaine> <Sujet métier du mail> [<Nom complet du fichier piece jointe>] <Code Resultat traitement>"
              return "$CR_KO"
              ;;
        esac
    done

    # Controler les parametres
    if [ $NB_PARAM -ne 2 ]; then
        AfficherAnomalie "Fonction EnvoyerMailCRE : parametre(s) manquant(s)"
        AfficherAnomalie "EnvoyerMailCRE <Nom de la chaine> <Sujet métier du mail> [<Nom complet du fichier piece jointe>] <Code Resultat traitement>"
        return "$CR_KO"
    fi

    # Controler le nom de la chaine
    ControlerNomTraitement "$EMC_NOM_CHAINE"
    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction EnvoyerMailCRE : Nom de la chaine ["${EMC_NOM_CHAINE}"] incorrect."
        return "$CR_KO"
    fi

    # Controler le sujet métier du mail
    if [ -z "${EMC_SUJET_METIER}" -a -n "${EMC_NOM_FIC}" ]; then
        AfficherAnomalie "Fonction EnvoyerMailCRE : Sujet du mail vide !"
        return "$CR_KO"
    fi

    # Controler le code statut du traitement
    if [ -z "${EMC_RESULT_DTC}" ]; then
        AfficherAnomalie "Code Statut Traitement vide !"
        return "$CR_KO"
    fi

    typeset -u EMC_HOSTNAME
    EMC_HOSTNAME=$HOSTNAME

    # Fixer la liste par defaut des destinataires du mail
    # en cas d'absence de destinataires designes en parametre
    # ou dans le fichier info de la chaine
    if [ "$ENVIRONNEMENT" = "$ENV_PROD" ]; then
        EMC_LISTE_EMAIL_DEFAUT="ETUDEINFO_COMPTA@bnpparibas.com"
        EMC_LISTE_EMAIL_DEFAUT="ETUDEINFO_COMPTA@cardif.fr"
    else
        EMC_LISTE_EMAIL_DEFAUT="ETUDEINFOCODA@bnpparibas.com"
        EMC_LISTE_EMAIL_DEFAUT="ETUDEINFOCODA@cardif.fr"
    fi

    # Lire dans le fichier Info de la chaine
    # la liste des utilisateurs a qui doit parvenir
    # le resultat de l'execution de la chaine
    EMC_LISTE_EMAIL_INFO="$(LireFicInfo "$CHAINE" "ListeEmail")"
    EMC_DESTINATAIRES="$EMC_LISTE_EMAIL_INFO"

    EMC_INFOTRAIT_INFO="$(LireFicInfo "$CHAINE" "InfoTrait")"

    # Recuperer l'identifiant application
    EMC_ID_APP="$(LireFicInfo "$CHAINE" "IdAPP")"

    # Recuperer le nom de la chaine
    EMC_CHAINE=$(GetXMLVal "$EMC_INFOTRAIT_INFO" "NomChaine")
    if [ -z "$EMC_CHAINE" ]; then
        AfficherInfo "Nom de la chaine non renseigne dans InfoTrait"
        EMC_CHAINE=$EMC_NOM_CHAINE
    fi

    # Recuperer  id traitement
    EMC_ID_EXEC=$(GetXMLVal "$EMC_INFOTRAIT_INFO" "IdExec")
    if [ -z "$EMC_ID_EXEC" ]; then
        AfficherInfo "IdExec non renseigne dans InfoTrait"
    fi

    # Recuperer le user qui a lancé la demande
    EMC_IdUser=$(GetXMLVal "$EMC_INFOTRAIT_INFO" "IdUser")
    if [ -z "$EMC_RoleUser" ]; then
        AfficherInfo "RoleUser non renseigne dans InfoTrait"
    fi

    # <MODIF> DVA - 03/09/08 - 1.01
    #         Modifier la construction du sujet du mail
    #         pour gerer les differents codes de resultat de traitements

    # Determiner le libelle du resultat du traitement
    # en fonction du code resultat
    case "$EMC_RESULT_DTC" in
        0)
            EMC_LIB_RESULT_DTC="OK"
            ;;
        201)
            EMC_LIB_RESULT_DTC="OK MAIS ALERTE TECHN. => A SIGNALER"
            ;;
        202)
            EMC_LIB_RESULT_DTC="KO TECHNIQUE => DECLARER 1 INCIDENT"
            ;;
        203)
            EMC_LIB_RESULT_DTC="KO TECHNIQUE CRITIQUE => DECLARER 1 INCIDENT"
            ;;
        204)
            EMC_LIB_RESULT_DTC="KO FONCTIONNEL => VOIR COMPTE-RENDU"
            ;;
        OK)
            EMC_LIB_RESULT_DTC="OK"
            ;;
        KO)
            EMC_LIB_RESULT_DTC="KO => VOIR COMPTE-RENDU"
            ;;
        *)
            EMC_LIB_RESULT_DTC="KO => VOIR COMPTE-RENDU"
            ;;
    esac

    # Construire le sujet du mail
    EMC_SUJET="DTC["${EMC_ID_APP}"] - Exec :[${EMC_ID_EXEC}] - User : [${EMC_IdUser}] Résultat: [${EMC_LIB_RESULT_DTC} (${EMC_RESULT_DTC})] ${EMC_SUJET_METIER} - (${EMC_CHAINE} ${EMC_HOSTNAME})"

    # </MODIF>

    # En cas d'echec de la lecture dans le fichier Info
    if [ "$(AvecErreur "$EMC_LISTE_EMAIL_INFO")" ]; then
        AfficherMessage "$EMC_LISTE_EMAIL_INFO"
        AfficherAnomalie "Fonction EnvoyerMailCRE : WARNING ! Erreur lors de la lecture de la liste de diffusion mail dans le fichier Info"

            # Fixer la liste des destinataires du mail
            # a celle donnee en parametre du traitement
            # + les destinataires par defaut
            EMC_DESTINATAIRES="$EMC_LISTE_EMAIL_DEFAUT"


     fi


    #Controler le nom du fichier piece jointe
    if [ -z "${EMC_NOM_FIC}" ]; then

        EMC_ID_DEC="$(GetIdDeclenchement "$EMC_NOM_CHAINE")"

        # Fixer le sujet du mail
        EMC_SUJET2="N° exec:[${EMC_ID_EXEC}] - [${EMC_NOM_CHAINE}] : Pas de compte-rendu disponible (${EMC_HOSTNAME})"

        # Recuperer le nom complet du fichier Info de la chaine
        EMC_NOM_FIC="$(GetFichierInfo "$EMC_NOM_CHAINE")"

        # Si le fichier INFO n'existe pas
        if [ "$(AvecErreur "$EMC_NOM_FIC")" ]; then

            # Fixer le sujet du mail
            EMC_SUJET="N° exec:[${EMC_ID_EXEC}] - [${EMC_NOM_CHAINE}] : Pas de compte-rendu disponible (${EMC_HOSTNAME})"

            # Recuperer le nom complet du fichier Flag de declenchement de la chaine
            EMC_NOM_FIC_FLAG="$(GetFichierFlagEnCours "$EMC_NOM_CHAINE")"

            # Si le fichier FLAG en cours n'existe pas, on genere un fichier par defaut
            if [ "$(AvecErreur "$EMC_NOM_FIC")" ]; then

                # Fixer le sujet du mail
                EMC_SUJET="$(date +'%d/%m/%Y %H:%M:%S') - [${CHAINE}] : Pas de compte-rendu ni de fichier INFO ni de fichier FLAG disponible (${EMC_HOSTNAME})"

                # Generer un fichier joint
                EMC_NOM_FIC="${TEMP_APPLI}/${CHAINE}_MAIL_KO"
                echo "TRAITEMENT EN ERREUR. MERCI DE SIGNALER CET INCIDENT AUPRES DE VOTRE SUPPORT INFORMATIQUE." > "$EMC_NOM_FIC"

            fi

        fi

     fi

    # On teste si le fichier piece jointe existe
    if [ ! -r $EMC_NOM_FIC ]; then
        AfficherAnomalie "Fonction EnvoyerMailCRE : Le fichier piece jointe ["${EMC_NOM_FIC}"] n'existe pas !"
        return "$CR_KO"
    fi

    # Envoi du mail
    AfficherMessage "EMC_SUJET " "$EMC_SUJET"
    AfficherMessage "$EMC_NOM_CHAINE " "$EMC_DESTINATAIRES " "$EMC_SUJET " "$EMC_NOM_FIC "
    # <MAJ> FAU - 15/10/08 - 1.02
    if $EMC_NFLAG ; then
       EnvoyerMail -n -c "$EMC_NOM_CHAINE" -d "$EMC_DESTINATAIRES" -s "$EMC_SUJET" -f "$EMC_NOM_FIC"
    else
       EnvoyerMail -c "$EMC_NOM_CHAINE" -d "$EMC_DESTINATAIRES" -s "$EMC_SUJET" -f "$EMC_NOM_FIC"
    fi
    # </MAJ> FAU - 15/10/08 - 1.02


    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction EnvoyerMailCRE : Echec de l'envoi du mail"
        return "$CR_KO"
    fi
    # Retourner le succes du traitement
    return "$CR_OK"
}

#---------------------------------------------------------------------------------
# Fonction CopieFicEnv -i <Infotrait>
#                      -f <Liste des fichiers a copier, separes par un espace>
#                      -r <Repertoire de destination>
#                      -d <Nom base>
#                      -u <Nom user base>
#                      -c facultatif (la source n'est pas supprimee)
#---------------------------------------------------------------------------------
function CopieFicEnv
{

    # Lecture et initialisation des parametres
    CFE_CFLAG=false
    typeset -i NB_PARAM=0
    while getopts i:f:r:d:u:c OPTION
    do
        case "$OPTION" in
           i) CFE_INFO_TRAIT="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           f) CFE_LISTE_FICHIER="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           r) CFE_DESTINATION="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           d) CFE_DATABASE="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           u) CFE_DATABASE_USER="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           c) CFE_CFLAG=true
              ;;
           ?) AfficherAnomalie "Fonction CopieFicEnv: Option inconnue"
              AfficherAnomalie "CopieFicEnv -i <Infotrait> -f <Liste des fichiers a copier, separes par un espace> -r <Repertoire de destination> -d <Nom base> -u <Nom user base> -c"
              return $CR_KO
              ;;
        esac
    done

    # Controler les parametres
    if [ $NB_PARAM -lt 5 ]; then
        AfficherAnomalie "Fonction CopieFicEnv : parametre(s) manquant(s)"
        AfficherAnomalie "CopieFicEnv -i <Infotrait> -f <Liste des fichiers a copier, separes par un espace> -r <Repertoire de destination> -d <Nom base> -u <Nom user base>"
        return $CR_KO
    fi

    # Recuperer le nom de la chaine
    CFE_CHAINE=$(GetXMLVal "$CFE_INFO_TRAIT" "NomChaine")
    if [ -z "$CFE_CHAINE" ]; then
        AfficherInfo "Nom de la chaine non renseigne dans InfoTrait"
        return $CR_KO
    fi

    # Test de l'existence des fichiers
    for FICHIER in $CFE_LISTE_FICHIER
    do
        if [ ! -r $FICHIER ]; then
            AfficherAnomalie "$TRAITEMENT : Le fichier : [${FICHIER}] n'existe pas ou n'est pas accessible en lecture!"
            AfficherAnomalie "TRAITEMENT INTERROMPU"
            return $CR_KO
        fi
    done

    # Afficher la liste des fichiers a copier vers la destination choisie
    AfficherInfo "Liste des fichiers a transferer vers ${CFE_DESTINATION} :"
    printf "$CFE_LISTE_FICHIER"

    # Copie de fichier vers la destination passee en parametre
    for FICHIER in $CFE_LISTE_FICHIER
    do

        # Afficher les parametres de la copie
        AfficherInfo "Copie du fichier [${FICHIER}] vers [${CFE_DESTINATION}]"

        # Tracer les parametres de la copie dans la table des log
        EcrireLog "$CFE_INFO_TRAIT" \
                  "INF" \
                  "Copie du fichier [${FICHIER}] vers [${CFE_DESTINATION}]" \
                  0 \
                  "${CFE_CHAINE}.ksh" \
                  "$CFE_DATABASE" \
                  "$CFE_DATABASE_USER"

        if [ $? -ne $CR_OK ]; then
            AfficherAnomalie "$TRAITEMENT : Echec de l'ecriture dans la table log_message"
            return $CR_KO
        fi

        # Realiser la copie (et l'archivage) du fichier courant
        # <MODIF 23/01/2009 1.1> gestion flag c : copy et archivage fichier sans supprimer la source
        if $CFE_CFLAG ; then
           AfficherInfo "Copie sans suppression source"
           PC_COPY_FICUNIX "$FICHIER" "$CFE_DESTINATION"
           FIC_ARCH="$(basename $FICHIER | cut -d '.' -f1)_$(date +%Y%m%d_%H%M%S).$(basename $FICHIER | cut -d '.' -f2-)"
           cat $FICHIER | compress >${ARCH_APPLI}/${FIC_ARCH}.Z
        else
           AfficherInfo "Copie avec suppression source"
           XXCOPFLUX01.ksh -a -Z "$FICHIER" "$CFE_DESTINATION"
        fi
        # </MODIF>
        if [ $? -ne $CR_OK ]; then
            EcrireLog "$CFE_INFO_TRAIT" \
                      "ERR" \
                      "ECHEC de la copie du fichier [${FICHIER}] vers [${CFE_DESTINATION}]" \
                      0 \
                      "${CFE_CHAINE}.ksh" \
                      "$CFE_DATABASE" \
                      "$CFE_DATABASE_USER"
            AfficherAnomalie "$TRAITEMENT : Echec de la copie du fichier [${FICHIER}] vers [${CFE_DESTINATION}]"
            return $CR_KO
        fi

    done

    # Tracer le succes de la copie des fichiers
    EcrireLog "$INFO_TRAIT" \
              "INF" \
              "Copie des fichiers vers ${CFE_DESTINATION} realisee avec succes" \
              0 \
              "${CFE_CHAINE}.ksh" \
              "$CFE_DATABASE" \
              "$CFE_DATABASE_USER"

    if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "$TRAITEMENT : Echec de l'ecriture dans la table log_message"
        return $CR_KO
    fi

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------------
# Fonction TransfertFicCFT -f <Liste des fichiers a envoyer, separes avec un espace>
#                          -c <Serveur de destination>
#                          -i <Id de transfert CFT>
#                          -a <Archivage et suppression du fichier d'origine>
#---------------------------------------------------------------------------------
function TransfertFicCFT
{
    # Lecture des parametres
    typeset -i NB_PARAM=0
    while getopts f:c:i:a OPTION
    do
        case "$OPTION" in
           f) TFC_LISTE_FICHIER="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           c) TFC_DESTINATION="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           i) TFC_ID_TRANSFERT="$OPTARG"
              NB_PARAM=$NB_PARAM+1
              ;;
           a) TFC_ARCHIVAGE="-a -Z"
              ;;
           ?) AfficherAnomalie "Fonction TransfertFicCFT: Option inconnue"
              AfficherAnomalie "TransfertFicCFT -f <Liste des fichiers a envoyer, separes avec un espace> -c <Serveur de destination> -i <Id de transfert CFT> -a <Archivage et suppression du fichier d'origine>"
              return $CR_KO
              ;;
        esac
    done

    # Controler les parametres
    if [ $NB_PARAM -lt 3 ]; then
        AfficherAnomalie "Fonction TransfertFicCFT : parametre(s) manquant(s)"
        AfficherAnomalie "TransfertFicCFT -f <Liste des fichiers a envoyer, separes avec un espace> -c <Serveur de destination> -i <Id de transfert CFT> -a <Archivage et suppression du fichier d'origine>"
        return $CR_KO
    fi

    echo "TFC_ARCHIVAGE : ${TFC_ARCHIVAGE}"

    for FICHIER in $TFC_LISTE_FICHIER
    do
        # Afficher les parametres de la copie
        AfficherInfo "Transfert CFT du fichier [${FICHIER}] vers [${TFC_DESTINATION}]"

        #Asuser cft CFTUTIL SEND PART=${PART_APLKWR}, IDF=${IDF_ASSURETAT}, FNAME="$OUT_APPLI/$FIC_OUT", PARM="$FIC_CIBLE"
        XX_SEND_CFTFIC $TFC_ARCHIVAGE -t 1800 -p "${TFC_DESTINATION}" -i "${TFC_ID_TRANSFERT}" -f "$FICHIER" -m "$(basename $FICHIER)" -F

        if [ $? -ne $CR_OK ]; then
            AfficherAnomalie "$TRAITEMENT : Echec de l'envoit par CFT du fichier : [${FICHIER}] vers [${TFC_DESTINATION}]"
            return $CR_KO
        fi
    done

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction RecupCLOB <Nom base> <Nom User> <RC_TABLE> <RC_COL> <RC_COL_DEC> <ID_DEC> <RC_COL_PARAM> <ID_PARAM> <RC_DIR> <RC_FIC> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00
    #         Modification des parametres d'appel du XXEXESQLORA01.ksh
    #         - suppression du parametre -e

function RecupCLOB
{
    # Controler les parametres
    if [ $# -lt 10 ]; then
        AfficherAnomalie "Fonction RecupCLOB : parametre manquant"
        AfficherAnomalie "Usage : RecupCLOB <Nom base> <Nom User> <RC_TABLE> <RC_COL> <RC_COL_DEC> <ID_DEC> <RC_COL_PARAM> <ID_PARAM> <RC_DIR> <RC_FIC> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les parametres
    RC_NOM_BASE="$1"
    RC_NOM_USER="$2"
    RC_TABLE="$3"
    RC_COL="$4"
    RC_COL_DEC="$5"
    RC_ID_DEC="$6"
    RC_COL_PARAM="$7"
    RC_ID_PARAM="$8"
    RC_DIR="$9"
    RC_FIC="${10}"
    shift 10
    RC_PARAM="$*"

	SelectVarParam "${RC_NOM_BASE}" "${RC_NOM_USER}" "select ${RC_DIR} from ${RC_TABLE} where ${RC_COL_DEC} = '${RC_ID_DEC}' and ${RC_COL_PARAM} = '${RC_ID_PARAM}'" "RC_DIRNAME"

        SelectVarParam "${RC_NOM_BASE}" "${RC_NOM_USER}" "select ${RC_FIC} from ${RC_TABLE} where ${RC_COL_DEC} = '${RC_ID_DEC}' and ${RC_COL_PARAM} = '${RC_ID_PARAM}'" "RC_FICNAME"

	eval "RC_DIRNAME=\$${RC_DIRNAME}"

    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    #RC_ORACLE_SID_OLD="$ORACLE_SID"
    ORACLE_SID="$RC_NOM_BASE"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    #ORAPASS=$(PC_PASSWD_INSORA $ORACLE_SID $RC_NOM_USER)
    #if [ $? -ne 0 ]; then
    #   AfficherAnomalie"Fonction RecupCLOB : Mot de passe non trouve pour user [$RC_NOM_USER] "
    #   return $CR_KO
    #fi

    ##Afficher le contexte d'execution du script SQL
    #AfficherInfo "Base d'execution  : [${ORACLE_SID}]"
    #AfficherInfo "Schema utilise    : [${RC_NOM_USER}]"
    #AfficherInfo "Fichier de sortie : [${RC_DIRNAME}/${RC_FICNAME}]"
    #AfficherInfo "Table d'extraction: [${RC_TABLE}]"
    #AfficherInfo "Colonne du CLOB   : [${RC_COL}]"
    #AfficherInfo "Colonne du ident  : [${RC_COL_DEC}]"
    #AfficherInfo "Identifiant       : [${RC_ID_DEC}]"
    #AfficherInfo "Colonne du param  : [${RC_COL_PARAM}]"
    #AfficherInfo "id paramètre      : [${RC_ID_PARAM}]"
    #AfficherInfo "Parametres script : [${RC_PARAM}]"

    # Executer le script
    # AfficherInfo "Debut du script PL/SQL : $(date)"

    #  echo ". DTCEXETRTSQL01.ksh"
    #  echo "    -mode select_clob"
    #  echo "    -f ${RC_DIRNAME}/${RC_FICNAME} "
    #  echo "    -u ${RC_NOM_USER} "
    #  echo "    -p ${ORAPASS} "
    #  echo "     -servername ${ORACLE_SID} "
    #  echo "     -sqlcodeEnvvar VAR_CODE "
    #  echo "     -msgerrEnvvar VAR_ERREUR "
    #  echo "     -nbrowsEnvvar VAR_NB "
    #  echo "     -execDurationEnvvar VAR_TIME "
    #  echo "     -clobcol ${RC_COL} "
    #  echo "     -q select ${RC_COL} from $RC_TABLE where ${RC_COL_DEC} = '$RC_ID_DEC' and ${RC_COL_PARAM} = '$RC_ID_PARAM'"
    #  echo "     ${RC_PARAM}"

    VAR_CODE="SANS"
    VAR_ERREUR="SANS"
    VAR_NB="SANS"
    VAR_TIME="SANS"

. DTCEXETRTSQL01.ksh \
-mode select_clob \
-f "${RC_DIRNAME}"/"${RC_FICNAME}" \
-u "${RC_NOM_USER}" \
-servername "${ORACLE_SID}" \
-sqlcodeEnvvar VAR_CODE \
-msgerrEnvvar VAR_ERREUR \
-nbrowsEnvvar VAR_NB \
-execDurationEnvvar VAR_TIME \
-clobcol "${RC_COL}" \
-q "  select "${RC_COL}" from "${RC_TABLE}" where "${RC_COL_DEC}"='"${RC_ID_DEC}"' and "${RC_COL_PARAM}"='"${RC_ID_PARAM}"'  " \
${RC_PARAM} >> /dev/null

    if [ ${VAR_CODE} = "SANS" ]; then
    RC_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     RC_CR_SCRIPT="204"
	else
	RC_CR_SCRIPT="0"
    	fi
    fi
    #echo " VAR_CODE : ${VAR_CODE}"
    #echo " VAR_ERREUR : ${VAR_ERREUR} "
    #echo " VAR_NB : ${VAR_NB} "
    #echo " VAR_TIME : ${VAR_TIME} "


    #AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$RC_CR_SCRIPT)"

    # Restaurer la base de donnee courante initiale
    #export ORACLE_SID="$RC_ORACLE_SID_OLD"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # retourner le resultat du traitement
    return "$RC_CR_SCRIPT"
}

#---------------------------------------------------------------------------
# Fonction RecupCLOBDefaut <Nom base> <Nom User> <ID_DEC> <ID_PARAM> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00
    #         Modification des parametres d'appel du XXEXESQLORA01.ksh
    #         - suppression du parametre -e

function RecupCLOBDefaut
{
# Memoriser les parametres
    RCD_NOM_BASE="$1"
    RCD_NOM_USER="$2"
    RCD_ID_DEC="$3"
    RCD_ID_PARAM="$4"
    shift 4
    RCD_PARAM="$*"

    AfficherInfo "RecupCLOB : $RCD_NOM_BASE $RCD_NOM_USER TA_CLOB TEXTE ID_DEC $RCD_ID_DEC NOM_PARAM $RCD_ID_PARAM REP_FICHIER NOM_FICHIER $RCD_PARAM"

  RecupCLOB "$RCD_NOM_BASE" "$RCD_NOM_USER" "TA_CLOB" "TEXTE" "ID_DEC" "$RCD_ID_DEC" "NOM_PARAM" "$RCD_ID_PARAM" "REP_FICHIER" "NOM_FICHIER" "$RCD_PARAM"

     if [ ${VAR_CODE} = "SANS" ]; then
    RC_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     RC_CR_SCRIPT="204"
	else
	RC_CR_SCRIPT="0"
    	fi
    fi

return "$RCD_CR_SCRIPT"

}

#---------------------------------------------------------------------------
# Fonction RecupCLOBFichier <Nom base> <Nom User> <Nom Fichier sorti> <Nom du fichier de requete> <Nom de colonne>  <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00
    #         Modification des parametres d'appel du XXEXESQLORA01.ksh
    #         - suppression du parametre -e

function RecupCLOBFichier
{
    # Controler les parametres
    if [ $# -lt 5 ]; then
      AfficherAnomalie "Fonction RecupCLOBFichier : parametre manquant"
      AfficherAnomalie "Usage : RecupCLOBFichier <Nom base> <Nom User> <Nom Fichier sorti> <Nom du fichier de requete> <Nom de colonne> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les parametres
    RCF_NOM_BASE="$1"
    RCF_NOM_USER="$2"
    RCF_NOM_FIC="$3"
    RCF_REQ="$4"
    RCF_COL="$5"
    shift 5
    RCF_PARAM="$*"


    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    #RCF_ORACLE_SID_OLD="$ORACLE_SID"
    ORACLE_SID="$RCF_NOM_BASE"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    #ORAPASS=$(PC_PASSWD_INSORA $ORACLE_SID $RCF_NOM_USER)
    #if [ $? -ne 0 ]; then
    #   AfficherAnomalie"Fonction RecupCLOBFichier : Mot de passe non trouve pour user [$RCF_NOM_USER] "
    #   return $CR_KO
    #fi

    # Afficher le contexte d'execution du script SQL
    # AfficherInfo "Base d'execution  : [${ORACLE_SID}]"
    # AfficherInfo "Schema utilise    : [${RCF_NOM_USER}]"
    # AfficherInfo "Fichier de sortie : [${RCF_NOM_FIC}]"
    # AfficherInfo "fichier de requete: [${RCF_REQ}]"
    # AfficherInfo "Colonne du CLOB   : [${RCF_COL}]"
    # AfficherInfo "Parametres script : [${RCF_PARAM}]"

    # Executer le script
    # AfficherInfo "Debut du script PL/SQL : $(date)"

    # echo ". script.sh"
    # echo "    -mode select_clob"
    # echo "    -f ${RCF_NOM_FIC} "
    # echo "    -u ${RCF_NOM_USER} "
    # echo "    -p ${ORAPASS} "
    # echo "     -servername ${ORACLE_SID} "
    # echo "     -sqlcodeEnvvar VAR_CODE "
    # echo "     -msgerrEnvvar VAR_ERREUR "
    # echo "     -nbrowsEnvvar VAR_NB "
    # echo "     -execDurationEnvvar VAR_TIME "
    # echo "     -clobcol ${RCF_COL} "
    # echo "     -qf ${RCF_REQ}"
    # echo "     ${RCF_PARAM}"

. DTCEXETRTSQL01.ksh \
-mode select_clob \
-f "${RCF_NOM_FIC}" \
-u "${RCF_NOM_USER}" \
-servername "${ORACLE_SID}" \
-sqlcodeEnvvar VAR_CODE \
-msgerrEnvvar VAR_ERREUR \
-nbrowsEnvvar VAR_NB \
-execDurationEnvvar VAR_TIME \
-clobcol "${RCF_COL}" \
-qf "${RCF_REQ}" \
${RCF_PARAM} >> /dev/null

         if [ ${VAR_CODE} = "SANS" ]; then
    RCF_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     RCF_CR_SCRIPT="204"
	else
	RCF_CR_SCRIPT="0"
    	fi
    fi

    # echo " VAR_CODE : ${VAR_CODE}"
    # echo " VAR_ERREUR : ${VAR_ERREUR} "
    # echo " VAR_NB : ${VAR_NB} "
    # echo " VAR_TIME : ${VAR_TIME} "



    # AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$RCF_CR_SCRIPT)"

    # Restaurer la base de donnee courante initiale
    #export ORACLE_SID="$RCF_ORACLE_SID_OLD"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # retourner le resultat du traitement
    return "$RCF_CR_SCRIPT"
}

#---------------------------------------------------------------------------
# Fonction RecupCLOB2 <Nom base> <Nom User> <Requete> <Nom champ CLOB> <Repertoire du fichier> <Nom du fichier> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------

function RecupCLOB2
{
    # Controler les parametres
    if [ $# -lt 6 ]; then
        AfficherAnomalie "Fonction RecupCLOB2 : parametre manquant"
        AfficherAnomalie "Usage : RecupCLOB2 <Nom base> <Nom User> <Requete> <Nom champ CLOB> <Repertoire du fichier> <Nom du fichier> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les parametres
    RC2_NOM_BASE="$1"
    RC2_NOM_USER="$2"
    RC2_REQUETE="$3"
    RC2_COL_CLOB="$4"
    RC2_DIR="$5"
    RC2_FIC="$6"
    shift 6
    RC2_PARAM="$*"

    VAR_CODE="SANS"
    VAR_ERREUR="SANS"
    VAR_NB="SANS"
    VAR_TIME="SANS"

. DTCEXETRTSQL01.ksh \
-mode select_clob \
-f "${RC2_DIR}/${RC2_FIC}" \
-u "${RC2_NOM_USER}" \
-servername "${RC2_NOM_BASE}" \
-sqlcodeEnvvar VAR_CODE \
-msgerrEnvvar VAR_ERREUR \
-nbrowsEnvvar VAR_NB \
-execDurationEnvvar VAR_TIME \
-clobcol "${RC2_COL_CLOB}" \
-q "${RC2_REQUETE}" \
"${RC2_PARAM}" >> /dev/null 

    if [ "${VAR_CODE}" = "SANS" ]; then
        RC2_CR_SCRIPT="$CR_KO"
    else
        if [ ! "${VAR_CODE}" = "0" ]; then
            RC2_CR_SCRIPT="$CR_KO_FONCTIONNEL"
        else
            RC2_CR_SCRIPT="$CR_OK"
        fi
    fi

    # retourner le resultat du traitement
    return "$RC2_CR_SCRIPT"
}

#---------------------------------------------------------------------------
# Fonction AjouterCLOB <Nom base> <Nom User> <Nom Fichier entree> <AC_TABLE> <AC_COL> <AC_IND> <AC_COL_DEC> <AC_ID_DEC> <AC_COL_PARAM> <AC_ID_PARAM> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------

# <CREA> RLE - 28/04/2009 - 1.00


function AjouterCLOB
{
    # Controler les parametres
    if [ $# -lt 10 ]; then
        AfficherAnomalie "Fonction AjouterCLOB : parametre manquant"
        AfficherAnomalie "Usage : AjouterCLOB <Nom base> <Nom User> <Nom Fichier entree> <AC_TABLE> <AC_COL> <AC_IND> <AC_COL_DEC> <AC_ID_DEC> <AC_COL_PARAM> <AC_ID_PARAM> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les parametres
    AC_NOM_BASE="$1"
    AC_NOM_USER="$2"
    AC_NOM_FIC="$3"
    AC_TABLE="$4"
    AC_COL="$5"
    AC_IND="$6"
    AC_COL_DEC="$7"
    AC_ID_DEC="$8"
    AC_COL_PARAM="$9"
    AC_ID_PARAM="${10}"
    shift 10
    AC_PARAM="$*"


    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    #AC_ORACLE_SID_OLD="$ORACLE_SID"
    ORACLE_SID="$AC_NOM_BASE"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    #ORAPASS=$(PC_PASSWD_INSORA $ORACLE_SID $AC_NOM_USER)
    #if [ $? -ne 0 ]; then
    #   AfficherAnomalie"Fonction RecupCLOBFichier : Mot de passe non trouve pour user [$AC_NOM_USER] "
    #   return $CR_KO
    #fi

    # Afficher le contexte d'execution du script
    # AfficherInfo "Base d'execution  : [${ORACLE_SID}]"
    # AfficherInfo "Schema utilise    : [${AC_NOM_USER}]"
    # AfficherInfo "Fichier d'entree  : [${AC_NOM_FIC}]"
    # AfficherInfo "Table d'insertion : [${AC_TABLE}]"
    # AfficherInfo "Colonne du CLOB   : [${AC_COL}]"
    # AfficherInfo "Colonne de l'ordre: [${AC_IND}]"
    # AfficherInfo "Colonne du ident  : [${AC_COL_DEC}]"
    # AfficherInfo "Identifiant       : [${AC_ID_DEC}]"
    # AfficherInfo "Colonne du param  : [${AC_COL_PARAM}]"
    # AfficherInfo "id paramètre      : [${AC_ID_PARAM}]"
    # AfficherInfo "Parametres script : [${AC_PARAM}]"

    # Executer le script
    # AfficherInfo "Debut du script PL/SQL : $(date)"

AC_PARAM="${AC_COL_DEC}=${AC_ID_DEC}|${AC_COL_PARAM}=${AC_ID_PARAM}|$AC_PARAM"

    # echo ". DTCEXETRTSQL01.ksh"
    # echo "    -mode insert_clob"
    # echo "    -f ${AC_NOM_FIC} "
    # echo "    -u ${AC_NOM_USER} "
    # echo "    -p ${AC_NOM_USER} "
    # echo "     -servername ${ORACLE_SID} "
    # echo "     -sqlcodeEnvvar VAR_CODE "
    # echo "     -msgerrEnvvar VAR_ERREUR "
    # echo "     -nbrowsEnvvar VAR_NB "
    # echo "     -execDurationEnvvar VAR_TIME "
    # echo "     -tablename ${AC_TABLE} "
    # echo "     -clobcol ${AC_COL} "
    # echo "     -indexcol ${AC_IND} "
    # echo "     -param ${AC_PARAM}"

. DTCEXETRTSQL01.ksh \
-mode insert_clob \
-f "${AC_NOM_FIC}" \
-u "${AC_NOM_USER}" \
-servername "${ORACLE_SID}" \
-sqlcodeEnvvar VAR_CODE \
-msgerrEnvvar VAR_ERREUR \
-nbrowsEnvvar VAR_NB \
-execDurationEnvvar VAR_TIME \
-tablename "${AC_TABLE}" \
-clobcol "${AC_COL}" \
-indexcol "${AC_IND}" \
-param "${AC_PARAM}" >> /dev/null

    # echo " VAR_CODE : ${VAR_CODE}"
    # echo " VAR_ERREUR : ${VAR_ERREUR} "
    # echo " VAR_NB : ${VAR_NB} "
    # echo " VAR_TIME : ${VAR_TIME} "

     if [ ${VAR_CODE} = "SANS" ]; then
    AC_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     AC_CR_SCRIPT="204"
	else
	RC_CR_SCRIPT="0"
    	fi
    fi


    # AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$AC_CR_SCRIPT)"

    # Restaurer la base de donnee courante initiale
    #export ORACLE_SID="$AC_ORACLE_SID_OLD"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # retourner le resultat du traitement
    return "$AC_CR_SCRIPT"
}

#---------------------------------------------------------------------------
# Fonction AjouterCLOBDefaut <Nom base> <Nom User> <Nom Fichier sorti> <ID_DEC> <ID_PARAM> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00


function AjouterCLOBDefaut
{
# Memoriser les parametres
    ACD_NOM_BASE="$1"
    ACD_NOM_USER="$2"
    ACD_NOM_FIC="$3"
    ACD_ID_DEC="$4"
    ACD_ID_PARAM="$5"
    shift;shift;shift;shift;shift
    ACD_PARAM="$*"

  AfficherInfo "AjouterCLOB : $ACD_NOM_BASE $ACD_NOM_USER $ACD_NOM_FIC TA_CLOB TEXTE ID_DEC $ACD_ID_DEC NOM_PARAM $ACD_ID_PARAM $ACD_PARAM "

  AjouterCLOB "$ACD_NOM_BASE" "$ACD_NOM_USER" "$ACD_NOM_FIC" "TA_CLOB" "TEXTE" "ORDRE" "ID_DEC" "$ACD_ID_DEC" "NOM_PARAM" "$ACD_ID_PARAM" "$ACD_PARAM"

       if [ ${VAR_CODE} = "SANS" ]; then
    ACD_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     ACD_CR_SCRIPT="204"
	else
	RCD_CR_SCRIPT="0"
    	fi
    fi

return "$ACD_CR_SCRIPT"

}

#---------------------------------------------------------------------------
# Fonction SelectReqParam <Nom base> <Nom User> <Requete> <Nom reception> <Entete Colonne> <Valeur Unique> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00


function SelectReqParam
{
    # Controler les parametres
    if [ $# -lt 6 ]; then
        AfficherAnomalie "Fonction SelectReqParam : parametre manquant"
        AfficherAnomalie "Usage : SelectReqParam <Nom base> <Nom User> <Requete> <Nom reception> <Entete Colonne> <Valeur Unique> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les parametres
    SRP_NOM_BASE="$1"
    SRP_NOM_USER="$2"
    SRP_REQ="$3"
    SRP_REC="$4"
    SRP_COL="$5"
    SRP_UNI="$6"
    shift 6
    SRP_PARAM="$*"

    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    #ORACLE_SID_OLD="$ORACLE_SID"
    ORACLE_SID="$SRP_NOM_BASE"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    #ORAPASS=$(PC_PASSWD_INSORA $ORACLE_SID $SRP_NOM_USER)
    #if [ $? -ne 0 ]; then
    #   AfficherAnomalie"Fonction SelectReqParam : Mot de passe non trouve pour user [$SRP_NOM_USER] "
    #   return $CR_KO
    #fi

    # Afficher le contexte d'execution du script
    # AfficherInfo "Base d'execution  : [${ORACLE_SID}]"
    # AfficherInfo "Schema utilise    : [${SRP_NOM_BASE}]"
    # AfficherInfo "Requete	    : [${SRP_REQ}]"
    # AfficherInfo "Mom recuperation  : [${SRP_REC}]"
    # AfficherInfo "Entete colonne    : [${SRP_COL}]"
    # AfficherInfo "Valeur unique     : [${SRP_UNI}]"
    # AfficherInfo "Parametres script : [${SRP_PARAM}]"

    # Executer le script
    # AfficherInfo "Debut du script PL/SQL : $(date)"

     # echo ". DTCEXETRTSQL01.ksh"
     # echo "    -mode select_query"
     # echo "    -q ${SRP_REQ} "
     # echo "    -u ${SRP_NOM_USER} "
     # echo "    -p ${ORAPASS} "
     # echo "     -servername ${ORACLE_SID} "
     # echo "     -sqlcodeEnvvar VAR_CODE "
     # echo "     -msgerrEnvvar VAR_ERREUR "
     # echo "     -nbrowsEnvvar VAR_NB "
     # echo "     -execDurationEnvvar VAR_TIME "
     # echo "     -to F "
     # echo "     -out ${SRP_REC} "
     # echo "     -colname ${SRP_COL}"
     # echo "     -unique ${SRP_UNI}"
     # echo "     ${SRP_PARAM}"

. DTCEXETRTSQL01.ksh \
-mode select_query \
-q "${SRP_REQ}" \
-u "${SRP_NOM_USER}" \
-servername "${ORACLE_SID}" \
-sqlcodeEnvvar VAR_CODE \
-msgerrEnvvar VAR_ERREUR \
-nbrowsEnvvar VAR_NB \
-execDurationEnvvar VAR_TIME \
-to F \
-out "${SRP_REC}" \
-colname "${SRP_COL}" \
-unique "${SRP_UNI}" \
"${SRP_PARAM}" >> /dev/null

       if [ ${VAR_CODE} = "SANS" ]; then
    SRP_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     SRP_CR_SCRIPT="204"
	else
	SRP_CR_SCRIPT="0"
    	fi
    fi

    # echo " VAR_CODE : ${VAR_CODE}"
    # echo " VAR_ERREUR : ${VAR_ERREUR} "
    # echo " VAR_NB : ${VAR_NB} "
    # echo " VAR_TIME : ${VAR_TIME} "


    # AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$SRP_CR_SCRIPT)"

    # Restaurer la base de donnee courante initiale
    #export ORACLE_SID="$RC_ORACLE_SID_OLD"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # retourner le resultat du traitement
    return "$SRP_CR_SCRIPT"
}

#---------------------------------------------------------------------------
# Fonction SelectReqParamEntete <Nom base> <Nom User> <Requete> <Nom reception> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00


function SelectReqParamEntete
{
    # Controler les parametres
    if [ $# -lt 4 ]; then
        AfficherAnomalie "Fonction SelectReqParamEntete : parametre manquant"
        AfficherAnomalie "Usage : SelectReqParamEntete <Nom base> <Nom User> <Requete> <Nom reception> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les parametres
    SRPE_NOM_BASE="$1"
    SRPE_NOM_USER="$2"
    SRPE_REQ="$3"
    SRPE_REC="$4"
    shift 4
    SRPE_PARAM="$*"

    # AfficherInfo "SelectReqParam : $SRPE_NOM_BASE $SRPE_NOM_USER $SRPE_REQ $SRPE_REC Y N $SRPE_PARAM"

    SelectReqParam "$SRPE_NOM_BASE" "$SRPE_NOM_USER" "$SRPE_REQ" "$SRPE_REC" "Y" "N" "$SRPE_PARAM"

   if [ ${VAR_CODE} = "SANS" ]; then
    SRPE_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     SRPE_CR_SCRIPT="204"
	else
	SRPE_CR_SCRIPT="0"
    	fi
    fi

return "$SRPE_CR_SCRIPT"

}

#---------------------------------------------------------------------------
# Fonction SelectReqFichier <Nom base> <Nom User> <Nom fichier entree> <Nom reception> <Entete Colonne> <Valeur Unique> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00

function SelectReqFichier
{
    # Controler les parametre
    if [ $# -lt 6 ]; then
        AfficherAnomalie "Fonction SelectReqFichier : parametre manquant"
        AfficherAnomalie "Usage : SelectReqFichier <Nom base> <Nom User> <Nom fichier entree> <Nom reception> <Entete Colonne> <Valeur Unique> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les Paramètres
    SRF_NOM_BASE="$1"
    SRF_NOM_USER="$2"
    SRF_FIC="$3"
    SRF_REC="$4"
    SRF_COL="$5"
    SRF_UNI="$6"
    shift 6
    SRF_PARAM="$*"

    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    #ORACLE_SID_OLD="$ORACLE_SID"
    ORACLE_SID="$SRF_NOM_BASE"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    #ORAPASS=$(PC_PASSWD_INSORA $ORACLE_SID $SRF_NOM_USER)
    #if [ $? -ne 0 ]; then
    #   AfficherAnomalie"Fonction SelectReqParam : Mot de passe non trouve pour user [$SRF_NOM_USER] "
    #   return $CR_KO
    #fi

    # Afficher le contexte d'execution du script
    # AfficherInfo "Base d'execution  : [${ORACLE_SID}]"
    # AfficherInfo "Schema utilise    : [${SRF_NOM_BASE}]"
    # AfficherInfo "Fichier entrée    : [${SRF_FIC}]"
    # AfficherInfo "Mom recuperation  : [${SRF_REC}]"
    # AfficherInfo "Entete colonne    : [${SRF_COL}]"
    # AfficherInfo "Valeur unique     : [${SRF_UNI}]"
    # AfficherInfo "Paramètres script : [${SRF_PARAM}]"

    # Executer le script
    # AfficherInfo "Debut du script PL/SQL : $(date)"

    # echo ". DTCEXETRTSQL01.ksh"
    # echo "    -mode select_query"
    # echo "    -qf ${SRF_FIC} "
    # echo "    -u ${SRF_NOM_USER} "
    # echo "    -p ${ORAPASS} "
    # echo "     -servername ${ORACLE_SID} "
    # echo "     -sqlcodeEnvvar VAR_CODE "
    # echo "     -msgerrEnvvar VAR_ERREUR "
    # echo "     -nbrowsEnvvar VAR_NB "
    # echo "     -execDurationEnvvar VAR_TIME "
    # echo "     -to F "
    # echo "     -out ${SRF_REC} "
    # echo "     -colname ${SRF_COL}"
    # echo "     -unique ${SRF_UNI}"
    # echo "     ${SRF_PARAM}"

. DTCEXETRTSQL01.ksh \
-mode select_query \
-qf "${SRF_FIC}" \
-u "${SRF_NOM_USER}" \
-servername "${ORACLE_SID}" \
-sqlcodeEnvvar VAR_CODE \
-msgerrEnvvar VAR_ERREUR \
-nbrowsEnvvar VAR_NB \
-execDurationEnvvar VAR_TIME \
-to F \
-out "${SRF_REC}" \
-colname "${SRF_COL}" \
-unique "${SRF_UNI}" \
"${SRF_PARAM}" >> /dev/null

     if [ ${VAR_CODE} = "SANS" ]; then
    SRF_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     SRF_CR_SCRIPT="204"
	else
	SRF_CR_SCRIPT="0"
    	fi
    fi


    # echo " VAR_CODE : ${VAR_CODE}"
    # echo " VAR_ERREUR : ${VAR_ERREUR} "
    # echo " VAR_NB : ${VAR_NB} "
    # echo " VAR_TIME : ${VAR_TIME} "


    # AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$SRF_CR_SCRIPT)"

    # Restaurer la base de donnee courante initiale
    #export ORACLE_SID="$RC_ORACLE_SID_OLD"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # retourner le resultat du traitement
    return "$SRF_CR_SCRIPT"
}

#---------------------------------------------------------------------------
# Fonction SelectReqFichierEntete <Nom base> <Nom User> <Nom fichier entree> <Nom reception> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00


function SelectReqFichierEntete
{
    # Controler les parametres
    if [ $# -lt 4 ]; then
        AfficherAnomalie "Fonction SelectReqFichierEntete : parametre manquant"
        AfficherAnomalie "Usage : SelectReqFichierEntete <Nom base> <Nom User> <Nom fichier entree> <Nom reception> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les parametres
    SRFE_NOM_BASE="$1"
    SRFE_NOM_USER="$2"
    SRFE_REQ="$3"
    SRFE_REC="$4"
    shift 4
    SRFE_PARAM="$*"

    # AfficherInfo "SelectReqFichier : $SRFE_NOM_BASE $SRFE_NOM_USER $SRFE_REQ $SRFE_REC Y N $SRFE_PARAM"

    SelectReqFichier "$SRFE_NOM_BASE" "$SRFE_NOM_USER" "$SRFE_REQ" "$SRFE_REC" "Y" "N" "$SRFE_PARAM"

     if [ ${VAR_CODE} = "SANS" ]; then
    SRFE_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     SRFE_CR_SCRIPT="204"
	else
	SRFE_CR_SCRIPT="0"
    	fi
    fi

return "$SRFE_CR_SCRIPT"

}

#---------------------------------------------------------------------------
# Fonction SelectVarParam <Nom base> <Nom User> <Requete> <Nom reception> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00


function SelectVarParam
{
    # Controler les parametres
    if [ $# -lt 4 ]; then
        AfficherAnomalie "Fonction SelectVarParam : parametre manquant"
        AfficherAnomalie "Usage : SelectVarParam <Nom base> <Nom User> <Requete> <Nom reception> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les parametres
    SVP_NOM_BASE="$1"
    SVP_NOM_USER="$2"
    SVP_REQ="$3"
    SVP_REC="$4"
    shift 4
    SVP_PARAM="$*"

    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    #ORACLE_SID_OLD="$ORACLE_SID"
    export ORACLE_SID="$SVP_NOM_BASE"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    #ORAPASS=$(PC_PASSWD_INSORA $ORACLE_SID $SVP_NOM_USER)
    #if [ $? -ne 0 ]; then
    #   AfficherAnomalie"Fonction SelectVarParam : Mot de passe non trouve pour user [$SVP_NOM_USER] "
    #   return $CR_KO
    #fi

    # Afficher le contexte d'execution du script SQL
    # AfficherInfo "Base d'execution  : [${ORACLE_SID}]"
    # AfficherInfo "Schema utilise    : [${SVP_NOM_BASE}]"
    # AfficherInfo "Requete	     : [${SVP_REQ}]"
    # AfficherInfo "Nom recuperation  : [${SVP_REC}]"
    # AfficherInfo "Parametres script : [${SVP_PARAM}]"

    # Executer le script
    # AfficherInfo "Debut du script PL/SQL : $(date)"

    # echo ". DTCEXETRTSQL01.ksh"
    # echo "    -mode select_query"
    # echo "    -q ${SVP_REQ} "
    # echo "    -u ${SVP_NOM_USER} "
    # echo "    -p ${ORAPASS} "
    # echo "     -servername ${ORACLE_SID} "
    # echo "     -sqlcodeEnvvar VAR_CODE "
    # echo "     -msgerrEnvvar VAR_ERREUR "
    # echo "     -nbrowsEnvvar VAR_NB "
    # echo "     -execDurationEnvvar VAR_TIME "
    # echo "     -to V "
    # echo "     -out ${SVP_REC} "
    # echo "     -colname N"
    # echo "     -unique Y"
    # echo "     ${SVP_PARAM}"

. DTCEXETRTSQL01.ksh \
-mode select_query \
-q "${SVP_REQ}" \
-u "${SVP_NOM_USER}" \
-servername "${ORACLE_SID}" \
-sqlcodeEnvvar VAR_CODE \
-msgerrEnvvar VAR_ERREUR \
-nbrowsEnvvar VAR_NB \
-execDurationEnvvar VAR_TIME \
-to V \
-out "${SVP_REC}" \
-colname N \
-unique Y \
${SVP_PARAM} >> /dev/null

     if [ ${VAR_CODE} = "SANS" ]; then
    SVP_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     SVP_CR_SCRIPT="204"
	else
	SVP_CR_SCRIPT="0"
    	fi
    fi

     # echo " VAR_CODE : ${VAR_CODE}"
     # echo " VAR_ERREUR : ${VAR_ERREUR} "
     # echo " VAR_NB : ${VAR_NB} "
     # echo " VAR_TIME : ${VAR_TIME} "


    # AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$SVP_CR_SCRIPT)"

    # Restaurer la base de donnee courante initiale
    #export ORACLE_SID="$RC_ORACLE_SID_OLD"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # retourner le resultat du traitement
    return "$SVP_CR_SCRIPT"
}


#---------------------------------------------------------------------------
# Fonction SelectVarFichier <Nom base> <Nom User> <Nom fichier entree> <Nom reception> <PARAMETRE_optionnel>
#---------------------------------------------------------------------------
    # <CREA> RLE - 27/04/2009 - 1.00

function SelectVarFichier
{
    # Controler les parametre
    if [ $# -lt 4 ]; then
        AfficherAnomalie "Fonction SelectVarFichier : parametre manquant"
        AfficherAnomalie "Usage : SelectVarFichier <Nom base> <Nom User> <Nom fichier entree> <Nom reception> <PARAMETRE_optionnel>"
        return $CR_KO
    fi

    # Memoriser les Paramètres
    SVF_NOM_BASE="$1"
    SVF_NOM_USER="$2"
    SVF_FIC="$3"
    SVF_REC="$4"
    shift 4
    SVF_PARAM="$*"

    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    #ORACLE_SID_OLD="$ORACLE_SID"
    export ORACLE_SID="$SVF_NOM_BASE"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    #ORAPASS=$(PC_PASSWD_INSORA $ORACLE_SID $SVF_NOM_USER)
    #if [ $? -ne 0 ]; then
    #   AfficherAnomalie"Fonction SelectVarFichier : Mot de passe non trouve pour user [$SVF_NOM_USER] "
    #   return $CR_KO
    #fi


    # Afficher le contexte d'execution du script
    AfficherInfo "Base d'execution  : [${ORACLE_SID}]"
    AfficherInfo "Schema utilise    : [${SVF_NOM_BASE}]"
    AfficherInfo "Fichier entrée    : [${SVF_FIC}]"
    AfficherInfo "Mom recuperation  : [${SVF_REC}]"
    AfficherInfo "Paramètres script : [${SVF_PARAM}]"

    # Executer le script
    AfficherInfo "Debut du script PL/SQL : $(date)"

    #echo ". DTCEXETRTSQL01.ksh"
    #echo "    -mode select_query"
    #echo "    -qf ${SVF_FIC} "
    #echo "    -u ${SVF_NOM_USER} "
    #echo "    -p ${SVF_NOM_USER} "
    #echo "     -servername ${ORACLE_SID} "
    #echo "     -sqlcodeEnvvar VAR_CODE "
    #echo "     -msgerrEnvvar VAR_ERREUR "
    #echo "     -nbrowsEnvvar VAR_NB "
    #echo "     -execDurationEnvvar VAR_TIME "
    #echo "     -to V "
    #echo "     -out ${SVF_REC} "
    #echo "     -colname N"
    #echo "     -unique Y"
    #echo "     ${SVF_PARAM}"

. DTCEXETRTSQL01.ksh \
-mode select_query \
-qf "${SVF_FIC}" \
-u "${SVF_NOM_USER}" \
-servername "${ORACLE_SID}" \
-sqlcodeEnvvar VAR_CODE \
-msgerrEnvvar VAR_ERREUR \
-nbrowsEnvvar VAR_NB \
-execDurationEnvvar VAR_TIME \
-to V \
-out "${SVF_REC}" \
-colname N \
-unique Y \
"${SVF_PARAM}" >> /dev/null

     if [ ${VAR_CODE} = "SANS" ]; then
    SVF_CR_SCRIPT="202"
    else
     if [ ${VAR_CODE} != "0" ]; then
     SVF_CR_SCRIPT="204"
	else
	SVF_CR_SCRIPT="0"
    	fi
    fi

    #echo " VAR_CODE : ${VAR_CODE}"
    #echo " VAR_ERREUR : ${VAR_ERREUR} "
    #echo " VAR_NB : ${VAR_NB} "
    #echo " VAR_TIME : ${VAR_TIME} "


    AfficherInfo "Fin du script PL/SQL : $(date) (Code retour=$SVF_CR_SCRIPT)"

    # Restaurer la base de donnee courante initiale
    #export ORACLE_SID="$RC_ORACLE_SID_OLD"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # retourner le resultat du traitement
    return "$SVF_CR_SCRIPT"
}

#---------------------------------------------------------------------------
# Fonction GetDebNomTInfo <Nom de la chaine>
#---------------------------------------------------------------------------
function GetDebNomTInfo
{
    # Controler les parametres
    if [ $# -ne 1 ]; then
        AfficherAnomalie "Fonction GetDebNomFichierInfo : parametre manquant"
        AfficherAnomalie "Usage : GetDebNomFichierInfo <Nom du traitement>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GDNTI_NOM_CHAINE="$1"

    # Afficher le debut du nom du fichier INFO = nom de la chaine en parametre
    printf "$GDNTI_NOM_CHAINE"

    # Retourner le succes du traitement
    return $CR_OK
}

#--------------------------------------------------------------------------------
# Fonction MajTInfo <Nom de la chaine> <Nom du parametre> <Valeur du parametre> <Nom base> <nom user>
#--------------------------------------------------------------------------------
function MajTInfo
{

    # Controler les parametres
    if [ $# -ne 5 ]; then
        AfficherAnomalie "Fonction MajTInfo : parametre manquant"
        AfficherAnomalie "Usage : MajTInfo <Nom de la chaine> <Nom du parametre> <Valeur du parametre> <Nom base> <nom user> "
        return $CR_KO
    fi

    # Memoriser les parametres
    MTI_NOM_CHAINE="$1"
    MTI_NOM_PARAM="$2"
    MTI_VAL_PARAM="$3"
    MTI_NOM_BASE="$4"
    MTI_NOM_USER="$5"
    MTI_CHAINE="$6"

    # Positionner la base de donnee indiquee en parametre
    # comme base de donnee courante
    #ORACLE_SID_OLD="$ORACLE_SID"
    export ORACLE_SID="$MTI_NOM_BASE"
    #eval $(PC_ENV_INSORA "$ORACLE_SID")

    # Recherche du parametre dans le fichier INFO
    SelectVarParam ${MTI_NOM_BASE}  ${MTI_NOM_USER} "select VALEUR from T_INFO where SCRIPT_APP='${MTI_NOM_CHAINE}' and CRITERE='${MTI_NOM_PARAM}'" "MTI_VAL_PARAM_OLD"

	echo "Ancienne valeur : ${MTI_VAL_PARAM_OLD}"

	# Fixer le nom du fichier de script anonyme PL/SQL a lancer
    # pour executer une requete
	FIC_SQL="${DBORA_APPLI}/sql/req_${MTI_NOM_CHAINE}.tmp.$(date +'%s').sql"

    if [ "${MTI_VAL_PARAM_OLD}" != " " ]; then
        # s'il existe on le met à jour
       #REQ_SQL="\"update T_INFO set VALEUR=''$MTI_VAL_PARAM'' where SCRIPT_APP=''${MTI_NOM_CHAINE}'' and CRITERE=''$MTI_NOM_PARAM''\""
       echo "update T_INFO set VALEUR='$MTI_VAL_PARAM' where SCRIPT_APP='${MTI_NOM_CHAINE}' and CRITERE='$MTI_NOM_PARAM';"
       echo "update T_INFO set VALEUR='$MTI_VAL_PARAM' where SCRIPT_APP='${MTI_NOM_CHAINE}' and CRITERE='$MTI_NOM_PARAM';">>$FIC_SQL
    else
        # sinon on l'ajoute à la fin du fichier
	#REQ_SQL="\"insert into T_INFO values(''${MTI_NOM_CHAINE}'',''$MTI_NOM_PARAM'', ''$MTI_VAL_PARAM'')\""
	echo "insert into T_INFO values('${MTI_NOM_CHAINE}','$MTI_NOM_PARAM', '$MTI_VAL_PARAM');"
       	echo "insert into T_INFO values('${MTI_NOM_CHAINE}','$MTI_NOM_PARAM', '$MTI_VAL_PARAM');">>$FIC_SQL
    fi

	ExecScriptSQL "${MTI_NOM_BASE}" "${MTI_NOM_USER}" "$FIC_SQL" ""
	if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction MajTInfo : Erreur lors de l'execution du script SQL "
        return $CR_KO
    fi
	rm $FIC_SQL
    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction SupprimerTInfo <Nom de la chaine> <Nom base> <nom user>
#---------------------------------------------------------------------------
function SupprimerTInfo
{
    # Controler les parametres
    if [ $# -ne 3 ]; then
        AfficherAnomalie "Fonction SupprimerTInfo : parametre manquant"
        AfficherAnomalie "Usage : SupprimerTInfo <Nom de la chaine> <Nom base> <nom user>"
        return $CR_KO
    fi

    # Memoriser le parametre
    STI_NOM_CHAINE="$1"
    STI_NOM_BASE="$2"
    STI_NOM_USER="$3"

    # Fixer le nom du fichier de script anonyme PL/SQL a lancer
    # pour executer une requete
#	FIC_SQL="${DBORA_APPLI}/sql/req.tmp.`date +%s`.sql"
	FIC_SQL="${DBORA_APPLI}/sql/req_${STI_NOM_CHAINE}.tmp.$(date +'%s').sql"

	echo "delete from T_INFO WHERE SCRIPT_APP='${STI_NOM_CHAINE}';">>"$FIC_SQL"

	ExecScriptSQL "${STI_NOM_BASE}" "${STI_NOM_USER}" "${FIC_SQL}" ""
	if [ $? -ne $CR_OK ]; then
        AfficherAnomalie "Fonction SupprimerTInfo : Erreur lors de l'execution du script SQL "
        return $CR_KO
    fi
	rm $FIC_SQL
    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction LireTInfo <Nom de la chaine> <Nom du parametre> <Nom de la base> <nom user> <variable retour>
#---------------------------------------------------------------------------
function LireTInfo
{

    # Controler les parametres
    if [ $# -ne 5 ]; then
        AfficherAnomalie "Fonction LireTInfo : parametre manquant"
        AfficherAnomalie "Usage : LireTInfo <Nom de la chaine> <Nom du parametre> <Chaine de connexion> <nom user> <variable retour>"
        return $CR_KO
    fi

    # Memoriser les parametres
    LTI_NOM_CHAINE="$1"
    LTI_NOM_PARAM="$2"
    LTI_NOM_BASE="$3"
    LTI_NOM_USER="$4"
    LTI_VAR_PARAM="$5"
    # Lire le parametre du fichier INFO

SelectVarParam "${LTI_NOM_BASE}" "${LTI_NOM_USER}" "select VALEUR from T_INFO where SCRIPT_APP='${LTI_NOM_CHAINE}' and CRITERE='${LTI_NOM_PARAM}'" "LTI_VAL_PARAM"

eval "$LTI_VAR_PARAM=\$LTI_VAL_PARAM"

    if [ -z "${LTI_VAL_PARAM}" ]; then
        AfficherAnomalie "Fonction LireTInfo : Pas de paramètre trouvé"
        return $CR_KO
    fi

    # Afficher l'identifiant de declenchement
    #echo "Valeur du paramètre : $LTI_VAL_PARAM"
    #printf "$LTI_VAL_PARAM"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetIdDeclenchementTable <Nom de la chaine> <Nom base> <nom user> <variable retour>
#---------------------------------------------------------------------------
function GetIdDeclenchementTable
{
    # Controler les parametres
    if [ $# -ne 4 ]; then
        AfficherAnomalie "Fonction GetIdDeclenchementTable : parametre manquant"
        AfficherAnomalie "Usage : GetIdDeclenchementTable <Nom du traitement> <Nom base> <nom user> <variable retour>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GIDT_NOM_CHAINE="$1"
    GIDT_NOM_BASE="$2"
    GIDT_NOM_USER="$3"
    GIDT_NOM_DECLENCH="$4"

   SelectVarParam "${GIDT_NOM_BASE}" "${GIDT_NOM_USER}" "select id_dec from V_DTC_DECLENCHEMENT D,V_DTC_TRAITEMENT T where D.id_traitement = T.id_traitement and dt_fin IS NULL and ROWNUM = 1 and txt_script_traitement = '${GIDT_NOM_CHAINE}' and cd_statut = 'WT' order by id_dec " "GIDT_NUM_DECLENCH"

    if [ -z "${GIDT_NUM_DECLENCH}" ]; then
        AfficherAnomalie "Fonction GetIdDeclenchementTable : Pas de déclenchement trouvé"
        return $CR_KO
    fi

eval "$GIDT_NOM_DECLENCH=$GIDT_NUM_DECLENCH"

    # Afficher l'identifiant de declenchement
    #printf "$GIDT_NUM_DECLENCH"

    # Retourner le succes du traitement
    return $CR_OK
}

#---------------------------------------------------------------------------
# Fonction GetIdDeclenchementEncoursTable <Nom de la chaine> <Nom base> <nom user> <variable retour>
#---------------------------------------------------------------------------
function GetIdDeclenchementEncoursTable
{
    # Controler les parametres
    if [ $# -ne 4 ]; then
        AfficherAnomalie "Fonction GetIdDeclenchementEncoursTable : parametre manquant"
        AfficherAnomalie "Usage : GetIdDeclenchementEncoursTable <Nom du traitement> <Nom base> <nom user> <variable retour>"
        return $CR_KO
    fi

    # Memoriser le parametre
    GIDET_NOM_CHAINE="$1"
    GIDET_NOM_BASE="$2"
    GIDET_NOM_USER="$3"
    GIDET_NOM_DECLENCH="$4"

	echo "select id_dec from V_DTC_DECLENCHEMENT D,V_DTC_TRAITEMENT T where D.id_traitement = T.id_traitement and dt_fin is null and ROWNUM = 1 and txt_script_traitement = '${GIDET_NOM_CHAINE}' and cd_statut = 'EX' order by id_dec"

   SelectVarParam "$GIDET_NOM_BASE" "$GIDET_NOM_USER" "select id_dec from V_DTC_DECLENCHEMENT D,V_DTC_TRAITEMENT T where D.id_traitement = T.id_traitement and dt_fin is null and ROWNUM = 1 and txt_script_traitement = '${GIDET_NOM_CHAINE}' and cd_statut = 'EX' order by id_dec" "GIDET_NUM_DECLENCH"

    if [ -z "${GIDET_NUM_DECLENCH}" ]; then
        AfficherAnomalie "Fonction GetIdDeclenchementEncoursTable : Pas de déclenchement trouvé"
        return $CR_KO
    fi

eval "$GIDET_NOM_DECLENCH=$GIDET_NUM_DECLENCH"

    # Afficher l'identifiant de declenchement
    #printf "$GIDET_NUM_DECLENCH"

    # Retourner le succes du traitement
    return $CR_OK
}
