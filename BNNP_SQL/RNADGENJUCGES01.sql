-- ------------------------
-- PR_RN_IMPORT_GESTION.SQL : création du fichier à intégrer dans accurate pour la justification de compte
-- -----------------------
WHENEVER SQLERROR EXIT 202;
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
SET SERVEROUTPUT ON
SET VERIFY OFF
SET LINESIZE 2000

DECLARE

--***********************************************************************
-- Fevrier 2009 - POPS - NVE
--***********************************************************************
-- Justification de comptes :
-- Procedure d'import du flux ExtraitReglement dans la table temporaire TA_RN_IMPORT_GESTION_JC
-- export de la table TA_RN_EXPORT_JC_GESTION sous forme de fichier plat pour intégration dans Accurate (pas de cumul quotidien)
-- Selection des mouvements issus des flux de gestion d'après des couples Produit/Mode de reglement

-- --------------------------------------------------------------------------------------------------
-- -------------
-- Algorithme --
-- -------------
-- * Récupération des balises à alimenter pour la gestion : liste des balises en dur (performance)
-- * Ouverture du fichier FICHIER_GESTION en provenance du Bus
-- * Tant que le fichier n'est pas vide
-- *     Lecture du fichier ligne à ligne avec insertion dans la table TA_RN_IMPORT_GESTION_JC
-- * Fermeture du fichier
-- * Archivage du fichier
-- * chargement des données dans TA_RN_EXPORT_JC
-- * génération du fichier plat pour intégration dans Accurate
/* ********************************************************************************** */
/* ********************************************************************************** */
/* ********************************************************************************** */

/* ******************************************************/
/* Variable d'import dans la table TA_RN_IMPORT_GESTION_JC */
/* ******************************************************/
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
Var_DATECOMPTAORIG TA_RN_IMPORT_GESTION_JC.DATECOMPTAORIG%TYPE :='';  -- V1.2
Var_NOMSOCIETE TA_RN_IMPORT_GESTION_JC.NOMSOCIETE%TYPE :='';
Var_LIBELLEMODEREGLEMENT TA_RN_IMPORT_GESTION_JC.LIBELLEMODEREGLEMENT%TYPE :='';

/* ***********************************************/
/* Variables pour curseur Curseur_ZonesParCompte */
/* ***********************************************/
VarCurs_ID_COMPTE_ACCURATE      TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE%TYPE;
VarCurs_NUM_COMPTE_ACCURATE     TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE%TYPE;
VarCurs_NOM_CHAMP               TA_RN_FEEDER_STD.NOM_CHAMP%TYPE;
VarCurs_NOM_BALISE              TA_RN_BALISE.NOM_BALISE%TYPE;

/* ************************************************************/
/* Variables de référence pour curseur Curseur_ZonesParCompte */
/* ************************************************************/
Var_Ref_ID_COMPTE_ACCURATE      TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE%TYPE;
Var_Ref_NUM_COMPTE_ACCURATE     TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE%TYPE;
Var_Ref_NOM_CHAMP               TA_RN_FEEDER_STD.NOM_CHAMP%TYPE;
Var_Ref_NOM_BALISE              TA_RN_BALISE.NOM_BALISE%TYPE;

-- Variables pour Insert TA_RN_IMPORT_GESTION_JC --
ListeChampsImport VARCHAR2(2048) :='(DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,
SCHEME,PAYMENTREFERENCE,POLICYREFERENCE,NUMEROCLIENT,NOMCLIENT,SETTLEMENTMODE,BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,
VALUEDATE,TRADEDATE,OPERATIONNETAMOUNT,OPERATIONNETAMOUNTCURRENCY,BENEFICIARYNAME,BENEFICIARYFIRST,BENEFICIARYREFERENCE,
PRESENTMENTREFERENCE,CHEQUEREFERENCE,DEPOSITSLIPREFERENCE,CREDITSLIPREFERENCE,COMMENTAIRE,CREATIONDATE,RIBCOMPLET,ID_CHARGEMENT_GESTION, DATECOMPTAORIG)';  -- V1.2

ListeChampsExport VARCHAR2(1024);
ListeValeursImport VARCHAR2(2048);

-- Variables de chargement
Var_ID_CHARGEMENT_GESTION INTEGER :=0;

-- V1.2 Variable ramenant la formule associée à la chaine et au statut reglement (EMIS ou ANNULE)
Var_FORMULE   TA_RN_FORMULES_GESTION.FORMULE%TYPE;

/* **********************************************/
/* Variable d'export dans la table TA_RN_EXPORT_JC */
/* ******************************************** */
Var_ACCNUM          TA_RN_EXPORT_JC.ACCNUM%TYPE;
Var_TRANSDATE       TA_RN_EXPORT_JC.TRANSDATE%TYPE;
Var_VALUEDATE_EXP   TA_RN_EXPORT_JC.VALUEDATE%TYPE;
Var_NARR            TA_RN_EXPORT_JC.NARR%TYPE;
Var_INTREF          TA_RN_EXPORT_JC.INTREF%TYPE;
Var_EXTREF          TA_RN_EXPORT_JC.EXTREF%TYPE;
Var_TYPEMVT         TA_RN_EXPORT_JC.TYPEMVT%TYPE;
Var_DEPT            TA_RN_EXPORT_JC.DEPT%TYPE;
Var_USER1           TA_RN_EXPORT_JC.USER1%TYPE;
Var_USER2           TA_RN_EXPORT_JC.USER2%TYPE;
Var_USER3           TA_RN_EXPORT_JC.USER3%TYPE;
Var_USER4           TA_RN_EXPORT_JC.USER4%TYPE;
Var_USER5           TA_RN_EXPORT_JC.USER5%TYPE;
Var_USER6           TA_RN_EXPORT_JC.USER6%TYPE;
Var_USER7           TA_RN_EXPORT_JC.USER7%TYPE;
Var_USER8           TA_RN_EXPORT_JC.USER8%TYPE;
Var_USER9           TA_RN_EXPORT_JC.USER9%TYPE;
Var_USER10          TA_RN_EXPORT_JC.USER10%TYPE;
Var_USER11          TA_RN_EXPORT_JC.USER11%TYPE;
Var_USER12          TA_RN_EXPORT_JC.USER12%TYPE;
Var_USER13          TA_RN_EXPORT_JC.USER13%TYPE;
Var_USER14          TA_RN_EXPORT_JC.USER14%TYPE;
Var_USER15          TA_RN_EXPORT_JC.USER15%TYPE;
Var_USER16          TA_RN_EXPORT_JC.USER16%TYPE;
Var_CURR            TA_RN_EXPORT_JC.CURR%TYPE;
Var_ORAMT           TA_RN_EXPORT_JC.ACCNUM%TYPE;
Var_RECPT           TA_RN_EXPORT_JC.RECPT%TYPE;
Var_PAYMT           TA_RN_EXPORT_JC.PAYMT%TYPE;
Var_QUANT           TA_RN_EXPORT_JC.QUANT%TYPE;
Var_PERC            TA_RN_EXPORT_JC.PERC%TYPE;
Var_UNITPRICE       TA_RN_EXPORT_JC.UNITPRICE%TYPE;
Var_USERDECB        TA_RN_EXPORT_JC.USERDECB%TYPE;
Var_USERDECC        TA_RN_EXPORT_JC.USERDECC%TYPE;
Var_USERDECD        TA_RN_EXPORT_JC.USERDECD%TYPE;
Var_USERDATEA       TA_RN_EXPORT_JC.USERDATEA%TYPE;
Var_USERDATEB       TA_RN_EXPORT_JC.USERDATEB%TYPE;
Var_USERDATEC       TA_RN_EXPORT_JC.USERDATEC%TYPE;
Var_USERDATED       TA_RN_EXPORT_JC.USERDATED%TYPE;
Var_FLAGA           TA_RN_EXPORT_JC.FLAGA%TYPE;
Var_FLAGB           TA_RN_EXPORT_JC.FLAGB%TYPE;
Var_FLAGC           TA_RN_EXPORT_JC.FLAGC%TYPE;
Var_FLAGD           TA_RN_EXPORT_JC.FLAGD%TYPE;
Var_FLAGE           TA_RN_EXPORT_JC.FLAGE%TYPE;
Var_FLAGF           TA_RN_EXPORT_JC.FLAGF%TYPE;
Var_FLAGG           TA_RN_EXPORT_JC.FLAGG%TYPE;
Var_FLAGH           TA_RN_EXPORT_JC.FLAGH%TYPE;
Var_ISSTATEMENT     TA_RN_EXPORT_JC.ISSTATEMENT%TYPE;
Var_ISHOLDING       TA_RN_EXPORT_JC.ISHOLDING%TYPE;
Var_WF_STR          TA_RN_EXPORT_JC.WF_STR%TYPE;
Var_PERIOD          TA_RN_EXPORT_JC.PERIOD%TYPE;

/* *************************************************************** */
/* Extraction des balises et zones du Feeder à alimenter dans     */
/* Accurate pour la gestion                                  */
/* (Alimentation du fichier d'export pour Accurate)                 */
/*                                        */
/* Récupération des zones correspondantes du Feeder standard     */
/* Pour chaque compte du périmètre, zones du fichier à alimenter   */
/*                                        */
/* Le curseur ne s'appuie plus désormais que sur le RIB          */
/* *************************************************************** */

/* *************************************************************** */
/*   Justification de compte                                       */
/*******************************************************************/
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

/* ******************************************** */
/* Curseur sur la table d'EXPORT                */
/* ******************************************** */
CURSOR Curseur_EXPORT_GESTION IS
SELECT ACCNUM,
     TRANSDATE,
     VALUEDATE,
     NARR,
     INTREF,
     EXTREF,
     TYPEMVT,
     DEPT,
     USER1,
     USER2,
     USER3,
     USER4,
     USER5,
     USER6,
     USER7,
     USER8,
     USER9,
     USER10,
     USER11,
     USER12,
     USER13,
     USER14,
     USER15,
     USER16,
     CURR,
     ORAMT,
     RECPT,
     PAYMT,
     QUANT,
     PERC,
     UNITPRICE,
     USERDECB,
     USERDECC,
     USERDECD,
     USERDATEA,
     USERDATEB,
     USERDATEC,
     USERDATED,
     FLAGA,
     FLAGB,
     FLAGC,
     FLAGD,
     FLAGE,
     FLAGF,
     FLAGG,
     FLAGH,
     ISSTATEMENT,
     ISHOLDING,
     WF_STR,
     PERIOD
FROM TA_RN_EXPORT_JC
WHERE TA_RN_EXPORT_JC.SOURCE = 'GEST'
  AND ID_CHARGEMENT=Var_ID_CHARGEMENT_GESTION
ORDER BY ACCNUM;

-- Variables réceptrices du curseur --
Enreg_EXPORT_GESTION Curseur_EXPORT_GESTION%ROWTYPE;

-- Définition des erreurs applicatives --
PB_LECTURE_TX_REGLT_GEST EXCEPTION;
SUPPRESSION_IMPOSSIBLE EXCEPTION;
PARAM_GESTION_IMPOSSIBLE EXCEPTION;
PB_INSERT_TA_RN_IMP_GEST_JC EXCEPTION;
PB_INSERT_TA_RN_EXPORT_JC EXCEPTION;
PB_TW_EXPORT_GEST_JC EXCEPTION;
PB_GENERATION_CLOB_GEST_JC EXCEPTION;
PB_ID_CHARGEMENT EXCEPTION;
PB_RECHERCHE_LIBELLE EXCEPTION;

LIGNE_FLUX_GESTION VARCHAR2(512);

s_Ligne VARCHAR2(1000);
SEPARATEUR_FLUX_SORTIE CHAR(1):=',';

Var_Source CONSTANT CHAR(4) :='GEST';

s_ID_FIC CONSTANT VARCHAR2(64) := 'FIC_GEST_JC';
t_InfoTrait PKG_GLOBAL.T_INFO_TRAITEMENT := '<IdExec>433-GEST-JC</IdExec>';
s_NomFic   CONSTANT VARCHAR2(50) := 'ExtraitReglement_JC.txt.';

s_ReqPurgeClob VARCHAR2(255);

CURSOR Curseur_Lignes_XML IS
SELECT  TT2.column_value AS xml_line
FROM
	TX_REGLT_GEST SS,
	TABLE(PIPE_CLOB(SS.bb,4000, CHR(10))) TT,
	TABLE(STRING_TOKENIZE(TT.column_value, CHR(10))) TT2;

TYPE T_REG_XML IS TABLE OF Curseur_Lignes_XML%ROWTYPE;
tab_REG_XML T_REG_XML;
idx_XML NUMBER;

v_step  NUMBER(4) := 0;
Var_N_Uncommitted NUMBER := 0;
bSociete NUMBER(2) := 0;
bDepAccount NUMBER(2) := 0;
bBeneficiary NUMBER(2) := 0;
bRegltIdentification NUMBER(2) := 0;
bContext NUMBER(2) := 0;

/* ************************* */
/* Déclaration des fonctions */
/* ************************* */

/* ************************* */
/* --- Extraction Balise --- */
/* ************************* */
FUNCTION ExtraireBalise(Balise IN varchar2, Chaine IN varchar2) RETURN varchar2 IS

position_deb integer;
longueur integer;

valeur_balise varchar2(250);

 BEGIN

	 -- Début de la valeur de balise (position de la balise + longueur balise) --
	 position_deb := INSTR(Chaine,Balise) + LENGTH(Balise);

	 -- Fin de la valeur de balise (position de la balise de fin - 1 --
	 longueur := INSTR(Chaine,SUBSTR(Balise,1,1)||'/'||SUBSTR(Balise,2)) - position_deb;

	 valeur_balise := SUBSTR(Chaine,position_deb,longueur);
	 valeur_balise := TRIM(SUBSTR(valeur_balise,1,250));
	 valeur_balise := REPLACE(valeur_balise,'''',' ');

	IF Balise = '<RIBCheckDigit>' THEN
		--DBMS_OUTPUT.PUT_LINE('RIBCheckDigit : >'||valeur_balise||'<');
	  IF LENGTH(valeur_balise) = 1 THEN
		  valeur_balise := '0'||valeur_balise;
		   --DBMS_OUTPUT.PUT_LINE('RIBCheckDigit : >'||valeur_balise||'<');
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

	 -- Début de la valeur de balise (position de la balise + longueur balise) --
	 position_deb := INSTR(Chaine,Balise) + LENGTH(Balise);

	 -- Fin de la valeur de balise (position de la balise de fin - 1 --
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

	 -- Début de la valeur de balise
	 position_deb := INSTR(Chaine,'>',1,1) + 1;

	 -- Fin de la valeur de balise --
	 longueur := INSTR(Chaine,'<',1,2) - position_deb;

	 valeur_balise := SUBSTR(Chaine,position_deb,longueur);
	 --valeur_balise := REPLACE(valeur_balise,'.',',');

	  --DBMS_OUTPUT.PUT_LINE('Fonction ExtraireBaliseMontant : >'||valeur_balise||'<');

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

	 -- Début de la valeur de balise (position de la balise + longueur balise) --
	 position_deb := INSTR(Chaine,Balise) + LENGTH(Balise) + 1;

	 -- Fin de la valeur de balise (position de la balise de fin - 1 --
	 longueur := INSTR(Chaine,'>') - 1 - position_deb;

	 valeur_balise := SUBSTR(Chaine,position_deb,longueur);

	  --DBMS_OUTPUT.PUT_LINE('Fonction ExtraireBaliseDevise Balise : '||Balise||' Valeur : >'||valeur_balise||'<');

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

WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE('Erreur recherche mode de règlement : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
  RAISE PB_RECHERCHE_LIBELLE;

END;

 -- DBMS_OUTPUT.PUT_LINE('Fonction LibelleMR : >'||libelle||'<');

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

WHEN OTHERS THEN
   DBMS_OUTPUT.PUT_LINE('Erreur recherche libellé société : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
  RAISE PB_RECHERCHE_LIBELLE;

END;

 -- DBMS_OUTPUT.PUT_LINE('Fonction Libelle société : >'||libelle||'<');

  RETURN libelle;

END LibelleSociete;

/* ******************************** */
/* Fin de déclaration des fonctions */
/* ******************************** */

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

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     Var_ID_CHARGEMENT_GESTION := 1;
  WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('Etape ' || v_step || ': erreur lors du calcul de l''ID_CHARGEMENT  '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
     RAISE PB_ID_CHARGEMENT;

END;

/* ********************************** */
/* Lecture donnees XML TX_REGLT_GEST  */
/* ********************************** */

BEGIN
v_step := 20;

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
			-- Si le libellé n'est pas renseigné, on le renseigne par le mode de règlement
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
				DBMS_OUTPUT.PUT_LINE('Erreur recherche formule : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
				raise_application_error('-20005', 'Erreur critique en recherche formule');
			END;

			IF Var_FORMULE = 2 THEN
			-- Formule 2
			-- La date de saisie et la date valeur restent inchangées
			-- Date d'opération prend la valeur de la date de saisie
			-- La balise USERDATEB contiendra la date comptable d'origine

				Var_DATECOMPTAORIG := Var_TRADEDATE;
				Var_TRADEDATE := Var_CREATIONDATE;

			ELSIF Var_FORMULE = 1 THEN

			-- Formule 1
			-- Mise à jour de la date comptable si elle est antérieure au mois/année de la date de saisie --
				IF NOT (LENGTH(Var_TRADEDATE) = 0 OR LENGTH(Var_CREATIONDATE) = 0 OR LENGTH(Var_CREATIONDATE) IS NULL OR LENGTH(Var_TRADEDATE) IS NULL) THEN
					  -- Si la date de saisie < date intégration alors date de saisie = date intégration - 1 jour
					  --DBMS_OUTPUT.PUT_LINE('Var_CREATIONDATE : '||Var_CREATIONDATE);
					  IF LAST_DAY(TO_DATE(Var_CREATIONDATE,'dd/MM/YYYY')) < LAST_DAY(TO_DATE(TO_CHAR(sysdate,'dd/MM/YYYY'),'dd/MM/YYYY')) THEN
						 Var_CREATIONDATE := TO_CHAR(sysdate - 1,'dd/MM/YYYY');
						 --DBMS_OUTPUT.PUT_LINE('sysdate : '||TO_CHAR(sysdate,'dd/MM/YYYY'));
						 --DBMS_OUTPUT.PUT_LINE('Var_CREATIONDATE MAJ : '||Var_CREATIONDATE);
					  END IF;

					  -- Si la date comptable < mois de la date de saisie alors date comptable = 1er du mois date saisie
					  -- 	   				  		 	   		   		  		date valeur = date comptable origine
					  IF LAST_DAY(TO_DATE(Var_TRADEDATE,'dd/MM/YYYY')) < LAST_DAY(TO_DATE(Var_CREATIONDATE,'dd/MM/YYYY')) THEN
						 Var_VALUEDATE := Var_TRADEDATE;
						 Var_TRADEDATE := '01'||SUBSTR(Var_CREATIONDATE,3,8);
						 -- DBMS_OUTPUT.PUT_LINE('Var_TRADEDATE MAJ : '||Var_TRADEDATE);
					  END IF;

				END IF;

			END IF;     -- V1.2

			ListeValeursImport := '('||''''||Var_DATECREATION||''''||','||''''||Var_FROMDATETIME||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_TODATETIME||''''||','||''''||Var_TYPEREGLEMENT||''''||','||''''||Var_STATUTREGLEMENT||''''||','||''''||Var_IDENTIFICATION||''''||','||''''||Var_ISSUER||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_SCHEME||''''||','||''''||Var_PAYMENTREFERENCE||''''||','||''''||Var_POLICYREFERENCE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_NUMEROCLIENT||''''||','||''''||Var_NOMCLIENT||''''||','||''''||Var_SETTLEMENTMODE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_BANKCODE||''''||','||''''||Var_BRANCHCODE||''''||','||''''||Var_IDENTIFICATIONRIB||''''||','||''''||Var_RIBCHECKDIGIT||''''||','||''''||Var_VALUEDATE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_TRADEDATE||''''||','||''''||Var_OPERATIONNETAMOUNT||''''||','||''''||Var_OPERATIONNETAMOUNTCURRENCY||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_BENEFICIARYNAME||''''||','||''''||Var_BENEFICIARYFIRST||''''||','||''''||Var_BENEFICIARYREFERENCE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_PRESENTMENTREFERENCE||''''||','||''''||Var_CHEQUEREFERENCE||''''||','||''''||Var_DEPOSITSLIPREFERENCE||''''||',';
			ListeValeursImport := ListeValeursImport||''''||Var_CREDITSLIPREFERENCE||''''||','||''''||Var_COMMENTAIRE||''''||','||''''||Var_CREATIONDATE||''''||','||''''||Var_RIBCOMPLET||''''||','||Var_ID_CHARGEMENT_GESTION||','||''''||Var_DATECOMPTAORIG||''''||')';  -- V1.2

			BEGIN
				EXECUTE IMMEDIATE 'INSERT INTO TA_RN_IMPORT_GESTION_JC '||ListeChampsImport||' '||'VALUES '||ListeValeursImport;

			    --ADI
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
				--ADI

				Var_N_Uncommitted := Var_N_Uncommitted + 1;
				IF Var_N_Uncommitted = 500 THEN
					DBMS_OUTPUT.PUT_LINE('COMMIT!');
					Var_N_Uncommitted := 0;
					COMMIT;
				END IF;
			EXCEPTION
			   WHEN OTHERS THEN
					DBMS_OUTPUT.PUT_LINE('Erreur inconnue lors de l''insertion en TA_RN_IMPORT_GESTION_JC : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
					RAISE PB_INSERT_TA_RN_IMP_GEST_JC;
			END;
		END IF; -- </Reglement>
		CONTINUE;
	END IF;  -- bSociete = 0 ETC.

-- Fin boucle principale
END LOOP;

END IF; -- COUNT > 0

<<end_read_XML>>

DBMS_OUTPUT.PUT_LINE('COMMIT!');
COMMIT;
DBMS_OUTPUT.PUT_LINE('Etape '|| v_step || ': Traitement import dans TA_RN_IMPORT_GESTION_JC terminé avec succès.');

EXCEPTION
WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('Procédure PR_RN_IMPORT_GESTION_JC etape '|| v_step || ': erreur lors de l''import TX_REGLT_GEST --> TA_RN_IMPORT_GESTION_JC '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
    RAISE PB_LECTURE_TX_REGLT_GEST;
END;

/* ***************************************************** */
/* Fin du traitement importation PR_RN_IMPORT_GESTION_JC */
/* ***************************************************** */

/* ************************************************* */
/* DEBUT Alimentation de la table d'export       */
/*                                    */
/* Pour chaque Société,devise,type de règlement,   */
/*            Mode de règlement,compte accurate   */
/*         - liste des champs pour insert       */
/*         - liste des valeurs pour insert       */
/* ************************************************* */
BEGIN
v_step := 30;

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

-- Tant que pas fin fichier --
WHILE (NOT Curseur_ZonesParCompte%NOTFOUND)
LOOP

	-- Tant qu'on est sur le même compte accurate, on concatène les noms de balise à récupérer
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

    --Il n'y a plus de balise à concaténer, on supprime la ',' de la fin de chaîne
	ListeChampsExport  := SUBSTR(ListeChampsExport,1,LENGTH(ListeChampsExport) - 1);
	ListeValeursImport := SUBSTR(ListeValeursImport,1,LENGTH(ListeValeursImport) - 1);

	-- *********************************************************************************************
	-- Génération du détail des écritures
	-- Toutes les lignes dont le produit et le mode de règlement sont présents dans TA_RN_GESTION_JC
	-- doivent être intégrées dans le compte accurate correspondant
	-- *********************************************************************************************
	BEGIN
	  v_step := 32;
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

	EXCEPTION
	  WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE('Pas de détail');
	  WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('Etape ' || v_step || ': erreur insertion dans TA_RN_EXPORT_JC : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
		RAISE PB_INSERT_TA_RN_EXPORT_JC;
	END;

	-- **************************************
	-- Fin génération du détail des écritures
	-- **************************************

	-- *********************************************************************************************
    -- Génération d'une écriture de contrepartie qui se rapprochera avec le cumul saisi en compta
    -- *********************************************************************************************

	BEGIN
		-- **************************************************** --
		-- écriture de contrepartie = cumul par date comptable  --
		-- **************************************************** --
		v_step := 34;
		EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT_JC (SOURCE,ACCNUM,'||ListeChampsExport||')'
			||' ('
			||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport
			||' FROM '
			||' (SELECT DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,'
			||''''||''''||' AS PAYMENTREFERENCE,'||''''||''''||' AS POLICYREFERENCE,NUMEROCLIENT,'||''''||''''||' AS NOMCLIENT,'
			||'SETTLEMENTMODE,BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,'||''''||''''||' AS VALUEDATE,TRADEDATE,'
			||' DECODE(SCHEME,'||''''||'ELOG'||''''||',SUM(ABS(TO_NUMBER(OPERATIONNETAMOUNT))), SUM(TO_NUMBER(OPERATIONNETAMOUNT))) AS OPERATIONNETAMOUNT,OPERATIONNETAMOUNTCURRENCY,'||''''||''''||' AS BENEFICIARYNAME,'  -- V1.1
			||''''||''''||' AS BENEFICIARYFIRST,'||''''||''''||' AS BENEFICIARYREFERENCE,'||''''||''''||' AS PRESENTMENTREFERENCE,'||''''||''''||' AS CHEQUEREFERENCE,'
			||''''||''''||' AS DEPOSITSLIPREFERENCE,'||''''||''''||' AS CREDITSLIPREFERENCE,'||''''||'Ecriture extourne'||''''||' AS COMMENTAIRE,'
			||''''||''''||' AS CREATIONDATE,'||''''||''''||' AS RIBCOMPLET,'||'ID_CHARGEMENT_GESTION, DATECOMPTAORIG FROM TA_RN_IMPORT_GESTION_JC '   -- V1.2
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

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('Pas de contrepartie');
		WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('Etape '|| v_step || ': erreur insertion TA_RN_EXPORT_JC : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
			RAISE PB_INSERT_TA_RN_EXPORT_JC;
	END;

	ListeChampsExport :='ID_CHARGEMENT,';
	ListeValeursImport := ''||Var_ID_CHARGEMENT_GESTION||',';

	Var_Ref_NUM_COMPTE_ACCURATE   := VarCurs_NUM_COMPTE_ACCURATE;
	Var_Ref_ID_COMPTE_ACCURATE    := VarCurs_ID_COMPTE_ACCURATE;

END LOOP;

CLOSE Curseur_ZonesParCompte;

DBMS_OUTPUT.PUT_LINE('Traitement alimentation table export terminé avec succès');

-- Si le traitement se déroule normalement, On effectue la validation des modifications
-- Les tables temporaires et d'export resteront chargées uniquement si le traitement plante en génération du fichier plat
COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Curseur_ZonesParCompte vide : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));

    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Etape '|| v_step || ': erreur alimentation table TA_RN_EXPORT_JC: '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
      RAISE PARAM_GESTION_IMPOSSIBLE;
END;

/* *******************************************/
/* FIN Alimentation de la table d'export     */
/* *******************************************/

/* ******************************** */
/* DEBUT Ecriture fichier de sortie */
/* ******************************** */
BEGIN
v_step := 40;

FOR Enreg_EXPORT_GESTION IN Curseur_EXPORT_GESTION
LOOP
  -- Prise en compte des montants dans Accurate :
  --      ENC --> Réception --> Débit
  --      DEC --> Paiement  --> Crédit
  -- Inversion en cas d'annulation ou de génération des écritures d'extourne

	Var_RECPT:='0';
	Var_PAYMT:='0';

	IF (Enreg_EXPORT_GESTION.NARR = 'Ecriture extourne') THEN
		IF (Enreg_EXPORT_GESTION.TYPEMVT = 'DEC') THEN
			IF (Enreg_EXPORT_GESTION.DEPT = 'EMIS') THEN
				Var_RECPT:=ABS(TO_NUMBER(Enreg_EXPORT_GESTION.ORAMT));
			ELSIF (Enreg_EXPORT_GESTION.DEPT = 'ANNULE') THEN
				Var_PAYMT:=ABS(TO_NUMBER(Enreg_EXPORT_GESTION.ORAMT));
			END IF;
		ELSIF (Enreg_EXPORT_GESTION.TYPEMVT = 'ENC') THEN
			IF (Enreg_EXPORT_GESTION.DEPT = 'EMIS') THEN
				Var_PAYMT:=ABS(TO_NUMBER(Enreg_EXPORT_GESTION.ORAMT));
			ELSIF (Enreg_EXPORT_GESTION.DEPT = 'ANNULE') THEN
   	  			Var_RECPT:=ABS(TO_NUMBER(Enreg_EXPORT_GESTION.ORAMT));
   	      	END IF;
		END IF;
	ELSE
		IF (Enreg_EXPORT_GESTION.TYPEMVT = 'ENC') THEN
			IF (Enreg_EXPORT_GESTION.DEPT = 'EMIS') THEN
				Var_RECPT:=ABS(TO_NUMBER(Enreg_EXPORT_GESTION.ORAMT));
			ELSIF (Enreg_EXPORT_GESTION.DEPT = 'ANNULE') THEN
				Var_PAYMT:=ABS(TO_NUMBER(Enreg_EXPORT_GESTION.ORAMT));
			END IF;
		ELSIF (Enreg_EXPORT_GESTION.TYPEMVT = 'DEC') THEN
			IF (Enreg_EXPORT_GESTION.DEPT = 'EMIS') THEN
				Var_PAYMT:=ABS(TO_NUMBER(Enreg_EXPORT_GESTION.ORAMT));
			ELSIF (Enreg_EXPORT_GESTION.DEPT = 'ANNULE') THEN
   	  			Var_RECPT:=ABS(TO_NUMBER(Enreg_EXPORT_GESTION.ORAMT));
			END IF;
		END IF;
	END IF;

	s_Ligne :=
		  Enreg_EXPORT_GESTION.ACCNUM||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.TRANSDATE||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.VALUEDATE||SEPARATEUR_FLUX_SORTIE||
		  '"'||Enreg_EXPORT_GESTION.NARR||'"'||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.INTREF||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.EXTREF||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.TYPEMVT||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.DEPT||SEPARATEUR_FLUX_SORTIE||
		  '"'||Enreg_EXPORT_GESTION.USER1||'"'||SEPARATEUR_FLUX_SORTIE||
		  '"'||Enreg_EXPORT_GESTION.USER2||'"'||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER3||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER4||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER5||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER6||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.CURR||SEPARATEUR_FLUX_SORTIE||
		  '"'||REPLACE(Enreg_EXPORT_GESTION.ORAMT,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
		  '"'||REPLACE(Var_RECPT,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
		  '"'||REPLACE(Var_PAYMT,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
		  '"'||Enreg_EXPORT_GESTION.QUANT||'"'||SEPARATEUR_FLUX_SORTIE||
		  '"'||REPLACE(Enreg_EXPORT_GESTION.PERC,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
		  '"'||REPLACE(Enreg_EXPORT_GESTION.UNITPRICE,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USERDATEA||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USERDATEB||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER7||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER8||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.FLAGA||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.FLAGB||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.FLAGC||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.FLAGD||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.FLAGE||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.FLAGF||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.FLAGG||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.FLAGH||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.ISSTATEMENT||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.ISHOLDING||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.WF_STR||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.PERIOD||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER9||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER10||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER11||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER12||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER13||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER14||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER15||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USER16||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USERDATEC||SEPARATEUR_FLUX_SORTIE||
		  Enreg_EXPORT_GESTION.USERDATED||SEPARATEUR_FLUX_SORTIE||
		  '"'||REPLACE(Enreg_EXPORT_GESTION.USERDECB,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
		  '"'||REPLACE(Enreg_EXPORT_GESTION.USERDECC,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
		  '"'||REPLACE(Enreg_EXPORT_GESTION.USERDECD,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE;

	INSERT INTO TW_EXPORT_GEST_JC (valeur)
      SELECT s_Ligne FROM DUAL;

END LOOP;

COMMIT;

EXCEPTION
WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('Procédure PR_RN_IMPORT_GEST_JC etape '|| v_step || ': erreur de transfert en TW_EXPORT_GEST_JC '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
	RAISE PB_TW_EXPORT_GEST_JC;
END;

/* **************************************************** */
/* FIN Transfert TA_RN_EXPORT_JC --> TW_EXPORT_GEST_JC  */
/* ******************************************************/

/* *********************************************************** */
/* DEBUT Generation du CLOB ExtraitReglement_JC.txt            */
/* *********************************************************** */
BEGIN
  v_step := 50;
	s_ReqPurgeClob := 'DELETE FROM TA_CLOB WHERE ID_DEC = ''433-GEST-JC''';
	EXECUTE IMMEDIATE s_ReqPurgeClob;
	COMMIT;

  v_step := 55;
	IF PKG_TEC_FICHIERS.F_ECRIRECSV_CLOB_SILENTLY(t_InfoTrait,
                                         s_ID_FIC,
                                         1,
                                         'SELECT valeur FROM TW_EXPORT_GEST_JC ORDER BY pos',
                                         s_NomFic || TO_CHAR(sysdate, 'yymmddhhmiss'),
                                         SEPARATEUR_FLUX_SORTIE,
                                         'OUT_APPLI') = -1 THEN RAISE PB_GENERATION_CLOB_GEST_JC;
  END IF;
  COMMIT;

  EXECUTE IMMEDIATE ('TRUNCATE TABLE TW_EXPORT_GEST_JC');

EXCEPTION
  WHEN OTHERS THEN
    EXECUTE IMMEDIATE ('TRUNCATE TABLE TW_EXPORT_GEST_JC');
	DBMS_OUTPUT.PUT_LINE('Procédure PR_RN_IMPORT_GEST_JC etape '|| v_step || ': erreur de generation du clob ExtraitReglement_JC.txt en TA_CLOB '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
    RAISE PB_GENERATION_CLOB_GEST_JC;
END;

/* ****************************************************************************** */
/* DEBUT Vidage des tables temporaires TA_RN_IMPORT_GESTION_JC et TA_RN_EXPORT_JC */
/* ****************************************************************************** */
BEGIN
v_step := 60;

  DBMS_OUTPUT.PUT_LINE('Vidage des tables temporaires TA_RN_IMPORT_GESTION_JC et TA_RN_EXPORT_JC');

  -- TA_RN_IMPORT_GESTION_JC --
  DELETE FROM TA_RN_IMPORT_GESTION_JC WHERE ID_CHARGEMENT_GESTION=Var_ID_CHARGEMENT_GESTION;
  DBMS_OUTPUT.PUT_LINE('Nombre de lignes TA_RN_IMPORT_GESTION_JC supprimées = '||TO_CHAR(SQL%ROWCOUNT));

  -- TA_RN_EXPORT_JC --
  DELETE FROM TA_RN_EXPORT_JC where TA_RN_EXPORT_JC.SOURCE = 'GEST' AND ID_CHARGEMENT=Var_ID_CHARGEMENT_GESTION;
  DBMS_OUTPUT.PUT_LINE('Nombre de lignes TA_RN_EXPORT_JC supprimées = '||TO_CHAR(SQL%ROWCOUNT));

  COMMIT;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     DBMS_OUTPUT.PUT_LINE('Pas de données à supprimer : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));

  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Etape '|| v_step || ': erreur de suppression des données dans TA_RN_IMPORT_GESTION_JC et TA_RN_EXPORT_JC : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
    RAISE SUPPRESSION_IMPOSSIBLE;
END;

/* **************************************************************************** */
/* FIN Vidage des tables temporaires TA_RN_IMPORT_GESTION_JC et TA_RN_EXPORT_JC */
/* **************************************************************************** */

/* **************************** */
/* GLOBAL exception block       */
/* **************************** */
EXCEPTION
WHEN PB_LECTURE_TX_REGLT_GEST THEN
 DBMS_OUTPUT.PUT_LINE('Erreur lecture donnees XML TX_REGLT_GEST');
 raise_application_error('-20001','Procédure PR_RN_IMPORT_GESTION: Erreur lecture donnees TX_REGLT_GEST');

WHEN SUPPRESSION_IMPOSSIBLE THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Erreur critique lors de la suppression de données dans TA_RN_IMPORT_GESTION_JC et TA_RN_EXPORT_JC');
 raise_application_error('-20002','Erreur critique lors de la suppression de données dans TA_RN_IMPORT_GESTION_JC et TA_RN_EXPORT_JC');

WHEN PARAM_GESTION_IMPOSSIBLE THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Erreur critique en alimentation table gestion_accurate');
 raise_application_error('-20003','Erreur critique en alimentation table gestion_accurate');

WHEN PB_INSERT_TA_RN_IMP_GEST_JC THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Problème insertion TA_RN_IMPORT_GESTION_JC');
 raise_application_error('-20004','Erreur critique en insertion table TA_RN_IMPORT_GESTION_JC');

WHEN PB_INSERT_TA_RN_EXPORT_JC THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Problème insertion TA_RN_EXPORT_JC');
 raise_application_error('-20005','Erreur critique lors de l''insertion dans la table TA_RN_EXPORT_JC');

WHEN PB_TW_EXPORT_GEST_JC THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('*** Problème alimentation TW_EXPORT_GEST_JC');
 raise_application_error('-20006', 'Problème d''alimentation de la table TW_EXPORT_GEST_JC');

WHEN PB_GENERATION_CLOB_GEST_JC THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('*** Problème generation CLOB ExtraitReglement_JC');
 raise_application_error('-20007', 'Problème de generation du CLOB ExtraitReglement_JC');

WHEN PB_ID_CHARGEMENT THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Problème lors de la generation ID_CHARGEMENT');
 raise_application_error('-20008','Erreur critique lors de la generation ID_CHARGEMENT');

WHEN PB_RECHERCHE_LIBELLE THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Problème transcodage société / mode de règlement');
 raise_application_error('-20009','Erreur critique en recherche société / mode de règlement');

WHEN OTHERS THEN
    -- En cas d erreur du traitement on ne valide pas les modifications
    ROLLBACK;
	DBMS_OUTPUT.PUT_LINE('Erreur : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
	raise_application_error('-20099','Erreur critique dans la procédure Procédure PR_RN_IMPORT_GESTION_JC '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
END;
/
