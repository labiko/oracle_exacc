-- ------------------------
-- PR_RN_IMPORT_GESTION.SQL
-- -----------------------
WHENEVER SQLERROR EXIT 202;
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
SET SERVEROUTPUT ON
SET VERIFY OFF
SET LINESIZE 2000

DECLARE

/* ********************************************************************************************************************   */
/* RAPPROCHEMENTS BANCAIRES : Procedure d'import du flux ExtraitReglement dans la table temporaire TA_RN_IMPORT_GESTION   */
/* ********************************************************************************************************************   */
/* ********************************************************************************************************************   */
/* PR_RN_IMPORT_GESTION 	: import du flux ExtraitReglement dans la table TA_RN_IMPORT_GESTION	          */
/* 				: traitement des donnees de TA_RN_IMPORT_GESTION (controles,filtres, aggregations...)     */
/* 				: export de la table TA_RN_EXPORT_GESTION sous forme de fichier plat pour integration     */
/*                                dans Accurate										  */
-- --------------------------------------------------------------------------------------------------
-- Algorithme --
-- -------------
-- * Recuperation des balises a alimenter pour la gestion : liste des balises en dur (performance)
-- * Ouverture du fichier FICHIER_GESTION en provenance du Bus
-- * Tant que le fichier n'est pas vide
-- * 	  Lecture du fichier ligne a ligne avec insertion dans la table TA_RN_IMPORT_GESTION
-- * Fermeture du fichier
-- * Archivage du fichier
-- * chargement des donnees dans TA_RN_EXPORT
-- * generation du fichier plat pour integration dans Accurate
/* ********************************************************************************** */

/* ******************************************************/
/* Variable d'import dans la table TA_RN_IMPORT_GESTION */
/* ******************************************************/
Var_DATECREATION TA_RN_IMPORT_GESTION.DATECREATION%TYPE :='';
Var_FROMDATETIME TA_RN_IMPORT_GESTION.FROMDATETIME%TYPE :='';
Var_TODATETIME TA_RN_IMPORT_GESTION.TODATETIME%TYPE :='';
Var_TYPEREGLEMENT TA_RN_IMPORT_GESTION.TYPEREGLEMENT%TYPE :='';
Var_STATUTREGLEMENT TA_RN_IMPORT_GESTION.STATUTREGLEMENT%TYPE :='';
Var_IDENTIFICATION TA_RN_IMPORT_GESTION.IDENTIFICATION%TYPE :='';
Var_ISSUER TA_RN_IMPORT_GESTION.ISSUER%TYPE :='';
Var_SCHEME TA_RN_IMPORT_GESTION.SCHEME%TYPE :='';
Var_PAYMENTREFERENCE TA_RN_IMPORT_GESTION.PAYMENTREFERENCE%TYPE :='';
Var_POLICYREFERENCE TA_RN_IMPORT_GESTION.POLICYREFERENCE%TYPE :='';
Var_NUMEROCLIENT TA_RN_IMPORT_GESTION.NUMEROCLIENT%TYPE :='';
Var_NOMCLIENT TA_RN_IMPORT_GESTION.NOMCLIENT%TYPE :='';
Var_SETTLEMENTMODE TA_RN_IMPORT_GESTION.SETTLEMENTMODE%TYPE :='';
Var_BANKCODE TA_RN_IMPORT_GESTION.BANKCODE%TYPE :='';
Var_BRANCHCODE TA_RN_IMPORT_GESTION.BRANCHCODE%TYPE :='';
Var_IDENTIFICATIONRIB TA_RN_IMPORT_GESTION.IDENTIFICATIONRIB%TYPE :='';
Var_RIBCHECKDIGIT TA_RN_IMPORT_GESTION.RIBCHECKDIGIT%TYPE :='';
Var_RIBCOMPLET TA_RN_IMPORT_GESTION.RIBCOMPLET%TYPE :='';
Var_VALUEDATE TA_RN_IMPORT_GESTION.VALUEDATE%TYPE :='';
Var_TRADEDATE TA_RN_IMPORT_GESTION.TRADEDATE%TYPE :='';
Var_OPERATIONNETAMOUNT TA_RN_IMPORT_GESTION.OPERATIONNETAMOUNT%TYPE :='';
Var_OPERATIONNETAMOUNTCURRENCY TA_RN_IMPORT_GESTION.OPERATIONNETAMOUNTCURRENCY%TYPE :='';
Var_BENEFICIARYNAME TA_RN_IMPORT_GESTION.BENEFICIARYNAME%TYPE :='';
Var_BENEFICIARYFIRST TA_RN_IMPORT_GESTION.BENEFICIARYFIRST%TYPE :='';
Var_BENEFICIARYREFERENCE TA_RN_IMPORT_GESTION.BENEFICIARYREFERENCE%TYPE :='';
Var_PRESENTMENTREFERENCE TA_RN_IMPORT_GESTION.PRESENTMENTREFERENCE%TYPE :='';
Var_CHEQUEREFERENCE TA_RN_IMPORT_GESTION.CHEQUEREFERENCE%TYPE :='';
Var_CHEQUEVIREMENTREFERENCE TA_RN_IMPORT_GESTION.CHEQUEREFERENCE%TYPE :=''; -- AJOUT pour SGF-79265-HERA champs du fichier Var_CHEQUEVIREMENTREFERENCE
Var_DEPOSITSLIPREFERENCE TA_RN_IMPORT_GESTION.DEPOSITSLIPREFERENCE%TYPE :='';
Var_CREDITSLIPREFERENCE TA_RN_IMPORT_GESTION.CREDITSLIPREFERENCE%TYPE :='';
Var_COMMENTAIRE TA_RN_IMPORT_GESTION.COMMENTAIRE%TYPE :='';
Var_CREATIONDATE TA_RN_IMPORT_GESTION.CREATIONDATE%TYPE :='';
Var_DATECOMPTAORIG TA_RN_IMPORT_GESTION.DATECOMPTAORIG%TYPE :='';  -- V1.2

Var_NOMSOCIETE TA_RN_IMPORT_GESTION.NOMSOCIETE%TYPE :='';
Var_LIBELLEMODEREGLEMENT TA_RN_IMPORT_GESTION.LIBELLEMODEREGLEMENT%TYPE :='';

/* ***********************************************/
/* Variables pour curseur Curseur_ZonesParCompte */
/* ***********************************************/
VarCurs_ID_COMPTE_BANC_SYST TA_RN_COMPTE_BANCAIRE_SYSTEME.ID_COMPTE_BANCAIRE_SYSTEME%TYPE;
VarCurs_NUMERO TA_RN_COMPTE_BANCAIRE_SYSTEME.NUMERO%TYPE;
VarCurs_RIBBANKCODE TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBANKCODE%TYPE;
VarCurs_RIBBRANCHCODE TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBRANCHCODE%TYPE;
VarCurs_RIBIDENTIFICATION TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBIDENTIFICATION%TYPE;
VarCurs_RIBCHECKDIGIT TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBCHECKDIGIT%TYPE;
VarCurs_GENERATIONCONTREPARTIE TA_RN_COMPTE_BANCAIRE_SYSTEME.GENERATIONCONTREPARTIE%TYPE;
VarCurs_NUM_COMPTE_ACCURATE TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE%TYPE;
VarCurs_RIB_DEPOSITAIRE TA_RN_COMPTE_BANCAIRE_SYSTEME.RIB%TYPE;
VarCurs_NOM_CHAMP TA_RN_FEEDER_STD.NOM_CHAMP%TYPE;
VarCurs_NOM_BALISE TA_RN_BALISE.NOM_BALISE%TYPE;

/* ***********************************************/
/* Transcodification societe + mode de reglement */
/* ***********************************************/
VarLibelle_Societe TA_RN_SOCIETE.NOM%TYPE;
VarLibelle_MR TA_RN_MODE_REGLEMENT.LIBELLE%TYPE;

/* ************************************************************/
/* Variables de reference pour curseur Curseur_ZonesParCompte */
/* ************************************************************/
Var_Ref_ID_COMPTE_BANC_SYST TA_RN_COMPTE_BANCAIRE_SYSTEME.ID_COMPTE_BANCAIRE_SYSTEME%TYPE;
Var_Ref_NUMERO TA_RN_COMPTE_BANCAIRE_SYSTEME.NUMERO%TYPE;
Var_Ref_RIBBANKCODE TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBANKCODE%TYPE;
Var_Ref_RIBBRANCHCODE TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBRANCHCODE%TYPE;
Var_Ref_RIBIDENTIFICATION TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBIDENTIFICATION%TYPE;
Var_Ref_RIBCHECKDIGIT TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBCHECKDIGIT%TYPE;
Var_Ref_GENERATIONCONTREPARTIE TA_RN_COMPTE_BANCAIRE_SYSTEME.GENERATIONCONTREPARTIE%TYPE;
Var_Ref_NUM_COMPTE_ACCURATE TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE%TYPE;
Var_Ref_RIB_DEPOSITAIRE TA_RN_COMPTE_BANCAIRE_SYSTEME.RIB%TYPE;
Var_Ref_NOM_CHAMP TA_RN_FEEDER_STD.NOM_CHAMP%TYPE;
Var_Ref_NOM_BALISE TA_RN_BALISE.NOM_BALISE%TYPE;

-- Variables pour Insert TA_RN_IMPORT_GESTION --
ListeChampsImport VARCHAR2(2048) :='(DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,
SCHEME,PAYMENTREFERENCE,POLICYREFERENCE,NUMEROCLIENT,NOMCLIENT,SETTLEMENTMODE,BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,
VALUEDATE,TRADEDATE,OPERATIONNETAMOUNT,OPERATIONNETAMOUNTCURRENCY,BENEFICIARYNAME,BENEFICIARYFIRST,BENEFICIARYREFERENCE,
PRESENTMENTREFERENCE,CHEQUEREFERENCE,DEPOSITSLIPREFERENCE,CREDITSLIPREFERENCE,COMMENTAIRE,CREATIONDATE,RIBCOMPLET,ID_CHARGEMENT_GESTION, DATECOMPTAORIG)';  -- V1.2

ListeChampsExport VARCHAR2(1024);
ListeValeursImport VARCHAR2(2048);

-- Variables de chargement
Var_ID_CHARGEMENT_GESTION INTEGER :=0;

-- V1.2 Variable ramenant la formule associee a la chaine et au statut reglement (EMIS ou ANNULE)
Var_FORMULE   TA_RN_FORMULES_GESTION.FORMULE%TYPE;

/* **********************************************/
/* Variable d'export dans la table TA_RN_EXPORT */
/* ******************************************** */
Var_ACCNUM	 		 TA_RN_EXPORT.ACCNUM%TYPE;
Var_TRANSDATE	 	 TA_RN_EXPORT.TRANSDATE%TYPE;
Var_VALUEDATE_EXP	 TA_RN_EXPORT.VALUEDATE%TYPE;
Var_NARR	 		 TA_RN_EXPORT.NARR%TYPE;
Var_INTREF	 		 TA_RN_EXPORT.INTREF%TYPE;
Var_EXTREF	 		 TA_RN_EXPORT.EXTREF%TYPE;
Var_TYPEMVT	 		 TA_RN_EXPORT.TYPEMVT%TYPE;
Var_DEPT	 		 TA_RN_EXPORT.DEPT%TYPE;
Var_USER1	 		 TA_RN_EXPORT.USER1%TYPE;
Var_USER2	 		 TA_RN_EXPORT.USER2%TYPE;
Var_USER3	 		 TA_RN_EXPORT.USER3%TYPE;
Var_USER4	 		 TA_RN_EXPORT.USER4%TYPE;
Var_USER5	 		 TA_RN_EXPORT.USER5%TYPE;
Var_USER6	 		 TA_RN_EXPORT.USER6%TYPE;
Var_USER7	 		 TA_RN_EXPORT.USER7%TYPE;
Var_USER8	 		 TA_RN_EXPORT.USER8%TYPE;
Var_USER9	 		 TA_RN_EXPORT.USER9%TYPE;
Var_USER10	 		 TA_RN_EXPORT.USER10%TYPE;
Var_USER11	 		 TA_RN_EXPORT.USER11%TYPE;
Var_USER12	 		 TA_RN_EXPORT.USER12%TYPE;
Var_USER13	 		 TA_RN_EXPORT.USER13%TYPE;
Var_USER14	 		 TA_RN_EXPORT.USER14%TYPE;
Var_USER15	 		 TA_RN_EXPORT.USER15%TYPE;
Var_USER16	 		 TA_RN_EXPORT.USER16%TYPE;
Var_CURR	 		 TA_RN_EXPORT.CURR%TYPE;
Var_ORAMT	 		 TA_RN_EXPORT.ACCNUM%TYPE;
Var_RECPT	 		 TA_RN_EXPORT.RECPT%TYPE;
Var_PAYMT	 		 TA_RN_EXPORT.PAYMT%TYPE;
Var_QUANT	 		 TA_RN_EXPORT.QUANT%TYPE;
Var_PERC	 		 TA_RN_EXPORT.PERC%TYPE;
Var_UNITPRICE 		 TA_RN_EXPORT.UNITPRICE%TYPE;
Var_USERDECB		 TA_RN_EXPORT.USERDECB%TYPE;
Var_USERDECC 		 TA_RN_EXPORT.USERDECC%TYPE;
Var_USERDECD 		 TA_RN_EXPORT.USERDECD%TYPE;
Var_USERDATEA 		 TA_RN_EXPORT.USERDATEA%TYPE;
Var_USERDATEB 		 TA_RN_EXPORT.USERDATEB%TYPE;
Var_USERDATEC 		 TA_RN_EXPORT.USERDATEC%TYPE;
Var_USERDATED 		 TA_RN_EXPORT.USERDATED%TYPE;
Var_FLAGA	 		 TA_RN_EXPORT.FLAGA%TYPE;
Var_FLAGB	 		 TA_RN_EXPORT.FLAGB%TYPE;
Var_FLAGC	 		 TA_RN_EXPORT.FLAGC%TYPE;
Var_FLAGD	 		 TA_RN_EXPORT.FLAGD%TYPE;
Var_FLAGE	 		 TA_RN_EXPORT.FLAGE%TYPE;
Var_FLAGF	 		 TA_RN_EXPORT.FLAGF%TYPE;
Var_FLAGG	 		 TA_RN_EXPORT.FLAGG%TYPE;
Var_FLAGH	 		 TA_RN_EXPORT.FLAGH%TYPE;
Var_ISSTATEMENT		 TA_RN_EXPORT.ISSTATEMENT%TYPE;
Var_ISHOLDING	 	 TA_RN_EXPORT.ISHOLDING%TYPE;
Var_WF_STR			 TA_RN_EXPORT.WF_STR%TYPE;
Var_PERIOD			 TA_RN_EXPORT.PERIOD%TYPE;

/* *************************************************************** */
/* Extraction des balises et zones du Feeder a alimenter dans	   */
/* Accurate pour la gestion	 	   	  		   			 	 	   */
/* (Alimentation du fichier d'export pour Accurate)            	   */
/* 				 					 	  						   */
/* Recuperation des zones correspondantes du Feeder standard	   */
/* Pour chaque compte du perimetre, zones du fichier a alimenter   */
/* 				 					 	  						   */
/* Le curseur ne s'appuie plus desormais que sur le RIB     	   */
/* *************************************************************** */

/* *************************************************************** */
/* 	Rapprochements bancaires		 	  						   */
/*******************************************************************/
CURSOR Curseur_ZonesParCompte IS
SELECT DISTINCT
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.ID_COMPTE_BANCAIRE_SYSTEME,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.NUMERO,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBANKCODE||TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBRANCHCODE||TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBIDENTIFICATION||TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBCHECKDIGIT AS RIB_DEPOSITAIRE,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBANKCODE,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBRANCHCODE,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBIDENTIFICATION,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBCHECKDIGIT,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.GENERATIONCONTREPARTIE,
	  TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE,
	  TA_RN_FEEDER_STD.NOM_CHAMP,
	  TA_RN_BALISE.NOM_BALISE
 FROM TA_RN_COMPTE_ACCURATE,
 	  TA_RN_BALISE,
 	  TA_RN_FEEDER_STD,
 	  TA_RN_BALISE_PAR_COMPTE,
 	  TA_RN_COMPTE_BANCAIRE_SYSTEME,
 	  TA_RN_GESTION_ACCURATE
WHERE TA_RN_COMPTE_BANCAIRE_SYSTEME.ID_COMPTE_BANCAIRE_SYSTEME=TA_RN_GESTION_ACCURATE.ID_COMPTE_BANCAIRE_SYSTEME
  AND TA_RN_GESTION_ACCURATE.ID_COMPTE_ACCURATE=TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE
  AND TA_RN_COMPTE_ACCURATE.FLAG_ACTIF='O'
  AND TA_RN_COMPTE_ACCURATE.TYPE_RAPPRO='B'
  AND TA_RN_BALISE_PAR_COMPTE.ID_BALISE=TA_RN_BALISE.ID_BALISE
  AND TA_RN_BALISE_PAR_COMPTE.ID_COMPTE_ACCURATE=TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE
  AND TA_RN_BALISE_PAR_COMPTE.NUM_COL_FEEDER=TA_RN_FEEDER_STD.NUM_COL_FEEDER
  AND TA_RN_BALISE.TYPE_BALISE='GEST'
ORDER BY  RIB_DEPOSITAIRE,
		  TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE,
	  	  TA_RN_FEEDER_STD.NOM_CHAMP,
	  	  TA_RN_BALISE.NOM_BALISE;

-- Variables receptrices du curseur --
Enreg_ZonesParCompte Curseur_ZonesParCompte%ROWTYPE;
		  
/* *************************************************************** */
/* 	Rapprochements comptabilite-gestion	  						   */
/*******************************************************************/
CURSOR CurseurC_ZonesParCompte IS
SELECT DISTINCT
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.ID_COMPTE_BANCAIRE_SYSTEME,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.NUMERO,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBANKCODE||TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBRANCHCODE||TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBIDENTIFICATION||TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBCHECKDIGIT AS RIB_DEPOSITAIRE,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBANKCODE,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBBRANCHCODE,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBIDENTIFICATION,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.RIBCHECKDIGIT,
	  TA_RN_COMPTE_BANCAIRE_SYSTEME.GENERATIONCONTREPARTIE,
	  TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE,
	  TA_RN_FEEDER_STD.NOM_CHAMP,
	  TA_RN_BALISE.NOM_BALISE
 FROM TA_RN_COMPTE_ACCURATE,
 	  TA_RN_BALISE,
 	  TA_RN_FEEDER_STD,
 	  TA_RN_BALISE_PAR_COMPTE,
 	  TA_RN_COMPTE_BANCAIRE_SYSTEME,
 	  TA_RN_GESTION_ACCURATE
WHERE TA_RN_COMPTE_BANCAIRE_SYSTEME.ID_COMPTE_BANCAIRE_SYSTEME=TA_RN_GESTION_ACCURATE.ID_COMPTE_BANCAIRE_SYSTEME
  AND TA_RN_GESTION_ACCURATE.ID_COMPTE_ACCURATE=TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE
  AND TA_RN_COMPTE_ACCURATE.FLAG_ACTIF='O'
  AND TA_RN_COMPTE_ACCURATE.TYPE_RAPPRO='C'
  AND TA_RN_BALISE_PAR_COMPTE.ID_BALISE=TA_RN_BALISE.ID_BALISE
  AND TA_RN_BALISE_PAR_COMPTE.ID_COMPTE_ACCURATE=TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE
  AND TA_RN_BALISE_PAR_COMPTE.NUM_COL_FEEDER=TA_RN_FEEDER_STD.NUM_COL_FEEDER
  AND TA_RN_BALISE.TYPE_BALISE='GEST'
ORDER BY  RIB_DEPOSITAIRE,
		  TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE,
	  	  TA_RN_FEEDER_STD.NOM_CHAMP,
	  	  TA_RN_BALISE.NOM_BALISE;
		  
-- Variables receptrices du curseur --
EnregC_ZonesParCompte CurseurC_ZonesParCompte%ROWTYPE;

/* *************************************************************** */
/* Curseur sur la table d'EXPORT								   */
/* *************************************************************** */
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
FROM TA_RN_EXPORT
WHERE TA_RN_EXPORT.SOURCE = 'GEST'
  AND ID_CHARGEMENT=Var_ID_CHARGEMENT_GESTION
ORDER BY ACCNUM;

-- Variables receptrices du curseur --
Enreg_EXPORT_GESTION Curseur_EXPORT_GESTION%ROWTYPE;

-- Definition des erreurs applicatives --
PB_LECTURE_TX_REGLT_GEST EXCEPTION;
SUPPRESSION_IMPOSSIBLE EXCEPTION;
PARAM_GESTION_IMPOSSIBLE EXCEPTION;
PB_INSERT_TA_RN_IMP_GEST EXCEPTION;
PB_INSERT_TA_RN_EXPORT EXCEPTION;
PB_TW_EXPORT_GEST EXCEPTION;
PB_GENERATION_CLOB_GST EXCEPTION;
PB_GENERATION_CLOB_GDT EXCEPTION;
PB_RECHERCHE_LIBELLE EXCEPTION;
PB_ID_CHARGEMENT EXCEPTION;

LIGNE_FLUX_GESTION VARCHAR2(512);
LIGNE_FLUX_SORTIE VARCHAR2(4096);
s_Ligne VARCHAR2(1000);
SEPARATEUR_FLUX_SORTIE CHAR(1):=',';

Var_Source CONSTANT CHAR(4) :='GEST';

s_ID_FIC_GST CONSTANT VARCHAR2(64) := 'FIC_EXP_GEST';
s_ID_FIC_GDT CONSTANT VARCHAR2(64) := 'FIC_EXP_GDT';
t_InfoTrait_GST PKG_GLOBAL.T_INFO_TRAITEMENT := '<IdExec>431-GEST</IdExec>';
t_InfoTrait_GDT PKG_GLOBAL.T_INFO_TRAITEMENT := '<IdExec>432-GDT</IdExec>';
s_NomFic_GST   CONSTANT VARCHAR2(50) := 'ExtraitReglement.txt.';
s_NomFic_GDT   CONSTANT VARCHAR2(50) := 'ExtraitReglement_RapCtl.txt.';

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
/* Declaration des fonctions */
/* ************************* */
 
/* ************************* */
/* --- Extraction Balise --- */
/* ************************* */
FUNCTION ExtraireBalise(Balise IN varchar2, Chaine IN varchar2) RETURN varchar2 IS

position_deb integer;
longueur integer;

valeur_balise varchar2(250);

 BEGIN
	  -- Debut de la valeur de balise (position de la balise + longueur balise) --
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

	  -- Debut de la valeur de balise (position de la balise + longueur balise) --
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

	  -- Debut de la valeur de balise
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

	  -- Debut de la valeur de balise (position de la balise + longueur balise) --
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
	 
	   SELECT LIBELLE INTO 	libelle FROM TA_RN_MODE_REGLEMENT
		WHERE CODE_MODE_REGLEMENT = CodeMR;

	EXCEPTION
	   WHEN NO_DATA_FOUND THEN
		  libelle := 'Operation sans libelle';

	   WHEN OTHERS THEN
		  --DBMS_OUTPUT.PUT_LINE('Erreur recherche mode de reglement : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
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
		SELECT 	NOM INTO libelle FROM TA_RN_SOCIETE
		  WHERE	CODE = CodeSociete;
		  
	EXCEPTION
	  WHEN NO_DATA_FOUND THEN
		  libelle := '';

	  WHEN OTHERS THEN
		  --DBMS_OUTPUT.PUT_LINE('Erreur recherche libelle societe : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
		  RAISE PB_RECHERCHE_LIBELLE;

	END;

    -- DBMS_OUTPUT.PUT_LINE('Fonction Libelle societe : >'||libelle||'<');
	RETURN libelle;
END LibelleSociete;
/* ******************************** */
/* Fin de declaration des fonctions */
/* ******************************** */

/* *********************** */
/* Debut procedure globale */
/* *********************** */
BEGIN

/* ************************************* */
/* DEBUT Recuperation de l'ID chargement */
/* ************************************* */

BEGIN
v_step := 10;
SELECT SQ_RN_CHRGGEST.nextval INTO Var_ID_CHARGEMENT_GESTION FROM DUAL;

EXCEPTION
WHEN OTHERS THEN
	 DBMS_OUTPUT.PUT_LINE('Etape ' || v_step || ': erreur lors du calcul de l''ID_CHARGEMENT '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
	 RAISE PB_ID_CHARGEMENT;
END;

--DBMS_OUTPUT.PUT_LINE('Var_ID_CHARGEMENT_GESTION : '||TO_CHAR(Var_ID_CHARGEMENT_GESTION));

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
Var_CHEQUEVIREMENTREFERENCE :=''; -- AJOUT pour SGF-79265-HERA champs du fichier Var_CHEQUEVIREMENTREFERENCE
Var_DEPOSITSLIPREFERENCE :='';
Var_CREDITSLIPREFERENCE :='';
Var_COMMENTAIRE :='';
Var_CREATIONDATE :='';
Var_DATECOMPTAORIG :='';  -- V1.2

tab_REG_XML := T_REG_XML();

OPEN Curseur_Lignes_XML;
FETCH Curseur_Lignes_XML BULK COLLECT INTO tab_REG_XML;
CLOSE Curseur_Lignes_XML;

v_step := 25;

--DBMS_OUTPUT.PUT_LINE('BULK COLLECT!');

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
		-- AJOUT pour SGF-79265-HERA champs du fichier Var_CHEQUEVIREMENTREFERENCE
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<ChequeVirementReference>') <> 0 THEN
			Var_CHEQUEVIREMENTREFERENCE := ExtraireBalise('<ChequeVirementReference>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<DepositSlipReference>') <> 0 THEN
			Var_DEPOSITSLIPREFERENCE := ExtraireBalise('<DepositSlipReference>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<DepositSliptReference>') <> 0 THEN
			Var_DEPOSITSLIPREFERENCE := ExtraireBalise('<DepositSliptReference>',TRIM(LIGNE_FLUX_GESTION));
		ELSIF INSTR(LIGNE_FLUX_GESTION,'<CreditSlipReference>') <> 0 THEN
			Var_CREDITSLIPREFERENCE := ExtraireBalise('<CreditSlipReference>',TRIM(LIGNE_FLUX_GESTION));
		-- FIN de Reglement, time to INSERT
		ELSIF (INSTR(LIGNE_FLUX_GESTION,'</Reglement>')) <> 0 THEN
			-- Si le libelle n'est pas renseigne, on le renseigne par le mode de reglement 
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
			-- La date de saisie et la date valeur restent inchangees
			-- Date d'operation prend la valeur de la date de saisie
			-- La balise USERDATEB contiendra la date comptable d'origine
		  
				Var_DATECOMPTAORIG := Var_TRADEDATE;
				Var_TRADEDATE := Var_CREATIONDATE;

			ELSIF Var_FORMULE = 1 THEN

			-- Formule 1   
			-- Mise a jour de la date comptable si elle est anterieure au mois/annee de la date de saisie --
				IF NOT (LENGTH(Var_TRADEDATE) = 0 OR LENGTH(Var_CREATIONDATE) = 0 OR LENGTH(Var_CREATIONDATE) IS NULL OR LENGTH(Var_TRADEDATE) IS NULL) THEN
					  -- Si la date de saisie < date integration alors date de saisie = date integration - 1 jour 
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
			-- 20241203  AJOUT pour SGF-79265-HERA champs du fichier Var_CHEQUEVIREMENTREFERENCE
            -- 20241203 remplacement de Var_CHEQUEREFERENCE par Var_CHEQUEVIREMENTREFERENCE pour HERA si CM ou VM
			IF Var_SCHEME = 'HERA' AND (Var_SETTLEMENTMODE = 'CM' OR Var_SETTLEMENTMODE = 'VM') THEN
			    Var_CHEQUEREFERENCE := Var_CHEQUEVIREMENTREFERENCE ;
			END IF;
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
				EXECUTE IMMEDIATE 'INSERT INTO TA_RN_IMPORT_GESTION '||ListeChampsImport||' '||'VALUES '||ListeValeursImport;
			    
				-- ADI
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
			   Var_RIBCOMPLET:='';
			   Var_BANKCODE :='';
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
			   Var_CHEQUEVIREMENTREFERENCE :=''; -- AJOUT pour SGF-79265-HERA champs du fichier Var_CHEQUEVIREMENTREFERENCE
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
					DBMS_OUTPUT.PUT_LINE('Erreur inconnue lors de l''insertion en TA_RN_IMPORT_GESTION : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
					RAISE PB_INSERT_TA_RN_IMP_GEST;
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
DBMS_OUTPUT.PUT_LINE('Etape '|| v_step || ': Traitement import dans TA_RN_IMPORT_GESTION termine avec succes.');

EXCEPTION
WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('Procedure PR_RN_IMPORT_GESTION etape '|| v_step || ': erreur lors de l''import TX_REGLT_GEST --> TA_RN_IMPORT_GESTION '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
    RAISE PB_LECTURE_TX_REGLT_GEST;

END;

/* ************************************************* */
/* DEBUT Alimentation de la table d'export			 */
/* 		 			  	 		 		   			 */
/* Pour chaque Societe,devise,type de reglement,	 */
/* 	  		   Mode de reglement,compte accurate	 */
/* 	  		- liste des champs pour insert			 */
/* 	  		- liste des valeurs pour insert			 */
/* ************************************************* */
BEGIN

v_step := 30;
ListeChampsExport :='ID_CHARGEMENT,';
ListeValeursImport := ''||Var_ID_CHARGEMENT_GESTION||',';

OPEN Curseur_ZonesParCompte;

FETCH Curseur_ZonesParCompte
 INTO VarCurs_ID_COMPTE_BANC_SYST,
      VarCurs_NUMERO,
      VarCurs_RIB_DEPOSITAIRE,
      VarCurs_RIBBANKCODE,
      VarCurs_RIBBRANCHCODE,
      VarCurs_RIBIDENTIFICATION,
      VarCurs_RIBCHECKDIGIT,
	  VarCurs_GENERATIONCONTREPARTIE,
      VarCurs_NUM_COMPTE_ACCURATE,
      VarCurs_NOM_CHAMP,
      VarCurs_NOM_BALISE;

Var_Ref_ID_COMPTE_BANC_SYST := VarCurs_ID_COMPTE_BANC_SYST;
Var_Ref_NUMERO := VarCurs_NUMERO;
Var_Ref_RIB_DEPOSITAIRE:=VarCurs_RIB_DEPOSITAIRE;
Var_Ref_RIBBANKCODE:=VarCurs_RIBBANKCODE;
Var_Ref_RIBBRANCHCODE:=VarCurs_RIBBRANCHCODE;
Var_Ref_RIBIDENTIFICATION:=VarCurs_RIBIDENTIFICATION;
Var_Ref_RIBCHECKDIGIT:=VarCurs_RIBCHECKDIGIT;
Var_Ref_GENERATIONCONTREPARTIE:=VarCurs_GENERATIONCONTREPARTIE;
Var_Ref_NUM_COMPTE_ACCURATE := VarCurs_NUM_COMPTE_ACCURATE;
Var_Ref_NOM_CHAMP := VarCurs_NOM_CHAMP;
Var_Ref_NOM_BALISE := VarCurs_NOM_BALISE;

-- Tant que pas fin fichier --
WHILE (NOT Curseur_ZonesParCompte%NOTFOUND)
LOOP
   
	-- Tant que pas fin fichier et meme societe-devise-mode reglement-RIB Depositaire --
	WHILE (
	   Var_Ref_RIBBANKCODE=VarCurs_RIBBANKCODE
	   AND Var_Ref_RIBBRANCHCODE=VarCurs_RIBBRANCHCODE
	   AND Var_Ref_RIBIDENTIFICATION=VarCurs_RIBIDENTIFICATION
	   AND Var_Ref_RIBCHECKDIGIT=VarCurs_RIBCHECKDIGIT
	   AND NOT Curseur_ZonesParCompte%NOTFOUND )
	LOOP
		  -- Tant que pas fin fichier et meme societe-devise-mode reglement-RIB depositaire-type de reglement-compte accurate --
		WHILE (
			 Var_Ref_RIBBANKCODE=VarCurs_RIBBANKCODE
			 AND Var_Ref_RIBBRANCHCODE=VarCurs_RIBBRANCHCODE
			 AND Var_Ref_RIBIDENTIFICATION=VarCurs_RIBIDENTIFICATION
			 AND Var_Ref_RIBCHECKDIGIT=VarCurs_RIBCHECKDIGIT
			 AND Var_Ref_NUM_COMPTE_ACCURATE=VarCurs_NUM_COMPTE_ACCURATE
			 AND NOT Curseur_ZonesParCompte%NOTFOUND )
		LOOP
			ListeChampsExport := ListeChampsExport||VarCurs_NOM_CHAMP||',';
			ListeValeursImport := ListeValeursImport||VarCurs_NOM_BALISE||',';
								 
			FETCH Curseur_ZonesParCompte
			INTO
			 VarCurs_ID_COMPTE_BANC_SYST,
			 VarCurs_NUMERO,
			 VarCurs_RIB_DEPOSITAIRE,
			 VarCurs_RIBBANKCODE,
			 VarCurs_RIBBRANCHCODE,
			 VarCurs_RIBIDENTIFICATION,
			 VarCurs_RIBCHECKDIGIT,
			 VarCurs_GENERATIONCONTREPARTIE,
			 VarCurs_NUM_COMPTE_ACCURATE,
			 VarCurs_NOM_CHAMP,
			 VarCurs_NOM_BALISE;

		  -- Tant que pas fin fichier et meme societe-devise-mode reglement-RIB depositaire-type de reglement-compte accurate --
		END LOOP;

		-- Enregistrement ListeChampsImport et ListeValeursImport dans la table pour la cle correspondante
		-- Cle = societe + devise + mode de reglement + RIB depositaire + type reglement + compte accurate
		ListeChampsExport := SUBSTR(ListeChampsExport,1,LENGTH(ListeChampsExport) - 1);
		ListeValeursImport := SUBSTR(ListeValeursImport,1,LENGTH(ListeValeursImport) - 1);
  
		-- Generation du detail des ecritures pour les modes de reglement non cumules --
		BEGIN
			v_step := 32;
			EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT (SOURCE,ACCNUM,'||ListeChampsExport||')'
								  ||' ('
								  ||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport||' FROM TA_RN_IMPORT_GESTION WHERE '
								  ||' NOT IDENTIFICATION IN (SELECT CODE FROM TA_RN_SOCIETE,TA_RN_EXCLUSION_SOCIETE WHERE TA_RN_SOCIETE.ID_SOCIETE=TA_RN_EXCLUSION_SOCIETE.ID_SOCIETE AND TA_RN_EXCLUSION_SOCIETE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'					  		 
								  ||' AND NOT OPERATIONNETAMOUNTCURRENCY IN (SELECT CODE_ISO_DEVISE FROM TA_RN_DEVISE,TA_RN_EXCLUSION_DEVISE WHERE TA_RN_DEVISE.ID_DEVISE=TA_RN_EXCLUSION_DEVISE.ID_DEVISE AND TA_RN_EXCLUSION_DEVISE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND NOT SETTLEMENTMODE IN (SELECT CODE_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT,TA_RN_EXCLUSION_MR WHERE TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT=TA_RN_EXCLUSION_MR.ID_MODE_REGLEMENT AND TA_RN_EXCLUSION_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND NOT TYPEREGLEMENT IN (SELECT TYPE_REGLEMENT FROM TA_RN_EXCLUSION_TR WHERE TA_RN_EXCLUSION_TR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND (NOT EXISTS (SELECT 1 FROM TA_RN_MODE_REGLEMENT,TA_RN_CUMUL_MR, TA_RN_PRODUIT'
								  ||' WHERE TA_RN_CUMUL_MR.ID_MODE_REGLEMENT=TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT'
								  ||' AND TA_RN_CUMUL_MR.ID_PRODUIT=TA_RN_PRODUIT.ID_PRODUIT'
								  ||' AND TA_RN_CUMUL_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST
								  ||' AND (TA_RN_PRODUIT.CODE_PRODUIT=NUMEROCLIENT OR TA_RN_PRODUIT.CODE_PRODUIT=''ALL'')'
								  ||' AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=SETTLEMENTMODE OR TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=''ALL'')'
								  ||')'
								  ||'  OR (SETTLEMENTMODE IN ('||''''||'VO'||''''||','||''''||'PC'||''''||','||''''||'PQ'||''''||','||''''||'PM'||''''||') AND STATUTREGLEMENT = '||''''||'ANNULE'||''''||')'
								  ||')'								  		  
								  ||' AND IDENTIFICATIONRIB = '||''''||Var_Ref_RIBIDENTIFICATION||''''
								  ||' AND RIBCHECKDIGIT = '||''''||Var_Ref_RIBCHECKDIGIT||''''
								  ||' AND BANKCODE = '||''''||Var_Ref_RIBBANKCODE||''''
								  ||' AND BRANCHCODE = '||''''||Var_Ref_RIBBRANCHCODE||''''
								  ||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
								  ||')';
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
		  DBMS_OUTPUT.PUT_LINE('Pas de detail');

		  WHEN OTHERS THEN
		  DBMS_OUTPUT.PUT_LINE('Etape '|| v_step || ': erreur insertion dans TA_RN_EXPORT : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
		  RAISE PB_INSERT_TA_RN_EXPORT;

		END;
		-- Fin generation du detail des ecritures pour les modes de reglement non cumules --
  
		-- Generation du cumul des ecritures pour les modes de reglement cumules --  
		BEGIN
			v_step := 34;
			EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT (SOURCE,ACCNUM,'||ListeChampsExport||')'
								  ||' ('
								  ||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport
								  ||' FROM '
								  ||' (SELECT DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,'
								  ||''''||''''||' AS PAYMENTREFERENCE,'||''''||''''||' AS POLICYREFERENCE,'||''''||''''||' AS NUMEROCLIENT,'||''''||''''||' AS NOMCLIENT,'
								  ||'SETTLEMENTMODE,BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,'||''''||''''||' AS VALUEDATE,TRADEDATE,'
								  ||' SUM(TO_NUMBER(OPERATIONNETAMOUNT)) AS OPERATIONNETAMOUNT,OPERATIONNETAMOUNTCURRENCY,'||''''||''''||' AS BENEFICIARYNAME,'
								  ||''''||''''||' AS BENEFICIARYFIRST,'||''''||''''||' AS BENEFICIARYREFERENCE,'||''''||''''||' AS PRESENTMENTREFERENCE,'||''''||''''||' AS CHEQUEREFERENCE,'
								  ||''''||''''||' AS DEPOSITSLIPREFERENCE,'||''''||''''||' AS CREDITSLIPREFERENCE,'||''''||'Ecriture cumul quotidien'||''''||' AS COMMENTAIRE,'
								  ||''''||''''||' AS CREATIONDATE,'||''''||''''||' AS RIBCOMPLET,'||'ID_CHARGEMENT_GESTION, DATECOMPTAORIG FROM TA_RN_IMPORT_GESTION '   -- V1.2
								  ||'WHERE NOT IDENTIFICATION IN (SELECT CODE FROM TA_RN_SOCIETE,TA_RN_EXCLUSION_SOCIETE WHERE TA_RN_SOCIETE.ID_SOCIETE=TA_RN_EXCLUSION_SOCIETE.ID_SOCIETE AND TA_RN_EXCLUSION_SOCIETE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'					  		 
								  ||' AND NOT OPERATIONNETAMOUNTCURRENCY IN (SELECT CODE_ISO_DEVISE FROM TA_RN_DEVISE,TA_RN_EXCLUSION_DEVISE WHERE TA_RN_DEVISE.ID_DEVISE=TA_RN_EXCLUSION_DEVISE.ID_DEVISE AND TA_RN_EXCLUSION_DEVISE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND NOT SETTLEMENTMODE IN (SELECT CODE_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT,TA_RN_EXCLUSION_MR WHERE TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT=TA_RN_EXCLUSION_MR.ID_MODE_REGLEMENT AND TA_RN_EXCLUSION_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND NOT TYPEREGLEMENT IN (SELECT TYPE_REGLEMENT FROM TA_RN_EXCLUSION_TR WHERE TA_RN_EXCLUSION_TR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND EXISTS (SELECT 1 FROM TA_RN_MODE_REGLEMENT,TA_RN_CUMUL_MR, TA_RN_PRODUIT'
								  ||' WHERE TA_RN_CUMUL_MR.ID_MODE_REGLEMENT=TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT'
								  ||' AND TA_RN_CUMUL_MR.ID_PRODUIT=TA_RN_PRODUIT.ID_PRODUIT'
								  ||' AND TA_RN_CUMUL_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST
								  ||' AND (TA_RN_PRODUIT.CODE_PRODUIT=NUMEROCLIENT OR TA_RN_PRODUIT.CODE_PRODUIT=''ALL'')'
								  ||' AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=SETTLEMENTMODE OR TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=''ALL'')'
								  ||')'
								  ||' AND NOT (SETTLEMENTMODE IN ('||''''||'VO'||''''||','||''''||'PC'||''''||','||''''||'PQ'||''''||','||''''||'PM'||''''||') AND STATUTREGLEMENT = '||''''||'ANNULE'||''''||')'
								  ||' AND IDENTIFICATIONRIB = '||''''||Var_Ref_RIBIDENTIFICATION||''''
								  ||' AND RIBCHECKDIGIT = '||''''||Var_Ref_RIBCHECKDIGIT||''''
								  ||' AND BANKCODE = '||''''||Var_Ref_RIBBANKCODE||''''
								  ||' AND BRANCHCODE = '||''''||Var_Ref_RIBBRANCHCODE||''''
								  ||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
								  ||' GROUP BY DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,SETTLEMENTMODE,BANKCODE,'
								  ||'BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,TRADEDATE,OPERATIONNETAMOUNTCURRENCY,ID_CHARGEMENT_GESTION, DATECOMPTAORIG)'   -- V1.2
								  ||')';

		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
		  DBMS_OUTPUT.PUT_LINE('Pas de cumul');

		  WHEN OTHERS THEN
		  DBMS_OUTPUT.PUT_LINE('Etape '|| v_step || ': erreur insertion dans TA_RN_EXPORT : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
		  RAISE PB_INSERT_TA_RN_EXPORT;

		END;
		-- Fin Generation du cumul des ecritures pour les modes de reglement cumules --

		-- Generation d'une ecriture de contrepartie qui se rapprochera avec le cumul saisi en compta   --
		IF Var_Ref_GENERATIONCONTREPARTIE='O' THEN
			BEGIN
				-- ecriture de contrepartie = cumul par date comptable  --
   			    --Si le flux vient de WYNSURE
				v_step := 36;
			    EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT (SOURCE,ACCNUM,'||ListeChampsExport||')'
							  ||' ('
							  ||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport
							  ||' FROM '
							  ||' (SELECT DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,'
							  ||''''||''''||' AS PAYMENTREFERENCE,'||''''||''''||' AS POLICYREFERENCE,NUMEROCLIENT,'||''''||''''||' AS NOMCLIENT,'
							  ||'SETTLEMENTMODE,BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,'||''''||''''||' AS VALUEDATE,TRADEDATE,'
							  ||' DECODE(SCHEME,'||''''||'ELOG'||''''||',SUM(ABS(TO_NUMBER(OPERATIONNETAMOUNT))), SUM(TO_NUMBER(OPERATIONNETAMOUNT))) AS OPERATIONNETAMOUNT,OPERATIONNETAMOUNTCURRENCY,'||''''||''''||' AS BENEFICIARYNAME,'  -- V1.1
							  ||''''||''''||' AS BENEFICIARYFIRST,'||''''||''''||' AS BENEFICIARYREFERENCE,'||''''||''''||' AS PRESENTMENTREFERENCE,'||''''||''''||' AS CHEQUEREFERENCE,'
							  ||''''||''''||' AS DEPOSITSLIPREFERENCE,'||''''||''''||' AS CREDITSLIPREFERENCE,'||''''||'Ecriture extourne'||''''||' AS COMMENTAIRE,'
							  ||''''||''''||' AS CREATIONDATE,'||''''||''''||' AS RIBCOMPLET,'||'ID_CHARGEMENT_GESTION, DATECOMPTAORIG FROM TA_RN_IMPORT_GESTION '   -- V1.2
							  ||'WHERE NOT IDENTIFICATION IN (SELECT CODE FROM TA_RN_SOCIETE,TA_RN_EXCLUSION_SOCIETE WHERE TA_RN_SOCIETE.ID_SOCIETE=TA_RN_EXCLUSION_SOCIETE.ID_SOCIETE AND TA_RN_EXCLUSION_SOCIETE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'					  		 
							  ||' AND NOT OPERATIONNETAMOUNTCURRENCY IN (SELECT CODE_ISO_DEVISE FROM TA_RN_DEVISE,TA_RN_EXCLUSION_DEVISE WHERE TA_RN_DEVISE.ID_DEVISE=TA_RN_EXCLUSION_DEVISE.ID_DEVISE AND TA_RN_EXCLUSION_DEVISE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
							  ||' AND NOT SETTLEMENTMODE IN (SELECT CODE_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT,TA_RN_EXCLUSION_MR WHERE TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT=TA_RN_EXCLUSION_MR.ID_MODE_REGLEMENT AND TA_RN_EXCLUSION_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
							  ||' AND NOT TYPEREGLEMENT IN (SELECT TYPE_REGLEMENT FROM TA_RN_EXCLUSION_TR WHERE TA_RN_EXCLUSION_TR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
							  ||' AND IDENTIFICATIONRIB = '||''''||Var_Ref_RIBIDENTIFICATION||''''
							  ||' AND RIBCHECKDIGIT = '||''''||Var_Ref_RIBCHECKDIGIT||''''
							  ||' AND BANKCODE = '||''''||Var_Ref_RIBBANKCODE||''''
							  ||' AND BRANCHCODE = '||''''||Var_Ref_RIBBRANCHCODE||''''
							  ||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
							  ||' AND SCHEME = ''WYNSURE'''
							  ||' GROUP BY DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,SETTLEMENTMODE,BANKCODE,'
							  ||'BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,TRADEDATE,OPERATIONNETAMOUNTCURRENCY,ID_CHARGEMENT_GESTION, DATECOMPTAORIG,NUMEROCLIENT)'   -- V1.2
							  ||')';
				                 		  
				--Si le flux ne vient pas de WYNSURE
				v_step := 38;
                EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT (SOURCE,ACCNUM,'||ListeChampsExport||')'
				                  		  ||' ('
								  		  ||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport
										  ||' FROM '
										  ||' (SELECT DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,'
										  ||''''||''''||' AS PAYMENTREFERENCE,'||''''||''''||' AS POLICYREFERENCE,'||''''||''''||' AS NUMEROCLIENT,'||''''||''''||' AS NOMCLIENT,'
                                          ||'SETTLEMENTMODE,BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,'||''''||''''||' AS VALUEDATE,TRADEDATE,'
                                          ||' DECODE(SCHEME,'||''''||'ELOG'||''''||',SUM(ABS(TO_NUMBER(OPERATIONNETAMOUNT))), SUM(TO_NUMBER(OPERATIONNETAMOUNT))) AS OPERATIONNETAMOUNT,OPERATIONNETAMOUNTCURRENCY,'||''''||''''||' AS BENEFICIARYNAME,'  -- V1.1
                                          ||''''||''''||' AS BENEFICIARYFIRST,'||''''||''''||' AS BENEFICIARYREFERENCE,'||''''||''''||' AS PRESENTMENTREFERENCE,'||''''||''''||' AS CHEQUEREFERENCE,'
                                          ||''''||''''||' AS DEPOSITSLIPREFERENCE,'||''''||''''||' AS CREDITSLIPREFERENCE,'||''''||'Ecriture extourne'||''''||' AS COMMENTAIRE,'
										  ||''''||''''||' AS CREATIONDATE,'||''''||''''||' AS RIBCOMPLET,'||'ID_CHARGEMENT_GESTION, DATECOMPTAORIG FROM TA_RN_IMPORT_GESTION '   -- V1.2
   								  		  ||'WHERE NOT IDENTIFICATION IN (SELECT CODE FROM TA_RN_SOCIETE,TA_RN_EXCLUSION_SOCIETE WHERE TA_RN_SOCIETE.ID_SOCIETE=TA_RN_EXCLUSION_SOCIETE.ID_SOCIETE AND TA_RN_EXCLUSION_SOCIETE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'					  		 
										  ||' AND NOT OPERATIONNETAMOUNTCURRENCY IN (SELECT CODE_ISO_DEVISE FROM TA_RN_DEVISE,TA_RN_EXCLUSION_DEVISE WHERE TA_RN_DEVISE.ID_DEVISE=TA_RN_EXCLUSION_DEVISE.ID_DEVISE AND TA_RN_EXCLUSION_DEVISE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  		  ||' AND NOT SETTLEMENTMODE IN (SELECT CODE_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT,TA_RN_EXCLUSION_MR WHERE TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT=TA_RN_EXCLUSION_MR.ID_MODE_REGLEMENT AND TA_RN_EXCLUSION_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  		  ||' AND NOT TYPEREGLEMENT IN (SELECT TYPE_REGLEMENT FROM TA_RN_EXCLUSION_TR WHERE TA_RN_EXCLUSION_TR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  		  ||' AND IDENTIFICATIONRIB = '||''''||Var_Ref_RIBIDENTIFICATION||''''
								  		  ||' AND RIBCHECKDIGIT = '||''''||Var_Ref_RIBCHECKDIGIT||''''
								  		  ||' AND BANKCODE = '||''''||Var_Ref_RIBBANKCODE||''''
								  		  ||' AND BRANCHCODE = '||''''||Var_Ref_RIBBRANCHCODE||''''
								  		  ||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
								  		  ||' AND SCHEME <> ''WYNSURE'''
										  ||' GROUP BY DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,SETTLEMENTMODE,BANKCODE,'
  		  								  ||'BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,TRADEDATE,OPERATIONNETAMOUNTCURRENCY,ID_CHARGEMENT_GESTION, DATECOMPTAORIG)'   -- V1.2
				                 		  ||')';
				                 		  
			EXCEPTION
			  WHEN NO_DATA_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('Pas de contrepartie');

			  WHEN OTHERS THEN
			     DBMS_OUTPUT.PUT_LINE('Etape ' || v_step || ': erreur insertion dans TA_RN_EXPORT : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
			     RAISE PB_INSERT_TA_RN_EXPORT;
		    END;
		END IF;
		-- Fin generation d'une ecriture de contrepartie qui se rapprochera avec le cumul saisi en compta --
				  
		ListeChampsExport :='ID_CHARGEMENT,';
		ListeValeursImport := ''||Var_ID_CHARGEMENT_GESTION||',';

		Var_Ref_NUM_COMPTE_ACCURATE := VarCurs_NUM_COMPTE_ACCURATE;
		Var_Ref_GENERATIONCONTREPARTIE:=VarCurs_GENERATIONCONTREPARTIE;

	-- Tant que pas fin fichier et meme societe-devise-mode reglement-RIB Depositaire --
    END LOOP;

	Var_Ref_NUMERO := VarCurs_NUMERO;
	Var_Ref_RIB_DEPOSITAIRE:=VarCurs_RIB_DEPOSITAIRE;
	Var_Ref_RIBBANKCODE:=VarCurs_RIBBANKCODE;
	Var_Ref_RIBBRANCHCODE:=VarCurs_RIBBRANCHCODE;
	Var_Ref_RIBIDENTIFICATION:=VarCurs_RIBIDENTIFICATION;
	Var_Ref_RIBCHECKDIGIT:=VarCurs_RIBCHECKDIGIT;
	Var_Ref_ID_COMPTE_BANC_SYST := VarCurs_ID_COMPTE_BANC_SYST;

END LOOP;

CLOSE Curseur_ZonesParCompte;

DBMS_OUTPUT.PUT_LINE('Traitement alimentation table export termine avec succes');

-- Si le traitement se deroule normalement, On effectue la validation des modifications
-- Les tables temporaires et d'export resteront chargees uniquement si le traitement plante en generation du fichier plat
COMMIT;


EXCEPTION
WHEN NO_DATA_FOUND THEN
	DBMS_OUTPUT.PUT_LINE('Curseur_ZonesParCompte vide : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));

WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Etape ' || v_step || ': erreur alimentation table TA_RN_EXPORT : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
  RAISE PARAM_GESTION_IMPOSSIBLE;

END;

/* *************************************************/
/* FIN Alimentation de la table d'export		   */
/* *************************************************/

/* ******************************** */
/* DEBUT Ecriture fichier de sortie */
/* ******************************** */
BEGIN
v_step := 40;
FOR Enreg_EXPORT_GESTION IN Curseur_EXPORT_GESTION 
LOOP
  	-- Prise en compte des montants dans Accurate :
  	-- 		 ENC --> Reception --> Debit
  	-- 		 DEC --> Paiement  --> Credit
  	-- Inversion en cas d'annulation ou de generation des ecritures d'extourne

    Var_RECPT := '0';
 	Var_PAYMT := '0';

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

	s_Ligne :=  Enreg_EXPORT_GESTION.ACCNUM||SEPARATEUR_FLUX_SORTIE||
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
	
	INSERT INTO TW_EXPORT_GEST (valeur)
      SELECT s_Ligne FROM DUAL;

END LOOP;

COMMIT;

EXCEPTION
WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('Procedure PR_RN_IMPORT_GEST etape '|| v_step ||': Erreur de transfert en TW_EXPORT_GEST '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
	RAISE PB_TW_EXPORT_GEST;
END;

/* ************************************************** */
/* FIN Transfert TA_RN_EXPORT --> TW_EXPORT_GEST      */
/* ********************************************** *** */

/* *********************************************************** */
/* DEBUT Generation du CLOB ExtraitReglement.txt               */
/* *********************************************************** */
BEGIN
  v_step := 50;
	s_ReqPurgeClob := 'DELETE FROM TA_CLOB WHERE ID_DEC = ''431-GEST''';
	EXECUTE IMMEDIATE s_ReqPurgeClob;
	COMMIT;
	
  v_step := 55;
	IF PKG_TEC_FICHIERS.F_ECRIRECSV_CLOB_SILENTLY(t_InfoTrait_GST,
                                         s_ID_FIC_GST,
                                         1,
                                         'SELECT valeur FROM TW_EXPORT_GEST ORDER BY pos',
                                         s_NomFic_GST || TO_CHAR(sysdate, 'yymmddhhmiss'),
                                         SEPARATEUR_FLUX_SORTIE,
                                         'OUT_APPLI') = -1 THEN RAISE PB_GENERATION_CLOB_GST;
  END IF;
  COMMIT;

  EXECUTE IMMEDIATE ('TRUNCATE TABLE TW_EXPORT_GEST');

EXCEPTION
  WHEN OTHERS THEN
    EXECUTE IMMEDIATE ('TRUNCATE TABLE TW_EXPORT_GEST');
	DBMS_OUTPUT.PUT_LINE('Procedure PR_RN_IMPORT_GEST etape '|| v_step || ': Erreur lors de la generation du clob ExtraitReglement.txt en TA_CLOB '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
    RAISE PB_GENERATION_CLOB_GST;
END;

/* ************************************************************************ */
/* DEBUT Vidage des tables temporaires TA_RN_IMPORT_GESTION et TA_RN_EXPORT */
/* ************************************************************************ */
BEGIN
v_step := 60;

DBMS_OUTPUT.PUT_LINE('Vidage de la table temporaire TA_RN_EXPORT');

DELETE FROM TA_RN_EXPORT WHERE TA_RN_EXPORT.SOURCE = 'GEST' AND ID_CHARGEMENT=Var_ID_CHARGEMENT_GESTION;
DBMS_OUTPUT.PUT_LINE('Nombre de lignes TA_RN_EXPORT supprimees = '||TO_CHAR(SQL%ROWCOUNT));

COMMIT;

EXCEPTION
WHEN NO_DATA_FOUND THEN
	DBMS_OUTPUT.PUT_LINE('Pas de donnees a supprimer : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));

WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Etape '|| v_step ||': erreur lors de la suppression des donnees dans TA_RN_EXPORT : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
  RAISE SUPPRESSION_IMPOSSIBLE;

END;

/* ************************************************ */
/* FIN Vidage de la table temporaire TA_RN_EXPORT   */
/* ************************************************ */

/* ************************************************* */
/*      DEBUT Alimentation de la table d'export		 */
/*      pour l'extraction comptabilite-gestion		 */
/* 		 			  	 		 		   			 */
/* Pour chaque Societe,devise,type de reglement,	 */
/* 	  		   Mode de reglement,compte accurate	 */
/* 	  		- liste des champs pour insert			 */
/* 	  		- liste des valeurs pour insert			 */
/* ************************************************* */
BEGIN

v_step := 70;
ListeChampsExport :='ID_CHARGEMENT,';
ListeValeursImport := ''||Var_ID_CHARGEMENT_GESTION||',';

OPEN CurseurC_ZonesParCompte;

FETCH CurseurC_ZonesParCompte
 INTO
	VarCurs_ID_COMPTE_BANC_SYST,
	VarCurs_NUMERO,
	VarCurs_RIB_DEPOSITAIRE,
	VarCurs_RIBBANKCODE,
	VarCurs_RIBBRANCHCODE,
	VarCurs_RIBIDENTIFICATION,
	VarCurs_RIBCHECKDIGIT,
	VarCurs_GENERATIONCONTREPARTIE,
	VarCurs_NUM_COMPTE_ACCURATE,
	VarCurs_NOM_CHAMP,
	VarCurs_NOM_BALISE;

Var_Ref_ID_COMPTE_BANC_SYST := VarCurs_ID_COMPTE_BANC_SYST;
Var_Ref_NUMERO := VarCurs_NUMERO;
Var_Ref_RIB_DEPOSITAIRE:=VarCurs_RIB_DEPOSITAIRE;
Var_Ref_RIBBANKCODE:=VarCurs_RIBBANKCODE;
Var_Ref_RIBBRANCHCODE:=VarCurs_RIBBRANCHCODE;
Var_Ref_RIBIDENTIFICATION:=VarCurs_RIBIDENTIFICATION;
Var_Ref_RIBCHECKDIGIT:=VarCurs_RIBCHECKDIGIT;
Var_Ref_GENERATIONCONTREPARTIE:=VarCurs_GENERATIONCONTREPARTIE;
Var_Ref_NUM_COMPTE_ACCURATE := VarCurs_NUM_COMPTE_ACCURATE;
Var_Ref_NOM_CHAMP := VarCurs_NOM_CHAMP;
Var_Ref_NOM_BALISE := VarCurs_NOM_BALISE;

-- Tant que pas fin fichier --
WHILE ( NOT CurseurC_ZonesParCompte%NOTFOUND )
LOOP
	-- Tant que pas fin fichier et meme societe-devise-mode reglement-RIB Depositaire --
	WHILE (
		Var_Ref_RIBBANKCODE=VarCurs_RIBBANKCODE
		AND Var_Ref_RIBBRANCHCODE=VarCurs_RIBBRANCHCODE
		AND Var_Ref_RIBIDENTIFICATION=VarCurs_RIBIDENTIFICATION
		AND Var_Ref_RIBCHECKDIGIT=VarCurs_RIBCHECKDIGIT
		AND NOT CurseurC_ZonesParCompte%NOTFOUND )
	LOOP
		-- Tant que pas fin fichier et meme societe-devise-mode reglement-RIB depositaire-type de reglement-compte accurate --
		WHILE (
			Var_Ref_RIBBANKCODE=VarCurs_RIBBANKCODE
			AND Var_Ref_RIBBRANCHCODE=VarCurs_RIBBRANCHCODE
			AND Var_Ref_RIBIDENTIFICATION=VarCurs_RIBIDENTIFICATION
			AND Var_Ref_RIBCHECKDIGIT=VarCurs_RIBCHECKDIGIT
			AND Var_Ref_NUM_COMPTE_ACCURATE=VarCurs_NUM_COMPTE_ACCURATE
			AND NOT CurseurC_ZonesParCompte%NOTFOUND )
		LOOP
			ListeChampsExport := ListeChampsExport||VarCurs_NOM_CHAMP||',';

			-- Transcodification du nom de societe et du libelle mode de reglement --
			-- Reporte dans la requete d'extraction sur la table TA_RN_SOCIETE --
			ListeValeursImport := ListeValeursImport||VarCurs_NOM_BALISE||',';
								 
			FETCH CurseurC_ZonesParCompte INTO
			 VarCurs_ID_COMPTE_BANC_SYST,
			 VarCurs_NUMERO,
			 VarCurs_RIB_DEPOSITAIRE,
			 VarCurs_RIBBANKCODE,
			 VarCurs_RIBBRANCHCODE,
			 VarCurs_RIBIDENTIFICATION,
			 VarCurs_RIBCHECKDIGIT,
			 VarCurs_GENERATIONCONTREPARTIE,
			 VarCurs_NUM_COMPTE_ACCURATE,
			 VarCurs_NOM_CHAMP,
			 VarCurs_NOM_BALISE;

		-- Tant que pas fin fichier et meme societe-devise-mode reglement-RIB depositaire-type de reglement-compte accurate --
		END LOOP;

		-- Enregistrement ListeChampsImport et ListeValeursImport dans la table pour la cle correspondante
		-- Cle = societe + devise + mode de reglement + RIB depositaire + type reglement + compte accurate
		ListeChampsExport := SUBSTR(ListeChampsExport,1,LENGTH(ListeChampsExport) - 1);
		ListeValeursImport := SUBSTR(ListeValeursImport,1,LENGTH(ListeValeursImport) - 1);
		  
		-- Generation du detail des ecritures pour les modes de reglement non cumules --
		BEGIN
			v_step := 72;
			EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT (SOURCE,ACCNUM,'||ListeChampsExport||')'
								  ||' ('
								  ||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport||' FROM TA_RN_IMPORT_GESTION WHERE '
								  ||' NOT IDENTIFICATION IN (SELECT CODE FROM TA_RN_SOCIETE,TA_RN_EXCLUSION_SOCIETE WHERE TA_RN_SOCIETE.ID_SOCIETE=TA_RN_EXCLUSION_SOCIETE.ID_SOCIETE AND TA_RN_EXCLUSION_SOCIETE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'					  		 
								  ||' AND NOT OPERATIONNETAMOUNTCURRENCY IN (SELECT CODE_ISO_DEVISE FROM TA_RN_DEVISE,TA_RN_EXCLUSION_DEVISE WHERE TA_RN_DEVISE.ID_DEVISE=TA_RN_EXCLUSION_DEVISE.ID_DEVISE AND TA_RN_EXCLUSION_DEVISE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND NOT SETTLEMENTMODE IN (SELECT CODE_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT,TA_RN_EXCLUSION_MR WHERE TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT=TA_RN_EXCLUSION_MR.ID_MODE_REGLEMENT AND TA_RN_EXCLUSION_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND NOT TYPEREGLEMENT IN (SELECT TYPE_REGLEMENT FROM TA_RN_EXCLUSION_TR WHERE TA_RN_EXCLUSION_TR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND (NOT EXISTS (SELECT 1 FROM TA_RN_MODE_REGLEMENT,TA_RN_CUMUL_MR, TA_RN_PRODUIT'
								  ||' WHERE TA_RN_CUMUL_MR.ID_MODE_REGLEMENT=TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT'
								  ||' AND TA_RN_CUMUL_MR.ID_PRODUIT=TA_RN_PRODUIT.ID_PRODUIT'
								  ||' AND TA_RN_CUMUL_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST
								  ||' AND (TA_RN_PRODUIT.CODE_PRODUIT=NUMEROCLIENT OR TA_RN_PRODUIT.CODE_PRODUIT=''ALL'')'
								  ||' AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=SETTLEMENTMODE OR TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=''ALL'')'
								  ||')'
								  ||'  OR (SETTLEMENTMODE IN ('||''''||'VO'||''''||','||''''||'PC'||''''||','||''''||'PQ'||''''||','||''''||'PM'||''''||') AND STATUTREGLEMENT = '||''''||'ANNULE'||''''||')'
								  ||')'	
								  ||' AND IDENTIFICATIONRIB = '||''''||Var_Ref_RIBIDENTIFICATION||''''
								  ||' AND RIBCHECKDIGIT = '||''''||Var_Ref_RIBCHECKDIGIT||''''
								  ||' AND BANKCODE = '||''''||Var_Ref_RIBBANKCODE||''''
								  ||' AND BRANCHCODE = '||''''||Var_Ref_RIBBRANCHCODE||''''
								  ||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
								  ||')';
		EXCEPTION   
			WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('Pas de detail');

			WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('Etape '|| v_step ||': erreur insertion dans TA_RN_EXPORT : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
			RAISE PB_INSERT_TA_RN_EXPORT;
		END; 
		-- Fin generation du detail des ecritures pour les modes de reglement non cumules --
		
		-- Generation du cumul des ecritures pour les modes de reglement cumules --
		BEGIN
			v_step := 74;
        	EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT (SOURCE,ACCNUM,'||ListeChampsExport||')'
								  ||' ('
								  ||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport
								  ||' FROM '
								  ||' (SELECT DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,'
								  ||''''||''''||' AS PAYMENTREFERENCE,'||''''||''''||' AS POLICYREFERENCE,'||''''||''''||' AS NUMEROCLIENT,'||''''||''''||' AS NOMCLIENT,'
								  ||'SETTLEMENTMODE,BANKCODE,BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,'||''''||''''||' AS VALUEDATE,TRADEDATE,'
								  ||' SUM(TO_NUMBER(OPERATIONNETAMOUNT)) AS OPERATIONNETAMOUNT,OPERATIONNETAMOUNTCURRENCY,'||''''||''''||' AS BENEFICIARYNAME,'
								  ||''''||''''||' AS BENEFICIARYFIRST,'||''''||''''||' AS BENEFICIARYREFERENCE,'||''''||''''||' AS PRESENTMENTREFERENCE,'||''''||''''||' AS CHEQUEREFERENCE,'
								  ||''''||''''||' AS DEPOSITSLIPREFERENCE,'||''''||''''||' AS CREDITSLIPREFERENCE,'||''''||'Ecriture cumul quotidien'||''''||' AS COMMENTAIRE,'
								  ||''''||''''||' AS CREATIONDATE,'||''''||''''||' AS RIBCOMPLET,'||'ID_CHARGEMENT_GESTION, DATECOMPTAORIG FROM TA_RN_IMPORT_GESTION '   -- V1.2
								  ||'WHERE NOT IDENTIFICATION IN (SELECT CODE FROM TA_RN_SOCIETE,TA_RN_EXCLUSION_SOCIETE WHERE TA_RN_SOCIETE.ID_SOCIETE=TA_RN_EXCLUSION_SOCIETE.ID_SOCIETE AND TA_RN_EXCLUSION_SOCIETE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'					  		 
								  ||' AND NOT OPERATIONNETAMOUNTCURRENCY IN (SELECT CODE_ISO_DEVISE FROM TA_RN_DEVISE,TA_RN_EXCLUSION_DEVISE WHERE TA_RN_DEVISE.ID_DEVISE=TA_RN_EXCLUSION_DEVISE.ID_DEVISE AND TA_RN_EXCLUSION_DEVISE.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND NOT SETTLEMENTMODE IN (SELECT CODE_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT,TA_RN_EXCLUSION_MR WHERE TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT=TA_RN_EXCLUSION_MR.ID_MODE_REGLEMENT AND TA_RN_EXCLUSION_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND NOT TYPEREGLEMENT IN (SELECT TYPE_REGLEMENT FROM TA_RN_EXCLUSION_TR WHERE TA_RN_EXCLUSION_TR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST||')'
								  ||' AND EXISTS (SELECT 1 FROM TA_RN_MODE_REGLEMENT,TA_RN_CUMUL_MR, TA_RN_PRODUIT'
								  ||' WHERE TA_RN_CUMUL_MR.ID_MODE_REGLEMENT=TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT'
								  ||' AND TA_RN_CUMUL_MR.ID_PRODUIT=TA_RN_PRODUIT.ID_PRODUIT'
								  ||' AND TA_RN_CUMUL_MR.ID_COMPTE_BANCAIRE_SYSTEME='||Var_Ref_ID_COMPTE_BANC_SYST
								  ||' AND (TA_RN_PRODUIT.CODE_PRODUIT=NUMEROCLIENT OR TA_RN_PRODUIT.CODE_PRODUIT=''ALL'')'
								  ||' AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=SETTLEMENTMODE OR TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=''ALL'')'
								  ||')'
								  ||' AND NOT (SETTLEMENTMODE IN ('||''''||'VO'||''''||','||''''||'PC'||''''||','||''''||'PQ'||''''||','||''''||'PM'||''''||') AND STATUTREGLEMENT = '||''''||'ANNULE'||''''||')'
								  ||' AND IDENTIFICATIONRIB = '||''''||Var_Ref_RIBIDENTIFICATION||''''
								  ||' AND RIBCHECKDIGIT = '||''''||Var_Ref_RIBCHECKDIGIT||''''
								  ||' AND BANKCODE = '||''''||Var_Ref_RIBBANKCODE||''''
								  ||' AND BRANCHCODE = '||''''||Var_Ref_RIBBRANCHCODE||''''
								  ||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
								  ||' GROUP BY DATECREATION,FROMDATETIME,TODATETIME,TYPEREGLEMENT,STATUTREGLEMENT,IDENTIFICATION,ISSUER,SCHEME,SETTLEMENTMODE,BANKCODE,'
								  ||'BRANCHCODE,IDENTIFICATIONRIB,RIBCHECKDIGIT,TRADEDATE,OPERATIONNETAMOUNTCURRENCY,ID_CHARGEMENT_GESTION, DATECOMPTAORIG)'   -- V1.2
								  ||')';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('Pas de cumul');

			WHEN OTHERS THEN
			DBMS_OUTPUT.PUT_LINE('Etape '|| v_step || ': erreur insertion dans TA_RN_EXPORT : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
			RAISE PB_INSERT_TA_RN_EXPORT;
		END;
		-- Fin Generation du cumul des ecritures pour les modes de reglement cumules --

		ListeChampsExport :='ID_CHARGEMENT,';
		ListeValeursImport := ''||Var_ID_CHARGEMENT_GESTION||',';

		Var_Ref_NUM_COMPTE_ACCURATE := VarCurs_NUM_COMPTE_ACCURATE;
		Var_Ref_GENERATIONCONTREPARTIE:=VarCurs_GENERATIONCONTREPARTIE;

	-- Tant que pas fin fichier et meme societe-devise-mode reglement-RIB Depositaire --
    END LOOP;

	Var_Ref_NUMERO := VarCurs_NUMERO;
	Var_Ref_RIB_DEPOSITAIRE:=VarCurs_RIB_DEPOSITAIRE;
	Var_Ref_RIBBANKCODE:=VarCurs_RIBBANKCODE;
	Var_Ref_RIBBRANCHCODE:=VarCurs_RIBBRANCHCODE;
	Var_Ref_RIBIDENTIFICATION:=VarCurs_RIBIDENTIFICATION;
	Var_Ref_RIBCHECKDIGIT:=VarCurs_RIBCHECKDIGIT;
	Var_Ref_ID_COMPTE_BANC_SYST := VarCurs_ID_COMPTE_BANC_SYST;
END LOOP;

CLOSE CurseurC_ZonesParCompte;

DBMS_OUTPUT.PUT_LINE('Etape '|| v_step || ': alimentation table TA_RN_EXPORT pour RapCtl termine avec succes');

-- Si le traitement se deroule normalement, On effectue la validation des modifications
-- Les tables temporaires et d'export resteront chargees uniquement si le traitement plante en generation du fichier plat
COMMIT;

EXCEPTION
WHEN NO_DATA_FOUND THEN
	DBMS_OUTPUT.PUT_LINE('Curseur_ZonesParCompte vide : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));

WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Etape '|| v_step ||': erreur alimentation table TA_RN_EXPORT pour RapCtl : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
  RAISE PARAM_GESTION_IMPOSSIBLE;

END;

/* *************************************************/
/* FIN Alimentation de la table d'export		   */
/* *************************************************/

/* ******************************** */
/* DEBUT Ecriture fichier de sortie */
/* ******************************** */
BEGIN
v_step := 80;
FOR Enreg_EXPORT_GESTION IN Curseur_EXPORT_GESTION LOOP
  	-- Prise en compte des montants dans Accurate :
  	-- 		 ENC --> Reception --> Debit
  	-- 		 DEC --> Paiement  --> Credit
  	-- Inversion en cas d'annulation ou de generation des ecritures d'extourne

    Var_RECPT:='0';
 	Var_PAYMT:='0';

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
	
	s_Ligne :=	Enreg_EXPORT_GESTION.ACCNUM||SEPARATEUR_FLUX_SORTIE||
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
				
	INSERT INTO TW_EXPORT_GEST (valeur)
      SELECT s_Ligne FROM DUAL;			

END LOOP;

EXCEPTION
WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE('Procedure PR_RN_IMPORT_GEST etape '|| v_step || ': Erreur de transfert RapCtl en TW_EXPORT_GEST '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
	RAISE PB_TW_EXPORT_GEST;
END;

/* ************************************************** */
/* FIN Transfert TA_RN_EXPORT --> TW_EXPORT_GEST      */
/* ********************************************** *** */

/* *********************************************************** */
/* DEBUT Generation du CLOB ExtraitReglement_RapCtl.txt        */
/* *********************************************************** */
BEGIN
  v_step := 90;
	s_ReqPurgeClob := 'DELETE FROM TA_CLOB WHERE ID_DEC = ''432-GDT''';
	EXECUTE IMMEDIATE s_ReqPurgeClob;
	COMMIT;
	
  v_step := 95;
	IF PKG_TEC_FICHIERS.F_ECRIRECSV_CLOB_SILENTLY(t_InfoTrait_GDT,
                                         s_ID_FIC_GDT,
                                         1,
                                         'SELECT valeur FROM TW_EXPORT_GEST ORDER BY pos',
                                         s_NomFic_GDT || TO_CHAR(sysdate, 'yymmddhhmiss'),
                                         SEPARATEUR_FLUX_SORTIE,
                                         'OUT_APPLI') = -1 THEN RAISE PB_GENERATION_CLOB_GDT;
  END IF;
  COMMIT;

  EXECUTE IMMEDIATE ('TRUNCATE TABLE TW_EXPORT_GEST');

EXCEPTION
  WHEN OTHERS THEN
    EXECUTE IMMEDIATE ('TRUNCATE TABLE TW_EXPORT_GEST');
	DBMS_OUTPUT.PUT_LINE('Procedure PR_RN_IMPORT_GEST etape '|| v_step || ': Erreur lors de la generation du clob ExtraitReglement_RapCtl.txt en TA_CLOB '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
    RAISE PB_GENERATION_CLOB_GDT;
END;

/* ****************************** */
/* FIN Ecriture fichier de sortie */
/* ****************************** */

/* ************************************************************************ */
/* DEBUT Vidage des tables temporaires TA_RN_IMPORT_GESTION et TA_RN_EXPORT */
/* ************************************************************************ */
BEGIN
v_step := 100;

DELETE FROM TA_RN_EXPORT WHERE TA_RN_EXPORT.SOURCE = 'GEST' AND ID_CHARGEMENT=Var_ID_CHARGEMENT_GESTION;
DBMS_OUTPUT.PUT_LINE('Lignes TA_RN_EXPORT supprimees = '||TO_CHAR(SQL%ROWCOUNT));

DELETE FROM TA_RN_IMPORT_GESTION WHERE ID_CHARGEMENT_GESTION=Var_ID_CHARGEMENT_GESTION;
DBMS_OUTPUT.PUT_LINE('Lignes TA_RN_IMPORT_GESTION supprimees = '||TO_CHAR(SQL%ROWCOUNT));

COMMIT;

EXCEPTION

WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Etape ' || v_step || ': erreur lors de la suppression de donnees dans TA_RN_IMPORT_GESTION et TA_RN_EXPORT : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
  RAISE SUPPRESSION_IMPOSSIBLE;
END;

/* ********************************************************************** */
/* FIN Vidage des tables temporaires TA_RN_IMPORT_GESTION et TA_RN_EXPORT */
/* ********************************************************************** */

/* **************************** */
/* GLOBAL exception block       */
/* **************************** */
EXCEPTION

WHEN PB_LECTURE_TX_REGLT_GEST THEN
 DBMS_OUTPUT.PUT_LINE('Erreur lecture donnees XML TX_REGLT_GEST');
 raise_application_error('-20001','Procedure PR_RN_IMPORT_GESTION: Erreur lecture donnees TX_REGLT_GEST');

WHEN SUPPRESSION_IMPOSSIBLE THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Erreur critique lors de la suppression de donnees dans TA_RN_IMPORT_GESTION et TA_RN_EXPORT');
 raise_application_error('-20002','Erreur critique lors de la suppression de donnees dans TA_RN_IMPORT_GESTION et TA_RN_EXPORT');

WHEN PARAM_GESTION_IMPOSSIBLE THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Erreur critique en alimentation table gestion_accurate');
 raise_application_error('-20003','Erreur critique en alimentation table gestion_accurate');

WHEN PB_INSERT_TA_RN_IMP_GEST THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Probleme insertion TA_RN_IMPORT_GESTION');
 raise_application_error('-20004','Erreur critique en insertion table TA_RN_IMPORT_GESTION');

WHEN PB_INSERT_TA_RN_EXPORT THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Probleme insertion TA_RN_EXPORT');
 raise_application_error('-20005','Erreur critique lors de l''insertion dans la table TA_RN_EXPORT');
 
WHEN PB_TW_EXPORT_GEST THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('*** Probleme alimentation TW_EXPORT_GEST');
 raise_application_error('-20006', 'Probleme d''alimentation de la table TW_EXPORT_GEST');
 
WHEN PB_GENERATION_CLOB_GST THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('*** Probleme generation CLOB ExtraitReglement');
 raise_application_error('-20007', 'Probleme de generation du CLOB ExtraitReglement');
 
WHEN PB_GENERATION_CLOB_GDT THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('*** Probleme generation CLOB ExtraitReglement');
 raise_application_error('-20008', 'Probleme de generation du CLOB ExtraitReglement_RapCtl');

WHEN PB_ID_CHARGEMENT THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Probleme lors de la generation ID_CHARGEMENT');
 raise_application_error('-20009','Erreur critique lors de la generation ID_CHARGEMENT');

WHEN PB_RECHERCHE_LIBELLE THEN
 ROLLBACK;
 DBMS_OUTPUT.PUT_LINE('Probleme transcodage societe / mode de reglement');
 raise_application_error('-20010','Erreur critique en recherche societe / mode de reglement');
 
WHEN OTHERS THEN
    ROLLBACK;
	DBMS_OUTPUT.PUT_LINE('Erreur : '||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
	raise_application_error('-20099','Erreur critique dans la procedure Procedure PR_RN_IMPORT_GESTION'||TO_CHAR(SQLCODE)||' '||SQLERRM(SQLCODE));
END;
/
