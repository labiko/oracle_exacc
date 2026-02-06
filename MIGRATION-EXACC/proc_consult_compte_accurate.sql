-- ============================================================================
-- FONCTION TABLE : FN_CONSULT_COMPTE_ACCURATE
-- Description : Consulte les informations d'un compte ACCURATE avant modification
--
-- Paramètres :
--   p_num_compte_accurate  : (OBLIGATOIRE) Numéro du compte ACCURATE (ex: 'BBNP42304-EUR')
--   p_flag_actif           : (FACULTATIF) Filtrer par FLAG_ACTIF (O/N)
--   p_num_compte_comptable : (FACULTATIF) Filtrer par NUM_COMPTE_COMPTABLE
--   p_codes_societe        : (FACULTATIF) Filtrer par liste de codes société (séparés par virgule)
--
-- Retourne : Une table avec toutes les informations du compte
-- Usage : SELECT * FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE('BBNP42304-EUR'));
--
-- SCRIPT IDEMPOTENT : Peut être exécuté plusieurs fois sans erreur
-- ============================================================================

-- ============================================================================
-- ETAPE 1 : SUPPRESSION DES OBJETS EXISTANTS (bloc PL/SQL pour ignorer erreurs)
-- Ordre important : fonction -> table type -> row type
-- ============================================================================

-- 1.1 Supprimer la fonction si elle existe
BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE';
    DBMS_OUTPUT.PUT_LINE('Fonction FN_CONSULT_COMPTE_ACCURATE supprimée.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -4043 THEN -- ORA-04043: object does not exist
            DBMS_OUTPUT.PUT_LINE('Fonction FN_CONSULT_COMPTE_ACCURATE n''existe pas - OK');
        ELSE
            RAISE;
        END IF;
END;
/

-- 1.2 Supprimer le type TABLE si il existe
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE EXP_RNAPA.T_COMPTE_ACCURATE_TABLE';
    DBMS_OUTPUT.PUT_LINE('Type T_COMPTE_ACCURATE_TABLE supprimé.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -4043 THEN -- ORA-04043: object does not exist
            DBMS_OUTPUT.PUT_LINE('Type T_COMPTE_ACCURATE_TABLE n''existe pas - OK');
        ELSE
            RAISE;
        END IF;
END;
/

-- 1.3 Supprimer le type OBJECT si il existe
BEGIN
    EXECUTE IMMEDIATE 'DROP TYPE EXP_RNAPA.T_COMPTE_ACCURATE_ROW';
    DBMS_OUTPUT.PUT_LINE('Type T_COMPTE_ACCURATE_ROW supprimé.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -4043 THEN -- ORA-04043: object does not exist
            DBMS_OUTPUT.PUT_LINE('Type T_COMPTE_ACCURATE_ROW n''existe pas - OK');
        ELSE
            RAISE;
        END IF;
END;
/

-- ============================================================================
-- ETAPE 2 : CREATION DU TYPE OBJECT (structure d'une ligne)
-- ============================================================================
CREATE OR REPLACE TYPE EXP_RNAPA.T_COMPTE_ACCURATE_ROW AS OBJECT (
    ID_COMPTE_ACCURATE      NUMBER,
    GROUPEG                 VARCHAR2(200),
    FLAG_ACTIF              VARCHAR2(10),
    NUM_COMPTE_ACCURATE     VARCHAR2(100),
    LST_CODE_SOCIETE        VARCHAR2(4000),
    LST_CPT_COMPTABLE       VARCHAR2(4000),
    SOCIETE                 VARCHAR2(100),
    LIBELLE_COMPTE_COMPTABLE VARCHAR2(500),
    NOM_COMPTE_ACCURATE     VARCHAR2(200),
    TYPE_RAPPRO             VARCHAR2(50),
    METHODE                 VARCHAR2(100),
    COMPTE_BANCAIRE         VARCHAR2(100),
    NUM_COMPTE_COMPTABLE    VARCHAR2(100),
    BANQUE                  VARCHAR2(200),
    RIB                     VARCHAR2(100),
    RIB_ACCURATE            VARCHAR2(100),
    ID_COMPTE_BANCAIRE      NUMBER,
    BANQUE_ACTIF            VARCHAR2(10),
    NOM_COMPTE_BANCAIRE     VARCHAR2(200),
    ID_CPT_BANCAIRE_SYSTEME NUMBER,
    RCBS_RIB                VARCHAR2(100),
    TIERS                   VARCHAR2(100),
    GENERATION_CONTREPARTIE VARCHAR2(10),
    LST_SOUS_COMPTE         VARCHAR2(4000),
    ID_DEVISE               NUMBER,
    CODE_ISO_DEVISE         VARCHAR2(10),
    ACCOUNT_ID              NUMBER,
    LST_ID_CPT_ACCURATE     VARCHAR2(4000),
    BRANCHCODE              VARCHAR2(50),
    BANKCODE                VARCHAR2(50),
    IDENTIFICATION          VARCHAR2(100)
);
/

-- ============================================================================
-- ETAPE 3 : CREATION DU TYPE TABLE (collection)
-- ============================================================================
CREATE OR REPLACE TYPE EXP_RNAPA.T_COMPTE_ACCURATE_TABLE AS TABLE OF EXP_RNAPA.T_COMPTE_ACCURATE_ROW;
/

-- ============================================================================
-- ETAPE 4 : CREATION DE LA FONCTION PIPELINED
-- ============================================================================
CREATE OR REPLACE FUNCTION EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE (
    p_num_compte_accurate   IN VARCHAR2,
    p_flag_actif            IN VARCHAR2 DEFAULT NULL,
    p_num_compte_comptable  IN VARCHAR2 DEFAULT NULL,
    p_codes_societe         IN VARCHAR2 DEFAULT NULL
)
RETURN EXP_RNAPA.T_COMPTE_ACCURATE_TABLE PIPELINED
AS
BEGIN
    -- Validation paramètre obligatoire
    IF p_num_compte_accurate IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'ERREUR: Le paramètre p_num_compte_accurate est obligatoire.');
    END IF;

    FOR rec IN (
        SELECT
            RCA.ID_COMPTE_ACCURATE,
            G3.ACCT_NUM||'-'||G2.ACCT_NUM||'-'||G1.ACCT_NUM AS GROUPEG,
            RCA.FLAG_ACTIF,
            RCA.NUM_COMPTE_ACCURATE,
            LISTAGG(DISTINCT RS.CODE, ',') AS LST_CODE_SOCIETE,
            LISTAGG(DISTINCT RCC.Num_Compte_COMPTABLE, ',') AS LST_CPT_COMPTABLE,
            BCI.SOCIETE,
            BCI.LIBELLE_COMPTE_COMPTABLE,
            RCA.NOM AS NOM_COMPTE_ACCURATE,
            RCA.type_rappro AS TYPE_RAPPRO,
            BCM.METHODE,
            BCM.COMPTE_BANCAIRE,
            GCC.NUM_COMPTE_COMPTABLE,
            BCI.BANQUE,
            REPLACE(REPLACE(BCI.RIB,'/',''),' ','') AS RIB,
            BCI.RIB AS RIB_ACCURATE,
            RPB.ID_COMPTE_BANCAIRE,
            RPB.FLAG_ACTIF AS BANQUE_ACTIF,
            RCB.NOM AS NOM_COMPTE_BANCAIRE,
            RGA.id_compte_bancaire_systeme AS ID_CPT_BANCAIRE_SYSTEME,
            RCBS.RIB AS RCBS_RIB,
            RCBS.TIERS,
            RCBS.GENERATIONCONTREPARTIE AS GENERATION_CONTREPARTIE,
            LISTAGG(DISTINCT ANM.account_number, ',') AS LST_SOUS_COMPTE,
            RD.ID_DEVISE,
            RD.CODE_ISO_DEVISE,
            BCI.ACCOUNT_ID,
            LISTAGG(DISTINCT RCA.ID_COMPTE_ACCURATE, ',') AS LST_ID_CPT_ACCURATE,
            RCB.BRANCHCODE,
            RCB.BANKCODE,
            RCB.IDENTIFICATION
        FROM EXP_RNAPA.TA_RN_COMPTE_ACCURATE RCA
            LEFT JOIN BANKREC.bs_account_number_map ANM ON (RCA.NUM_COMPTE_ACCURATE||'-CB' = ANM.account_number OR RCA.NUM_COMPTE_ACCURATE||'-ST' = ANM.account_number)
            LEFT JOIN EXP_RNAPA.TA_RN_BC_INFOS BCI ON RCA.NUM_COMPTE_ACCURATE = BCI.compte_comptable
            LEFT JOIN EXP_RNAPA.TA_RN_COMPTA_ACCURATE CtaA ON CtaA.ID_COMPTE_ACCURATE = RCA.ID_COMPTE_ACCURATE
            LEFT JOIN EXP_RNAPA.TA_RN_PERIMETRE_COMPTA RPC ON RPC.ID_PERIMETRE_COMPTA = CtaA.ID_PERIMETRE_COMPTA
            LEFT JOIN EXP_RNAPA.TA_RN_BANQUE_ACCURATE RBA ON RBA.ID_COMPTE_ACCURATE = RCA.ID_COMPTE_ACCURATE
            LEFT JOIN EXP_RNAPA.TA_RN_PERIMETRE_BANQUE RPB ON RPB.ID_PERIMETRE_BANQUE = RBA.ID_PERIMETRE_BANQUE
            LEFT JOIN EXP_RNAPA.TA_RN_COMPTE_BANCAIRE RCB ON RCB.ID_COMPTE_BANCAIRE = RPB.ID_COMPTE_BANCAIRE
            LEFT JOIN EXP_RNAPA.TA_RN_COMPTE_COMPTABLE RCC ON RCC.ID_COMPTE_COMPTABLE = RPC.id_compte_comptable
            LEFT JOIN EXP_RNAPA.TA_RN_GESTION_ACCURATE RGA ON RGA.id_compte_accurate = RCA.ID_COMPTE_ACCURATE
            LEFT JOIN EXP_RNAPA.TA_RN_COMPTE_BANCAIRE_SYSTEME RCBS ON RCBS.id_compte_bancaire_systeme = RGA.id_compte_bancaire_systeme
            LEFT JOIN EXP_RNAPA.TA_RN_SOCIETE RS ON RPC.ID_SOCIETE = RS.ID_SOCIETE
            LEFT JOIN EXP_RNAPA.TA_RN_DEVISE RD ON RPC.ID_DEVISE = RD.ID_DEVISE
            LEFT JOIN EXP_RNAPA.BA_COMPTE_METHODE BCM ON RCA.NUM_COMPTE_ACCURATE = BCM.COMPTE_COMPTABLE
            LEFT JOIN EXP_RNAPA.TA_RN_GEST_COMPTE_COMPTABLE GCC ON GCC.COMPTE_BANCAIRE = BCM.COMPTE_BANCAIRE
            LEFT JOIN BANKREC.BRR_ACCOUNTS A ON BCI.ACCOUNT_ID = A.Account_ID
            LEFT JOIN BS_ACCTS G1 ON G1.ACCT_ID = A.ACCOUNT_GROUP
            LEFT JOIN BS_ACCTS G2 ON G2.ACCT_ID = G1.ACCT_GROUP
            LEFT JOIN BS_ACCTS G3 ON G3.ACCT_ID = G2.ACCT_GROUP
            LEFT JOIN BS_ACCTS G4 ON G4.ACCT_ID = G3.ACCT_GROUP
        WHERE RCA.NUM_COMPTE_ACCURATE = p_num_compte_accurate
            -- Filtre FLAG_ACTIF (si fourni)
            AND (p_flag_actif IS NULL OR RCA.FLAG_ACTIF = p_flag_actif)
            -- Filtre NUM_COMPTE_COMPTABLE (si fourni)
            AND (p_num_compte_comptable IS NULL OR GCC.NUM_COMPTE_COMPTABLE = p_num_compte_comptable)
            -- Filtre CODES_SOCIETE (si fourni)
            AND (p_codes_societe IS NULL OR RS.CODE IN (
                SELECT TRIM(REGEXP_SUBSTR(p_codes_societe, '[^,]+', 1, LEVEL))
                FROM DUAL
                CONNECT BY REGEXP_SUBSTR(p_codes_societe, '[^,]+', 1, LEVEL) IS NOT NULL
            ))
        GROUP BY
            RCA.ID_COMPTE_ACCURATE,
            (G3.ACCT_NUM||'-'||G2.ACCT_NUM||'-'||G1.ACCT_NUM),
            BCI.ACCOUNT_ID,
            BCI.SOCIETE,
            RCA.NUM_COMPTE_ACCURATE,
            BCI.LIBELLE_COMPTE_COMPTABLE,
            BCM.METHODE,
            BCM.COMPTE_BANCAIRE,
            GCC.NUM_COMPTE_COMPTABLE,
            RD.ID_DEVISE,
            RD.CODE_ISO_DEVISE,
            BCI.BANQUE,
            REPLACE(REPLACE(BCI.RIB,'/',''),' ',''),
            BCI.RIB,
            RCB.BRANCHCODE,
            RCB.BANKCODE,
            RCB.IDENTIFICATION,
            RCA.NOM,
            RCA.FLAG_ACTIF,
            RCA.type_rappro,
            RPB.ID_COMPTE_BANCAIRE,
            RPB.FLAG_ACTIF,
            RCB.NOM,
            RGA.id_compte_bancaire_systeme,
            RCBS.RIB,
            RCBS.TIERS,
            RCBS.GENERATIONCONTREPARTIE
        ORDER BY RCA.FLAG_ACTIF DESC, (G3.ACCT_NUM||'-'||G2.ACCT_NUM||'-'||G1.ACCT_NUM) DESC, RCA.NUM_COMPTE_ACCURATE
    ) LOOP
        PIPE ROW (EXP_RNAPA.T_COMPTE_ACCURATE_ROW(
            rec.ID_COMPTE_ACCURATE,
            rec.GROUPEG,
            rec.FLAG_ACTIF,
            rec.NUM_COMPTE_ACCURATE,
            rec.LST_CODE_SOCIETE,
            rec.LST_CPT_COMPTABLE,
            rec.SOCIETE,
            rec.LIBELLE_COMPTE_COMPTABLE,
            rec.NOM_COMPTE_ACCURATE,
            rec.TYPE_RAPPRO,
            rec.METHODE,
            rec.COMPTE_BANCAIRE,
            rec.NUM_COMPTE_COMPTABLE,
            rec.BANQUE,
            rec.RIB,
            rec.RIB_ACCURATE,
            rec.ID_COMPTE_BANCAIRE,
            rec.BANQUE_ACTIF,
            rec.NOM_COMPTE_BANCAIRE,
            rec.ID_CPT_BANCAIRE_SYSTEME,
            rec.RCBS_RIB,
            rec.TIERS,
            rec.GENERATION_CONTREPARTIE,
            rec.LST_SOUS_COMPTE,
            rec.ID_DEVISE,
            rec.CODE_ISO_DEVISE,
            rec.ACCOUNT_ID,
            rec.LST_ID_CPT_ACCURATE,
            rec.BRANCHCODE,
            rec.BANKCODE,
            rec.IDENTIFICATION
        ));
    END LOOP;

    RETURN;
END FN_CONSULT_COMPTE_ACCURATE;
/

-- ============================================================================
-- VERIFICATION DE LA COMPILATION
-- ============================================================================
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('FN_CONSULT_COMPTE_ACCURATE', 'T_COMPTE_ACCURATE_ROW', 'T_COMPTE_ACCURATE_TABLE');

-- ============================================================================
-- EXEMPLES D'UTILISATION
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exemple 1 : Consultation simple (paramètre obligatoire uniquement)
-- ----------------------------------------------------------------------------
-- SELECT * FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE('BBNP42304-EUR'));

-- ----------------------------------------------------------------------------
-- Exemple 2 : Consultation avec filtre FLAG_ACTIF = 'O' (comptes actifs)
-- ----------------------------------------------------------------------------
-- SELECT * FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE('BBNP42304-EUR', 'O'));

-- ----------------------------------------------------------------------------
-- Exemple 3 : Consultation avec filtre FLAG_ACTIF = 'N' (comptes inactifs)
-- ----------------------------------------------------------------------------
-- SELECT * FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE('BBNP42304-EUR', 'N'));

-- ----------------------------------------------------------------------------
-- Exemple 4 : Consultation avec filtre NUM_COMPTE_COMPTABLE
-- ----------------------------------------------------------------------------
-- SELECT * FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE('BBNP42304-EUR', NULL, '512100'));

-- ----------------------------------------------------------------------------
-- Exemple 5 : Consultation avec filtre sur un seul code société
-- ----------------------------------------------------------------------------
-- SELECT * FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE('BBNP42304-EUR', NULL, NULL, 'FR01'));

-- ----------------------------------------------------------------------------
-- Exemple 6 : Consultation avec filtre sur plusieurs codes société (liste)
-- ----------------------------------------------------------------------------
-- SELECT * FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE('BBNP42304-EUR', NULL, NULL, 'FR01,FR02,BE01'));

-- ----------------------------------------------------------------------------
-- Exemple 7 : Consultation avec tous les filtres combinés
-- ----------------------------------------------------------------------------
-- SELECT * FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE('BBNP42304-EUR', 'O', '512100', 'FR01,FR02'));

-- ----------------------------------------------------------------------------
-- Exemple 8 : Sélectionner uniquement certaines colonnes (avec ID_COMPTE_ACCURATE)
-- ----------------------------------------------------------------------------
-- SELECT ID_COMPTE_ACCURATE, NUM_COMPTE_ACCURATE, FLAG_ACTIF, SOCIETE, NUM_COMPTE_COMPTABLE, LST_CODE_SOCIETE
-- FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE('BBNP42304-EUR'));

-- ----------------------------------------------------------------------------
-- Exemple 9 : Utilisation avec paramètres nommés
-- ----------------------------------------------------------------------------
-- SELECT * FROM TABLE(EXP_RNAPA.FN_CONSULT_COMPTE_ACCURATE(
--     p_num_compte_accurate  => 'BBNP42304-EUR',
--     p_flag_actif           => 'O',
--     p_codes_societe        => 'FR01,FR02'
-- ));
