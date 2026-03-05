create or replace PACKAGE BODY                       "PKG_DTC"
AS
-- ***********************************************************************
-- # PACKAGE      : PKG_DTC
-- # DESCRIPTION  : Gestion des informations de Declenchement
-- #                des Traitements Comptables (DTC)
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 03/08/2006 |           | DVA    | Creation
-- # 1.1     | 30/11/2007 |           | FRA    | add f_get_id_app
-- # 1.2     | 29/05/2008 |           | FRA    | Gestion Controleur DTC
-- # 1.3     | 18/08/2008 |           | DVA    | Gestion Code retour pkg metier
-- #         |            |           |        | + gestion lib resultat trait.
-- #         |            |           |        |   (table T_STATUT)
-- #         |            |           |        | + gestion table T_INFO
-- # 1.4     | 08/03/2010 | FMCP-647  | KBE    | Les DTC 571 du jour ne sont pas
-- #         |            |           |        | inclus dans le scope du marquage
-- #         |            |           |        | en KOBD. Package impacté sur
-- #         |            |           |        | COD2EUP0
-- #         |            |           |        | (voir aussi FMCP-2818 EVOL)
-- # 1.5     | 16/12/2011 | FMCP-3174 | OJE    | Ne pas marquer en KOBD
-- #         |            |           |        | les DTC en différés
-- #         |            |           |        | (voir aussi FMCP-2818 EVOL)
-- ***********************************************************************

-- =======================================================================
-- DECLARATION DES CONTANTES
-- =======================================================================

-- Nom du package
gs_PACKAGE CONSTANT VARCHAR2(25):='PKG_DTC';

gs_STATUT_ANO_DB CONSTANT VARCHAR2(25):='KOBD';

-- =======================================================================
-- DECLARATION DES VARIABLES
-- =======================================================================

-- Type de parametre a ne pas prendre en compte, ils ne servent que pour DTC
s_EXCEPLOG CONSTANT VARCHAR2(64):='DOWN,Fichier';

-- =======================================================================
-- # PROCEDURE    : F_GET_NOM_APP
-- # DESCRIPTION  : Lire le nom de l'application/traitement declenche
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   :
-- #   + pn_IdDec  : Identifiant de declenchement
-- #   + ps_NomApp : Nom de l'application/traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 03/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_NOM_APP(
                       t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                       s_NomApp OUT NOCOPY VARCHAR2
                      )
                      RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_NOM_APP';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- LECTURE DU NOM DE L'APPLICATION
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<LectureNomApp>>
    BEGIN

        -- Initialiser le nom de l'application
        s_NomApp:='';

        -- Rechercher le nom de l'application
        s_ReqSql:=
            'SELECT '                  ||
            '    A.NOM_APP '           ||
            'FROM '                    ||
            '    T_APPLICATIONS   A, ' ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    A.ID_APP = D.ID_APP ' ||
            'AND D.ID_DEC = ''' || n_IdDec || '''';

        EXECUTE IMMEDIATE s_ReqSql INTO s_NomApp;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche du nom de l''application (SELECT) :' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le nom de l'application
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Nom application : [' || s_NomApp || ']',
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureNomApp;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_NOM_APP;

-- =======================================================================
-- # PROCEDURE    : F_GET_ID_APP
-- # DESCRIPTION  : Lire le nom de l'application/traitement declenche
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   :
-- #   + pn_IdDec  : Identifiant de declenchement
-- #   + ps_IDApp :  id application/traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/11/2007 |           | FRA    | Creation
-- =======================================================================
FUNCTION F_GET_ID_APP(
                       t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                       s_IDApp OUT NOCOPY VARCHAR2
                      )
                      RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_ID_APP';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- LECTURE IDENTIFIANT APPLICATION
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<LectureIdApp>>
    BEGIN

        -- Initialiser l'identifiant de l'application
        s_IDApp:='';

        -- Rechercher l'identifiant de l'application
        s_ReqSql:=
            'SELECT '                  ||
            '    A.ID_APP '           ||
            'FROM '                    ||
            '    T_APPLICATIONS   A, ' ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    A.ID_APP = D.ID_APP ' ||
            'AND D.ID_DEC = '''          || n_IdDec || '''';

        EXECUTE IMMEDIATE s_ReqSql INTO s_IDApp;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche du nom de l''application (SELECT) :' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le nom de l'application
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Identifiant application : [' || s_IDApp || ']',
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureNomApp;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_ID_APP;
-- =======================================================================
-- # PROCEDURE    : F_GET_PROJET
-- # DESCRIPTION  : Lire le nom du projet du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   :
-- #   + pn_IdDec  : Identifiant de declenchement
-- #   + ps_Projet : Nom du projet du traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_PROJET(
                      t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                      s_Projet OUT NOCOPY VARCHAR2
                     )
                     RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_PROJET';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- LECTURE DU PROJET
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<LectureProjet>>
    BEGIN

        -- Initialiser le projet
        s_Projet:='';

        -- Rechercher le projet
        s_ReqSql:=
            'SELECT '                  ||
            '    A.PROJET '            ||
            'FROM '                    ||
            '    T_APPLICATIONS   A, ' ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    A.ID_APP = D.ID_APP ' ||
            'AND D.ID_DEC = '''          || to_char(n_IdDec) ||'';

        EXECUTE IMMEDIATE s_ReqSql INTO s_Projet;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche du projet (SELECT) :' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le projet
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Projet : ' ||
                         NVL(s_Projet,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureProjet;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_PROJET;


-- =======================================================================
-- # PROCEDURE    : F_GET_SOUS_PROJET
-- # DESCRIPTION  : Lire le nom du sous-projet du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   :
-- #   + pn_IdDec      : Identifiant de declenchement
-- #   + ps_SousProjet : Nom du sous-projet du traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_SOUS_PROJET(
                           t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                           s_SousProjet OUT NOCOPY VARCHAR2
                          )
                          RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_SOUS_PROJET';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- LECTURE DU SOUS-PROJET
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<LectureSousProjet>>
    BEGIN

        -- Initialiser le sous-projet
        s_SousProjet:='';

        -- Rechercher le sous-projet
        s_ReqSql:=
            'SELECT '                  ||
            '    A.SOUS_PROJET '       ||
            'FROM '                    ||
            '    T_APPLICATIONS   A, ' ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    A.ID_APP = D.ID_APP ' ||
            'AND D.ID_DEC = '''          || to_char(n_IdDec)|| '';

        EXECUTE IMMEDIATE s_ReqSql INTO s_SousProjet;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche du sous-projet (SELECT) :' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le sous-projet
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Sous-projet : ' ||
                         NVL(s_SousProjet,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureSousProjet;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_SOUS_PROJET;

-- =======================================================================
-- # PROCEDURE    : F_GET_SCRIPT
-- # DESCRIPTION  : Lire le nom du script du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   :
-- #   + pn_IdDec  : Identifiant de declenchement
-- #   + ps_Script : Nom du script du traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_SCRIPT(
                      t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                      s_Script OUT NOCOPY VARCHAR2
                     )
                     RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_SCRIPT';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- LECTURE DU SCRIPT DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<LectureScript>>
    BEGIN

        -- Initialiser le script du traitement
        s_Script:='';

        -- Rechercher le script du traitement
        s_ReqSql:=
            'SELECT '                  ||
            '    A.SCRIPT_APP '        ||
            'FROM '                    ||
            '    T_APPLICATIONS   A, ' ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    A.ID_APP = D.ID_APP ' ||
            'AND D.ID_DEC = '''          || to_char(n_IdDec) ||'''';

        EXECUTE IMMEDIATE s_ReqSql INTO s_Script;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche du script (SELECT) :' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le script
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Script : ' ||
                         NVL(s_Script,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureScript;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_SCRIPT;

-- =======================================================================
-- # PROCEDURE    : F_GET_NB_PARAM
-- # DESCRIPTION  : Lire le nombre de parametres du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   :
-- #   + pn_IdDec   : Identifiant de declenchement
-- #   + pn_NbParam : Nombre de parametre du traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_NB_PARAM(
                        t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                        n_NbParam OUT NOCOPY NUMBER,
                        b_Silence IN         BOOLEAN DEFAULT FALSE
                       )
                       RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_NB_PARAM';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- LECTURE NOMBRE DE PARAMETRES DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<LectureNbParam>>
    BEGIN

        -- Initialiser le nombre de parametres
        n_NbParam:=0;

        -- Rechercher le nombre de parametres
        s_ReqSql:=
            'SELECT '                   ||
            '    count(P.ID_PARAMAPP) ' ||
            'FROM '                     ||
            '    T_PARAMAPPLI     P,  ' ||
            '    T_APPLICATIONS   A,  ' ||
            '    T_DECLENCHEMENTS D   ' ||
            'WHERE '                    ||
            '    P.ID_APP = A.ID_APP  ' ||
            'AND A.ID_APP = D.ID_APP  ' ||
            'AND P.TYPE_PARAMAPP NOT IN (''DOWN'', ''Fichier'')  ' ||
            'AND D.ID_DEC ='''          || to_char(n_IdDec) || '''';

        EXECUTE IMMEDIATE s_ReqSql INTO n_NbParam;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        IF NOT b_Silence THEN
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Recherche du nombre de parametres (SELECT) :' ||
                            SQL%ROWCOUNT || ' lignes selectionnees',
                            SQL%ROWCOUNT,
                            s_FONCTION);

           -- Tracer le nombre de parametres
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Nombre de parametres : ['||TO_CHAR(n_NbParam)||']',
                            0,
                            s_FONCTION);
        END IF;

      EXCEPTION
        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureNbParam;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_NB_PARAM;

-- =======================================================================
-- # PROCEDURE    : F_GET_VAL_PARAM
-- # DESCRIPTION  : Lire un parametre du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- #                et du no d'ordre du parametre
-- # PARAMETRES   :
-- #   + pn_IdDec     : Identifiant de declenchement
-- #   + pn_NoParam   : No d'ordre du parametre de declenchement
-- #   + ps_ValParam  : Valeur du parametre du traitement demande
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_VAL_PARAM(
                         t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                         n_NoParam  IN          NUMBER,
                         s_ValParam OUT NOCOPY  VARCHAR2,
                         b_Silence  IN          BOOLEAN DEFAULT FALSE
                        )
                        RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_VAL_PARAM';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Nombre maximum de parametres du traitement
    n_NbParamMax NUMBER := 0;

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------

    <<ControlParam>>
    BEGIN

        -- Si le No d'ordre du parametre n'est pas renseigne
        IF n_NoParam IS NULL
        THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre ' ||
                             'non renseigne !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Si le No d'ordre du parametre <=0
        IF n_NoParam <= 0
        THEN
            n_CodeRet:=4;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] <=0 !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Rechercher le nombre maximum de parametre du traitement
        n_CodeRet:=F_GET_NB_PARAM(t_InfoTrait,n_NbParamMax, b_Silence);
        IF  n_CodeRet <> PKG_GLOBAL.gn_CR_OK
        THEN
            RETURN n_CodeRet;
        END IF;

        -- Si le No du parametre demande est superieur
        -- au nombre de parametre maximum du traitement
        IF n_NoParam > n_NbParamMax
        THEN
            n_CodeRet:=5;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] est invalide ' ||
                             '(max [' || n_NbParamMax || '] parametres) !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

    END ControlParam;

    -- -------------------------------------------------------------------
    -- LECTURE DE LA VALEUR DU PARAMETRE DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- ET DE SON NO D'ORDRE
    -- -------------------------------------------------------------------

    <<LectureValParam>>
    BEGIN

        -- Initialiser la valeur du parametre
        s_ValParam:='';

        -- Rechercher la valeur du parametre
        s_ReqSql:=
            'SELECT '||
            '    DECODE(P.VALEUR_PARAMDEC, '''',''NULL'',''''''''||P.VALEUR_PARAMDEC||'''''''')' ||
            'FROM '||
            '    T_PARAMDEC P ' ||
            'WHERE '||
            '    P.ID_DEC = ''' || to_char(n_IdDec) || ''''||
            'AND P.ORDRE_PARAMDEC = '||to_char(n_NoParam);
            --'SELECT '                              ||
            --'   P.VALEUR_PARAMDEC                  ||
            --'FROM '                                ||
            --'    T_PARAMDEC P       '              ||
            --'WHERE '                               ||
            --'    P.ID_DEC =         '              || n_IdDec || ' ' ||
            --'AND P.ORDRE_PARAMDEC = '              || n_NoParam;

        EXECUTE IMMEDIATE s_ReqSql INTO s_ValParam;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        IF NOT b_Silence THEN
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Recherche de la valeur du parametre No [' ||
                            to_char(n_NoParam,'9900') || '] (SELECT) : '||
                            SQL%ROWCOUNT || ' lignes selectionnees',
                            SQL%ROWCOUNT,
                            s_FONCTION);
        END IF;

        -- <MODIF> DVA - 12/08/08 - 1.01
        --         Conditionner l'affichage du message au parametre b_Silence
        --         + modifier le type de message de log : INF => TRT

        IF NOT b_Silence THEN
            -- Tracer la valeur du parametre
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_TRT,
                             'Parametre ['||to_char(n_NoParam,'9900')||'] : '||
                             '['||nvl(s_ValParam,'<NON RENSEIGNE>')||']',
                              0,
                            s_FONCTION);
        END IF;

        -- </MODIF>

      EXCEPTION

        -- Echec de la recherche de la valeur du parametre
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=6;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Valeur du parametre No [' ||
                             to_char(n_NoParam,'9900') || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureValParam;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_VAL_PARAM;


-- =======================================================================
-- # PROCEDURE    : F_GET_LIB_PARAM
-- # DESCRIPTION  : Lire le libelle d'un parametre du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- #                et du no d'ordre du parametre
-- # PARAMETRES   :
-- #   + pn_IdDec     : Identifiant de declenchement
-- #   + pn_NoParam   : No d'ordre du parametre de declenchement
-- #   + ps_LibParam  : libelle du parametre du traitement demande
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_LIB_PARAM(
                         t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                         n_NoParam  IN          NUMBER,
                         s_LibParam OUT NOCOPY  VARCHAR2
                        )
                        RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_LIB_PARAM';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Nombre maximum de parametres du traitement
    n_NbParamMax NUMBER := 0;

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------

    <<ControlParam>>
    BEGIN

        -- Si le No d'ordre du parametre n'est pas renseigne
        IF n_NoParam IS NULL
        THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre ' ||
                             'non renseigne !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Si le No d'ordre du parametre <=0
        IF n_NoParam <= 0
        THEN
            n_CodeRet:=4;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] <=0 !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Rechercher le nombre maximum de parametre du traitement
        n_CodeRet:=F_GET_NB_PARAM(t_InfoTrait,n_NbParamMax);
        IF  n_CodeRet <> PKG_GLOBAL.gn_CR_OK
        THEN
            RETURN n_CodeRet;
        END IF;

        -- Si le No du parametre demande est superieur
        -- au nombre de parametre maximum du traitement
        IF n_NoParam > n_NbParamMax
        THEN
            n_CodeRet:=5;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] est invalide ' ||
                             '(max [' || n_NbParamMax || '] parametres) !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

    END ControlParam;

    -- -------------------------------------------------------------------
    -- LECTURE DU LIBELLE DU PARAMETRE DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- ET DE SON NO D'ORDRE
    -- -------------------------------------------------------------------

    <<LectureLibParam>>
    BEGIN

        -- Initialiser le libelle du parametre
        s_LibParam:='';

        -- Rechercher libelle du parametre
        s_ReqSql:=
            'SELECT '                   ||
            '    P.LIBELLE_PARAMAPP   ' ||
            'FROM '                     ||
            '    T_PARAMAPPLI     P,  ' ||
            '    T_DECLENCHEMENTS D   ' ||
            'WHERE '                    ||
            '    D.ID_DEC =           ''' || to_char(n_IdDec) || '''' ||
            'AND D.ID_APP = P.ID_APP  ' ||
            'AND P.ORDRE_PARAMAPP =   ' || n_NoParam;

        EXECUTE IMMEDIATE s_ReqSql INTO s_LibParam;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche le libelle du parametre No [' ||
                         TO_CHAR(n_NoParam) || '] (SELECT) : ' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le libelle du parametre
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'libelle du parametre No [' ||
                         TO_CHAR(n_NoParam) || '] : ' ||
                         NVL(s_LibParam,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Echec de la recherche du libelle du parametre
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=6;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'libelle du parametre No [' ||
                             n_NoParam || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureLibParam;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_LIB_PARAM;


-- =======================================================================
-- # PROCEDURE    : F_GET_TYPE_PARAM
-- # DESCRIPTION  : Lire le type d'un parametre du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- #                et du no d'ordre du parametre
-- # PARAMETRES   :
-- #   + pn_IdDec     : Identifiant de declenchement
-- #   + pn_NoParam   : No d'ordre du parametre de declenchement
-- #   + ps_TypeParam : Type du parametre du traitement demande
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_TYPE_PARAM(
                          t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                          n_NoParam   IN         NUMBER,
                          s_TypeParam OUT NOCOPY T_TYPE_PARAM_APPLI,
                          b_Silence   IN         BOOLEAN DEFAULT FALSE
                         )
                         RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_TYPE_PARAM';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Nombre maximum de parametres du traitement
    n_NbParamMax NUMBER := 0;

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------

    <<ControlParam>>
    BEGIN

        -- Si le No d'ordre du parametre n'est pas renseigne
        IF n_NoParam IS NULL
        THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre ' ||
                             'non renseigne !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Si le No d'ordre du parametre <=0
        IF n_NoParam <= 0
        THEN
            n_CodeRet:=4;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] <=0 !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Rechercher le nombre maximum de parametre du traitement
        n_CodeRet:=F_GET_NB_PARAM(t_InfoTrait,n_NbParamMax, b_Silence);
        IF  n_CodeRet <> PKG_GLOBAL.gn_CR_OK
        THEN
            RETURN n_CodeRet;
        END IF;

        -- Si le No du parametre demande est superieur
        -- au nombre de parametre maximum du traitement
        IF n_NoParam > n_NbParamMax
        THEN
            n_CodeRet:=5;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] est invalide ' ||
                             '(max [' || n_NbParamMax || '] parametres) !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

    END ControlParam;

    -- -------------------------------------------------------------------
    -- LECTURE DU TYPE DU PARAMETRE DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- ET DE SON NO D'ORDRE
    -- -------------------------------------------------------------------

    <<LectureTypeParam>>
    BEGIN

        -- Initialiser le type de parametre
        s_TypeParam:='';

        -- Rechercher le type de parametre
        s_ReqSql:=
            'SELECT '                   ||
            '    P.TYPE_PARAMAPP      ' ||
            'FROM '                     ||
            '    T_PARAMAPPLI     P,  ' ||
            '    T_DECLENCHEMENTS D   ' ||
            'WHERE '                    ||
            '    D.ID_DEC =           '''          || to_char(n_IdDec) || '''' ||
            'AND D.ID_APP = P.ID_APP  ' ||
            'AND P.ORDRE_PARAMAPP =   ' || to_char(n_NoParam);

        EXECUTE IMMEDIATE s_ReqSql INTO s_TypeParam;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        IF NOT b_Silence THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             'Recherche le type du parametre No [' ||
                             TO_CHAR(n_NoParam) || '] (SELECT) : ' ||
                             SQL%ROWCOUNT || ' lignes selectionnees',
                             SQL%ROWCOUNT,
                             s_FONCTION);

            -- <MODIF> DVA - 12/08/08 - 1.01
            --         Modifier le type de message : INF => DBG
            --         afin d'alleger les compte-rendus utilisateurs

            -- Tracer le type du parametre
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             'Type du parametre No [' ||
                             TO_CHAR(n_NoParam) || '] : ' ||
                             NVL(s_TypeParam,'<NON RENSEIGNE>'),
                             0,
                             s_FONCTION);
            -- </MODIF>

        END IF;

      EXCEPTION

        -- Echec de la recherche du type du parametre
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=6;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Type du parametre No [' ||
                             n_NoParam || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureTypeParam;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_TYPE_PARAM;


-- =======================================================================
-- # PROCEDURE    : F_GET_OBLIG_PARAM
-- # DESCRIPTION  : Lire le caractere obligatoire ou facultatif
-- #                d'un parametre du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- #                et du no d'ordre du parametre
-- # PARAMETRES   :
-- #   + pn_IdDec     : Identifiant de declenchement
-- #   + pn_NoParam   : No d'ordre du parametre de declenchement
-- #   + ps_EstOblig  : Caractere obligatoire ou facultatif
-- #                    du parametre du traitement demande
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/08/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_OBLIG_PARAM(
                           t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                           n_NoParam  IN         NUMBER,
                           s_EstOblig OUT NOCOPY T_OBLIG_PARAM_APPLI
                          )
                          RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_OBLIG_PARAM';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Nombre maximum de parametres du traitement
    n_NbParamMax NUMBER := 0;

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------

    <<ControlParam>>
    BEGIN

        -- Si le No d'ordre du parametre n'est pas renseigne
        IF n_NoParam IS NULL
        THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre ' ||
                             'non renseigne !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Si le No d'ordre du parametre <=0
        IF n_NoParam <= 0
        THEN
            n_CodeRet:=4;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] <=0 !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Rechercher le nombre maximum de parametre du traitement
        n_CodeRet:=F_GET_NB_PARAM(t_InfoTrait,n_NbParamMax);
        IF  n_CodeRet <> PKG_GLOBAL.gn_CR_OK
        THEN
            RETURN n_CodeRet;
        END IF;

        -- Si le No du parametre demande est superieur
        -- au nombre de parametre maximum du traitement
        IF n_NoParam > n_NbParamMax
        THEN
            n_CodeRet:=5;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] est invalide ' ||
                             '(max [' || n_NbParamMax || '] parametres) !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

    END ControlParam;

    -- -------------------------------------------------------------------
    -- LECTURE DU CARACTERE OBLIGATOIRE OU FACULTATIF DU PARAMETRE DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- ET DE SON NO D'ORDRE
    -- -------------------------------------------------------------------

    <<LectureObligParam>>
    BEGIN

        -- Initialiser
        s_EstOblig:='';

        -- Rechercher
        s_ReqSql:=
            'SELECT '                   ||
            '    P.OBLIG_PARAMAPPLI   ' ||
            'FROM '                     ||
            '    T_PARAMAPPLI     P,  ' ||
            '    T_DECLENCHEMENTS D   ' ||
            'WHERE '                    ||
            '    D.ID_DEC =           '''          || to_char(n_IdDec) || '''' ||
            'AND D.ID_APP = P.ID_APP  ' ||
            'AND P.ORDRE_PARAMAPP =   ' || to_char(n_NoParam);

        EXECUTE IMMEDIATE s_ReqSql INTO s_EstOblig;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche le caractere obligatoire ou facultatif ' ||
                         'du parametre No [' ||
                         TO_CHAR(n_NoParam) || '] (SELECT) : ' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le caractere obligatoire ou facultatif du parametre
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Parametre No [' || TO_CHAR(n_NoParam) ||
                         '] obligatoire : ' ||
                         NVL(s_EstOblig,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Echec de la recherche du caractere
        -- obligatoire ou facultatif du parametre
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=6;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Caractere obligatoire ou facultatif ' ||
                             'du parametre No [' ||
                             n_NoParam || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureObligParam;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_OBLIG_PARAM;


-- =======================================================================
-- # PROCEDURE    : F_GET_VAL_DEF_PARAM
-- # DESCRIPTION  : Lire la valeur par defaut
-- #                d'un parametre du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- #                et du no d'ordre du parametre
-- # PARAMETRES   :
-- #   + pn_IdDec       : Identifiant de declenchement
-- #   + pn_NoParam     : No d'ordre du parametre de declenchement
-- #   + ps_ValDefParam : Valeur par defaut du parametre
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 04/09/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_VAL_DEF_PARAM(
                             t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                             n_NoParam     IN         NUMBER,
                             s_ValDefParam OUT NOCOPY VARCHAR2
                            )
                            RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_VAL_DEF_PARAM';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Nombre maximum de parametres du traitement
    n_NbParamMax NUMBER := 0;

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------

    <<ControlParam>>
    BEGIN

        -- Si le No d'ordre du parametre n'est pas renseigne
        IF n_NoParam IS NULL
        THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre ' ||
                             'non renseigne !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Si le No d'ordre du parametre <=0
        IF n_NoParam <= 0
        THEN
            n_CodeRet:=4;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] <=0 !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Rechercher le nombre maximum de parametres du traitement
        n_CodeRet:=F_GET_NB_PARAM(t_InfoTrait,n_NbParamMax);
        IF  n_CodeRet <> PKG_GLOBAL.gn_CR_OK
        THEN
            RETURN n_CodeRet;
        END IF;

        -- Si le No du parametre demande est superieur
        -- au nombre de parametres maximum du traitement
        IF n_NoParam > n_NbParamMax
        THEN
            n_CodeRet:=5;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] est invalide ' ||
                             '(max [' || n_NbParamMax || '] parametres) !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

    END ControlParam;

    -- -------------------------------------------------------------------
    -- LECTURE DE LA VALEUR PAR DEFAUT DU PARAMETRE DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- ET DE SON NO D'ORDRE
    -- -------------------------------------------------------------------

    <<LectureValDefParam>>
    BEGIN

        -- Initialiser a vide la valeur par defaut du parametre
        s_ValDefParam:='';

        -- Rechercher la valeur par defaut du parametre
        s_ReqSql:=
            'SELECT '                   ||
            '    P.DEFAULT_PARAMAPPLI ' ||
            'FROM '                     ||
            '    T_PARAMAPPLI     P,  ' ||
            '    T_DECLENCHEMENTS D   ' ||
            'WHERE '                    ||
            '    D.ID_DEC =           '''          || to_char(n_IdDec) || '''' ||
            'AND D.ID_APP = P.ID_APP  ' ||
            'AND P.ORDRE_PARAMAPP =   ' || to_char(n_NoParam);

        EXECUTE IMMEDIATE s_ReqSql INTO s_ValDefParam;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche la valeur par defaut ' ||
                         'du parametre No [' ||
                         TO_CHAR(n_NoParam) || '] (SELECT) : ' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer la valeur par defaut du parametre
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Valeur par defaut du parametre No [' ||
                         TO_CHAR(n_NoParam) || '] : ' ||
                         NVL(s_ValDefParam,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Echec de la recherche de la valeur par defaut du parametre
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=6;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Valeur par defaut ' ||
                             'du parametre No [' ||
                             n_NoParam || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureValDefParam;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_VAL_DEF_PARAM;


-- =======================================================================
-- # PROCEDURE    : F_GET_MODIF_PARAM
-- # DESCRIPTION  : Lire le caractere modifiable de la valeur
-- #                d'un parametre du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- #                et du no d'ordre du parametre
-- # PARAMETRES   :
-- #   + pn_IdDec         : Identifiant de declenchement
-- #   + pn_NoParam       : No d'ordre du parametre de declenchement
-- #   + ps_EstModifiable : Caractere modifiable de la valeur du parametre
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 04/09/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_MODIF_PARAM(
                           t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                           n_NoParam       IN         NUMBER,
                           s_EstModifiable OUT NOCOPY VARCHAR2
                          )
                          RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_MODIF_PARAM';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Nombre maximum de parametres du traitement
    n_NbParamMax NUMBER := 0;

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------

    <<ControlParam>>
    BEGIN

        -- Si le No d'ordre du parametre n'est pas renseigne
        IF n_NoParam IS NULL
        THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre ' ||
                             'non renseigne !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Si le No d'ordre du parametre <=0
        IF n_NoParam <= 0
        THEN
            n_CodeRet:=4;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] <=0 !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

        -- Rechercher le nombre maximum de parametres du traitement
        n_CodeRet:=F_GET_NB_PARAM(t_InfoTrait,n_NbParamMax);
        IF  n_CodeRet <> PKG_GLOBAL.gn_CR_OK
        THEN
            RETURN n_CodeRet;
        END IF;

        -- Si le No du parametre demande est superieur
        -- au nombre de parametres maximum du traitement
        IF n_NoParam > n_NbParamMax
        THEN
            n_CodeRet:=5;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'No d''ordre du parametre [' ||
                             n_NoParam || '] est invalide ' ||
                             '(max [' || n_NbParamMax || '] parametres) !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;
        END IF;

    END ControlParam;

    -- -------------------------------------------------------------------
    -- LECTURE DE LA VALEUR PAR DEFAUT DU PARAMETRE DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- ET DE SON NO D'ORDRE
    -- -------------------------------------------------------------------

    <<LectureEstParamModifiable>>
    BEGIN

        -- Initialiser a vide la valeur par defaut du parametre
        s_EstModifiable:='';

        -- Rechercher la valeur par defaut du parametre
        s_ReqSql:=
            'SELECT '                      ||
            '    P.MODIFIABLE_PARAMAPPLI ' ||
            'FROM '                        ||
            '    T_PARAMAPPLI     P,     ' ||
            '    T_DECLENCHEMENTS D      ' ||
            'WHERE '                       ||
            '    D.ID_DEC = '''          || to_char(n_IdDec) || '''' ||
            'AND D.ID_APP = P.ID_APP     ' ||
            'AND P.ORDRE_PARAMAPP =      ' || to_char(n_NoParam);

        EXECUTE IMMEDIATE s_ReqSql INTO s_EstModifiable;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche du Caractere modifiable de la valeur ' ||
                         'du parametre No [' ||
                         to_char(n_NoParam,'9900') || '] (SELECT) : ' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le caractere modifiable de la valeur du parametre
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Valeur du parametre No [' ||
                         to_char(n_NoParam,'9900') || '] modifiable : ' ||
                         nvl(s_EstModifiable,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Echec de la recherche du caractere modifiable
        -- de la valeur du parametre
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=6;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Caractere modifiable de la valeur par defaut ' ||
                             'du parametre No [' ||
                             n_NoParam || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureEstParamModifiable;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_MODIF_PARAM;


-- =======================================================================
-- # PROCEDURE    : F_DEBUT_CHAINE
-- # DESCRIPTION  : Initialiser le traitement de debut d'une chaine
-- # PARAMETRES   : t_InfoTrait : Informations generales sur le traitement en cours
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.00    | 30/11/2006 |           | JHI    | Creation
-- # 1.01    | 18/08/2008 |           | DVA    | Enreg infos dans T_INFO
-- =======================================================================
FUNCTION F_DEBUT_CHAINE(
                        t_InfoTrait IN OUT PKG_GLOBAL.T_INFO_TRAITEMENT
                       )
                        RETURN NUMBER
IS
    -- Transaction autonome
    --PRAGMA AUTONOMOUS_TRANSACTION;

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_DEBUT_CHAINE';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Nom de la chaine a executer
    s_NomChaine VARCHAR2(64) := '';

    -- Identifiant de l'application (ou chaine de traitements)
    s_IDApp VARCHAR2(3) := '';

    -- Liste des valeurs des parametres de la chaine a executer
    s_ListeValParam VARCHAR2(2048):='';

    -- Date de debut de traitement au format AAAA/MM/DD HH:MI:SS
    s_DateDebTrait VARCHAR(19) := '';

    -- Message d'erreur remonte par la procedure de controle de t_InfoTrait
    s_MsgErreur VARCHAR(512) := '';

    -- Titre de la chaine de traitement
    s_NomApp VARCHAR2(100):='';

    -- Liste des mails
    s_ListeMail VARCHAR2(4000):='';

    -- Identifiant d'execution du traitement courant
    n_IdExecTraitement VARCHAR2(15) := '';

    -- Nombre de parametres de la chaine de traitements
    n_NbParam NUMBER:=0;

    -- Informations sur l'utilisateur declencheur
    s_RoleUser     VARCHAR2(12)   := '';
    s_IdUser       VARCHAR2(64)   := '';
    s_UID          VARCHAR2(8)    := '';
    s_LoginWindows VARCHAR2(50)   := '';
    s_Nom          VARCHAR2(50)   := '';
    s_Prenom       VARCHAR2(50)   := '';
    s_Mail         VARCHAR2(1024) := '';

BEGIN

    -- Initialisation des types de message log a tracer
    IF PKG_LOG.F_INI_LST_TYPE_MSG_LOG(t_InfoTrait) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------

    -- Executer la fonction de controle des parametres
    n_CodeRet := PKG_GLOBAL.F_CTRL_INFO_TRAIT(t_InfoTrait, s_MsgErreur);
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        s_MsgErreur,
                        n_CodeRet,
                        s_FONCTION
                        );
        RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- RECUPERER LES INFORMATIONS SUR LA CHAINE DE TRAITEMENTS
    -- -------------------------------------------------------------------

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,n_IdExecTraitement)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recuperer le nom de la chaine de traitements (application) a lancer
    IF PKG_GLOBAL.F_GET_NOM_CHAINE(t_InfoTrait, s_NomChaine)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recuperer l'identifiant de l'application
    IF F_GET_ID_APP(t_InfoTrait,s_IDApp) <> PKG_GLOBAL.gn_CR_OK THEN
        RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recuperer le titre de la chaine de traitement
    IF F_GET_NOM_APP(t_InfoTrait, s_NomApp) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recuperer le role de l'utilisateur du traitement
    IF PKG_GLOBAL.F_GET_USER_ROLE(t_InfoTrait, s_RoleUser)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    IF s_RoleUser = 'DTC' THEN

       -- Recuperer l'identifiant de l'utilisateur du traitement,
       IF F_GET_USER(t_InfoTrait, s_IdUser, TRUE) <> PKG_GLOBAL.gn_CR_OK THEN
          RETURN PKG_GLOBAL.gn_CR_KO;
       END IF;

       -- Recuperer les informations sur l'utilisateur declencheur
       IF F_GET_USER_INFO(
                         t_InfoTrait,
                         s_IdUser,
                         s_UID,
                         s_LoginWindows,
                         s_Nom,
                         s_Prenom,
                         s_Mail,
                         TRUE
                         ) <> PKG_GLOBAL.gn_CR_OK THEN
          RETURN PKG_GLOBAL.gn_CR_KO;
       END IF;

       -- Memoriser l'identifiant de l'utilisateur du traitement
       -- pour ameliorer le niveau de trace dans les logs
       IF PKG_GLOBAL.F_SET_ID_USER_TRAIT(
                                        t_InfoTrait,
                                        s_IdUser
                                        ) <> PKG_GLOBAL.gn_CR_OK THEN
             RETURN PKG_GLOBAL.gn_CR_KO;
       END IF;

    END IF;

    -- Recuperer la liste des adresses e-mail pour l'envoi du CRE
    IF F_GET_LISTE_MAIL(t_InfoTrait, s_ListeMail) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recuperer le nombre de parametres de la chaine de traitements
    IF F_GET_NB_PARAM(t_InfoTrait,n_NbParam,TRUE) <> PKG_GLOBAL.gn_CR_OK THEN
        RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Construire la liste des parametres du traitement
    IF F_GET_LISTE_VAL_PARAM(t_InfoTrait, s_ListeValParam, TRUE)
       <> PKG_GLOBAL.gn_CR_OK THEN
        RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- TRACER ET AFFICHER LES INFORMATIONS SUR LA CHAINE DE TRAITEMENTS
    -- -------------------------------------------------------------------

    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_TRT,
                    '*******************************************************',
                    0,
                    s_FONCTION
                    );

    -- Marquer le debut du traitement
    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_DEB,
                    '** '||s_NomApp||' - '||
                    '['||
                    s_NomChaine ||
                    ']',
                    0,
                    s_FONCTION
                    );

    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_TRT,
                    '*******************************************************',
                    0,
                    s_FONCTION
                    );

    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_TRT,
                    '** No Traitement DTC          : ['|| n_IdExecTraitement ||']',
                    0,
                    s_FONCTION
                    );

    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_TRT,
                    '** No Application DTC         : [' || s_IDApp || ']',
                    0,
                    s_FONCTION
                    );

    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_TRT,
                    '** Utilisateur declencheur    : ' ||
                    '[' ||
                    trim(s_IdUser) ||
                    case
                        when      trim(s_Nom)    is not null
                             and  trim(s_Prenom) is not null
                        then ' - ' || upper(s_Nom) || ' ' || s_Prenom
                        else ''
                    end ||
                    case
                        when trim(s_Mail) is not null
                        then ' - ' || trim(s_Mail)
                        else ''
                    end ||
                    ']',
                    0,
                    s_FONCTION
                    );

    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_TRT,
                    '** Destinataires compte-rendu : [' || s_ListeMail || ']',
                    0,
                    s_FONCTION
                    );

    /*
    Le nombre de parametre retourne est parfois faux dans la mesure ou
    il ne prend pas en compte les parametres de type FILE et DOWN :
    il est donc parfois incohirent avec la liste des parametres.
    Inutile donc de le calculer et de l'afficher
    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_TRT,
                    '** Nombre de parametres       : [' || to_char(n_NbParam) || ']',
                    0,
                    s_FONCTION
                    );
    */

    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_TRT,
                    '** Valeurs des parametres     : ',
                    0,
                    s_FONCTION
                    );

    -- Afficher la liste des parametres du traitement
    -- A FAIRE : BLOC DE CODE A METTRE DANS UNE FONCTION SEPAREE
    <<AfficherParam>>
    DECLARE

        -- Texte d'affichage des parametres
        s_TexteParam VARCHAR2(255):='';

        -- Taille affichage valeur param
        n_TailleAffichage NUMBER:=0;
        n_TAILLE_MAX_AFFICHAGE CONSTANT NUMBER:=40;

    BEGIN

        -- Pour chacun des parametres du traitement
        FOR vcur_ParamCour IN
        (
        select
            pd.ordre_paramdec   as NUM_PARAM,
            pd.valeur_paramdec  as VAL_PARAM,
            pa.libelle_paramapp as LIB_PARAM
        from
            t_declenchements de,
            t_paramdec       pd,
            t_paramappli     pa
        where
            de.id_dec=n_IdExecTraitement
        and de.id_dec=pd.id_dec
        and de.id_app=pa.id_app
        and pd.ordre_paramdec=pa.ordre_paramapp
        and pa.type_paramapp not in ('DOWN')
        order by
            pd.ordre_paramdec asc
        )
        LOOP

            -- Construire le texte a afficher pour le parametre courant
            s_TexteParam:='';
            s_TexteParam:='parametre ' ||
                          '['||trim(to_char(vcur_ParamCour.NUM_PARAM,'9900'))||'] : '||
                          '['||nvl(vcur_ParamCour.VAL_PARAM,'<NON RENSEIGNE>')||']';

            IF length(s_TexteParam)>n_TAILLE_MAX_AFFICHAGE THEN
                n_TailleAffichage:=length(s_TexteParam);
            ELSE
                n_TailleAffichage:=n_TAILLE_MAX_AFFICHAGE;
            END IF;

            s_TexteParam:=rpad(s_TexteParam,n_TailleAffichage);
            s_TexteParam:=s_TexteParam||' <== '||trim(vcur_ParamCour.LIB_PARAM);

            -- Afficher les donnees du parametre courant
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_TRT,
                            s_TexteParam,
                            0,
                            s_FONCTION
                            );

        END LOOP;

    END AfficherParam;

    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_TRT,
                    '*******************************************************',
                    0,
                    s_FONCTION
                    );

    -- -------------------------------------------------------------------
    -- MEMORISER LES INFORMATIONS SUR LA CHAINE DE TRAITEMENTS
    -- -------------------------------------------------------------------

    -- Vider les informations correspondant a la precedente execution
    -- de la chaine de traitements
    IF F_PURGER_INFO(t_InfoTrait)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;
   /* IF PKG_TEC_FICHIERS.F_ECRIRE_FICHIER(
                                        t_InfoTrait,
                                        s_NomChaine||'.info',
                                        'DIR_TEMP',
                                        'InfoTrait;'||t_InfoTrait,
                                        'W'
                                        ) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF; */

    -- Memoriser l'InfoTrait
    IF F_MAJ_INFO(t_InfoTrait, 'InfoTrait', t_InfoTrait)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;
    /*IF F_MAJ_FIC_INFO(t_InfoTrait, 'InfoTrait', t_InfoTrait)
       <> PKG_GLOBAL.gn_CR_OK THEN
       ROLLBACK;
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF; */

    -- Memoriser l'identifiant d'application (ou de chaine de traitements)
    IF F_MAJ_INFO(t_InfoTrait, 'IdAPP', s_IDApp)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;
   /* IF F_MAJ_FIC_INFO(t_InfoTrait, 'IdAPP', s_IDApp)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF; */

    -- Memoriser la liste des mails des destinataires
    -- des compte-rendus d'execution de la chaine de traitements
    IF F_MAJ_INFO(t_InfoTrait, 'ListeEmail', s_ListeMail)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;
   /* IF F_MAJ_FIC_INFO(t_InfoTrait, 'ListeEmail', s_ListeMail)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;*/

    -- Memoriser la liste des parametres du traitement
    -- A FAIRE : BLOC DE CODE A METTRE DANS UNE FONCTION SEPAREE
    <<MemoriserParam>>
    DECLARE

        -- Texte pour le numero du parametre
        s_TexteNumParam VARCHAR2(255):='';

        -- Texte pour la valeur du parametre
        s_TexteValParam VARCHAR2(255):='';

    BEGIN

        -- Pour chacun des parametres du traitement
        FOR vcur_ParamCour IN
        (
        select
            pd.ordre_paramdec   as NUM_PARAM,
            pd.valeur_paramdec  as VAL_PARAM,
            pa.libelle_paramapp as LIB_PARAM
        from
            t_declenchements de,
            t_paramdec       pd,
            t_paramappli     pa
        where
            de.id_dec=n_IdExecTraitement
        and de.id_dec=pd.id_dec
        and de.id_app=pa.id_app
        and pd.ordre_paramdec=pa.ordre_paramapp
        and pa.type_paramapp not in ('DOWN','Fichier')
        order by
            pd.ordre_paramdec asc
        )
        LOOP

            -- Construire le texte a afficher pour le numero du parametre courant
            s_TexteNumParam:='';
            s_TexteNumParam:='Param_'||trim(to_char(vcur_ParamCour.NUM_PARAM));

            -- Construire le texte a afficher pour le parametre courant
            s_TexteValParam:='';
            s_TexteValParam:=nvl(vcur_ParamCour.VAL_PARAM,'');

           -- Memoriser le parametre courant
           IF F_MAJ_INFO(t_InfoTrait, s_TexteNumParam, s_TexteValParam)
              <> PKG_GLOBAL.gn_CR_OK THEN
               RETURN PKG_GLOBAL.gn_CR_KO;
           END IF;
 /*          IF F_MAJ_FIC_INFO(t_InfoTrait, s_TexteNumParam, s_TexteValParam)
              <> PKG_GLOBAL.gn_CR_OK THEN
               RETURN PKG_GLOBAL.gn_CR_KO;
           END IF;
*/
        END LOOP;

    END MemoriserParam;

    -- -------------------------------------------------------------------
    -- METTRE A JOUR L'HEURE DE DEBUT D'EXECUTION DE LA CHAINE
    -- DE TRAITEMENTS
    -- -------------------------------------------------------------------

    -- Ecriture de la date/heure de debut du traitement
    IF F_SET_DATE_DEB(t_InfoTrait) <> PKG_GLOBAL.gn_CR_OK THEN
       ROLLBACK;
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Valider la transaction
    COMMIT;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        ROLLBACK;
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_DEBUT_CHAINE;

-- =======================================================================
-- # PROCEDURE    : F_FIN_CHAINE
-- # DESCRIPTION  : Cloture du traitement d'une chaine
-- # PARAMETRES   : t_InfoTrait : Informations generales sur le traitement en cours
-- #              : s_Resultat  : resultat de la chaine (OK ou KO)
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 28/09/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_FIN_CHAINE(
                        t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                        s_Resultat  IN VARCHAR2
                       )
                        RETURN NUMBER
IS
    -- Transaction autonome
    --PRAGMA AUTONOMOUS_TRANSACTION;

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_FIN_CHAINE';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Nom de la chaine a executer
    s_NomChaine VARCHAR2(64) := '';

    -- Message d'erreur remonte par la procedure de controle de t_InfoTrait
    s_MsgErreur VARCHAR(512) := '';

    -- Date de fin de traitement au format AAAA/MM/DD HH:MI:SS
    s_DateFinTrait VARCHAR(19) := '';

    --Requete
    s_ReqSql VARCHAR2(2000) := '';

    --Identifiant execution
    s_IDdec VARCHAR2(15) := '';

    --Statut traitement
    s_Statut VARCHAR2(4) := '';

BEGIN

    -- REMARQUE : L'objectif de cette fonction est de tracer le maximum
    --            d'informations dans la table de log et dans un fichier
    --            de compte-rendu d'execution et de mettre ce fichier
    --            a disposition de l'utilisateur en le chargeant dans DTC
    --            (Table T_GENFICHIER)
    --            En consequence, toutes les erreurs detectees
    --            dans cette fonction sont tracees au maximum
    --            mais ne provoquent pas l'interruption du traitement
    --            Dans tous les cas, on COMMIT a la fin pour essayer
    --            d'enregistrer le maximum d'information dans la base
    --            dont au minimum le resultat du traitement et son heure de fin

    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------
    n_CodeRet := PKG_GLOBAL.F_CTRL_INFO_TRAIT(t_InfoTrait, s_MsgErreur);
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         s_MsgErreur,
                         n_CodeRet,
                         s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- ECRIRE LE RESULTAT DU TRAITEMENT ET SA DATE DE FIN
    -- -------------------------------------------------------------------

    -- Ecriture de la date/heure de fin du traitement
    n_CodeRet := F_SET_DATE_FIN(t_InfoTrait);
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'Erreur lors de l''ecriture de la date/heure de fin de chaine de traitements',
                         PKG_GLOBAL.gn_CR_KO,
                         s_FONCTION);
    END IF;

    -- Ecriture du statut de fin d'execution du traitement
    n_CodeRet := F_SET_RESULTAT_TRAIT(t_InfoTrait, s_Resultat);
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'Erreur lors de l''ecriture du statut de fin d''execution de la chaine de traitements',
                         PKG_GLOBAL.gn_CR_KO,
                         s_FONCTION);
    END IF;

    -- -------------------------------------------------------------------
    -- PURGER LE CLOB GENERE
    -- -------------------------------------------------------------------
    n_CodeRet := pkg_global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,s_IDdec);

s_ReqSql:=
            'SELECT STATUT '                                                                || CHR(10) ||
            '  FROM T_DECLENCHEMENTS '                                                      || CHR(10) ||
            'WHERE '                                                                        || CHR(10) ||
            '    ID_DEC = '''||trim(s_IDdec)||''''
            ;

        -- Tracer la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : [' || s_ReqSql ||']',
                        0,
                        s_FONCTION);

        -- Executer la requete
        EXECUTE IMMEDIATE s_ReqSql into s_Statut;

    if s_Statut = 'OK' then

    -- On purge la table de CLOB de travail afin de ne pas saturer la base
        BEGIN

            -- On supprime les CLOB de travail pour les traitements au statut OK
            -- et les traitements datant de plus de 20 jours quels que soient leurs statuts
            s_ReqSql := 'delete from TA_CLOB '||
                        'where id_dec in (select id_dec from v_dtc_declenchement '||
                                               'where id_dec like '''||SUBSTR(s_IDdec,1,3)||'_%'' ' ||
                                               'and (cd_statut = ''OK'' or dt_deb+20 <= sysdate))';

            EXECUTE IMMEDIATE s_ReqSql;

        EXCEPTION

        WHEN OTHERS THEN
            ROLLBACK;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'Erreur lors de la purge de la table de CLOB : '|| SQLERRM,
                         PKG_GLOBAL.gn_CR_KO,
                         s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;
        END;

    -- On purge la table de ligne de fichier afin de ne pas saturer la base
        BEGIN

            -- On supprime les lignes de fichier pour les traitements au statut OK
            -- et les traitements datant de plus de 20 jours quels que soient leurs statuts
            s_ReqSql:='delete from v_dtc_param_dec_file_ligne '||
                      'where id_param_dec in (select id_param_dec from v_dtc_declenchement d, v_dtc_param_dec p '||
                                             'where p.id_dec = d.id_dec '||
                                             'and d.id_dec like '''||SUBSTR(s_IDdec,1,3)||'_%'' ' ||
                                             'and (cd_statut = ''OK'' or dt_deb+20 <= sysdate))';

            -- Tracer la requete
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'REQUETE : [' || s_ReqSql ||']',
                            PKG_GLOBAL.gn_CR_OK,
                            s_FONCTION);

            -- Executer la requete
            EXECUTE IMMEDIATE s_ReqSql;

        EXCEPTION
            -- Erreurs non gerees
        WHEN OTHERS THEN
            ROLLBACK;
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ERR,
                            'Erreur lors de la purge de la table de ligne de fichier : '|| SQLERRM,
                            PKG_GLOBAL.gn_CR_KO,
                            s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;
        END;

    END IF;


        -- Tracer le resultat du traitement
        /*
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_RES,
                         'Resultat du traitement : ' ||
                         NVL(s_ResultatTrait,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);
        */
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_RES,
                        '*******************************************************',
                        0,
                        s_FONCTION
                        );
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_RES,
                        '** PURGE DU CLOB DU TRAITEMENT  ',
                        0,
                        s_FONCTION
                        );
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_RES,
                        '*******************************************************',
                        0,
                        s_FONCTION
                        );




    -- -------------------------------------------------------------------
    -- TRACER LA FIN DE LA CHAINE DE TRAITEMENTS
    -- -------------------------------------------------------------------

    -- Recuperation du nom du traitement a lancer
    IF PKG_GLOBAL.F_GET_NOM_CHAINE(t_InfoTrait, s_NomChaine) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Tracer la fin du traitement
    PKG_LOG.P_ECRIRE(t_InfoTrait,
                     PKG_LOG.gt_LOG_TYPE_FIN,
                     '==> FIN DE LA CHAINE DE TRAITEMENTS ['||s_NomChaine||']',
                     NULL,
                     s_FONCTION);



/*
    -- -------------------------------------------------------------------
    -- FICHIER DE COMPTE-RENDU D'EXECUTION
    -- -------------------------------------------------------------------

    -- Initialisation des types de message log a tracer
    n_CodeRet := PKG_LOG.F_INI_LST_TYPE_MSG_LOG(t_InfoTrait);
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'Erreur lors de l''initialisation des types de message log a tracer',
                         PKG_GLOBAL.gn_CR_KO,
                         s_FONCTION);
    END IF;

    -- Generation du compte rendu d'execution
    n_CodeRet := PKG_LOG.F_EXT_CRE(t_InfoTrait,s_RepCre_Param, s_NomFicCre);
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'Erreur lors de l''extraction du compte rendu d''execution',
                         PKG_GLOBAL.gn_CR_KO,
                         s_FONCTION);
    END IF;

    -- -------------------------------------------------------------------
    -- FICHIER A CHARGER DANS DTC
    -- -------------------------------------------------------------------

    -- Chargement dans T_GENFICHIER
    -- Si le traitement ne genere pas de fichier a recuperer dans DTC
    -- c'est le fichier '*.cre' qui est charge dans T_GENFICHIER
    -- Sinon on charge le fichier genere par le traitement
    IF ((s_NomFicDTC IS NULL) OR (TRIM(s_NomFicDTC) = '')) THEN
       n_CodeRet := F_CHARGER_GENFICHIER(t_InfoTrait, s_RepCre_Param, s_NomFicCre);
    ELSE
       n_CodeRet := F_CHARGER_GENFICHIER(t_InfoTrait, s_RepDTC_Param, s_NomFicDTC);
    END IF;
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'Erreur lors du chargement des parametres de sortie de DTC (Table T_GENFICHIER)',
                         PKG_GLOBAL.gn_CR_KO,
                         s_FONCTION);
    END IF;

   */
    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Validation de la transaction
    COMMIT;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        ROLLBACK;
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_FIN_CHAINE;

-- =======================================================================
-- # PROCEDURE    : F_SET_RESULTAT_TRAIT
-- # DESCRIPTION  : Ecrire la resultat d'un traitement
-- #                a partir de son identifiant de declenchement
-- # PARAMETRES   :
-- #   + pn_IdDec         : Identifiant de declenchement
-- #   + ps_ResultatTrait : Resultat du traitement
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 28/09/2006 |           | DVA    | Creation
-- # 1.0     | 18/08/2008 |           | DVA    | Gerer Code retour + libelle
-- =======================================================================
FUNCTION F_SET_RESULTAT_TRAIT(
                              t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                              s_ResultatTrait IN VARCHAR2
                             )
                             RETURN NUMBER
IS
    -- Transaction autonome
    --PRAGMA AUTONOMOUS_TRANSACTION;

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_SET_RESULTAT_TRAIT';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement ou d'execution
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(4000) :='';

    -- Libelle du statut (ou resultat) du traitement DTC
    s_LibStatut VARCHAR2(64) :='';

BEGIN

    -- Lire l'identifiant d'execution dans les informations
    -- du traitement en cours
    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- <MODIF> DVA - 17/10/2008 - 1.01
    --         Controler les valeurs du resultat a partir de la table T_STATUT
    --         et plus de maniere statique en dur
    --         tout en recherchant le libelle du resultat du traitement


    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------

    --<<ControlParam>>
    --BEGIN

    --    -- Controler la validite du resultat du traitement passe en parametre
    --  IF UPPER(TRIM(s_ResultatTrait)) NOT IN (gt_RESULTAT_TRAIT_OK,
    --                                          gt_RESULTAT_TRAIT_KO,
    --                                          gt_RESULTAT_TRAIT_ERR_CODA)
    --  THEN
    --      --ROLLBACK;
    --      n_CodeRet:=3;
    --      PKG_LOG.P_ECRIRE(t_InfoTrait,
    --                       PKG_LOG.gt_LOG_TYPE_ERR,
    --                       'La valeur [' ||
    --                       UPPER(TRIM(s_ResultatTrait)) ||
    --                       '] n''est pas un resultat de traitement valide !',
    --                       n_CodeRet,
    --                       s_FONCTION);
    --      RETURN PKG_GLOBAL.gn_CR_KO;
    --  END IF;

    --END ControlParam;

    -- -------------------------------------------------------------------
    -- RECHERCHER LE LIBELLE DU RESULTAT A PARTIR DE SON CODE EN PARAMETRE
    -- -------------------------------------------------------------------

    <<RechercherLibResultat>>
    BEGIN

        -- Tracer l'objet de la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : Rechercher le libelle du resultat du traitement '||
                        'a partir du code resultat ['||s_ResultatTrait||']',
                        0,
                        s_FONCTION
                        );

        -- Construire la requete
        s_ReqSql:=
            'SELECT '                  || CHR(10) ||
            '    LB_STATUT'            || CHR(10) ||
            'FROM '                    || CHR(10) ||
        '    T_STATUT '                || CHR(10) ||
            'WHERE '                   || CHR(10) ||
            '    CD_STATUT='''||trim(s_ResultatTrait)||''''
            ;

        -- Tracer la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : [' || s_ReqSql || ']',
                        0,
                        s_FONCTION);

        -- executer la requete
        EXECUTE IMMEDIATE s_ReqSql INTO s_LibStatut;

        -- Tracer le nombre de lignes retournees/impactees par la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE (SELECT) : ' ||
                        SQL%ROWCOUNT || ' lignes selectionnees',
                        SQL%ROWCOUNT,
                        s_FONCTION
                        );

        -- Tracer l'information retournee par la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'libelle du resultat du traitement : [' || s_LibStatut || ']',
                        0,
                        s_FONCTION
                        );

    EXCEPTION

        -- Erreurs non gerees
        WHEN others THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ALR,
                             'CODE RESULTAT ['||s_ResultatTrait||'] NON GERE !',
                             100,
                             s_FONCTION);
            -- Initialiser le libelle a une valeur par defaut
            s_LibStatut:='KO                    => VOIR COMPTE-RENDU';

    END RechercherLibResultat;

    -- </MODIF>

    -- -------------------------------------------------------------------
    -- ECRITURE DU RESULTAT DU TRAITEMENT
    -- A PARTIR DE SON IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<EcritureResultatTrait>>
    BEGIN

       -- <MODIF> DVA - 17/10/2008 - 1.01
       --         Utiliser le libelle correspondant au code resultat
       --         pour mettre a jour la table T_DECLENCHEMENTS
       --         au lieu d'utiliser le code resultat directement

        /*
        -- Mettre a jour le resultat du traitement
        s_ReqSql:=
            'UPDATE '                                          ||
            '    T_DECLENCHEMENTS '                            ||
            'SET '                                             ||
            '    STATUT = :s_ResultatTrait '                   ||
            'WHERE '                                           ||
            '    ID_DEC = :n_IdDec';

        EXECUTE IMMEDIATE s_ReqSql USING s_ResultatTrait, n_IdDec;
        */

        -- Mettre a jour le resultat du traitement
       /* RLE
            s_ReqSql:=
            'UPDATE '                                          || CHR(10) ||
            '     T_DECLENCHEMENTS '                            || CHR(10) || RLE
            'SET '                                             || CHR(10) ||
            '    STATUT      = '''||s_LibStatut    ||''', '    || CHR(10) ||
            '    CODE_RETOUR = '''||s_ResultatTrait||'''  '    || CHR(10) ||
            'WHERE '                                           || CHR(10) ||
            '    ID_DEC = '||to_char(n_IdDec);
        */

        s_ReqSql:=
            'UPDATE '                                                                       || CHR(10) ||
            '    V_DTC_DECLENCHEMENT '                                                      || CHR(10) ||
            'SET '                                                                          || CHR(10) ||
            'CD_STATUT=(select CD_STATUT_IHM from T_STATUT where CD_STATUT = :CD_STATUT) '  || CHR(10) ||
            'WHERE '                                                                        || CHR(10) ||
            '    ID_DEC = '''          || to_char(n_IdDec) || '''';

        -- Tracer la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : [' || s_ReqSql ||']',
                        0,
                        s_FONCTION);

        -- Executer la requete
        EXECUTE IMMEDIATE s_ReqSql using s_ResultatTrait;

        -- Tracer le nombre de lignes traitees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Ecriture du resultat du traitement (UPDATE) : ' ||
                         SQL%ROWCOUNT || ' lignes mises a jour',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le resultat du traitement
        /*
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_RES,
                         'Resultat du traitement : ' ||
                         NVL(s_ResultatTrait,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);
        */
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_RES,
                        '*******************************************************',
                        0,
                        s_FONCTION
                        );
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_RES,
                        '** RESULTAT DE LA CHAINE DE TRAITEMENTS : ' ||
                        '['||nvl(s_LibStatut,'<NON RENSEIGNE>')||'] '||
                        '(CR=['||s_ResultatTrait||'])',
                        0,
                        s_FONCTION
                        );
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_RES,
                        '*******************************************************',
                        0,
                        s_FONCTION
                        );

        -- </MODIF>

      EXCEPTION

        -- Echec de la recherche de l'identifiant d'execution du traitement
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=4;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'IDENTIFIANT D''EXECUTION DU TRAITEMENT '||
                             '['||to_char(n_IdDec)||'] INCONNU !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END EcritureResultatTrait;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_SET_RESULTAT_TRAIT;


-- =======================================================================
-- # PROCEDURE    : F_EXE_TRAITEMENT
-- # DESCRIPTION  : Executer un traitement fonctionnel
-- #                a partir du nom du traitement a executer
-- #                et de l'identifiant de declenchement du traitement
-- #                Le traitement est materialise par une fonction stockee
-- #                denommee systematiquement RUN
-- #                contenu dans un package denomme obligatoirement
-- #                PKG_<Nom traitement>
-- #                La fonction RUN doit obligatoirement avoir
-- #                comme premier parametre l'InfoTrait
-- #                (les informations generales sur le traitement en cours)
-- #                du traitement. Les parametres suivants doivent
-- #                correspondrent aux parametres du traitements
-- #                tels que saisis dans DTC et dans le meme ordre
-- #                que dans l'ecran
-- # PARAMETRES   : t_InfoTrait : informations generales
-- #                sur le traitement en cours
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.00    | 16/08/2006 |           | DVA    | Creation
-- # 1.01    | 08/08/2008 |           | DVA    | Modif gestion codes retour
-- #         |            |           |        | + Enreg infos dans T_INFO
-- =======================================================================
FUNCTION F_EXE_TRAITEMENT(
                          t_InfoTrait IN OUT PKG_GLOBAL.T_INFO_TRAITEMENT
                         )
                         RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_EXE_TRAITEMENT';

    -- Prefixe du nom du package contenant le traitement a executer
    s_PREFIXE_NOM_PACKAGE_TRAIT CONSTANT VARCHAR2(4):='PKG_';

    -- Nom de la fonction stockee point d'entree du traitement a executer
    s_NOM_FONCTION_TRAIT CONSTANT VARCHAR2(25):='RUN';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER DEFAULT PKG_GLOBAL.gn_CR_KO;

    -- Code Retour package metier execute
    n_CodeRetPkgMetier NUMBER DEFAULT PKG_GLOBAL.gn_CR_KO;

    -- Nom du package contenant le traitement a executer
    s_NomPackageTrait VARCHAR2(25) :='';

    -- Nom complet (package.fonction) de la fonction stockee executee
    s_NomCompletFonction VARCHAR2(51):='';

    -- Liste des valeurs des parametres du traitement a executer
    s_ListeValParam VARCHAR2(2048):='';

    -- Commande complete d'appel de la fonction stockee a executer
    s_CmdeAppelFonction VARCHAR2(4096):='';

    -- Nom du traitement a executer
    s_NomTraitement VARCHAR2(64):='';

    -- Message d'erreur remonte par la procedure de controle de t_InfoTrait
    s_MsgErreur VARCHAR(512) := '';

BEGIN

    -- -------------------------------------------------------------------
    -- CONTROLE DES PARAMETRES
    -- -------------------------------------------------------------------
    n_CodeRet := PKG_GLOBAL.F_CTRL_INFO_TRAIT(t_InfoTrait, s_MsgErreur);
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ERR,
                            s_MsgErreur,
                            n_CodeRet,
                            s_FONCTION);
           RETURN PKG_GLOBAL.gn_CR_OK;
    END IF;

    -- -------------------------------------------------------------------
    -- TRACER ET AFFICHER LES INFORMATIONS SUR LE TRAITEMENT
    -- -------------------------------------------------------------------

    -- Initialisation des types de message log a tracer
    IF PKG_LOG.F_INI_LST_TYPE_MSG_LOG(t_InfoTrait) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recuperation du nom du traitement a lancer
    IF PKG_GLOBAL.F_GET_NOM_TRAITEMENT(t_InfoTrait, s_NomTraitement)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- ECRIRE LE RESULTAT PAR DEFAUT DU TRAITEMENT DANS LE FICHIER INFO
    -- -------------------------------------------------------------------

    -- Initialiser le code retour du package metier a KO par defaut
    n_CodeRetPkgMetier:=PKG_GLOBAL.gn_CR_KO;

    -- Stocker ce resultat par defaut dans le fichier INFO
 /*   IF F_MAJ_FIC_INFO(t_InfoTrait, 'CodeRetFonc', n_CodeRetPkgMetier)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;
*/
    -- <AJOUT> DVA - 18/08/08 - 1.01
    --         Enregistrement du code retour du package metier
    --         dans la table T_INFO dont la finalite est de remplacer
    --         le fichier INFO
    IF F_MAJ_INFO(t_InfoTrait, 'CodeRetFonc', n_CodeRetPkgMetier)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- </AJOUT>

    -- -------------------------------------------------------------------
    -- PREPARER LA COMMANDE D'EXECUTION DE LA FONCTION RUN DU PACKAGE METIER
    -- -------------------------------------------------------------------

    -- Construire le nom complet de la fonction a executer
    s_NomPackageTrait:=s_PREFIXE_NOM_PACKAGE_TRAIT || s_NomTraitement;
    s_NomCompletFonction:=s_NomPackageTrait || '.' || s_NOM_FONCTION_TRAIT;

    -- Construire la liste des parametres du traitement
    IF F_GET_LISTE_VAL_PARAM(t_InfoTrait, s_ListeValParam, TRUE) <> PKG_GLOBAL.gn_CR_OK THEN
        RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Construire la commande complete d'appel de la fonction
    s_CmdeAppelFonction:=
        'BEGIN '                                                     ||
        '    :x1 := ' || s_NomCompletFonction || '(' || s_ListeValParam || ')' || ';' ||
        'END;' ;

    -- Tracer la commande
    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_DBG,
                    'COMMANDE EXECUTION PACKAGE METIER : ' ||
                    '['||s_CmdeAppelFonction||']',
                    0,
                    s_FONCTION
                    );

-- <MODIF> DVA - 08/08/08 - 1.01
--         Modification de la gestion des codes retour
--         afin que la fonction ne retourne KO qu'en cas
--         de pb technique du package PKG_DTC
--         et pas dans le cas ou le package metier retourne KO
--         En bref, le code retour de la fonction ne doit pas dependre
--         du code retour du package metier execute

    -- -------------------------------------------------------------------
    -- EXECUTER LA FONCTION RUN DU PACKAGE METIER
    -- -------------------------------------------------------------------

    -- Marquer le debut du traitement
    PKG_LOG.P_ECRIRE(t_InfoTrait,
                     PKG_LOG.gt_LOG_TYPE_DEB,
                     '==> DEBUT TRAITEMENT ORACLE ['||s_NomTraitement||']',
                     0,
                     s_FONCTION);

    <<Exec_package_metier>>
    BEGIN

        -- executer la fonction stockee
        EXECUTE IMMEDIATE s_CmdeAppelFonction USING OUT n_CodeRetPkgMetier;

    EXCEPTION

        -- Erreurs non gerees
        WHEN others THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END Exec_package_metier;

    -- Tracer la fin du package metier
    PKG_LOG.P_ECRIRE(t_InfoTrait,
                     PKG_LOG.gt_LOG_TYPE_FIN,
                     '==> FIN TRAITEMENT ORACLE ' ||
                     '['||s_NomTraitement||'] ' ||
                     '- ' ||
                     'CR = ['|| to_char(n_CodeRetPkgMetier)||']',
                     n_CodeRetPkgMetier,
                     s_FONCTION);

    -- -------------------------------------------------------------------
    -- ECRIRE LE RESULTAT DU TRAITEMENT DANS LE FICHIER INFO
    -- -------------------------------------------------------------------
/*
    -- Stocker le resultat du traitement metier dans le fichier INFO
    IF F_MAJ_FIC_INFO(t_InfoTrait, 'CodeRetFonc', n_CodeRetPkgMetier)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;
*/
    -- <AJOUT> DVA - 18/08/08 - 1.01
    --         Enregistrement du code retour du package metier
    --         dans la table T_INFO dont la finalite est de remplacer
    --         le fichier INFO
    IF F_MAJ_INFO(t_InfoTrait, 'CodeRetFonc', n_CodeRetPkgMetier)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;
    -- </AJOUT>

    -- -------------------------------------------------------------------
    -- GERER LE CODE RETOUR DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Selon le code retour du package metier
    CASE n_CodeRetPkgMetier

        -- Succes de l'execution du package metier
        WHEN PKG_GLOBAL.gn_CR_OK THEN
            n_CodeRet:=PKG_GLOBAL.gn_CR_OK;

        -- Echec du package metier suite a un probleme technique
        WHEN PKG_GLOBAL.gn_CR_KO THEN
            n_CodeRet:=PKG_GLOBAL.gn_CR_KO;

        -- Echec du package metier suite a un probleme fonctionnel
        WHEN PKG_GLOBAL.gn_CR_KO_FCT THEN
            n_CodeRet:=PKG_GLOBAL.gn_CR_KO_FCT;

        -- Dans les autres cas
        ELSE

            -- Si le code retour est compris entre 1 et 200
            -- il s'agit d'un cas fonctionnel
            IF n_CodeRetPkgMetier BETWEEN 1 AND 200 THEN
                n_CodeRet:=PKG_GLOBAL.gn_CR_KO_FCT;
            -- Il s'agit code retour non gere
            ELSE
                n_CodeRet:=PKG_GLOBAL.gn_CR_KO;
            END IF;

    END CASE;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le resultat du traitement
    RETURN n_CodeRet;

-- </MODIF>


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_EXE_TRAITEMENT;

-- =======================================================================
-- # PROCEDURE    : F_LIRE_FIC_PARAM
-- # DESCRIPTION  : Lecture d'un parametre du fichier de parametres de declenchement
-- # PARAMETRES   :
-- #     + t_InfoTrait   : Informations generales sur le traitement en cours
-- #     + s_NomFicParam : Nom du fichier de parametres DTC
-- #     + s_RepFicParam : Repertoire du fichier de parametres DTC
-- #     + s_NomParam    : Nom du parametre dont on veut recuperer la valeur
-- #     + s_ValParam    : Valeur du parametre que l'on cherche a lire
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 18/08/2007 |           | DVA    | Creation
-- #         |            |           |        |
-- #         |            |           |        |
-- =======================================================================
FUNCTION F_LIRE_FIC_PARAM(
                          t_InfoTrait   IN            PKG_GLOBAL.T_INFO_TRAITEMENT,
                          s_NomFicParam IN            VARCHAR2,
                          s_RepFicParam IN            VARCHAR2,
                          s_NomParam    IN            VARCHAR2,
                          s_ValParam    IN OUT NOCOPY VARCHAR2
                         )
                         RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_LIRE_FIC_PARAM';

    -- Code retour
    n_CodeRet NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Taille maximun d'une ligne du fichier de parametres
    i_TAILLE_MAX_LIGNE CONSTANT PLS_INTEGER:=1024;

    -- Pointeurs de fichier
    l_Fichier   UTL_FILE.FILE_TYPE;

    -- Tampon de travail
    s_Ligne VARCHAR2(1024);

BEGIN

     -- LOG MIGRATION EXACC : Tracer appel UTL_FILE
     SP_LOG_FICHIER('PKG_DTC', 'F_LIRE_FIC_PARAM', s_NomFicParam, 'UTL_FILE.GET_LINE + FCLOSE');

     s_ValParam := NULL;

     -- Ouverture du fichier de parametres "<nom chaine>_*.dtc"
    BEGIN

        -- Ouvrir le fichier a charger
        n_CodeRet:=PKG_TEC_FICHIERS.F_OUVRIR_FICHIER(
                                                     t_InfoTrait,
                                                     UPPER(trim(s_RepFicParam)),
                                                     trim(s_NomFicParam),
                                                     'R',
                                                     i_TAILLE_MAX_LIGNE,
                                                     l_Fichier
                                                    );
        IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
            RETURN PKG_GLOBAL.gn_CR_KO;
        END IF;


    EXCEPTION
        WHEN OTHERS THEN
            PKG_LOG.P_AFFICHER(SQLERRM || ' [' || s_RepFicParam || '] -> ' || s_NomFicParam);
            RETURN PKG_GLOBAL.gn_CR_KO;
    END;

    -- Traitement
    BEGIN
        -- Lecture de la premiere ligne du fichier
        UTL_FILE.GET_LINE(l_Fichier, s_Ligne);

        -- Parcourir chaque ligne jusqu'a trouver le nom du parametre recherche
        WHILE INSTR(s_Ligne, s_NomParam||';') = 0 LOOP
              -- Lecture de la ligne suivante du fichier
              UTL_FILE.GET_LINE(l_Fichier, s_Ligne);
        END LOOP;

        -- On a trouve la ligne, on recupere la valeur du parametre
        s_ValParam := SUBSTR(s_Ligne,LENGTH(s_NomParam)+2);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN -- Fin du fichier en entree
            -- Fermeture du fichier
            UTL_FILE.FCLOSE(l_Fichier);
            -- Si s_ValParam est vide, le parametre s_NomParam n'existe pas dans le fichier INFO
            IF s_ValParam IS NULL THEN
                PKG_LOG.P_ECRIRE(t_InfoTrait,
                                 PKG_LOG.gt_LOG_TYPE_DBG,
                                 'Le parametre ['||s_NomParam||'] n''existe pas dans le fichier ['||s_RepFicParam||'/'||s_NomFicParam||'] !',
                                 1,
                                 s_FONCTION);
                RETURN 1;
            END IF;
    END;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
         PKG_LOG.P_ECRIRE(t_InfoTrait);
         RETURN PKG_GLOBAL.gn_CR_KO;
END F_LIRE_FIC_PARAM;

-- =======================================================================
-- # PROCEDURE    : F_CREER_DECLENCHEMENT
-- # DESCRIPTION  : Creer les enregistrements necessaires dans les tables T_DECLENCHEMENTS et T_PARAMDEC
-- #                Renvoyer l'id d'execution cree
-- # PARAMETRES   : s_NomTrait : Nom du traitement (script_app dans la table T_APPLICATIONS)
-- #                n_IdDec : Identifiant d'execution du traitement
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 31/10/2006 |           | JHI    | Creation
-- # 1.1     | 18/08/2007 |           | DVA    | Ajout de la gestion d'un fichier
-- #         |            |           |        | de parametres de declenchement
-- #         |            |           |        |
-- #         |            |           |        |
-- =======================================================================
FUNCTION F_CREER_DECLENCHEMENT(
                               t_InfoTrait   IN OUT PKG_GLOBAL.T_INFO_TRAITEMENT,
                               s_UserDec     IN VARCHAR2,
                               s_NomFicParam IN VARCHAR2 DEFAULT NULL,
                               s_RepFicParam IN VARCHAR2 DEFAULT 'DIR_TEMP'
                              )
                               RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_CREER_DECLENCHEMENT';

    -- Code retour
    n_CodeRet NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Nom de la chaine de traitements
    s_NomChaine VARCHAR2(64):='';

    -- Identifiant d'application
    n_IdApp NUMBER:=0;

    -- Identifianct de declenchement ou d'execution
    n_IdDec VARCHAR(12);

    -- Identifiant des parametres de declenchements
    n_SeqParamDec NUMBER(12):=0;

    -- No de ligne courante (boucle)
    i_NoLigneCour  PLS_INTEGER := 1;

    -- Nombre de parametre du traitement
    n_NbParam NUMBER:=0;

    -- No du parametre courant
    n_NoParam NUMBER:=0;

    -- Nom d'un parametre de declenchement
    -- dans le fichiers des parametres de declenchement
    s_NomParam VARCHAR2(128):='';

    -- Valeur d'un parametre de declenchement
    -- dans le fichiers des parametres de declenchement
    s_ValParam VARCHAR2(128):='';

    -- Requete Sql
    s_ReqSql VARCHAR2(1024):='';

BEGIN

    BEGIN
         -- Recuperation des numeros de sequence
         SELECT SEQ_ID_DEC.NEXTVAL INTO n_IdDec FROM dual;

    EXCEPTION

         WHEN OTHERS THEN
             -- Annuler la transaction
             ROLLBACK;
             -- Initialiser le buffer d'ecriture
             DBMS_OUTPUT.ENABLE(999999);
             -- Afficher le message d'erreur Oracle
             DBMS_OUTPUT.PUT_LINE(s_FONCTION||' : Erreur No '||TO_CHAR(SQLCODE)||' : '|| SQLERRM);
             -- Retourner l'echec du traitement
             RETURN PKG_GLOBAL.gn_CR_KO;
    END;

    -- Affectation de l'id de declenchement dans le t_InfoTrait
    IF PKG_GLOBAL.F_SET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       ROLLBACK;
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Lecture du nom de la chaine dans le t_InfoTrait
    IF PKG_GLOBAL.F_GET_NOM_CHAINE(t_InfoTrait, s_NomChaine) <> PKG_GLOBAL.gn_CR_OK THEN
       ROLLBACK;
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Mettre a jour le nom du traitement avec le nom generique
    -- du traitement de declenchement auto ou programme de chaine de traitements
    IF PKG_GLOBAL.F_SET_NOM_TRAITEMENT(t_InfoTrait, 'XXEXETRTDEC') <> PKG_GLOBAL.gn_CR_OK THEN
       ROLLBACK;
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recherche de l'identifiant de la chaine de traitements dans DTC
    <<RechercherIdApp>>
    BEGIN

        -- Rechercher le nom de l'application
        s_ReqSql:=
            'SELECT '                 ||
            '    A.ID_APP '           ||
            'FROM '                   ||
            '    T_APPLICATIONS   A ' ||
            'WHERE '                  ||
            '    A.SCRIPT_APP = '''   || s_NomChaine || '''';

        EXECUTE IMMEDIATE s_ReqSql INTO n_IdApp;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche de l''identifiant ' ||
                         'de la chaine de traitements ['||s_NomChaine||']' ||
                         '(SELECT) : ' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            n_CodeRet:=1;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'La chaine de traitements [' ||
                             s_NomChaine || '] n''a pas ete declaree dans DTC !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            ROLLBACK;
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END RechercherIdApp;

    -- Insertion des lignes nicessaires au declenchement dans T_DECLENCHEMENTS et T_PARAMDEC
    -- en fonction des valeurs par defaut de T_PARAMAPPLI pour le traitement passe en parametre
    <<CreerDeclenchement>>
    BEGIN

        -- Inserer un nouveau declenchement
        s_ReqSql:=
            'INSERT INTO T_DECLENCHEMENTS'                             ||
            '('                                                        ||
            '    ID_DEC, ID_APP, USER_DEC, DATE_DEC'                   ||
            ')'                                                        ||
            'VALUES'                                                   ||
            '('                                                        ||
             ''             || to_char(n_IdDec) || ''''','||n_IdApp||','''||s_UserDec||''', SYSDATE' ||
            ')';

        EXECUTE IMMEDIATE s_ReqSql;

        -- Tracer le nombre de lignes impactees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Creation d''un declenchement ' ||
                         'pour la chaine de traitements [' ||s_NomChaine||']' ||
                         '(INSERT) : ' ||
                         SQL%ROWCOUNT || ' lignes inserees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

    EXCEPTION
        -- Erreurs non gerees
        WHEN OTHERS THEN
            ROLLBACK;
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END CreerDeclenchement;

    -- Compter le nombre de parametres de la chaine de traitements
    -- (sont exclus les parametres de sortie de type DOWN)
    IF F_GET_NB_PARAM(t_InfoTrait, n_NbParam, TRUE) <> PKG_GLOBAL.gn_CR_OK THEN
        ROLLBACK;
        RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Si la chaine de traitement admet des parametres d'entree
    IF n_NbParam > 0 THEN

        -- -----------------------------------------------------------------
        -- MODIF DVA le 18/08/2007
        -- -----------------------------------------------------------------

        -- Si un nom de fichier de parametres de declenchement est renseigne
        IF trim(s_NomFicParam) IS NOT NULL THEN

            -- Remarque : le fichier de parametre doit respecter le format suivant :
            -- ------------------------
            -- Param_1;<valeur param 1>
            -- Param_2;<valeur param 2>
            -- ...
            -- Param_n;<valeur param n>
            -- ------------------------
            -- avec n=n_NbParam

            -- Pour chacun des parametres a lire
            FOR n_NoParam IN 1..n_NbParam LOOP

                -- Construire le nom du parametre
                s_NomParam:='Param_' || TO_CHAR(n_NoParam);

                -- Lire la valeur du parametre dans le fichier
                n_CodeRet:=F_LIRE_FIC_PARAM(
                                            t_InfoTrait,
                                            trim(s_NomFicParam),
                                            s_RepFicParam,
                                            s_NomParam,
                                            s_ValParam
                                           );
                IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
                    RETURN PKG_GLOBAL.gn_CR_KO;
                END IF;

                -- La valeur d'un parametre ne peut pas exceder 128 caracteres
                IF LENGTH(trim(s_ValParam))>128 THEN
                    PKG_LOG.P_ECRIRE(t_InfoTrait,
                                     PKG_LOG.gt_LOG_TYPE_ERR,
                                     'La valeur du parametre No ['||TO_CHAR(n_NoParam)||'] ' ||
                                     'de la chaine ['||s_NomChaine||']'||
                                     'est superieure a 128 caracteres (max autorise) : ' ||
                                     '['||trim(s_ValParam)||'] ' ||
                                     '(soit ['||TO_CHAR(LENGTH(trim(s_ValParam)))||'] caracteres)',
                                     11,
                                     s_FONCTION);
                    RETURN PKG_GLOBAL.gn_CR_KO;
                END IF;

                -- Renseigner la table des parametres de declenchement
                -- avec la valeur lue dans le fichier
                <<InsertParamDec>>
                BEGIN

                    -- Construire la requete
                    s_ReqSql:=
                        'INSERT INTO T_PARAMDEC'                                ||
                        '(ID_PARAMDEC,ID_DEC,VALEUR_PARAMDEC,ORDRE_PARAMDEC)'   ||
                        'VALUES '                                               ||
                        '(' ||
                        'SEQ_ID_PARAMDEC.NEXTVAL,' ||
                        to_char(n_IdDec) ||',' ||
                        '''' || trim(s_ValParam) || ''',' ||
                        to_char(n_NoParam) ||
                        ')'
                        ;

                    -- executer la requete
                    EXECUTE IMMEDIATE s_ReqSql;

                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK;
                        PKG_LOG.P_ECRIRE(t_InfoTrait);
                        PKG_LOG.P_ECRIRE(t_InfoTrait,
                                         PKG_LOG.gt_LOG_TYPE_ERR,
                                         s_ReqSql,
                                         SQLCODE,
                                         s_FONCTION);
                        PKG_LOG.P_ECRIRE(t_InfoTrait,
                                         PKG_LOG.gt_LOG_TYPE_ERR,
                                         'Echec de l''enregistrement du parametre No ['||TO_CHAR(n_NoParam)||'] ' ||
                                         'de la chaine ['||s_NomChaine||'] : '||
                                         '['||trim(s_ValParam)||'] ',
                                         12,
                                         s_FONCTION);
                        RETURN PKG_GLOBAL.gn_CR_KO;
                END InsertParamDec;

            END LOOP;   -- Fin lecture des parametres dans le fichier des parametres

        -- En l'absence de fichier de parametres,
        -- prendre les valeur du champ T_PARAMAPPLI.BATCH_PARAMAPPLI
        ELSE

            <<CreerParamFromBatchParamappli>>
            BEGIN

                -- Inserer les parametres de declenchement de la chaine
                   s_ReqSql:=
                    'INSERT INTO T_PARAMDEC'                                ||
                    '    SELECT '                                           ||
                    '        SEQ_ID_PARAMDEC.NEXTVAL,'                      ||
                    '        '|| to_char(n_IdDec) ||','                     ||
                    '        BATCH_PARAMAPPLI, '                            ||
                    '        ORDRE_PARAMAPP'                                ||
                    '    FROM   '                                           ||
                    '        T_APPLICATIONS A, '                            ||
                    '        T_PARAMAPPLI   P  '                            ||
                    '    WHERE  '                                           ||
                    '        SCRIPT_APP = '''||s_NomChaine||''''            ||
                    '    AND P.ID_APP   = A.ID_APP'                         ||
                    '    AND P.TYPE_PARAMAPP NOT IN (''DOWN'', ''Fichier'')  ';

                EXECUTE IMMEDIATE s_ReqSql;

                -- Tracer le nombre de lignes impactees par la requete
                -- Remarque : le nombre de lignes est stocke en tant que code exception
                --            pour les messages de type 'compteur'
                PKG_LOG.P_ECRIRE(t_InfoTrait,
                                 PKG_LOG.gt_LOG_TYPE_DBG,
                                 'Creation des parametres de declenchement ' ||
                                 'pour la chaine de traitements [' ||s_NomChaine||']' ||
                                 '(INSERT) : ' ||
                                 SQL%ROWCOUNT || ' lignes inserees',
                                 SQL%ROWCOUNT,
                                 s_FONCTION);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    ROLLBACK;
                    n_CodeRet:=2;
                    PKG_LOG.P_ECRIRE(t_InfoTrait,
                                     PKG_LOG.gt_LOG_TYPE_ERR,
                                     'La chaine de traitements [' ||
                                     s_NomChaine || '] n''a pas ete declaree dans DTC !',
                                     n_CodeRet,
                                     s_FONCTION);
                    PKG_LOG.P_ECRIRE(t_InfoTrait,
                                     PKG_LOG.gt_LOG_TYPE_DBG,
                                     s_ReqSql,
                                     n_CodeRet,
                                     s_FONCTION);
                    RETURN PKG_GLOBAL.gn_CR_KO;

                -- Erreurs non gerees
                WHEN OTHERS THEN
                    ROLLBACK;
                    PKG_LOG.P_ECRIRE(t_InfoTrait);
                    PKG_LOG.P_ECRIRE(t_InfoTrait,
                                     PKG_LOG.gt_LOG_TYPE_DBG,
                                     s_ReqSql,
                                     SQLCODE,
                                     s_FONCTION);
                    RETURN PKG_GLOBAL.gn_CR_KO;

            END CreerParamFromBatchParamappli;

        END IF;
        -- -----------------------------------------------------------------
        -- FIN MODIF DVA le 18/08/2007
        -- -----------------------------------------------------------------

    END IF;

    -- Generation du fichier flag
    IF F_MAJ_FIC_FLAG(t_InfoTrait, n_IdDec, s_NomChaine) <> PKG_GLOBAL.gn_CR_OK THEN
       ROLLBACK;
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Validation de la transaction
    COMMIT;

    -- Afficher un message d'information
    PKG_LOG.P_ECRIRE(t_InfoTrait,
                     PKG_LOG.gt_LOG_TYPE_INF,
                     'Le declenchement automatique ou programme ' ||
                     'de la chaine [' || s_NomChaine || '] ' ||
                     'est execute sous le No ['|| TO_CHAR(n_IdDec) ||']',
                     0,
                     s_FONCTION);

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION

    WHEN OTHERS THEN

       -- Annuler la transaction
       ROLLBACK;

        -- Afficher le message d'erreur Oracle
        PKG_LOG.P_ECRIRE(t_InfoTrait);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_CREER_DECLENCHEMENT;

-- =======================================================================
-- # PROCEDURE    : F_GET_LISTE_VAL_PARAM
-- # DESCRIPTION  : Renvoyer la liste des parametres necessaires a l'execution du traitement
-- # PARAMETRES   : n_IdDec : Identifiant d'execution du traitement
-- #                s_ListeValParm : Liste des parametres separes par une virgule
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.00    | 31/10/2006 |           | JHI    | Creation
-- # 1.01    | 18/08/2008 |           | DVA    | Suppression Enreg dans fic info
-- =======================================================================
FUNCTION F_GET_LISTE_VAL_PARAM(
                               t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                               s_ListeValParam      IN OUT NOCOPY VARCHAR2,
                               b_Silence            IN            BOOLEAN DEFAULT TRUE
                               )
                                RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_CREER_DECLENCHEMENT';

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant d'execution du traitement
    n_IdDec VARCHAR(12);

    -- Nombre de parametres necessaire au traitement
    n_NbParam NUMBER;

    -- No de ligne courante (boucle)
    i_NoLigneCour  PLS_INTEGER := 1;

    -- Valeur du parametre en retour
    s_ValParam VARCHAR2(150);

    -- Type parametre
    s_TypeParam VARCHAR2(64);

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Calcul du nombre de parametres a concatener
    IF F_GET_NB_PARAM(t_InfoTrait, n_NbParam, b_Silence) <> PKG_GLOBAL.gn_CR_OK THEN

        -- Afficher le message d'erreur Oracle
        PKG_LOG.P_ECRIRE(t_InfoTrait);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

    END IF;

    -- <MODIF> DVA - 12/08/08 - 1.01
    --         Modification du type de message de log :
    --         INF => TRT
    --         En effet, le nombre de parametres de la chaine doit etre decrit
    --         dans son entete
    --         + precision de l'id de declenchement du traitement dans le message
    --         + conditionner l'affichage du message sur la valeur de b_Silence

    -- Tracer le nombre de parametres
    /*
    PKG_LOG.P_ECRIRE(t_InfoTrait,
                     PKG_LOG.gt_LOG_TYPE_INF,
                     'Nombre de parametres : ' || TO_CHAR(n_NbParam),
                     0,
                     s_FONCTION);
    */

    -- Si la fonction n'est pas appelee en mode silencieux
    if not b_Silence then

        -- Tracer le nombre de parametres
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_TRT,
                        'Nombre de parametres du traitement ' ||
                        'No ['||to_char(n_IdDec)||'] : ' ||
                        '['||to_char(n_NbParam)||']',
                        0,
                        s_FONCTION
                        );
    end if;

    -- </MODIF>

    -- Concatenation des parametres dans la variable passee en parametre

    -- Recuperer les informations generales du traitement en cours
    s_ListeValParam := ''''||t_InfoTrait||'''';

    -- Si le traitement a des parametres
    IF n_NbParam > 0 THEN

        -- Constituer la liste des valeurs des parametres necessaires au traitement
        FOR i_NoLigneCour IN 1..n_NbParam LOOP

            -- Lire le type du parametre
            IF F_GET_TYPE_PARAM(
                               t_InfoTrait,
                               i_NoLigneCour,
                               s_TypeParam,
                               b_Silence
                               ) <> PKG_GLOBAL.gn_CR_OK THEN

                -- Afficher le message d'erreur Oracle
                PKG_LOG.P_ECRIRE(t_InfoTrait);

                -- Retourner l'echec du traitement
                RETURN PKG_GLOBAL.gn_CR_KO;

            END IF;

            -- Ne pas prendre pas en compte les parametres de type DOWN ou FILE
            IF INSTR(s_EXCEPLOG,s_TypeParam,1)=0 THEN

                -- Lire la valeur du parametre
                IF F_GET_VAL_PARAM(
                                  t_InfoTrait,
                                  i_NoLigneCour,
                                  s_ValParam,
                                  b_Silence
                                  ) <> PKG_GLOBAL.gn_CR_OK THEN

                    -- Afficher le message d'erreur Oracle
                    PKG_LOG.P_ECRIRE(t_InfoTrait);

                    -- Retourner l'echec du traitement
                    RETURN PKG_GLOBAL.gn_CR_KO;

                END IF;

                -- <SUPPR> DVA - 18/08/08 - 1.01
                --         La fonction courante n'a pas vocation a enregistrer
                --         les parametres dans le fichier INFO mais juste
                --         d'en retourner la liste

                /*
                -- Stocker la valeur du parametre dans le fichier INFO
                IF F_MAJ_FIC_INFO(
                                 t_InfoTrait,
                                 'Param_'||to_char(i_NoLigneCour),
                                 replace(s_ValParam,'''','')
                                 ) <> PKG_GLOBAL.gn_CR_OK THEN
                    RETURN PKG_GLOBAL.gn_CR_KO;
                END IF;
                */

                -- </SUPPR>

                -- Gestion de l'apostrophe dans une chaine
                --(on ajoute 4 cotes pour pouvoir transferer l'info)..
--                IF SUBSTR(s_ValParam,1,1)='''' AND LENGTH(s_ValParam) > 3 THEN
--                    s_ValParam :=
--                        ''''||
--                        REPLACE(
--                               SUBSTR(s_ValParam, 2, LENGTH(s_ValParam)-2),
--                               '''',
--                               ''''''''''
--                               )||
--                        '''';
--                END IF;

s_ValParam := '' || s_ValParam || '';

                -- Ajouter le parametre courant a la liste des parametres
                s_ListeValParam := s_ListeValParam||','||s_ValParam;

            END IF;

        END LOOP;

    END IF;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        PKG_LOG.P_ECRIRE(t_InfoTrait);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_LISTE_VAL_PARAM;

-- =======================================================================
-- # PROCEDURE    : F_CHARGER_GENFICHIER
-- # DESCRIPTION  : Charge le contenu d'un fichier dans la table T_GENFICHIER
-- #                afin d'etre exploitable via l'interface DTC
-- # PARAMETRES   : n_IdDec       : Identifiant d'execution du traitement
-- #                s_CheminAcces : Chemin d'acces du fichier sur le serveur
-- #                s_NomFichier  : Nom du fichier a charger
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 07/11/2006 |           | JHI    | Creation
-- # 1.1     | 18/08/2007 |           | DVA    | Modif ouverture fichier
-- =======================================================================
FUNCTION F_CHARGER_GENFICHIER(
                              t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                              s_Dir          VARCHAR2,
                              s_FileName     VARCHAR2
                             )
                             RETURN NUMBER
IS

    -- TRANSACTION AUTONOME
    --PRAGMA AUTONOMOUS_TRANSACTION;

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_CHARGER_FICHIER';

    -- Code retour
    n_CodeRet NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Taille maximun d'une ligne dans la table T_GENFICHIER
    i_TAILLE_MAX_LIGNE CONSTANT PLS_INTEGER:=4000;

    -- No de ligne courante (boucle)
    i_NoLigne NUMBER := 1;

    -- Pointeurs de fichier
    l_Fichier   UTL_FILE.FILE_TYPE;

    -- Tampon de travail
    s_Ligne VARCHAR2(4000);

BEGIN

     -- LOG MIGRATION EXACC : Tracer appel UTL_FILE
     SP_LOG_FICHIER('PKG_DTC', 'F_CHARGER_GENFICHIER', s_FileName, 'UTL_FILE.GET_LINE + FCLOSE');

     -- Ouverture du fichier en entree
    <<OuvrirFichierCRE>>
    BEGIN

        -- --------------------------------------------------------------------
        -- MODIF DVA le 18/08/2007
        -- --------------------------------------------------------------------

        -- Ouvrir le fichier a charger
        n_CodeRet:=PKG_TEC_FICHIERS.F_OUVRIR_FICHIER(
                                                     t_InfoTrait,
                                                     UPPER(trim(s_Dir)),
                                                     trim(s_FileName),
                                                     'R',
                                                     i_TAILLE_MAX_LIGNE,
                                                     l_Fichier
                                                    );
        IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
            RETURN PKG_GLOBAL.gn_CR_KO;
        END IF;

        --l_Fichier := UTL_FILE.FOPEN(s_Dir, s_FileName, 'R', i_TAILLE_MAX_LIGNE) ;

        -- --------------------------------------------------------------------
        -- FIN MODIF DVA le 18/08/2007
        -- --------------------------------------------------------------------


    EXCEPTION
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, 'Ouverture fichier: '||s_Dir||'/'||s_FileName);
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            --PKG_LOG.P_AFFICHER(SQLERRM || ' [' || s_Dir || '] -> ' || s_FileName);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END OuvrirFichierCRE;

    -- Traitement
    <<ChargerTable>>
    BEGIN

        -- Purge de la table avant la nouvelle insertion
        IF F_VIDE_GENFICHIER(t_InfoTrait) <> PKG_GLOBAL.gn_CR_OK THEN
            ROLLBACK;
            RETURN PKG_GLOBAL.gn_CR_KO;
        END IF;
        --COMMIT;

        -- Pour chacune des lignes du fichier de compte-rendu
        LOOP
            -- Lire une ligne
            UTL_FILE.GET_LINE(l_Fichier, s_Ligne);

            -- Ecrire dans la table T_GENFICHIER
            IF F_ECRIRE_LIGNE_GENFICHIER(t_InfoTrait, i_NoLigne, s_Ligne) <> PKG_GLOBAL.gn_CR_OK THEN
                --ROLLBACK;
                RETURN PKG_GLOBAL.gn_CR_KO;
            END IF;

            -- Valider l'ecriture
            --COMMIT;

            -- Incrementer le compteur de lignes
            i_NoLigne := i_NoLigne + 1;

        END LOOP;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN -- Fin du fichier en entree
            IF UTL_FILE.IS_OPEN(l_Fichier) THEN
                UTL_FILE.FCLOSE(l_Fichier);
            END IF;
        WHEN OTHERS THEN
            --ROLLBACK;
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            IF UTL_FILE.IS_OPEN(l_Fichier) THEN
                UTL_FILE.FCLOSE(l_Fichier);
            END IF;
            RETURN PKG_GLOBAL.gn_CR_KO;

    END ChargerTable;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION

    WHEN OTHERS THEN
        --ROLLBACK;
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_CHARGER_GENFICHIER;

-- =======================================================================
-- # PROCEDURE    : F_ECRIRE_LIGNE_GENFICHIER
-- # DESCRIPTION  : Ecrit une ligne dans la table T_GENFICHIER
-- #                afin d'etre exploitable via l'interface DTC
-- # PARAMETRES   : n_IdDec    : Identifiant d'execution du traitement
-- #                s_NumLigne : numero de la ligne
-- #                s_Texte    : Texte
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 07/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_ECRIRE_LIGNE_GENFICHIER(
                             t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                             n_NumLigne   NUMBER,
                             s_Texte      VARCHAR2
                            )
                             RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_ECRIRE_LIGNE_GENFICHIER';

    -- Taille maximun d'une ligne dans la table T_GENFICHIER
    i_TAILLE_MAX_LIGNE CONSTANT PLS_INTEGER:=4000;

    -- Code retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Id application
    n_IdApp NUMBER;

    -- Identifiant de declenchement
    n_IdDec NUMBER;

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- controle des parametres en entree
    IF NVL(n_NumLigne,0)=0 THEN
       PKG_LOG.P_ECRIRE(t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'Numero de ligne ' ||
                        'non renseigne !',
                         n_CodeRet,
                         s_FONCTION);
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    IF s_Texte IS NULL THEN
       PKG_LOG.P_ECRIRE(t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'La zone texte est vide (ligne no : '||n_NumLigne||')',
                         n_CodeRet,
                         s_FONCTION);
       RETURN PKG_GLOBAL.gn_CR_KO;
    ELSE IF (LENGTH(s_Texte) > i_TAILLE_MAX_LIGNE) THEN
       PKG_LOG.P_ECRIRE(t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'La taille de la zone texte ne doit pas depasser '||i_TAILLE_MAX_LIGNE||' (ligne no : '||n_NumLigne||')',
                         n_CodeRet,
                         s_FONCTION);
       RETURN PKG_GLOBAL.gn_CR_KO;
       END IF;
    END IF;

    -- Recuperation de l'id d'application
    s_ReqSql:=
            'SELECT '               ||
            '    ID_APP '           ||
            'FROM '                 ||
            '    T_DECLENCHEMENTS ' ||
            'WHERE '                ||
            '    ID_DEC = :n_IdDec';

    EXECUTE IMMEDIATE s_ReqSql INTO n_IdApp USING n_IdDec;

    -- Insertion de la ligne dans la table
    s_ReqSql:=
            'INSERT INTO '                          ||
            '    T_GENFICHIER '                     ||
            'VALUES '                               ||
            '    (:n_IdApp, :n_NumLigne, :s_Texte)';

    EXECUTE IMMEDIATE s_ReqSql USING n_IdApp, n_NumLigne, s_Texte;

    --COMMIT;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        PKG_LOG.P_ECRIRE(t_InfoTrait);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_ECRIRE_LIGNE_GENFICHIER;

-- =======================================================================
-- # PROCEDURE    : F_GET_USER
-- # DESCRIPTION  : Lire l'id de l'utilisateur du traitement declenche
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   : n_IdDec    : Identifiant de declenchement
-- #                s_IdUser   : Id utilisateur du traitement declenche
-- #                s_RoleUser : Role utilisateur du traitemetn declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 09/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_GET_USER(
                      t_InfoTrait IN         PKG_GLOBAL.T_INFO_TRAITEMENT,
                      s_IdUser    OUT NOCOPY VARCHAR2,
                      b_Silence   IN         BOOLEAN DEFAULT FALSE
                    )
                    RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_USER';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

BEGIN

    -- Lire l'identifiant d'execution dans les informations du traitement en cours
    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- LECTURE DE L'ID DE L'UTILISATEUR DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<LectureIdUser>>
    BEGIN

        -- Initialiser l'id utilisateur du traitement
        s_IdUser:='';

        -- Rechercher l'id utilisateur du traitement
        s_ReqSql:=
            'SELECT '                  ||
            '    D.USER_DEC '          ||
            'FROM '                    ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    D.ID_DEC = '''          || to_char(n_IdDec) || '''';

        EXECUTE IMMEDIATE s_ReqSql INTO s_IdUser;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        IF NOT b_Silence THEN
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Recherche de l''id. utilisateur (SELECT) :' ||
                            SQL%ROWCOUNT || ' lignes selectionnees',
                            SQL%ROWCOUNT,
                            s_FONCTION);

           -- Tracer l'id utilisateur
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Id. Utilisateur : ' ||
                            NVL(s_IdUser,'<NON RENSEIGNE>'),
                            0,
                            s_FONCTION);
        END IF;

    EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureIdUser;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_USER;

-- =======================================================================
-- # PROCEDURE    : F_GET_USER_INFO
-- # DESCRIPTION  : Donne les informations concernant l'utilisateur
-- #                qui a declenche le traitement en cours a partir de son login
-- # PARAMETRES   :
-- #     + t_InfoTrait    : Informations sur le traitement en cours
-- #     + s_IdUser       : Login utilisateur qui a declenche le traitement
-- #     + s_UID          : Identifiant Annuaire de l'utilisateur
-- #     + s_LoginWindows : Login windows de l'utilisateur
-- #     + s_Nom          : Nom de l'utilisateur
-- #     + s_Prenom       : Prenom de l'utilisateur
-- #     + s_Mail         : adresse mail de l'utilisateur
-- #     + b_Silence      : Vrai : pas de traces - Faux : mode traces active
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 16/08/2007 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_GET_USER_INFO(
                         t_InfoTrait    IN         PKG_GLOBAL.T_INFO_TRAITEMENT,
                         s_IdUser       IN             VARCHAR2,
                         s_UID          IN OUT NOCOPY  VARCHAR2,
                         s_LoginWindows IN OUT NOCOPY  VARCHAR2,
                         s_Nom          IN OUT NOCOPY  VARCHAR2,
                         s_Prenom       IN OUT NOCOPY  VARCHAR2,
                         s_Mail         IN OUT NOCOPY  VARCHAR2,
                         b_Silence      IN             BOOLEAN DEFAULT TRUE
                        )
                        RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_USER_INFO';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

BEGIN

    -- Lire l'identifiant d'execution dans les informations du traitement en cours
    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- LECTURE DE L'ID DE L'UTILISATEUR DU TRAITEMENT
    -- A PARTIR DE L'IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<LectureInfoUser>>
    BEGIN

        -- Initialiser les variables
        s_UID:='';
        s_LoginWindows:='';
        s_Nom:='';
        s_Prenom:='';
        s_Mail:='';

        -- Rechercher l'id utilisateur du traitement
        s_ReqSql:=
            'SELECT '                  ||
            '    U.UID_ANNUAIRE, '     ||
            '    U.LOGIN_WINDOWS, '    ||
            '    U.NOM, '              ||
            '    U.PRENOM, '           ||
            '    U.MAIL '              ||
            'FROM '                    ||
            '    T_DTCUSER U  '        ||
            'WHERE '                   ||
            '    U.LOGIN = '''         || trim(s_IdUser)||'''';

        EXECUTE IMMEDIATE s_ReqSql INTO s_UID,s_LoginWindows,s_Nom,s_Prenom,s_Mail ;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        IF NOT b_Silence THEN
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Recherche des infos de l''utilisateur DTC (SELECT) :' ||
                            SQL%ROWCOUNT || ' lignes selectionnees',
                            SQL%ROWCOUNT,
                            s_FONCTION);

           -- Tracer l'id utilisateur
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Id Utilisateur : ' ||
                            NVL(s_IdUser,'<NON RENSEIGNE>'),
                            0,
                            s_FONCTION);
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'UID Annuaire : ' ||
                            NVL(s_UID,'<NON RENSEIGNE>'),
                            0,
                            s_FONCTION);
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Login Windows : ' ||
                            NVL(s_LoginWindows,'<NON RENSEIGNE>'),
                            0,
                            s_FONCTION);
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Nom : ' ||
                            NVL(s_Nom,'<NON RENSEIGNE>'),
                            0,
                            s_FONCTION);
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Prenom : ' ||
                            NVL(s_Nom,'<NON RENSEIGNE>'),
                            0,
                            s_FONCTION);
           PKG_LOG.P_ECRIRE(t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Mail : ' ||
                            NVL(s_Mail,'<NON RENSEIGNE>'),
                            0,
                            s_FONCTION);
        END IF;

    EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Login DTC [' || s_IdUser || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureInfoUser;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_USER_INFO;



-- =======================================================================
-- # PROCEDURE    : F_GET_DATE_DEC
-- # DESCRIPTION  : Lire la date de declenchement du traitement
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   : n_IdDec    : Identifiant de declenchement
-- #                d_DateDec  : Date de declenchement du traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 09/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_GET_DATE_DEC(
                      t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                      d_DateDec    OUT NOCOPY DATE
                     )
                     RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_DATE_DEC';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    <<LectureDateDec>>
    BEGIN

        -- Initialiser la date de declenchement du traitement
        d_DateDec:=NULL;

        -- Rechercher la date de declenchement du traitement
        s_ReqSql:=
            'SELECT '                  ||
            '    TO_DATE(D.DATE_DEC) ' ||
            'FROM '                    ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    D.ID_DEC = '''          || to_char(n_IdDec) || ''''
            ;

        EXECUTE IMMEDIATE s_ReqSql INTO d_DateDec;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche de la date de declenchement (SELECT) :' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer la date de declenchement
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Date de declenchement : ' ||
                         NVL(d_DateDec,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureDateDec;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_DATE_DEC;

-- =======================================================================
-- # PROCEDURE    : F_GET_DATE_DEb
-- # DESCRIPTION  : Lire la date de debut du traitement
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   : n_IdDec    : Identifiant de declenchement
-- #                d_DateDeb  : Date de debut du traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 09/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_GET_DATE_DEB(
                       t_InfoTrait  IN  PKG_GLOBAL.T_INFO_TRAITEMENT,
                       d_DateDeb    OUT NOCOPY DATE
                       )
                       RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_DATE_DEB';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    <<LectureDateDeb>>
    BEGIN

        -- Initialiser la date de debut du traitement
        d_DateDeb:=NULL;

        -- Rechercher la date de debut du traitement
        s_ReqSql:=
            'SELECT '                  ||
            '    TO_DATE(D.DATE_DEB) '          ||
            'FROM '                    ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    D.ID_DEC = '''          || to_char(n_IdDec) || '''';

        EXECUTE IMMEDIATE s_ReqSql INTO d_DateDeb;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche de la date de debut (SELECT) :' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer la date de debut
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Date de debut : ' ||
                         NVL(d_DateDeb,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureDateDeb;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_DATE_DEB;

-- =======================================================================
-- # PROCEDURE    : F_GET_DATE_FIN
-- # DESCRIPTION  : Lire la date de fin du traitement
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   : n_IdDec    : Identifiant de declenchement
-- #                d_DateFin  : Date de fin du traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 09/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_GET_DATE_FIN(
                      t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                      d_DateFin    OUT NOCOPY DATE
                     )
                     RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_DATE_FIN';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    <<LectureDateFin>>
    BEGIN

        -- Initialiser la date de fin du traitement
        d_DateFin:=NULL;

        -- Rechercher la date de fin du traitement
        s_ReqSql:=
            'SELECT '                  ||
            '    TO_DATE(D.DATE_FIN) '          ||
            'FROM '                    ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    D.ID_DEC = '''          || to_char(n_IdDec) || '''';

        EXECUTE IMMEDIATE s_ReqSql INTO d_DateFin;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche de la date de fin (SELECT) :' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer la date de fin
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Date de fin : ' ||
                         NVL(d_DateFin,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureDateFin;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_DATE_FIN;

-- =======================================================================
-- # PROCEDURE    : F_GET_STATUT
-- # DESCRIPTION  : Lire le statut du traitement
-- #                a partir de l'identifiant de declenchement
-- # PARAMETRES   : n_IdDec   : Identifiant de declenchement
-- #                s_Statut  : Statut du traitement declenche
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 09/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_GET_STATUT(
                      t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                      s_Statut    OUT NOCOPY  VARCHAR2
                     )
                     RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_STATUT';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    <<LectureStatut>>
    BEGIN

        -- Initialiser le statut du traitement
        s_Statut:='';

        -- Rechercher le statut du traitement
        s_ReqSql:=
            'SELECT '                  ||
            '    TO_DATE(D.STATUT) '          ||
            'FROM '                    ||
            '    T_DECLENCHEMENTS D  ' ||
            'WHERE '                   ||
            '    D.ID_DEC = '''          || to_char(n_IdDec) || '''';

        EXECUTE IMMEDIATE s_ReqSql INTO s_Statut;

        -- Tracer le nombre de lignes retournees par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Recherche du statut (SELECT) :' ||
                         SQL%ROWCOUNT || ' lignes selectionnees',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer le statut
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Statut : ' ||
                         NVL(s_Statut,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);

      EXCEPTION

        -- Identifiant de declenchement introuvable
        WHEN NO_DATA_FOUND THEN
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant de declenchement [' ||
                             to_char(n_IdDec) || '] introuvable !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END LectureStatut;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_STATUT;

-- =======================================================================
-- # PROCEDURE    : F_GET_LAST_EXE_OK
-- # DESCRIPTION  : recuperer les infos sur la derniere execution avec succes
-- #                d'un traitement donne a partir du nom du traitement
-- # PARAMETRES   : s_NomChaine : Nom de la chaine de traitement
-- #                n_IdDec    : Identifiant de declenchement
-- #                s_IdUser   : Id utilisateur
-- #                d_DateDec  : Date de declenchement
-- #                d_DateDeb  : Date de debut
-- #                d_DateFin  : Date de fin
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 13/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_GET_LAST_EXE_OK(
                           t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                           s_NomChaine IN VARCHAR2,
                           n_IdDec    OUT NOCOPY VARCHAR2,
                           s_IdUser   OUT NOCOPY VARCHAR2,
                           d_DateDec OUT NOCOPY DATE,
                           d_DateDeb  OUT NOCOPY DATE,
                           d_DateFin  OUT NOCOPY DATE
                          )
                          RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_LAST_EXE_OK';

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

BEGIN

     -- Si le nom de la chaine n'est pas renseigne
    IF s_NomChaine IS NULL OR TRIM(s_NomChaine) = '' THEN
       n_CodeRet:=1;
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_ERR,
                         'Nom de la chaine ' ||
                         'non renseigne !',
                         n_CodeRet,
                         s_FONCTION);
        RETURN n_CodeRet;
     END IF;

    SELECT
        D.ID_DEC,
        D.USER_DEC,
        D.DATE_DEC,
        D.DATE_DEB,
        D.DATE_FIN
    INTO
        n_IdDec,
        s_IdUser,
        d_DateDec,
        d_DateDeb,
        d_DateFin
    FROM
        T_APPLICATIONS    A,
        T_DECLENCHEMENTS D
    WHERE
        A.SCRIPT_APP = s_NomChaine
    AND A.ID_APP     = D.ID_APP
    AND D.STATUT     = gt_RESULTAT_TRAIT_OK
    AND D.DATE_FIN   = (SELECT MAX(DATE_FIN)
                        FROM   T_DECLENCHEMENTS T
                        WHERE  ID_APP = A.ID_APP );

    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
         n_CodeRet := 2;
         PKG_LOG.P_ECRIRE(t_InfoTrait,
                          PKG_LOG.gt_LOG_TYPE_ERR,
                          'La chaine ['||s_NomChaine||'] n''a jamais ete executee avec succes ou n''existe pas',
                          n_CodeRet,
                          s_FONCTION);
         RETURN n_CodeRet;
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_LAST_EXE_OK;

-- =======================================================================
-- # PROCEDURE    : F_ECRIRE_UNE_LIGNE_GENFIC
-- # DESCRIPTION  : Ecrit une seule ligne dans la table T_GENFICHIER avec
-- #                purge de la table avant l'insertion
-- #                afin d'etre exploitable via l'interface DTC
-- # PARAMETRES   : n_IdDec    : Identifiant d'execution du traitement
-- #                s_Texte    : Texte
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 07/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_ECRIRE_UNE_LIGNE_GENFIC(
                                  t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                                  s_Texte        VARCHAR2
                                  )
                                  RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_ECRIRE_UNE_LIGNE_GENFIC';

    -- Taille maximun d'une ligne dans la table T_GENFICHIER
    i_TAILLE_MAX_LIGNE CONSTANT PLS_INTEGER:=4000;

    -- Code retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Id application
    n_IdApp VARCHAR(12);

    -- Identifiant de declenchement
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Controle des parametres en entree
    IF NVL(n_IdDec,'0')='0' THEN
       PKG_LOG.P_ECRIRE(t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'Identifiant de declenchement ' ||
                        'non renseigne !',
                         n_CodeRet,
                         s_FONCTION);
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    IF s_Texte IS NULL THEN
       PKG_LOG.P_ECRIRE(t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'La zone texte est vide',
                         n_CodeRet,
                         s_FONCTION);
       RETURN PKG_GLOBAL.gn_CR_KO;
    ELSE IF (LENGTH(s_Texte) > i_TAILLE_MAX_LIGNE) THEN
       PKG_LOG.P_ECRIRE(t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'La taille de la zone texte ne doit pas depasser ' ||
                        '['||to_char(i_TAILLE_MAX_LIGNE)||'] caracteres !',
                         n_CodeRet,
                         s_FONCTION);
       RETURN PKG_GLOBAL.gn_CR_KO;
       END IF;
    END IF;

    -- Recuperation de l'id. d'application
    s_ReqSql:=
            'SELECT '               ||
            '    ID_APP '           ||
            'FROM '                 ||
            '    T_DECLENCHEMENTS ' ||
            'WHERE '                ||
            '    ID_DEC = :n_IdDec';

    EXECUTE IMMEDIATE s_ReqSql INTO n_IdApp USING n_IdDec;

    -- Purge de la table avant la nouvelle insertion
    IF F_VIDE_GENFICHIER(t_InfoTrait) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Insertion de la ligne dans la table
    s_ReqSql:=
            'INSERT INTO '                          ||
            '    T_GENFICHIER '                     ||
            'VALUES '                               ||
            '    (:n_IdApp, 1, :s_Texte)';

    EXECUTE IMMEDIATE s_ReqSql USING n_IdApp, s_Texte;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        PKG_LOG.P_ECRIRE(t_InfoTrait);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_ECRIRE_UNE_LIGNE_GENFIC;

-- =======================================================================
-- # PROCEDURE    : F_VIDE_GENFICHIER
-- # DESCRIPTION  : Purge de la table T_GENFICHIER pour une application donnee
-- # PARAMETRES   : n_IdDec    : Identifiant d'execution du traitement
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 07/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_VIDE_GENFICHIER(
                             t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT
                            )
                             RETURN NUMBER
IS
    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_VIDE_GENFICHIER';

    -- Code retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Id application
    n_IdApp NUMBER;

    -- Identifiant de declenchement
    n_IdDec NUMBER;

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

BEGIN

    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Controle des parametres en entree
    IF NVL(n_IdDec,0)=0 THEN
       PKG_LOG.P_ECRIRE(t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'Identifiant de declenchement ' ||
                        'non renseigne !',
                         n_CodeRet,
                         s_FONCTION);
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Purge de la table
    s_ReqSql:=
            'DELETE FROM T_GENFICHIER '||
            'WHERE id_app = (SELECT id_app '||
                            'FROM  T_DECLENCHEMENTS '||
                            'WHERE id_dec = :n_IdDec)';

    EXECUTE IMMEDIATE s_ReqSql USING n_IdDec;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION

    WHEN OTHERS THEN

        -- Afficher le message d'erreur Oracle
        PKG_LOG.P_ECRIRE(t_InfoTrait);

        -- Retourner l'echec du traitement
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_VIDE_GENFICHIER;

-- =======================================================================
-- # PROCEDURE    : F_MAJ_FIC_FLAG
-- # DESCRIPTION  : Creation d'un fichier flag
-- # PARAMETRES   : t_InfoTrait : Informations generales sur le traitement en cours
-- #                n_IdDec     : Identifiant de d'execution
-- #                s_NomChaine : Nom de la chaine de traitement
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 23/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_MAJ_FIC_FLAG(
                        t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                        n_IdDec     IN NUMBER,
                        s_NomChaine IN VARCHAR2
                       )
                       RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_MAJ_FIC_FLAG';

    -- Nom du fichier flag
    s_NomFicFlag VARCHAR2(64):='';

    -- Repertoire du fichier flag
    s_RepFicFlag VARCHAR2(25):='';

    -- Contenu du fichier flag
    s_ContenuFicFlag VARCHAR2(255):='';

BEGIN

    -- Initialiser les informations sur le fichier flag
    s_NomFicFlag:=s_NomChaine||'_'||TO_CHAR(n_IdDec)||'.flag';
    s_RepFicFlag:='DIR_TEMP';
    s_ContenuFicFlag:=to_char(n_IdDec)||CHR(10)||s_NomChaine;

    -- Mise a jour du fichier flag
    IF PKG_TEC_FICHIERS.F_ECRIRE_FICHIER(t_InfoTrait,
                                         s_NomFicFlag,
                                         s_RepFicFlag,
                                         s_ContenuFicFlag,
                                         'a') <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Afficher un message pour confirmer la creation du fichier
    PKG_LOG.P_ECRIRE(t_InfoTrait,
                     PKG_LOG.gt_LOG_TYPE_INF,
                     'Creation du fichier de declenchement ' ||
                     ' [' || s_NomFicFlag || ']' ,
                     0,
                     s_FONCTION);


    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
         PKG_LOG.P_ECRIRE(t_InfoTrait);
         RETURN PKG_GLOBAL.gn_CR_KO;
END F_MAJ_FIC_FLAG;

-- =======================================================================
-- # PROCEDURE    : F_MAJ_FIC_INFO
-- # DESCRIPTION  : Creation d'un fichier info
-- # PARAMETRES   : t_InfoTrait : Informations generales sur le traitement en cours
-- #                s_NomParam  : Nom du parametre a rajouter
-- #                s_ValParam  : Valeur du parametre a rajouter
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 30/11/2006 |           | JHI    | Creation
-- =======================================================================
FUNCTION F_MAJ_FIC_INFO(
                        t_InfoTrait  IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                        s_NomParam   IN VARCHAR2,
                        s_ValParam   IN VARCHAR2
                       )
                        RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_MAJ_FIC_INFO';

    -- Nom de la chaine de traitements
    s_NomChaine VARCHAR2(32) := '';

    -- Nom du fichier Info
    s_NomFicInfo VARCHAR2(64):='';

    -- Repertoire du fichier Info
    s_RepFicInfo VARCHAR2(32):='';

    -- Contenu d'une nouvelle ligne du fichier Info
    s_NouvelleLigneFicInfo VARCHAR2(1024):='';

    -- Ancienne ligne du fichier info en cas de mise a jour
    s_AncienneLigneFicInfo VARCHAR2(1024):='';

    -- Valeur existante du parametre si deja present dans le fichier info
    s_ValParamOld VARCHAR2(1000):='';

    -- Code retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

BEGIN

    -- Verifier les parametres
    IF ((s_NomParam IS NULL) OR (TRIM(s_NomParam)='')) THEN
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'Parametre [s_NomParam] non renseigne !',
                        1,
                        s_FONCTION
                        );
        RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recuperation du nom de la chaine en cours
    IF PKG_GLOBAL.F_GET_NOM_CHAINE(t_InfoTrait, s_NomChaine)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Verifier si le parametre existe deja dans le fichier info
    n_CodeRet := F_LIRE_FIC_INFO(t_InfoTrait, s_NomParam, s_ValParamOld);
    IF     n_CodeRet <> PKG_GLOBAL.gn_CR_OK
       AND n_CodeRet <> 1
       AND n_CodeRet <> 2 THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Initialiser les informations sur le fichier info
    s_NomFicInfo:=s_NomChaine || '.info';
    s_RepFicInfo:='DIR_TEMP';
    s_AncienneLigneFicInfo:=s_NomParam || ';' || s_ValParamOld;
    s_NouvelleLigneFicInfo:=s_NomParam || ';' || s_ValParam;

    -- Si le parametre n'existe pas deja dans le fichier INFO
    IF (
           (
               TRIM(s_ValParamOld) = ''
           OR  s_ValParamOld       IS NULL
           )
       AND n_CodeRet <> 2
       ) THEN

       -- Ajouter une nouvelle ligne au fichier INFO
       IF PKG_TEC_FICHIERS.F_ECRIRE_FICHIER(
                                           t_InfoTrait,
                                           s_NomFicInfo,
                                           s_RepFicInfo,
                                           s_NouvelleLigneFicInfo,
                                           'A'
                                           ) <> PKG_GLOBAL.gn_CR_OK THEN
          RETURN PKG_GLOBAL.gn_CR_KO;
       END IF;

    ELSE

       -- Mettre a jour la ligne du fichier INFO correspondant au parametre
       IF PKG_TEC_FICHIERS.F_MAJ_LIGNE_FIC(
                                          t_InfoTrait,
                                          s_AncienneLigneFicInfo,
                                          s_NouvelleLigneFicInfo,
                                          s_NomFicInfo,
                                          s_RepFicInfo
                                          ) <> PKG_GLOBAL.gn_CR_OK THEN
          RETURN PKG_GLOBAL.gn_CR_KO;
       END IF;

    END IF;

    -- Afficher un message pour confirmer la mise a jour du fichier info
    IF n_CodeRet = 1 THEN
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'Creation du parametre ['|| s_NomParam ||'] ' ||
                        'dans le fichier Info ' ||
                        ' [' || s_NomFicInfo || ']' ,
                        0,
                        s_FONCTION
                        );
    ELSE
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'Mise a jour du parametre ['|| s_NomParam ||'] ' ||
                        'dans le fichier Info ' ||
                        ' [' || s_NomFicInfo || ']' ,
                        0,
                        s_FONCTION
                        );
    END IF;

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
         PKG_LOG.P_ECRIRE(t_InfoTrait);
         RETURN PKG_GLOBAL.gn_CR_KO;
END F_MAJ_FIC_INFO;

-- =======================================================================
-- # PROCEDURE    : F_SET_DATE_DEB
-- # DESCRIPTION  : Ecrire la date/heure de debut d'un traitement
-- #                a partir de son identifiant de declenchement
-- # PARAMETRES   : t_InfoTrait : Informations generales sur le traitement en cours
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 28/09/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_SET_DATE_DEB(
                       t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT
                       )
                       RETURN NUMBER
IS
    -- Transaction autonome
    --PRAGMA AUTONOMOUS_TRANSACTION;

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_SET_DATE_DEB';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement ou d'execution
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Date de debut de traitement au format AAAA/MM/DD HH:MI:SS
    s_DateDebTrait VARCHAR(19) := '';

BEGIN

    -- Lire l'identifiant de declenchement dans les informations sur le traitement en cours
    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- ECRITURE DE LA DATE/HEURE DE DEBUT DU TRAITEMENT
    -- A PARTIR DE SON IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<EcritureDateDeb>>
    BEGIN

        -- Initialiser la date de debut de traitement
        s_DateDebTrait:=TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS');

      --  s_DateDebTrait:='20090513 12:00:00';

        -- Mettre a jour la date/heure de debut de traitement
        s_ReqSql:=
            'UPDATE '                                          ||
            '    V_DTC_DECLENCHEMENT '                            ||
            'SET '                                             ||
           '    DT_DEB = TO_DATE(:s_DateDebTrait,''YYYY/MM/DD HH24:MI:SS'') ' ||
    --       ' DT_DEB = TO_DATE(''2009/05/13 12:00:00'',''YYYY/MM/DD HH24:MI:SS'') ' ||
            'WHERE '                                           ||
            '    ID_DEC   = :n_IdDec';

        EXECUTE IMMEDIATE s_ReqSql USING s_DateDebTrait, n_IdDec;

        --EXECUTE IMMEDIATE s_ReqSql USING n_IdDec;

        -- Tracer le nombre de lignes traite par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Ecriture de la date/heure de debut de traitement (UPDATE) : ' ||
                         SQL%ROWCOUNT || ' lignes mise a jour',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- <MODIF> DVA - 12/08/08 - 1.01
        --         Modification du type de message de log :
        --         INF => DEB

        -- Tracer la date/heure de debut du traitement
        /*
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_INF,
                         'Date/Heure de debut du traitement : ' ||
                         NVL(s_DateDebTrait,'<NON RENSEIGNE>'),
                         0,
                         s_FONCTION);
        */

        -- Tracer la date/heure de debut du traitement
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Date/Heure de debut du traitement : ' ||
                         '['||nvl(s_DateDebTrait,'<NON RENSEIGNE>')||']',
                         0,
                         s_FONCTION);
        -- </MODIF>

        -- Valider la transaction
        --COMMIT;

      EXCEPTION

        -- Echec de la recherche de l'identifiant d'execution du traitement
        WHEN NO_DATA_FOUND THEN
            --ROLLBACK;
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant d''execution du traitement ['||
                             TO_CHAR(n_IdDec) ||'] inconnu !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            --ROLLBACK;
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END EcritureDateDeb;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        --ROLLBACK;
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_SET_DATE_DEB;

-- =======================================================================
-- # PROCEDURE    : F_SET_DATE_FIN
-- # DESCRIPTION  : Ecrire la date/heure de fin d'un traitement
-- #                a partir de son identifiant de declenchement
-- # PARAMETRES   : t_InfoTrait : Informations generales sur le traitement en cours
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 28/09/2006 |           | DVA    | Creation
-- =======================================================================
FUNCTION F_SET_DATE_FIN(
                              t_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT
                             )
                             RETURN NUMBER
IS
    -- Transaction autonome
    --PRAGMA AUTONOMOUS_TRANSACTION;

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_SET_DATE_FIN';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Identifiant de declenchement ou d'execution
    n_IdDec VARCHAR(12);

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Date de fin de traitement au format AAAA/MM/DD HH:MI:SS
    s_DateFinTrait VARCHAR(19) := '';

BEGIN

    -- Lire l'identifiant d'execution dans les informations
    -- sur le traitement en cours
    IF PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, n_IdDec)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- -------------------------------------------------------------------
    -- ECRITURE DE LA DATE/HEURE DE FIN DU TRAITEMENT
    -- A PARTIR DE SON IDENTIFIANT DE DECLENCHEMENT
    -- -------------------------------------------------------------------

    <<EcritureDateFin>>
    BEGIN

        -- Initialiser la date de fin de traitement
        s_DateFinTrait:=TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS');

        -- Mettre a jour la date/heure de fin de traitement
        s_ReqSql:=
            'UPDATE '                                          ||
            '    V_DTC_DECLENCHEMENT '                            ||
            'SET '                                             ||
            '    DT_FIN = TO_DATE(:s_DateFinTrait,''YYYY/MM/DD HH24:MI:SS'') ' ||
            'WHERE '                                           ||
            '    ID_DEC   = :n_IdDec';

        EXECUTE IMMEDIATE s_ReqSql USING s_DateFinTrait, n_IdDec;

        -- Tracer le nombre de lignes traite par la requete
        -- Remarque : le nombre de lignes est stocke en tant que code exception
        --            pour les messages de type 'compteur'
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Ecriture de la date/heure de fin de traitement (UPDATE) : ' ||
                         SQL%ROWCOUNT || ' lignes mise a jour',
                         SQL%ROWCOUNT,
                         s_FONCTION);

        -- Tracer la date/heure de debut du traitement
        PKG_LOG.P_ECRIRE(t_InfoTrait,
                         PKG_LOG.gt_LOG_TYPE_DBG,
                         'Date/Heure de fin du traitement : ' ||
                         '['||nvl(s_DateFinTrait,'<NON RENSEIGNE>')||']',
                         0,
                         s_FONCTION);

        -- Valider la transaction
        --COMMIT;

      EXCEPTION

        -- Echec de la recherche de l'identifiant d'execution du traitement
        WHEN NO_DATA_FOUND THEN
            --ROLLBACK;
            n_CodeRet:=3;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Identifiant d''execution du traitement ['||
                             TO_CHAR(n_IdDec) ||'] inconnu !',
                             n_CodeRet,
                             s_FONCTION);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             n_CodeRet,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

        -- Erreurs non gerees
        WHEN OTHERS THEN
            --ROLLBACK;
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             s_ReqSql,
                             SQLCODE,
                             s_FONCTION);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END EcritureDateFin;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        --ROLLBACK;
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_SET_DATE_FIN;

-- =======================================================================
-- # PROCEDURE    : F_LIRE_FIC_INFO
-- # DESCRIPTION  : Lecture d'un parametre du fichier info
-- # PARAMETRES   : t_InfoTrait : Informations generales sur le traitement en cours
-- #                s_NomParam  : Nom du parametre dont on veut recuperer la valeur
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 08/12/2006 |           | JHI    | Creation
-- # 1.1     | 18/08/2007 |           | DVA    | Modif ouverture fichier
-- # 1.2     | 30/08/2007 |           | JHI    | Gestion du cas ou le parametre existe deja mais n'a pas de valeur
-- =======================================================================
FUNCTION F_LIRE_FIC_INFO(
                         t_InfoTrait IN  PKG_GLOBAL.T_INFO_TRAITEMENT,
                         s_NomParam  IN  VARCHAR2,
                         s_ValParam  OUT VARCHAR2
                        )
                         RETURN NUMBER
IS

    -- Nom de la fonction
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_LIRE_FIC_INFO';

    -- Code retour
    n_CodeRet NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Taille maximun d'une ligne dans la table T_GENFICHIER
    i_TAILLE_MAX_LIGNE CONSTANT PLS_INTEGER:=1024;

    -- Pointeurs de fichier
    l_Fichier   UTL_FILE.FILE_TYPE;

    -- Tampon de travail
    s_Ligne VARCHAR2(1024);

    -- repertoire du fichier INFO
    s_Dir VARCHAR2(64):='DIR_TEMP';

    -- Nom du fichier INFO
    s_FileName VARCHAR2(64);

BEGIN

     -- LOG MIGRATION EXACC : Tracer appel UTL_FILE (log après récupération nom fichier)

     s_ValParam := NULL;

     -- On recupere le nom du fichier INFO (qui est le nom de la chaine)
     IF PKG_GLOBAL.F_GET_NOM_CHAINE(t_InfoTrait, s_FileName)
        <> PKG_GLOBAL.gn_CR_OK THEN
        RETURN PKG_GLOBAL.gn_CR_KO;
     END IF;

     -- LOG MIGRATION EXACC : Tracer appel UTL_FILE
     SP_LOG_FICHIER('PKG_DTC', 'F_LIRE_FIC_INFO', s_FileName || '.info', 'UTL_FILE.GET_LINE + FCLOSE');

     -- Ouverture du fichier INFO
    BEGIN

        -- --------------------------------------------------------------------
        -- MODIF DVA le 18/08/2007
        -- --------------------------------------------------------------------

        -- Ouvrir le fichier a charger
        n_CodeRet:=PKG_TEC_FICHIERS.F_OUVRIR_FICHIER(
                                                    t_InfoTrait,
                                                    s_Dir,
                                                    UPPER(trim(s_FileName))||
                                                    '.info',
                                                    'R',
                                                    i_TAILLE_MAX_LIGNE,
                                                    l_Fichier
                                                    );
        IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
            RETURN PKG_GLOBAL.gn_CR_KO;
        END IF;

        --l_Fichier := UTL_FILE.FOPEN(s_Dir, s_FileName||'.info', 'R', i_TAILLE_MAX_LIGNE) ;

        -- --------------------------------------------------------------------
        -- FIN MODIF DVA le 18/08/2007
        -- --------------------------------------------------------------------

    EXCEPTION
        WHEN OTHERS THEN
            PKG_LOG.P_AFFICHER(
                              'ECHEC LECTURE FICHIER INFO ' ||
                              '['||s_Dir||'/'||upper(trim(s_FileName))||
                              '.info]'
                              );
            RETURN PKG_GLOBAL.gn_CR_KO;
    END;

    -- Traitement
    BEGIN
        -- lecture de la premiere ligne du fichier
        UTL_FILE.GET_LINE(l_Fichier, s_Ligne);

        -- On parcours chaque ligne jusqu'a trouver le nom du parametre recherche
        WHILE INSTR(s_Ligne, s_NomParam||';') = 0 LOOP
              -- lecture de la ligne suivante du fichier
              UTL_FILE.GET_LINE(l_Fichier, s_Ligne);
        END LOOP;

        -- On a trouve la ligne, on recupere la valeur du parametre
        s_ValParam := SUBSTR(s_Ligne,LENGTH(s_NomParam)+2);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN -- Fin du fichier en entree
            -- Fermeture du fichier
            UTL_FILE.FCLOSE(l_Fichier);
            -- Si s_ValParam est vide, le parametre s_NomParam n'existe pas dans le fichier INFO
            IF s_ValParam IS NULL THEN
                PKG_LOG.P_ECRIRE(t_InfoTrait,
                                 PKG_LOG.gt_LOG_TYPE_DBG,
                                 'Le parametre ['||s_NomParam||'] '||
                                 'n''existe pas dans le fichier ' ||
                                 '['||s_Dir||'/'||upper(trim(s_FileName))||
                                 '.info] !',
                                 1,
                                 s_FONCTION);
                RETURN 1;
            END IF;
    END;

    -- --------------------------------------------------------------------
    -- MODIF JHI le 30/08/2007
    -- --------------------------------------------------------------------
    -- si le parametre existe deja mais n'a pas de valeur
    -- (possible lors de la mise a jour du fichier via un ksh)
    -- alors on retourne un code erreur different
    IF (TRIM(s_ValParam) = '' OR s_ValParam IS NULL) THEN
       RETURN 2;
    END IF;
    -- --------------------------------------------------------------------
    -- FIN MODIF JHI le 30/08/2007
    -- --------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
         PKG_LOG.P_ECRIRE(t_InfoTrait);
         RETURN PKG_GLOBAL.gn_CR_KO;
END F_LIRE_FIC_INFO;

/*
<FUNCTION>
============================================================================
 NOM        : F_LIRE_INFO
 OBJET      : Lire une information concernant la chaine de traitement
              dans la table T_INFO a partir du nom de la chaine
              et du nom de l'information recherchee (critere)
============================================================================
 PARAMETRES
 pt_InfoTrait      : Informations sur le traitement en cours
 ps_Critere        : Nom de l'information a lire
 ps_Valeur         : Valeur de l'information a lire
----------------------------------------------------------------------------
 VALEUR RETOURNEE
 Pkg_Global.gn_CR_OK : Succes du traitement
 Pkg_Global.gn_CR_KO : Echec du traitement (sans precision)
 1                   : parametre non renseigne
 2                   : Information recherchee non trouvee
============================================================================
 Version                   : 1.00
 Date                      : 18/08/08
 Auteur (+ trigramme)      : David VAREILLE (DVA)
 Sociiti                   : ADEX
 Nature du changement      : CREATION
 Reference du changement   : FMCPTA-126
 Description du changement : Creation
============================================================================
</FUNCTION>
*/
FUNCTION F_LIRE_INFO(
                    pt_InfoTrait IN            PKG_GLOBAL.T_INFO_TRAITEMENT,
                    ps_Critere   IN            VARCHAR2,
                    ps_Valeur    IN OUT NOCOPY VARCHAR2
                    )
                    RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_LIRE_INFO';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES LOCALES
    -- -------------------------------------------------------------------

    -- Code retour
    n_CodeRet NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Nom de l'information recherchee (critere)
    s_Critere VARCHAR2(255):='';

    -- Nom de la chaine de traitement courante
    s_NomChaine VARCHAR2(64) := '';

BEGIN

    -------------------------------------------------------
    -- LIRE ET FORMATER LES PARAMETRES
    -------------------------------------------------------

    s_Critere:=trim(ps_Critere);

    -------------------------------------------------------
    -- INITIALISER LES PARAMETRES SORTANTS
    -------------------------------------------------------

    ps_Valeur:='';

    -------------------------------------------------------
    -- CONTROLER LES PARAMETRES ENTRANT
    -------------------------------------------------------

    -- Verifier que le parametre [Critere] est bien renseigne
    IF s_Critere='' or s_Critere is null THEN

        -- Fixer le code retour correspondant a cette anomalie
        n_CodeRet := 1;

        -- Tracer l'anomalie de valeur du parametre
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'La valeur du parametre [critere] ' ||
                        'n''est pas renseignee !',
                        n_CodeRet,
                        s_FONCTION
                        );

        -- Interrompre le traitement
        RETURN n_CodeRet;

    END IF;

    -------------------------------------------------------
    -- LIRE LA VALEUR CORRESPONDANT AU CRITERE
    -------------------------------------------------------

    -- Recuperation du nom de la chaine de traitements en cours
    IF PKG_GLOBAL.F_GET_NOM_CHAINE(pt_InfoTrait, s_NomChaine)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    <<RechercherValeurCritere>>
    DECLARE

        -- Texte de la requete SQL
        s_ReqSql VARCHAR2(4000):='';

    BEGIN

        -- Tracer l'objet de la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : Recherche de la valeur du critere ' ||
                        '['||s_Critere||']',
                        0,
                        s_FONCTION
                        );

        -- Construire la requete
        s_ReqSql:=
            'SELECT '                                 || CHR(10) ||
            '    VALEUR '                             || CHR(10) ||
            'FROM '                                   || CHR(10) ||
            '    T_INFO '                             || CHR(10) ||
            'WHERE '                                  || CHR(10) ||
            '    SCRIPT_APP = '''||s_NomChaine||''' ' || CHR(10) ||
            'AND CRITERE    = '''||s_Critere  ||''' '
            ;

        -- Tracer la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : [' || s_ReqSql || ']',
                        0,
                        s_FONCTION
                        );

        -- executer la requete
        EXECUTE IMMEDIATE s_ReqSql INTO ps_Valeur;

        -- Tracer le nombre de lignes retournees/impactees par la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE (SELECT) : ' ||
                        SQL%ROWCOUNT || ' lignes selectionnees',
                        SQL%ROWCOUNT,
                        s_FONCTION
                        );

        -- Tracer l'information retournee par la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'Valeur du critere ['||s_Critere||'] : ' ||
                        '['||ps_Valeur||']',
                        0,
                        s_FONCTION
                        );

    EXCEPTION

        -- Aucun enregistrement retourne/impacte par la requete
        WHEN no_data_found THEN
            n_CodeRet := 2;
            PKG_LOG.P_ECRIRE(pt_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             'Critere ['||s_Critere||'] inexistant '||
                             'pour la chaine ['||s_NomChaine||'] !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN others THEN
            PKG_LOG.P_ECRIRE(pt_InfoTrait);
            RETURN PKG_GLOBAL.gn_CR_KO;

    END RechercherValeurCritere;


    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(pt_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_LIRE_INFO;

/*
<FUNCTION>
============================================================================
 NOM        : F_MAJ_INFO
 OBJET      : Mettre a jour ou ajouter une information
              concernant la chaine de traitement
              dans la table T_INFO a partir du nom de la chaine,
              du nom de l'information a ajouter ou mettre a jour (critere)
              et de la valeur de cette information
============================================================================
 PARAMETRES
 pt_InfoTrait      : Informations sur le traitement en cours
 ps_Critere        : Nom de l'information a ajouter ou a mettre a jour
 ps_Valeur         : Valeur de l'information a ajouter ou a mettre a jour
----------------------------------------------------------------------------
 VALEUR RETOURNEE
 Pkg_Global.gn_CR_OK : Succes du traitement
 Pkg_Global.gn_CR_KO : Echec du traitement (sans precision)
 1                   : Critere non renseigne
============================================================================
 Version                   : 1.00
 Date                      : 18/08/08
 Auteur (+ trigramme)      : David VAREILLE (DVA)
 Sociiti                   : ADEX
 Nature du changement      : CREATION
 Reference du changement   : FMCPTA-126
 Description du changement : Creation
============================================================================
</FUNCTION>
*/
FUNCTION F_MAJ_INFO(
                    pt_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                    ps_Critere   IN VARCHAR2,
                    ps_Valeur    IN VARCHAR2
                    )
                    RETURN NUMBER
IS

    -- Transaction autonome
    PRAGMA AUTONOMOUS_TRANSACTION;

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_MAJ_INFO';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES LOCALES
    -- -------------------------------------------------------------------

    -- Code retour
    n_CodeRet NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Nom de l'information recherchee (critere)
    s_Critere VARCHAR2(255):='';

    -- Valeur de l'information a ajouter ou mettre a jour
    s_Valeur VARCHAR2(4000):='';

    -- Nom de la chaine de traitement courante
    s_NomChaine VARCHAR2(64) := '';

    -- Indicateur de non existence de l'information a mettre a jour
    -- dans la table T_INFO
    b_InfoNonTouvee BOOLEAN:=FALSE;

    -- RLE
    s_test VARCHAR2(4000):='';

BEGIN

    -------------------------------------------------------
    -- LIRE ET FORMATER LES PARAMETRES
    -------------------------------------------------------

    s_Critere:=trim(ps_Critere);
    s_Valeur :=trim(ps_Valeur);

    -------------------------------------------------------
    -- CONTROLER LES PARAMETRES ENTRANT
    -------------------------------------------------------

    -- Verifier que le parametre [Critere] est bien renseigne
    IF s_Critere='' or s_Critere is null THEN

        -- Fixer le code retour correspondant a cette anomalie
        n_CodeRet := 1;

        -- Tracer l'anomalie de valeur du parametre
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'La valeur du parametre [critere] ' ||
                        'n''est pas renseignee !',
                        n_CodeRet,
                        s_FONCTION
                        );

        -- Interrompre le traitement
        RETURN n_CodeRet;

    END IF;

    -------------------------------------------------------
    -- AJOUTER OU METTRE A JOUR LA VALEUR DU CRITERE
    -------------------------------------------------------

    -- Recuperation du nom de la chaine de traitements en cours
    IF PKG_GLOBAL.F_GET_NOM_CHAINE(pt_InfoTrait, s_NomChaine)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    <<MAJValeurCritere>>
    DECLARE

        -- Texte de la requete SQL
        s_ReqSql VARCHAR2(4000):='';

    BEGIN

        -- Tracer l'objet de la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : Mise a jour ' ||
                        'de la valeur du critere ' ||
                        '['||s_Critere||'] '||
                        'pour la chaine ['||s_NomChaine||'] : ' ||
                        '['||s_Valeur||']',
                        0,
                        s_FONCTION
                        );

        -- Construire la requete
        /*
        L'utilisation du MERGE sur une base distante (via un DBLINK)
        est buguee dans la version 9.2.06 d'Oracle :

        Bug 3413826 9.2.0.4
        Abstract: ORA-904: INVALID IDENTIFIER, WITH 'MERGE'  INTO A TABLE ACROSS DBLINK.
        Fixed in 10.2
        Backportable to 9.2

        Il est donc necessaire de remplacer le MERGE par un autre code
        au moins en attendant d'installer un patch correctif

        s_ReqSql:=
            'merge into '                                      || chr(10) ||
            '    T_INFO c '                                    || chr(10) ||
            'using '                                           || chr(10) ||
            '    ( '                                           || chr(10) ||
            '    select '                                      || chr(10) ||
            '        '''||s_NomChaine||''' SCRIPT_APP, '       || chr(10) ||
            '        '''||s_Critere  ||''' CRITERE, '          || chr(10) ||
            '        '''||s_Valeur   ||''' VALEUR'             || chr(10) ||
            '    from '                                        || chr(10) ||
            '        dual '                                    || chr(10) ||
            '    ) s '                                         || chr(10) ||
            'on '                                              || chr(10) ||
            '    ( '                                           || chr(10) ||
            '        c.SCRIPT_APP = s.SCRIPT_APP '             || chr(10) ||
            '    and c.CRITERE    = s.CRITERE '                || chr(10) ||
            '    ) '                                           || chr(10) ||
            'when matched then update '                        || chr(10) ||
            '    set '                                         || chr(10) ||
            '        c.VALEUR  =  s.VALEUR '                   || chr(10) ||
            'when not matched then insert '                    || chr(10) ||
            '    ( '                                           || chr(10) ||
            '        c.SCRIPT_APP, '                           || chr(10) ||
            '        c.CRITERE, '                              || chr(10) ||
            '        c.VALEUR '                                || chr(10) ||
            '    ) '                                           || chr(10) ||
            '    values '                                      || chr(10) ||
            '    ( '                                           || chr(10) ||
            '        s.SCRIPT_APP, '                           || chr(10) ||
            '        s.CRITERE, '                              || chr(10) ||
            '        s.VALEUR '                                || chr(10) ||
            '    ) '
            ;
        */
        --RLE
        s_ReqSql:=
            'select VALEUR '                           || CHR(10) ||
            ' from   T_INFO '                          || CHR(10) ||
            'where '                                   || CHR(10) ||
            '    SCRIPT_APP = ''' ||s_NomChaine||''' ' || CHR(10) ||
            'and CRITERE    = ''' ||s_Critere  ||''' '
            ;
     --/RLE
                EXECUTE IMMEDIATE s_ReqSql into s_test ;


        s_ReqSql:=
            'update '                                  || CHR(10) ||
            '    T_INFO '                              || CHR(10) ||
            'set '                                     || CHR(10) ||
            '    VALEUR     = ''' ||s_Valeur   ||''' ' || CHR(10) ||
            'where '                                   || CHR(10) ||
            '    SCRIPT_APP = ''' ||s_NomChaine||''' ' || CHR(10) ||
            'and CRITERE    = ''' ||s_Critere  ||''' '
            ;

        -- Tracer la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : [' || s_ReqSql || ']',
                        0,
                        s_FONCTION
                        );

        -- Executer la requete
        EXECUTE IMMEDIATE s_ReqSql;

        -- Tracer le nombre de lignes retournees/impactees par la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE (UPDATE) : ' ||
                        SQL%ROWCOUNT || ' lignes modifiees',
                        SQL%ROWCOUNT,
                        s_FONCTION
                        );

        -- Valider la transaction
        commit;

    EXCEPTION

        -- Le critere n'existe pas pour cette chaine dans la table T_INFO :
        -- il faut donc l'ajouter
        WHEN NO_DATA_FOUND THEN
            b_InfoNonTouvee:=TRUE;
            PKG_LOG.P_ECRIRE(
                            pt_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'Mise a jour impossible de la valeur du critere '||
                            '['||s_Critere||'] '||
                            'pour la chaine ['||s_NomChaine||'] : ' ||
                            'critere non trouve !',
                            0,
                            s_FONCTION
                            );

        -- Erreurs non gerees
        WHEN others THEN
            PKG_LOG.P_ECRIRE(pt_InfoTrait);
            rollback;
            RETURN PKG_GLOBAL.gn_CR_KO;

    END MAJValeurCritere;

    -- Si l'information a mettre a jour n'a pas ete trouvee,
    -- c'est quelle n'existe pas : il faut donc l'ajouter
    IF b_InfoNonTouvee THEN

        <<InsertValeurCritere>>
        DECLARE

            -- Texte de la requete SQL
            s_ReqSql VARCHAR2(4000):='';

        BEGIN

            -- Tracer l'objet de la requete
            PKG_LOG.P_ECRIRE(
                            pt_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'REQUETE : Ajout ' ||
                            'de la valeur du critere ' ||
                            '['||s_Critere||'] '||
                            'pour la chaine ['||s_NomChaine||'] : ' ||
                            '['||s_Valeur||']',
                            0,
                            s_FONCTION
                            );

            -- Construire la requete
            s_ReqSql:=
                'insert into '                 || CHR(10) ||
                '    T_INFO '                  || CHR(10) ||
                '( '                           || CHR(10) ||
                '    SCRIPT_APP, '             || CHR(10) ||
                '    CRITERE, '                || CHR(10) ||
                '    VALEUR '                  || CHR(10) ||
                ') '                           || CHR(10) ||
                'values '                      || CHR(10) ||
                '( '                           || CHR(10) ||
                '    ''' ||s_NomChaine||''', ' || CHR(10) ||
                '    ''' ||s_Critere  ||''', ' || CHR(10) ||
                '    ''' ||s_Valeur   ||''' '  || CHR(10) ||
                ') '
                ;

            -- Tracer la requete
            PKG_LOG.P_ECRIRE(
                            pt_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'REQUETE : [' || s_ReqSql || ']',
                            0,
                            s_FONCTION
                            );

            -- Executer la requete
            EXECUTE IMMEDIATE s_ReqSql;

            -- Tracer le nombre de lignes retournees/impactees par la requete
            PKG_LOG.P_ECRIRE(
                            pt_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_DBG,
                            'REQUETE (INSERT) : ' ||
                            SQL%ROWCOUNT || ' lignes ajoutees',
                            SQL%ROWCOUNT,
                            s_FONCTION
                            );

            -- Valider la transaction
            commit;

        EXCEPTION

            -- Erreurs non gerees
            WHEN others THEN
                PKG_LOG.P_ECRIRE(pt_InfoTrait);
                rollback;
                RETURN PKG_GLOBAL.gn_CR_KO;

        END InsertValeurCritere;

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

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(pt_InfoTrait);
        rollback;
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_MAJ_INFO;

/*
<FUNCTION>
============================================================================
 NOM        : F_SUPPRIMER_INFO
 OBJET      : Supprimer une information
              concernant une chaine de traitement
              dans la table T_INFO a partir du nom de la chaine,
              et du nom de l'information a supprimer (critere)
============================================================================
 PARAMETRES
 pt_InfoTrait      : Informations sur le traitement en cours
 ps_Critere        : Nom de l'information a supprimer
----------------------------------------------------------------------------
 VALEUR RETOURNEE
 Pkg_Global.gn_CR_OK : Succes du traitement
 Pkg_Global.gn_CR_KO : Echec du traitement (sans precision)
 1                   : Critere non renseigne
 2                   : critere non trouve (info a supprimer inexistante)
============================================================================
 Version                   : 1.00
 Date                      : 18/08/08
 Auteur (+ trigramme)      : David VAREILLE (DVA)
 Sociiti                   : ADEX
 Nature du changement      : CREATION
 Reference du changement   : FMCPTA-126
 Description du changement : Creation
============================================================================
</FUNCTION>
*/
FUNCTION F_SUPPRIMER_INFO(
                         pt_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT,
                         ps_Critere   IN VARCHAR2
                         )
                         RETURN NUMBER
IS

    -- Transaction autonome
    PRAGMA AUTONOMOUS_TRANSACTION;

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_SUPPRIMER_INFO';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES LOCALES
    -- -------------------------------------------------------------------

    -- Code retour
    n_CodeRet NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Nom de l'information recherchee (critere)
    s_Critere VARCHAR2(255):='';

    -- Nom de la chaine de traitement courante
    s_NomChaine VARCHAR2(64) := '';

BEGIN

    -------------------------------------------------------
    -- LIRE ET FORMATER LES PARAMETRES
    -------------------------------------------------------

    s_Critere:=trim(ps_Critere);

    -------------------------------------------------------
    -- CONTROLER LES PARAMETRES ENTRANT
    -------------------------------------------------------

    -- Verifier que le parametre [Critere] est bien renseigne
    IF s_Critere='' or s_Critere is null THEN

        -- Fixer le code retour correspondant a cette anomalie
        n_CodeRet := 1;

        -- Tracer l'anomalie de valeur du parametre
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'La valeur du parametre [critere] ' ||
                        'n''est pas renseignee !',
                        n_CodeRet,
                        s_FONCTION
                        );

        -- Interrompre le traitement
        RETURN n_CodeRet;

    END IF;

    -------------------------------------------------------
    -- SUPPRIMER LA LIGNE CORRESPONDANT AU CRITERE
    -------------------------------------------------------

    -- Recuperation du nom de la chaine de traitements en cours
    IF PKG_GLOBAL.F_GET_NOM_CHAINE(pt_InfoTrait, s_NomChaine)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    <<SupprimerCritere>>
    DECLARE

        -- Texte de la requete SQL
        s_ReqSql VARCHAR2(4000):='';

    BEGIN

        -- Tracer l'objet de la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : Suppression de la ligne ' ||
                        'ayant pour critere ['||s_Critere||']',
                        0,
                        s_FONCTION
                        );

        -- Construire la requete
        s_ReqSql:=
            'delete from '                                     || chr(10) ||
            '    T_INFO  '                                     || chr(10) ||
            'where '                                           || chr(10) ||
            '    SCRIPT_APP = '''||s_NomChaine||''' '          || chr(10) ||
            'and CRITERE    = '''||s_Critere  ||''' '
            ;

        -- Tracer la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : [' || s_ReqSql || ']',
                        0,
                        s_FONCTION
                        );

        -- Executer la requete
        EXECUTE IMMEDIATE s_ReqSql;

        -- Tracer le nombre de lignes retournees/impactees par la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE (DELETE) : ' ||
                        SQL%ROWCOUNT || ' lignes supprimees',
                        SQL%ROWCOUNT,
                        s_FONCTION
                        );

        -- Valider la transaction
        commit;

    EXCEPTION

        -- Aucun enregistrement retourne/impacte par la requete
        WHEN no_data_found THEN
            n_CodeRet := 2;
            PKG_LOG.P_ECRIRE(pt_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_DBG,
                             'Critere ['||s_Critere||'] inexistant '||
                             'pour la chaine ['||s_NomChaine||'] !',
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

        -- Erreurs non gerees
        WHEN others THEN
            PKG_LOG.P_ECRIRE(pt_InfoTrait);
            rollback;
            RETURN PKG_GLOBAL.gn_CR_KO;

    END SupprimerCritere;

    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(pt_InfoTrait);
        rollback;
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_SUPPRIMER_INFO;

/*
<FUNCTION>
============================================================================
 NOM        : F_PURGER_INFO
 OBJET      : Supprimer toutes les informations
              concernant une chaine de traitement
              dans la table T_INFO a partir du nom de la chaine,
============================================================================
 PARAMETRES
 pt_InfoTrait      : Informations sur le traitement en cours
----------------------------------------------------------------------------
 VALEUR RETOURNEE
 Pkg_Global.gn_CR_OK : Succes du traitement
 Pkg_Global.gn_CR_KO : Echec du traitement (sans precision)
============================================================================
 Version                   : 1.00
 Date                      : 18/08/08
 Auteur (+ trigramme)      : David VAREILLE (DVA)
 Sociiti                   : ADEX
 Nature du changement      : CREATION
 Reference du changement   : FMCPTA-126
 Description du changement : Creation
============================================================================
</FUNCTION>
*/
FUNCTION F_PURGER_INFO(
                      pt_InfoTrait IN PKG_GLOBAL.T_INFO_TRAITEMENT
                      )
                      RETURN NUMBER
IS

    -- Transaction autonome
    PRAGMA AUTONOMOUS_TRANSACTION;

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_PURGER_INFO';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES LOCALES
    -- -------------------------------------------------------------------

    -- Code retour
    n_CodeRet NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Nom de la chaine de traitement courante
    s_NomChaine VARCHAR2(64) := '';

BEGIN

    -------------------------------------------------------
    -- PURGER TOUTES LES LIGNES CORRESPONDANT A LA CHAINE
    -------------------------------------------------------

    -- Recuperation du nom de la chaine de traitements en cours
    IF PKG_GLOBAL.F_GET_NOM_CHAINE(pt_InfoTrait, s_NomChaine)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    <<PugerInfoChaine>>
    DECLARE

        -- Texte de la requete SQL
        s_ReqSql VARCHAR2(4000):='';

    BEGIN

        -- Tracer l'objet de la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : Suppression des lignes d''information ' ||
                        'de la chaine ['||s_NomChaine||']',
                        0,
                        s_FONCTION
                        );

        -- Construire la requete
        s_ReqSql:=
            'delete from '                                     || chr(10) ||
            '    T_INFO  '                                     || chr(10) ||
            'where '                                           || chr(10) ||
            '    SCRIPT_APP = '''||s_NomChaine||''' '
            ;

        -- Tracer la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : [' || s_ReqSql || ']',
                        0,
                        s_FONCTION
                        );

        -- executer la requete
        EXECUTE IMMEDIATE s_ReqSql;

        -- Tracer le nombre de lignes retournees/impactees par la requete
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE (DELETE) : ' ||
                        SQL%ROWCOUNT || ' lignes supprimees',
                        SQL%ROWCOUNT,
                        s_FONCTION
                        );

        -- Valider la transaction
        commit;

    EXCEPTION

        -- Erreurs non gerees
        WHEN others THEN
            PKG_LOG.P_ECRIRE(pt_InfoTrait);
            rollback;
            RETURN PKG_GLOBAL.gn_CR_KO;

    END PugerInfoChaine;


    -- -------------------------------------------------------------------
    -- FIN DU TRAITEMENT
    -- -------------------------------------------------------------------

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;


EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gerees
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(pt_InfoTrait);
        rollback;
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_PURGER_INFO;

-- =======================================================================
-- # PROCEDURE    : F_GET_LISTE_MAIL
-- # DESCRIPTION  : Recupere la liste des e-mails auxquels adresser le CRE
-- #                (Compte-Rendu d'Execution)
-- # PARAMETRES   :
-- #  + t_InfoTrait  : Informations generales sur le traitement en cours
-- #  + s_ListeEmail : Liste des e-mails
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 28/03/2007 |           | JHI    | Creation
-- # 1.1     | 16/08/2007 |           | DVA    | Ajout de l'adresse mail
-- #         |            |           |        | de l'utilisateur qui a declenche le traitement
-- #         |            |           |        | a la liste des destinataires du CRE
-- # 1.2     | 18/08/2008 |           | DVA    | Suppression enreg dans fic INFO + ajout param sortie s_ListeEmail
-- =======================================================================
FUNCTION F_GET_LISTE_MAIL(
                         t_InfoTrait  IN            PKG_GLOBAL.T_INFO_TRAITEMENT,
                         s_ListeEmail IN OUT NOCOPY VARCHAR2
                         )
                         RETURN NUMBER
IS

    -- Separateur des destinataires dans la liste d'email
    s_SEP_LISTE_EMAIL CONSTANT VARCHAR2(1):=' ';

    -- Nom de la fonction courante
    s_FONCTION VARCHAR2(64):=gs_PACKAGE||'.'||'F_GET_LISTE_MAIL';

    -- Nom de la chaine en cours
    s_NomChaine VARCHAR2(64):='';

    -- Info du user DTC qui a declenche la traitement
    s_IdUser       VARCHAR2(32)  :='';
    s_UID          CHAR(8)       :='';
    s_LoginWindows VARCHAR2(50)  :='';
    s_Nom          VARCHAR2(50)  :='';
    s_Prenom       VARCHAR2(50)  :='';
    s_Mail         VARCHAR2(1024):='';

BEGIN

    -- Initialiser les parametres sortants
    s_ListeEmail:='';

    -- Recuperation du nom de la chaine
    IF PKG_GLOBAL.F_GET_NOM_CHAINE(t_InfoTrait, s_NomChaine) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recuperation de la liste des adresses e-mail
    SELECT
        trim(CRE_MAIL)||s_SEP_LISTE_EMAIL||trim(CRE_MAIL_CC)
    INTO
        s_ListeEmail
    FROM
        T_APPLICATIONS
    WHERE
        SCRIPT_APP = s_NomChaine;

    -- ------------------------------------------------------------------------
    -- AJOUT DVA le 16/08/2007
    -- ------------------------------------------------------------------------

    -- Recuperation de l'utilisateur ayant declenche le traitement
    IF F_GET_USER(t_InfoTrait,
                  s_IdUser,
                  TRUE) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Recuperation des caracteristiques de l'utilisateur
    -- qui a declenche le traitement,
    -- dont son adresse mail
    IF F_GET_USER_INFO(
                       t_InfoTrait,
                       s_IdUser,
                       s_UID,
                       s_LoginWindows,
                       s_Nom,
                       s_Prenom,
                       s_Mail,
                       TRUE
                      ) <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;

    -- Ajouter l'adresse mail de l'utilisateur a la liste des destinataires
    -- du compte-rendu d'execution
    IF trim(s_Mail) IS NOT NULL THEN
        s_ListeEmail:=trim(s_Mail) || ' ' || trim(s_ListeEmail);
    END IF;

    -- ------------------------------------------------------------------------
    -- AJOUT DVA le 16/08/2007
    -- ------------------------------------------------------------------------

    -- <SUPPR> DVA - 18/08/08 - 1.2
    --         La fonction courante ne doit s'occuper que de retourner
    --         la liste des adresses mail. L'enregistrement de cette liste
    --         dans le fichier INFO doit etre devolu a une autre fonction

    /*
    -- Mise a jour du fichier INFO
    IF F_MAJ_FIC_INFO(t_InfoTrait, 'ListeEmail', s_ListeEmail)
       <> PKG_GLOBAL.gn_CR_OK THEN
       RETURN PKG_GLOBAL.gn_CR_KO;
    END IF;
    */

    -- </SUPPR>

    -- Retourner le succes du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN PKG_GLOBAL.gn_CR_KO;

END F_GET_LISTE_MAIL;
-- =======================================================================
-- # PROCEDURE    : F_GET_ID_EXEC_WAITING
-- # DESCRIPTION  : Recherche demande declenchement en attente
-- # PARAMETRES   : IN  : n_Id_APP ==> identifiant application
-- #                OUT : n_Id_Dec ==> retourne le declenchement le plus ancien
-- #                                   ou NULL si pas de declenchement
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 28/05/2008 |           | FAU    | Creation
-- =======================================================================
FUNCTION F_GET_ID_EXEC_WAITING(
                              t_InfoTrait  IN  PKG_GLOBAL.T_INFO_TRAITEMENT,
                              n_Id_APP     IN  NUMBER,
                              n_Id_Dec     OUT NUMBER
                              )
                              RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_GET_ID_EXEC_WAITING';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    -- Nom du Traitement DTC
    s_NomTrait VARCHAR2(30):='DTC Control';

    --
    s_Interval   VARCHAR2(20):='';

    --
    s_ResultatTrait VARCHAR2(20):='DECL';

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    s_CTL_DECL CHAR(1):='';

BEGIN


    n_Id_Dec := NULL;

    -- Recherche demande en cours
    -- Il ne doit y' avoir qu'une seule demande en cours pour un id appli donne
    BEGIN
        s_ReqSql:=
            'SELECT '                                      || CHR(10) ||
            '    MAX(DEC.ID_DEC) '                         || CHR(10) ||
            'FROM '                                        || CHR(10) ||
            '    T_DECLENCHEMENTS DEC  '                   || CHR(10) ||
            'WHERE '                                       || CHR(10) ||
            '    DEC.ID_APP= ' || to_char(n_Id_APP) || ' ' || CHR(10) ||
            'AND DEC.DATE_DEB IS NOT NULL '                || CHR(10) ||
            'AND DEC.DATE_FIN IS NULL '                    || CHR(10) ||
            'ORDER BY '                                    || CHR(10) ||
            '    ID_DEC DESC '
            ;

        EXECUTE IMMEDIATE s_ReqSql INTO n_Id_Dec;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=1;
            PKG_LOG.P_ECRIRE(t_InfoTrait,
                             PKG_LOG.gt_LOG_TYPE_ERR,
                             'Erreur Recherche identifiant en cours '  ||
                             SQLERRM || ' ' ||
                             'Identifiant app : ' || TO_CHAR(n_Id_APP),
                             n_CodeRet,
                             s_FONCTION);
            RETURN n_CodeRet;

    END;

    -- Rechercher l'identifiant execution en attente
    IF n_Id_Dec IS NULL THEN

        s_ReqSql:=
            'SELECT '                                || CHR(10) ||
            '    MIN(DEC.ID_DEC) '                   || CHR(10) ||
            'FROM '                                  || CHR(10) ||
            '    T_DECLENCHEMENTS DEC '              || CHR(10) ||
            'WHERE '                                 || CHR(10) ||
            '    DEC.ID_APP='||to_char(n_Id_APP)||' '|| CHR(10) ||
          --'AND (DEC.CTL_DECL <> ''Y'') '           || CHR(10) ||
            'AND DEC.DATE_DEB IS NULL '              || CHR(10) ||
            'AND DEC.DATE_FIN IS NULL  '
            ;

        BEGIN

            EXECUTE IMMEDIATE s_ReqSql INTO n_Id_Dec;

            s_ReqSql:=
                'SELECT '                                || CHR(10) ||
                '    DEC.CTL_DECL '                      || CHR(10) ||
                'FROM '                                  || CHR(10) ||
                '    T_DECLENCHEMENTS DEC '              || CHR(10) ||
                'WHERE '                                 || CHR(10) ||
                '    DEC.ID_APP='||to_char(n_Id_APP)||' '|| CHR(10) ||
                'AND DEC.ID_DEC='||to_char(n_Id_Dec)||' '|| CHR(10) ||
                'AND DEC.DATE_DEB IS NULL '              || CHR(10) ||
                'AND DEC.DATE_FIN IS NULL '
                ;

            IF n_Id_Dec IS NOT NULL THEN

                -- recherche si le flag a deja ete depose
                EXECUTE IMMEDIATE s_ReqSql INTO s_CTL_DECL;

                IF s_CTL_DECL = 'Y' THEN
                    n_Id_Dec:=NULL;
                END IF;

            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 NULL;
                 RETURN PKG_GLOBAL.gn_CR_OK;

            WHEN OTHERS THEN
                PKG_LOG.P_ECRIRE(t_InfoTrait);
                n_CodeRet:=2;
                PKG_LOG.P_ECRIRE(t_InfoTrait,
                                 PKG_LOG.gt_LOG_TYPE_ERR,
                                 'ERREUR : <A COMPLETER>'  ||
                                 '(Id. app : ' || TO_CHAR(n_Id_APP) || ')',
                                 n_CodeRet,
                                 s_FONCTION);
                RETURN n_CodeRet;

        END;

    ELSE

        n_Id_Dec:=NULL;

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

    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_INF,
                        'ERREUR Recherche identifiant declenchement :' ||
                        'Identifiant app : [' || TO_CHAR(n_Id_APP) || '])',
                        PKG_GLOBAL.gn_CR_OK,
                        s_FONCTION
                        );
        RETURN PKG_GLOBAL.gn_CR_KO;
END F_GET_ID_EXEC_WAITING;


-- =======================================================================
-- # PROCEDURE    : P_Scan_Demande_DTC
-- # DESCRIPTION  : Parcourir la liste des applis pour rechercher
-- #                les declenchements a effectuer
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 28/05/2008 |           | FAU    | Creation
-- =======================================================================
PROCEDURE P_SCAN_DEMANDE_DTC(t_InfoTrait IN  PKG_GLOBAL.T_INFO_TRAITEMENT)
AS

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'P_SCAN_DEMANDE_DTC';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    -- Code Retour
    n_CodeRet NUMBER := PKG_GLOBAL.gn_CR_KO;

    --Nom Traitement
    s_NomTrait    VARCHAR2(30) :='CTRL_DECL_DTC';
    s_Param       VARCHAR2(100):='';
    s_Message     VARCHAR2(100):='';

    -- Requete SQL
    s_ReqSql VARCHAR2(1024) :='';

    -- Identifiant de declenchement
    n_Id_Dec NUMBER :=NULL;

    -- Liste des applications DTC
    -- dont le declenchement est gere par le job Oracle
    CURSOR cur_Liste_Appli_Controlees
    IS
        SELECT
            ID_APP,
            SCRIPT_APP
        FROM
            T_APPLICATIONS
        WHERE
            rtrim(SCRIPT_APP) IS NOT NULL
        AND CONTROLEUR_DECLENCHEMENT ='Y'
        ORDER BY
            ID_APP
        ;

BEGIN

    -- Pour chacune des applications dont le declenchements est gere
    -- par le job Oracle
    FOR app_rec IN cur_Liste_Appli_Controlees
    LOOP

        -- Si l'application DTC n'est pas celle de gestion des droits DTC
        IF app_rec.id_app <> 99 THEN

            -- Rechercher l'identifiant de declenchement
            -- du plus ancien traitement en attente de declenchement
            n_CodeRet:=F_Get_Id_Exec_Waiting(
                                            t_InfoTrait,
                                            app_rec.id_app,
                                            n_Id_Dec
                                            );

            IF  n_CodeRet = PKG_GLOBAL.gn_CR_OK THEN

                -- Depose flag avec identifiant
                IF n_Id_Dec IS NOT NULL THEN

                    -- Construire le contenu du fichier flag
                    s_Param:=n_Id_Dec||PKG_GLOBAL.gs_CRLF||app_rec.script_app;

                    -- Generer le fichier flag
                    P_CRE_FIC_UNIX_DTC(
                                      t_InfoTrait,
                                      'DIR_TEMP',
                                      app_rec.script_app ||
                                      '_'|| n_Id_Dec|| '.flag',
                                      s_Message,
                                      s_Param
                                      );

                END IF;

            END IF;

        END IF;

    END LOOP;

    -- Fin du traitement
    RETURN;

EXCEPTION
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_INF,
                        'ERREUR : ECHEC DECLENCHEMENT !',
                        PKG_GLOBAL.gn_CR_OK,
                        s_FONCTION
                        );
        RETURN;

END P_SCAN_DEMANDE_DTC;

-- =======================================================================
-- # PROCEDURE   : P_CRE_FIC_UNIX_DTC
-- # DESCRIPTION  : Deposer un fichier flag dans TEMP_APPLI
-- #
-- # PARAMETRES   :
-- #   + chemin_vp  : Nom Directory Oracle
-- #   + fichier_vp : Nom fichier flag
-- #   + message_vp : null
-- #   + param      : contenu du fichier flag
-- #                  = liste des valeurs des parametres du traitement DTC
-- #
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 01/02/2008 |           | FRA    |  Mise en place Logger
-- =======================================================================
PROCEDURE P_CRE_FIC_UNIX_DTC(
                            pt_InfoTrait IN    PKG_GLOBAL.T_INFO_TRAITEMENT,
                            chemin_vp   IN     VARCHAR2,
                            fichier_vp  IN     VARCHAR2,
                            message_vp  IN OUT VARCHAR2,
                            param       IN     VARCHAR2
                            )
AS

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):= 'P_CRE_FIC_UNIX_DTC';

    -- Code retour
    n_CodeRet NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Fichier flag DTC a ecrire
    fichier_vf utl_file.FILE_TYPE;

    -- Identifiant de declenchement
    s_IdDec VARCHAR2(12):='';

    -- Position dans une chaine de caracteres
    n_Pos NUMBER:=0;

    -- Nom du traitement courant
    s_NomTrait VARCHAR2(30):='';

    -- Informations sur le traitement en cours
    t_InfoTrait PKG_GLOBAL.T_INFO_TRAITEMENT:=NULL;

BEGIN

    -------------------------------------------------------
    -- CONSTRUIRE UN INFOTRAIT
    -------------------------------------------------------

    -- Extraire l'identifiant de declenchement
    -- du contenu du message passe en parametre
    -- en lisant la premiere ligne du message
    n_Pos:=instr(param,PKG_GLOBAL.gs_CRLF,1);
    IF n_Pos=0 THEN
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'ERREUR : CONTENU FICHIER FLAG INCORRECT !',
                        1,
                        s_FONCTION
                        );
        PKG_LOG.P_AFFICHER('ERREUR : CONTENU FICHIER FLAG INCORRECT !');
        RETURN;
    END IF;

    s_IdDec:=substr(param,1,n_Pos-1);
    IF s_IdDec is null or length(s_IdDec)=0 THEN
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'ERREUR : ID. DECLENCHEMENT NON RENSEIGNE !',
                        2,
                        s_FONCTION
                        );
        PKG_LOG.P_AFFICHER('ERREUR : ID. DECLENCHEMENT NON RENSEIGNE !');
        RETURN;
    END IF;

    PKG_LOG.P_AFFICHER('Identifiant de declenchement : [' ||s_IdDec||']' );
    PKG_LOG.P_ECRIRE(
                    pt_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_DBG,
                    'Identifiant de declenchement : [' ||s_IdDec||']',
                    0,
                    s_FONCTION
                    );

    -- Extraire le nom du traitement du nom de fichier flag
    -- (ce dernier est de la forme <NOM_TRAIT>_<ID_EXEC>.flag
    --  ou <NOM_TRAIT>.flag)
    n_Pos:=instr(fichier_vp,'_',1);
    IF n_Pos=0 THEN
        n_Pos:=instr(fichier_vp,'.',1);
        IF n_Pos=0 THEN
            PKG_LOG.P_ECRIRE(
                            pt_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ERR,
                            'ERREUR : CONTENU FICHIER FLAG INCORRECT !',
                            3,
                            s_FONCTION
                            );
            PKG_LOG.P_AFFICHER('ERREUR : CONTENU FICHIER FLAG INCORRECT !');
            RETURN;
        ELSE
            s_NomTrait:=substr(fichier_vp,1,n_Pos-1);
        END IF;
    ELSE
        s_NomTrait:=substr(fichier_vp,1,n_Pos-1);
    END IF;

    PKG_LOG.P_ECRIRE(
                    pt_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_INF,
                    'Nom du traitement : [' ||s_NomTrait||']',
                    0,
                    s_FONCTION
                    );
    PKG_LOG.P_AFFICHER('Nom du traitement : [' ||s_NomTrait||']' );

    -- Construire automatiquement les informations sur le traitement en cours
    n_CodeRet:=PKG_GLOBAL.F_BUILD_INFOTRAIT(
                                           t_InfoTrait,
                                           s_NomTrait,
                                           s_NomTrait,
                                           'DTC',
                                           n_IdExec => s_IdDec
                                           );
    IF n_CodeRet <> PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_AFFICHER('ERREUR : ECHEC CONSTRUCTION INFOTRAIT !');
        PKG_LOG.P_ECRIRE(
                        pt_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'ERREUR : ECHEC CONSTRUCTION INFOTRAIT !',
                        4,
                        s_FONCTION
                        );
        RETURN;
    END IF;

    -------------------------------------------------------
    -- OUVRIR LE FICHIER FLAG EN MODE ECRITURE
    -------------------------------------------------------

    <<Ouvrir_Fichier_Flag>>
    BEGIN

        -- Ouverture du fichier en ecriture
        fichier_vf := utl_file.fopen(chemin_vp,fichier_vp,'w');

    EXCEPTION
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=5;
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ERR ,
                            'ERREUR : ECHEC OUVERTURE FICHIER DECLENCHEMENT ' ||
                            '['||chemin_vp||'/'||fichier_vp||'] !' ,
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN;

    END Ouvrir_Fichier_Flag;

    -------------------------------------------------------
    -- ECRIRE LE CONTENU DU FICHIER FLAG
    -------------------------------------------------------

    <<Ecrire_Contenu_Fichier_Flag>>
    BEGIN

        -- Ecriture d'un enregistrement
        utl_file.put(fichier_vf,param);


    EXCEPTION
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=6;
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ERR ,
                            'ERREUR : ECHEC ECRITURE DU CONTENU ' ||
                            'DU FICHIER DECLENCHEMENT ' ||
                            '['||chemin_vp||'/'||fichier_vp||'] !' ,
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN;

    END Ecrire_Contenu_Fichier_Flag;

    <<Forcer_Ecriture_disque>>
    BEGIN

        -- Forcer l'ecriture du fichier sur le disque
        utl_file.fflush(fichier_vf);

    EXCEPTION
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=7;
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ERR ,
                            'ERREUR : ECHEC ECRITURE SUR DISQUE DU CONTENU ' ||
                            'DU FICHIER DECLENCHEMENT ' ||
                            '['||chemin_vp||'/'||fichier_vp||'] !' ,
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN;

    END Forcer_Ecriture_disque;

    -------------------------------------------------------
    -- FERMER LE FICHIER FLAG
    -------------------------------------------------------

    <<Fermer_Fichier_Flag>>
    BEGIN

        -- Fermeture fichier
        utl_file.fclose(fichier_vf);

    EXCEPTION
        WHEN OTHERS THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=8;
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ERR ,
                            'ERREUR : ECHEC FERMETURE ' ||
                            'DU FICHIER DECLENCHEMENT ' ||
                            '['||chemin_vp||'/'||fichier_vp||'] !' ,
                            n_CodeRet,
                            s_FONCTION
                            );
            RETURN;

    END Fermer_Fichier_Flag;


    -------------------------------------------------------
    -- CONTROLER LA PRESENCE DU FICHIER FLAG GENERE
    -------------------------------------------------------

    --  Controle existence fichier +  controle  existence DIRECTORY
    IF PKG_TEC_FICHIERS.F_FileExists(
                                    t_InfoTrait,
                                    fichier_vp,
                                    chemin_vp
                                    )= 'FALSE' THEN

        -- Fixer le code retour
        n_CodeRet:=9;

        -- Tracer l'anomalie
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR ,
                        'ERREUR : FICHIER DECLENCHEMENT ' ||
                        '['||chemin_vp||'/'||fichier_vp||'] ' ||
                        'NON TROUVE !' ,
                        n_CodeRet,
                        s_FONCTION
                        );

        -- Intrrompre le traitement
        RETURN;

    END IF;

    -- Tracer le Succes de la Generation du fichier flag
    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_INF,
                    'INFO TECHNIQUE : FICHIER DE DECLENCHEMENT ' ||
                    '['||chemin_vp||'/'||fichier_vp||'] ' ||
                    'GENERE AVEC SUCCES !' ,
                    0,
                    s_FONCTION
                    );

    -------------------------------------------------------
    -- RECUPERER L'IDENTIFIANT DE DECLENCHEMENT
    -- A PARTIR DE L'INFOTRAIT
    -------------------------------------------------------

    -- recuperer l'identifiant d'execution
    n_CodeRet:=PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(
                                                  t_InfoTrait,
                                                  s_IdDec
                                                  );

    IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_INF,
                        'ERREUR : ECHEC DE LECTURE DE L''IDENTIFIANT ' ||
                        'DE DECLENCHEMENT. ' ||
                        'IMPOSSIBLE DE METTRE A JOUR L''INDICATEUR ' ||
                        'DE CONFIRMATION DE LA GENERATION DU FICHIER ' ||
                        'DE DECLENCHEMENT !',
                        10,
                        s_FONCTION
                        );
         RETURN;
    END IF;

    -- Tracer l'identifiant de declenchement
    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_DBG,
                    'Identifiant de declenchement : ' ||
                    '['||s_IdDec||']' ,
                    0,
                    s_FONCTION
                    );


    -------------------------------------------------------
    -- METTRE A JOUR L'INDICATEUR DE GENERATION DU FICHIER
    -- FLAG DANS LES TABLES DE DTC
    -------------------------------------------------------


    <<MAJ_Ind_gen_flag>>
    DECLARE

        -- Texte de la requete SQL
        s_ReqSql VARCHAR2(4000):='';

    BEGIN

        -- Tracer l'objet de la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : Mise a jour de l''indicateur ' ||
                        'de Generation du fichier flag ' ||
                        'dans la table DTC de suivi des declenchements ' ||
                        '(T_DECLENCHEMENTS)',
                        0,
                        s_FONCTION
                        );

        -- Construire la requete
        s_ReqSql:=
            'UPDATE '                     || CHR(10) ||
            '    V_DTC_DECLENCHEMENT '       || CHR(10) ||
            'SET '                        || CHR(10) ||
            '    CTL_DECL = ''Y'' '       || CHR(10) ||
            'WHERE '                      || CHR(10) ||
            '    ID_DEC = '||s_IdDec
            ;

        -- Tracer la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE : [' || s_ReqSql || ']',
                        0,
                        s_FONCTION);

        -- executer la requete
        EXECUTE IMMEDIATE s_ReqSql;

        -- Tracer le nombre de lignes retournees/impactees par la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'REQUETE (UPDATE) : ' ||
                        SQL%ROWCOUNT || ' lignes modifiees',
                        SQL%ROWCOUNT,
                        s_FONCTION
                        );

        -- Valider (iventuellement) la transaction
        COMMIT;

        -- Tracer l'information retournee par la requete
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_DBG,
                        'INFO TECHNIQUE : Fichier de declenchement ' ||
                        '['||chemin_vp||'/'||fichier_vp||'] ' ||
                        'genere avec succes !',
                        0,
                        s_FONCTION
                        );

    EXCEPTION

        -- Aucun enregistrement retourne/impacte par la requete
        WHEN no_data_found THEN
            n_CodeRet := 11;
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ALR,
                            'AVERTISSEMENT : DECLENCHEMENT ' ||
                            '['||s_IdDec||'] INTROUVABLE ! ' ||
                            'IMPOSSIBLE DE METTRE A JOUR L''INDICATEUR ' ||
                            'DE CONFIRMATION DE LA GENERATION DU FICHIER ' ||
                            'DE DECLENCHEMENT !',
                            n_CodeRet,
                            s_FONCTION
                            );
            ROLLBACK;

        -- Erreurs non gerees
        WHEN others THEN
            PKG_LOG.P_ECRIRE(t_InfoTrait);
            ROLLBACK;
            PKG_LOG.P_ECRIRE(
                            t_InfoTrait,
                            PKG_LOG.gt_LOG_TYPE_ERR,
                            'ERREUR : IMPOSSIBLE DE METTRE A JOUR ' ||
                            'L''INDICATEUR DE GENERATION DU FICHIER FLAG !',
                            12,
                            s_FONCTION
                            );
            RETURN;

    END MAJ_Ind_gen_flag;


    -------------------------------------------------------
    -- FIN DU TRAITEMENT
    -------------------------------------------------------

    -- Initialiser le contenu du message sortant
    -- pour liberer la memoire
    message_vp := NULL;

    -- Retourner le Succes du traitement
    RETURN;

EXCEPTION
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        RETURN;

END P_CRE_FIC_UNIX_DTC;

-- =======================================================================
-- # PROCEDURE    : Job_Failure_Control
-- # DESCRIPTION  : Envoi mail si job Broken
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Référence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 28/05/2008 |           | FAU   | Creation
-- =======================================================================
/*
<PROCEDURE>
===============================================================================
 NOM        : P_SHUTDOWN_EVENT
 OBJET      : Mettre au statut ano les traitements DTC qui seraient en cours
              lorsque la base est arretee pour sauvegarde
===============================================================================
 PARAMETRES
 Aucun
 -------------------------------------------------------------------------------
 VALEUR RETOURNEE
 Aucune
 Remarque : Envoi mail si echec
===============================================================================
 Version                   : 1.00
 DATE                      : 16/05/08
 Auteur (+ trigramme)      : François AUVITY (FAU)
 Société                   : ALTI
 Nature du changement      : CREATION
 Référence du changement   : Fiche JIRA FMCPTA-126
 Description du changement : Création
===============================================================================
</PROCEDURE>
*/
PROCEDURE P_SHUTDOWN_EVENT
AS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'P_SHUTDOWN_EVENT';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES LOCALES
    -- -------------------------------------------------------------------

    -- Code retour
    n_CodeRet     NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Informations sur le traitement en cours
    t_InfoTrait   PKG_GLOBAL.T_INFO_TRAITEMENT;

    -- Requête SQL
    s_ReqSql VARCHAR2(500):='';

    -- Identifiant d'execution
    s_IdDec VARCHAR2(12):='';

    -- FMCP-647 : exclusion temporaire du DTC 571 en différé du marquage
    -- en KOBD. COD1EUP0, RNA1EUP0 ET EUFRHQFIN1AP ne sont pas impactes.
    -- FMCP-3174 (FMCP-2818) : nous selectionnons que les DTC en cours
    -- à la fermeture de la base de données hormis ceux en différés qui
    -- sont au dela de la date de passage de la procédure.
    CURSOR cur_Liste_Trt_en_Cours
    IS
     SELECT
           H.ID_DEC, max(H.DT_MAJ)
     FROM
     (
       SELECT
          DD.*, DDH.DT_MAJ
       FROM
          V_DTC_DECLENCHEMENT DD,
          V_DTC_DECLENCHEMENT_HISTO DDH
       WHERE
           DDH.ID_DEC = DD.ID_DEC
       AND DD.DT_FIN IS NULL
       AND DDH.DT_MAJ <= sysdate
     ) H
     GROUP BY H.ID_DEC;
BEGIN
    --Alimentation Infotrait arbitraire
    n_CodeRet:=PKG_GLOBAL.F_BUILD_INFOTRAIT(
                                           t_InfoTrait,
                                           'SHUTDOWN-BASE',
                                           'SHUTDOWN-BASE',
                                           'SYS'
                                           );

    PKG_LOG.P_AFFICHER('ShutDown Base detecte ' );
    PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_INF,
                    'ShutDown Base detecte ',
                    0,
                    s_FONCTION
                    );

   -- Maj des traitements qui sont en cours ou en attente
   -- pour la journée en cours lorsque la base se ferme (shutdown)
   -- afin d'eviter des traitements orphelins (sans statut terminé)
    FOR Cur_Liste_Trt IN cur_Liste_Trt_en_Cours
    LOOP

        s_ReqSql:=
            ' UPDATE '                                       || CHR(10) ||
            '    V_DTC_DECLENCHEMENT '                       || CHR(10) ||
            ' SET '                                          || CHR(10) ||
            '    DT_FIN = sysdate, '                         || CHR(10) ||
            '    CD_STATUT = ''' || gs_STATUT_ANO_DB || '''' || CHR(10) ||
            ' WHERE ID_DEC = ''' || Cur_Liste_Trt.ID_DEC || ''''
            ;

         EXECUTE IMMEDIATE s_ReqSql;

        PKG_LOG.P_AFFICHER('Declenchement cloturé no: [' ||Cur_Liste_Trt.ID_DEC||']' );
        PKG_LOG.P_ECRIRE(
                    t_InfoTrait,
                    PKG_LOG.gt_LOG_TYPE_INF,
                    'Declenchement cloturé no: [' ||Cur_Liste_Trt.ID_DEC||']',
                    0,
                    s_FONCTION
                    );
    END LOOP;

    -- recuperer l'identifiant d'execution
    n_CodeRet:=PKG_GLOBAL.F_GET_ID_EXEC_TRAITEMENT(
                                                  t_InfoTrait,
                                                  s_IdDec
                                                  );

    IF n_CodeRet<>PKG_GLOBAL.gn_CR_OK THEN
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_INF,
                        'ERREUR : ECHEC DE LECTURE DE L''IDENTIFIANT ' ||
                        'DE DECLENCHEMENT.',
                        PKG_GLOBAL.gn_CR_KO,
                        s_FONCTION
                        );
         RETURN;
    END IF;

    -- On met le traitement de cloture en ok
    s_ReqSql:=
            ' UPDATE '                                                  || CHR(10) ||
            '    V_DTC_DECLENCHEMENT '                                  || CHR(10) ||
            ' SET '                                                     || CHR(10) ||
            '    DT_FIN = sysdate, '                                    || CHR(10) ||
            '    CD_STATUT = (select cd_statut from v_dtc_code_retour ' || CHR(10) ||
                              'where cd_retour = '''||PKG_GLOBAL.gn_CR_OK||''')'   || CHR(10) ||
            ' WHERE ID_DEC = ''' || s_IdDec || ''''
            ;

     EXECUTE IMMEDIATE s_ReqSql;

EXCEPTION

    -- -------------------------------------------------------------------
    -- GESTION DES EXCEPTIONS
    -- -------------------------------------------------------------------

    -- Erreurs non gérées
    WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(t_InfoTrait);
        PKG_LOG.P_ECRIRE(
                        t_InfoTrait,
                        PKG_LOG.gt_LOG_TYPE_ERR,
                        'Echec Update V_DTC_DECLENCHEMENT sur fermeture base !',
                        5,
                        s_FONCTION
                        );
        s_ReqSql:=
        ' UPDATE '                                                  || CHR(10) ||
        '    V_DTC_DECLENCHEMENT '                                  || CHR(10) ||
        ' SET '                                                     || CHR(10) ||
        '    DT_FIN = sysdate, '                                    || CHR(10) ||
        '    CD_STATUT = (select cd_statut from v_dtc_code_retour ' || CHR(10) ||
                          'where cd_retour = '''||PKG_GLOBAL.gn_CR_KO||''')'   || CHR(10) ||
        ' WHERE ID_DEC = ''' || s_IdDec || ''''
        ;

        EXECUTE IMMEDIATE s_ReqSql;

        RETURN;

END P_SHUTDOWN_EVENT;

END PKG_DTC;