-- ============================================================================
-- AUDIT BR_DATA - Tracer l'origine des insertions
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Identifier quel script/package insère dans BANKREC.BR_DATA
-- ============================================================================

-- ============================================================================
-- ÉTAPE 1 : Créer la table de log d'audit
-- ============================================================================

CREATE TABLE AUDIT_BR_DATA_INSERTIONS (
    ID_AUDIT            NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    DATE_INSERTION      TIMESTAMP DEFAULT SYSTIMESTAMP,
    USERNAME            VARCHAR2(128),
    OSUSER              VARCHAR2(128),
    MACHINE             VARCHAR2(128),
    PROGRAM             VARCHAR2(128),
    MODULE              VARCHAR2(128),
    ACTION              VARCHAR2(128),
    CALL_STACK          VARCHAR2(4000),
    ERROR_STACK         VARCHAR2(4000),
    MONTANT             NUMBER,
    DESCRIPTION         VARCHAR2(500),
    LIGNE_COMPLETE      CLOB
);

COMMENT ON TABLE AUDIT_BR_DATA_INSERTIONS IS 'Audit des insertions dans BANKREC.BR_DATA';

-- Index pour recherche rapide
CREATE INDEX IDX_AUDIT_MONTANT ON AUDIT_BR_DATA_INSERTIONS(MONTANT);
CREATE INDEX IDX_AUDIT_DATE ON AUDIT_BR_DATA_INSERTIONS(DATE_INSERTION);

-- ============================================================================
-- ÉTAPE 2 : Créer le trigger d'audit sur BR_DATA
-- ============================================================================

CREATE OR REPLACE TRIGGER TRG_AUDIT_BR_DATA_INSERT
AFTER INSERT ON BANKREC.BR_DATA
FOR EACH ROW
DECLARE
    v_call_stack   VARCHAR2(4000);
    v_error_stack  VARCHAR2(4000);
    v_username     VARCHAR2(128);
    v_osuser       VARCHAR2(128);
    v_machine      VARCHAR2(128);
    v_program      VARCHAR2(128);
    v_module       VARCHAR2(128);
    v_action       VARCHAR2(128);
    v_montant      NUMBER;
    v_description  VARCHAR2(500);
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    -- Capturer la call stack (qui a appelé l'INSERT)
    BEGIN
        v_call_stack := DBMS_UTILITY.FORMAT_CALL_STACK;
    EXCEPTION
        WHEN OTHERS THEN
            v_call_stack := 'Erreur capture call stack: ' || SQLERRM;
    END;

    -- Capturer la error stack
    BEGIN
        v_error_stack := DBMS_UTILITY.FORMAT_ERROR_STACK;
    EXCEPTION
        WHEN OTHERS THEN
            v_error_stack := NULL;
    END;

    -- Récupérer les informations de session
    SELECT
        SYS_CONTEXT('USERENV', 'SESSION_USER'),
        SYS_CONTEXT('USERENV', 'OS_USER'),
        SYS_CONTEXT('USERENV', 'HOST'),
        SYS_CONTEXT('USERENV', 'MODULE'),
        SYS_CONTEXT('USERENV', 'ACTION')
    INTO v_username, v_osuser, v_machine, v_module, v_action
    FROM DUAL;

    -- Récupérer le program depuis V$SESSION
    BEGIN
        SELECT program INTO v_program
        FROM V$SESSION
        WHERE SID = SYS_CONTEXT('USERENV', 'SID')
          AND ROWNUM = 1;
    EXCEPTION
        WHEN OTHERS THEN
            v_program := 'N/A';
    END;

    -- Extraire le montant et description de BR_DATA
    BEGIN
        v_montant := :NEW.AMOUNT;
        v_description := 'ACCT_ID=' || :NEW.ACCT_ID ||
                        ' | NARRATIVE=' || SUBSTR(:NEW.NARRATIVE, 1, 100) ||
                        ' | INTL_REF=' || :NEW.INTL_REF ||
                        ' | EXTL_REF=' || :NEW.EXTL_REF ||
                        ' | TRANS_DATE=' || TO_CHAR(:NEW.TRANS_DATE, 'DD/MM/YYYY');
    EXCEPTION
        WHEN OTHERS THEN
            v_montant := NULL;
            v_description := 'Erreur extraction: ' || SQLERRM;
    END;

    -- Insérer dans la table d'audit
    INSERT INTO AUDIT_BR_DATA_INSERTIONS (
        DATE_INSERTION,
        USERNAME,
        OSUSER,
        MACHINE,
        PROGRAM,
        MODULE,
        ACTION,
        CALL_STACK,
        ERROR_STACK,
        MONTANT,
        DESCRIPTION,
        LIGNE_COMPLETE
    ) VALUES (
        SYSTIMESTAMP,
        v_username,
        v_osuser,
        v_machine,
        v_program,
        v_module,
        v_action,
        v_call_stack,
        v_error_stack,
        v_montant,
        v_description,
        'Voir BR_DATA directement'  -- On pourrait sérialiser toute la ligne en JSON
    );

    COMMIT;  -- Transaction autonome
EXCEPTION
    WHEN OTHERS THEN
        -- Ne pas bloquer l'insertion même si l'audit échoue
        NULL;
END;
/

-- ============================================================================
-- ÉTAPE 3 : Activer le trigger
-- ============================================================================

ALTER TRIGGER TRG_AUDIT_BR_DATA_INSERT ENABLE;

-- ============================================================================
-- ÉTAPE 4 : Requêtes pour analyser les résultats
-- ============================================================================

-- Après avoir relancé le traitement, exécuter ces requêtes :

-- 1. Voir toutes les insertions tracées (simple)
SELECT
    ID_AUDIT,
    TO_CHAR(DATE_INSERTION, 'DD/MM/YYYY HH24:MI:SS') AS DATE_INS,
    USERNAME,
    PROGRAM,
    MONTANT,
    SUBSTR(DESCRIPTION, 1, 100) AS INFO
FROM AUDIT_BR_DATA_INSERTIONS
ORDER BY DATE_INSERTION DESC;

-- 2. Voir avec call stack (détaillé)
SELECT
    ID_AUDIT,
    DATE_INSERTION,
    USERNAME,
    PROGRAM,
    MONTANT,
    DESCRIPTION,
    SUBSTR(CALL_STACK, 1, 200) AS CALL_STACK_DEBUT
FROM AUDIT_BR_DATA_INSERTIONS
ORDER BY DATE_INSERTION DESC;

-- 3. Voir UNIQUEMENT les insertions pour 22.36 et 2817
SELECT
    ID_AUDIT,
    TO_CHAR(DATE_INSERTION, 'DD/MM/YYYY HH24:MI:SS') AS DATE_INS,
    USERNAME,
    PROGRAM,
    MONTANT,
    DESCRIPTION,
    CALL_STACK
FROM AUDIT_BR_DATA_INSERTIONS
WHERE MONTANT IN (22.36, 2817, -22.36, -2817)
ORDER BY MONTANT DESC, DATE_INSERTION DESC;

-- 4. Extraire automatiquement le package/procédure source (MAGIC QUERY!)
SELECT
    'MONTANT: ' || MONTANT AS Transaction,
    REGEXP_SUBSTR(CALL_STACK, 'package body [^ ]+', 1, 1, 'i') AS Source_Package,
    REGEXP_SUBSTR(CALL_STACK, 'procedure [^ ]+', 1, 1, 'i') AS Source_Procedure,
    REGEXP_SUBSTR(CALL_STACK, 'line [0-9]+', 1, 1, 'i') AS Ligne_Code,
    PROGRAM,
    TO_CHAR(DATE_INSERTION, 'HH24:MI:SS') AS Heure,
    CALL_STACK
FROM AUDIT_BR_DATA_INSERTIONS
WHERE MONTANT IN (22.36, 2817)
ORDER BY MONTANT DESC;

-- ============================================================================
-- ÉTAPE 5 : Nettoyage (après analyse)
-- ============================================================================

-- Une fois l'analyse terminée, vous pouvez désactiver le trigger:
-- ALTER TRIGGER TRG_AUDIT_BR_DATA_INSERT DISABLE;

-- Et supprimer la table d'audit si besoin:
-- DROP TABLE AUDIT_BR_DATA_INSERTIONS;
-- DROP TRIGGER TRG_AUDIT_BR_DATA_INSERT;

-- ============================================================================
-- NOTES IMPORTANTES
-- ============================================================================
-- 1. Le trigger utilise PRAGMA AUTONOMOUS_TRANSACTION pour ne pas bloquer
--    l'insertion principale même si l'audit échoue
--
-- 2. Adapter les colonnes AMOUNT et DESCRIPTION selon la vraie structure de BR_DATA
--
-- 3. La CALL_STACK va montrer toute la pile d'appels, exemple:
--    ----- PL/SQL Call Stack -----
--      object      line  object
--      handle    number  name
--    0x7f1234    123  package body SCHEMA.PKG_IMPORT_BANQUE
--    0x7f5678    456  procedure SCHEMA.PROC_INTEGRATION
--
-- 4. Si BR_DATA est alimentée par un programme externe (Java, Python, etc.),
--    le PROGRAM montrera le nom du processus
-- ============================================================================
