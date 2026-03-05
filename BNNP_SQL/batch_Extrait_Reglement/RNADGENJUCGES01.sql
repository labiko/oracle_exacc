-- ============================================================================
-- PR_RN_IMPORT_GESTION.SQL : VERSION AVEC TRAÇAGE COMPLET
-- ============================================================================
-- VERSION AMÉLIORÉE - Traçage différentiel 22.36 vs 2817
-- Date modification : 07/02/2026
-- Modifications :
--   1. Log de CHAQUE transaction insérée (PAYMENTREFERENCE + MONTANT + CLIENT)
--   2. Log des COMMIT avec compteur
--   3. Log du test EXISTS pour TA_RN_GESTION_JC (avant INSERT)
--   4. Log spécifique pour détecter 22.36 et 2817 dans le XML
-- ============================================================================

WHENEVER SQLERROR EXIT 202;
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
SET SERVEROUTPUT ON
SET VERIFY OFF
SET LINESIZE 2000

DECLARE

-- ============================================================================
-- CONSTANTE POUR LE NOM DE LA PROCEDURE (LOGS)
-- ============================================================================
c_NOM_PROCEDURE CONSTANT VARCHAR2(50) := 'PR_RN_IMPORT_GESTION_JC_TRACE';

-- Variables d'import dans la table TA_RN_IMPORT_GESTION_JC
Var_DATECREATION TA_RN_IMPORT_GESTION_JC.DATECREATION%TYPE :='';
Var_FROMDATETIME TA_RN_IMPORT_GESTION_JC.FROMDATETIME%TYPE :='';
Var_TODATETIME TA_RN_IMPORT_GESTION_JC.TODATETIME%TYPE :='';
Var_TYPEREGLEMENT TA_RN_IMPORT_GESTION_JC.TYPEREGLEMENT%TYPE :='';
Var_STATUTREGLEMENT TA_RN_IMPORT_GESTION_JC.STATUTREGLEMENT%TYPE :='';
Var_IDENTIFICATION TA_RN_IMPORT_GESTION_JC.IDENTIFICATION%TYPE :='';
Var_ISSUER TA_RN_IMPORT_GESTION_JC.ISSUER%TYPE :='';
Var_SCHEME TA_RN_IMPORT_GESTION_JC.SCHEME%TYPE :='';
Var_PAYMENTREFERENCE TA_RN_IMPORT_GESTION_JC.PAYMENTREFERENCE%TYPE :='';
Var_POLICYREFERENCE TA_RN_IMPORT_GESTION_JC.POLICYREFERENCE%TYPE :='';
Var_NUMEROCLIENT TA_RN_IMPORT_GESTION_JC.NUMEROCLIENT%TYPE :='';
Var_NOMCLIENT TA_RN_IMPORT_GESTION_JC.NOMCLIENT%TYPE :='';
Var_SETTLEMENTMODE TA_RN_IMPORT_GESTION_JC.SETTLEMENTMODE%TYPE :='';
Var_BANKCODE TA_RN_IMPORT_GESTION_JC.BANKCODE%TYPE :='';
Var_BRANCHCODE TA_RN_IMPORT_GESTION_JC.BRANCHCODE%TYPE :='';
Var_IDENTIFICATIONRIB TA_RN_IMPORT_GESTION_JC.IDENTIFICATIONRIB%TYPE :='';
Var_RIBCHECKDIGIT TA_RN_IMPORT_GESTION_JC.RIBCHECKDIGIT%TYPE :='';
Var_RIBCOMPLET TA_RN_IMPORT_GESTION_JC.RIBCOMPLET%TYPE :='';
Var_VALUEDATE TA_RN_IMPORT_GESTION_JC.VALUEDATE%TYPE :='';
Var_TRADEDATE TA_RN_IMPORT_GESTION_JC.TRADEDATE%TYPE :='';
Var_OPERATIONNETAMOUNT TA_RN_IMPORT_GESTION_JC.OPERATIONNETAMOUNT%TYPE :='';
Var_OPERATIONNETAMOUNTCURRENCY TA_RN_IMPORT_GESTION_JC.OPERATIONNETAMOUNTCURRENCY%TYPE :='';
Var_BENEFICIARYNAME TA_RN_IMPORT_GESTION_JC.BENEFICIARYNAME%TYPE :='';
Var_BENEFICIARYFIRST TA_RN_IMPORT_GESTION_JC.BENEFICIARYFIRST%TYPE :='';
Var_BENEFICIARYREFERENCE TA_RN_IMPORT_GESTION_JC.BENEFICIARYREFERENCE%TYPE :='';
Var_PRESENTMENTREFERENCE TA_RN_IMPORT_GESTION_JC.PRESENTMENTREFERENCE%TYPE :='';
Var_CHEQUEREFERENCE TA_RN_IMPORT_GESTION_JC.CHEQUEREFERENCE%TYPE :='';
Var_DEPOSITSLIPREFERENCE TA_RN_IMPORT_GESTION_JC.DEPOSITSLIPREFERENCE%TYPE :='';
Var_CREDITSLIPREFERENCE TA_RN_IMPORT_GESTION_JC.CREDITSLIPREFERENCE%TYPE :='';
Var_COMMENTAIRE TA_RN_IMPORT_GESTION_JC.COMMENTAIRE%TYPE :='';
Var_CREATIONDATE TA_RN_IMPORT_GESTION_JC.CREATIONDATE%TYPE :='';
Var_DATECOMPTAORIG TA_RN_IMPORT_GESTION_JC.DATECOMPTAORIG%TYPE :='';
Var_NOMSOCIETE TA_RN_IMPORT_GESTION_JC.NOMSOCIETE%TYPE :='';
Var_LIBELLEMODEREGLEMENT TA_RN_IMPORT_GESTION_JC.LIBELLEMODEREGLEMENT%TYPE :='';

-- Variables pour curseur Curseur_ZonesParCompte
VarCurs_ID_COMPTE_ACCURATE      TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE%TYPE;
VarCurs_NUM_COMPTE_ACCURATE     TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE%TYPE;
VarCurs_NOM_CHAMP               TA_RN_FEEDER_STD.NOM_CHAMP%TYPE;
VarCurs_NOM_BALISE              TA_RN_BALISE.NOM_BALISE%TYPE;

-- Variables de référence pour curseur Curseur_ZonesParCompte
Var_Ref_ID_COMPTE_ACCURATE      TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE%TYPE;
Var_Ref_NUM_COMPTE_ACCURATE     TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE%TYPE;
Var_Ref_NOM_CHAMP               TA_RN_FEEDER_STD.NOM_CHAMP%TYPE;
Var_Ref_NOM_BALISE              TA_RN_BALISE.NOM_BALISE%TYPE;

-- Variables pour Insert TA_RN_IMPORT_GESTION_JC
ListeChampsImport VARCHAR2(2048) :='(DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,
SCHEME,PAYMENTREFERENCE,POLICYREFERENCE,NUMEROCLIENT,NOMCLIENT,SETTLEMENTMODE,BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,
VALUEDATE,TRADEDATE,OPERATIONNETAMOUNT,OPERATIONNETAMOUNTCURRENCY,BENEFICIARYNAME,BENEFICIARYFIRST,BENEFICIARYREFERENCE,
PRESENTMENTREFERENCE,CHEQUEREFERENCE,DEPOSITSLIPREFERENCE,CREDITSLIPREFERENCE,COMMENTAIRE,CREATIONDATE,RIBCOMPLET,ID_CHARGEMENT_GESTION, DATECOMPTAORIG)';

ListeChampsExport VARCHAR2(1024);
ListeValeursImport VARCHAR2(2048);

-- Variables de chargement
Var_ID_CHARGEMENT_GESTION INTEGER :=0;

-- Variable formule
Var_FORMULE   TA_RN_FORMULES_GESTION.FORMULE%TYPE;

-- Variables diverses
v_step  NUMBER(4) := 0;
Var_N_Uncommitted NUMBER := 0;
bSociete NUMBER(2) := 0;
bDepAccount NUMBER(2) := 0;
bBeneficiary NUMBER(2) := 0;
bRegltIdentification NUMBER(2) := 0;
bContext NUMBER(2) := 0;

LIGNE_FLUX_GESTION VARCHAR2(512);
s_Ligne VARCHAR2(1000);
SEPARATEUR_FLUX_SORTIE CHAR(1):=',';
Var_Source CONSTANT CHAR(4) :='GEST';

-- ============================================================================
-- NOUVELLES VARIABLES POUR LE TRAÇAGE
-- ============================================================================
v_total_transactions_lues NUMBER := 0;
v_found_22_36 BOOLEAN := FALSE;
v_found_2817 BOOLEAN := FALSE;

-- Définition des erreurs applicatives
PB_LECTURE_TX_REGLT_GEST EXCEPTION;
SUPPRESSION_IMPOSSIBLE EXCEPTION;
PARAM_GESTION_IMPOSSIBLE EXCEPTION;
PB_INSERT_TA_RN_IMP_GEST_JC EXCEPTION;
PB_INSERT_TA_RN_EXPORT_JC EXCEPTION;
PB_TW_EXPORT_GEST_JC EXCEPTION;
PB_GENERATION_CLOB_GEST_JC EXCEPTION;
PB_ID_CHARGEMENT EXCEPTION;
PB_RECHERCHE_LIBELLE EXCEPTION;

-- Curseurs
CURSOR Curseur_ZonesParCompte IS
SELECT DISTINCT
    TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE,
    TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE,
    TA_RN_FEEDER_STD.NOM_CHAMP,
    TA_RN_BALISE.NOM_BALISE
 FROM TA_RN_COMPTE_ACCURATE,
      TA_RN_BALISE,
      TA_RN_FEEDER_STD,
      TA_RN_BALISE_PAR_COMPTE
WHERE TA_RN_COMPTE_ACCURATE.FLAG_ACTIF='O'
  AND TA_RN_COMPTE_ACCURATE.TYPE_RAPPRO='J'
  AND TA_RN_BALISE_PAR_COMPTE.ID_BALISE=TA_RN_BALISE.ID_BALISE
  AND TA_RN_BALISE_PAR_COMPTE.ID_COMPTE_ACCURATE=TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE
  AND TA_RN_BALISE_PAR_COMPTE.NUM_COL_FEEDER=TA_RN_FEEDER_STD.NUM_COL_FEEDER
  AND TA_RN_BALISE.TYPE_BALISE='GEST'
ORDER BY
	TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE,
	TA_RN_FEEDER_STD.NOM_CHAMP,
	TA_RN_BALISE.NOM_BALISE;

CURSOR Curseur_Lignes_XML IS
SELECT  TT2.column_value AS xml_line
FROM
	TX_REGLT_GEST SS,
	TABLE(PIPE_CLOB(SS.bb,4000, CHR(10))) TT,
	TABLE(STRING_TOKENIZE(TT.column_value, CHR(10))) TT2;

TYPE T_REG_XML IS TABLE OF Curseur_Lignes_XML%ROWTYPE;
tab_REG_XML T_REG_XML;
idx_XML NUMBER;

/* ============================================================================ */
/* PROCEDURE P_LOG : Enregistrement dans la table de logs                       */
/* ============================================================================ */
PROCEDURE P_LOG (
    p_type_log       IN VARCHAR2,
    p_message        IN VARCHAR2,
    p_nom_balise     IN VARCHAR2 DEFAULT NULL,
    p_valeur         IN VARCHAR2 DEFAULT NULL,
    p_code_erreur    IN VARCHAR2 DEFAULT NULL,
    p_stack_trace    IN CLOB DEFAULT NULL,
    p_etape          IN NUMBER DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO TA_RN_LOG_EXECUTION (
        NOM_PROCEDURE,
        TYPE_LOG,
        NOM_BALISE,
        VALEUR_EXTRAITE,
        MESSAGE,
        CODE_ERREUR,
        STACK_TRACE,
        ID_CHARGEMENT,
        ETAPE
    ) VALUES (
        c_NOM_PROCEDURE,
        p_type_log,
        p_nom_balise,
        SUBSTR(p_valeur, 1, 4000),
        SUBSTR(p_message, 1, 4000),
        p_code_erreur,
        p_stack_trace,
        Var_ID_CHARGEMENT_GESTION,
        p_etape
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur P_LOG: ' || SQLERRM);
END P_LOG;

/* ************************* */
/* --- Extraction Balise --- */
/* ************************* */
FUNCTION ExtraireBalise(Balise IN varchar2, Chaine IN varchar2) RETURN varchar2 IS
position_deb integer;
longueur integer;
valeur_balise varchar2(250);
BEGIN
	 position_deb := INSTR(Chaine,Balise) + LENGTH(Balise);
	 longueur := INSTR(Chaine,SUBSTR(Balise,1,1)||'/'||SUBSTR(Balise,2)) - position_deb;
	 valeur_balise := SUBSTR(Chaine,position_deb,longueur);
	 valeur_balise := TRIM(SUBSTR(valeur_balise,1,250));
	 valeur_balise := REPLACE(valeur_balise,'''',' ');
	IF Balise = '<RIBCheckDigit>' THEN
	  IF LENGTH(valeur_balise) = 1 THEN
		  valeur_balise := '0'||valeur_balise;
	  END IF;
	END IF;
	RETURN valeur_balise;
END ExtraireBalise;

/* ****************************** */
/* --- Extraction Balise Date --- */
/* ****************************** */
FUNCTION ExtraireBaliseDate(Balise IN varchar2, Chaine IN varchar2) RETURN varchar2 IS
position_deb integer;
longueur integer;
valeur_balise varchar2(128);
BEGIN
	 position_deb := INSTR(Chaine,Balise) + LENGTH(Balise);
	 longueur := INSTR(Chaine,SUBSTR(Balise,1,1)||'/'||SUBSTR(Balise,2)) - position_deb;
	valeur_balise := SUBSTR(Chaine,position_deb,longueur);
	IF valeur_balise <> 'T' THEN
		valeur_balise := SUBSTR(valeur_balise,9,2)||'/'||SUBSTR(valeur_balise,6,2)||'/'||SUBSTR(valeur_balise,1,4);
	ELSE
		valeur_balise := '';
	END IF;
	RETURN valeur_balise;
END ExtraireBaliseDate;

/* ***************************************** */
/* --- Extraction Balise de type montant --- */
/* ***************************************** */
FUNCTION ExtraireBaliseMontant(Chaine IN varchar2) RETURN varchar2 IS
position_deb integer;
longueur integer;
valeur_balise varchar2(128);
BEGIN
	 position_deb := INSTR(Chaine,'>',1,1) + 1;
	 longueur := INSTR(Chaine,'<',1,2) - position_deb;
	 valeur_balise := SUBSTR(Chaine,position_deb,longueur);
	RETURN valeur_balise;
END ExtraireBaliseMontant;

/* ***************************************** */
/* --- Extraction Balise de type devise  --- */
/* ***************************************** */
FUNCTION ExtraireBaliseDevise(Balise IN varchar2, Chaine IN varchar2) RETURN varchar2 IS
position_deb integer;
longueur integer;
valeur_balise varchar2(128);
BEGIN
	 position_deb := INSTR(Chaine,Balise) + LENGTH(Balise) + 1;
	 longueur := INSTR(Chaine,'>') - 1 - position_deb;
	 valeur_balise := SUBSTR(Chaine,position_deb,longueur);
	RETURN valeur_balise;
END ExtraireBaliseDevise;

/* **************************** */
/* --- Extraction LibelleMR --- */
/* **************************** */
FUNCTION LibelleMR(CodeMR IN varchar2) RETURN varchar2 IS
libelle varchar2(128);
BEGIN
BEGIN
SELECT   LIBELLE
 INTO   libelle
 FROM    TA_RN_MODE_REGLEMENT
WHERE    CODE_MODE_REGLEMENT=CodeMR;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   libelle := 'Opération sans libellé';
   P_LOG('WARNING', 'Mode de reglement non trouve, valeur par defaut utilisee', 'CODE_MODE_REGLEMENT', CodeMR);
WHEN OTHERS THEN
   P_LOG('EXCEPTION', 'Erreur recherche mode de reglement : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE),
         'CODE_MODE_REGLEMENT', CodeMR, TO_CHAR(SQLCODE), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  RAISE PB_RECHERCHE_LIBELLE;
END;
  RETURN libelle;
END LibelleMR;

/* ********************************* */
/* --- Extraction LibelleSociete --- */
/* ********************************* */
FUNCTION LibelleSociete(CodeSociete IN varchar2) RETURN varchar2 IS
libelle varchar2(128);
BEGIN
BEGIN
SELECT   NOM
 INTO   libelle
 FROM    TA_RN_SOCIETE
WHERE    CODE=CodeSociete;
EXCEPTION
WHEN NO_DATA_FOUND THEN
   libelle := '';
   P_LOG('WARNING', 'Societe non trouvee', 'CODE_SOCIETE', CodeSociete);
WHEN OTHERS THEN
   P_LOG('EXCEPTION', 'Erreur recherche libelle societe : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE),
         'CODE_SOCIETE', CodeSociete, TO_CHAR(SQLCODE), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  RAISE PB_RECHERCHE_LIBELLE;
END;
  RETURN libelle;
END LibelleSociete;

/* *********************** */
/* Début procédure globale */
/* *********************** */
BEGIN
  /* ************************************* */
  /* DEBUT Récupération de l'ID chargement */
  /* ************************************* */
BEGIN
  v_step := 10;
  SELECT SQ_RN_CHRGGEST.nextval INTO Var_ID_CHARGEMENT_GESTION FROM DUAL;
  P_LOG('INFO', '========== DEBUT TRAITEMENT AVEC TRACAGE COMPLET ==========',
        NULL, 'ID_CHARGEMENT: ' || TO_CHAR(Var_ID_CHARGEMENT_GESTION), NULL, NULL, v_step);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     Var_ID_CHARGEMENT_GESTION := 1;
     P_LOG('WARNING', 'Sequence non trouvee, ID_CHARGEMENT initialise a 1', NULL, '1', NULL, NULL, v_step);
  WHEN OTHERS THEN
     P_LOG('EXCEPTION', 'Erreur lors du calcul de l''ID_CHARGEMENT  '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE),
           NULL, NULL, TO_CHAR(SQLCODE), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, v_step);
     RAISE PB_ID_CHARGEMENT;
END;

/* ********************************** */
/* Lecture donnees XML TX_REGLT_GEST  */
/* ********************************** */
BEGIN
v_step := 20;
P_LOG('INFO', 'Debut lecture donnees XML TX_REGLT_GEST', NULL, NULL, NULL, NULL, v_step);

/* initialisation variables d'import */
Var_DATECREATION :='';
Var_FROMDATETIME :='';
Var_TODATETIME :='';
Var_TYPEREGLEMENT :='';
Var_STATUTREGLEMENT :='';
Var_IDENTIFICATION :='';
Var_ISSUER :='';
Var_SCHEME :='';
Var_PAYMENTREFERENCE :='';
Var_POLICYREFERENCE :='';
Var_NUMEROCLIENT :='';
Var_NOMCLIENT :='';
Var_SETTLEMENTMODE :='';
Var_BANKCODE :='';
Var_RIBCOMPLET :='';
Var_BRANCHCODE :='';
Var_IDENTIFICATIONRIB :='';
Var_RIBCHECKDIGIT :='';
Var_VALUEDATE :='';
Var_TRADEDATE :='';
Var_OPERATIONNETAMOUNT :='';
Var_OPERATIONNETAMOUNTCURRENCY :='';
Var_BENEFICIARYNAME :='';
Var_BENEFICIARYFIRST :='';
Var_BENEFICIARYREFERENCE :='';
Var_PRESENTMENTREFERENCE :='';
Var_CHEQUEREFERENCE :='';
Var_DEPOSITSLIPREFERENCE :='';
Var_CREDITSLIPREFERENCE :='';
Var_COMMENTAIRE :='';
Var_CREATIONDATE :='';
Var_DATECOMPTAORIG :='';

tab_REG_XML := T_REG_XML();

OPEN Curseur_Lignes_XML;
FETCH Curseur_Lignes_XML BULK COLLECT INTO tab_REG_XML;
CLOSE Curseur_Lignes_XML;

v_step := 25;
P_LOG('INFO', 'Nombre de lignes XML chargees', 'COUNT', TO_CHAR(tab_REG_XML.COUNT), NULL, NULL, v_step);

-- ============================================================================
-- MODIFICATION 4 : RECHERCHE SPÉCIFIQUE DE 22.36 et 2817 DANS LE XML
-- ============================================================================
IF tab_REG_XML.COUNT > 0 THEN
    P_LOG('INFO', '---------- RECHERCHE TRANSACTIONS CIBLES DANS LE XML ----------', NULL, NULL, NULL, NULL, v_step);

    FOR i IN tab_REG_XML.FIRST .. tab_REG_XML.LAST LOOP
        -- Recherche de 22.36
        IF INSTR(tab_REG_XML(i).xml_line, '22.36') > 0 THEN
            v_found_22_36 := TRUE;
            P_LOG('INFO', '? Transaction 22.36 TROUVEE dans le XML',
                  'LIGNE_XML', TO_CHAR(i) || ' | ' || SUBSTR(tab_REG_XML(i).xml_line, 1, 100),
                  NULL, NULL, v_step);
        END IF;

        -- Recherche de 2817
        IF INSTR(tab_REG_XML(i).xml_line, '2817') > 0 AND INSTR(tab_REG_XML(i).xml_line, 'OperationNetAmount') > 0 THEN
            v_found_2817 := TRUE;
            P_LOG('INFO', '? Transaction 2817 TROUVEE dans le XML',
                  'LIGNE_XML', TO_CHAR(i) || ' | ' || SUBSTR(tab_REG_XML(i).xml_line, 1, 100),
                  NULL, NULL, v_step);
        END IF;
    END LOOP;

    IF NOT v_found_22_36 THEN
        P_LOG('WARNING', '? Transaction 22.36 NON TROUVEE dans le XML - Verification necessaire du fichier source',
              NULL, NULL, NULL, NULL, v_step);
    END IF;

    IF NOT v_found_2817 THEN
        P_LOG('WARNING', '? Transaction 2817 NON TROUVEE dans le XML - Verification necessaire du fichier source',
              NULL, NULL, NULL, NULL, v_step);
    END IF;

    P_LOG('INFO', '---------- FIN RECHERCHE TRANSACTIONS CIBLES ----------', NULL, NULL, NULL, NULL, v_step);
END IF;
-- ============================================================================

IF tab_REG_XML.COUNT > 0 THEN
FOR idx_XML IN tab_REG_XML.FIRST .. tab_REG_XML.LAST
LOOP
	LIGNE_FLUX_GESTION := tab_REG_XML(idx_XML).xml_line;

	IF INSTR(LIGNE_FLUX_GESTION,'</Flux>') <> 0 THEN
	   GOTO end_read_XML;
	END IF;

	IF INSTR(LIGNE_FLUX_GESTION,'<DateCreation>') <> 0 THEN
		Var_DATECREATION := ExtraireBaliseDate('<DateCreation>',TRIM(LIGNE_FLUX_GESTION));
	ELSIF INSTR(LIGNE_FLUX_GESTION,'<FromDateTime>') <> 0 THEN
		Var_FROMDATETIME := ExtraireBaliseDate('<FromDateTime>',TRIM(LIGNE_FLUX_GESTION));
	ELSIF INSTR(LIGNE_FLUX_GESTION,'<ToDateTime>') <> 0 THEN
		Var_TODATETIME := ExtraireBaliseDate('<ToDateTime>',TRIM(LIGNE_FLUX_GESTION));
	ELSIF INSTR(LIGNE_FLUX_GESTION,'<TypeReglement>') <> 0 THEN
		Var_TYPEREGLEMENT := ExtraireBalise('<TypeReglement>',TRIM(LIGNE_FLUX_GESTION));
	ELSIF INSTR(LIGNE_FLUX_GESTION,'<StatutReglement>') <> 0 THEN
		Var_STATUTREGLEMENT := ExtraireBalise('<StatutReglement>',TRIM(LIGNE_FLUX_GESTION));
	END IF;

    IF INSTR(LIGNE_FLUX_GESTION,'<Societe>') <> 0 THEN
		bSociete := 1; CONTINUE;
	END IF;

	IF INSTR(LIGNE_FLUX_GESTION,'</Societe>') <> 0 THEN
		bSociete := 0; CONTINUE;
	END IF;

	IF INSTR(LIGNE_FLUX_GESTION,'<DepositoryAccount>') <> 0 THEN
		bDepAccount := 1; CONTINUE;
	END IF;

	IF INSTR(LIGNE_FLUX_GESTION,'</DepositoryAccount>') <> 0 THEN
		bDepAccount := 0; CONTINUE;
	END IF;

	IF bSociete = 1 THEN
		IF INSTR(LIGNE_FLUX_GESTION,'<Identification>') <> 0 THEN
			Var_IDENTIFICATION := ExtraireBalise('<Identification>',TRIM(LIGNE_FLUX_GESTION));
			Var_NOMSOCIETE := LibelleSociete(Var_IDENTIFICATION);
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<Issuer>') <> 0 THEN
			Var_ISSUER := ExtraireBalise('<Issuer>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<Scheme>') <> 0 THEN
			Var_SCHEME := ExtraireBalise('<Scheme>',TRIM(LIGNE_FLUX_GESTION));
		END IF;
		CONTINUE;
	END IF;

    IF INSTR(LIGNE_FLUX_GESTION,'<Identification>') <> 0
	   AND bSociete = 0 AND bDepAccount = 0 THEN
	    bRegltIdentification := 1; CONTINUE;
	END IF;

	IF INSTR(LIGNE_FLUX_GESTION,'</Identification>') <> 0
	   AND bSociete = 0 AND bDepAccount = 0 THEN
	    bRegltIdentification := 0; CONTINUE;
	END IF;

	IF bRegltIdentification = 1 THEN
		IF INSTR(LIGNE_FLUX_GESTION,'<NumeroClient>') <> 0 THEN
		  	Var_NUMEROCLIENT := ExtraireBalise('<NumeroClient>',TRIM(LIGNE_FLUX_GESTION));
	   	ELSIF INSTR(LIGNE_FLUX_GESTION,'<PolicyReference>') <> 0 THEN
		  	Var_POLICYREFERENCE := ExtraireBalise('<PolicyReference>',TRIM(LIGNE_FLUX_GESTION));
	   	END IF;
		CONTINUE;
	END IF;

	IF bDepAccount = 1 THEN
		IF INSTR(LIGNE_FLUX_GESTION,'<BankCode>') <> 0 THEN
		  	Var_BANKCODE := ExtraireBalise('<BankCode>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<BranchCode>') <> 0 THEN
		  	Var_BRANCHCODE := ExtraireBalise('<BranchCode>',TRIM(LIGNE_FLUX_GESTION));
	   	ELSIF INSTR(LIGNE_FLUX_GESTION,'<Identification>') <> 0 THEN
		  	Var_IDENTIFICATIONRIB := ExtraireBalise('<Identification>',TRIM(LIGNE_FLUX_GESTION));
	   	ELSIF INSTR(LIGNE_FLUX_GESTION,'<RIBCheckDigit>') <> 0 THEN
		  	Var_RIBCHECKDIGIT := ExtraireBalise('<RIBCheckDigit>',TRIM(LIGNE_FLUX_GESTION));
			Var_RIBCOMPLET := Var_BANKCODE||Var_BRANCHCODE||Var_IDENTIFICATIONRIB||Var_RIBCHECKDIGIT;
	   	END IF;
		CONTINUE;
	END IF;

  	IF INSTR(LIGNE_FLUX_GESTION,'<Beneficiary>') <> 0 THEN
	    bBeneficiary := 1; CONTINUE;
	END IF;

	IF INSTR(LIGNE_FLUX_GESTION,'</Beneficiary>') <> 0 THEN
	    bBeneficiary := 0; CONTINUE;
	END IF;

	IF bBeneficiary = 1 THEN
		IF INSTR(LIGNE_FLUX_GESTION,'<BeneficiaryName>') <> 0 THEN
		  	Var_BENEFICIARYNAME := ExtraireBalise('<BeneficiaryName>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<BeneficiaryFirstName>') <> 0 THEN
		  	Var_BENEFICIARYFIRST := ExtraireBalise('<BeneficiaryFirstName>',TRIM(LIGNE_FLUX_GESTION));
	   	ELSIF INSTR(LIGNE_FLUX_GESTION,'<BeneficiaryReference>') <> 0 THEN
		  	Var_BENEFICIARYREFERENCE := ExtraireBalise('<BeneficiaryReference>',TRIM(LIGNE_FLUX_GESTION));
	   	END IF;
		CONTINUE;
	END IF;

	IF INSTR(LIGNE_FLUX_GESTION,'<Context>') <> 0 THEN
	    bContext := 1; CONTINUE;
	END IF;

	IF INSTR(LIGNE_FLUX_GESTION,'</Context>') <> 0 THEN
	    bContext := 0; CONTINUE;
	END IF;

    IF bContext = 1 THEN
		IF INSTR(LIGNE_FLUX_GESTION,'<Comment>') <> 0 THEN
		  	Var_COMMENTAIRE := ExtraireBalise('<Comment>',TRIM(LIGNE_FLUX_GESTION));
	   	ELSIF INSTR(LIGNE_FLUX_GESTION,'<CreationDate>') <> 0 THEN
		  	Var_CREATIONDATE := ExtraireBaliseDate('<CreationDate>',TRIM(LIGNE_FLUX_GESTION));
	   	ELSIF INSTR(LIGNE_FLUX_GESTION,'<NomClient>') <> 0 THEN
		  	Var_NOMCLIENT := ExtraireBalise('<NomClient>',TRIM(LIGNE_FLUX_GESTION));
	   	END IF;
		CONTINUE;
	END IF;

	IF bSociete = 0 AND bDepAccount = 0 AND bBeneficiary = 0
	    AND bRegltIdentification = 0 AND bContext = 0 THEN

		IF INSTR(LIGNE_FLUX_GESTION,'<PaymentReference>') <> 0 THEN
			Var_PAYMENTREFERENCE := ExtraireBalise('<PaymentReference>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<SettlementMode>') <> 0 THEN
			Var_SETTLEMENTMODE := ExtraireBalise('<SettlementMode>',TRIM(LIGNE_FLUX_GESTION));
			Var_LIBELLEMODEREGLEMENT := LibelleMR(Var_SETTLEMENTMODE);
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<ValueDate>') <> 0 THEN
			Var_VALUEDATE := ExtraireBaliseDate('<ValueDate>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<TradeDate>') <> 0 THEN
			Var_TRADEDATE := ExtraireBaliseDate('<TradeDate>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<OperationNetAmount') <> 0 THEN
			Var_OPERATIONNETAMOUNT := ExtraireBaliseMontant(TRIM(LIGNE_FLUX_GESTION));
			Var_OPERATIONNETAMOUNTCURRENCY := ExtraireBaliseDevise('Currency=',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<PresentmentReference>') <> 0 THEN
            Var_PRESENTMENTREFERENCE := ExtraireBalise('<PresentmentReference>',TRIM(LIGNE_FLUX_GESTION));
        ELSIF INSTR(LIGNE_FLUX_GESTION,'<ChequeReference>') <> 0 THEN
			Var_CHEQUEREFERENCE := ExtraireBalise('<ChequeReference>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<DepositSlipReference>') <> 0 THEN
			Var_DEPOSITSLIPREFERENCE := ExtraireBalise('<DepositSlipReference>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<CreditSlipReference>') <> 0 THEN
			Var_CREDITSLIPREFERENCE := ExtraireBalise('<CreditSlipReference>',TRIM(LIGNE_FLUX_GESTION));
		-- FIN de Reglement, time to INSERT
		ELSIF (INSTR(LIGNE_FLUX_GESTION,'</Reglement>')) <> 0 THEN
			IF NVL(TRIM(Var_COMMENTAIRE), 'NULL') = 'NULL' THEN
				Var_COMMENTAIRE := Var_LIBELLEMODEREGLEMENT;
			END IF;

			BEGIN
				SELECT DISTINCT formule INTO Var_FORMULE
				  FROM TA_RN_FORMULES_GESTION
				  WHERE source = Var_SCHEME AND dept = Var_STATUTREGLEMENT;
			EXCEPTION
			WHEN OTHERS THEN
				ROLLBACK;
				P_LOG('EXCEPTION', 'Erreur recherche formule : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE),
				      'SCHEME/STATUT', Var_SCHEME||'/'||Var_STATUTREGLEMENT, TO_CHAR(SQLCODE), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, v_step);
				raise_application_error('-20005', 'Erreur critique en recherche formule');
			END;

			IF Var_FORMULE = 2 THEN
				Var_DATECOMPTAORIG := Var_TRADEDATE;
				Var_TRADEDATE := Var_CREATIONDATE;
			ELSIF Var_FORMULE = 1 THEN
				IF NOT (LENGTH(Var_TRADEDATE) = 0 OR LENGTH(Var_CREATIONDATE) = 0 OR LENGTH(Var_CREATIONDATE) IS NULL OR LENGTH(Var_TRADEDATE) IS NULL) THEN
					  IF LAST_DAY(TO_DATE(Var_CREATIONDATE,'dd/MM/YYYY')) < LAST_DAY(TO_DATE(TO_CHAR(sysdate,'dd/MM/YYYY'),'dd/MM/YYYY')) THEN
						 Var_CREATIONDATE := TO_CHAR(sysdate - 1,'dd/MM/YYYY');
					  END IF;
					  IF LAST_DAY(TO_DATE(Var_TRADEDATE,'dd/MM/YYYY')) < LAST_DAY(TO_DATE(Var_CREATIONDATE,'dd/MM/YYYY')) THEN
						 Var_VALUEDATE := Var_TRADEDATE;
						 Var_TRADEDATE := '01'||SUBSTR(Var_CREATIONDATE,3,8);
					  END IF;
				END IF;
			END IF;

			ListeValeursImport := '('||''''||Var_DATECREATION||''''||','||''''||Var_FROMDATETIME||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_TODATETIME||''''||','||''''||Var_TYPEREGLEMENT||''''||','||''''||Var_STATUTREGLEMENT||''''||','||''''||Var_IDENTIFICATION||''''||','||''''||Var_ISSUER||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_SCHEME||''''||','||''''||Var_PAYMENTREFERENCE||''''||','||''''||Var_POLICYREFERENCE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_NUMEROCLIENT||''''||','||''''||Var_NOMCLIENT||''''||','||''''||Var_SETTLEMENTMODE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_BANKCODE||''''||','||''''||Var_BRANCHCODE||''''||','||''''||Var_IDENTIFICATIONRIB||''''||','||''''||Var_RIBCHECKDIGIT||''''||','||''''||Var_VALUEDATE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_TRADEDATE||''''||','||''''||Var_OPERATIONNETAMOUNT||''''||','||''''||Var_OPERATIONNETAMOUNTCURRENCY||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_BENEFICIARYNAME||''''||','||''''||Var_BENEFICIARYFIRST||''''||','||''''||Var_BENEFICIARYREFERENCE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_PRESENTMENTREFERENCE||''''||','||''''||Var_CHEQUEREFERENCE||''''||','||''''||Var_DEPOSITSLIPREFERENCE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_CREDITSLIPREFERENCE||''''||','||''''||Var_COMMENTAIRE||''''||','||''''||Var_CREATIONDATE||''''||','||''''||Var_RIBCOMPLET||''''||','||Var_ID_CHARGEMENT_GESTION||','||''''||Var_DATECOMPTAORIG||''''||')';

			BEGIN
				EXECUTE IMMEDIATE 'INSERT INTO TA_RN_IMPORT_GESTION_JC '||ListeChampsImport||' '||'VALUES '||ListeValeursImport;

                -- ============================================================================
                -- MODIFICATION 1 : LOG DE CHAQUE TRANSACTION INSÉRÉE
                -- ============================================================================
                v_total_transactions_lues := v_total_transactions_lues + 1;

                P_LOG('INFO', 'Transaction inseree dans TA_RN_IMPORT_GESTION_JC',
                      'PAYMENTREFERENCE',
                      Var_PAYMENTREFERENCE || ' | MONTANT=' || Var_OPERATIONNETAMOUNT || ' | CLIENT=' || Var_NUMEROCLIENT || ' | RIB=' || Var_IDENTIFICATIONRIB,
                      NULL, NULL, v_step);

                -- Log spécifique si c'est une de nos transactions cibles
                IF Var_OPERATIONNETAMOUNT = '22.36' THEN
                    P_LOG('INFO', '?? TRANSACTION CIBLE 22.36 INSEREE',
                          'PAYMENTREF', Var_PAYMENTREFERENCE,
                          NULL, NULL, v_step);
                ELSIF Var_OPERATIONNETAMOUNT = '2817' THEN
                    P_LOG('INFO', '?? TRANSACTION CIBLE 2817 INSEREE',
                          'PAYMENTREF', Var_PAYMENTREFERENCE,
                          NULL, NULL, v_step);
                END IF;
                -- ============================================================================

			    -- Réinitialisation des variables
				Var_TYPEREGLEMENT :='';
				Var_STATUTREGLEMENT :='';
				Var_IDENTIFICATION :='';
				Var_ISSUER :='';
				Var_SCHEME :='';
				Var_PAYMENTREFERENCE :='';
				Var_POLICYREFERENCE :='';
				Var_NUMEROCLIENT :='';
				Var_NOMCLIENT :='';
				Var_SETTLEMENTMODE :='';
				Var_BANKCODE :='';
				Var_RIBCOMPLET :='';
				Var_BRANCHCODE :='';
				Var_IDENTIFICATIONRIB :='';
				Var_RIBCHECKDIGIT :='';
				Var_VALUEDATE :='';
				Var_TRADEDATE :='';
				Var_OPERATIONNETAMOUNT :='';
				Var_OPERATIONNETAMOUNTCURRENCY :='';
				Var_BENEFICIARYNAME :='';
				Var_BENEFICIARYFIRST :='';
				Var_BENEFICIARYREFERENCE :='';
				Var_PRESENTMENTREFERENCE :='';
				Var_CHEQUEREFERENCE :='';
				Var_DEPOSITSLIPREFERENCE :='';
				Var_CREDITSLIPREFERENCE :='';
				Var_COMMENTAIRE :='';
				Var_CREATIONDATE :='';
				Var_DATECOMPTAORIG :='';

				Var_N_Uncommitted := Var_N_Uncommitted + 1;

                -- ============================================================================
                -- MODIFICATION 2 : LOG DES COMMIT AVEC COMPTEUR
                -- ============================================================================
				IF Var_N_Uncommitted = 500 THEN
					P_LOG('INFO', 'COMMIT intermediaire - 500 enregistrements',
					      NULL,
					      'Total transactions traitees: ' || TO_CHAR(v_total_transactions_lues) ||
					      ' | En attente commit: ' || TO_CHAR(Var_N_Uncommitted),
					      NULL, NULL, v_step);
					Var_N_Uncommitted := 0;
					COMMIT;
				END IF;
                -- ============================================================================

			EXCEPTION
			   WHEN OTHERS THEN
					P_LOG('EXCEPTION', 'Erreur lors de l''insertion en TA_RN_IMPORT_GESTION_JC : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE),
					      'PAYMENTREFERENCE', Var_PAYMENTREFERENCE || ' | MONTANT=' || Var_OPERATIONNETAMOUNT,
					      TO_CHAR(SQLCODE), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, v_step);
					RAISE PB_INSERT_TA_RN_IMP_GEST_JC;
			END;
		END IF; -- </Reglement>
		CONTINUE;
	END IF;

END LOOP;
END IF; -- COUNT > 0

<<end_read_XML>>

P_LOG('INFO', 'COMMIT final import - Total transactions: ' || TO_CHAR(v_total_transactions_lues),
      NULL, 'Transactions en attente: ' || TO_CHAR(Var_N_Uncommitted), NULL, NULL, v_step);
COMMIT;

P_LOG('INFO', 'Traitement import dans TA_RN_IMPORT_GESTION_JC termine avec succes',
      NULL, 'Total final: ' || TO_CHAR(v_total_transactions_lues) || ' transactions', NULL, NULL, v_step);

EXCEPTION
WHEN OTHERS THEN
	P_LOG('EXCEPTION', 'Erreur lors de l''import TX_REGLT_GEST --> TA_RN_IMPORT_GESTION_JC '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE),
	      NULL, NULL, TO_CHAR(SQLCODE), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, v_step);
    RAISE PB_LECTURE_TX_REGLT_GEST;
END;

/* ***************************************************** */
/* Fin du traitement importation PR_RN_IMPORT_GESTION_JC */
/* ***************************************************** */

/* ************************************************* */
/* DEBUT Alimentation de la table d'export          */
/* ************************************************* */
BEGIN
v_step := 30;
P_LOG('INFO', 'Debut alimentation table export TA_RN_EXPORT_JC', NULL, NULL, NULL, NULL, v_step);

ListeChampsExport :='ID_CHARGEMENT,';
ListeValeursImport := ''||Var_ID_CHARGEMENT_GESTION||',';

OPEN Curseur_ZonesParCompte;

FETCH Curseur_ZonesParCompte
 INTO
	  VarCurs_ID_COMPTE_ACCURATE,
	  VarCurs_NUM_COMPTE_ACCURATE,
	  VarCurs_NOM_CHAMP,
	  VarCurs_NOM_BALISE;

    Var_Ref_ID_COMPTE_ACCURATE    := VarCurs_ID_COMPTE_ACCURATE;
    Var_Ref_NUM_COMPTE_ACCURATE   := VarCurs_NUM_COMPTE_ACCURATE;
    Var_Ref_NOM_CHAMP             := VarCurs_NOM_CHAMP;
    Var_Ref_NOM_BALISE            := VarCurs_NOM_BALISE;

WHILE (NOT Curseur_ZonesParCompte%NOTFOUND)
LOOP

	WHILE ( Var_Ref_NUM_COMPTE_ACCURATE=VarCurs_NUM_COMPTE_ACCURATE
			AND NOT Curseur_ZonesParCompte%NOTFOUND )
	LOOP
		ListeChampsExport := ListeChampsExport||VarCurs_NOM_CHAMP||',';
		ListeValeursImport := ListeValeursImport||VarCurs_NOM_BALISE||',';

		FETCH Curseur_ZonesParCompte
		  INTO  VarCurs_ID_COMPTE_ACCURATE,
				VarCurs_NUM_COMPTE_ACCURATE,
				VarCurs_NOM_CHAMP,
				VarCurs_NOM_BALISE;
	END LOOP;

	ListeChampsExport  := SUBSTR(ListeChampsExport,1,LENGTH(ListeChampsExport) - 1);
	ListeValeursImport := SUBSTR(ListeValeursImport,1,LENGTH(ListeValeursImport) - 1);

	-- ============================================================================
	-- MODIFICATION 3 : LOG DU TEST EXISTS AVANT INSERT
	-- ============================================================================
	BEGIN
	  v_step := 32;

	  -- Compter combien de lignes vont être insérées
	  DECLARE
	      v_count_to_insert NUMBER := 0;
	  BEGIN
	      EXECUTE IMMEDIATE
	          'SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE '
	          ||' EXISTS (SELECT 1 FROM TA_RN_MODE_REGLEMENT, TA_RN_PRODUIT, TA_RN_GESTION_JC'
	          ||' WHERE  TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT = TA_RN_GESTION_JC.ID_MODE_REGLEMENT'
	          ||' AND TA_RN_PRODUIT.ID_PRODUIT = TA_RN_GESTION_JC.ID_PRODUIT'
	          ||' AND TA_RN_GESTION_JC.ID_COMPTE_ACCURATE = '||Var_Ref_ID_COMPTE_ACCURATE
	          ||' AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=''ALL'' OR TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=SETTLEMENTMODE)'
	          ||' AND (TA_RN_PRODUIT.CODE_PRODUIT=''ALL'' OR TA_RN_PRODUIT.CODE_PRODUIT=NUMEROCLIENT))'
	          ||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
	      INTO v_count_to_insert;

	      P_LOG('INFO', 'Test EXISTS TA_RN_GESTION_JC pour compte accurate',
	            'ID_COMPTE_ACCURATE',
	            TO_CHAR(Var_Ref_ID_COMPTE_ACCURATE) || ' (' || Var_Ref_NUM_COMPTE_ACCURATE || ') - ' ||
	            TO_CHAR(v_count_to_insert) || ' transactions a inserer',
	            NULL, NULL, v_step);

	      IF v_count_to_insert = 0 THEN
	          P_LOG('WARNING', 'Aucune transaction ne passe le filtre TA_RN_GESTION_JC pour ce compte',
	                'ID_COMPTE_ACCURATE', TO_CHAR(Var_Ref_ID_COMPTE_ACCURATE),
	                NULL, NULL, v_step);
	      END IF;
	  END;
	  -- ============================================================================

	  -- INSERT réel dans TA_RN_EXPORT_JC
	  EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT_JC (SOURCE,ACCNUM,'||ListeChampsExport||')'
		||' ('
		||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport
		||' FROM TA_RN_IMPORT_GESTION_JC WHERE '
		||' EXISTS (SELECT 1 FROM TA_RN_MODE_REGLEMENT, TA_RN_PRODUIT, TA_RN_GESTION_JC'
				||' WHERE  TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT = TA_RN_GESTION_JC.ID_MODE_REGLEMENT'
				||' AND TA_RN_PRODUIT.ID_PRODUIT = TA_RN_GESTION_JC.ID_PRODUIT'
				||' AND TA_RN_GESTION_JC.ID_COMPTE_ACCURATE = '||Var_Ref_ID_COMPTE_ACCURATE
				||' AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=''ALL'' OR TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=SETTLEMENTMODE)'
				||' AND (TA_RN_PRODUIT.CODE_PRODUIT=''ALL'' OR TA_RN_PRODUIT.CODE_PRODUIT=NUMEROCLIENT))'
		||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
		||')';

      -- LOG du nombre de lignes effectivement insérées
      P_LOG('INFO', 'INSERT dans TA_RN_EXPORT_JC complete',
            'ID_COMPTE_ACCURATE',
            TO_CHAR(Var_Ref_ID_COMPTE_ACCURATE) || ' (' || Var_Ref_NUM_COMPTE_ACCURATE || ') - ' ||
            TO_CHAR(SQL%ROWCOUNT) || ' lignes effectivement inserees',
            NULL, NULL, v_step);

	EXCEPTION
	  WHEN NO_DATA_FOUND THEN
		P_LOG('WARNING', 'Pas de detail pour le compte', 'NUM_COMPTE_ACCURATE', Var_Ref_NUM_COMPTE_ACCURATE, NULL, NULL, v_step);
	  WHEN OTHERS THEN
		P_LOG('EXCEPTION', 'Erreur insertion dans TA_RN_EXPORT_JC : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE),
		      'NUM_COMPTE_ACCURATE', Var_Ref_NUM_COMPTE_ACCURATE, TO_CHAR(SQLCODE), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, v_step);
		RAISE PB_INSERT_TA_RN_EXPORT_JC;
	END;

	-- Ecriture de contrepartie (identique, juste les logs ajoutés)
	BEGIN
		v_step := 34;
		EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT_JC (SOURCE,ACCNUM,'||ListeChampsExport||')'
			||' ('
			||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport
			||' FROM '
			||' (SELECT DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,'
			||''''||''''||' AS PAYMENTREFERENCE,'||''''||''''||' AS POLICYREFERENCE,NUMEROCLIENT,'||''''||''''||' AS NOMCLIENT,'
			||'SETTLEMENTMODE,BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,'||''''||''''||' AS VALUEDATE,TRADEDATE,'
			||' DECODE(SCHEME,'||''''||'ELOG'||''''||',SUM(ABS(TO_NUMBER(OPERATIONNETAMOUNT))), SUM(TO_NUMBER(OPERATIONNETAMOUNT))) AS OPERATIONNETAMOUNT,OPERATIONNETAMOUNTCURRENCY,'||''''||''''||' AS BENEFICIARYNAME,'
			||''''||''''||' AS BENEFICIARYFIRST,'||''''||''''||' AS BENEFICIARYREFERENCE,'||''''||''''||' AS PRESENTMENTREFERENCE,'||''''||''''||' AS CHEQUEREFERENCE,'
			||''''||''''||' AS DEPOSITSLIPREFERENCE,'||''''||''''||' AS CREDITSLIPREFERENCE,'||''''||'Ecriture extourne'||''''||' AS COMMENTAIRE,'
			||''''||''''||' AS CREATIONDATE,'||''''||''''||' AS RIBCOMPLET,'||'ID_CHARGEMENT_GESTION, DATECOMPTAORIG FROM TA_RN_IMPORT_GESTION_JC '
			||'WHERE'
			||' EXISTS (SELECT 1 FROM TA_RN_MODE_REGLEMENT, TA_RN_PRODUIT, TA_RN_GESTION_JC'
			||' WHERE  TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT = TA_RN_GESTION_JC.ID_MODE_REGLEMENT'
			||' AND TA_RN_PRODUIT.ID_PRODUIT = TA_RN_GESTION_JC.ID_PRODUIT'
			||' AND TA_RN_GESTION_JC.ID_COMPTE_ACCURATE = '||Var_Ref_ID_COMPTE_ACCURATE
			||' AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=''ALL'' OR TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=SETTLEMENTMODE)'
			||' AND (TA_RN_PRODUIT.CODE_PRODUIT=''ALL'' OR TA_RN_PRODUIT.CODE_PRODUIT=NUMEROCLIENT))'
			||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
			||' GROUP BY DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,SETTLEMENTMODE,NUMEROCLIENT,'
			||'BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,TRADEDATE,OPERATIONNETAMOUNTCURRENCY,ID_CHARGEMENT_GESTION, DATECOMPTAORIG)'
			||')';

      P_LOG('INFO', 'INSERT ecriture contrepartie complete',
            'ID_COMPTE_ACCURATE',
            TO_CHAR(Var_Ref_ID_COMPTE_ACCURATE) || ' - ' || TO_CHAR(SQL%ROWCOUNT) || ' lignes inserees',
            NULL, NULL, v_step);

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			P_LOG('WARNING', 'Pas de contrepartie pour le compte', 'NUM_COMPTE_ACCURATE', Var_Ref_NUM_COMPTE_ACCURATE, NULL, NULL, v_step);
		WHEN OTHERS THEN
			P_LOG('EXCEPTION', 'Erreur insertion TA_RN_EXPORT_JC : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE),
			      'NUM_COMPTE_ACCURATE', Var_Ref_NUM_COMPTE_ACCURATE, TO_CHAR(SQLCODE), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, v_step);
			RAISE PB_INSERT_TA_RN_EXPORT_JC;
	END;

	ListeChampsExport :='ID_CHARGEMENT,';
	ListeValeursImport := ''||Var_ID_CHARGEMENT_GESTION||',';

	Var_Ref_NUM_COMPTE_ACCURATE   := VarCurs_NUM_COMPTE_ACCURATE;
	Var_Ref_ID_COMPTE_ACCURATE    := VarCurs_ID_COMPTE_ACCURATE;

END LOOP;

CLOSE Curseur_ZonesParCompte;

P_LOG('INFO', 'Traitement alimentation table export termine avec succes', NULL, NULL, NULL, NULL, v_step);
COMMIT;

P_LOG('INFO', '========== FIN TRAITEMENT AVEC TRACAGE COMPLET ==========',
      NULL, 'ID_CHARGEMENT: ' || TO_CHAR(Var_ID_CHARGEMENT_GESTION), NULL, NULL, v_step);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
      P_LOG('WARNING', 'Curseur_ZonesParCompte vide : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE), NULL, NULL, TO_CHAR(SQLCODE), NULL, v_step);
    WHEN OTHERS THEN
      P_LOG('EXCEPTION', 'Erreur alimentation table TA_RN_EXPORT_JC: '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE),
            NULL, NULL, TO_CHAR(SQLCODE), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE, v_step);
      RAISE PARAM_GESTION_IMPOSSIBLE;
END;

END;
/

PROMPT ============================================================================
PROMPT Script RNADGENJUCGES01_TRACE_COMPLETE termine
PROMPT Consultez TA_RN_LOG_EXECUTION pour voir les logs detailles
PROMPT ============================================================================
