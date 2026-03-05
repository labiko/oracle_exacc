create or replace PACKAGE BODY Pkg_Tec_Fichiers AS

-- ***********************************************************************
-- # PACKAGE      : PKG_TEC_FICHIERS
-- # DESCRIPTION  : Gestion de l'acces aux fichiers externes à la base
-- #                et déposés sur le filesystem unix
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 17/04/2006 |           | PDI    | Creation
-- # 1.1     | 13/08/2007 |           | DVA    | Ajout de la gestion des directories
-- #         |            |           |        | des directories par code appli
-- # 1.2     | 27/06/2008 |           | FAU    | pROCEDURE RENOMMAGE DE FICHIER
-- # 1.3     | 29/04/2009 |	      | RLE    | Ajout procédure CLOB
-- ***********************************************************************

-- =======================================================================
-- DECLARATION DES CONTANTES
-- =======================================================================

-- Nom du package
gs_PACKAGE CONSTANT VARCHAR2(25):='PKG_TEC_FICHIERS';

-- Taille maxi d'une ligne de fichier
gi_MAX_LINE_SIZE CONSTANT INTEGER:=4000;

-- =======================================================================
-- DECLARATION DES VARIABLES GLOBALES
-- =======================================================================

-- =======================================================================
-- # PROCEDURE    : F_EXISTE_DIR
-- # DESCRIPTION  : Verifier l'existence d'un directory Oracle
-- # PARAMETRES   :
-- #   + t_InfoTrait  : informations du traitement
-- #   + s_DirComplet : Nom complet de l'objet directory oracle recherché
-- #   + b_Existe     : booléen : 1=Vrai, 0=Faux
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 13/08/2007 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_EXISTE_DIR(
                      t_InfoTrait  IN         Pkg_Global.T_INFO_TRAITEMENT,
                      s_DirComplet IN         VARCHAR2,
                      b_Existe     OUT NOCOPY NUMBER
                     )
                     RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_EXISTE_DIR';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

BEGIN

    -- -------------------------------------------------------------------
    -- VERIFIER LES PARAMETRES
    -- -------------------------------------------------------------------

    -- Si le directory recherché n'est pas renseigné
    IF trim(s_DirComplet) IS NULL THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : DIRECTORY RECHERCHE NON RENSEIGNE. ' ||
                         'IMPOSSIBLE DE VERIFIER SON EXISTENCE !',
                         1,
                         s_FONCTION);
        RETURN 1;
    END IF;

    -- -------------------------------------------------------------------
    -- RECHERCHER L'EXISTENCE DU DIRECTORY
    -- -------------------------------------------------------------------

    -- Initialiser l'indicateur a FAUX
    b_Existe:=0;

    -- Rechercher l'existence du directory
    SELECT
        COUNT(*)
    INTO
        b_Existe
    FROM
        ALL_DIRECTORIES
    WHERE
        DIRECTORY_NAME=UPPER(trim(s_DirComplet))
    ;

    -- Retourner le succes du traitement
    RETURN Pkg_Global.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gérées
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;

END F_EXISTE_DIR;


-- =======================================================================
-- # PROCEDURE    : F_GET_DIR_UNIX_PATH_FROM_DIR
-- # DESCRIPTION  : Lire le chemin unix correspondant à un objet directory oracle
-- # PARAMETRES   :
-- #   + t_InfoTrait   : informations du traitement
-- #   + s_DirComplet  : Nom complet de l'objet directory oracle
-- #   + s_DirUnixPath : chemin unix complet correspondant au directory
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 13/08/2007 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_UNIX_PATH_FROM_DIR(
                                  t_InfoTrait   IN         Pkg_Global.T_INFO_TRAITEMENT,
                                  s_DirComplet  IN         VARCHAR2,
                                  s_DirUnixPath OUT NOCOPY VARCHAR2
                                 )
                                 RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_UNIX_PATH_FROM_DIR';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

BEGIN

    -- -------------------------------------------------------------------
    -- VERIFIER LES PARAMETRES
    -- -------------------------------------------------------------------

    -- Si le directory recherché n'est pas renseigné
    IF trim(s_DirComplet) IS NULL THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : LE DIRECTORY DONT ON RECHERCHE ' ||
                         'LE CHEMIN UNIX N''EST PAS RENSEIGNE !',
                         1,
                         s_FONCTION);
        RETURN 1;
    END IF;

    -- -------------------------------------------------------------------
    -- RECHERCHER LE CHEMIN UNIX DU DIRECTORY
    -- -------------------------------------------------------------------

    -- Initialiser le chemin recherché à vide
    s_DirUnixPath:='';

    -- Rechercher l'existence du directory
    SELECT
        DIRECTORY_PATH
    INTO
        s_DirUnixPath
    FROM
        ALL_DIRECTORIES
    WHERE
        DIRECTORY_NAME=s_DirComplet
    ;

    -- Retourner le succes du traitement
    RETURN Pkg_Global.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------
    WHEN NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : LE DIRECTORY ['||s_DirComplet||'] ' ||
                         'DONT ON RECHERCHE LE CHEMIN UNIX N''EXISTE PAS !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    -- Erreurs non gérées
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;

END F_GET_UNIX_PATH_FROM_DIR;

-- =======================================================================
-- # PROCEDURE    : F_GET_DIR_FROM_UNIX_PATH
-- # DESCRIPTION  : Lire l'objet directory oracle correspondant à un chemin unix
-- # PARAMETRES   :
-- #   + t_InfoTrait   : informations du traitement
-- #   + s_DirComplet  : Nom complet de l'objet directory oracle
-- #   + s_DirUnixPath : chemin unix complet correspondant au directory
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 20/08/2007 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_GET_DIR_FROM_UNIX_PATH(
                                  t_InfoTrait   IN         Pkg_Global.T_INFO_TRAITEMENT,
                                  s_DirUnixPath IN         VARCHAR2,
                                  s_DirComplet  OUT NOCOPY VARCHAR2
                                 )
                                 RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_DIR_FROM_UNIX_PATH';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

BEGIN

    -- -------------------------------------------------------------------
    -- VERIFIER LES PARAMETRES
    -- -------------------------------------------------------------------

    -- Si le chemin recherché n'est pas renseigné
    IF trim(s_DirUnixPath) IS NULL THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : LE CHEMIN UNIX DONT ON RECHERCHE ' ||
                         'LE DIRECTORY N''EST PAS RENSEIGNE !',
                         1,
                         s_FONCTION);
        RETURN 1;
    END IF;

    -- -------------------------------------------------------------------
    -- RECHERCHER LE CHEMIN UNIX DU DIRECTORY
    -- -------------------------------------------------------------------

    -- Initialiser le directory recherché à vide
    s_DirComplet:='';

    -- Rechercher l'existence du directory
    -- Remarque : si plusieurs directories correspondent au chemin unix,
    -- on prend le premier ramené
    SELECT
        DIRECTORY_NAME
    INTO
        s_DirComplet
    FROM
        ALL_DIRECTORIES
    WHERE
        UPPER(DIRECTORY_PATH)=s_DirUnixPath
    AND ROWNUM = 1
    ORDER BY
        DIRECTORY_NAME ASC
    ;

    -- Retourner le succes du traitement
    RETURN Pkg_Global.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------
    WHEN NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : IL N''EXISTE PAS DE DIRECTORY ' ||
                         'POUR LE CHEMIN UNIX ['||s_DirUnixPath||'] !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    -- Erreurs non gérées
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;

END F_GET_DIR_FROM_UNIX_PATH;

-- =======================================================================
-- # PROCEDURE    : F_GET_DIR
-- # DESCRIPTION  : Construire le nom complet de l'objet directory oracle
-- #                a utiliser en fonction du code appli du traitement
-- # PARAMETRES   :
-- #   + t_InfoTrait  : informations du traitement
-- #   + s_DirDemande : Type de répertoire demandé : DIR_TEMP, DIR_IN, DIR_OUT, DIR_LOG
-- #   + s_DirComplet : Nom complet du directory oracle retourné
-- #   + s_DirUnix    : Chemin unix équivalent au directory Oracle
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 03/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_DIR(
                   t_InfoTrait  IN         Pkg_Global.T_INFO_TRAITEMENT,
                   s_DirDemande IN         VARCHAR2,
                   s_DirComplet OUT NOCOPY VARCHAR2,
                   s_DirUnix    OUT NOCOPY VARCHAR2
                  )
                  RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_DIR';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := Pkg_Global.gn_CR_KO;

    -- Code appli
    s_CodeAppli VARCHAR2(3):='';

    -- Indicateur d'existence du directory
    b_Existe NUMBER(1):=0;

BEGIN

    -- -------------------------------------------------------------------
    -- VERIFIER LES PARAMETRES
    -- -------------------------------------------------------------------

    -- Si le directory demandé n'est pas renseigné
    IF trim(s_DirDemande) IS NULL THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : DIRECTORY DEMANDE NON RENSEIGNE. ' ||
                         'IMPOSSIBLE DE DETERMINER LE NOM COMPLET ' ||
                         'DU DIRECTORY !',
                         1,
                         s_FONCTION);
        RETURN 1;
    END IF;

    -- Si le directory demandé ne contient pas la liste de valeurs suivantes :
    -- DIR_TEMP, DIR_IN, DIR_OUT et DIR_LOG
    IF (
           INSTR(s_DirDemande,'DIR_TEMP') = 0
       AND INSTR(s_DirDemande,'DIR_IN')   = 0
       AND INSTR(s_DirDemande,'DIR_OUT')  = 0
       AND INSTR(s_DirDemande,'DIR_LOG')  = 0
       ) THEN

        n_CodeRet:=F_GET_DIR_FROM_UNIX_PATH(
                                           t_InfoTrait,
                                           s_DirDemande,
                                           s_DirComplet
                                           );
        -- En cas d'echec
        IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
           Pkg_Log.P_ECRIRE(t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : IMPOSSIBLE DE DETERMINER ' ||
                            'LE DIRECTORY A PARTIR DU CHEMIN UNIX !',
                            4,
                            s_FONCTION);
           RETURN 4;
        END IF;

        IF (
           INSTR(s_DirComplet,'DIR_TEMP') = 0
       AND INSTR(s_DirComplet,'DIR_IN')   = 0
       AND INSTR(s_DirComplet,'DIR_OUT')  = 0
       AND INSTR(s_DirComplet,'DIR_LOG')  = 0
       ) THEN

             Pkg_Log.P_ECRIRE(t_InfoTrait,
                              Pkg_Log.gt_LOG_TYPE_ERR,
                              'ERREUR : DIRECTORY DEMANDE ' ||
                              '['||s_DirDemande||'] INCORRECT. ' ||
                              'IL NE CONTIENT PAS LES VALEURS SUIVANTES : ' ||
                              'DIR_TEMP, DIR_IN, DIR_OUT, DIR_LOG. ' ||
                              'IMPOSSIBLE DE DETERMINER LE NOM COMPLET ' ||
                              'DU DIRECTORY !',
                              2,
                              s_FONCTION);
             RETURN 2;
        ELSE
            RETURN Pkg_Global.gn_CR_OK;
        END IF;
    END IF;


    -- -------------------------------------------------------------------
    -- LIRE LE CODE APPLI DU TRAITEMENT EN COURS
    -- -------------------------------------------------------------------

    -- Lire le code appli dans les informations du traitement en cours
    n_CodeRet:=Pkg_Global.F_GET_CODE_APPLI(t_InfoTrait,s_CodeAppli);

    -- En cas d'echec
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : IMPOSSIBLE DE DETERMINER ' ||
                         'LE CODE APPLICATION ET ' ||
                         'DONC LE NOM COMPLET DU DIRECTORY !',
                         3,
                         s_FONCTION);
        RETURN 3;
    END IF;


    -- -------------------------------------------------------------------
    -- CONSTRUIRE LE NOM DU DIRECTORY ET VERIFIER SON EXISTENCE
    -- -------------------------------------------------------------------

    -- Initialiser les variables
    s_DirComplet:='';
    s_DirUnix:='';

    -- Selon le contenu du directory demandé
    -- construire le nom du directory selon le format :
    -- <Racine du nom du directory demande>_<Code appli>
    IF INSTR(s_DirDemande,'DIR_TEMP') <> 0 THEN
        s_DirComplet:='DIR_TEMP_'||UPPER(trim(s_CodeAppli));
    END IF;
    IF  INSTR(s_DirDemande,'DIR_IN')  <> 0 THEN
        s_DirComplet:='DIR_IN_'||UPPER(trim(s_CodeAppli));
    END IF;
    IF INSTR(s_DirDemande,'DIR_OUT')  <> 0 THEN
        s_DirComplet:='DIR_OUT_'||UPPER(trim(s_CodeAppli));
    END IF;
    IF INSTR(s_DirDemande,'DIR_LOG')  <> 0 THEN
        s_DirComplet:='DIR_LOG_'||UPPER(trim(s_CodeAppli));
    END IF;

    -- Vérifier l'existence du directory
    n_CodeRet:=F_EXISTE_DIR(t_InfoTrait,s_DirComplet,b_Existe);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : ECHEC LORS DE LA VERIFICATION ' ||
                         'DE L''EXISTENCE DU DIRECTORY !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

    -- Si le directory n'existe pas : plan B
    -- Ce plan B n'est mis en place qu'à titre temporaire
    IF b_Existe=0 THEN

        -- Se rabbattre sur les objets directory
        -- indépendant du code appli
        IF INSTR(s_DirDemande,'DIR_TEMP') <> 0 THEN
            s_DirComplet:='DIR_TEMP';
        END IF;
        IF  INSTR(s_DirDemande,'DIR_IN')   <> 0 THEN
            s_DirComplet:='DIR_IN';
        END IF;
        IF INSTR(s_DirDemande,'DIR_OUT')  <> 0 THEN
            s_DirComplet:='DIR_OUT';
        END IF;
        IF INSTR(s_DirDemande,'DIR_LOG')  <> 0 THEN
            s_DirComplet:='DIR_LOG';
        END IF;

        -- Vérifier l'existence du directory
        b_Existe:=0;
        n_CodeRet:=F_EXISTE_DIR(t_InfoTrait,s_DirComplet,b_Existe);
        IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait,
                             Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : ECHEC LORS DE LA VERIFICATION ' ||
                             'DE L''EXISTENCE DU DIRECTORY !',
                             Pkg_Global.gn_CR_KO,
                             s_FONCTION);
            RETURN Pkg_Global.gn_CR_KO;
        END IF;

        -- Si le directory n'existe pas non plus : constat d'échec
        IF b_Existe=0 THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait,
                             Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : DIRECTORY INEXISTANT !',
                             Pkg_Global.gn_CR_KO,
                             s_FONCTION);
            RETURN Pkg_Global.gn_CR_KO;
        END IF;

    END IF;

    -- Si un directory existe
    IF b_Existe=1 THEN

        -- Lire le chemin unix correspondant au directory
        n_CodeRet:=F_GET_UNIX_PATH_FROM_DIR(
                                           t_InfoTrait,
                                           s_DirComplet,
                                           s_DirUnix
                                           );
        IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait,
                             Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : ECHEC LORS DE LA LECTURE ' ||
                             'DU CHEMIN UNIX DU DIRECTORY ' ||
                             '['||s_DirComplet||'] !',
                             Pkg_Global.gn_CR_KO,
                             s_FONCTION);
            RETURN Pkg_Global.gn_CR_KO;
        END IF;

    END IF;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN Pkg_Global.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gérées
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;

END F_GET_DIR;



 /******************************************************************************
   NAME:    Fic_Ecrire
   PURPOSE: Ecrit la ligne passée en paramêtre dans le fichier fFic
   PARAMS : fFic    : handle du fichier
            v_Ligne : ligne à écrire
   RETOUR : 0 si OK
            -1 Sinon

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17/04/2006                    1. Created.
******************************************************************************/
 FUNCTION F_ECRIRE_LIGNE(
                        t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                        f_Fic       IN UTL_FILE.FILE_TYPE,
                        s_Ligne     IN VARCHAR2
                        )
                        RETURN INTEGER
IS
 BEGIN
     UTL_FILE.Put_Line(f_Fic, s_Ligne);
     UTL_FILE.FFLUSH(f_Fic);
     RETURN 0;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_Ecrire(t_InfoTrait);
        RETURN -1;

END F_ECRIRE_LIGNE;

 /******************************************************************************
   NAME:    FileExists
   PURPOSE: Vérifier l'existence d'un fichier dans un dossier donné.
            Avant de pouvoir l'utiliser, il vous faut créer un DIRECTORY
   PARAMS : s_FileName : nom du fichier
            Dir :        nom du directory

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/06/2006                    1. Created.
 ******************************************************************************/
FUNCTION F_FileExists(
                     s_FileName VARCHAR2,
                     s_Dir VARCHAR2
                     )
                     RETURN VARCHAR2
AS
    b_exists    BOOLEAN;
    n_length    NUMBER;
    n_blocksize NUMBER;

BEGIN

    UTL_FILE.FGETATTR(s_Dir, s_FileName, b_exists, n_length, n_blocksize);
    IF b_exists THEN
       RETURN 'TRUE';
    ELSE
       RETURN 'FALSE';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_AFFICHER(
                          'ERREUR : ' || SQLERRM || ' - ' ||
                          'IMPOSSIBLE DE DETERMINER L''EXISTENCE DU FICHIER '||
                          '['||s_Dir||'/'||s_FileName||']'
                          );
        RETURN 'FALSE';
END F_FileExists;

 /******************************************************************************
   NAME:    FileExists
   PURPOSE: Vérifier l'existence d'un fichier dans un dossier donné.
            Avant de pouvoir l'utiliser, il vous faut créer un DIRECTORY
   PARAMS : s_FileName : nom du fichier
            Dir :        nom du directory

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        16/06/2007  DVA               Création
 ******************************************************************************/
FUNCTION F_FileExists(
                      t_InfoTrait  IN         Pkg_Global.T_INFO_TRAITEMENT,
                      s_FileName   IN         VARCHAR2,
                      s_Dir        IN         VARCHAR2
                     )
                     RETURN VARCHAR2
AS
    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_FileExists';

    b_exists    BOOLEAN;
    n_length    NUMBER;
    n_blocksize NUMBER;

    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_DirComplet    VARCHAR2(30):='';
    s_DirUnix       VARCHAR2(255):='';

BEGIN

    -- Construire le nom complet de l'objet directory
    -- qui va permettre l'acces au filesystem unix
    -- (le nom de l'objet directory est fonction du code appli)
    n_CodeRet:=F_GET_DIR(t_InfoTrait,s_Dir,s_DirComplet,s_DirUnix);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'ERREUR : IMPOSSIBLE DE RECUPERER ' ||
                         'LE DIRECTORY ORACLE CORRESPONDANT A ' ||
                         ' ['||s_Dir||'] !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

    -- Tester l'existence du fichier par tentative de lecture de ses attributs
    UTL_FILE.FGETATTR(
                     s_DirComplet,
                     trim(s_FileName),
                     b_exists,
                     n_length,
                     n_blocksize
                     );
    IF b_exists THEN
       RETURN 'TRUE';
    ELSE
       RETURN 'FALSE';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_Ecrire(t_InfoTrait);
        Pkg_Log.P_ECRIRE(
                        t_InfoTrait,
                        Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : IMPOSSIBLE DE DETERMINER ' ||
                        'L''EXISTENCE DU FICHIER '||
                        '['||s_Dir||'/'||s_FileName||'] !',
                        1,
                        s_FONCTION
                        );
        RETURN 'FALSE';

END F_FileExists;

 /******************************************************************************
   NAME:    FileExists
   PURPOSE: Vérifier l'existence d'un fichier dans un dossier donné.
            Surcharge avec retour taille fichier
   PARAMS : s_FileName : nom du fichier
            Dir :        nom du directory
   JIRA :   FMCPTA-132
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/06/2008   FAU                 1. Created.
 ******************************************************************************/
FUNCTION F_FileExists(
                     s_FileName VARCHAR2,
                     s_Dir VARCHAR2,
                     n_FileLength OUT NUMBER
                     )
                     RETURN VARCHAR2
AS
    b_exists    BOOLEAN;
    n_blocksize NUMBER;

BEGIN
    n_FileLength:=0;
    UTL_FILE.FGETATTR(s_Dir, s_FileName, b_exists, n_FileLength, n_blocksize);
    IF b_exists THEN
       RETURN 'TRUE';
    ELSE
       RETURN 'FALSE';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_AFFICHER(
                          'ERREUR : ' || SQLERRM || ' - ' ||
                          'IMPOSSIBLE DE LIRE LES ATTRIBUTS DU FICHIER '||
                          '['||s_Dir||'/'||s_FileName||']'
                          );
        RETURN 'FALSE';
END F_FileExists;
/******************************************************************************
   NAME:    F_EcrireCsv
   PURPOSE: Ecrit le résultat de la requête passée en paramêtre, dans un
            fichier passé en paramêtre.
   PARAMS : p_query     : requête
            p_separator : format du séparateur dans le fichier
            p_dir       : répertoire de destination du fichier
            p_filename  : nom du fichier

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/08/2006                    1. Created.
   1.1        16/08/2007  DVA                  Gestion de objets DIRECTORY
******************************************************************************/
 FUNCTION F_ECRIRECSV(
                      t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                      p_query     IN VARCHAR2,
                      p_separator IN VARCHAR2 DEFAULT ',',
                      p_dir       IN VARCHAR2,
                      p_filename  IN VARCHAR2,
                      p_mode      IN VARCHAR2 DEFAULT 'w'
                     )
                      RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_ECRIRECSV';

    l_output        UTL_FILE.FILE_TYPE;
    l_theCursor     INTEGER DEFAULT dbms_sql.open_cursor;
    l_columnValue   VARCHAR2(2000);
    l_status        INTEGER;
    l_colCnt        NUMBER DEFAULT 0;
    l_separator     VARCHAR2(10) DEFAULT '';
    l_cnt           NUMBER DEFAULT 0;

    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_DirComplet    VARCHAR2(30):='';
    s_DirUnix       VARCHAR2(255):='';
    s_FileName      VARCHAR2(255):='';

BEGIN

    -- ----------------------------------------------------------------------
    -- AJOUT DVA le 16/08/2007
    -- ----------------------------------------------------------------------

    -- Construire le nom complet de l'objet directory
    -- qui va permettre l'acces au filesystem unix
    -- (le nom de l'objet directory est fonction du code appli)
    n_CodeRet:=F_GET_DIR(t_InfoTrait,p_Dir,s_DirComplet,s_DirUnix);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(
                        t_InfoTrait,
                        Pkg_Log.gt_LOG_TYPE_ORA,
                        'ERREUR : IMPOSSIBLE DE RECUPERER LE DIRECTORY ' ||
                        'ORACLE CORRESPONDANT A ['||p_Dir||'] !',
                        Pkg_Global.gn_CR_KO,
                        s_FONCTION
                        );
        RETURN Pkg_Global.gn_CR_KO;
    END IF;


    -- ----------------------------------------------------------------------
    -- FIN AJOUT DVA le 16/08/2007
    -- ----------------------------------------------------------------------

    -- ----------------------------------------------------------------------
    -- OUVRIR LE FICHIER
    -- ----------------------------------------------------------------------

    -- En mode création de fichier,
    -- renommer le fichier avec un # devant afin d'éviter
    -- qu'il ne soit exploité par un filewatcher par exemple
    -- alors que sa création n'est pas complète.
    IF UPPER(p_mode) = 'W' THEN
        s_FileName:='#'||trim(p_filename);
    ELSE
        s_FileName:=trim(p_filename);
    END IF;

    -- Créer le fichier
    n_CodeRet:=F_OUVRIR_FICHIER(
                               t_InfoTrait,
                               p_dir,
                               s_FileName,
                               p_mode,
                               gi_MAX_LINE_SIZE,
                               l_output
                               );
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

/*
    <<Ouverture_fichier>>
    BEGIN

        -- Ouverture du fichier
        l_output := utl_file.fopen(
                                  s_DirComplet,
                                  s_FileName,
                                  p_mode,
                                  gi_MAX_LINE_SIZE
                                  );
    EXCEPTION
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=PKG_GLOBAL.gn_CR_KO;
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC OUVERTURE FICHIER ' ||
                            '['||s_DirComplet||'/'||'#'||p_filename||']' ||
                            '(Mode : ['||p_mode||'] - ' ||
                            'Taille max ligne : '||
                            '['||to_char(gi_MAX_LINE_SIZE)||'])',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Ouverture_fichier;
*/

    -- ----------------------------------------------------------------------
    -- LIRE LES DONNEES POUR ALIMENTER LE FICHIER
    -- ----------------------------------------------------------------------

    <<Construire_curseur>>
    BEGIN
        -- Construire le curseur
        dbms_sql.parse(  l_theCursor, p_query, dbms_sql.native );
        FOR i IN 1 .. 255 LOOP
            BEGIN
                dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
                l_colCnt := i;
            EXCEPTION
                WHEN OTHERS THEN
                    IF ( SQLCODE = -1007 ) THEN EXIT;
                    ELSE
                        RAISE;
                    END IF;
            END;
        END LOOP;
        dbms_sql.define_column( l_theCursor, 1, l_columnValue, 4000 );
    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC CONSTRUCTION CURSEUR ' ||
                            'DE LECTURE DES INFORMATIONS A EXPORTER ' ||
                            'DANS LE FICHIER CSV !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Construire_curseur;

    <<Ouvrir_curseur>>
    BEGIN
        -- Ouvrir le curseur
        l_status := dbms_sql.EXECUTE(l_theCursor);
    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC REQUETE DE ' ||
                            'DE LECTURE DES INFORMATIONS A EXPORTER ' ||
                            'DANS LE FICHIER CSV !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Ouvrir_curseur;

    <<Parcourir_curseur>>
    BEGIN

        -- Parcourir le curseur et alimenter le fichier
        LOOP

            EXIT WHEN ( dbms_sql.fetch_rows(l_theCursor) <= 0 );

            l_separator := '';
            FOR i IN 1 .. l_colCnt LOOP

                dbms_sql.column_value( l_theCursor, i, l_columnValue );

                <<Ecrire_fichier>>
                BEGIN
                    utl_file.put( l_output, l_separator || l_columnValue );
                EXCEPTION
                    WHEN  OTHERS THEN
                        Pkg_Log.P_ECRIRE(t_InfoTrait);
                        n_CodeRet:=Pkg_Global.gn_CR_KO;
                        Pkg_Log.P_ECRIRE(
                                        t_InfoTrait,
                                        Pkg_Log.gt_LOG_TYPE_ERR,
                                        'ERREUR : ' ||
                                        'ECHEC ECRITURE INFORMATIONS ' ||
                                        'DANS LE FICHIER CSV ! ' ||
                                        '(INFO A ECRIRE : ' ||
                                        '['||l_separator||l_columnValue||'])',
                                        n_CodeRet,
                                        s_FONCTION
                                        );
                        RETURN n_CodeRet;
                END Ecrire_fichier;

                l_separator := p_separator;
            END LOOP;

            utl_file.new_line( l_output );
            l_cnt := l_cnt+1;

        END LOOP;

    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ' ||
                            'ECHEC LECTURE DES INFORMATIONS A EXPORTER ' ||
                            'DANS LE FICHIER CSV !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Parcourir_curseur;

    <<Fermer_curseur>>
    BEGIN
        -- Fermer le curseur
        dbms_sql.close_cursor(l_theCursor);
    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC FERMETURE DU CURSEUR ' ||
                            'DE LECTURE DES INFORMATIONS A EXPORTER ' ||
                            'DANS LE FICHIER CSV !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Fermer_curseur;

    <<Forcer_ecriture>>
    BEGIN
        -- Forcer l'écriture du fichier sur le disque
        utl_file.fflush(l_output);
    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC ECRITURE FICHIER CSV ' ||
                            'SUR LE DISQUE (FFLUSH) !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Forcer_ecriture;

    <<Fermer_fichier>>
    BEGIN
        -- Fermer le fichier
        utl_file.fclose( l_output );
    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC FERMETURE FICHIER CSV !' ,
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Fermer_fichier;

    -- En mode Ecriture
    IF UPPER(p_mode) = 'W' THEN

        <<Renommer_fichier>>
        BEGIN
            -- On renomme le fichier avec le nom attendu en sortie
            utl_file.frename(
                            s_DirComplet,
                            s_Filename,
                            s_DirComplet,
                            p_Filename,
                            TRUE
                            );
        EXCEPTION
            WHEN  OTHERS THEN
                Pkg_Log.P_ECRIRE(t_InfoTrait);
                n_CodeRet:=Pkg_Global.gn_CR_KO;
                Pkg_Log.P_ECRIRE(
                                t_InfoTrait,
                                Pkg_Log.gt_LOG_TYPE_ERR,
                                'ERREUR : ECHEC RENOMMAGE FICHIER CSV '||
                                'DE ['||s_DirComplet||'/'||s_Filename||'] '||
                                'VERS ['||s_DirComplet||'/'||p_Filename||'] !',
                                n_CodeRet,
                                s_FONCTION
                                );
                RETURN n_CodeRet;
        END Renommer_fichier;

    END IF;

    -- Retourner le succés du traitement
    RETURN Pkg_Global.GN_CR_OK;

EXCEPTION
    WHEN  OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        n_CodeRet:=Pkg_Global.gn_CR_KO;
        Pkg_Log.P_ECRIRE(
                        t_InfoTrait,
                        Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : ECHEC EXPORT FICHIER CSV '||
                        '['||s_DirComplet||'/'||p_Filename||'] !',
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN n_CodeRet;

END F_EcrireCsv;

/******************************************************************************
   NAME:    F_ECRIRE_FICHIER
   PURPOSE: Ecrit le contenu de la valeur passée en paramêtre, dans un
            fichier passé en paramêtre.
   PARAMS : t_InfoTrait : Informations générales sur le traitement en cours
            s_FileName  : nom du fichier
            s_Dir       : répertoire de destination du fichier
            s_Texte     : texte à écrire dans le fichier

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/11/2006  JHI                  1. Created.
   1.1        16/08/2007  DVA                  Gestion de objets DIRECTORY
******************************************************************************/
FUNCTION F_ECRIRE_FICHIER(
                          t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                          s_FileName  IN VARCHAR2,
                          s_Dir       IN VARCHAR2,
                          s_Texte     IN VARCHAR2,
                          s_mode      IN VARCHAR2 DEFAULT 'w'
                         )
                          RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_ECRIRE_FICHIER';

    l_output        UTL_FILE.FILE_TYPE;

    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_DirComplet    VARCHAR2(30):='';
    s_DirUnix       VARCHAR2(255):='';

BEGIN

    -- ----------------------------------------------------------------------
    -- AJOUT DVA le 16/08/2007
    -- ----------------------------------------------------------------------

    -- Construire le nom complet de l'objet directory
    -- qui va permettre l'acces au filesystem unix
    -- (le nom de l'objet directory est fonction du code appli)
    n_CodeRet:=F_GET_DIR(t_InfoTrait,s_Dir,s_DirComplet,s_DirUnix);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'ERREUR : IMPOSSIBLE DE GENERER ' ||
                         'LE FICHIER ['||s_FileName||'] !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    END IF;
    -- ----------------------------------------------------------------------
    -- FIN AJOUT DVA le 16/08/2007
    -- ----------------------------------------------------------------------

    IF UPPER(s_mode) = 'W' THEN
        l_output := UTL_FILE.FOPEN(
                                  s_DirComplet,
                                  '#'||s_FileName,
                                  s_mode,
                                  gi_MAX_LINE_SIZE
                                  );
    ELSE
        l_output := UTL_FILE.FOPEN(
                                  s_DirComplet,
                                  s_FileName,
                                  s_mode,
                                  gi_MAX_LINE_SIZE
                                  );
    END IF;

    -- Ecrire le texte dans le fichier
    UTL_FILE.PUT(l_output, s_Texte);

    -- Forcer l'écriture du fichier sur le disque
    UTL_FILE.FFLUSH(l_output);

    -- Fermer le fichier
    UTL_FILE.FCLOSE(l_output);

    IF UPPER(s_mode) = 'W' THEN
        -- On renomme le fichier avec le nom attendu en sortie
        UTL_FILE.FRENAME(
                        s_DirComplet,
                        '#'||s_FileName,
                        s_DirComplet,
                        s_FileName,
                        TRUE
                        );
    END IF;

    -- Retourner le succés du traitement
    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN  UTL_FILE.INVALID_PATH THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'CHEMIN INCORRECT',
                         1,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  UTL_FILE.INVALID_MODE THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'MODE INVALIDE',
                         2,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  UTL_FILE.INVALID_OPERATION THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'OPERATION INVALIDE',
                         3,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  UTL_FILE.INVALID_FILEHANDLE THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'FICHIER INVALIDE',
                         4,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  UTL_FILE.WRITE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'ERREUR D''ECRITURE',
                         5,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  UTL_FILE.INTERNAL_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'INTERNAL ERROR',
                         6,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'PAS DE DONNEES TROUVEES',
                         7,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  VALUE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'VALUE ERROR',
                         8,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;

END F_ECRIRE_FICHIER;

/******************************************************************************
   NAME:    F_MAJ_LIGNE_FIC
   PURPOSE: Remplace une ligne dans un fichier par une nouvelle ligne
   PARAMS : t_InfoTrait      : Informations générales sur le traitement en cours
            s_AncienneLigne  : Ligne à remplacer
            s_NouvelleLigne  : Nouvelle valeur
            s_NomFic         : nom du fichier
            s_RepFic         : répertoire du fichier

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        09/01/2007  JHI                  1. Created.
******************************************************************************/
FUNCTION F_MAJ_LIGNE_FIC(
                         t_InfoTrait     IN Pkg_Global.T_INFO_TRAITEMENT,
                         s_AncienneLigne IN VARCHAR2,
                         s_NouvelleLigne IN VARCHAR2,
                         s_NomFic        IN VARCHAR2,
                         s_RepFic        IN VARCHAR2
                        )
                         RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_MAJ_LIGNE_FIC';

    -- Pointeurs de fichier
    l_FichierIn   UTL_FILE.FILE_TYPE;
    l_FichierOut   UTL_FILE.FILE_TYPE;

    -- Tampon de travail
    s_Ligne VARCHAR2(4000);

    -- Nom du fichier INFO
    s_NomTemp VARCHAR2(64):='#'||s_NomFic||'_temp';

    -- Code retour
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;

    -- Nom complet du directory
    s_DirComplet    VARCHAR2(30):='';

    -- Chemin unix correspondant au directory
    s_DirUnix       VARCHAR2(255):='';

BEGIN

    -- ----------------------------------------------------------------------
    -- AJOUT DVA le 16/08/2007
    -- ----------------------------------------------------------------------

    -- Construire le nom complet de l'objet directory
    -- qui va permettre l'acces au filesystem unix
    -- (le nom de l'objet directory est fonction du code appli)
    n_CodeRet:=F_GET_DIR(t_InfoTrait,s_RepFic,s_DirComplet,s_DirUnix);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'ERREUR : IMPOSSIBLE DE METTRE A JOUR ' ||
                         'UNE LIGNE DANS LE FICHIER ['||s_NomFic||'] !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

    -- ----------------------------------------------------------------------
    -- FIN AJOUT DVA le 16/08/2007
    -- ----------------------------------------------------------------------

    -- Ouverture du fichier source en lecture
    BEGIN
        l_FichierIn := UTL_FILE.FOPEN(
                                     s_DirComplet,
                                     s_NomFic,
                                     'R',
                                     gi_MAX_LINE_SIZE
                                     ) ;
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_AFFICHER(
                              'ERREUR : '||SQLERRM || ' ' ||
                              '(FICHIER : '||
                              '['||s_DirComplet||'/'||s_NomFic||'])'
                              );
            RETURN Pkg_Global.gn_CR_KO;
    END;

    -- Ouverture du fichier temp en écriture
    BEGIN
        l_FichierOut := UTL_FILE.FOPEN(
                                      s_DirComplet,
                                      s_NomTemp,
                                      'W',
                                      gi_MAX_LINE_SIZE
                                      ) ;
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_AFFICHER(
                              'ERREUR : '||SQLERRM || ' ' ||
                              '(FICHIER : '||
                              '['||s_DirComplet||'/'||s_NomTemp||'])'
                              );
            RETURN Pkg_Global.gn_CR_KO;
    END;

    -- Traitement
    BEGIN
         LOOP
            -- lecture du fichier en entrée
            UTL_FILE.GET_LINE(l_FichierIn, s_Ligne);

            -- Si on trouve la ligne à remplacer on effectue le changement
            IF INSTR(s_Ligne, s_AncienneLigne) <> 0 THEN
               s_Ligne := s_NouvelleLigne;
            END IF;

            -- écriture du fichier en sortie
            UTL_FILE.PUT_LINE(l_FichierOut, s_Ligne);
         END LOOP ;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN -- Fin du fichier en entrée
             UTL_FILE.FFLUSH(l_FichierOut);
             -- Fermeture des fichiers
             IF UTL_FILE.IS_OPEN(l_FichierIn) THEN
                UTL_FILE.FCLOSE(l_FichierIn);
             END IF;
             IF UTL_FILE.IS_OPEN(l_FichierOut) THEN
                UTL_FILE.FCLOSE(l_FichierOut);
             END IF;
    END;

    -- On remplace le fichier source par le fichier temporaire
    UTL_FILE.FRENAME(s_DirComplet, s_NomTemp, s_DirComplet, s_NomFic, TRUE);

    -- Retourner le succes du traitement
    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN  UTL_FILE.INVALID_PATH THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'CHEMIN INCORRECT',
                         1,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    WHEN  UTL_FILE.INVALID_MODE THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'MODE INVALIDE',
                         2,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    WHEN  UTL_FILE.INVALID_OPERATION THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'OPERATION INVALIDE',
                         3,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    WHEN  UTL_FILE.INVALID_FILEHANDLE THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'FICHIER INVALIDE',
                         4,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    WHEN  UTL_FILE.WRITE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'ERREUR D''ECRITURE',
                         5,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    WHEN  UTL_FILE.INTERNAL_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'INTERNAL ERROR',
                         6,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    WHEN  NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'PAS DE DONNEES TROUVEES',
                         7,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    WHEN  VALUE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'VALUE ERROR',
                         8,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;

    WHEN OTHERS THEN
         Pkg_Log.P_ECRIRE(t_InfoTrait);
         IF UTL_FILE.IS_OPEN(l_FichierIn) THEN
            UTL_FILE.FCLOSE(l_FichierIn);
         END IF;
         IF UTL_FILE.IS_OPEN(l_FichierOut) THEN
             UTL_FILE.FCLOSE(l_FichierOut);
         END IF;
         RETURN Pkg_Global.gn_CR_KO;
END F_MAJ_LIGNE_FIC;

/******************************************************************************
   NAME:    F_GetDirectory
   PURPOSE: Cherche et crée le Directory en fonction de la variable
            d'environnement passée en paramètre
   PARAMS : s_EnvVar : nolm de la variable d'environnement
            s_NomDir : nom de la directory à créer

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        26/10/2006                    1. Created.
******************************************************************************/
FUNCTION F_MetCotes(s_Chaine VARCHAR2) RETURN VARCHAR2 IS
BEGIN
  RETURN '''' || s_Chaine || '''';
END F_MetCotes;

/****************************************************************************
you can call this function like,
find_position(<src_string>,<which_position>,<delimeter_string>)
will return you the actual characters.,
For example,

declare
i varchar2(2000):='first second third fourth ';
begin
 dbms_output.put_line('first='||find_position(i,1,' '));
 dbms_output.put_line('first='||find_position(i,2,' '));
 dbms_output.put_line('first='||find_position(i,3,' '));
 dbms_output.put_line('first='||find_position(i,4,' '));
end;

first=first
first=SECOND
first=third
first=fourth
*****************************************************************************/
FUNCTION F_FindPosition(s_src VARCHAR2,
                        n_pos NUMBER,
                        s_del VARCHAR2) RETURN VARCHAR2 IS
 i NUMBER:=0;
 ipos NUMBER:=0;
 ipos1 NUMBER:=0;
 sss VARCHAR2(50);
BEGIN
   WHILE (i < n_pos) LOOP
      ipos1:=ipos;
      ipos:=INSTR(s_src, s_del, ipos+1);
      i:=i+1;
   END LOOP;
   IF (ipos=0) THEN
     RETURN NULL; --SUBSTR(SUBSTR(s_src, ipos1+1), 1, LENGTH(SUBSTR(s_src, ipos1+1))-1);
   ELSE
     IF SUBSTR(s_src,(ipos1+1),(ipos-ipos1)) = s_del THEN
       RETURN NULL;
     ELSE
       RETURN SUBSTR(
                    SUBSTR( s_src, (ipos1+1), (ipos-ipos1) ),
                    1,
                    LENGTH(SUBSTR(s_src, (ipos1+1), (ipos-ipos1)))-1
                    );
     END IF;
   END IF;
END F_FindPosition;

/*
FUNCTION F_CreateDirectory(s_EnvVar VARCHAR2,
                           s_NomDir VARCHAR2) RETURN NUMBER IS

  s_EnvVarValue PUB_PARAMS.TXT_ENV_VAR_VALUE%TYPE;

BEGIN
  SELECT p.txt_env_var_value INTO s_EnvVarValue FROM pub_params p
  WHERE p.cd_env_var = s_EnvVar;

  EXECUTE IMMEDIATE 'CREATE OR REPLACE DIRECTORY '||s_NomDir||' AS '||F_MetCotes(s_EnvVarValue);
  RETURN 0;

  EXCEPTION WHEN OTHERS THEN
    PKG_LOG.P_Ecrire();
    RETURN -1;

END F_CreateDirectory;
*/

/******************************************************************************
   NAME:    F_DropDirectory
   PURPOSE:
   PARAMS : s_NomDir : nom de la directory à créer

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        26/10/2006                    1. Created.
******************************************************************************/
/*
FUNCTION F_DropDirectory(s_NomDir VARCHAR2) RETURN NUMBER IS

BEGIN

  EXECUTE IMMEDIATE 'DROP DIRECTORY '||s_NomDir;
  RETURN 0;

  EXCEPTION WHEN OTHERS THEN
    PKG_LOG.P_Ecrire();
    RETURN -1;

END F_DropDirectory;
 */

 /*
 FUNCTION Fic_Lire(s_FileName VARCHAR2, s_Dir VARCHAR2) RETURN INTEGER;
   IF FileExists(s_FileName, s_Dir) THEN
   END IF;
 END Fic_Lire;
*/

-- =======================================================================
-- # PROCEDURE    : F_OUVRIR_FICHIER
-- # DESCRIPTION  : Ouvrir un fichier
-- # PARAMETRES   :
-- #   + t_InfoTrait   : Informations du traitement
-- #   + s_DirName     : Répertoire du fichier à ouvrir : DIR_TEMP, DIR_IN, DIR_OUT, DIR_LOG
-- #   + s_FileName    : Nom du fichier à ouvrir
-- #   + s_OpenMode    : Mode d'ouverture R=Lecture, W=Ecriture, A=Ajout
-- #   + i_MaxLineSize : Taille max d'une ligne en octet (de 1 à 32767)
-- #   + n_FileRef     : Référence du fichier ouvert
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 18/08/2007 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_OUVRIR_FICHIER(
                          t_InfoTrait   IN            Pkg_Global.T_INFO_TRAITEMENT,
                          s_DirName     IN            VARCHAR2       DEFAULT 'DIR_TEMP',
                          s_FileName    IN            VARCHAR2,
                          s_OpenMode    IN            VARCHAR2       DEFAULT 'R',
                          i_MaxLineSize IN            BINARY_INTEGER DEFAULT 4000,
                          n_FileRef     IN OUT NOCOPY UTL_FILE.FILE_TYPE
                         )
                         RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_OUVRIR_FICHIER';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code retour
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;

    -- Nom complet d'un objet Directory Oracle existant
    -- et permettant d'accéder au disque
    s_DirComplet    VARCHAR2(30):='';

    -- Chemin unix correspondant à un objet Directory Oracle existant
    -- et permettant d'accéder au disque
    s_DirUnix       VARCHAR2(255):='';

BEGIN

    -- -------------------------------------------------------------------
    -- VERIFIER LES PARAMETRES
    -- -------------------------------------------------------------------

    -- Si le nom du répertoire du fichier à ouvrir n'est pas renseigné
    IF trim(s_DirName) IS NULL THEN
        n_CodeRet:=1;
        Pkg_Log.P_ECRIRE(
                        t_InfoTrait,
                        Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : REPERTOIRE DU FICHIER ' ||
                        'A OUVRIR NON RENSEIGNE. ' ||
                        'IMPOSSIBLE D''OUVRIR LE  FICHIER ' ||
                        '['||s_FileName||'] !',
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN n_CodeRet;
    END IF;

    -- Si le nom du fichier à ouvrir n'est pas renseigné
    IF trim(s_FileName) IS NULL THEN
        n_CodeRet:=2;
        Pkg_Log.P_ECRIRE(
                        t_InfoTrait,
                        Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : NOM DU FICHIER A OUVRIR NON RENSEIGNE !',
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN n_CodeRet;
    END IF;

/*
    -- Si le mode d'ouverture du fichier à ouvrir n'est pas renseigné ou incorrect
    IF    trim(s_OpenMode) IS NULL
       OR UPPER(trim(s_OpenMode)) NOT IN ('R','W','A') THEN
        n_CodeRet:=3;
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'ERREUR : MODE D''OUVERTURE DU FICHIER ' ||
                        'NON RENSEIGNE OU INCORRECT : ' ||
                        'SEULES LES VALEURS R(EAD), W(RITE) ' ||
                        'ET A(PPEND) SONT ADMISES !',
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN n_CodeRet;
    END IF;
*/
/*
    -- Si la taille maximum du fichier à ouvrir n'est pas correcte
    IF i_MaxLineSize < 1 OR i_MaxLineSize > 32767 THEN
        n_CodeRet:=4;
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'ERREUR : TAILLE MAX D''UNE LIGNE DE FICHIER ' ||
                        '['||to_char(i_MaxLineSize)||'] ' ||
                        'INCORRECTE (VALEURS AUTORISEES : [1 à 32767]) ! ',
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN n_CodeRet;
    END IF;
*/

    -- -------------------------------------------------------------------
    -- VERIFIER L'EXISTENCE DU FICHIER A OUVRIR
    -- -------------------------------------------------------------------
/*
    IF F_FileExists(t_InfoTrait,trim(s_FileName),trim(s_DirName))='FALSE' THEN
        n_CodeRet:=5;
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ORA,
                        'ERREUR : IMPOSSIBLE D''OUVRIR LE FICHIER ' ||
                        '['||s_FileName||'] ' ||
                        'DU REPERTOIRE ['||s_DirName||'] !',
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN n_CodeRet;
    END IF;
*/

    -- -------------------------------------------------------------------
    -- DETERMINER L'OBJET DIRECTORY ORACLE CORRESPONDANT AU REPERTOIRE DU FICHIER
    -- -------------------------------------------------------------------

    -- Construire le nom complet de l'objet directory
    -- qui va permettre l'acces au filesystem unix
    -- (le nom de l'objet directory est fonction du code appli)
    n_CodeRet:=F_GET_DIR(
                        t_InfoTrait,
                        UPPER(trim(s_DirName)),
                        s_DirComplet,
                        s_DirUnix
                        );
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        n_CodeRet:=6;
        Pkg_Log.P_ECRIRE(
                        t_InfoTrait,
                        Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : IMPOSSIBLE D''OUVRIR LE FICHIER ' ||
                        '['||s_FileName||'] ' ||
                        'DU REPERTOIRE ['||s_DirName||'] !',
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN n_CodeRet;
    END IF;

    -- -------------------------------------------------------------------
    -- OUVRIR LE FICHIER
    -- -------------------------------------------------------------------

    <<OuvrirFichier>>
    BEGIN
        n_FileRef := NULL;
        n_FileRef := utl_file.fopen(
                                   s_DirComplet,
                                   trim(s_FileName),
                                   UPPER(trim(s_OpenMode)),
                                   i_MaxLineSize
                                   );

    EXCEPTION

        -- Mode d'ouverture invalide
        WHEN UTL_FILE.INVALID_MODE THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=7;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : MODE D''OUVERTURE DU FICHIER ' ||
                            '['||s_DirComplet||'/'||s_FileName||'] ' ||
                            'INVALIDE : ' ||
                            'SEULES LES VALEURS ' ||
                            'R(EAD), W(RITE) ET A(PPEND) SONT ADMISES !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;

        -- Nom de répertoire invalide.
        WHEN UTL_FILE.INVALID_PATH THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=8;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ' ||
                            'REPERTOIRE ['||s_DirComplet||'] INVALIDE : ' ||
                            'IMPOSSIBLE D''OUVRIR LE FICHIER ' ||
                            '['||s_FileName||'] !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;

        -- Nom de fichier invalide.
        WHEN UTL_FILE.INVALID_FILENAME THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=9;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : FICHIER ' ||
                            '['||s_DirComplet||'/'||s_FileName||'] ' ||
                            'INTROUVABLE ! OUVERTURE IMPOSSIBLE !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;

        -- Accès au fichier interdit
        WHEN UTL_FILE.ACCESS_DENIED THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=10;
            Pkg_Log.P_ECRIRE(
                             t_InfoTrait,
                             Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : ACCES INTERDIT. ' ||
                             'IMPOSSIBLE D''OUVRIR LE FICHIER ' ||
                            '['||s_DirComplet||'/'||s_FileName||'] !',
                             n_CodeRet,
                             s_FONCTION
                             );
            RETURN n_CodeRet;

        -- La valeur de taille_ligne_maxi est trop grande ou trop petite.
        WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=11;
            Pkg_Log.P_ECRIRE(
                             t_InfoTrait,
                             Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : TAILLE MAX D''UNE LIGNE DE FICHIER ' ||
                             '['||TO_CHAR(i_MaxLineSize)||'] INCORRECTE ' ||
                             '(VALEURS AUTORISEES : [1 à 32767]) ! ' ||
                             'IMPOSSIBLE D''OUVRIR LE FICHIER ' ||
                            '['||s_DirComplet||'/'||s_FileName||'] !',
                             n_CodeRet,
                             s_FONCTION
                             );
            RETURN n_CodeRet;

        -- Le fichier ne peut être ouvert.
        WHEN UTL_FILE.INVALID_OPERATION THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=12;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : OPERATION INVALIDE ' ||
                            'LORS DE L''OUVERTURE DU FICHIER ' ||
                            '['||s_DirComplet||'/'||s_FileName||'] !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;

        -- Le fichier est déjà ouvert
        WHEN UTL_FILE.FILE_OPEN THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=13;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : LE FICHIER ' ||
                            '['||s_DirComplet||'/'||s_FileName||'] ' ||
                            'EST DEJA OUVERT !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;

        -- Erreur interne UTL_FILE
        WHEN UTL_FILE.INTERNAL_ERROR THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=14;
            Pkg_Log.P_ECRIRE(
                             t_InfoTrait,
                             Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : ERREUR INTERNE ' ||
                             'PACKAGE ORACLE UTL_FILE. ' ||
                             'IMPOSSIBLE D''OUVRIR LE FICHIER ' ||
                            '['||s_DirComplet||'/'||s_FileName||'] !',
                             n_CodeRet,
                             s_FONCTION
                             );
            RETURN n_CodeRet;

        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=15;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC D''OUVERTURE DU FICHIER ' ||
                            '['||s_DirComplet||'/'||s_FileName||'] !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;

    END OuvrirFichier;

    -- Retourner le succes du traitement
    RETURN Pkg_Global.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gérées
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        n_CodeRet:=Pkg_Global.gn_CR_KO;
        Pkg_Log.P_ECRIRE(
                        t_InfoTrait,
                        Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : ECHEC D''OUVERTURE DU FICHIER ' ||
                        '['||s_DirComplet||'/'||s_FileName||'] !',
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN n_CodeRet;

END F_OUVRIR_FICHIER;
 /******************************************************************************
   NAME:    FileRename
   PURPOSE: renommer un fichier dans le meme repertoire.

   PARAMS : s_FileName : nom du fichier
            Dir :        nom du directory
   JIRA :   FMCPTA-132
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/06/2008   FAU                 1. Created.
 ******************************************************************************/
FUNCTION F_FileRename(
                     ps_Dir VARCHAR2,
                     ps_FileNameSrc VARCHAR2,
                     ps_FileNameDest VARCHAR2
                     )
                     RETURN BOOLEAN
AS


BEGIN

    UTL_FILE.Frename(ps_Dir, ps_FileNameSrc,ps_Dir, ps_FileNameDest,TRUE);

    RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_AFFICHER(
                          'ERREUR : ' || SQLERRM || ' - ' ||
                          'IMPOSSIBLE DE RENOMMER LE FICHIER '||
                          '['||ps_Dir||'/'||ps_FileNameSrc||']'
                          );
     RETURN FALSE;
END F_FileRename;

 /******************************************************************************
   NAME:    F_ECRIRE_LIGNE_CLOB
   PURPOSE: Ecrit la ligne passée en paramêtre dans dans l'objet CLOB de la table passé
            en paramètre
   PARAMS : t_InfoTrait : Identifiant d'execution
            s_Param     : Identifiant de paramètre
            n_Ordre     : Identifiant d'ordre
            s_Ligne     : Ligne a insérer
            p_Entete    : insertion en entete de CLOB ou à la fin (O/N)
            t_Table    : Table de CLOB
            c_Dec       : Colonne d'identifiant d'execution dans t_Table
            c_Param     : Colonne d'identifiant de paramètre dans t_Table
            c_Ordre     : Colonne d'identifiant d'ordre dans t_Table
            c_Texte    : Colonne de l'objet CLOB dans t_Table
   RETOUR : 0 si OK
            -1 Sinon

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        17/04/2009  RLE              1. Created.
******************************************************************************/
 FUNCTION F_ECRIRE_LIGNE_CLOB(
                        t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                        s_Param     IN VARCHAR2,
                        n_Ordre     IN NUMBER,
                        s_Ligne     IN VARCHAR2,
                        p_Entete    IN VARCHAR2 default 'N',
                        t_Table     IN VARCHAR2 default 'TA_CLOB',
                        c_Dec       IN VARCHAR2 default 'ID_DEC',
                        c_Param     IN VARCHAR2 default 'NOM_PARAM',
                        c_Ordre     IN VARCHAR2 default 'ORDRE',
                        c_Texte        IN VARCHAR2 default    'TEXTE')
                        RETURN INTEGER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_ECRIRE_LIGNE_CLOB';

    l_Output        CLOB:=empty_clob();
    l_Entete        CLOB:=empty_clob();
    s_req           VARCHAR(255):= '';
    s_Dec           VARCHAR(15):= '';
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;

 BEGIN

    n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,s_Dec);

     dbms_lob.createtemporary(l_Output, TRUE);
     dbms_lob.open(l_Output, dbms_lob.lob_readwrite);

     s_req := 'select '||c_Texte ||  ' from '    ||t_Table ||
     ' where '||c_Dec||' = :s_Dec'               ||
     ' and '||c_Param||' = :s_Param'                   ||
     ' and '||c_Ordre||' = :n_Ordre'                      ||
     ' FOR update';

     EXECUTE IMMEDIATE s_req into l_Output using s_Dec,s_Param,n_Ordre;

     if p_Entete = 'N' then
        DBMS_LOB.WRITEAPPEND ( l_Output, length(chr(10)||s_Ligne),(chr(10)||s_Ligne));
     else
        begin
            dbms_lob.createtemporary(l_Entete, TRUE);
            dbms_lob.open(l_Entete, dbms_lob.lob_readwrite);
            l_Entete := To_Clob(s_Ligne||(chr(10)));
            dbms_lob.APPEND(l_Entete,l_Output);
            l_Output := l_Entete;
            DBMS_LOB.FREETEMPORARY (l_Entete);
        end;
     end if;

     s_req := 'Update '        ||t_Table     ||
     ' set '||c_Texte ||  ' = :l_Output'     ||
     ' where '||c_Dec||' = :s_Dec'     ||
     ' and '||c_Param||' = :s_Param'         ||
     ' and '||c_Ordre||' = :n_Ordre'          ;

    EXECUTE IMMEDIATE s_req using l_Output,s_Dec,s_Param,n_Ordre;

    RETURN Pkg_Global.GN_CR_OK;

EXCEPTION
    WHEN  NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'PAS DE DONNEES TROUVEES',
                         7,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  VALUE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'VALUE ERROR',
                         8,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;

END F_ECRIRE_LIGNE_CLOB;

/******************************************************************************
   NAME:    F_EcrireCsv_CLOB
   PURPOSE: Ecrit le résultat de la requête passée en paramêtre, dans un tableau
            de CLOB passé en paramêtre.
   PARAMS : t_InfoTrait : Identifiant d'execution
            s_Param     : Identifiant de paramètre
            n_Ordre     : Identifiant d'ordre
            p_query     : Requete
            p_separator : Seperateur utilise
            t_Table    : Table de CLOB
            c_Dec       : Colonne d'identifiant d'execution dans t_Table
            c_Param     : Colonne d'identifiant de paramètre dans t_Table
            c_Ordre     : Colonne d'identifiant d'ordre dans t_Table
            c_Texte    : Colonne de l'objet CLOB dans t_Table

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/08/2006  RLE              1. Created.
******************************************************************************/
 FUNCTION F_ECRIRECSV_CLOB(
                      t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                      s_Param     IN VARCHAR2,
                      n_Ordre     IN NUMBER,
                      p_query     IN VARCHAR2,
                      s_FileName  IN VARCHAR2,
                      p_separator IN VARCHAR2 DEFAULT ',',
                      s_DirName   IN VARCHAR2 default 'OUT_APPLI',
                      t_Table     IN VARCHAR2 default 'TA_CLOB',
                      c_Dec       IN VARCHAR2 default 'ID_DEC',
                      c_Param     IN VARCHAR2 default 'NOM_PARAM',
                      c_Ordre     IN VARCHAR2 default 'ORDRE',
                      c_Texte     IN VARCHAR2 default 'TEXTE',
                      s_Dir       IN VARCHAR2 default 'REP_FICHIER',
                      s_File      IN VARCHAR2 default 'NOM_FICHIER'
                     )
                      RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_ECRIRECSV_CLOB';

    l_output        CLOB:=empty_clob();
    l_theCursor     INTEGER DEFAULT dbms_sql.open_cursor;
    l_columnValue   VARCHAR2(2000);
    l_status        INTEGER;
    l_colCnt        NUMBER DEFAULT 0;
    l_separator     VARCHAR2(10) DEFAULT '';
    l_cnt           NUMBER DEFAULT 0;
    l_ligne         VARCHAR2(4000);
    l_octet         INTEGER :=1;


    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_req           VARCHAR2(255):='';
    s_Dec           VARCHAR(15):='';

BEGIN


 n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,s_Dec);

    -- ----------------------------------------------------------------------
    -- LIRE LES DONNEES POUR ALIMENTER LE FICHIER
    -- ----------------------------------------------------------------------

    dbms_lob.createtemporary(l_output, TRUE);
     dbms_lob.open(l_output, dbms_lob.lob_readwrite);

    <<Construire_curseur>>
    BEGIN
        -- Construire le curseur
        dbms_sql.parse(  l_theCursor, p_query, dbms_sql.native );
        FOR i IN 1 .. 255 LOOP
            BEGIN
                dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
                l_colCnt := i;
            EXCEPTION
                WHEN OTHERS THEN
                    IF ( SQLCODE = -1007 ) THEN EXIT;
                    ELSE
                        RAISE;
                    END IF;
            END;
        END LOOP;
        dbms_sql.define_column( l_theCursor, 1, l_columnValue, 4000 );
    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC CONSTRUCTION CURSEUR ' ||
                            'DE LECTURE DES INFORMATIONS A EXPORTER ' ||
                            'DANS LE FICHIER CSV !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Construire_curseur;

    <<Ouvrir_curseur>>
    BEGIN
        -- Ouvrir le curseur
        l_status := dbms_sql.EXECUTE(l_theCursor);
    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC REQUETE DE ' ||
                            'DE LECTURE DES INFORMATIONS A EXPORTER ' ||
                            'DANS LE FICHIER CSV !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Ouvrir_curseur;

    <<Parcourir_curseur>>
    BEGIN

        -- Parcourir le curseur et alimenter le fichier
        LOOP

            EXIT WHEN ( dbms_sql.fetch_rows(l_theCursor) <= 0 );
            l_ligne := '';
            l_separator := '';
            FOR i IN 1 .. l_colCnt LOOP

                dbms_sql.column_value( l_theCursor, i, l_columnValue );

                <<Alimenter_CLOB>>
                BEGIN

                    l_ligne := l_ligne || l_separator || l_columnValue;

                EXCEPTION
                    WHEN  OTHERS THEN
                        Pkg_Log.P_ECRIRE(t_InfoTrait);
                        n_CodeRet:=Pkg_Global.gn_CR_KO;
                        Pkg_Log.P_ECRIRE(
                                        t_InfoTrait,
                                        Pkg_Log.gt_LOG_TYPE_ERR,
                                        'ERREUR : ' ||
                                        'ECHEC ECRITURE INFORMATIONS ' ||
                                        'DANS LE FICHIER CSV ! ' ||
                                        '(INFO A ECRIRE : ' ||
                                        '['||l_separator||l_columnValue||'])',
                                        n_CodeRet,
                                        s_FONCTION
                                        );
                        RETURN n_CodeRet;
                END Alimenter_CLOB;

                l_separator := p_separator;
            END LOOP;
            l_cnt := l_cnt+1;


     /*DBMS_LOB.WRITE (l_output,length(l_ligne||chr(10)),l_octet,l_ligne||chr(10));
     l_octet := l_octet + length(l_ligne||chr(10));*/

  DBMS_LOB.WRITEAPPEND ( l_output, length(l_ligne||chr(10)), l_ligne||chr(10));

    END LOOP;

    <<Inserer_CLOB>>
    BEGIN
            s_req := 'Insert into '||t_Table||'('||c_Dec||' , '||c_Param||' , '||c_Ordre||' , '||c_Texte||' , '||s_Dir||', '||s_File||' ) values (:s_Dec, :s_Param, :n_Ordre, :l_output, :s_DirName, :FileName)';

      EXECUTE IMMEDIATE s_req using s_Dec,s_Param,n_Ordre,l_output,s_DirName,s_FileName;
     EXCEPTION
                    WHEN  OTHERS THEN
                        Pkg_Log.P_ECRIRE(t_InfoTrait);
                        n_CodeRet:=Pkg_Global.gn_CR_KO;
                        Pkg_Log.P_ECRIRE(
                                        t_InfoTrait,
                                        Pkg_Log.gt_LOG_TYPE_ERR,
                                        'ERREUR : ' ||
                                        'ECHEC INSERTION INFORMATIONS ' ||
                                        'DANS LA TABLE DES CLOB ! ' ||
                                        n_CodeRet,
                                        s_FONCTION
                                        );
                        RETURN n_CodeRet;
                END Inserer_CLOB;

    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ' ||
                            'ECHEC LECTURE DES INFORMATIONS A EXPORTER ' ||
                            'DANS LE FICHIER CSV !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Parcourir_curseur;

    <<Fermer_curseur>>
    BEGIN
        -- Fermer le curseur
        dbms_sql.close_cursor(l_theCursor);
    EXCEPTION
        WHEN  OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(
                            t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC FERMETURE DU CURSEUR ' ||
                            'DE LECTURE DES INFORMATIONS A EXPORTER ' ||
                            'DANS LE FICHIER CSV !',
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN n_CodeRet;
    END Fermer_curseur;

    -- Retourner le succés du traitement
    RETURN Pkg_Global.GN_CR_OK;

EXCEPTION
    WHEN  OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        n_CodeRet:=Pkg_Global.gn_CR_KO;
        Pkg_Log.P_ECRIRE(
                        t_InfoTrait,
                        Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : ECHEC EXPORT FICHIER CSV !',
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN n_CodeRet;

END F_EcrireCsv_CLOB;

/******************************************************************************
   NAME:    F_EcrireCsv_CLOB_SILENTLY
   PURPOSE: Ecrit le résultat de la requête passée en paramêtre, dans un tableau
            de CLOB passé en paramêtre. KEEP QUIET, no verbose logs.
   PARAMS : t_InfoTrait : Identifiant d'execution
            s_Param     : Identifiant de paramètre
            n_Ordre     : Identifiant d'ordre
            p_query     : Requete
            p_separator : Seperateur utilise
            t_Table    : Table de CLOB
            c_Dec       : Colonne d'identifiant d'execution dans t_Table
            c_Param     : Colonne d'identifiant de paramètre dans t_Table
            c_Ordre     : Colonne d'identifiant d'ordre dans t_Table
            c_Texte    : Colonne de l'objet CLOB dans t_Table

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/08/2006  RLE              1. Created.
******************************************************************************/
 FUNCTION F_ECRIRECSV_CLOB_SILENTLY(
                      t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                      s_Param     IN VARCHAR2,
                      n_Ordre     IN NUMBER,
                      p_query     IN VARCHAR2,
                      s_FileName  IN VARCHAR2,
                      p_separator IN VARCHAR2 DEFAULT ',',
                      s_DirName   IN VARCHAR2 default 'OUT_APPLI',
                      t_Table     IN VARCHAR2 default 'TA_CLOB',
                      c_Dec       IN VARCHAR2 default 'ID_DEC',
                      c_Param     IN VARCHAR2 default 'NOM_PARAM',
                      c_Ordre     IN VARCHAR2 default 'ORDRE',
                      c_Texte     IN VARCHAR2 default 'TEXTE',
                      s_Dir       IN VARCHAR2 default 'REP_FICHIER',
                      s_File      IN VARCHAR2 default 'NOM_FICHIER'
                     )
                      RETURN NUMBER
IS

    l_output        CLOB:=empty_clob();
    l_theCursor     INTEGER DEFAULT dbms_sql.open_cursor;
    l_columnValue   VARCHAR2(2000);
    l_status        INTEGER;
    l_colCnt        NUMBER DEFAULT 0;
    l_separator     VARCHAR2(10) DEFAULT '';
    l_cnt           NUMBER DEFAULT 0;
    l_ligne         VARCHAR2(4000);
    l_octet         INTEGER :=1;

    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_req           VARCHAR2(255):='';
    s_Dec           VARCHAR(15):='';

BEGIN

 n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, s_Dec);

    -- ----------------------------------------------------------------------
    -- LIRE LES DONNEES POUR ALIMENTER LE FICHIER
    -- ----------------------------------------------------------------------

    dbms_lob.createtemporary(l_output, TRUE);
    dbms_lob.open(l_output, dbms_lob.lob_readwrite);

    <<Construire_curseur>>
    BEGIN
        -- Construire le curseur
        dbms_sql.parse(  l_theCursor, p_query, dbms_sql.native );
        FOR i IN 1 .. 255 LOOP
            BEGIN
                dbms_sql.define_column( l_theCursor, i, l_columnValue, 4000 );
                l_colCnt := i;
            EXCEPTION
                WHEN OTHERS THEN
                    IF ( SQLCODE = -1007 ) THEN EXIT;
                    ELSE
                        RAISE;
                    END IF;
            END;
        END LOOP;
        dbms_sql.define_column( l_theCursor, 1, l_columnValue, 4000 );
    EXCEPTION
        WHEN  OTHERS THEN
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Construire_curseur;

    <<Ouvrir_curseur>>
    BEGIN
        -- Ouvrir le curseur
        l_status := dbms_sql.EXECUTE(l_theCursor);
    EXCEPTION
        WHEN  OTHERS THEN
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Ouvrir_curseur;

    <<Parcourir_curseur>>
    BEGIN

        -- Parcourir le curseur et alimenter le fichier
        LOOP
            EXIT WHEN ( dbms_sql.fetch_rows(l_theCursor) <= 0 );
            l_ligne := '';
            l_separator := '';
            FOR i IN 1 .. l_colCnt LOOP

                dbms_sql.column_value( l_theCursor, i, l_columnValue );

                <<Alimenter_CLOB>>
                BEGIN

                    l_ligne := l_ligne || l_separator || l_columnValue;

                EXCEPTION
                    WHEN  OTHERS THEN
                        n_CodeRet:=Pkg_Global.gn_CR_KO;
                        RETURN n_CodeRet;
                END Alimenter_CLOB;

                l_separator := p_separator;
            END LOOP;
            l_cnt := l_cnt+1;

        DBMS_LOB.WRITEAPPEND ( l_output, length(l_ligne||chr(10)), l_ligne||chr(10));

    END LOOP;

    <<Inserer_CLOB>>
    BEGIN
        s_req := 'Insert into '||t_Table||'('||c_Dec||' , '||c_Param||' , '||c_Ordre||' , '||c_Texte||' , '||s_Dir||', '||s_File||' ) values (:s_Dec, :s_Param, :n_Ordre, :l_output, :s_DirName, :FileName)';
        EXECUTE IMMEDIATE s_req USING s_Dec,s_Param,n_Ordre,l_output,s_DirName,s_FileName;
    EXCEPTION
		WHEN  OTHERS THEN
			n_CodeRet:=Pkg_Global.gn_CR_KO;
			RETURN n_CodeRet;
	END Inserer_CLOB;

    EXCEPTION
        WHEN  OTHERS THEN
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Parcourir_curseur;

    <<Fermer_curseur>>
    BEGIN
        -- Fermer le curseur
        dbms_sql.close_cursor(l_theCursor);
    EXCEPTION
        WHEN  OTHERS THEN
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Fermer_curseur;

    -- Retourner le succés du traitement
    RETURN Pkg_Global.GN_CR_OK;

EXCEPTION
    WHEN  OTHERS THEN
        n_CodeRet:=Pkg_Global.gn_CR_KO;
        RETURN n_CodeRet;

END F_EcrireCsv_CLOB_SILENTLY;

/******************************************************************************
   NAME:    F_ECRIRE_CLOB
   PURPOSE: Ecrit le contenu de la valeur passée en paramêtre, dans un tableau de
            CLOB passé en paramêtre.
   PARAMS : t_InfoTrait : Identifiant d'execution
            s_Param     : Identifiant de paramètre
            n_Ordre     : Identifiant d'ordre
            s_Texte     : Texte à inserer
            t_Table    : Table de CLOB
            c_Dec       : Colonne d'identifiant d'execution dans t_Table
            c_Param     : Colonne d'identifiant de paramètre dans t_Table
            c_Ordre     : Colonne d'identifiant d'ordre dans t_Table
            c_Texte    : Colonne de l'objet CLOB dans t_Table

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/11/2006  JHI                  1. Created.
******************************************************************************/
FUNCTION F_ECRIRE_CLOB(
                          t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                          s_Param     IN VARCHAR2,
                          n_Ordre     IN NUMBER,
                          s_Texte     IN VARCHAR2,
                          s_FileName  IN VARCHAR2,
                          s_DirName   IN VARCHAR2 default 'OUT_APPLI',
                          t_Table     IN VARCHAR2 default 'TA_CLOB',
                          c_Dec       IN VARCHAR2 default 'ID_DEC',
                          c_Param     IN VARCHAR2 default 'NOM_PARAM',
                          c_Ordre     IN VARCHAR2 default 'ORDRE',
                          c_Texte     IN VARCHAR2 default 'TEXTE',
                          s_Dir       IN VARCHAR2 default 'REP_FICHIER',
                          s_File      IN VARCHAR2 default 'NOM_FICHIER'
                      )
                          RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_ECRIRE_FICHIER_CLOB';
    l_output        CLOB:=empty_clob();
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_req           VARCHAR(255):= '';

    s_Dec           VARCHAR(15):='';
BEGIN

 n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,s_Dec);

    dbms_lob.createtemporary(l_output, TRUE);
     dbms_lob.open(l_output, dbms_lob.lob_readwrite);

    -- Ecrire le texte dans le CLOB
        DBMS_LOB.WRITEAPPEND (l_output, length(s_Texte),s_Texte);

    -- Générer l'entrée dans la table de CLOB
     s_req := 'Insert into '||t_Table||'('||c_Dec||' , '||c_Param||' , '||c_Ordre||' , '||c_Texte||' , '||s_Dir||', '||s_File||' ) values (:s_Dec, :s_Param, :n_Ordre, :l_output, :s_DirName, :FileName)';

    EXECUTE IMMEDIATE s_req using s_Dec,s_Param,n_Ordre,l_output,s_DirName,s_FileName;

    -- Retourner le succés du traitement
    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN  NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'PAS DE DONNEES TROUVEES',
                         7,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  VALUE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'VALUE ERROR',
                         8,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;

END F_ECRIRE_CLOB;

/******************************************************************************
   NAME:    F_VIDER_CLOB
   PURPOSE: Vide la table passé en paramètre de l'enregistrement correspondant
   		a l'identifiant d'execution donnée
   PARAMS : t_InfoTrait : Identifiant d'execution
            t_Table    : Table de CLOB
            c_Dec       : Colonne d'identifiant d'execution dans t_Table

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        07/05/2009  RLE                  1. Created.
******************************************************************************/
FUNCTION F_VIDER_CLOB(
                          t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                          t_Table     IN VARCHAR2 default 'TA_CLOB',
                          c_Dec       IN VARCHAR2 default 'ID_DEC'
                      )
                          RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_VIDER_CLOB';
    l_output        CLOB:=empty_clob();
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_req           VARCHAR(255):= '';

   s_Dec VARCHAR(15) := '';

BEGIN

 n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,s_Dec);

    -- Générer la suppression dans la table de CLOB
     s_req := 'delete from '||t_Table||' where '||c_Dec||' = :s_Dec';

      EXECUTE IMMEDIATE s_req using s_Dec;


    -- Retourner le succés du traitement
    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN  NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'PAS DE DONNEES TROUVEES',
                         7,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  VALUE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'VALUE ERROR',
                         8,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN  OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;

END F_VIDER_CLOB;

END Pkg_Tec_Fichiers;
