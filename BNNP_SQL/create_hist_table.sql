-- =======================================================================
-- Script de creation de la table Traitement_EXTRAIT_COMPTA_HIST
-- Stocke l'historique des fichiers ExtraitComptaGene traites
-- =======================================================================
--
-- ATTENTION : Ce script correspond a la structure REELLE de la table
--             en production (EXP_VLAPA_I)
--
-- LANCEMENT :
--   sqlplus / as sysdba @create_hist_table.sql
--
-- =======================================================================

SET SERVEROUTPUT ON
SET ECHO ON

-- Connexion au schema
ALTER SESSION SET CURRENT_SCHEMA = EXP_VLAPA_I;

-- Suppression de la table si elle existe
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE Traitement_EXTRAIT_COMPTA_HIST CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE('Table Traitement_EXTRAIT_COMPTA_HIST supprimee.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Table Traitement_EXTRAIT_COMPTA_HIST n''existait pas.');
END;
/

-- Creation de la table (structure reelle)
CREATE TABLE Traitement_EXTRAIT_COMPTA_HIST (
    POS                 NUMBER,
    VALEUR              VARCHAR2(4000),
    FROM_DATETIME       VARCHAR2(50),
    TO_DATETIME         VARCHAR2(50),
    DATE_SUPPRESSION    DATE
);

-- Commentaires sur la table et les colonnes
COMMENT ON TABLE Traitement_EXTRAIT_COMPTA_HIST IS 'Historique des fichiers ExtraitComptaGene traites';
COMMENT ON COLUMN Traitement_EXTRAIT_COMPTA_HIST.POS IS 'Position/numero de ligne dans le fichier source';
COMMENT ON COLUMN Traitement_EXTRAIT_COMPTA_HIST.VALEUR IS 'Contenu XML (ligne ou fragment)';
COMMENT ON COLUMN Traitement_EXTRAIT_COMPTA_HIST.FROM_DATETIME IS 'Date debut extraction (format YYYY-MM-DDTHH:MI:SS)';
COMMENT ON COLUMN Traitement_EXTRAIT_COMPTA_HIST.TO_DATETIME IS 'Date fin extraction (format YYYY-MM-DDTHH:MI:SS)';
COMMENT ON COLUMN Traitement_EXTRAIT_COMPTA_HIST.DATE_SUPPRESSION IS 'Date/heure de suppression logique';

-- Index pour ameliorer les performances de recherche
CREATE INDEX IDX_HIST_FROM_DATETIME ON Traitement_EXTRAIT_COMPTA_HIST(FROM_DATETIME);
CREATE INDEX IDX_HIST_TO_DATETIME ON Traitement_EXTRAIT_COMPTA_HIST(TO_DATETIME);
CREATE INDEX IDX_HIST_DATE_SUPPRESSION ON Traitement_EXTRAIT_COMPTA_HIST(DATE_SUPPRESSION);

-- Verification table HIST
PROMPT === TABLE HIST CREEE ===
DESC Traitement_EXTRAIT_COMPTA_HIST;

-- =======================================================================
-- CREATION DU TRIGGER BEFORE DELETE
-- Archive les lignes supprimees de Traitement_EXTRAIT_COMPTA
-- vers Traitement_EXTRAIT_COMPTA_HIST
-- =======================================================================

CREATE OR REPLACE TRIGGER TRG_ARCHIVE_EXTRAIT_COMPTA
BEFORE DELETE ON EXP_VLAPA_I.Traitement_EXTRAIT_COMPTA
FOR EACH ROW
DECLARE
    v_from_dt VARCHAR2(30);
    v_to_dt   VARCHAR2(30);
BEGIN
    -- Extraire FromDateTime si present dans cette ligne
    v_from_dt := REGEXP_SUBSTR(:OLD.VALEUR, '<FromDateTime>([^<]+)</FromDateTime>', 1, 1, NULL, 1);

    -- Extraire ToDateTime si present dans cette ligne
    v_to_dt := REGEXP_SUBSTR(:OLD.VALEUR, '<ToDateTime>([^<]+)</ToDateTime>', 1, 1, NULL, 1);

    -- Inserer dans la table d'historique
    INSERT INTO EXP_VLAPA_I.Traitement_EXTRAIT_COMPTA_HIST (
        POS,
        VALEUR,
        FROM_DATETIME,
        TO_DATETIME,
        DATE_SUPPRESSION
    ) VALUES (
        :OLD.POS,
        :OLD.VALEUR,
        v_from_dt,
        v_to_dt,
        SYSDATE
    );
END;
/

-- Verification trigger
PROMPT === TRIGGER CREE ===
SELECT trigger_name, table_name, status
FROM user_triggers
WHERE trigger_name = 'TRG_ARCHIVE_EXTRAIT_COMPTA';

PROMPT === FIN DE CREATION ===
