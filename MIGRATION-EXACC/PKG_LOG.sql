create or replace PACKAGE BODY PKG_LOG AS
-- ***********************************************************************
-- # PACKAGE      : PKG_LOG
-- # DESCRIPTION  : Journalisation de messages fonctionnels ou techniques
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 16/08/2006 |           | DVA    | Creation
-- # 1.1     | 16/08/2007 |           | DVA    | Gestion des objets Oracle
-- #         |            |           |        | DIRECTORY pour acces au disque
-- # 1.2     | 06/11/2008 |           | FAU    | Derivation P_ECRIRE
-- ***********************************************************************

-- =======================================================================
-- DECLARATION DES CONTANTES
-- =======================================================================

-- Nom du package
gs_PACKAGE CONSTANT VARCHAR2(25):='PKG_LOG';

-- Taille maximum d'un message dans la log
gi_MAX_MESSAGE_SIZE CONSTANT INTEGER:=4000;


-- =======================================================================
-- DECLARATION DES TYPES
-- =======================================================================



-- =======================================================================
-- DECLARATION DES VARIABLES
-- =======================================================================

-- Liste des types de message de log à tracer
gs_ListeTypeMsgLog VARCHAR2(255):=gt_LOG_TYPE_INF||','||gt_LOG_TYPE_CPT||','||gt_LOG_TYPE_DEB||','||gt_LOG_TYPE_TRT||','||
                                  gt_LOG_TYPE_FIN||','||gt_LOG_TYPE_RES||','||gt_LOG_TYPE_ERR||','||gt_LOG_TYPE_ALR||','||
                                  gt_LOG_TYPE_ORA||','||gt_LOG_TYPE_DBG;


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
                      t_InfoTrait  IN         PKG_GLOBAL.T_INFO_TRAITEMENT,
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
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'ERREUR : Directory recherché non renseigné. Impossible de vérifier son existence !',
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
        DIRECTORY_NAME=s_DirComplet
    ;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gérées
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_EXISTE_DIR;


-- =======================================================================
-- # PROCEDURE    : F_GET_DIR_UNIX_PATH
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
                                  t_InfoTrait   IN         PKG_GLOBAL.T_INFO_TRAITEMENT,
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
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'ERREUR : le directory dont on recherche ' ||
                         'le chemin unix n''est pas renseigné !',
                         1,
                         s_FONCTION);
        RETURN 1;
    END IF;

    -- -------------------------------------------------------------------
    -- RECHERCHER LE CHEMIN UNIX DU DIRECTORY
    -- -------------------------------------------------------------------

    -- Initialiser le chemin reccherché à vide
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
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------
    WHEN NO_DATA_FOUND THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'ERREUR : le directory ['||s_DirComplet||'] ' ||
                         'dont on recherche le chemin unix n''existe pas !',
                         PKG_GLOBAL.gn_CR_KO,
                         s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    -- Erreurs non gérées
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_UNIX_PATH_FROM_DIR;


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
                   t_InfoTrait  IN         PKG_GLOBAL.T_INFO_TRAITEMENT,
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
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

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
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'ERREUR : Directory demandé non renseigné. ' ||
                         'Impossible de déterminer le nom complet ' ||
                         'du directory !',
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

        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'ERREUR : Directory demandé incorrect. ' ||
                         'Il ne contient pas les valeurs suivantes : ' ||
                         'DIR_TEMP, DIR_IN, DIR_OUT, DIR_LOG. ' ||
                         'Impossible de déterminer le nom complet ' ||
                         'du directory !',
                         2,
                         s_FONCTION);
        RETURN 2;
    END IF;


    -- -------------------------------------------------------------------
    -- LIRE LE CODE APPLI DU TRAITEMENT EN COURS
    -- -------------------------------------------------------------------

    -- Lire le code appli dans les informations du traitement en cours
    n_CodeRet:=PKG_GLOBAL.F_GET_CODE_APPLI(t_InfoTrait,s_CodeAppli);

    -- En cas d'echec
    IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'ERREUR : Impossible de déterminer ' ||
                         'le code application et donc le nom complet ' ||
                         'du directory !',
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
    IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'ERREUR : Echec lors de la vérification ' ||
                         'de l''existence du directory !',
                         PKG_GLOBAL.gn_CR_KO,
                         s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;
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
        IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'ERREUR : Echec lors de la vérification ' ||
                             'de l''existence du directory !',
                             PKG_GLOBAL.gn_CR_KO,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;
        END IF;

        -- Si le directory n'existe pas non plus : constat d'échec
        IF b_Existe=0 THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'ERREUR : Directory inexistant !',
                             PKG_GLOBAL.gn_CR_KO,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;
        END IF;

    END IF;

    -- Si un directory existe
    IF b_Existe=1 THEN

        -- Lire le chemin unix correspondant au directory
        n_CodeRet:=F_GET_UNIX_PATH_FROM_DIR(t_InfoTrait,s_DirComplet,s_DirUnix);
        IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'ERREUR : Echec lors de la lecture ' ||
                             'du chemin unix du directory ' ||
                             '['||s_DirComplet||'] !',
                             PKG_GLOBAL.gn_CR_KO,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;
        END IF;

    END IF;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gérées
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_DIR;


-- =======================================================================
-- # PROCEDURE    : P_AFFICHER
-- # DESCRIPTION  : Afficher un message à l'écran (DBMS_OUTPUT)
-- #                sur une ou plusieurs lignes selon la taille
-- #                du message
-- # PARAMETRES   :
-- #   + ps_Message        : Texte du message à afficher
-- # MODIFICATION
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 18/08/2006 |           | DVA    | Creation
-- =======================================================================
PROCEDURE P_AFFICHER(s_Message IN VARCHAR2)
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'P_AFFICHER';

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Taille maximun d'une ligne
    -- (<=> taille max du buffer - cf. doc DBMS_OUTPUT)
    i_TAILLE_MAX_LIGNE CONSTANT PLS_INTEGER:=255;

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Texte du message débarrassé de ses espaces avant et aprés
    s_Msg      VARCHAR2(4096):='';

    -- Texte d'une ligne de message
    s_TexteLigne   VARCHAR2(255):='';

    -- Nombre de lignes nécessaire pour afficher le message
    i_NbLignes     PLS_INTEGER := 0;

    -- Nombre de caracteres restant sur la dernière ligne
    i_Reste        PLS_INTEGER := 0;

    -- No de ligne courante (boucle)
    i_NoLigneCour  PLS_INTEGER := 1;

    -- Position (No de caractère) dans le message
    -- de debut de la ligne courante
    i_PosDebLig    PLS_INTEGER := 1;

BEGIN

    -- -------------------------------------------------------------------
    -- AFFICHER LA OU LES LIGNES CORRESPONDANT AU MESSAGE
    -- -------------------------------------------------------------------

    -- Initialiser le buffer d'écriture
    DBMS_OUTPUT.ENABLE(999999);

    -- Elimination des espaces en fin message
    -- afin d'en reduire la taille au maximum
    s_Msg:=RTRIM(NVL(s_Message,''));

    -- Si le message est de taille inférieur la taille max d'une ligne
    IF LENGTH(s_Msg)<=i_TAILLE_MAX_LIGNE THEN

        -- Afficher le message
        DBMS_OUTPUT.PUT_LINE(s_Msg);

        -- Interrompre le traitement
        RETURN;

    END IF;

    -- Calcul du nombre de lignes nécessaire pour afficher le message
    i_NbLignes:=LENGTH(s_Msg)/i_TAILLE_MAX_LIGNE;

    -- Calcul du nombre de caractères restant sur la dernière ligne
    i_Reste:=MOD(LENGTH(s_Msg),i_TAILLE_MAX_LIGNE);

    -- Si la dernière ligne du message n'est pas une ligne complète
    IF i_Reste > 0
    THEN
        -- Incrémenter le nombre de lignes nécessaire
        -- pour afficher le message
        i_NbLignes:=i_NbLignes+1;
    END IF;

    -- Pour chaque ligne à afficher
    FOR i_NoLigneCour IN 1..i_NbLignes LOOP

        -- Extraire le texte de la ligne à afficher
        -- à partir du message original
        s_TexteLigne:=SUBSTR(s_Msg,i_PosDebLig,i_TAILLE_MAX_LIGNE);

        -- Afficher la ligne
        DBMS_OUTPUT.PUT_LINE(s_TexteLigne);

        -- Mettre à jour la position dans le message
        -- au début de la ligne suivante
        i_PosDebLig:=i_PosDebLig+i_TAILLE_MAX_LIGNE;

    END LOOP;

    -- Terminer le traitement
    RETURN;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        --DBMS_OUTPUT.PUT_LINE(s_FONCTION||' : ' ||
        --                     'Erreur No '||to_char(SQLCODE)||' : '|| SQLERRM);
        -- Mauvaise idée d'afficher un message avec DBMS_OUTPUT
        -- quand l'erreur est due à la saturation du buffer de DBMS_OUTPUT !!

        -- Terminer le traitement
        RETURN;

END P_AFFICHER;


-- =======================================================================
-- # PROCEDURE    : F_GET_INFO_CONTEXTE
-- # DESCRIPTION  : Lire les informations sur le contexte
-- #                d'exécution du programme
-- # PARAMETRES   :
-- #   + ps_UserOracle       : Identifiant utilisateur Oracle connecté
-- #   + ps_NomObjetAppelant : Nom de l'objet appelant cette fonction
-- #   + pn_NoLigneProg      : No de ligne dans le programme appelant
-- #   + ps_TypeAppelant     : Type d'objet appelant
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 18/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_INFO_CONTEXTE(
                             s_UserOracle       OUT VARCHAR2,
                             s_NomObjetAppelant OUT VARCHAR2,
                             n_NoLigneProg      OUT NUMBER,
                             s_TypeAppelant     OUT VARCHAR2
                            )
                            RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_INFO_CONTEXTE';

    -- Niveau dans la pile des appel : Me (cette fonction)
    n_NIVEAU_PILE_ME CONSTANT NUMBER:=1;

    -- Niveau dans la pile des appel : My Caller
    n_NIVEAU_PILE_MY_CALLER CONSTANT NUMBER:=2;

    -- Niveau dans la pile des appel : Their Caller
    n_NIVEAU_PILE_THEIR_CALLER CONSTANT NUMBER:=3;

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Pile des appels de fonctions
    s_CallStack  VARCHAR2(4096) DEFAULT dbms_utility.format_call_stack;

    -- Position (nb de caractères)
    -- dans la chaine constituant la pile des appels
    n_Position NUMBER:=0;

    -- Indicateur de debut des données utiles
    -- dans la chaine de la pile d'appels
    -- (fin des lignes de titre)
    b_DebPileTrouve BOOLEAN DEFAULT FALSE;

    -- Ligne courante (ou portion) dans la chaine
    -- de la pile des appels
    s_LigneCour VARCHAR2(255):='';

    -- Niveau courant dans l'arborescence
    -- de la pile des appels
    n_NiveauPileCour NUMBER := 0;

BEGIN

    -- Pour chaque ligne de la pile des appels
    LOOP

        -- Rechercher la position de la fin de la 1ère ligne
        -- de la pile des appels
        n_Position := INSTR( s_CallStack, CHR(10) );

        -- Condition de sortie de la boucle :
        -- * le niveau souhaité dans la pile est atteind OU
        -- * la pile est vide (pas de saut de ligne)
        EXIT WHEN ( n_NiveauPileCour = n_NIVEAU_PILE_THEIR_CALLER OR
                    n_Position IS NULL                            OR
                    n_Position = 0 );

        -- Extraire la ligne courante
        s_LigneCour := SUBSTR( s_CallStack,1,n_Position-1 );

        -- Eliminer la ligne courante de la chaine
        -- de la pile des appels
        s_CallStack := SUBSTR( s_CallStack,n_Position+1 );

        -- Si le début des données utiles n'a pas encore été trouvé
        IF ( NOT b_DebPileTrouve ) THEN

            -- Si la ligne courante correspond à la dernière ligne de titre
            IF ( s_LigneCour LIKE '%handle%number%name%' ) THEN

                -- Fixer à vrai l'indicateur de début des données utiles
                b_DebPileTrouve := TRUE;

            END IF;

        -- Cas des lignes de donnés utiles
        -- (les lignes de titre ont été passées)
        ELSE

            -- Remarque :
            -- n_NiveauPileCour = 1 is ME
            -- n_NiveauPileCour = 2 is MY Caller
            -- n_NiveauPileCour = 3 is Their Caller

            -- Incrémenter le niveau courant dans la pile
            n_NiveauPileCour := n_NiveauPileCour + 1;

            -- Afficher la pile
            P_AFFICHER(SUBSTR(s_CallStack,1,255));

            -- S'il s'agit de la procédure appelante
            IF ( n_NiveauPileCour = n_NIVEAU_PILE_THEIR_CALLER ) THEN

                -- Extraire le No de ligne du programme
                n_NoLigneProg := TO_NUMBER(
                                            SUBSTR(
                                                   s_LigneCour,
                                                   INSTR(s_LigneCour,' ',1,2),
                                                   9
                                                  )
                                           );

                -- Extraire la suite de la ligne courante
                s_LigneCour   := LTRIM(
                                       SUBSTR(
                                              s_LigneCour,
                                              INSTR(s_LigneCour,' ',1,2) + 10
                                             )
                                      );

                -- Déterminer le type de l'objet appelant
                IF    ( s_LigneCour LIKE 'pr%' ) THEN
                    n_Position := LENGTH( 'procedure ' );
                ELSIF ( s_LigneCour LIKE 'fun%' ) THEN
                    n_Position := LENGTH( 'function ' );
                ELSIF ( s_LigneCour LIKE 'package body%' ) THEN
                    n_Position := LENGTH( 'package body ' );
                ELSIF ( s_LigneCour LIKE 'pack%' ) THEN
                    n_Position := LENGTH( 'package ' );
                    n_NiveauPileCour := n_NiveauPileCour-1;
                ELSIF ( s_LigneCour LIKE 'anonymous%' ) THEN
                    n_Position := LENGTH( 'anonymous block ' );
                ELSE
                    n_Position := NULL;
                END IF;

                IF ( n_Position IS NOT NULL ) THEN
                   s_TypeAppelant := LTRIM(RTRIM(UPPER(SUBSTR(s_LigneCour,1,n_Position-1))));
                ELSE
                   s_TypeAppelant := 'TRIGGER';
                END IF;

                -- Extraire la fin de la ligne courante
                s_LigneCour := SUBSTR(s_LigneCour,NVL(n_Position,1));

                -- Rechercher la position du '.'
                n_Position := INSTR( s_LigneCour, '.' );

                -- Extraire l'utilisateur Oracle
                s_UserOracle := LTRIM(RTRIM(SUBSTR(s_LigneCour,1,n_Position-1)));

                -- Extraire le nom de l'objet appelant
                s_NomObjetAppelant := LTRIM(RTRIM(SUBSTR(s_LigneCour,n_Position+1)));

            END IF;

        END IF;

    END LOOP;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        P_AFFICHER(s_FONCTION||' : ' ||
                   'Erreur No '||TO_CHAR(SQLCODE)||' : '||SQLERRM);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_INFO_CONTEXTE;

-- =======================================================================
-- # PROCEDURE    : F_GET_CONTEXTE
-- # DESCRIPTION  : Lire les informations sur le contexte
-- #                d'exécution du programme
-- #                Les informations sont obtenues sous la forme
-- #                <User Oracle>.<Objet>@<No de ligne>
-- # PARAMETRES   :
-- #   + ps_UserOracle       : Identifiant utilisateur Oracle connecté
-- #   + ps_NomObjetAppelant : Nom de l'objet appelant cette fonction
-- #   + pn_NoLigneProg      : No de ligne dans le programme appelant
-- #   + ps_TypeAppelant     : Type d'objet appelant
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 18/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_CONTEXTE RETURN VARCHAR2
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_CONTEXTE';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code retour
    n_CodeRet NUMBER DEFAULT PKG_GLOBAL.gn_CR_KO;

    -- Informations sur le contexte formatées correctement
    s_Contexte VARCHAR2(64):='';

    -- Utilisateur Oracle connecté
    s_UserOracle VARCHAR2(15):='';

    -- Nom de l'objet appelant (package, procédure...)
    s_NomObjetAppelant VARCHAR2(25):='';

    -- No de ligne du programme appelant
    n_NoLigneProg NUMBER:=0;

    -- Type de programme appelant
    s_TypeAppelant VARCHAR2(64):='';

BEGIN

    -- -------------------------------------------------------------------
    -- LIRE LES INFORMATIONS DE CONTEXTE
    -- -------------------------------------------------------------------

    -- Lire les informations
    n_CodeRet:=F_GET_INFO_CONTEXTE(s_UserOracle,
                                   s_NomObjetAppelant,
                                   n_NoLigneProg,
                                   s_TypeAppelant);

    -- En cas de probleme
    IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN

        -- Afficher un message d'erreur
        P_AFFICHER(s_FONCTION||' : Erreur de lecture ' ||
                               'des informations de contexte !');

        -- Retourner un contexte vide
        RETURN '';

    END IF;

    -- -------------------------------------------------------------------
    -- LES RESTITUER FORMATEES
    -- -------------------------------------------------------------------

    IF LENGTH(s_UserOracle)>0 THEN
        s_Contexte:= trim(s_UserOracle);
    END IF;
    IF LENGTH(s_NomObjetAppelant)>0 THEN
        IF LENGTH(s_Contexte)>0 THEN
            s_Contexte:=s_Contexte || '.' || trim(s_NomObjetAppelant);
        ELSE
            s_Contexte:= trim(s_NomObjetAppelant);
        END IF;
    END IF;
    IF n_NoLigneProg >0 THEN
        IF LENGTH(s_Contexte)>0 THEN
            s_Contexte:=s_Contexte || '@' || TO_CHAR(n_NoLigneProg);
        ELSE
            s_Contexte:= '@' || TO_CHAR(n_NoLigneProg);
        END IF;
    END IF;

    -- Retourner les informations formatées
    RETURN s_Contexte;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        P_AFFICHER(s_FONCTION||' : ' ||
                   'Erreur No '||TO_CHAR(SQLCODE)||' : '||SQLERRM);

        -- Retourner un contexte vide
        RETURN '';

END F_GET_CONTEXTE;

-- =======================================================================
-- # PROCEDURE    : F_WRITE_MESSAGE
-- # DESCRIPTION  : Ecrire un message dans la table de log des messages
-- #                + Affichage du message
-- # PARAMETRES   :
-- #   + pn_IdExec        : Identifiant de declenchement
-- #   + ps_CdTypeMessage : Type de message
-- #   + pn_CdException   : Code exception à l'origine du message
-- #   + ps_LbMessage     : Libellé du message
-- #   + ps_IdTraitement  : Identifiant du traitement
-- #   + ps_IdProg        : Identifiant du programme
-- #   + pn_NoLigneProg   : No de ligne dans le programme
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 18/08/2006 |           | DVA    | Creation
-- # 2.0     | 06/11/2008 |           | FAU    | Ajout param TypeApp
-- =======================================================================
FUNCTION F_WRITE_MESSAGE(
                         n_IdExec        IN LOG_MESSAGE.ID_EXEC%TYPE         DEFAULT 0,
                         s_CdTypeMessage IN LOG_MESSAGE.CD_TYPE_MESSAGE%TYPE DEFAULT gt_LOG_TYPE_ORA,
                         n_CdException   IN LOG_MESSAGE.CD_EXCEPTION%TYPE    DEFAULT SQLCODE,
                         s_LbMessage     IN LOG_MESSAGE.LB_MESSAGE%TYPE      DEFAULT '',
                         s_IdTraitement  IN LOG_MESSAGE.ID_TRAITEMENT%TYPE   DEFAULT 'INCONNU',
                         s_IdProg        IN LOG_MESSAGE.ID_PROG%TYPE         DEFAULT F_GET_CONTEXTE,
                         n_NoLigneProg   IN LOG_MESSAGE.NO_LIGNE_PROG%TYPE
                        )
                        RETURN NUMBER
IS

    -- Transaction autonome
    PRAGMA AUTONOMOUS_TRANSACTION;

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_WRITE_MESSAGE';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Identifiant de message
    n_IdMessage NUMBER:=0;

    -- Date/Heure d'écriture du message
    d_DateMessage TIMESTAMP DEFAULT SYSTIMESTAMP;

    -- Libellé du type de message
    s_LbTypeMessage LOG_TYPE_MESSAGE.LB_TYPE_MESSAGE%TYPE:='';

BEGIN

    -- -------------------------------------------------------------------
    -- INITIALISER LES INFOS ASSOCIEES AU MESSAGE
    -- -------------------------------------------------------------------

    -- Lire le nouvel identifiant de message (séquence)
    SELECT
            SEQ_LOG_MESSAGE.NEXTVAL
    INTO
            n_IdMessage
    FROM
            DUAL;

    -- Lire le libellé du type de message
    -- à partir du code type de message
    SELECT
            L.LB_TYPE_MESSAGE
    INTO
            s_LbTypeMessage
    FROM
            LOG_TYPE_MESSAGE L
    WHERE
            L.CD_TYPE_MESSAGE = s_CdTypeMessage;

    -- -------------------------------------------------------------------
    -- AFFICHER LE MESSAGE
    -- -------------------------------------------------------------------

    -- Afficher tout le message et ses éléments associés
    P_AFFICHER('---------------------------------------------');
    P_AFFICHER('Id. message   : ' || TO_CHAR(n_IdMessage));
    P_AFFICHER('Date          : ' || TO_CHAR(d_DateMessage,
                                             'YYYY-MM-DD HH24:MI:SSXFF'));
    P_AFFICHER('Id. Execution : ' || TO_CHAR(n_IdExec));
    P_AFFICHER('Type message  : ' || s_CdTypeMessage || ' - ' || s_LbTypeMessage);
    P_AFFICHER('Exception     : ' || TO_CHAR(n_CdException));
    P_AFFICHER('Message       : ' || s_LbMessage);
    P_AFFICHER('Traitement    : ' || s_IdTraitement);
    P_AFFICHER('Programme     : ' || s_IdProg);
    P_AFFICHER('No ligne prog : ' || TO_CHAR(n_NoLigneProg));
    P_AFFICHER('---------------------------------------------');

    -- -------------------------------------------------------------------
    -- FILTRER LES TYPES DE MESSAGES A TRACER EN TABLE
    -- -------------------------------------------------------------------

    -- Si le type de message a tracer fait partie de la liste
    -- des types de messages autorises
    IF INSTR(gs_ListeTypeMsgLog,s_CdTypeMessage,1)!=0
    THEN

        -- -------------------------------------------------------------------
        -- ECRIRE LE MESSAGE DANS LA TABLE DE LOG DES MESSAGES
        -- -------------------------------------------------------------------

        -- Ecrire le message dans la table
        INSERT INTO LOG_MESSAGE
        (
         ID_MESSAGE,
         DT_MESSAGE,
         ID_EXEC,
         CD_TYPE_MESSAGE,
         CD_EXCEPTION,
         LB_MESSAGE,
         ID_TRAITEMENT,
         ID_PROG,
         NO_LIGNE_PROG
        )
        VALUES
        (
         n_IdMessage,
         d_DateMessage,
         n_IdExec,
         s_CdTypeMessage,
         n_CdException,
         REPLACE(s_LbMessage, CHR(10), ' '),
         s_IdTraitement,
         s_IdProg,
         n_NoLigneProg
         );


    END IF;

  -- Valider la transaction autonome
    COMMIT;

    -- Retourner le succes du traitement
  RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION

    WHEN OTHERS THEN

        -- Annuler la transaction autonome --> non, ce doit être fait au niveau du prog appelant : faux!!
        ROLLBACK;

        -- Afficher le message d'erreur Oracle
        P_AFFICHER(s_FONCTION||' : ' ||
                   'Erreur No '||TO_CHAR(SQLCODE)||' : '||SQLERRM);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_WRITE_MESSAGE;


-- =======================================================================
-- # PROCEDURE    : P_ECRIRE
-- # DESCRIPTION  : Ecrire un message de trace
-- #                Affichage du message +
-- #                sauvegarde dans la table de log des messages
-- # PARAMETRES   :
-- #   + t_InfoTrait   : Informations generale du traitement en cours
-- #   + s_TypeMessage : Type de message
-- #   + s_LbMessage   : Libellé du message
-- #   + n_CdException : Code de l'exception à l'origine du message
-- #   + s_IdProg      : Identifiant du programme à l'origine du message
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 18/08/2006 |           | DVA    | Creation
-- =======================================================================
PROCEDURE P_ECRIRE(
             t_InfoTrait      IN PKG_GLOBAL.T_INFO_TRAITEMENT,
             s_TypeMessage  IN T_LOG_TYPE_MESSAGE            DEFAULT gt_LOG_TYPE_ORA,
             s_LbMessage    IN LOG_MESSAGE.LB_MESSAGE%TYPE   DEFAULT SQLERRM,
             n_CdException  IN LOG_MESSAGE.CD_EXCEPTION%TYPE DEFAULT SQLCODE,
             s_IdProg       IN LOG_MESSAGE.ID_PROG%TYPE      DEFAULT F_GET_CONTEXTE
                  )
AS
    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'P_ECRIRE';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code retour
    n_CodeRet NUMBER DEFAULT PKG_GLOBAL.gn_CR_KO;

    -- Identifiant d'exécution du traitement
    n_IdExec        LOG_MESSAGE.ID_EXEC%TYPE:=0;

    -- Identifiant du traitement applicatif
    s_IdTraitement  LOG_MESSAGE.ID_TRAITEMENT%TYPE:='';

    -- Nom de la chaine de traitement
    s_NomChaine  VARCHAR2(32):='';

    -- Nom du traitement
    s_NomTraitement VARCHAR2(32):='';

    -- No de ligne du programme
    n_NoLigneProg   LOG_MESSAGE.NO_LIGNE_PROG%TYPE:=NULL;

BEGIN

    -- -------------------------------------------------------------------
    -- PREPARER LES INFOS ASSOCIEES AU MESSAGE
    -- -------------------------------------------------------------------

    -- Lire l'identifiant d'exécution (ou de déclenchement) du traitement
    n_CodeRet:=PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdExec);

    -- Lire le nom de la chaine de traitement en cours
    n_CodeRet:=PKG_GLOBAL.F_GET_NOM_CHAINE(t_InfoTrait, s_NomChaine);

    -- Lire le nom du traitement courant
    n_CodeRet:=PKG_GLOBAL.F_GET_NOM_TRAITEMENT(t_InfoTrait, s_NomTraitement);

    s_IdTraitement := s_NomChaine||'.'||s_NomTraitement;

    -- Extraire éventuellement le No de ligne des informations
    -- sur le programme passées en paramètre sous le format
    -- <User Oracle>.<Objet>@<No de ligne>
    IF INSTR(s_IdProg,'@')<>0 THEN
        n_NoLigneProg:=TO_CHAR(SUBSTR(s_IdProg,INSTR(s_IdProg,'@')+1));
    END IF;

    -- -------------------------------------------------------------------
    -- ECRIRE + AFFICHER LE MESSAGE
    -- -------------------------------------------------------------------

    -- Ecrire le message
    n_CodeRet:=F_WRITE_MESSAGE(NVL(n_IdExec,0),
                               NVL(s_TypeMessage,gt_LOG_TYPE_ORA),
                               NVL(n_CdException,0),
                               NVL(s_LbMessage,'**MESSAGE NON RENSEIGNE**'),
                               s_IdTraitement,
                               NVL(s_IdProg,'INCONNU'),
                               n_NoLigneProg);


    -- Fin du traitement
    RETURN;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        P_AFFICHER(s_FONCTION||' : ' ||
                   'Erreur No '||TO_CHAR(SQLCODE)||' : '||SQLERRM);

        -- Interrompre le traitement
        RETURN;

END P_ECRIRE;
-- =======================================================================
-- # PROCEDURE    : P_ECRIRE_APP
-- # DESCRIPTION  : Ecrire un message de trace
-- #                Affichage du message +
-- #                sauvegarde dans la table de log des messages
-- # PARAMETRES   :
-- #   + t_InfoTrait   : Informations generale du traitement en cours
-- #   + s_TypeMessage : Type de message
-- #   + s_LbMessage   : Libellé du message
-- #   + n_CdException : Code de l'exception à l'origine du message
-- #   + s_IdProg      : Identifiant du programme à l'origine du message
-- #   + ps_TypeApp    : Code appli (DTC, Actuate , Oracle Job...)
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 18/08/2006 |           | DVA    | Creation
-- # 2.0     | 06/11/2008 |           | FAU    | Derivation P_ECRIRE
-- =======================================================================
/*PROCEDURE P_ECRIRE_APP(
             t_InfoTrait      IN PKG_GLOBAL.T_INFO_TRAITEMENT,
             s_TypeMessage  IN T_LOG_TYPE_MESSAGE            DEFAULT gt_LOG_TYPE_ORA,
             s_LbMessage    IN LOG_MESSAGE.LB_MESSAGE%TYPE   DEFAULT SQLERRM,
             n_CdException  IN LOG_MESSAGE.CD_EXCEPTION%TYPE DEFAULT SQLCODE,
             s_IdProg       IN LOG_MESSAGE.ID_PROG%TYPE      DEFAULT F_GET_CONTEXTE,
             ps_TypeApp       IN LOG_MESSAGE.TYPE_APP%TYPE

                  )
AS
    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'P_ECRIRE_ACT';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code retour
    n_CodeRet NUMBER DEFAULT PKG_GLOBAL.gn_CR_KO;

    -- Identifiant d'exécution du traitement
    n_IdExec        LOG_MESSAGE.ID_EXEC%TYPE:=0;

    -- Identifiant du traitement applicatif
    s_IdTraitement  LOG_MESSAGE.ID_TRAITEMENT%TYPE:='';

    -- Nom de la chaine de traitement
    s_NomChaine  VARCHAR2(32):='';

    -- Nom du traitement
    s_NomTraitement VARCHAR2(32):='';

    -- No de ligne du programme
    n_NoLigneProg   LOG_MESSAGE.NO_LIGNE_PROG%TYPE:=NULL;

BEGIN

    -- -------------------------------------------------------------------
    -- PREPARER LES INFOS ASSOCIEES AU MESSAGE
    -- -------------------------------------------------------------------

    -- Lire l'identifiant d'exécution (ou de déclenchement) du traitement
    n_CodeRet:=PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdExec);

    -- Lire le nom de la chaine de traitement en cours
    n_CodeRet:=PKG_GLOBAL.F_GET_NOM_CHAINE(t_InfoTrait, s_NomChaine);

    -- Lire le nom du traitement courant
    n_CodeRet:=PKG_GLOBAL.F_GET_NOM_TRAITEMENT(t_InfoTrait, s_NomTraitement);

    s_IdTraitement := s_NomChaine||'.'||s_NomTraitement;

    -- Extraire éventuellement le No de ligne des informations
    -- sur le programme passées en paramètre sous le format
    -- <User Oracle>.<Objet>@<No de ligne>
    IF INSTR(s_IdProg,'@')<>0 THEN
        n_NoLigneProg:=TO_CHAR(SUBSTR(s_IdProg,INSTR(s_IdProg,'@')+1));
    END IF;

    -- -------------------------------------------------------------------
    -- ECRIRE + AFFICHER LE MESSAGE
    -- -------------------------------------------------------------------

    -- Ecrire le message
    n_CodeRet:=F_WRITE_MESSAGE(NVL(n_IdExec,0),
                               NVL(s_TypeMessage,gt_LOG_TYPE_ORA),
                               NVL(n_CdException,0),
                               NVL(s_LbMessage,'**MESSAGE NON RENSEIGNE**'),
                               s_IdTraitement,
                               NVL(s_IdProg,'INCONNU'),
                               n_NoLigneProg,
                               ps_TypeApp);


    -- Fin du traitement
    RETURN;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        P_AFFICHER(s_FONCTION||' : ' ||
                   'Erreur No '||TO_CHAR(SQLCODE)||' : '||SQLERRM);

        -- Interrompre le traitement
        RETURN;

END P_ECRIRE_APP;*/
-- =======================================================================
-- # PROCEDURE    : F_SET_TYPE_MSG_LOG
-- # DESCRIPTION  : Mettre à jour les types de message log à tracer
-- # PARAMETRES   :
-- #   + ps_ListeTypeMsgLog : Liste des type de message log à tracer
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/10/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_SET_TYPE_MSG_LOG(s_ListeTypeMsgLog IN VARCHAR2)
                            RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_SET_TYPE_MSG_LOG';

BEGIN

    -- Mettre à jour la liste des type de message
    gs_ListeTypeMsgLog:=s_ListeTypeMsgLog;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        P_AFFICHER(s_FONCTION||' : ' ||
                   'Erreur No '||TO_CHAR(SQLCODE)||' : '||SQLERRM);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_SET_TYPE_MSG_LOG;

-- =======================================================================
-- # PROCEDURE    : F_GET_TYPE_MSG_LOG
-- # DESCRIPTION  : Lire les types de message log à tracer
-- # PARAMETRES   :
-- #   + ps_ListeTypeMsgLog : Liste des type de message log à tracer
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/10/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_GET_TYPE_MSG_LOG(s_ListeTypeMsgLog OUT NOCOPY VARCHAR2)
                            RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_TYPE_MSG_LOG';

BEGIN

    -- Lire le nom du traitement courant
    s_ListeTypeMsgLog:=gs_ListeTypeMsgLog;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        P_AFFICHER(s_FONCTION||' : ' ||
                   'Erreur No '||TO_CHAR(SQLCODE)||' : '||SQLERRM);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_TYPE_MSG_LOG;

/******************************************************************************
   NAME:    F_ECRIRE_LOG
   PURPOSE: Ecrit le résultat de la requête passée en paramêtre, dans un
            fichier passé en paramêtre.
   PARAMS : p_query     : requête
            p_separator : format du séparateur dans le fichier
            p_dir       : répertoire de destination du fichier
            p_filename  : nom du fichier

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/08/2006  PDI              1. Created.
   1.1        16/08/2007  DVA              Ajout gestion objets directory
******************************************************************************/
 FUNCTION F_ECRIRE_LOG(
                       t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                       s_Query     IN VARCHAR2,
                       s_Separator IN VARCHAR2 DEFAULT ',',
                       s_Dir       IN VARCHAR2,
                       s_Filename  IN VARCHAR2,
                       s_Mode      IN VARCHAR2 DEFAULT 'W'
                      )
                      RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_ECRIRE_LOG';

    -- Code retour
    n_CodeRet       NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Fichier de log
    l_Output        UTL_FILE.FILE_TYPE;

    -- Curseur
    i_TheCursor     INTEGER DEFAULT dbms_sql.open_cursor;

    -- Valeur de la colonne
    s_ColumnValue   VARCHAR2(4000);

    -- Statut
    i_Status        INTEGER;

    -- Séparateur de colonne
    s_Separateur     VARCHAR2(10) DEFAULT '';

    -- Compteur des colonnes écrites dans le fichier de log
    n_ColCnt        NUMBER DEFAULT 0;

    -- Compteur des lignes écrites dans le fichier de log
    n_Cnt           NUMBER DEFAULT 0;

    -- Chemin unix d'ecriture du fichier de log
    s_DirUnix       VARCHAR2(255):='';

    -- Nom de l'objet Directory Oracle correspondant au répertoire unix
    -- d'écriture du fichier de log
    s_DirComplet    VARCHAR2(30):='';

BEGIN

    -- -----------------------------------------------------------------------
    -- AJOUT DVA le 16/08/2007
    -- -----------------------------------------------------------------------

    -- Construire le nom complet de l'objet directory
    -- qui va permettre l'acces au filesystem unix
    -- (le nom de l'objet directory est fonction du code appli)
    n_CodeRet:=F_GET_DIR(t_InfoTrait,s_Dir,s_DirComplet,s_DirUnix);
    IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'ERREUR : Impossible de générer le fichier ['||s_Filename||'] !',
                         PKG_GLOBAL.GN_CR_KO,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    END IF;

    -- -----------------------------------------------------------------------
    -- FIN AJOUT DVA le 16/08/2007
    -- -----------------------------------------------------------------------

    IF UPPER(s_mode) = 'W' THEN
       -- On préfixe le nom de fichier avec le caractère #
       -- afin d'éviter qu'il ne soit récupéré par une autre application
       -- avant d'être totalement écrit
       l_output := utl_file.fopen(
                                 s_DirComplet,
                                 '#'||s_Filename,
                                 s_Mode,
                                 gi_MAX_MESSAGE_SIZE
                                 );
    ELSE
       l_output := utl_file.fopen(
                                 s_DirComplet,
                                 s_Filename,
                                 s_Mode,
                                 gi_MAX_MESSAGE_SIZE
                                 );
    END IF;

    -- Tracer la requete d'extraction
    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_DBG,
                    'Requete extraction log : '||s_Query,
                    0,
                    s_FONCTION
                    );

    -- Construire le curseur
    dbms_sql.parse(  i_TheCursor, s_Query, dbms_sql.native );
    FOR i IN 1 .. 255 LOOP
        BEGIN
            dbms_sql.define_column( i_TheCursor, i, s_ColumnValue, 2000 );
            n_ColCnt := i;
        EXCEPTION
            WHEN OTHERS THEN
                IF ( SQLCODE = -1007 ) THEN EXIT;
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;
    dbms_sql.define_column( i_TheCursor, 1, s_ColumnValue, 2000 );

    -- Ouvrir le curseur
    i_Status := dbms_sql.EXECUTE(i_TheCursor);

    -- Lire le curseur et compléter le fichier de log
    LOOP
        EXIT WHEN ( dbms_sql.fetch_rows(i_TheCursor) <= 0 );
        s_Separateur := '';
        FOR i IN 1 .. n_ColCnt LOOP
            dbms_sql.column_value( i_TheCursor, i, s_ColumnValue );
            utl_file.put( l_Output, s_Separateur || s_ColumnValue );
            s_Separateur := s_Separator;
        END LOOP;
        utl_file.new_line( l_Output );
        n_Cnt := n_Cnt+1;
    END LOOP;
    dbms_sql.close_cursor(i_TheCursor);

    -- Forcer l'écriture du fichier de log sur le disque
    utl_file.fflush(l_output);

    -- Fermer le fichier de log
    utl_file.fclose( l_Output );

    -- En mode écriture
    IF UPPER(s_mode) = 'W' THEN

       -- On renomme le fichier avec le nom attendu en sortie
       utl_file.frename(
                       s_DirComplet,
                       '#'||s_Filename,
                       s_DirComplet,
                       s_Filename,
                       TRUE
                       );

    END IF;

    -- Retourner le succés du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

  EXCEPTION
     WHEN  UTL_FILE.INVALID_PATH THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Chemin incorrect : ['||s_Dir||']',
                         1,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  UTL_FILE.INVALID_MODE THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Mode invalide',
                         2,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  UTL_FILE.INVALID_OPERATION THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Opération invalide',
                         3,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  UTL_FILE.INVALID_FILEHANDLE THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Fichier invalide : ['||s_Filename||']',
                         4,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  UTL_FILE.WRITE_ERROR THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Erreur d''écriture',
                         5,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  UTL_FILE.INTERNAL_ERROR THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Internal error',
                         6,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  NO_DATA_FOUND THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Pas de données trouvées',
                         7,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  VALUE_ERROR THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Value error',
                         8,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.GN_CR_KO;

END F_ECRIRE_LOG;

-- =======================================================================
-- # PROCEDURE    : F_ADD_CLAUSE_WHERE
-- # DESCRIPTION  : Permet de concaténer la clause WHERE d'une requête SQL
-- #                avec une autre condition en déterminant
-- #                s'il faut ajouter un AND ou non
-- # PARAMETRES   : s_ClauseWhere : requête SQL
-- #                s_Condition   : condition à concaténer
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 02/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_ADD_CLAUSE_WHERE(
                            s_ClauseWhere IN OUT NOCOPY VARCHAR2,
                            s_Condition VARCHAR2
                           )
                            RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_ADD_CLAUSE_WHERE';

    -- Code retour
    n_CodeRet NUMBER DEFAULT PKG_GLOBAL.gn_CR_KO;

BEGIN
    -- Si le dernier mot de la requête en cours est WHERE alors la condition est la clause WHERE, on la concatène simplement
    IF INSTR(s_ClauseWhere, ' WHERE ')=(LENGTH(s_ClauseWhere)-6) THEN
       s_ClauseWhere := s_ClauseWhere||s_Condition;
    ELSE
    -- Sinon il y a déjà une clause WHERE, il s'agit d'une nouvelle condition on ajoute donc AND avant
       s_ClauseWhere := s_ClauseWhere||' AND '||s_Condition;
    END IF;

    -- Retourner le succès du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
        -- Afficher le message d'erreur Oracle
        P_AFFICHER(s_Fonction||' : Erreur No '||TO_CHAR(SQLCODE)||' : '||SQLERRM);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_ADD_CLAUSE_WHERE;

-- =======================================================================
-- # PROCEDURE    : F_EXT_CRE
-- # DESCRIPTION  : Génère un fichier de log au format CSV
-- #                et a partir des données de la table de log des messages
-- #                filtrée en fonction des paramètres fournis
-- # PARAMETRES   :
-- #    d_DateDebMsg   : date à partir de laquelle on commence
-- #                     à récupérer les logs
-- #    d_DateFinMsg   : date jusqu'à laquelle on arrête de récupèrer les log
-- #    n_IdExec       : identifiant d'exécution ou de déclenchement
-- #                     du traitement
-- #    s_CdTypeMsg    : code du type de message ou liste de codes
-- #                     entre apostrophes et séparés par une virgule
-- #    s_IdTraitement : idenfiant du traitement applicatif génerateur
-- #                     du message
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/10/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION  F_EXT_CRE(
                    t_InfoTrait    IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                    s_Dir          IN VARCHAR2,
                    s_Filename     IN VARCHAR2,
                    d_DateDebMsg   IN DATE     DEFAULT NULL,
                    d_DateFinMsg   IN DATE     DEFAULT NULL,
                    s_CdTypeMsg    IN VARCHAR2 DEFAULT NULL,
                    s_IdTraitement IN VARCHAR2 DEFAULT NULL,
                    s_Separator    IN VARCHAR2 DEFAULT ';'
                   )
                    RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_EXT_CRE';

    -- Code retour
    n_CodeRet NUMBER DEFAULT PKG_GLOBAL.gn_CR_KO;

    -- Identifiant d'exécution
    n_IdExec NUMBER;

    s_TypeMsgExclu VARCHAR2(60) := '''DBG'''||','||'''CPT''';

    -- Nom des colonnes de la table à inclure en tête du fichier CRE
    s_NomChampTable VARCHAR2(128):=
        'SELECT ' ||
        '    ''DT_MESSAGE;LB_MESSAGE;ID_EXEC;CD_TYPE_MESSAGE;CD_EXCEPTION'' '||
        'FROM DUAL';

    -- Paramètres de génération de la requête
    s_NomTableLog           VARCHAR2(30)   := 'LOG_MESSAGE';

    -- Liste des champs à extraire dans le CRE
    s_ListeChamp            VARCHAR2(200)  :=
        'TO_CHAR(DT_MESSAGE, ''DD/MM/YYYY HH24:MI:SS'') DT_MESSAGE, ' ||
        'LB_MESSAGE, ' ||
        'ID_EXEC, ' ||
        'CD_TYPE_MESSAGE, ' ||
        'CD_EXCEPTION ';

    -- Requete SQL
    s_Query                 VARCHAR2(4000) := '';

    -- Clause WHERE : filtre sur la date
    s_QueryClauseDate       VARCHAR2(100)  :=
        'TO_DATE(SUBSTR(DT_MESSAGE,1,8)) ' ||
        'BETWEEN '||d_DateDebMsg||' AND '||d_DateFinMsg;

    -- Clause WHERE : filtre sur l'identifiant d'exécution
    s_QueryClauseIdExec     VARCHAR2(100)  := '';

    -- Clause WHERE : filtre sur le type de message
    -- (liste des valeurs retenues)
    s_QueryClauseTypeMsg    VARCHAR2(100)  :=
        'CD_TYPE_MESSAGE IN ('||s_CdTypeMsg||')';

    -- Clause WHERE : filtre sur l'identifiant de traitement
    s_QueryClauseIdTrait    VARCHAR2(100)  :=
        'ID_TRAITEMENT = '||s_IdTraitement;

    -- Clause WHERE : filtre sur le type de message
    -- (liste des valeurs exclues)
    s_QueryClauseTypeMsg2   VARCHAR2(100)  :=
        'CD_TYPE_MESSAGE NOT IN ('||s_TypeMsgExclu||')';

    -- clause ORDER BY : tri sur l'identifiant de message
    s_QuerySortIdMessage    VARCHAR2(100)  := 'ORDER BY ID_MESSAGE';

    -- Exception
    ERREUR EXCEPTION;

BEGIN

    -- Ecrire la ligne d'entete du fichier CRE
    n_CodeRet:=F_ECRIRE_LOG(
                           t_InfoTrait,
                           s_NomChampTable,
                           '',
                           s_Dir,
                           s_Filename,
                           'W'
                           );
    IF  n_CodeRet<> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Récuperer l'identifiant d'exécution
    n_CodeRet:=PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdExec);
    IF  n_CodeRet<> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Si aucun des 5 paramètres n'existe
    -- tracer un message d'erreur
    IF (
          (
              (d_DateDebMsg IS NULL) OR
              (d_DateFinMsg IS NULL)
          )                          AND
          n_IdExec IS NULL           AND
          s_CdTypeMsg IS NULL        AND
          s_IdTraitement IS NULL
       )
    THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'Aucun des paramètres nécessaires au traitement ' ||
                         'n''est renseigné !'  ||
                         '(d_DateDebMsg : '   || d_DateDebMsg   || ',' ||
                         ' d_DateFinMsg : '   || d_DateFinMsg   || ',' ||
                         ' n_IdExec : '       || n_IdExec       || ',' ||
                         ' s_CdTypeMsg : '    || s_CdTypeMsg    || ',' ||
                         ' s_IdTraitement : ' || s_IdTraitement || ')',
                         PKG_GLOBAL.gn_CR_KO,
                         s_FONCTION);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Construire la requête qui va extraire le compte-rendu
    -- de la table les logs à partir des critères en entrée
    s_Query := 'SELECT '||s_ListeChamp||' FROM '||s_NomTableLog||' WHERE ';

    -- Construire la clause WHERE filtrant sur la date du message de log
    IF (d_DateDebMsg IS NOT NULL AND d_DateFinMsg IS NOT NULL) THEN
       IF F_ADD_CLAUSE_WHERE(s_Query, s_QueryClauseDate)
          <> PKG_GLOBAL.gn_CR_OK THEN
          RAISE ERREUR;
       END IF;
    END IF;

    -- Construire la clause WHERE filtrant sur l'identifiant d'exécution
    s_QueryClauseIdExec := 'ID_EXEC = '||n_IdExec;
    IF n_IdExec IS NOT NULL THEN
       IF F_ADD_CLAUSE_WHERE(s_Query, s_QueryClauseIdExec)
          <> PKG_GLOBAL.gn_CR_OK THEN
          RAISE ERREUR;
       END IF;
    END IF;

    -- Construire la clause WHERE filtrant sur
    IF s_CdTypeMsg IS NOT NULL THEN
       IF F_ADD_CLAUSE_WHERE(s_Query, s_QueryClauseTypeMsg)
          <> PKG_GLOBAL.gn_CR_OK THEN
          RAISE ERREUR;
       END IF;
    END IF;

    -- Construire la clause WHERE filtrant sur
    IF s_IdTraitement IS NOT NULL THEN
       IF F_ADD_CLAUSE_WHERE(s_Query, s_QueryClauseIdTrait)
          <> PKG_GLOBAL.gn_CR_OK THEN
          RAISE ERREUR;
       END IF;
    END IF;

    -- Restriction des types messages : on n'extrait pas les DBG et CPT
    -- (débug et compteur)
    s_Query := s_Query||' AND '||s_QueryClauseTypeMsg2;

    -- Ajout du tri à la requete pour avoir les messages dans l'ordre
    s_Query := s_Query||' '||s_QuerySortIdMessage;

    -- Compléter le fichier CRE avec les données retournées par la requete
    n_CodeRet := F_ECRIRE_LOG(
                             t_InfoTrait,
                             s_Query,
                             s_Separator,
                             s_Dir,
                             s_Filename,
                             'A'
                             );

    -- Retourner le résultat du traitement
    RETURN n_CodeRet;

EXCEPTION
    WHEN ERREUR THEN
         -- Afficher le message d'erreur Oracle
        PKG_LOG.P_ECRIRE(t_InfoTrait);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

    WHEN OTHERS THEN
        -- Afficher le message d'erreur Oracle
        PKG_LOG.P_ECRIRE(t_InfoTrait);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_EXT_CRE;

-- =======================================================================
-- # PROCEDURE    : F_ADD_CLAUSE_WHERE
-- # DESCRIPTION  : Permet de concaténer la clause WHERE d'une requête SQL
-- #                avec une autre condition en déterminant
-- #                s'il faut ajouter un AND ou non
-- # PARAMETRES   : s_ClauseWhere : requête SQL
-- #                s_Condition   : condition à concaténer
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 02/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_INI_LST_TYPE_MSG_LOG(
                               t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT
                               )
                               RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_INI_LST_TYPE_MSG_LOG';

    -- Environnement (DEV, REC, PRD)
    s_Environnement VARCHAR2(3);

    -- Liste des types de messages de log qui sont tracés par environnement
    s_ListeTypeMsgLog VARCHAR2(255):='';

    -- Code retour
    n_CodeRet NUMBER DEFAULT PKG_GLOBAL.gn_CR_KO;

BEGIN

    -- Récupération de l'environnement afin de déterminer les logs à tracer
    n_CodeRet:=PKG_GLOBAL.F_GET_ENVIRONNEMENT(t_InfoTrait,s_Environnement);
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Construction de la liste des types de log à tracer
    IF INSTR(PKG_GLOBAL.gs_ENVIRONNEMENT_DEV||','||
             PKG_GLOBAL.gs_ENVIRONNEMENT_REC,
             s_Environnement,1)=1
    THEN
       s_ListeTypeMsgLog := gt_LOG_TYPE_INF||','||
                            gt_LOG_TYPE_CPT||','||
                            gt_LOG_TYPE_DEB||','||
                            gt_LOG_TYPE_TRT||','||
                            gt_LOG_TYPE_FIN||','||
                            gt_LOG_TYPE_RES||','||
                            gt_LOG_TYPE_ERR||','||
                            gt_LOG_TYPE_ALR||','||
                            gt_LOG_TYPE_ORA||','||
                            gt_LOG_TYPE_DBG;
    ELSE -- on est en PROD
       s_ListeTypeMsgLog := gt_LOG_TYPE_INF||','||
                            gt_LOG_TYPE_CPT||','||
                            gt_LOG_TYPE_DEB||','||
                            gt_LOG_TYPE_TRT||','||
                            gt_LOG_TYPE_FIN||','||
                            gt_LOG_TYPE_RES||','||
                            gt_LOG_TYPE_ERR||','||
                            gt_LOG_TYPE_ALR||','||
                            gt_LOG_TYPE_ORA;
    END IF;

    -- Mise à jour de la variable globale des types de log à tracer
    n_CodeRet:=F_SET_TYPE_MSG_LOG(s_ListeTypeMsgLog);
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Retourner le succès du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
        -- Afficher le message d'erreur Oracle
        P_AFFICHER(s_Fonction||' : ' ||
                   'Erreur No '||TO_CHAR(SQLCODE)||' : '||SQLERRM);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_INI_LST_TYPE_MSG_LOG;

/******************************************************************************
   NAME:    F_ECRIRE_LOG_CLOB
   PURPOSE: Ecrit le résultat de la requête passée en paramêtre, dans un
            table CLOB passé en paramêtre.
   PARAMS :  t_InfoTrait : Identifiant d'execution
            t_Param     : Identifiant de paramètre
            t_Ordre     : Identifiant d'ordre
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
   1.0        19/08/2006  PDI              1. Created.
   1.1        16/08/2007  DVA              Ajout gestion objets directory
******************************************************************************/
 FUNCTION F_ECRIRE_LOG_CLOB(
                                          t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                      t_Param     IN VARCHAR2,
                      t_Ordre     IN NUMBER,
                      p_query     IN VARCHAR2,
                      s_FileName  IN VARCHAR2,
                      p_separator IN VARCHAR2 DEFAULT ',',
                      s_DirName   IN VARCHAR2 default '$OUT_APPLI',
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
        gs_PACKAGE || '.' || 'F_ECRIRE_LOG_CLOB';

    -- Code retour
    n_CodeRet       NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Fichier de log
    l_Output        CLOB:=empty_clob();

    -- Curseur
    i_TheCursor     INTEGER DEFAULT dbms_sql.open_cursor;

    -- Valeur de la colonne
    s_ColumnValue   VARCHAR2(4000);

    -- Statut
    i_Status        INTEGER;

    -- Séparateur de colonne
    s_Separateur     VARCHAR2(10) DEFAULT '';

    -- Compteur des colonnes écrites dans le fichier de log
    n_ColCnt        NUMBER DEFAULT 0;

    -- Compteur des lignes écrites dans le fichier de log
    n_Cnt           NUMBER DEFAULT 0;

        l_ligne         VARCHAR2(4000);
            s_req           VARCHAR2(255):='';


BEGIN


    dbms_lob.createtemporary(l_output, TRUE);
     dbms_lob.open(l_output, dbms_lob.lob_readwrite);

    -- Tracer la requete d'extraction
    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_DBG,
                    'Requete extraction log : '||p_query,
                    0,
                    s_FONCTION
                    );

    -- Construire le curseur
    dbms_sql.parse(  i_TheCursor, p_query, dbms_sql.native );
    FOR i IN 1 .. 255 LOOP
        BEGIN
            dbms_sql.define_column( i_TheCursor, i, s_ColumnValue, 2000 );
            n_ColCnt := i;
        EXCEPTION
            WHEN OTHERS THEN
                IF ( SQLCODE = -1007 ) THEN EXIT;
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;
    dbms_sql.define_column( i_TheCursor, 1, s_ColumnValue, 2000 );

    -- Ouvrir le curseur
    i_Status := dbms_sql.EXECUTE(i_TheCursor);

    -- Lire le curseur et compléter le fichier de log
    LOOP
        EXIT WHEN ( dbms_sql.fetch_rows(i_TheCursor) <= 0 );
        s_Separateur := '';
            l_ligne := '';
        FOR i IN 1 .. n_ColCnt LOOP
            dbms_sql.column_value( i_TheCursor, i, s_ColumnValue );
            l_ligne := l_ligne || p_separator || s_columnValue;
            s_Separateur := p_Separator;
        END LOOP;
        n_Cnt := n_Cnt+1;
        DBMS_LOB.WRITEAPPEND ( l_output, length(l_ligne||chr(10)), l_ligne||chr(10));
    END LOOP;
    dbms_sql.close_cursor(i_TheCursor);

 <<Inserer_CLOB>>
    BEGIN

      s_req := 'Insert into '||t_Table||'('||c_Dec||' , '||c_Param||' , '||c_Ordre||' , '||c_Texte||' , '||s_Dir||', '||s_File||' ) values (:t_InfoTrait, :t_Param, :t_ordre, :l_output, :s_DirName, :FileName)';

      EXECUTE IMMEDIATE s_req using t_InfoTrait,t_Param,t_ordre,l_output,s_DirName,s_FileName;

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


    -- Retourner le succés du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

  EXCEPTION
    WHEN  NO_DATA_FOUND THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Pas de données trouvées',
                         7,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  VALUE_ERROR THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ORA,
                         'Value error',
                         8,
                         s_FONCTION);
        RETURN PKG_GLOBAL.GN_CR_KO;
    WHEN  OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.GN_CR_KO;

END F_ECRIRE_LOG_CLOB;


END PKG_LOG;