create or replace PACKAGE BODY             "PKG_RNADEXTAUTO01"
AS

-- ***********************************************************************
-- # PACKAGE      : PKG_RNADEXTAUTO01
-- # DESCRIPTION  :
-- #
-- # MODIFICATIONS :
-- # ---------------------------------------------------------------------
-- # Version | Date       | RÃ©fÃ©rence | Auteur | Specification
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.0     | 24/05/2007 |           | MMA    | Creation
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.1     | 01/09/2007 |              | ECO    | alimentation du fichier .info
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.2     | 30/10/2007 |           | MMA    | Ajout de la colonne DC Max
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.3     | 30/10/2007 |           | MMA    | Ajout de la partie "Base des Attendus en date comptable"
-- #                                           | Nouveau curseur Curseur_Attendus_DC_Max
-- #                                           | Nouveau paramÃ¿tre s_TypeDate Ã  l'utilisateur permettant de choisir
-- #                                           | l'extraction avec la date de rapprochement physique comme critÃ¿re
-- #                                           | ou la date comptable maximum du groupe de rapprochement
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.4     | 27/11/2007 |              | MMA    | Avenant sur le delta
-- #                                           | Pour un groupe de prelettrage, le delta est renseignÃ© uniquement
-- #                                           | pour l'id le plus petit et le plus ancien
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.5     | 20/07/2009 |              | RTI    | Mise en conformitÃ© EVSIF remplacement UTL_FILE par CLOB
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.5     | 26/11/2009 |           | NVE    | Suppression du contrÃ¿le sur le type de rappro et gÃ©nÃ©ration d'un fichier vide sans planter la chaÃ®ne dans ce cas
-- # ------- | ---------- | --------- | ------ | -------------------------
-- # 1.7     | 10/02/2014 |           | RPZ    | Type de rapprochement seulement 'Rappro Bancaire' (RB) ou Rappro de ContrÃ¿le (RC)
-- #                                           | Return un erreur fonctionnelle dans F_CONTROLE_DTC_FORMAT.
-- ***********************************************************************

-- =======================================================================
-- DECLARATION DES CONSTANTES
-- =======================================================================

-- Nom du package
gs_PACKAGE CONSTANT VARCHAR2(25):='PKG_RNADEXTAUTO01';

-- Retour chariot version windows
CRLF VARCHAR2(2) := CHR(13)||CHR(10);

-- erreur general
gn_CR_ERREUR                  NUMBER := 1;
-- erreur fonctionnelle
gn_CR_ERREUR_FONCT            NUMBER := 204; --RPZ - 17/02/2014 - FMCP-3664

-- =======================================================================
-- DECLARATION DES VARIABLES GLOBALES
-- =======================================================================

-- Informations sur le traitement en cours
gt_InfoTrait PKG_GLOBAL.T_INFO_TRAITEMENT;

/******************************************************************************
   NOM        : F_CONTROLE_DTC_FORMAT
   OBJET      : ContrÃ¿le du format des donnÃ©es DTC
   PARAMETRES : s_DateArrete                     -> Date d'arrÃªtÃ©
           s_TypeRapro                      -> Type de rapprochement
                s_TypeDate                                -> Type de date : date de rapprochement physique (P) ou
                                                                            date comptable max du groupe de rapprochement (C)

   VERSIONS:
   Ver        Date        Auteur           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        24/05/2007                   1. Creation
   ---------  ----------  ---------------  ------------------------------------
   1.3        30/10/2007  MMA              Ajout du contrÃ¿le sur le paramÃ¿tre s_TypeDate saisi
                                           Nouveau paramÃ¿tre s_TypeDate Ã  l'utilisateur permettant de choisir
                                           l'extraction avec la date de rapprochement physique 'P' comme critÃ¿re
                                           ou la date comptable maximum du groupe de rapprochement  'C'
   ---------  ----------  ---------------  ------------------------------------
   1.7        17/02/2014  RPZ              Type de rapprochement seulement 'Rappro Bancaire' (RB) ou Rappro de ContrÃ¿le (RC)
                                           Return un erreur fonctionnelle dans F_CONTROLE_DTC_FORMAT.
******************************************************************************/
FUNCTION F_CONTROLE_DTC_FORMAT(s_DateArrete VARCHAR2,s_TypeRapro VARCHAR2, s_TypeDate VARCHAR2) RETURN NUMBER IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------
    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_CONTROLE_DTC_FORMAT';


    n_Jour        NUMBER:=0;
    n_Mois        NUMBER:=0;
    n_Annee       NUMBER:=0;


    ERREUR             EXCEPTION;


 BEGIN

 -- Insertion donnÃ©es brutes dans table temporaire
  PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Controle du format des donnÃ©es DTC.', 0, s_FONCTION);

--  La date d'arrÃªtÃ© doit comporter 10 caractÃ¿res (format dd/mm/rrrr)
    IF LENGTH(TRIM(s_DateArrete)) != 10 THEN
          PKG_LOG.P_ECRIRE(gt_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, '(Ecran DTC) Format de la date incorrect ! :'||s_DateArrete, 0, s_Fonction);
             RAISE ERREUR;
    END IF;

--  Le jour de la date d'arrÃªtÃ© doit Ãªtre numÃ©rique
    BEGIN
         n_Jour       :=TO_NUMBER(NVL(substr(s_DateArrete,1,2),0));
        EXCEPTION
    WHEN VALUE_ERROR THEN
    PKG_LOG.P_ECRIRE(gt_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, '(Ecran DTC) Jour incorrect (non numÃ©rique) ! :'||s_DateArrete, 0, s_Fonction);
             RAISE ERREUR;
    END;

--  Le mois de la date d'arrÃªtÃ© doit Ãªtre numÃ©rique
    BEGIN
         n_Mois       :=TO_NUMBER(NVL(substr(s_DateArrete,4,2),0));
        EXCEPTION
    WHEN VALUE_ERROR THEN
    PKG_LOG.P_ECRIRE(gt_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, '(Ecran DTC) Mois incorrect (non numÃ©rique) ! :'||s_DateArrete, 0, s_Fonction);
             RAISE ERREUR;
    END;

--  L'annÃ©e de la date d'arrÃªtÃ© doit Ãªtre numÃ©rique
    BEGIN
         n_Annee       :=TO_NUMBER(NVL(substr(s_DateArrete,7,4),0));
        EXCEPTION
    WHEN VALUE_ERROR THEN
    PKG_LOG.P_ECRIRE(gt_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, '(Ecran DTC) AnnÃ©e incorrecte (non numÃ©rique) ! :'||s_DateArrete, 0, s_Fonction);
             RAISE ERREUR;
    END;

--  Le type de rapprochement doit Ãªtre soit RB ou RC
    IF s_TypeRapro NOT IN ('RB', 'RC') THEN --RPZ - 10/02/2014 - FMCP-3664
         PKG_LOG.P_ECRIRE(gt_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, '(Ecran DTC) Type de rapprochement incorrect ! :'||s_TypeRapro, 0, s_Fonction);
             RAISE ERREUR;
    END IF;

--  Le type de date choisi doit Ãªtre soit J (date de rapprochement en date du jour) soit D (date comptable max du groupe de rapprochement)
--  V1.3
    IF s_TypeDate NOT IN ('P', 'C') THEN
         PKG_LOG.P_ECRIRE(gt_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, '(Ecran DTC) Type de date incorrect ! :'||s_TypeDate, 0, s_Fonction);
             RAISE ERREUR;
    END IF;

    COMMIT;

    RETURN PKG_GLOBAL.gn_CR_OK;

  EXCEPTION
  WHEN ERREUR THEN
      RETURN gn_CR_ERREUR_FONCT; --RPZ - 17/02/2014 - FMCP-3664
  WHEN OTHERS THEN
    PKG_LOG.P_ECRIRE(gt_InfoTrait);
    RETURN PKG_GLOBAL.gn_CR_KO;

END F_CONTROLE_DTC_FORMAT;


/******************************************************************************
   NOM        :       F_CONTROLE_DTC
   OBJET      : Point d'entrÃ©e du package
   PARAMETRES : s_DateArrete                     -> Date d'arrÃªtÃ©
           s_TypeRapro                      -> Type de rapprochement
                s_TypeDate                                -> Type de date : date de rapprochement physique (P) ou
                                                                            date comptable max du groupe de rapprochement (C)
                                                             Ajout du paramÃ¿tre en entrÃ©e, mais pas de contrÃ¿le
   VERSIONS:
   Ver        Date        Auteur           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        06/06/2007   MMA             1. Creation
******************************************************************************/
FUNCTION F_CONTROLE_DTC(s_DateArrete VARCHAR2,s_TypeRapro VARCHAR2, s_TypeDate VARCHAR2) RETURN NUMBER IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------
    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_CONTROLE_DTC';

    ERREUR             EXCEPTION;
    n_Annee       NUMBER:=0;

 BEGIN

 -- Insertion donnÃ©es brutes dans table temporaire
  PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Controle des donnÃ©es DTC.', 0, s_FONCTION);


--    ContrÃ¿le de  l'AnnÃ©e

    n_Annee       :=TO_NUMBER(NVL(substr(s_DateArrete,7,4),0));

        IF n_Annee < 1980 THEN
       PKG_LOG.P_ECRIRE(gt_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, '(Ecran DTC) Annee antÃ©rieure Ã  1980 ! :'||n_Annee, 0, s_Fonction);
          RAISE ERREUR;
    END IF;

    COMMIT;

    RETURN PKG_GLOBAL.gn_CR_OK;

  EXCEPTION
  WHEN ERREUR THEN
      RETURN gn_CR_ERREUR;
  WHEN OTHERS THEN
    PKG_LOG.P_ECRIRE(gt_InfoTrait);
    RETURN PKG_GLOBAL.gn_CR_KO;

END F_CONTROLE_DTC;

/******************************************************************************
   NOM        :       F_Extraire_BAATGS
   OBJET      : Cette fonction extrait les attendus pour la Gestion
   PARAMETRES : s_DateArrete                     -> Date d'arrêté
           s_TypeRapro                      -> Type de rapprochement
            nbr_enreg                      -> Nbr D'enregistrement extrait
            s_TypeDate                                -> Type de date : date de rapprochement physique (P) ou
                                                                            date comptable max du groupe de rapprochement (C)

   VERSIONS:
   Ver        Date        Auteur           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        05/06/2007   MMA              Creation
   ---------  ----------  ---------------  ------------------------------------
   1.2        30/10/2007   MMA              Ajout de la colonne DC Max
   ---------  ----------  ---------------  ------------------------------------
   1.3        30/10/2007   MMA              Ajout du contrôle sur le paramètre s_TypeDate saisi
                                            Nouveau paramètre s_TypeDate à l'utilisateur permettant de choisir
                                            l'extraction avec la date de rapprochement physique 'P' comme critère
                                              ou la date comptable maximum du groupe de rapprochement  'C'
   ---------  ----------  ---------------  ------------------------------------
   1.4        27/11/2007   MMA              Avenant sur le delta
                                            Pour un groupe de prelettrage, le delta est renseigné uniquement
                                            pour l'id le plus petit et le plus ancien
   ---------  ----------  ---------------  ------------------------------------
   1.5        20/06/2024                    Remplacement de la colonne RECORD_ID par le COMPTE_COMPTABLE


   NOTES: Retourne -1 si erreur, 0 sinon

******************************************************************************/
FUNCTION F_Extraire_BAATGS(s_DateArrete VARCHAR2,s_TypeRapro VARCHAR2, nbr_enreg out NUMBER, s_TypeDate VARCHAR2) RETURN NUMBER IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------
    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_Extraire_BAATGS';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------
/* ***************************/
/* Variables pour curseurs   */
/* ***************************/

Var_DATE_ARRETE                BA_ATTENDUS_GEST.DATE_ARRETE%Type        :='';
Var_TYPE_RAPRO                BA_ATTENDUS_GEST.TYPE_RAPRO%Type        :='';
Var_SERVICE                BA_ATTENDUS_GEST.SERVICE%Type           :='';
Var_SOCIETE                BA_ATTENDUS_GEST.SOCIETE%Type           :='';
Var_COMPTE_BANCAIRE            BA_ATTENDUS_GEST.COMPTE_BANCAIRE%Type   :='';
Var_LIBELLE_COMPTE            BA_ATTENDUS_GEST.LIBELLE_COMPTE%Type    :='';
Var_DEVISE                BA_ATTENDUS_GEST.DEVISE%Type            :='';
Var_DATE_OPERATION_SUSPENS        BA_ATTENDUS_GEST.DATE_OPERATION_SUSPENS%Type  :='';
Var_LIBELLE_SUSPENS            BA_ATTENDUS_GEST.LIBELLE_SUSPENS%Type   :='';
Var_DEBIT                BA_ATTENDUS_GEST.DEBIT%Type             :=0;
Var_CREDIT                BA_ATTENDUS_GEST.CREDIT%Type            :=0;
Var_SENS_ATTENDU            BA_ATTENDUS_GEST.SENS_ATTENDU%Type      :='';
Var_COTE_SUSPENS                        BA_ATTENDUS_GEST.COTE_SUSPENS%Type      :='';
Var_ANCIENNETE_J            BA_ATTENDUS_GEST.ANCIENNETE_J%Type      :=0;
Var_ANCIENNETE_M            BA_ATTENDUS_GEST.ANCIENNETE_M%Type      :=0;
Var_BORNE_ANCIENNETE            BA_ATTENDUS_GEST.BORNE_ANCIENNETE%Type  :='';
Var_PILIER_MONTANT_DEBIT        BA_ATTENDUS_GEST.PILIER_MONTANT_DEBIT%Type    :='';
Var_PILIER_MONTANT_CREDIT        BA_ATTENDUS_GEST.PILIER_MONTANT_CREDIT%Type   :='';
Var_METHODE_PROVISION            BA_ATTENDUS_GEST.METHODE_PROVISION%Type :='';
Var_TAUX                BA_ATTENDUS_GEST.TAUX%Type              :=0;
Var_MONTANT_PROVISION              BA_ATTENDUS_GEST.MONTANT_PROVISION%Type :=0;
Var_STATUT                BA_ATTENDUS_GEST.STATUT%Type            :='';
Var_DATE_APUREMENT            BA_ATTENDUS_GEST.DATE_APUREMENT%Type    :='';
Var_DC_MAX                BA_ATTENDUS_CPTA.DC_MAX%Type           :='';  --V1.2
Var_PRIORITE                       BA_ATTENDUS_GEST.PRIORITE%Type          :='';
Var_COMMENTAIRE                BA_ATTENDUS_GEST.COMMENTAIRE%Type       :='';
Var_NETTING                BA_ATTENDUS_GEST.NETTING%Type           :='';
Var_DELTA                BA_ATTENDUS_GEST.DELTA%Type           :='';
Var_SENS_DELTA                BA_ATTENDUS_GEST.SENS_DELTA%Type           :='';
Var_NUMERO_FICHE                    BA_ATTENDUS_GEST.NUMERO_FICHE%Type      :='';
Var_DERNIER_STATUT                  BA_ATTENDUS_GEST.DERNIER_STATUT%Type    :='';
Var_RECORD_ID                       BA_ATTENDUS_GEST.RECORD_ID%Type         :=0;
Var_RECORD_ID_MIN                   BA_ATTENDUS_GEST.RECORD_ID%Type         :=0;
Var_MONTANT_DIFF                        BA_ATTENDUS_GEST.CREDIT%Type               := 0;
Var_NUM_PRELETTRAGE                     BA_ATTENDUS_GEST.NETTING%Type           :='';
Var_DATE_PLUS_ANCIEN                BA_ATTENDUS_GEST.DATE_OPERATION_SUSPENS%Type  :='';
Var_TAUX_PLUS_ELEVE                     BA_ATTENDUS_GEST.TAUX%Type  :='';
Var_NB_PRELETTRE                        NUMBER :=0;
Var_ANNOTE_LE             BA_ATTENDUS_CPTA.ANNOTE_LE%TYPE :='';

/* *************************************************************** */
/*      Extraction des Attendus de la base Accurate             */
/*     avec date de rapprochement en date du jour           */
/*      Récupération des zones dans une table "temporaire"            */
/* *************************************************************** */
CURSOR Curseur_Attendus_D_Rapro IS
SELECT DISTINCT
           (select TO_CHAR(s_DateArrete) from dual) as DATE_ARRETE,
           (select decode(rpad(acct_num,length(acct_num)-2), 'RB', 'Rapprochement Bancaire',
                                                           'RC', 'Rapprochement de Contrôle',
                                                           'JC', 'Justification de compte',
                                                           'CL', 'Compte de liaison')
                    from BS_ACCTS BS_ACCTS2 where BS_ACCTS2.ACCT_ID = (select H.level_03_account_id
                                                                                       From   BRR_ACCOUNT_HIERARCHIES H
                                                                                       where H.account_id =BS_ACCTS.ACCT_ID)) as TYPE_RAPRO,
            (select B.ACCT_NUM from BS_ACCTS B where B.ACCT_ID = (select H.level_02_account_id
                                                        from BRR_ACCOUNT_HIERARCHIES H
                                                         where H.account_id = BS_ACCTS.ACCT_ID)) as SERVICE,
        (select acct_name from BS_ACCTS ACCTS2 where ACCTS2.acct_id = BS_ACCTS.acct_group) as SOCIETE,
        BA_CPME.compte_bancaire as COMPTE_BANCAIRE,
        BS_ACCTS.ACCT_NAME as LIBELLE_COMPTE,
        BS_ACCTS.ACCT_CURRENCY as DEVISE,
        TO_CHAR(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR') as DATE_OPERATION_SUSPENS,
        BRR_TRANSACTIONS.NARRATIVE as LIBELLE_SUSPENS,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT) as DEBIT,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'PAYMENTCASHBOOK', BRR_TRANSACTIONS.AMOUNT) as CREDIT,
        DECODE(BRR_TRANSACTIONS.NUMERIC_TWO, 0, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','ABD','PAYMENTSTATEMENT','ACC','RECEIPTCASHBOOK','ABC','RECEIPTSTATEMENT','ACD'), 'A'||BRR_TRANSACTIONS.FLAG_C||DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D')) as SENS_ATTENDU,
        --DECODE(nvl(instr(BRR_TRANSACTIONS.LAST_NOTE_TEXT, ';'),0),0, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','ABD','PAYMENTSTATEMENT','ACC','RECEIPTCASHBOOK','ABC','RECEIPTSTATEMENT','ACD'), 'A'||DECODE(SIGN(TRIM(SUBSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,1,INSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,';') - 1))-1000),1,'B', 0 , 'B', 'C')||DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D')) as SENS_ATTENDU,
        DECODE(BRR_TRANSACTIONS.SIDE,'STATEMENT', 'B','CASHBOOK', 'C') as COTE_SUSPENS,
        (select TO_DATE(s_DateArrete, 'DD/MM/RRRR') - TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR') from dual) as ANCIENNETE_J,
        (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) as ANCIENNETE_M,
        (select libelle_anciennete from BA_CATEG_ANCIENNETE BACA
         where (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) >= BACA.borne_inf
         and   (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) < BACA.borne_sup) as BORNE_ANCIENNETE,
            DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                      where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)
                                          ,'RECEIPTCASHBOOK', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                         where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)) as PILIER_MONTANT_DEBIT,
            DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                      where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)
                                               ,'PAYMENTCASHBOOK', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                             where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)) as PILIER_MONTANT_CREDIT,
            BA_CPME.methode as METHODE_PROVISION,
            (select taux from BA_METHODE_PROVISION MEPR
                 where methode = (select methode from BA_COMPTE_METHODE CPME where CPME.ACCOUNT_ID = BS_ACCTS.acct_id)
                 and (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'),
                                    TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) >= MEPR.borne_inf
                 and (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'),
                                    TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) < MEPR.borne_sup) as TAUX,
        0 as MONTANT_PROVISION,
        BRR_TRANSACTIONS.STATE as STATUT,
        null as DATE_APUREMENT,
        null as DC_MAX,  --V1.2
        SUBSTR(BRR_TRANSACTIONS.CHARACTER_SIXTEEN, 1,5) as PRIORITE , -- JOB Ajout 27/11/2025    '' as PRIORITE,
        BRR_TRANSACTIONS.LAST_NOTE_TEXT as COMMENTAIRE,
        --TRIM(SUBSTR(LAST_NOTE_TEXT,1,INSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,';') - 1)) as NETTING,
           BRR_TRANSACTIONS.NUMERIC_TWO as NETTING,
         DECODE(DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT), null, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'PAYMENTCASHBOOK', BRR_TRANSACTIONS.AMOUNT), DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT)) as DELTA,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D') as SENS_DELTA,
        '' as NUMERO_FICHE,
        '' as DERNIER_STATUT,
        BRR_TRANSACTIONS.RECORD_ID as ID_ECRITURE,
    CASE BRR_TRANSACTIONS.DATE_LAST_NOTE_ADDED WHEN TO_DATE('01/01/1980','DD/MM/RRRR') THEN NULL
         ELSE TO_CHAR(BRR_TRANSACTIONS.DATE_LAST_NOTE_ADDED, 'DD/MM/RRRR') END AS ANNOTE_LE
FROM BRR_TRANSACTIONS BRR_TRANSACTIONS, BS_ACCTS BS_ACCTS, BA_COMPTE_METHODE BA_CPME
WHERE BS_ACCTS.ACCT_ID = BRR_TRANSACTIONS.ACCOUNT_ID
AND BA_CPME.ACCOUNT_ID = BS_ACCTS.ACCT_ID
AND (select (rpad(acct_num,length(acct_num)-2))
     from BS_ACCTS BS_ACCTS2 where BS_ACCTS2.ACCT_ID = (select H.level_03_account_id
                                                        From   BRR_ACCOUNT_HIERARCHIES H
                                                        where H.account_id = BS_ACCTS.ACCT_ID)) = s_TypeRapro
AND (select B.ACCT_NUM from BS_ACCTS B where B.ACCT_ID = (select H.level_02_account_id
                                                          from BRR_ACCOUNT_HIERARCHIES H
                                                           where H.account_id = BS_ACCTS.ACCT_ID)) = 'GESTION'
AND BRR_TRANSACTIONS.TRANSACTION_DATE <= TO_DATE(s_DateArrete, 'DD/MM/RRRR')
AND (BRR_TRANSACTIONS.STATE='OUTSTANDING')
-- en Recette uniquement AND BRR_TRANSACTIONS.TRANSACTION_DATE >= to_date(to_char( TO_DATE(s_DateArrete, 'DD/MM/RRRR') - 90 ,'ddmmyy'),'ddmmyy')  --JOB Ajout limitation en recette 90 jours avant date d'arrette
UNION
SELECT DISTINCT
            (select TO_CHAR(s_DateArrete) from dual) as DATE_ARRETE,
            (select decode(rpad(acct_num,length(acct_num)-2), 'RB', 'Rapprochement Bancaire',
                                                           'RC', 'Rapprochement de Contrôle',
                                                           'JC', 'Justification de compte',
                                                           'CL', 'Compte de liaison')
                from BS_ACCTS BS_ACCTS2 where BS_ACCTS2.ACCT_ID = (select H.level_03_account_id
                                                                               From   BRR_ACCOUNT_HIERARCHIES H
                                                                               where H.account_id =BS_ACCTS.ACCT_ID)) as TYPE_RAPRO,
        (select B.ACCT_NUM from BS_ACCTS B where B.ACCT_ID = (select H.level_02_account_id
                                                                 from BRR_ACCOUNT_HIERARCHIES H
                                                               where H.account_id = BS_ACCTS.ACCT_ID)) as SERVICE,
        (select acct_name from BS_ACCTS ACCTS2 where ACCTS2.acct_id = BS_ACCTS.acct_group) as SOCIETE,
        BA_CPME.compte_bancaire as COMPTE_BANCAIRE,
        BS_ACCTS.ACCT_NAME as LIBELLE_COMPTE,
        BS_ACCTS.ACCT_CURRENCY as DEVISE,
        TO_CHAR(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR') as DATE_OPERATION,
        BRR_TRANSACTIONS.NARRATIVE as LIBELLE_SUSPENS,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT) as DEBIT,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'PAYMENTCASHBOOK', BRR_TRANSACTIONS.AMOUNT) as CREDIT,
        DECODE(BRR_TRANSACTIONS.NUMERIC_TWO, 0, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','ABD','PAYMENTSTATEMENT','ACC','RECEIPTCASHBOOK','ABC','RECEIPTSTATEMENT','ACD'), 'A'||BRR_TRANSACTIONS.FLAG_C||DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D')) as SENS_ATTENDU,
           --DECODE(nvl(instr(BRR_TRANSACTIONS.LAST_NOTE_TEXT, ';'),0),0, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','ABD','PAYMENTSTATEMENT','ACC','RECEIPTCASHBOOK','ABC','RECEIPTSTATEMENT','ACD'), 'A'||DECODE(SIGN(TRIM(SUBSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,1,INSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,';') - 1))-1000),1,'B', 0 , 'B', 'C')||DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D')) as SENS_ATTENDU,
        DECODE(BRR_TRANSACTIONS.SIDE,'STATEMENT', 'B','CASHBOOK', 'C') as COTE_SUSPENS,
        (select TO_DATE(s_DateArrete, 'DD/MM/RRRR') - TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR') from dual) as ANCIENNETE_J,
        (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) as ANCIENNETE_M,
        (select libelle_anciennete from BA_CATEG_ANCIENNETE BACA
         where (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) >= BACA.borne_inf
         and   (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) < BACA.borne_sup) as BORNE_ANCIENNETE,
            DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                      where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)
                                           ,'RECEIPTCASHBOOK', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                         where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)) as PILIER_MONTANT_DEBIT,
            DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                      where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)
                                               ,'PAYMENTCASHBOOK', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                         where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)) as PILIER_MONTANT_CREDIT,
           BA_CPME.methode as METHODE_PROVISION,
               (select taux from BA_METHODE_PROVISION MEPR
                 where methode = (select methode from BA_COMPTE_METHODE CPME where CPME.ACCOUNT_ID = BS_ACCTS.acct_id)
                 and (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'),
                                    TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) >= MEPR.borne_inf
                 and (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'),
                                    TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) < MEPR.borne_sup) as TAUX,
        0 as MONTANT_PROVISION,
        BRR_TRANSACTIONS.STATE as STATUT,
        TO_DATE(BRR_TRANSACTIONS.UPDATE_TIME, 'DD/MM/RRRR') as DATE_APUREMENT,
        (SELECT MAX(E.TRANSACTION_DATE) FROM  BRR_TRANSACTIONS E
                                        WHERE E.RECONCILIATION_REFERENCE = BRR_TRANSACTIONS.RECONCILIATION_REFERENCE
                                        AND   E.ACCOUNT_ID = BRR_TRANSACTIONS.ACCOUNT_ID) as DC_MAX,  --V1.2
        SUBSTR(BRR_TRANSACTIONS.CHARACTER_SIXTEEN, 1,5) as PRIORITE , -- JOB Ajout 27/11/2025    '' as PRIORITE,
        BRR_TRANSACTIONS.LAST_NOTE_TEXT as COMMENTAIRE,
        --TRIM(SUBSTR(LAST_NOTE_TEXT,1,INSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,';') - 1)) as NETTING,
        BRR_TRANSACTIONS.NUMERIC_TWO as NETTING,
        DECODE(DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT), null, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'PAYMENTCASHBOOK', BRR_TRANSACTIONS.AMOUNT), DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT)) as DELTA,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D') as SENS_DELTA,
        '' as NUMERO_FICHE,
        '' as DERNIER_STATUT,
        BRR_TRANSACTIONS.RECORD_ID as ID_ECRITURE,
    CASE BRR_TRANSACTIONS.DATE_LAST_NOTE_ADDED WHEN TO_DATE('01/01/1980','DD/MM/RRRR') THEN NULL
         ELSE TO_CHAR(BRR_TRANSACTIONS.DATE_LAST_NOTE_ADDED, 'DD/MM/RRRR') END AS ANNOTE_LE
FROM BRR_TRANSACTIONS BRR_TRANSACTIONS, BS_ACCTS BS_ACCTS , BA_COMPTE_METHODE BA_CPME
WHERE BS_ACCTS.ACCT_ID = BRR_TRANSACTIONS.ACCOUNT_ID
AND BA_CPME.ACCOUNT_ID = BS_ACCTS.ACCT_ID
AND (select (rpad(acct_num,length(acct_num)-2))
     from BS_ACCTS BS_ACCTS2 where BS_ACCTS2.ACCT_ID = (select H.level_03_account_id
                                                        From   BRR_ACCOUNT_HIERARCHIES H
                                                        where H.account_id = BS_ACCTS.ACCT_ID)) = s_TypeRapro
AND (select B.ACCT_NUM from BS_ACCTS B where B.ACCT_ID = (select H.level_02_account_id
                                                          from BRR_ACCOUNT_HIERARCHIES H
                                                           where H.account_id = BS_ACCTS.ACCT_ID)) = 'GESTION'
AND BRR_TRANSACTIONS.TRANSACTION_DATE <= TO_DATE(s_DateArrete, 'DD/MM/RRRR')
AND BRR_TRANSACTIONS.UPDATE_TIME >= TO_DATE(s_DateArrete, 'DD/MM/RRRR')
AND (BRR_TRANSACTIONS.STATE='RECONCILED')
-- en Recette uniquement AND BRR_TRANSACTIONS.TRANSACTION_DATE >= to_date(to_char( TO_DATE(s_DateArrete, 'DD/MM/RRRR') - 90 ,'ddmmyy'),'ddmmyy')  --JOB Ajout limitation en recette 90 jours avant date d'arrette
order by SERVICE, SOCIETE, COMPTE_BANCAIRE, DATE_OPERATION_SUSPENS, NETTING;


/* *************************************************************** */
/*      Extraction des Attendus de la base Accurate                 */
/*     avec date comptable max par groupe de rapprochement               */
/*      Récupération des zones dans une table "temporaire"            */
/* *************************************************************** */
--  V1.3
CURSOR Curseur_Attendus_DC_Max IS
SELECT /*+  optimizer_features_enable('10.2.0.4') */ DISTINCT
           (select TO_CHAR(s_DateArrete) from dual) as DATE_ARRETE,
           (select decode(rpad(acct_num,length(acct_num)-2), 'RB', 'Rapprochement Bancaire',
                                                           'RC', 'Rapprochement de Contrôle',
                                                           'JC', 'Justification de compte',
                                                           'CL', 'Compte de liaison')
                    from BS_ACCTS BS_ACCTS2 where BS_ACCTS2.ACCT_ID = (select H.level_03_account_id
                                                                                       From   BRR_ACCOUNT_HIERARCHIES H
                                                                                       where H.account_id =BS_ACCTS.ACCT_ID)) as TYPE_RAPRO,
            (select B.ACCT_NUM from BS_ACCTS B where B.ACCT_ID = (select H.level_02_account_id
                                                        from BRR_ACCOUNT_HIERARCHIES H
                                                         where H.account_id = BS_ACCTS.ACCT_ID)) as SERVICE,
        (select acct_name from BS_ACCTS ACCTS2 where ACCTS2.acct_id = BS_ACCTS.acct_group) as SOCIETE,
        BA_CPME.compte_bancaire as COMPTE_BANCAIRE,
        BS_ACCTS.ACCT_NAME as LIBELLE_COMPTE,
        BS_ACCTS.ACCT_CURRENCY as DEVISE,
        TO_CHAR(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR') as DATE_OPERATION_SUSPENS,
        BRR_TRANSACTIONS.NARRATIVE as LIBELLE_SUSPENS,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT) as DEBIT,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'PAYMENTCASHBOOK', BRR_TRANSACTIONS.AMOUNT) as CREDIT,
        DECODE(BRR_TRANSACTIONS.NUMERIC_TWO, 0, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','ABD','PAYMENTSTATEMENT','ACC','RECEIPTCASHBOOK','ABC','RECEIPTSTATEMENT','ACD'), 'A'||BRR_TRANSACTIONS.FLAG_C||DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D')) as SENS_ATTENDU,
        --DECODE(nvl(instr(BRR_TRANSACTIONS.LAST_NOTE_TEXT, ';'),0),0, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','ABD','PAYMENTSTATEMENT','ACC','RECEIPTCASHBOOK','ABC','RECEIPTSTATEMENT','ACD'), 'A'||DECODE(SIGN(TRIM(SUBSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,1,INSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,';') - 1))-1000),1,'B', 0 , 'B', 'C')||DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D')) as SENS_ATTENDU,
        DECODE(BRR_TRANSACTIONS.SIDE,'STATEMENT', 'B','CASHBOOK', 'C') as COTE_SUSPENS,
        (select TO_DATE(s_DateArrete, 'DD/MM/RRRR') - TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR') from dual) as ANCIENNETE_J,
        (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) as ANCIENNETE_M,
        (select libelle_anciennete from BA_CATEG_ANCIENNETE BACA
         where (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) >= BACA.borne_inf
         and   (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) < BACA.borne_sup) as BORNE_ANCIENNETE,
            DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                      where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)
                                          ,'RECEIPTCASHBOOK', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                         where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)) as PILIER_MONTANT_DEBIT,
            DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                      where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)
                                               ,'PAYMENTCASHBOOK', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                             where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)) as PILIER_MONTANT_CREDIT,
            BA_CPME.methode as METHODE_PROVISION,
            (select taux from BA_METHODE_PROVISION MEPR
                 where methode = (select methode from BA_COMPTE_METHODE CPME where CPME.ACCOUNT_ID = BS_ACCTS.acct_id)
                 and (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'),
                                    TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) >= MEPR.borne_inf
                 and (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'),
                                    TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) < MEPR.borne_sup) as TAUX,
        0 as MONTANT_PROVISION,
        BRR_TRANSACTIONS.STATE as STATUT,
        null as DATE_APUREMENT,
        null as DC_MAX,  --V1.2
        SUBSTR(BRR_TRANSACTIONS.CHARACTER_SIXTEEN, 1,5) as PRIORITE , -- JOB Ajout 27/11/2025    '' as PRIORITE,
        BRR_TRANSACTIONS.LAST_NOTE_TEXT as COMMENTAIRE,
        --TRIM(SUBSTR(LAST_NOTE_TEXT,1,INSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,';') - 1)) as NETTING,
           BRR_TRANSACTIONS.NUMERIC_TWO as NETTING,
         DECODE(DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT), null, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'PAYMENTCASHBOOK', BRR_TRANSACTIONS.AMOUNT), DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT)) as DELTA,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D') as SENS_DELTA,
        '' as NUMERO_FICHE,
        '' as DERNIER_STATUT,
        BRR_TRANSACTIONS.RECORD_ID as ID_ECRITURE,
    CASE BRR_TRANSACTIONS.DATE_LAST_NOTE_ADDED WHEN TO_DATE('01/01/1980','DD/MM/RRRR') THEN NULL
         ELSE TO_CHAR(BRR_TRANSACTIONS.DATE_LAST_NOTE_ADDED, 'DD/MM/RRRR') END AS ANNOTE_LE
FROM BRR_TRANSACTIONS BRR_TRANSACTIONS, BS_ACCTS BS_ACCTS, BA_COMPTE_METHODE BA_CPME
WHERE BS_ACCTS.ACCT_ID = BRR_TRANSACTIONS.ACCOUNT_ID
AND BA_CPME.ACCOUNT_ID = BS_ACCTS.ACCT_ID
AND (select (rpad(acct_num,length(acct_num)-2))
     from BS_ACCTS BS_ACCTS2 where BS_ACCTS2.ACCT_ID = (select H.level_03_account_id
                                                        From   BRR_ACCOUNT_HIERARCHIES H
                                                        where H.account_id = BS_ACCTS.ACCT_ID)) = s_TypeRapro
AND (select B.ACCT_NUM from BS_ACCTS B where B.ACCT_ID = (select H.level_02_account_id
                                                          from BRR_ACCOUNT_HIERARCHIES H
                                                           where H.account_id = BS_ACCTS.ACCT_ID)) = 'GESTION'
AND BRR_TRANSACTIONS.TRANSACTION_DATE <= TO_DATE(s_DateArrete, 'DD/MM/RRRR')
AND (BRR_TRANSACTIONS.STATE='OUTSTANDING')
-- en Recette uniquement AND BRR_TRANSACTIONS.TRANSACTION_DATE >= to_date(to_char( TO_DATE(s_DateArrete, 'DD/MM/RRRR') - 90 ,'ddmmyy'),'ddmmyy')  --JOB Ajout limitation en recette 90 jours avant date d'arrette
UNION
SELECT /*+  optimizer_features_enable('10.2.0.4') */ DISTINCT
            (select TO_CHAR(s_DateArrete) from dual) as DATE_ARRETE,
            (select decode(rpad(acct_num,length(acct_num)-2), 'RB', 'Rapprochement Bancaire',
                                                           'RC', 'Rapprochement de Contrôle',
                                                           'JC', 'Justification de compte',
                                                           'CL', 'Compte de liaison')
                from BS_ACCTS BS_ACCTS2 where BS_ACCTS2.ACCT_ID = (select H.level_03_account_id
                                                                               From   BRR_ACCOUNT_HIERARCHIES H
                                                                               where H.account_id =BS_ACCTS.ACCT_ID)) as TYPE_RAPRO,
        (select B.ACCT_NUM from BS_ACCTS B where B.ACCT_ID = (select H.level_02_account_id
                                                                 from BRR_ACCOUNT_HIERARCHIES H
                                                               where H.account_id = BS_ACCTS.ACCT_ID)) as SERVICE,
        (select acct_name from BS_ACCTS ACCTS2 where ACCTS2.acct_id = BS_ACCTS.acct_group) as SOCIETE,
        BA_CPME.compte_bancaire as COMPTE_BANCAIRE,
        BS_ACCTS.ACCT_NAME as LIBELLE_COMPTE,
        BS_ACCTS.ACCT_CURRENCY as DEVISE,
        TO_CHAR(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR') as DATE_OPERATION,
        BRR_TRANSACTIONS.NARRATIVE as LIBELLE_SUSPENS,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT) as DEBIT,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'PAYMENTCASHBOOK', BRR_TRANSACTIONS.AMOUNT) as CREDIT,
        DECODE(BRR_TRANSACTIONS.NUMERIC_TWO, 0, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','ABD','PAYMENTSTATEMENT','ACC','RECEIPTCASHBOOK','ABC','RECEIPTSTATEMENT','ACD'), 'A'||BRR_TRANSACTIONS.FLAG_C||DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D')) as SENS_ATTENDU,
           --DECODE(nvl(instr(BRR_TRANSACTIONS.LAST_NOTE_TEXT, ';'),0),0, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','ABD','PAYMENTSTATEMENT','ACC','RECEIPTCASHBOOK','ABC','RECEIPTSTATEMENT','ACD'), 'A'||DECODE(SIGN(TRIM(SUBSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,1,INSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,';') - 1))-1000),1,'B', 0 , 'B', 'C')||DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D')) as SENS_ATTENDU,
        DECODE(BRR_TRANSACTIONS.SIDE,'STATEMENT', 'B','CASHBOOK', 'C') as COTE_SUSPENS,
        (select TO_DATE(s_DateArrete, 'DD/MM/RRRR') - TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR') from dual) as ANCIENNETE_J,
        (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) as ANCIENNETE_M,
        (select libelle_anciennete from BA_CATEG_ANCIENNETE BACA
         where (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) >= BACA.borne_inf
         and   (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'), TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) < BACA.borne_sup) as BORNE_ANCIENNETE,
            DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                      where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)
                                           ,'RECEIPTCASHBOOK', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                         where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)) as PILIER_MONTANT_DEBIT,
            DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                      where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)
                                               ,'PAYMENTCASHBOOK', (select libelle_pilier
                                                                                              from BA_PILIERS_MONTANTS PIMO
                                                         where BRR_TRANSACTIONS.AMOUNT >= PIMO.borne_inf and BRR_TRANSACTIONS.AMOUNT < PIMO.borne_sup)) as PILIER_MONTANT_CREDIT,
           BA_CPME.methode as METHODE_PROVISION,
               (select taux from BA_METHODE_PROVISION MEPR
                 where methode = (select methode from BA_COMPTE_METHODE CPME where CPME.ACCOUNT_ID = BS_ACCTS.acct_id)
                 and (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'),
                                    TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) >= MEPR.borne_inf
                 and (select months_between(TO_DATE(s_DateArrete, 'DD/MM/RRRR'),
                                    TO_DATE(BRR_TRANSACTIONS.TRANSACTION_DATE, 'DD/MM/RRRR')) from dual) < MEPR.borne_sup) as TAUX,
        0 as MONTANT_PROVISION,
        BRR_TRANSACTIONS.STATE as STATUT,
        TO_DATE(BRR_TRANSACTIONS.UPDATE_TIME, 'DD/MM/RRRR') as DATE_APUREMENT,
        (SELECT MAX(E.TRANSACTION_DATE) FROM  BRR_TRANSACTIONS E
                                        WHERE E.RECONCILIATION_REFERENCE = BRR_TRANSACTIONS.RECONCILIATION_REFERENCE
                                        AND   E.ACCOUNT_ID = BRR_TRANSACTIONS.ACCOUNT_ID) as DC_MAX,  --V1.2
        SUBSTR(BRR_TRANSACTIONS.CHARACTER_SIXTEEN, 1,5) as PRIORITE , -- JOB Ajout 27/11/2025    '' as PRIORITE,,,
        BRR_TRANSACTIONS.LAST_NOTE_TEXT as COMMENTAIRE,
        --TRIM(SUBSTR(LAST_NOTE_TEXT,1,INSTR(BRR_TRANSACTIONS.LAST_NOTE_TEXT,';') - 1)) as NETTING,
        BRR_TRANSACTIONS.NUMERIC_TWO as NETTING,
        DECODE(DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT), null, DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'RECEIPTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'PAYMENTCASHBOOK', BRR_TRANSACTIONS.AMOUNT), DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTSTATEMENT',BRR_TRANSACTIONS.AMOUNT,'RECEIPTCASHBOOK', BRR_TRANSACTIONS.AMOUNT)) as DELTA,
        DECODE(BRR_TRANSACTIONS.PAYMENT_OR_RECEIPT||BRR_TRANSACTIONS.SIDE,'PAYMENTCASHBOOK','D','PAYMENTSTATEMENT','C','RECEIPTCASHBOOK','C','RECEIPTSTATEMENT','D') as SENS_DELTA,
        '' as NUMERO_FICHE,
        '' as DERNIER_STATUT,
        BRR_TRANSACTIONS.RECORD_ID as ID_ECRITURE,
    CASE BRR_TRANSACTIONS.DATE_LAST_NOTE_ADDED WHEN TO_DATE('01/01/1980','DD/MM/RRRR') THEN NULL
         ELSE TO_CHAR(BRR_TRANSACTIONS.DATE_LAST_NOTE_ADDED, 'DD/MM/RRRR') END AS ANNOTE_LE
FROM BRR_TRANSACTIONS BRR_TRANSACTIONS, BS_ACCTS BS_ACCTS , BA_COMPTE_METHODE BA_CPME
WHERE BS_ACCTS.ACCT_ID = BRR_TRANSACTIONS.ACCOUNT_ID
AND BA_CPME.ACCOUNT_ID = BS_ACCTS.ACCT_ID
AND (select (rpad(acct_num,length(acct_num)-2))
     from BS_ACCTS BS_ACCTS2 where BS_ACCTS2.ACCT_ID = (select H.level_03_account_id
                                                        From   BRR_ACCOUNT_HIERARCHIES H
                                                        where H.account_id = BS_ACCTS.ACCT_ID)) = s_TypeRapro
AND (select B.ACCT_NUM from BS_ACCTS B where B.ACCT_ID = (select H.level_02_account_id
                                                          from BRR_ACCOUNT_HIERARCHIES H
                                                           where H.account_id = BS_ACCTS.ACCT_ID)) = 'GESTION'
AND BRR_TRANSACTIONS.TRANSACTION_DATE <= TO_DATE(s_DateArrete, 'DD/MM/RRRR')
--AND BRR_TRANSACTIONS.UPDATE_TIME >= TO_DATE(s_DateArrete, 'DD/MM/RRRR')
AND (SELECT MAX(E.TRANSACTION_DATE) FROM  BRR_TRANSACTIONS E
                                    WHERE E.RECONCILIATION_REFERENCE = BRR_TRANSACTIONS.RECONCILIATION_REFERENCE
                                    AND   E.ACCOUNT_ID = BRR_TRANSACTIONS.ACCOUNT_ID) >= TO_DATE(s_DateArrete, 'DD/MM/RRRR')
AND (BRR_TRANSACTIONS.STATE='RECONCILED')
-- en Recette uniquement AND BRR_TRANSACTIONS.TRANSACTION_DATE >= to_date(to_char( TO_DATE(s_DateArrete, 'DD/MM/RRRR') - 90 ,'ddmmyy'),'ddmmyy')  --JOB Ajout limitation en recette 90 jours avant date d'arrette
order by SERVICE, SOCIETE, COMPTE_BANCAIRE, DATE_OPERATION_SUSPENS, NETTING;


CURSOR Curseur_LignesLettrees IS
select distinct DATE_ARRETE,
TYPE_RAPRO,
SERVICE,
SOCIETE,
COMPTE_BANCAIRE,
LIBELLE_COMPTE,
DEVISE,
NETTING
from BA_ATTENDUS_GEST
where netting != 0
ORDER BY SOCIETE, COMPTE_BANCAIRE,DEVISE;


BEGIN -- general

EXECUTE IMMEDIATE 'TRUNCATE TABLE BA_ATTENDUS_GEST';

IF s_TypeDate = 'P' THEN  --  V1.3

  BEGIN  -- insert dans BA_ATTENDUS_GEST  Partie Extraction en date physique de rapprochement

  -- Insertion données brutes dans table temporaire
  PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Extraction des données de la Base des Attendus.', 0, s_FONCTION);

  -- ouverture curseur
  OPEN Curseur_Attendus_D_Rapro;


  LOOP

  FETCH Curseur_Attendus_D_Rapro
   INTO Var_DATE_ARRETE,
        Var_TYPE_RAPRO,
        Var_SERVICE,
        Var_SOCIETE,
        Var_COMPTE_BANCAIRE,
        Var_LIBELLE_COMPTE,
        Var_DEVISE,
        Var_DATE_OPERATION_SUSPENS,
        Var_LIBELLE_SUSPENS,
        Var_CREDIT,
        Var_DEBIT,
        Var_SENS_ATTENDU,
    Var_COTE_SUSPENS,
        Var_ANCIENNETE_J,
        Var_ANCIENNETE_M,
        Var_BORNE_ANCIENNETE,
        Var_PILIER_MONTANT_CREDIT,
        Var_PILIER_MONTANT_DEBIT,
        Var_METHODE_PROVISION,
        Var_TAUX,
        Var_MONTANT_PROVISION,
        Var_STATUT,
        Var_DATE_APUREMENT,
        Var_DC_MAX,  --V1.2
        Var_PRIORITE,
        Var_COMMENTAIRE,
        Var_NETTING,
        Var_DELTA,
    Var_SENS_DELTA,
        Var_NUMERO_FICHE,
        Var_DERNIER_STATUT,
        Var_RECORD_ID,
    Var_ANNOTE_LE;


  EXIT WHEN Curseur_Attendus_D_Rapro%NOTFOUND;

          -- Cas des lignes non prélettrées

          -- Calcul du montant provisionné en fonction du débit ou du crédit

               IF Var_DEBIT IS NOT NULL THEN
                 Var_MONTANT_PROVISION := Var_TAUX * Var_DEBIT;
               ELSE
                 Var_MONTANT_PROVISION := Var_TAUX * Var_CREDIT;
               END IF;


          -- Si l'attendu non prélettré a un sens delta = 'D', il n'est pas provisionné

          IF (Var_SENS_DELTA = 'D'
              AND Var_NETTING = 0) THEN
            Var_MONTANT_PROVISION := 0;
            Var_TAUX := 0;
          END IF;


                  -- les écritures d'extourne ne sont pas provisionnées
 -- JOB -- Mis en commentaire par JOB 23/10/2025  -  AER_ITFIN-58882
/*
IF Var_LIBELLE_SUSPENS like 'Ecriture extourne%' THEN
            Var_MONTANT_PROVISION := 0;
            Var_TAUX := 0;
          END IF;
*/
--  JOB

              INSERT INTO BA_ATTENDUS_GEST (DATE_ARRETE, TYPE_RAPRO, SERVICE, SOCIETE, COMPTE_BANCAIRE, LIBELLE_COMPTE,
                                                DEVISE, DATE_OPERATION_SUSPENS, LIBELLE_SUSPENS, DEBIT, CREDIT, SENS_ATTENDU, COTE_SUSPENS,
                                           ANCIENNETE_J, ANCIENNETE_M, BORNE_ANCIENNETE, PILIER_MONTANT_DEBIT, PILIER_MONTANT_CREDIT,
                                           METHODE_PROVISION, TAUX, MONTANT_PROVISION, STATUT, DATE_APUREMENT, DC_MAX, PRIORITE, COMMENTAIRE,
                            NETTING, DELTA, SENS_DELTA, NUMERO_FICHE, DERNIER_STATUT, RECORD_ID, ANNOTE_LE)  --V1.2
                    VALUES (Var_DATE_ARRETE, Var_TYPE_RAPRO, Var_SERVICE, Var_SOCIETE, Var_COMPTE_BANCAIRE, Var_LIBELLE_COMPTE,
                            Var_DEVISE, Var_DATE_OPERATION_SUSPENS, Var_LIBELLE_SUSPENS, Var_DEBIT, Var_CREDIT, Var_SENS_ATTENDU, Var_COTE_SUSPENS,
                          Var_ANCIENNETE_J, Var_ANCIENNETE_M, Var_BORNE_ANCIENNETE, Var_PILIER_MONTANT_DEBIT, Var_PILIER_MONTANT_CREDIT,
                          Var_METHODE_PROVISION, Var_TAUX, Var_MONTANT_PROVISION, Var_STATUT, Var_DATE_APUREMENT, Var_DC_MAX, Var_PRIORITE, Var_COMMENTAIRE,
                      Var_NETTING, Var_DELTA, Var_SENS_DELTA, Var_NUMERO_FICHE, Var_DERNIER_STATUT, Var_RECORD_ID, Var_ANNOTE_LE);  --V1.2

  END LOOP;

  -- fermeture curseur
  CLOSE Curseur_Attendus_D_Rapro;

  -- nbr enreg total
  nbr_enreg := SQL%ROWCOUNT;

  PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_CPT, nbr_enreg||' données extraites.', nbr_enreg, s_FONCTION);

  COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      PKG_LOG.P_ECRIRE(gt_InfoTrait);
      RETURN PKG_GLOBAL.gn_CR_KO;

  END; -- insert dans BA_ATTENDUS_GEST Partie Extraction en date physique de rapprochement

ELSE

  BEGIN  -- insert dans BA_ATTENDUS_GEST Partie extraction en date comptable max pour un groupe de rapprochement

  -- Insertion données brutes dans table temporaire
  PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Extraction des données de la Base des Attendus.', 0, s_FONCTION);

  -- ouverture curseur
  OPEN Curseur_Attendus_DC_Max;


  LOOP

  FETCH Curseur_Attendus_DC_Max
   INTO Var_DATE_ARRETE,
        Var_TYPE_RAPRO,
        Var_SERVICE,
        Var_SOCIETE,
        Var_COMPTE_BANCAIRE,
        Var_LIBELLE_COMPTE,
        Var_DEVISE,
        Var_DATE_OPERATION_SUSPENS,
        Var_LIBELLE_SUSPENS,
        Var_CREDIT,
        Var_DEBIT,
        Var_SENS_ATTENDU,
        Var_COTE_SUSPENS,
        Var_ANCIENNETE_J,
        Var_ANCIENNETE_M,
        Var_BORNE_ANCIENNETE,
        Var_PILIER_MONTANT_CREDIT,
        Var_PILIER_MONTANT_DEBIT,
        Var_METHODE_PROVISION,
        Var_TAUX,
        Var_MONTANT_PROVISION,
        Var_STATUT,
        Var_DATE_APUREMENT,
        Var_DC_MAX,  --V1.2
        Var_PRIORITE,
        Var_COMMENTAIRE,
        Var_NETTING,
        Var_DELTA,
        Var_SENS_DELTA,
        Var_NUMERO_FICHE,
        Var_DERNIER_STATUT,
        Var_RECORD_ID,
    Var_ANNOTE_LE;


  EXIT WHEN Curseur_Attendus_DC_Max%NOTFOUND;

          -- Cas des lignes non prélettrées

           -- Calcul du montant provisionné en fonction du débit ou du crédit

                  IF Var_DEBIT IS NOT NULL THEN
                    Var_MONTANT_PROVISION := Var_TAUX * Var_DEBIT;
                  ELSE
                    Var_MONTANT_PROVISION := Var_TAUX * Var_CREDIT;
                  END IF;


          -- Si l'attendu non prélettré a un sens delta = 'D', il n'est pas provisionné

          IF (Var_SENS_DELTA = 'D'
              AND Var_NETTING = 0) THEN
            Var_MONTANT_PROVISION := 0;
            Var_TAUX := 0;
          END IF;


                  -- les écritures d'extourne ne sont pas provisionnées
--  JOB -- Mis en commentaire par JOB 23/10/2025  -  AER_ITFIN-58882
/*
IF Var_LIBELLE_SUSPENS like 'Ecriture extourne%' THEN
            Var_MONTANT_PROVISION := 0;
            Var_TAUX := 0;
          END IF;
*/

      INSERT INTO BA_ATTENDUS_GEST (DATE_ARRETE, TYPE_RAPRO, SERVICE, SOCIETE, COMPTE_BANCAIRE, LIBELLE_COMPTE,
                                   DEVISE, DATE_OPERATION_SUSPENS, LIBELLE_SUSPENS, DEBIT, CREDIT, SENS_ATTENDU, COTE_SUSPENS,
                         ANCIENNETE_J, ANCIENNETE_M, BORNE_ANCIENNETE, PILIER_MONTANT_DEBIT, PILIER_MONTANT_CREDIT,
                         METHODE_PROVISION, TAUX, MONTANT_PROVISION, STATUT, DATE_APUREMENT, DC_MAX, PRIORITE, COMMENTAIRE,
                       NETTING, DELTA, SENS_DELTA, NUMERO_FICHE, DERNIER_STATUT, RECORD_ID, ANNOTE_LE)  --V1.2
            VALUES (Var_DATE_ARRETE, Var_TYPE_RAPRO, Var_SERVICE, Var_SOCIETE, Var_COMPTE_BANCAIRE, Var_LIBELLE_COMPTE,
                    Var_DEVISE, Var_DATE_OPERATION_SUSPENS, Var_LIBELLE_SUSPENS, Var_DEBIT, Var_CREDIT, Var_SENS_ATTENDU, Var_COTE_SUSPENS,
                  Var_ANCIENNETE_J, Var_ANCIENNETE_M, Var_BORNE_ANCIENNETE, Var_PILIER_MONTANT_DEBIT, Var_PILIER_MONTANT_CREDIT,
                  Var_METHODE_PROVISION, Var_TAUX, Var_MONTANT_PROVISION, Var_STATUT, Var_DATE_APUREMENT, Var_DC_MAX, Var_PRIORITE, Var_COMMENTAIRE,
                  Var_NETTING, Var_DELTA, Var_SENS_DELTA, Var_NUMERO_FICHE, Var_DERNIER_STATUT, Var_RECORD_ID, Var_ANNOTE_LE);  --V1.2

  END LOOP;

  -- fermeture curseur
  CLOSE Curseur_Attendus_DC_Max;

  -- nbr enreg total
  nbr_enreg := SQL%ROWCOUNT;

  PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_CPT, nbr_enreg||' données extraites.', nbr_enreg, s_FONCTION);

  COMMIT;


  EXCEPTION
    WHEN OTHERS THEN
      PKG_LOG.P_ECRIRE(gt_InfoTrait);
      RETURN PKG_GLOBAL.gn_CR_KO;

  END; -- insert dans BA_ATTENDUS_GEST Partie extraction en date comptable max pour un groupe de rapprochement

END IF;

BEGIN -- Recalcul des taux pour lignes prélettrées

  -- Insertion données brutes dans table temporaire
  PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Recalcul des taux pour lignes prélettrées.', 0, s_FONCTION);

-- ouverture curseur listant les comptes de la table BA_ATTENDUS_GEST
OPEN Curseur_LignesLettrees;


Var_DATE_ARRETE                      :='';
Var_TYPE_RAPRO                      :='';
Var_SERVICE                          :='';
Var_SOCIETE                          :='';
Var_COMPTE_BANCAIRE                  :='';
Var_LIBELLE_COMPTE                  :='';
Var_DEVISE                          :='';
Var_DATE_OPERATION_SUSPENS          :='';
Var_LIBELLE_SUSPENS                  :='';
Var_DEBIT                          :=0;
Var_CREDIT                          :=0;
Var_SENS_ATTENDU                  :='';
Var_COTE_SUSPENS                  :='';
Var_ANCIENNETE_J                  :=0;
Var_ANCIENNETE_M                  :=0;
Var_BORNE_ANCIENNETE              :='';
Var_PILIER_MONTANT_DEBIT          :='';
Var_PILIER_MONTANT_CREDIT          :='';
Var_METHODE_PROVISION              :='';
Var_TAUX                          :=0;
Var_MONTANT_PROVISION                :=0;
Var_STATUT                          :='';
Var_DATE_APUREMENT                  :='';
Var_DC_MAX                          :='';  --V1.2
Var_PRIORITE                         :='';
Var_COMMENTAIRE                      :='';
Var_NETTING                          :='';
Var_DELTA                         :=0;
Var_SENS_DELTA                    :='';
Var_NUMERO_FICHE                  :='';
Var_DERNIER_STATUT                :='';
Var_RECORD_ID                     :=0;
Var_RECORD_ID_MIN                  :=0;
Var_NB_PRELETTRE                  :=0;
Var_ANNOTE_LE           :='';


LOOP

FETCH Curseur_LignesLettrees
 INTO Var_DATE_ARRETE,
      Var_TYPE_RAPRO,
      Var_SERVICE,
      Var_SOCIETE,
      Var_COMPTE_BANCAIRE,
      Var_LIBELLE_COMPTE,
      Var_DEVISE,
      Var_NETTING;

EXIT WHEN Curseur_LignesLettrees%NOTFOUND;


    -- Calcul du delta, du sens delta, du taux le plus élevé, et de l'identifiant
    -- écriture le plus petit, par groupe de prélettrage


    BEGIN

    select sum(nvl(BA.credit,0))-sum(nvl(BA.debit,0)),
           decode(sign(sum(nvl(BA.credit,0))-sum(nvl(BA.debit,0))), 1,'C', -1, 'D', 0, '-'),
           BA.netting,
           max(taux),
           count(*)
    into   Var_MONTANT_DIFF,
           Var_SENS_DELTA,
           Var_NUM_PRELETTRAGE,
           Var_TAUX_PLUS_ELEVE,
           Var_NB_PRELETTRE
    from BA_ATTENDUS_GEST BA
    where BA.netting = Var_NETTING
    and BA.compte_bancaire = Var_COMPTE_BANCAIRE
    group by netting;


    EXCEPTION
      WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Calcul des sommes dans BA_ATTENDUS_GEST' || '/' || Var_COMPTE_BANCAIRE || '/' || Var_NETTING, 0, s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    END;


    -- Calcul de l'identifiant écriture le plus petit, par groupe de prélettrage,
    -- pour la date d'operation la plus ancienne

    BEGIN

    select min(to_date(BA.date_operation_suspens, 'dd/mm/rrrr')) as DATE_MIN,
           min(record_id)
    into   Var_DATE_PLUS_ANCIEN,
           Var_RECORD_ID_MIN
    from   BA_ATTENDUS_GEST BA
    where  BA.netting = Var_NETTING
    and    BA.compte_bancaire = Var_COMPTE_BANCAIRE
    and    to_date(BA.date_operation_suspens, 'dd/mm/rrrr') = (select min(to_date(BA2.date_operation_suspens, 'dd/mm/rrrr'))
                                                               from   BA_ATTENDUS_GEST BA2
                                                               where  BA2.netting = Var_NETTING
                                                               and    BA2.compte_bancaire = Var_COMPTE_BANCAIRE)
    group by netting;

    EXCEPTION
      WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Calcul de l''ID le plus petit' || '/' || Var_COMPTE_BANCAIRE || '/' || Var_NETTING, 0, s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    END;


    -- Association du delta et du sens delta à tout le groupe de prélettrage

    BEGIN

    update BA_ATTENDUS_GEST
    set delta = ABS(Var_MONTANT_DIFF),
        sens_delta = Var_SENS_DELTA
    where netting = Var_NETTING
    and   compte_bancaire = Var_COMPTE_BANCAIRE;


    EXCEPTION
      WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Modification du delta des lignes prelettrées', 0, s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    END;


    -- Pour un groupe de prélettrage, si le sens delta est 'D', le taux et le montant provisionnés
    -- seront à 0 ('-')

  IF Var_SENS_DELTA = 'D'
     OR Var_SENS_DELTA = '-' THEN


    BEGIN

       update BA_ATTENDUS_GEST
       set   taux = 0,
               montant_provision = 0
       where netting = Var_NETTING
       and   compte_bancaire = Var_COMPTE_BANCAIRE;


    EXCEPTION
      WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Modification du taux des lignes prelettrées au débit', 0, s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    END;


    -- Pour un groupe de prélettrage, sauf pour l'attendu le plus ancien du groupe,
    -- le delta est mis à zéro  V1.4

    BEGIN

    update BA_ATTENDUS_GEST
    set    delta = 0
    where  netting = Var_NETTING
    and    compte_bancaire = Var_COMPTE_BANCAIRE
    and    record_id != Var_RECORD_ID_MIN;


    EXCEPTION
      WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Modification du delta des autres lignes prelettrées', 0, s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    END;


  ELSE
    -- Calcul du taux et du montant provisionnés en fonction du taux le plus élevé du groupe
    -- de prélettrage (celui de l'attendu le plus ancien du groupe)

    BEGIN

    update BA_ATTENDUS_GEST
    set taux = Var_TAUX_PLUS_ELEVE,
        montant_provision = Var_TAUX_PLUS_ELEVE * Abs(Var_MONTANT_DIFF)
    where netting = Var_NETTING
    and   compte_bancaire = Var_COMPTE_BANCAIRE
    and   record_id = Var_RECORD_ID_MIN
    and   to_date(date_operation_suspens, 'dd/mm/rrrr') = to_date(Var_DATE_PLUS_ANCIEN, 'dd/mm/rrrr');


    EXCEPTION
      WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Modification du taux du plus petit record_id des lignes prelettrées', 0, s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    END;


    -- Pour les autres lignes du groupe de prélettrage, le taux et le montant sont à 0 ('-')

    BEGIN

    update BA_ATTENDUS_GEST
    set taux = 0,
        montant_provision = 0,
        delta = 0    --V1.4
    where netting = Var_NETTING
    and   compte_bancaire = Var_COMPTE_BANCAIRE
    and   record_id != Var_RECORD_ID_MIN;


    EXCEPTION
      WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Modification du taux des autres lignes prelettrées', 0, s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    END;

  END IF;

    -- S'il n'y a qu'un seul attendu pour un groupe de rapprochement, et que sons sens delta est 'D''
    -- le taux et le montant provisionné seront à 0 ('-')

    BEGIN

    IF Var_NB_PRELETTRE = 1
      AND Var_SENS_DELTA = 'D' THEN
       update BA_ATTENDUS_GEST
       set   taux = 0,
             montant_provision = 0
       where netting = Var_NETTING
       and   compte_bancaire = Var_COMPTE_BANCAIRE;
    END IF;

     EXCEPTION
      WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Modification du taux si le groupe de prélettrage ne contient qu''un attendu', 0, s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    END;


END LOOP;

-- fermeture curseur
CLOSE Curseur_LignesLettrees;




PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_CPT, ' donnees recalculees.', nbr_enreg, s_FONCTION);
-- MAJ de la colonne Num_Compte_Comptable


  BEGIN

    UPDATE BA_ATTENDUS_GEST
    set Num_Compte_Comptable = ( Select TA_RN_GEST_COMPTE_COMPTABLE.Num_Compte_Comptable
    FROM TA_RN_GEST_COMPTE_COMPTABLE
    where  TA_RN_GEST_COMPTE_COMPTABLE.COMPTE_BANCAIRE =EXP_RNAPA.BA_ATTENDUS_GEST.COMPTE_BANCAIRE
    );


    EXCEPTION
      WHEN OTHERS THEN
        PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Modification du numero compte comptable en erreur', 0, s_FONCTION);
        RETURN PKG_GLOBAL.gn_CR_KO;

    END;

COMMIT;

RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
  WHEN OTHERS THEN
    PKG_LOG.P_ECRIRE(gt_InfoTrait);
    RETURN PKG_GLOBAL.gn_CR_KO;

END; -- Recalcul des taux pour lignes prélettrées


END F_Extraire_BAATGS;




/******************************************************************************
   NOM        :       F_Generation_BAATGS
   OBJET      : Cette fonction gÃ©nÃ©re le fichier des Attendus pour la Gestion
   PARAMETRES : s_DateArrete                     -> Date d'arrÃªtÃ©
           s_TypeRapro                      -> Type de rapprochement

   VERSIONS:
   Ver        Date        Auteur           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        05/06/2007   MMA              Creation
   ---------  ----------  ---------------  ------------------------------------
   1.1        01/09/2007   ECO              Alimentation du fichier .info
   ---------  ----------  ---------------  ------------------------------------
   1.3        30/10/2007   MMA              Ajout du paramÃ¿tre s_TypeDate
                                            Type de date : date de rapprochement physique (P) ou
                                                           date comptable max du groupe de rapprochement (C)
   ---------  ----------  ---------------  ------------------------------------
   1.4        20/07/2009   RTI              Remplacement UTL FILE par CLOB et F_MAJ_FIC_INFO par F_MAJ_INFO
   ---------  ----------  ---------------  ------------------------------------
   1.5        20/06/2024                    Remplacement de la colonne RECORD_ID par le COMPTE_COMPTABLE


   NOTES: Retourne -1 si erreur, 0 sinon

******************************************************************************/
FUNCTION F_Generation_BAATGS(s_DateArrete VARCHAR2,s_TypeRapro VARCHAR2,s_TypeDate VARCHAR2)
                         RETURN NUMBER
IS

    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'F_Generation_BAATGS';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------

    s_NomFic                  VARCHAR2(50):='';
    s_Ligne                         VARCHAR2(1024);
    SORTIE                          EXCEPTION;

    n_Ret                          NUMBER;

/* *************************************************************** */
/* Lecture des Attendus dans la table BA_ATTENDUS_GEST            */
/*                                                                 */
/*      Export vers le fichier txt                                 */
/* *************************************************************** */
---- Modification Cursor pour  JIRA AER_ITFIN-49730
---- Ajout du champ Num_Compte_Comptable en fin du curseur

CURSOR Curseur_EXPORT IS

Select DATE_ARRETE,
       TYPE_RAPRO,
       SERVICE,
       SOCIETE,
       COMPTE_BANCAIRE,
       LIBELLE_COMPTE,
       DEVISE,
       DATE_OPERATION_SUSPENS,
       LIBELLE_SUSPENS,
       DEBIT,
       CREDIT,
       DECODE(DEBIT, null, CREDIT, DEBIT) AS CUMUL_DEBIT_CREDIT,
       SENS_ATTENDU,
       COTE_SUSPENS,
       ANCIENNETE_J,
       ANCIENNETE_M,
       BORNE_ANCIENNETE,
       PILIER_MONTANT_DEBIT,
       PILIER_MONTANT_CREDIT,
       DECODE(PILIER_MONTANT_DEBIT, null, PILIER_MONTANT_CREDIT, PILIER_MONTANT_DEBIT) AS PILIER_MNT_CUMUL_DEB_CDT,
       METHODE_PROVISION,
       TAUX,
       MONTANT_PROVISION,
       STATUT,
       DATE_APUREMENT,
       DC_MAX,  --V1.2
       PRIORITE,
          replace(replace(COMMENTAIRE,chr(10),'-'),chr(13),null) as COMMENTAIRE_BIS,
       NETTING,
       DELTA,
       SENS_DELTA,
       NUMERO_FICHE,
       DERNIER_STATUT,
       RECORD_ID,
       ANNOTE_LE,
       Num_Compte_Comptable -- AJOUT JIRA AER_ITFIN-49730
From  BA_ATTENDUS_GEST
order by SERVICE, SOCIETE, COMPTE_BANCAIRE, TO_DATE(DATE_OPERATION_SUSPENS, 'DD/MM/RRRR'), NETTING;

---- Fin Modification Cursor pour  JIRA AER_ITFIN-49730

-- Variables rÃ©ceptrices du curseur --
Enreg_Export   Curseur_Export%ROWTYPE;


SEPARATEUR_FLUX_SORTIE CHAR(1):=',';


BEGIN

DECLARE

n_Annee       NUMBER:=0;
n_Mois        NUMBER:=0;
n_Jour        NUMBER:=0;
nbr_enreg       NUMBER:=0;
w_taux          VARCHAR2(5);
w_montant_prov  VARCHAR2(18);
w_delta         VARCHAR2(20);  --V1.4


    BEGIN

    n_Mois       :=TO_NUMBER(NVL(substr(s_DateArrete,4,2),0));
        n_Jour       :=TO_NUMBER(NVL(substr(s_DateArrete,1,2),0));
        n_Annee      :=TO_NUMBER(NVL(substr(s_DateArrete,7,4),0));


    PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, 'Ecriture du fichier des Attendus - Gestion', 0, s_FONCTION);

   -- nom du fichier
   s_NomFic:='ACCURATE_A'||n_Annee||'_M'||n_Mois||'_J'||n_Jour||'_'||TO_CHAR(SYSDATE,'DD-MM-YYYY')||'_'||s_TypeRapro||'_BAATGS'||'.'||'txt';

     IF PKG_DTC.F_MAJ_INFO(gt_InfoTrait, 'FIC_DET_ATTENDU_GESTION', s_NomFic) = PKG_GLOBAL.GN_CR_OK THEN   --V1.1


        s_Ligne := ('DATE_ARRETE,TYPE_RAPRO,SERVICE,SOCIETE,COMPTE_BANCAIRE,LIBELLE_COMPTE,'||
                    'DEVISE,DATE_OPERATION_SUSPENS,LIBELLE_SUSPENS,DEBIT,CREDIT,CUMUL_DEBIT_CREDIT,SENS_ATTENDU,'||
                      'COTE_SUSPENS,ANCIENNETE_J,BORNE_ANCIENNETE,PILIER_MONTANT_DEBIT,PILIER_MONTANT_CREDIT,PILIER_MONTANT_CUMUL_DEBIT_CREDIT'||','||
                    'METHODE_PROVISION,NETTING,DELTA,SENS_DELTA,ID_ECRITURE,TAUX,'||
                    'MONTANT_PROVISION,DATE_APUREMENT,POST_ARRETE_DC_MAX,PRIORITE,COMMENTAIRE,NUMERO_FICHE,DERNIER_STATUT,RECORD_ID,ANNOTE_LE');  --V1.2


    insert into TraitementTableAttenduGestion
    select EXP_RNAPA.SEQ_ID_TRAITEMENTTABLEGestion.nextval, s_Ligne FROM Dual;


        FOR Enreg_EXPORT IN Curseur_EXPORT LOOP

        IF Enreg_EXPORT.TAUX != 0 THEN
           w_taux := to_char(Enreg_EXPORT.TAUX*100)||'%';
        ELSE
           w_taux := '-';
        END IF;


        IF Enreg_EXPORT.MONTANT_PROVISION != 0 THEN
          w_montant_prov := to_char(REPLACE(Enreg_EXPORT.MONTANT_PROVISION,'.',','));
        ELSE
           w_montant_prov := '-';
        END IF;

        -- V1.4
        IF Enreg_EXPORT.DELTA != 0 THEN
          w_delta := to_char(REPLACE(Enreg_EXPORT.DELTA,'.',','));
        ELSE
           w_delta := '';
        END IF;
        -- V1.4
---- Modification pour  JIRA AER_ITFIN-49730
---- Remplacement de l'avant derniere colonne RECORD_ID par Num_Compte_Comptable

    s_Ligne := (Enreg_EXPORT.DATE_ARRETE||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.TYPE_RAPRO||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.SERVICE||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.SOCIETE||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.COMPTE_BANCAIRE||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.LIBELLE_COMPTE||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.DEVISE||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.DATE_OPERATION_SUSPENS||SEPARATEUR_FLUX_SORTIE||
            '"'||Enreg_EXPORT.LIBELLE_SUSPENS||'"'||SEPARATEUR_FLUX_SORTIE||
            '"'||REPLACE(Enreg_EXPORT.DEBIT,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
            '"'||REPLACE(Enreg_EXPORT.CREDIT,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
            '"'||REPLACE(Enreg_EXPORT.CUMUL_DEBIT_CREDIT,'.',',')||'"'||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.SENS_ATTENDU||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.COTE_SUSPENS||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.ANCIENNETE_J||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.BORNE_ANCIENNETE||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.PILIER_MONTANT_DEBIT||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.PILIER_MONTANT_CREDIT||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.PILIER_MNT_CUMUL_DEB_CDT||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.METHODE_PROVISION||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.NETTING||SEPARATEUR_FLUX_SORTIE||
            '"'||w_delta||'"'||SEPARATEUR_FLUX_SORTIE|| --V1.4
            Enreg_EXPORT.SENS_DELTA||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.RECORD_ID||SEPARATEUR_FLUX_SORTIE||
            '"'||w_taux||'"'||SEPARATEUR_FLUX_SORTIE||
            '"'||w_montant_prov||'"'||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.DATE_APUREMENT||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.DC_MAX||SEPARATEUR_FLUX_SORTIE||   --V1.2
            Enreg_EXPORT.PRIORITE||SEPARATEUR_FLUX_SORTIE||
            '"'||Enreg_EXPORT.COMMENTAIRE_BIS||'"'||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.NUMERO_FICHE||SEPARATEUR_FLUX_SORTIE||
            Enreg_EXPORT.DERNIER_STATUT||SEPARATEUR_FLUX_SORTIE||
      Enreg_EXPORT.Num_Compte_Comptable||SEPARATEUR_FLUX_SORTIE||
      Enreg_EXPORT.ANNOTE_LE||SEPARATEUR_FLUX_SORTIE
            );
---- Modification pour  JIRA AER_ITFIN-49730
    insert into TraitementTableAttenduGestion
    select EXP_RNAPA.SEQ_ID_TRAITEMENTTABLEGestion.nextval, s_Ligne FROM Dual;

        END LOOP;

        -- nbr enreg total (-1 pour la ligne d'entÃªte)
         --nbr_enreg := SQL%ROWCOUNT;
         SELECT COUNT(*)-1 INTO nbr_enreg FROM TraitementTableAttenduGestion;

       IF PKG_TEC_FICHIERS.F_ECRIRECSV_CLOB(gt_InfoTrait,
                                        'FIC_DET_ATTENDU_GESTION',
                                        1,
                                        'SELECT valeur FROM TraitementTableAttenduGestion ORDER BY pos',
                                        s_NomFic,
                                        ',',
                                        'OUT_APPLI') = -1 THEN RAISE SORTIE;END IF;

--END;   --V1.1

    PKG_LOG.P_ECRIRE(gt_InfoTrait,
                     PKG_LOG.gt_LOG_TYPE_CPT,
             nbr_enreg||' lignes Ã©crites.',
             nbr_enreg,
             s_FONCTION);

    delete TraitementTableAttenduGestion;

    RETURN PKG_GLOBAL.gn_CR_OK;


  ELSE   --V1.1
    delete TraitementTableAttenduGestion;
    RETURN gn_CR_ERREUR;  --V1.1
  END IF;  --V1.1
 END;   --V1.1

EXCEPTION
    WHEN SORTIE THEN
      delete TraitementTableAttenduGestion;
      RETURN PKG_GLOBAL.gn_CR_KO;
    WHEN OTHERS THEN
    PKG_LOG.P_ECRIRE(gt_InfoTrait);
    delete TraitementTableAttenduGestion;
    RETURN PKG_GLOBAL.gn_CR_KO;

END F_Generation_BAATGS;

/******************************************************************************
   NOM        :       RUN
   OBJET      : Point d'entrÃ©e du package
   PARAMETRES : s_DateArrete                             -> Date d'arrete
                   s_TypeRapro                              -> Type de Rapprochement


   VERSIONS:
   Ver        Date        Auteur           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        05/06/2007   MMA              1. Creation
   1.1        17/02/2014   RPZ              ContrÃ¿le des erreurs fonctionnels
******************************************************************************/
FUNCTION RUN(
             t_InfoTrait PKG_GLOBAL.T_INFO_TRAITEMENT
)  RETURN NUMBER
IS
  s_DateArrete               VARCHAR2 (10) := '01/01/1970';
s_TypeRapro                VARCHAR2 (2) := 'RB';
s_TypeDate                 VARCHAR2 (1) := 'C';







    -- -------------------------------------------------------------------
    -- DECLARATION DES CONSTANTES
    -- -------------------------------------------------------------------

    -- Nom de la fonction courante
    s_FONCTION CONSTANT VARCHAR2(64):=
        gs_PACKAGE || '.' || 'RUN';

    -- -------------------------------------------------------------------
    -- DECLARATION DES VARIABLES
    -- -------------------------------------------------------------------


         -- Code retour
    n_Ret NUMBER:=PKG_GLOBAL.gn_CR_KO;

    -- Date/heure de dÃ©but du traitement
    d_Debut DATE:=NULL;

    ERREUR        EXCEPTION;
    ERREUR_FONCT  EXCEPTION;

    nbr_enreg NUMBER;


    n_Annee       NUMBER:=0;
    n_Mois        NUMBER:=0;
    n_Jour        NUMBER:=0;


BEGIN
        s_DateArrete := TO_CHAR(GET_DATE_ARRETE, 'dd/mm/yyyy');
        n_Mois       :=TO_NUMBER(NVL(substr(s_DateArrete,4,2),0));
        n_Jour       :=TO_NUMBER(NVL(substr(s_DateArrete,1,2),0));
        n_Annee      :=TO_NUMBER(NVL(substr(s_DateArrete,7,4),0));

        INSERT INTO t_info (SCRIPT_APP, CRITERE, VALEUR)
        VALUES ('RNADDEBAUTO01','Param_1', s_DateArrete);

        INSERT INTO t_info (SCRIPT_APP, CRITERE, VALEUR)
        VALUES ('RNADDEBAUTO01','Param_2', s_TypeRapro);

        INSERT INTO t_info (SCRIPT_APP, CRITERE, VALEUR)
        VALUES ('RNADDEBAUTO01','Param_3', s_TypeDate);


 -- Initaliser les informations sur le traitement en cours
    gt_InfoTrait:=t_InfoTrait;

    -- Tracer le dÃ©but du traitement
    PKG_LOG.P_ECRIRE(gt_InfoTrait,
                     PKG_LOG.gt_LOG_TYPE_DEB,
                     '--> GÃ©nÃ©ration du fichier de la base des attendus - Gestion ('||s_DateArrete||')',
                     0,
                     s_FONCTION);


-- contrÃ¿le du format des donnÃ©es DTC
    n_ret := F_Controle_DTC_Format(s_DateArrete,s_TypeRapro,s_TypeDate) ;  --  V1.3
    IF n_Ret != PKG_GLOBAL.gn_CR_OK THEN
       IF n_Ret = gn_CR_ERREUR_FONCT THEN --RPZ - 17/02/2014 - FMCP-3664
          RAISE ERREUR_FONCT;
       ELSE
          RAISE ERREUR;
       END IF;
    END IF;




-- Memoriser la date/heure de debut de traitement
    d_Debut := SYSDATE;

-- contrÃ¿le fonctionnel des donnÃ©es DTC
    n_ret := F_Controle_DTC(s_DateArrete,s_TypeRapro,s_TypeDate) ;  --  V1.3
    IF n_Ret != PKG_GLOBAL.gn_CR_OK THEN RAISE ERREUR; END IF;

    n_ret := F_Extraire_BAATGS(s_DateArrete,s_TypeRapro, nbr_enreg,s_TypeDate) ;  --  V1.3
    IF n_Ret != PKG_GLOBAL.gn_CR_OK THEN RAISE ERREUR; END IF;

-- ecriture du fichier seulement si le nombre d'enregistrements extraits est diffÃ©rent de zÃ©ro
    --IF nbr_enreg > 0 THEN --mis en commentaire le 26/11/2009 (NVE)
       n_ret := F_Generation_BAATGS(s_DateArrete,s_TypeRapro, s_TypeDate);  --  V1.3
       IF n_Ret != PKG_GLOBAL.gn_CR_OK THEN RAISE ERREUR; END IF;
    --ELSE
    IF nbr_enreg = 0 THEN
       PKG_LOG.P_ECRIRE(gt_InfoTrait,PKG_LOG.gt_LOG_TYPE_INF, '/!\...ATTENTION...,Aucune donnÃ©e extraite . Type Rapro : '||s_TypeRapro||' AnnÃ©e : ' ||n_Annee|| ' Mois: ' || n_mois|| ' Jour: ' || n_Jour , 0, s_FONCTION);
    END IF;

    -- Tracer la fin du traitement
    PKG_LOG.P_ECRIRE(gt_InfoTrait,
                     PKG_LOG.gt_LOG_TYPE_FIN,
                     '--> Fin GÃ©nÃ©ration de la base des attendus - Gestion '||
                     ' ('||PKG_DATE.date_diff (d_Debut, SYSDATE)||')',
                     0,
                     s_FONCTION);

    -- Retourner le resultat du traitement
    RETURN PKG_GLOBAL.gn_CR_OK;

EXCEPTION
   WHEN ERREUR THEN
      PKG_LOG.P_ECRIRE(gt_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, '/!\...ERREUR... Fin GÃ©nÃ©ration  Base des attendus Gestion ', 0, s_Fonction);
      RETURN gn_CR_ERREUR;
   WHEN ERREUR_FONCT THEN --RPZ - 17/02/2014 - FMCP-3664
      PKG_LOG.P_ECRIRE(gt_InfoTrait, PKG_LOG.gt_LOG_TYPE_ERR, '/!\...ERREUR... Fin GÃ©nÃ©ration  Base des attendus Compta ', 0, s_Fonction);
      RETURN gn_CR_ERREUR_FONCT; --RPZ - 17/02/2014 - FMCP-3664
   WHEN OTHERS THEN
      PKG_LOG.P_ECRIRE(gt_InfoTrait);
      RETURN PKG_GLOBAL.gn_CR_KO;
END RUN;


END PKG_RNADEXTAUTO01;