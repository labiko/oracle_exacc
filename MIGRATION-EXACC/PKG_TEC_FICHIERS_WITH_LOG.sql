-- ============================================================
-- PKG_TEC_FICHIERS - VERSION AVEC LOGGING UTL_FILE
-- Migration ExaCC - PARNA
-- Date : 25/02/2026
-- ============================================================
-- MODIFICATIONS : Ajout appels SP_LOG_FICHIER pour tracer
-- toutes les operations fichiers (directories, ouvertures,
-- lectures, ecritures, renommages)
-- ============================================================

create or replace PACKAGE BODY Pkg_Tec_Fichiers AS

-- ***********************************************************************
-- # PACKAGE      : PKG_TEC_FICHIERS
-- # DESCRIPTION  : Gestion de l'acces aux fichiers externes a la base
-- #                et deposes sur le filesystem unix
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | Reference | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 17/04/2006 |           | PDI    | Creation
-- # 1.1     | 13/08/2007 |           | DVA    | Ajout gestion directories
-- # 1.2     | 27/06/2008 |           | FAU    | Procedure renommage fichier
-- # 1.3     | 29/04/2009 |           | RLE    | Ajout procedure CLOB
-- # 2.0     | 25/02/2026 | EXACC     | MIGRATION | Ajout logging UTL_FILE
-- ***********************************************************************

-- =======================================================================
-- DECLARATION DES CONTANTES
-- =======================================================================

-- Nom du package
gs_PACKAGE CONSTANT VARCHAR2(25):='PKG_TEC_FICHIERS';

-- Taille maxi d'une ligne de fichier
gi_MAX_LINE_SIZE CONSTANT INTEGER:=4000;

-- =======================================================================
-- F_EXISTE_DIR : Verifier l'existence d'un directory Oracle
-- =======================================================================
FUNCTION F_EXISTE_DIR(
                      t_InfoTrait  IN         Pkg_Global.T_INFO_TRAITEMENT,
                      s_DirComplet IN         VARCHAR2,
                      b_Existe     OUT NOCOPY NUMBER
                     )
                     RETURN NUMBER
IS
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_EXISTE_DIR';
BEGIN
    IF trim(s_DirComplet) IS NULL THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : DIRECTORY RECHERCHE NON RENSEIGNE.',
                         1,
                         s_FONCTION);
        RETURN 1;
    END IF;

    b_Existe:=0;

    SELECT COUNT(*) INTO b_Existe
    FROM ALL_DIRECTORIES
    WHERE DIRECTORY_NAME=UPPER(trim(s_DirComplet));

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_EXISTE_DIR',
        p_directory_oracle  => s_DirComplet,
        p_statut            => CASE WHEN b_Existe > 0 THEN 'EXISTS' ELSE 'NOT_FOUND' END
    );

    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;
END F_EXISTE_DIR;

-- =======================================================================
-- F_GET_UNIX_PATH_FROM_DIR : Lire le chemin unix d'un directory Oracle
-- =======================================================================
FUNCTION F_GET_UNIX_PATH_FROM_DIR(
                                  t_InfoTrait   IN         Pkg_Global.T_INFO_TRAITEMENT,
                                  s_DirComplet  IN         VARCHAR2,
                                  s_DirUnixPath OUT NOCOPY VARCHAR2
                                 )
                                 RETURN NUMBER
IS
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_GET_UNIX_PATH_FROM_DIR';
BEGIN
    IF trim(s_DirComplet) IS NULL THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : LE DIRECTORY DONT ON RECHERCHE LE CHEMIN UNIX N''EST PAS RENSEIGNE !',
                         1,
                         s_FONCTION);
        RETURN 1;
    END IF;

    s_DirUnixPath:='';

    SELECT DIRECTORY_PATH INTO s_DirUnixPath
    FROM ALL_DIRECTORIES
    WHERE DIRECTORY_NAME=s_DirComplet;

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_GET_UNIX_PATH_FROM_DIR',
        p_directory_oracle  => s_DirComplet,
        p_nom_param         => 'PATH=' || s_DirUnixPath
    );

    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : LE DIRECTORY ['||s_DirComplet||'] N''EXISTE PAS !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;
END F_GET_UNIX_PATH_FROM_DIR;

-- =======================================================================
-- F_GET_DIR_FROM_UNIX_PATH : Lire le directory Oracle depuis chemin unix
-- =======================================================================
FUNCTION F_GET_DIR_FROM_UNIX_PATH(
                                  t_InfoTrait   IN         Pkg_Global.T_INFO_TRAITEMENT,
                                  s_DirUnixPath IN         VARCHAR2,
                                  s_DirComplet  OUT NOCOPY VARCHAR2
                                 )
                                 RETURN NUMBER
IS
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_GET_DIR_FROM_UNIX_PATH';
BEGIN
    IF trim(s_DirUnixPath) IS NULL THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : LE CHEMIN UNIX DONT ON RECHERCHE LE DIRECTORY N''EST PAS RENSEIGNE !',
                         1,
                         s_FONCTION);
        RETURN 1;
    END IF;

    s_DirComplet:='';

    SELECT DIRECTORY_NAME INTO s_DirComplet
    FROM ALL_DIRECTORIES
    WHERE UPPER(DIRECTORY_PATH)=s_DirUnixPath
    AND ROWNUM = 1
    ORDER BY DIRECTORY_NAME ASC;

    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : IL N''EXISTE PAS DE DIRECTORY POUR LE CHEMIN UNIX ['||s_DirUnixPath||'] !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;
END F_GET_DIR_FROM_UNIX_PATH;

-- =======================================================================
-- F_GET_DIR : FONCTION CENTRALE - Construire le nom du directory Oracle
-- =======================================================================
FUNCTION F_GET_DIR(
                   t_InfoTrait  IN         Pkg_Global.T_INFO_TRAITEMENT,
                   s_DirDemande IN         VARCHAR2,
                   s_DirComplet OUT NOCOPY VARCHAR2,
                   s_DirUnix    OUT NOCOPY VARCHAR2
                  )
                  RETURN NUMBER
IS
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_GET_DIR';
    n_CodeRet NUMBER := Pkg_Global.gn_CR_KO;
    s_CodeAppli VARCHAR2(3):='';
    b_Existe NUMBER(1):=0;
BEGIN
    IF trim(s_DirDemande) IS NULL THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : DIRECTORY DEMANDE NON RENSEIGNE.',
                         1,
                         s_FONCTION);
        RETURN 1;
    END IF;

    IF (INSTR(s_DirDemande,'DIR_TEMP') = 0
       AND INSTR(s_DirDemande,'DIR_IN') = 0
       AND INSTR(s_DirDemande,'DIR_OUT') = 0
       AND INSTR(s_DirDemande,'DIR_LOG') = 0) THEN

        n_CodeRet:=F_GET_DIR_FROM_UNIX_PATH(t_InfoTrait, s_DirDemande, s_DirComplet);
        IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
           Pkg_Log.P_ECRIRE(t_InfoTrait,
                            Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : IMPOSSIBLE DE DETERMINER LE DIRECTORY A PARTIR DU CHEMIN UNIX !',
                            4,
                            s_FONCTION);
           RETURN 4;
        END IF;

        IF (INSTR(s_DirComplet,'DIR_TEMP') = 0
           AND INSTR(s_DirComplet,'DIR_IN') = 0
           AND INSTR(s_DirComplet,'DIR_OUT') = 0
           AND INSTR(s_DirComplet,'DIR_LOG') = 0) THEN
             Pkg_Log.P_ECRIRE(t_InfoTrait,
                              Pkg_Log.gt_LOG_TYPE_ERR,
                              'ERREUR : DIRECTORY DEMANDE ['||s_DirDemande||'] INCORRECT.',
                              2,
                              s_FONCTION);
             RETURN 2;
        ELSE
            RETURN Pkg_Global.gn_CR_OK;
        END IF;
    END IF;

    n_CodeRet:=Pkg_Global.F_GET_CODE_APPLI(t_InfoTrait,s_CodeAppli);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : IMPOSSIBLE DE DETERMINER LE CODE APPLICATION !',
                         3,
                         s_FONCTION);
        RETURN 3;
    END IF;

    s_DirComplet:='';
    s_DirUnix:='';

    IF INSTR(s_DirDemande,'DIR_TEMP') <> 0 THEN
        s_DirComplet:='DIR_TEMP_'||UPPER(trim(s_CodeAppli));
    END IF;
    IF INSTR(s_DirDemande,'DIR_IN') <> 0 THEN
        s_DirComplet:='DIR_IN_'||UPPER(trim(s_CodeAppli));
    END IF;
    IF INSTR(s_DirDemande,'DIR_OUT') <> 0 THEN
        s_DirComplet:='DIR_OUT_'||UPPER(trim(s_CodeAppli));
    END IF;
    IF INSTR(s_DirDemande,'DIR_LOG') <> 0 THEN
        s_DirComplet:='DIR_LOG_'||UPPER(trim(s_CodeAppli));
    END IF;

    n_CodeRet:=F_EXISTE_DIR(t_InfoTrait,s_DirComplet,b_Existe);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ERR,
                         'ERREUR : ECHEC LORS DE LA VERIFICATION DE L''EXISTENCE DU DIRECTORY !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

    -- Plan B si directory n'existe pas
    IF b_Existe=0 THEN
        IF INSTR(s_DirDemande,'DIR_TEMP') <> 0 THEN
            s_DirComplet:='DIR_TEMP';
        END IF;
        IF INSTR(s_DirDemande,'DIR_IN') <> 0 THEN
            s_DirComplet:='DIR_IN';
        END IF;
        IF INSTR(s_DirDemande,'DIR_OUT') <> 0 THEN
            s_DirComplet:='DIR_OUT';
        END IF;
        IF INSTR(s_DirDemande,'DIR_LOG') <> 0 THEN
            s_DirComplet:='DIR_LOG';
        END IF;

        b_Existe:=0;
        n_CodeRet:=F_EXISTE_DIR(t_InfoTrait,s_DirComplet,b_Existe);
        IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait,
                             Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : ECHEC VERIFICATION EXISTENCE DIRECTORY !',
                             Pkg_Global.gn_CR_KO,
                             s_FONCTION);
            RETURN Pkg_Global.gn_CR_KO;
        END IF;

        IF b_Existe=0 THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait,
                             Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : DIRECTORY INEXISTANT !',
                             Pkg_Global.gn_CR_KO,
                             s_FONCTION);
            RETURN Pkg_Global.gn_CR_KO;
        END IF;
    END IF;

    IF b_Existe=1 THEN
        n_CodeRet:=F_GET_UNIX_PATH_FROM_DIR(t_InfoTrait, s_DirComplet, s_DirUnix);
        IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait,
                             Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : ECHEC LECTURE CHEMIN UNIX DU DIRECTORY ['||s_DirComplet||'] !',
                             Pkg_Global.gn_CR_KO,
                             s_FONCTION);
            RETURN Pkg_Global.gn_CR_KO;
        END IF;
    END IF;

    -- *** LOG AJOUT MIGRATION - TRACE MAPPING DIRECTORY ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_GET_DIR',
        p_directory_logique => s_DirDemande,
        p_directory_oracle  => s_DirComplet,
        p_nom_param         => 'CODE_APPLI=' || s_CodeAppli
    );

    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        -- *** LOG ERREUR ***
        SP_LOG_FICHIER(
            p_package_name      => 'PKG_TEC_FICHIERS',
            p_function_name     => 'F_GET_DIR',
            p_directory_logique => s_DirDemande,
            p_statut            => 'ERROR',
            p_message_erreur    => SQLERRM
        );
        RETURN Pkg_Global.gn_CR_KO;
END F_GET_DIR;

-- =======================================================================
-- F_ECRIRE_LIGNE : Ecrit une ligne dans un fichier
-- =======================================================================
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

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_ECRIRE_LIGNE',
        p_file_mode         => 'PUT_LINE',
        p_taille_octets     => LENGTH(s_Ligne),
        p_contenu_apercu    => SUBSTR(s_Ligne, 1, 200),
        p_statut            => 'OK'
    );

    RETURN 0;
EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_Ecrire(t_InfoTrait);
        SP_LOG_FICHIER(
            p_package_name      => 'PKG_TEC_FICHIERS',
            p_function_name     => 'F_ECRIRE_LIGNE',
            p_statut            => 'ERROR',
            p_message_erreur    => SQLERRM
        );
        RETURN -1;
END F_ECRIRE_LIGNE;

-- =======================================================================
-- F_FileExists : Verifier l'existence d'un fichier (version simple)
-- =======================================================================
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

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_FileExists',
        p_directory_oracle  => s_Dir,
        p_file_name         => s_FileName,
        p_taille_octets     => n_length,
        p_statut            => CASE WHEN b_exists THEN 'EXISTS' ELSE 'NOT_FOUND' END
    );

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

-- =======================================================================
-- F_FileExists : Version avec t_InfoTrait
-- =======================================================================
FUNCTION F_FileExists(
                      t_InfoTrait  IN         Pkg_Global.T_INFO_TRAITEMENT,
                      s_FileName   IN         VARCHAR2,
                      s_Dir        IN         VARCHAR2
                     )
                     RETURN VARCHAR2
AS
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_FileExists';
    b_exists    BOOLEAN;
    n_length    NUMBER;
    n_blocksize NUMBER;
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_DirComplet    VARCHAR2(30):='';
    s_DirUnix       VARCHAR2(255):='';
BEGIN
    n_CodeRet:=F_GET_DIR(t_InfoTrait,s_Dir,s_DirComplet,s_DirUnix);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                         Pkg_Log.gt_LOG_TYPE_ORA,
                         'ERREUR : IMPOSSIBLE DE RECUPERER LE DIRECTORY ORACLE CORRESPONDANT A ['||s_Dir||'] !',
                         Pkg_Global.gn_CR_KO,
                         s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

    UTL_FILE.FGETATTR(s_DirComplet, trim(s_FileName), b_exists, n_length, n_blocksize);

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_FileExists',
        p_directory_logique => s_Dir,
        p_directory_oracle  => s_DirComplet,
        p_file_name         => s_FileName,
        p_taille_octets     => n_length,
        p_statut            => CASE WHEN b_exists THEN 'EXISTS' ELSE 'NOT_FOUND' END
    );

    IF b_exists THEN
       RETURN 'TRUE';
    ELSE
       RETURN 'FALSE';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_Ecrire(t_InfoTrait);
        Pkg_Log.P_ECRIRE(t_InfoTrait,
                        Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : IMPOSSIBLE DE DETERMINER L''EXISTENCE DU FICHIER ['||s_Dir||'/'||s_FileName||'] !',
                        1,
                        s_FONCTION);
        RETURN 'FALSE';
END F_FileExists;

-- =======================================================================
-- F_FileExists : Version avec retour taille fichier
-- =======================================================================
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

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_FileExists',
        p_directory_oracle  => s_Dir,
        p_file_name         => s_FileName,
        p_taille_octets     => n_FileLength,
        p_statut            => CASE WHEN b_exists THEN 'EXISTS' ELSE 'NOT_FOUND' END
    );

    IF b_exists THEN
       RETURN 'TRUE';
    ELSE
       RETURN 'FALSE';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_AFFICHER(
                          'ERREUR : ' || SQLERRM || ' - ' ||
                          'IMPOSSIBLE DE LIRE LES ATTRIBUTS DU FICHIER ['||s_Dir||'/'||s_FileName||']'
                          );
        RETURN 'FALSE';
END F_FileExists;

-- =======================================================================
-- Fonctions utilitaires
-- =======================================================================
FUNCTION F_MetCotes(s_Chaine VARCHAR2) RETURN VARCHAR2 IS
BEGIN
  RETURN '''' || s_Chaine || '''';
END F_MetCotes;

FUNCTION F_FindPosition(s_src VARCHAR2, n_pos NUMBER, s_del VARCHAR2) RETURN VARCHAR2 IS
 i NUMBER:=0;
 ipos NUMBER:=0;
 ipos1 NUMBER:=0;
BEGIN
   WHILE (i < n_pos) LOOP
      ipos1:=ipos;
      ipos:=INSTR(s_src, s_del, ipos+1);
      i:=i+1;
   END LOOP;
   IF (ipos=0) THEN
     RETURN NULL;
   ELSE
     IF SUBSTR(s_src,(ipos1+1),(ipos-ipos1)) = s_del THEN
       RETURN NULL;
     ELSE
       RETURN SUBSTR(SUBSTR(s_src, (ipos1+1), (ipos-ipos1)), 1, LENGTH(SUBSTR(s_src, (ipos1+1), (ipos-ipos1)))-1);
     END IF;
   END IF;
END F_FindPosition;

-- =======================================================================
-- F_OUVRIR_FICHIER : Ouvrir un fichier (FONCTION CENTRALE)
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
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_OUVRIR_FICHIER';
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_DirComplet    VARCHAR2(30):='';
    s_DirUnix       VARCHAR2(255):='';
BEGIN
    IF trim(s_DirName) IS NULL THEN
        n_CodeRet:=1;
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : REPERTOIRE DU FICHIER A OUVRIR NON RENSEIGNE.',
                        n_CodeRet, s_FONCTION);
        RETURN n_CodeRet;
    END IF;

    IF trim(s_FileName) IS NULL THEN
        n_CodeRet:=2;
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : NOM DU FICHIER A OUVRIR NON RENSEIGNE !',
                        n_CodeRet, s_FONCTION);
        RETURN n_CodeRet;
    END IF;

    n_CodeRet:=F_GET_DIR(t_InfoTrait, UPPER(trim(s_DirName)), s_DirComplet, s_DirUnix);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        n_CodeRet:=6;
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : IMPOSSIBLE D''OUVRIR LE FICHIER ['||s_FileName||'] DU REPERTOIRE ['||s_DirName||'] !',
                        n_CodeRet, s_FONCTION);
        RETURN n_CodeRet;
    END IF;

    <<OuvrirFichier>>
    BEGIN
        n_FileRef := NULL;
        n_FileRef := utl_file.fopen(s_DirComplet, trim(s_FileName), UPPER(trim(s_OpenMode)), i_MaxLineSize);

        -- *** LOG AJOUT MIGRATION - OUVERTURE FICHIER ***
        SP_LOG_FICHIER(
            p_package_name      => 'PKG_TEC_FICHIERS',
            p_function_name     => 'F_OUVRIR_FICHIER',
            p_directory_logique => s_DirName,
            p_directory_oracle  => s_DirComplet,
            p_file_name         => s_FileName,
            p_file_mode         => s_OpenMode,
            p_statut            => 'OPEN'
        );

    EXCEPTION
        WHEN UTL_FILE.INVALID_MODE THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=7;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : MODE D''OUVERTURE INVALIDE !', n_CodeRet, s_FONCTION);
            SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_OUVRIR_FICHIER',
                          p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                          p_statut => 'ERROR', p_message_erreur => 'INVALID_MODE');
            RETURN n_CodeRet;
        WHEN UTL_FILE.INVALID_PATH THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=8;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : REPERTOIRE ['||s_DirComplet||'] INVALIDE !', n_CodeRet, s_FONCTION);
            SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_OUVRIR_FICHIER',
                          p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                          p_statut => 'ERROR', p_message_erreur => 'INVALID_PATH');
            RETURN n_CodeRet;
        WHEN UTL_FILE.INVALID_FILENAME THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=9;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : FICHIER INTROUVABLE !', n_CodeRet, s_FONCTION);
            SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_OUVRIR_FICHIER',
                          p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                          p_statut => 'ERROR', p_message_erreur => 'INVALID_FILENAME');
            RETURN n_CodeRet;
        WHEN UTL_FILE.ACCESS_DENIED THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=10;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : ACCES INTERDIT.', n_CodeRet, s_FONCTION);
            SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_OUVRIR_FICHIER',
                          p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                          p_statut => 'ERROR', p_message_erreur => 'ACCESS_DENIED');
            RETURN n_CodeRet;
        WHEN UTL_FILE.INVALID_MAXLINESIZE THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=11;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : TAILLE MAX LIGNE INCORRECTE !', n_CodeRet, s_FONCTION);
            SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_OUVRIR_FICHIER',
                          p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                          p_statut => 'ERROR', p_message_erreur => 'INVALID_MAXLINESIZE');
            RETURN n_CodeRet;
        WHEN UTL_FILE.INVALID_OPERATION THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=12;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : OPERATION INVALIDE !', n_CodeRet, s_FONCTION);
            SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_OUVRIR_FICHIER',
                          p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                          p_statut => 'ERROR', p_message_erreur => 'INVALID_OPERATION');
            RETURN n_CodeRet;
        WHEN UTL_FILE.FILE_OPEN THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=13;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : LE FICHIER EST DEJA OUVERT !', n_CodeRet, s_FONCTION);
            RETURN n_CodeRet;
        WHEN UTL_FILE.INTERNAL_ERROR THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=14;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                             'ERREUR : ERREUR INTERNE UTL_FILE.', n_CodeRet, s_FONCTION);
            SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_OUVRIR_FICHIER',
                          p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                          p_statut => 'ERROR', p_message_erreur => 'INTERNAL_ERROR');
            RETURN n_CodeRet;
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=15;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC OUVERTURE FICHIER !', n_CodeRet, s_FONCTION);
            SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_OUVRIR_FICHIER',
                          p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                          p_statut => 'ERROR', p_message_erreur => SQLERRM);
            RETURN n_CodeRet;
    END OuvrirFichier;

    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        n_CodeRet:=Pkg_Global.gn_CR_KO;
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : ECHEC OUVERTURE FICHIER !', n_CodeRet, s_FONCTION);
        RETURN n_CodeRet;
END F_OUVRIR_FICHIER;

-- =======================================================================
-- F_FileRename : Renommer un fichier
-- =======================================================================
FUNCTION F_FileRename(
                     ps_Dir VARCHAR2,
                     ps_FileNameSrc VARCHAR2,
                     ps_FileNameDest VARCHAR2
                     )
                     RETURN BOOLEAN
AS
BEGIN
    UTL_FILE.Frename(ps_Dir, ps_FileNameSrc, ps_Dir, ps_FileNameDest, TRUE);

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_FileRename',
        p_directory_oracle  => ps_Dir,
        p_file_name         => ps_FileNameSrc || ' -> ' || ps_FileNameDest,
        p_file_mode         => 'RENAME',
        p_statut            => 'OK'
    );

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_AFFICHER('ERREUR : ' || SQLERRM || ' - IMPOSSIBLE DE RENOMMER LE FICHIER ['||ps_Dir||'/'||ps_FileNameSrc||']');
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_FileRename',
                      p_directory_oracle => ps_Dir, p_file_name => ps_FileNameSrc,
                      p_statut => 'ERROR', p_message_erreur => SQLERRM);
        RETURN FALSE;
END F_FileRename;

-- =======================================================================
-- F_ECRIRECSV : Ecrit le resultat d'une requete dans un fichier CSV
-- =======================================================================
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
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_ECRIRECSV';
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
    n_CodeRet:=F_GET_DIR(t_InfoTrait,p_Dir,s_DirComplet,s_DirUnix);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA,
                        'ERREUR : IMPOSSIBLE DE RECUPERER LE DIRECTORY ORACLE !',
                        Pkg_Global.gn_CR_KO, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

    IF UPPER(p_mode) = 'W' THEN
        s_FileName:='#'||trim(p_filename);
    ELSE
        s_FileName:=trim(p_filename);
    END IF;

    n_CodeRet:=F_OUVRIR_FICHIER(t_InfoTrait, p_dir, s_FileName, p_mode, gi_MAX_LINE_SIZE, l_output);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

    <<Construire_curseur>>
    BEGIN
        dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);
        FOR i IN 1 .. 255 LOOP
            BEGIN
                dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
                l_colCnt := i;
            EXCEPTION
                WHEN OTHERS THEN
                    IF (SQLCODE = -1007) THEN EXIT;
                    ELSE RAISE;
                    END IF;
            END;
        END LOOP;
        dbms_sql.define_column(l_theCursor, 1, l_columnValue, 4000);
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC CONSTRUCTION CURSEUR !', n_CodeRet, s_FONCTION);
            RETURN n_CodeRet;
    END Construire_curseur;

    <<Ouvrir_curseur>>
    BEGIN
        l_status := dbms_sql.EXECUTE(l_theCursor);
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC REQUETE !', n_CodeRet, s_FONCTION);
            RETURN n_CodeRet;
    END Ouvrir_curseur;

    <<Parcourir_curseur>>
    BEGIN
        LOOP
            EXIT WHEN (dbms_sql.fetch_rows(l_theCursor) <= 0);
            l_separator := '';
            FOR i IN 1 .. l_colCnt LOOP
                dbms_sql.column_value(l_theCursor, i, l_columnValue);
                <<Ecrire_fichier>>
                BEGIN
                    utl_file.put(l_output, l_separator || l_columnValue);
                EXCEPTION
                    WHEN OTHERS THEN
                        Pkg_Log.P_ECRIRE(t_InfoTrait);
                        n_CodeRet:=Pkg_Global.gn_CR_KO;
                        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                                        'ERREUR : ECHEC ECRITURE CSV !', n_CodeRet, s_FONCTION);
                        RETURN n_CodeRet;
                END Ecrire_fichier;
                l_separator := p_separator;
            END LOOP;
            utl_file.new_line(l_output);
            l_cnt := l_cnt+1;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC LECTURE DONNEES !', n_CodeRet, s_FONCTION);
            RETURN n_CodeRet;
    END Parcourir_curseur;

    <<Fermer_curseur>>
    BEGIN
        dbms_sql.close_cursor(l_theCursor);
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC FERMETURE CURSEUR !', n_CodeRet, s_FONCTION);
            RETURN n_CodeRet;
    END Fermer_curseur;

    <<Forcer_ecriture>>
    BEGIN
        utl_file.fflush(l_output);
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC FFLUSH !', n_CodeRet, s_FONCTION);
            RETURN n_CodeRet;
    END Forcer_ecriture;

    <<Fermer_fichier>>
    BEGIN
        utl_file.fclose(l_output);
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                            'ERREUR : ECHEC FERMETURE FICHIER !', n_CodeRet, s_FONCTION);
            RETURN n_CodeRet;
    END Fermer_fichier;

    IF UPPER(p_mode) = 'W' THEN
        <<Renommer_fichier>>
        BEGIN
            utl_file.frename(s_DirComplet, s_Filename, s_DirComplet, p_Filename, TRUE);
        EXCEPTION
            WHEN OTHERS THEN
                Pkg_Log.P_ECRIRE(t_InfoTrait);
                n_CodeRet:=Pkg_Global.gn_CR_KO;
                Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                                'ERREUR : ECHEC RENOMMAGE FICHIER !', n_CodeRet, s_FONCTION);
                RETURN n_CodeRet;
        END Renommer_fichier;
    END IF;

    -- *** LOG AJOUT MIGRATION - ECRITURE CSV TERMINEE ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_ECRIRECSV',
        p_directory_logique => p_dir,
        p_directory_oracle  => s_DirComplet,
        p_file_name         => p_filename,
        p_file_mode         => p_mode,
        p_nb_lignes         => l_cnt,
        p_statut            => 'OK'
    );

    RETURN Pkg_Global.GN_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        n_CodeRet:=Pkg_Global.gn_CR_KO;
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR,
                        'ERREUR : ECHEC EXPORT CSV !', n_CodeRet, s_FONCTION);
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_ECRIRECSV',
                      p_directory_oracle => s_DirComplet, p_file_name => p_filename,
                      p_statut => 'ERROR', p_message_erreur => SQLERRM);
        RETURN n_CodeRet;
END F_EcrireCsv;

-- =======================================================================
-- F_ECRIRE_FICHIER : Ecrit un texte dans un fichier
-- =======================================================================
FUNCTION F_ECRIRE_FICHIER(
                          t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                          s_FileName  IN VARCHAR2,
                          s_Dir       IN VARCHAR2,
                          s_Texte     IN VARCHAR2,
                          s_mode      IN VARCHAR2 DEFAULT 'w'
                         )
                          RETURN NUMBER
IS
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_ECRIRE_FICHIER';
    l_output        UTL_FILE.FILE_TYPE;
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_DirComplet    VARCHAR2(30):='';
    s_DirUnix       VARCHAR2(255):='';
BEGIN
    n_CodeRet:=F_GET_DIR(t_InfoTrait,s_Dir,s_DirComplet,s_DirUnix);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA,
                         'ERREUR : IMPOSSIBLE DE GENERER LE FICHIER ['||s_FileName||'] !',
                         Pkg_Global.gn_CR_KO, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

    IF UPPER(s_mode) = 'W' THEN
        l_output := UTL_FILE.FOPEN(s_DirComplet, '#'||s_FileName, s_mode, gi_MAX_LINE_SIZE);
    ELSE
        l_output := UTL_FILE.FOPEN(s_DirComplet, s_FileName, s_mode, gi_MAX_LINE_SIZE);
    END IF;

    UTL_FILE.PUT(l_output, s_Texte);
    UTL_FILE.FFLUSH(l_output);
    UTL_FILE.FCLOSE(l_output);

    IF UPPER(s_mode) = 'W' THEN
        UTL_FILE.FRENAME(s_DirComplet, '#'||s_FileName, s_DirComplet, s_FileName, TRUE);
    END IF;

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_ECRIRE_FICHIER',
        p_directory_logique => s_Dir,
        p_directory_oracle  => s_DirComplet,
        p_file_name         => s_FileName,
        p_file_mode         => s_mode,
        p_taille_octets     => LENGTH(s_Texte),
        p_contenu_apercu    => SUBSTR(s_Texte, 1, 200),
        p_statut            => 'OK'
    );

    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN UTL_FILE.INVALID_PATH THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'CHEMIN INCORRECT', 1, s_FONCTION);
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_ECRIRE_FICHIER',
                      p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                      p_statut => 'ERROR', p_message_erreur => 'INVALID_PATH');
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.INVALID_MODE THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'MODE INVALIDE', 2, s_FONCTION);
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_ECRIRE_FICHIER',
                      p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                      p_statut => 'ERROR', p_message_erreur => 'INVALID_MODE');
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.INVALID_OPERATION THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'OPERATION INVALIDE', 3, s_FONCTION);
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_ECRIRE_FICHIER',
                      p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                      p_statut => 'ERROR', p_message_erreur => 'INVALID_OPERATION');
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'FICHIER INVALIDE', 4, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.WRITE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'ERREUR D''ECRITURE', 5, s_FONCTION);
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_ECRIRE_FICHIER',
                      p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                      p_statut => 'ERROR', p_message_erreur => 'WRITE_ERROR');
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.INTERNAL_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'INTERNAL ERROR', 6, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_ECRIRE_FICHIER',
                      p_directory_oracle => s_DirComplet, p_file_name => s_FileName,
                      p_statut => 'ERROR', p_message_erreur => SQLERRM);
        RETURN Pkg_Global.gn_CR_KO;
END F_ECRIRE_FICHIER;

-- =======================================================================
-- F_MAJ_LIGNE_FIC : Remplace une ligne dans un fichier
-- =======================================================================
FUNCTION F_MAJ_LIGNE_FIC(
                         t_InfoTrait     IN Pkg_Global.T_INFO_TRAITEMENT,
                         s_AncienneLigne IN VARCHAR2,
                         s_NouvelleLigne IN VARCHAR2,
                         s_NomFic        IN VARCHAR2,
                         s_RepFic        IN VARCHAR2
                        )
                         RETURN NUMBER
IS
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_MAJ_LIGNE_FIC';
    l_FichierIn   UTL_FILE.FILE_TYPE;
    l_FichierOut  UTL_FILE.FILE_TYPE;
    s_Ligne VARCHAR2(4000);
    s_NomTemp VARCHAR2(64):='#'||s_NomFic||'_temp';
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_DirComplet    VARCHAR2(30):='';
    s_DirUnix       VARCHAR2(255):='';
    n_LignesLues    NUMBER := 0;
BEGIN
    n_CodeRet:=F_GET_DIR(t_InfoTrait,s_RepFic,s_DirComplet,s_DirUnix);
    IF n_CodeRet<>Pkg_Global.gn_CR_OK THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA,
                         'ERREUR : IMPOSSIBLE DE METTRE A JOUR UNE LIGNE DANS LE FICHIER ['||s_NomFic||'] !',
                         Pkg_Global.gn_CR_KO, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    END IF;

    -- Ouverture fichier source en lecture
    BEGIN
        l_FichierIn := UTL_FILE.FOPEN(s_DirComplet, s_NomFic, 'R', gi_MAX_LINE_SIZE);
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_AFFICHER('ERREUR : '||SQLERRM || ' (FICHIER : ['||s_DirComplet||'/'||s_NomFic||'])');
            RETURN Pkg_Global.gn_CR_KO;
    END;

    -- Ouverture fichier temp en ecriture
    BEGIN
        l_FichierOut := UTL_FILE.FOPEN(s_DirComplet, s_NomTemp, 'W', gi_MAX_LINE_SIZE);
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_AFFICHER('ERREUR : '||SQLERRM || ' (FICHIER : ['||s_DirComplet||'/'||s_NomTemp||'])');
            RETURN Pkg_Global.gn_CR_KO;
    END;

    -- Traitement
    BEGIN
         LOOP
            UTL_FILE.GET_LINE(l_FichierIn, s_Ligne);
            n_LignesLues := n_LignesLues + 1;
            IF INSTR(s_Ligne, s_AncienneLigne) <> 0 THEN
               s_Ligne := s_NouvelleLigne;
            END IF;
            UTL_FILE.PUT_LINE(l_FichierOut, s_Ligne);
         END LOOP;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
             UTL_FILE.FFLUSH(l_FichierOut);
             IF UTL_FILE.IS_OPEN(l_FichierIn) THEN
                UTL_FILE.FCLOSE(l_FichierIn);
             END IF;
             IF UTL_FILE.IS_OPEN(l_FichierOut) THEN
                UTL_FILE.FCLOSE(l_FichierOut);
             END IF;
    END;

    UTL_FILE.FRENAME(s_DirComplet, s_NomTemp, s_DirComplet, s_NomFic, TRUE);

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_MAJ_LIGNE_FIC',
        p_directory_logique => s_RepFic,
        p_directory_oracle  => s_DirComplet,
        p_file_name         => s_NomFic,
        p_file_mode         => 'R+W',
        p_nb_lignes         => n_LignesLues,
        p_nom_param         => 'REPLACE: ' || SUBSTR(s_AncienneLigne, 1, 50),
        p_statut            => 'OK'
    );

    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN UTL_FILE.INVALID_PATH THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'CHEMIN INCORRECT', 1, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.INVALID_MODE THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'MODE INVALIDE', 2, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.INVALID_OPERATION THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'OPERATION INVALIDE', 3, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.INVALID_FILEHANDLE THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'FICHIER INVALIDE', 4, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.WRITE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'ERREUR D''ECRITURE', 5, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN UTL_FILE.INTERNAL_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'INTERNAL ERROR', 6, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN OTHERS THEN
         Pkg_Log.P_ECRIRE(t_InfoTrait);
         IF UTL_FILE.IS_OPEN(l_FichierIn) THEN
            UTL_FILE.FCLOSE(l_FichierIn);
         END IF;
         IF UTL_FILE.IS_OPEN(l_FichierOut) THEN
             UTL_FILE.FCLOSE(l_FichierOut);
         END IF;
         SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_MAJ_LIGNE_FIC',
                       p_directory_oracle => s_DirComplet, p_file_name => s_NomFic,
                       p_statut => 'ERROR', p_message_erreur => SQLERRM);
         RETURN Pkg_Global.gn_CR_KO;
END F_MAJ_LIGNE_FIC;

-- =======================================================================
-- F_ECRIRE_LIGNE_CLOB : Ecrit une ligne dans un CLOB
-- =======================================================================
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
                        c_Texte     IN VARCHAR2 default 'TEXTE')
                        RETURN INTEGER
IS
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_ECRIRE_LIGNE_CLOB';
    l_Output        CLOB:=empty_clob();
    l_Entete        CLOB:=empty_clob();
    s_req           VARCHAR(255):= '';
    s_Dec           VARCHAR(15):= '';
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
BEGIN
    n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,s_Dec);

    dbms_lob.createtemporary(l_Output, TRUE);
    dbms_lob.open(l_Output, dbms_lob.lob_readwrite);

    s_req := 'select '||c_Texte ||' from '||t_Table ||
             ' where '||c_Dec||' = :s_Dec and '||c_Param||' = :s_Param and '||c_Ordre||' = :n_Ordre FOR update';

    EXECUTE IMMEDIATE s_req into l_Output using s_Dec,s_Param,n_Ordre;

    if p_Entete = 'N' then
        DBMS_LOB.WRITEAPPEND(l_Output, length(chr(10)||s_Ligne),(chr(10)||s_Ligne));
    else
        begin
            dbms_lob.createtemporary(l_Entete, TRUE);
            dbms_lob.open(l_Entete, dbms_lob.lob_readwrite);
            l_Entete := To_Clob(s_Ligne||(chr(10)));
            dbms_lob.APPEND(l_Entete,l_Output);
            l_Output := l_Entete;
            DBMS_LOB.FREETEMPORARY(l_Entete);
        end;
    end if;

    s_req := 'Update '||t_Table||' set '||c_Texte ||' = :l_Output where '||c_Dec||' = :s_Dec and '||c_Param||' = :s_Param and '||c_Ordre||' = :n_Ordre';
    EXECUTE IMMEDIATE s_req using l_Output,s_Dec,s_Param,n_Ordre;

    RETURN Pkg_Global.GN_CR_OK;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'PAS DE DONNEES TROUVEES', 7, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN VALUE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'VALUE ERROR', 8, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;
END F_ECRIRE_LIGNE_CLOB;

-- =======================================================================
-- F_ECRIRECSV_CLOB : Ecrit CSV dans table CLOB
-- =======================================================================
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
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_ECRIRECSV_CLOB';
    l_output        CLOB:=empty_clob();
    l_theCursor     INTEGER DEFAULT dbms_sql.open_cursor;
    l_columnValue   VARCHAR2(2000);
    l_status        INTEGER;
    l_colCnt        NUMBER DEFAULT 0;
    l_separator     VARCHAR2(10) DEFAULT '';
    l_cnt           NUMBER DEFAULT 0;
    l_ligne         VARCHAR2(4000);
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_req           VARCHAR2(255):='';
    s_Dec           VARCHAR(15):='';
BEGIN
    n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,s_Dec);

    dbms_lob.createtemporary(l_output, TRUE);
    dbms_lob.open(l_output, dbms_lob.lob_readwrite);

    <<Construire_curseur>>
    BEGIN
        dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);
        FOR i IN 1 .. 255 LOOP
            BEGIN
                dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
                l_colCnt := i;
            EXCEPTION
                WHEN OTHERS THEN
                    IF (SQLCODE = -1007) THEN EXIT;
                    ELSE RAISE;
                    END IF;
            END;
        END LOOP;
        dbms_sql.define_column(l_theCursor, 1, l_columnValue, 4000);
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR, 'ERREUR CURSEUR !', n_CodeRet, s_FONCTION);
            RETURN n_CodeRet;
    END Construire_curseur;

    <<Ouvrir_curseur>>
    BEGIN
        l_status := dbms_sql.EXECUTE(l_theCursor);
    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ERR, 'ERREUR REQUETE !', n_CodeRet, s_FONCTION);
            RETURN n_CodeRet;
    END Ouvrir_curseur;

    <<Parcourir_curseur>>
    BEGIN
        LOOP
            EXIT WHEN (dbms_sql.fetch_rows(l_theCursor) <= 0);
            l_ligne := '';
            l_separator := '';
            FOR i IN 1 .. l_colCnt LOOP
                dbms_sql.column_value(l_theCursor, i, l_columnValue);
                <<Alimenter_CLOB>>
                BEGIN
                    l_ligne := l_ligne || l_separator || l_columnValue;
                EXCEPTION
                    WHEN OTHERS THEN
                        Pkg_Log.P_ECRIRE(t_InfoTrait);
                        n_CodeRet:=Pkg_Global.gn_CR_KO;
                        RETURN n_CodeRet;
                END Alimenter_CLOB;
                l_separator := p_separator;
            END LOOP;
            l_cnt := l_cnt+1;
            DBMS_LOB.WRITEAPPEND(l_output, length(l_ligne||chr(10)), l_ligne||chr(10));
        END LOOP;

        <<Inserer_CLOB>>
        BEGIN
            s_req := 'Insert into '||t_Table||'('||c_Dec||','||c_Param||','||c_Ordre||','||c_Texte||','||s_Dir||','||s_File||') values (:s_Dec,:s_Param,:n_Ordre,:l_output,:s_DirName,:FileName)';
            EXECUTE IMMEDIATE s_req using s_Dec,s_Param,n_Ordre,l_output,s_DirName,s_FileName;
        EXCEPTION
            WHEN OTHERS THEN
                Pkg_Log.P_ECRIRE(t_InfoTrait);
                n_CodeRet:=Pkg_Global.gn_CR_KO;
                RETURN n_CodeRet;
        END Inserer_CLOB;

    EXCEPTION
        WHEN OTHERS THEN
            Pkg_Log.P_ECRIRE(t_InfoTrait);
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Parcourir_curseur;

    <<Fermer_curseur>>
    BEGIN
        dbms_sql.close_cursor(l_theCursor);
    EXCEPTION
        WHEN OTHERS THEN
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Fermer_curseur;

    -- *** LOG AJOUT MIGRATION - CLOB CREE ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_ECRIRECSV_CLOB',
        p_directory_logique => s_DirName,
        p_file_name         => s_FileName,
        p_file_mode         => 'CLOB',
        p_nb_lignes         => l_cnt,
        p_taille_octets     => DBMS_LOB.GETLENGTH(l_output),
        p_nom_param         => s_Param,
        p_statut            => 'OK'
    );

    RETURN Pkg_Global.GN_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        n_CodeRet:=Pkg_Global.gn_CR_KO;
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_ECRIRECSV_CLOB',
                      p_file_name => s_FileName, p_statut => 'ERROR', p_message_erreur => SQLERRM);
        RETURN n_CodeRet;
END F_EcrireCsv_CLOB;

-- =======================================================================
-- F_ECRIRECSV_CLOB_SILENTLY : Version silencieuse (sans logs verbeux)
-- =======================================================================
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
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_req           VARCHAR2(255):='';
    s_Dec           VARCHAR(15):='';
BEGIN
    n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait, s_Dec);

    dbms_lob.createtemporary(l_output, TRUE);
    dbms_lob.open(l_output, dbms_lob.lob_readwrite);

    <<Construire_curseur>>
    BEGIN
        dbms_sql.parse(l_theCursor, p_query, dbms_sql.native);
        FOR i IN 1 .. 255 LOOP
            BEGIN
                dbms_sql.define_column(l_theCursor, i, l_columnValue, 4000);
                l_colCnt := i;
            EXCEPTION
                WHEN OTHERS THEN
                    IF (SQLCODE = -1007) THEN EXIT;
                    ELSE RAISE;
                    END IF;
            END;
        END LOOP;
        dbms_sql.define_column(l_theCursor, 1, l_columnValue, 4000);
    EXCEPTION
        WHEN OTHERS THEN
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Construire_curseur;

    <<Ouvrir_curseur>>
    BEGIN
        l_status := dbms_sql.EXECUTE(l_theCursor);
    EXCEPTION
        WHEN OTHERS THEN
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Ouvrir_curseur;

    <<Parcourir_curseur>>
    BEGIN
        LOOP
            EXIT WHEN (dbms_sql.fetch_rows(l_theCursor) <= 0);
            l_ligne := '';
            l_separator := '';
            FOR i IN 1 .. l_colCnt LOOP
                dbms_sql.column_value(l_theCursor, i, l_columnValue);
                <<Alimenter_CLOB>>
                BEGIN
                    l_ligne := l_ligne || l_separator || l_columnValue;
                EXCEPTION
                    WHEN OTHERS THEN
                        n_CodeRet:=Pkg_Global.gn_CR_KO;
                        RETURN n_CodeRet;
                END Alimenter_CLOB;
                l_separator := p_separator;
            END LOOP;
            l_cnt := l_cnt+1;
            DBMS_LOB.WRITEAPPEND(l_output, length(l_ligne||chr(10)), l_ligne||chr(10));
        END LOOP;

        <<Inserer_CLOB>>
        BEGIN
            s_req := 'Insert into '||t_Table||'('||c_Dec||','||c_Param||','||c_Ordre||','||c_Texte||','||s_Dir||','||s_File||') values (:s_Dec,:s_Param,:n_Ordre,:l_output,:s_DirName,:FileName)';
            EXECUTE IMMEDIATE s_req USING s_Dec,s_Param,n_Ordre,l_output,s_DirName,s_FileName;
        EXCEPTION
            WHEN OTHERS THEN
                n_CodeRet:=Pkg_Global.gn_CR_KO;
                RETURN n_CodeRet;
        END Inserer_CLOB;

    EXCEPTION
        WHEN OTHERS THEN
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Parcourir_curseur;

    <<Fermer_curseur>>
    BEGIN
        dbms_sql.close_cursor(l_theCursor);
    EXCEPTION
        WHEN OTHERS THEN
            n_CodeRet:=Pkg_Global.gn_CR_KO;
            RETURN n_CodeRet;
    END Fermer_curseur;

    -- *** LOG AJOUT MIGRATION - CLOB SILENTLY ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_ECRIRECSV_CLOB_SILENTLY',
        p_directory_logique => s_DirName,
        p_file_name         => s_FileName,
        p_file_mode         => 'CLOB',
        p_nb_lignes         => l_cnt,
        p_taille_octets     => DBMS_LOB.GETLENGTH(l_output),
        p_nom_param         => s_Param,
        p_statut            => 'OK'
    );

    RETURN Pkg_Global.GN_CR_OK;

EXCEPTION
    WHEN OTHERS THEN
        n_CodeRet:=Pkg_Global.gn_CR_KO;
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_ECRIRECSV_CLOB_SILENTLY',
                      p_file_name => s_FileName, p_statut => 'ERROR', p_message_erreur => SQLERRM);
        RETURN n_CodeRet;
END F_EcrireCsv_CLOB_SILENTLY;

-- =======================================================================
-- F_ECRIRE_CLOB : Ecrit un texte dans table CLOB
-- =======================================================================
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
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_ECRIRE_FICHIER_CLOB';
    l_output        CLOB:=empty_clob();
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_req           VARCHAR(255):= '';
    s_Dec           VARCHAR(15):='';
BEGIN
    n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,s_Dec);

    dbms_lob.createtemporary(l_output, TRUE);
    dbms_lob.open(l_output, dbms_lob.lob_readwrite);

    DBMS_LOB.WRITEAPPEND(l_output, length(s_Texte), s_Texte);

    s_req := 'Insert into '||t_Table||'('||c_Dec||','||c_Param||','||c_Ordre||','||c_Texte||','||s_Dir||','||s_File||') values (:s_Dec,:s_Param,:n_Ordre,:l_output,:s_DirName,:FileName)';
    EXECUTE IMMEDIATE s_req using s_Dec,s_Param,n_Ordre,l_output,s_DirName,s_FileName;

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_ECRIRE_CLOB',
        p_directory_logique => s_DirName,
        p_file_name         => s_FileName,
        p_file_mode         => 'CLOB',
        p_taille_octets     => LENGTH(s_Texte),
        p_nom_param         => s_Param,
        p_contenu_apercu    => SUBSTR(s_Texte, 1, 200),
        p_statut            => 'OK'
    );

    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'PAS DE DONNEES TROUVEES', 7, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN VALUE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'VALUE ERROR', 8, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        SP_LOG_FICHIER(p_package_name => 'PKG_TEC_FICHIERS', p_function_name => 'F_ECRIRE_CLOB',
                      p_file_name => s_FileName, p_statut => 'ERROR', p_message_erreur => SQLERRM);
        RETURN Pkg_Global.gn_CR_KO;
END F_ECRIRE_CLOB;

-- =======================================================================
-- F_VIDER_CLOB : Vide la table CLOB pour un traitement
-- =======================================================================
FUNCTION F_VIDER_CLOB(
                          t_InfoTrait IN Pkg_Global.T_INFO_TRAITEMENT,
                          t_Table     IN VARCHAR2 default 'TA_CLOB',
                          c_Dec       IN VARCHAR2 default 'ID_DEC'
                      )
                          RETURN NUMBER
IS
    s_FONCTION CONSTANT VARCHAR2(64):= gs_PACKAGE || '.' || 'F_VIDER_CLOB';
    l_output        CLOB:=empty_clob();
    n_CodeRet       NUMBER:=Pkg_Global.gn_CR_KO;
    s_req           VARCHAR(255):= '';
    s_Dec           VARCHAR(15) := '';
BEGIN
    n_CodeRet := Pkg_Global.F_GET_ID_EXEC_TRAITEMENT(t_InfoTrait,s_Dec);

    s_req := 'delete from '||t_Table||' where '||c_Dec||' = :s_Dec';
    EXECUTE IMMEDIATE s_req using s_Dec;

    -- *** LOG AJOUT MIGRATION ***
    SP_LOG_FICHIER(
        p_package_name      => 'PKG_TEC_FICHIERS',
        p_function_name     => 'F_VIDER_CLOB',
        p_nom_param         => 'TABLE=' || t_Table || ' ID_DEC=' || s_Dec,
        p_statut            => 'PURGE'
    );

    RETURN Pkg_Global.gn_CR_OK;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'PAS DE DONNEES TROUVEES', 7, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN VALUE_ERROR THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait, Pkg_Log.gt_LOG_TYPE_ORA, 'VALUE ERROR', 8, s_FONCTION);
        RETURN Pkg_Global.gn_CR_KO;
    WHEN OTHERS THEN
        Pkg_Log.P_ECRIRE(t_InfoTrait);
        RETURN Pkg_Global.gn_CR_KO;
END F_VIDER_CLOB;

-- =======================================================================
-- FIN DU PACKAGE PKG_TEC_FICHIERS (VERSION AVEC LOGGING)
-- =======================================================================

END Pkg_Tec_Fichiers;
/

-- ============================================================
-- RESUME DES MODIFICATIONS POUR LE LOGGING
-- ============================================================
-- Fonctions instrumentees avec SP_LOG_FICHIER :
--
-- 1. F_EXISTE_DIR         - Log existence directory
-- 2. F_GET_UNIX_PATH_FROM_DIR - Log resolution path
-- 3. F_GET_DIR            - Log mapping logique -> Oracle (CENTRALE)
-- 4. F_FileExists (3x)    - Log verification existence fichier
-- 5. F_OUVRIR_FICHIER     - Log ouverture fichier (CENTRALE)
-- 6. F_FileRename         - Log renommage fichier
-- 7. F_ECRIRECSV          - Log ecriture CSV
-- 8. F_ECRIRE_FICHIER     - Log ecriture fichier
-- 9. F_MAJ_LIGNE_FIC      - Log modification fichier
-- 10. F_ECRIRECSV_CLOB    - Log creation CLOB
-- 11. F_ECRIRECSV_CLOB_SILENTLY - Log creation CLOB
-- 12. F_ECRIRE_CLOB       - Log creation CLOB
-- 13. F_VIDER_CLOB        - Log purge CLOB
--
-- PREREQUIS : Deployer TABLE_LOG_FICHIERS_PACKAGES.sql avant ce package
-- ============================================================
