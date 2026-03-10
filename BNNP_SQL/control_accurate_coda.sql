-- =======================================================================
-- Script de controle - Comptage des balises XML depuis table HIST
-- Meme format de sortie que le script KSH
-- =======================================================================
--
-- LANCEMENT (obligatoire avec 2 parametres) :
--
--   sqlplus -S / as sysdba @/home/oracle/control_accurate_coda.sql YYYYMMDD_DEBUT YYYYMMDD_FIN
--
-- EXEMPLES :
--   sqlplus -S / as sysdba @/home/oracle/control_accurate_coda.sql 20240112 20240113
--   sqlplus -S / as sysdba @/home/oracle/control_accurate_coda.sql 20250124 20250127
--   sqlplus -S / as sysdba @/home/oracle/control_accurate_coda.sql 20250301 20250302
--
-- PARAMETRES :
--   &1 = Date debut au format YYYYMMDD (ex: 20240112)
--   &2 = Date fin au format YYYYMMDD (ex: 20240113)
--
-- SORTIE :
--   Format identique au script KSH pour comparaison
--
-- MODIFICATION : Utilise FROM_DATETIME/TO_DATETIME au lieu de DATE_SUPPRESSION
--                pour filtrer les donnees (plusieurs extractions possibles par jour)
--
-- =======================================================================

-- Connexion au schema
ALTER SESSION SET CURRENT_SCHEMA = EXP_VLAPA_I;

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 200;
SET PAGESIZE 0;
SET FEEDBACK OFF;
SET HEADING OFF;
SET VERIFY OFF;

DECLARE
    -- =======================================================================
    -- PARAMETRES RECUS EN LIGNE DE COMMANDE
    -- =======================================================================
    v_date_debut_param  VARCHAR2(10) := '&1';  -- Format YYYYMMDD (parametre 1)
    v_date_fin_param    VARCHAR2(10) := '&2';  -- Format YYYYMMDD (parametre 2)

    -- Dates formatees pour recherche (format XML : YYYY-MM-DD)
    v_from_datetime_search VARCHAR2(20);
    v_to_datetime_search   VARCHAR2(20);

    -- Variables de comptage (meme que KSH)
    v_nb_mouvements     NUMBER := 0;
    v_nb_documents      NUMBER := 0;
    v_nb_societes       NUMBER := 0;
    v_total_valuedoc    NUMBER := 0;
    v_total_valuehome   NUMBER := 0;

    -- Variables de dates extraites du XML
    v_date_debut_xml    VARCHAR2(50);
    v_date_fin_xml      VARCHAR2(50);

    -- Verification structure
    v_flux_ouvert       NUMBER := 0;
    v_flux_ferme        NUMBER := 0;
    v_mvt_ouvert        NUMBER := 0;
    v_mvt_ferme         NUMBER := 0;

    -- Nombre de lignes dans HIST pour cette periode
    v_nb_lignes_hist    NUMBER := 0;

    -- Variables pour debug
    v_count_temp        NUMBER := 0;

BEGIN

    DBMS_OUTPUT.PUT_LINE('=======================================================================');
    DBMS_OUTPUT.PUT_LINE('DEBUT DU SCRIPT DE CONTROLE');
    DBMS_OUTPUT.PUT_LINE('=======================================================================');
    DBMS_OUTPUT.PUT_LINE('');

    -- =======================================================================
    -- LOG : Parametres recus
    -- =======================================================================
    DBMS_OUTPUT.PUT_LINE('[PARAM] Date debut param (YYYYMMDD) : ' || v_date_debut_param);
    DBMS_OUTPUT.PUT_LINE('[PARAM] Date fin param (YYYYMMDD)   : ' || v_date_fin_param);

    -- =======================================================================
    -- Conversion des dates au format XML (YYYY-MM-DD)
    -- =======================================================================
    v_from_datetime_search := SUBSTR(v_date_debut_param, 1, 4) || '-' ||
                              SUBSTR(v_date_debut_param, 5, 2) || '-' ||
                              SUBSTR(v_date_debut_param, 7, 2);

    v_to_datetime_search := SUBSTR(v_date_fin_param, 1, 4) || '-' ||
                            SUBSTR(v_date_fin_param, 5, 2) || '-' ||
                            SUBSTR(v_date_fin_param, 7, 2);

    DBMS_OUTPUT.PUT_LINE('[CONV]  FromDateTime recherche     : ' || v_from_datetime_search);
    DBMS_OUTPUT.PUT_LINE('[CONV]  ToDateTime recherche       : ' || v_to_datetime_search);
    DBMS_OUTPUT.PUT_LINE('');

    -- =======================================================================
    -- ETAPE 1 : Verification table HIST et comptage lignes pour cette plage
    -- =======================================================================
    DBMS_OUTPUT.PUT_LINE('[ETAPE 1] Verification donnees pour la plage de dates...');

    -- Compter les lignes qui correspondent a la plage de dates
    -- On utilise FROM_DATETIME et TO_DATETIME (pas DATE_SUPPRESSION)
    SELECT COUNT(*) INTO v_nb_lignes_hist
    FROM Traitement_EXTRAIT_COMPTA_HIST
    WHERE FROM_DATETIME LIKE v_from_datetime_search || '%'
       OR TO_DATETIME LIKE v_to_datetime_search || '%';

    DBMS_OUTPUT.PUT_LINE('[ETAPE 1] Lignes trouvees pour la plage : ' || v_nb_lignes_hist);

    IF v_nb_lignes_hist = 0 THEN
        -- Aucune ligne trouvee avec les colonnes FROM/TO_DATETIME
        -- Essayer de chercher dans la colonne VALEUR (fallback)
        SELECT COUNT(*) INTO v_nb_lignes_hist
        FROM Traitement_EXTRAIT_COMPTA_HIST
        WHERE VALEUR LIKE '%<FromDateTime>' || v_from_datetime_search || '%'
           OR VALEUR LIKE '%<ToDateTime>' || v_to_datetime_search || '%';

        DBMS_OUTPUT.PUT_LINE('[ETAPE 1] Lignes trouvees via VALEUR : ' || v_nb_lignes_hist);
    END IF;

    IF v_nb_lignes_hist = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[ERREUR] Aucune donnee trouvee pour :');
        DBMS_OUTPUT.PUT_LINE('[ERREUR]   FromDateTime=' || v_from_datetime_search);
        DBMS_OUTPUT.PUT_LINE('[ERREUR]   ToDateTime=' || v_to_datetime_search);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('[INFO] Extractions disponibles dans la table :');

        FOR rec IN (
            SELECT DISTINCT
                FROM_DATETIME,
                TO_DATETIME,
                DATE_SUPPRESSION,
                COUNT(*) OVER (PARTITION BY FROM_DATETIME, TO_DATETIME) AS nb_lignes
            FROM Traitement_EXTRAIT_COMPTA_HIST
            WHERE FROM_DATETIME IS NOT NULL OR TO_DATETIME IS NOT NULL
            ORDER BY DATE_SUPPRESSION DESC
            FETCH FIRST 10 ROWS ONLY
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('[INFO]   FROM=' || rec.FROM_DATETIME ||
                                 ' | TO=' || rec.TO_DATETIME ||
                                 ' | Nb=' || rec.nb_lignes ||
                                 ' | Archive=' || TO_CHAR(rec.DATE_SUPPRESSION, 'DD/MM/YYYY HH24:MI:SS'));
        END LOOP;
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('[ETAPE 1] Nb lignes dans le lot : ' || v_nb_lignes_hist);

    -- =======================================================================
    -- ETAPE 2 : Extraire les dates FromDateTime / ToDateTime
    -- =======================================================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('[ETAPE 2] Extraction des dates du XML...');

    BEGIN
        SELECT FROM_DATETIME
        INTO v_date_debut_xml
        FROM Traitement_EXTRAIT_COMPTA_HIST
        WHERE FROM_DATETIME LIKE v_from_datetime_search || '%'
          AND ROWNUM = 1;

        DBMS_OUTPUT.PUT_LINE('[ETAPE 2] FromDateTime extrait : ' || v_date_debut_xml);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Fallback : chercher dans VALEUR
            BEGIN
                SELECT REGEXP_SUBSTR(VALEUR, '<FromDateTime>([^<]+)</FromDateTime>', 1, 1, NULL, 1)
                INTO v_date_debut_xml
                FROM Traitement_EXTRAIT_COMPTA_HIST
                WHERE VALEUR LIKE '%<FromDateTime>' || v_from_datetime_search || '%'
                  AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_date_debut_xml := v_from_datetime_search || 'T04:00:00';
            END;
            DBMS_OUTPUT.PUT_LINE('[ETAPE 2] FromDateTime (fallback) : ' || v_date_debut_xml);
    END;

    BEGIN
        SELECT TO_DATETIME
        INTO v_date_fin_xml
        FROM Traitement_EXTRAIT_COMPTA_HIST
        WHERE TO_DATETIME LIKE v_to_datetime_search || '%'
          AND ROWNUM = 1;

        DBMS_OUTPUT.PUT_LINE('[ETAPE 2] ToDateTime extrait   : ' || v_date_fin_xml);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Fallback : chercher dans VALEUR
            BEGIN
                SELECT REGEXP_SUBSTR(VALEUR, '<ToDateTime>([^<]+)</ToDateTime>', 1, 1, NULL, 1)
                INTO v_date_fin_xml
                FROM Traitement_EXTRAIT_COMPTA_HIST
                WHERE VALEUR LIKE '%<ToDateTime>' || v_to_datetime_search || '%'
                  AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_date_fin_xml := v_to_datetime_search || 'T04:00:00';
            END;
            DBMS_OUTPUT.PUT_LINE('[ETAPE 2] ToDateTime (fallback) : ' || v_date_fin_xml);
    END;

    -- =======================================================================
    -- ETAPE 3 : Comptage des balises (meme logique que KSH)
    -- Filtre par FROM_DATETIME et TO_DATETIME
    -- =======================================================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('[ETAPE 3] Comptage des balises XML...');

    SELECT
        NVL(SUM(REGEXP_COUNT(VALEUR, '<MouvementComptable>')), 0),
        NVL(SUM(REGEXP_COUNT(VALEUR, '<DocumentComptable>')), 0),
        NVL(SUM(REGEXP_COUNT(VALEUR, '<Statement>')), 0)
    INTO v_nb_mouvements, v_nb_documents, v_nb_societes
    FROM Traitement_EXTRAIT_COMPTA_HIST
    WHERE FROM_DATETIME LIKE v_from_datetime_search || '%'
       OR TO_DATETIME LIKE v_to_datetime_search || '%'
       OR (FROM_DATETIME IS NULL AND TO_DATETIME IS NULL
           AND EXISTS (
               SELECT 1 FROM Traitement_EXTRAIT_COMPTA_HIST h2
               WHERE h2.FROM_DATETIME LIKE v_from_datetime_search || '%'
           ));

    DBMS_OUTPUT.PUT_LINE('[ETAPE 3] NB_MOUVEMENTS : ' || v_nb_mouvements);
    DBMS_OUTPUT.PUT_LINE('[ETAPE 3] NB_DOCUMENTS  : ' || v_nb_documents);
    DBMS_OUTPUT.PUT_LINE('[ETAPE 3] NB_SOCIETES   : ' || v_nb_societes);

    -- =======================================================================
    -- ETAPE 4 : Somme des montants (OperationAmount / HomeAmount)
    -- =======================================================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('[ETAPE 4] Calcul des totaux montants...');

    -- Compter lignes avec OperationAmount
    SELECT COUNT(*) INTO v_count_temp
    FROM Traitement_EXTRAIT_COMPTA_HIST
    WHERE VALEUR LIKE '%<OperationAmount%'
      AND (FROM_DATETIME LIKE v_from_datetime_search || '%'
           OR TO_DATETIME LIKE v_to_datetime_search || '%'
           OR (FROM_DATETIME IS NULL AND TO_DATETIME IS NULL));

    DBMS_OUTPUT.PUT_LINE('[ETAPE 4] Lignes avec OperationAmount : ' || v_count_temp);

    SELECT
        NVL(ROUND(SUM(TO_NUMBER(
            REGEXP_SUBSTR(VALEUR, '<OperationAmount[^>]*>([^<]+)</OperationAmount>', 1, 1, NULL, 1)
        )), 2), 0)
    INTO v_total_valuedoc
    FROM Traitement_EXTRAIT_COMPTA_HIST
    WHERE VALEUR LIKE '%<OperationAmount%'
      AND (FROM_DATETIME LIKE v_from_datetime_search || '%'
           OR TO_DATETIME LIKE v_to_datetime_search || '%'
           OR (FROM_DATETIME IS NULL AND TO_DATETIME IS NULL));

    DBMS_OUTPUT.PUT_LINE('[ETAPE 4] TOTAL_VALUEDOC : ' || v_total_valuedoc);

    -- Compter lignes avec HomeAmount
    SELECT COUNT(*) INTO v_count_temp
    FROM Traitement_EXTRAIT_COMPTA_HIST
    WHERE VALEUR LIKE '%<HomeAmount%'
      AND (FROM_DATETIME LIKE v_from_datetime_search || '%'
           OR TO_DATETIME LIKE v_to_datetime_search || '%'
           OR (FROM_DATETIME IS NULL AND TO_DATETIME IS NULL));

    DBMS_OUTPUT.PUT_LINE('[ETAPE 4] Lignes avec HomeAmount : ' || v_count_temp);

    SELECT
        NVL(ROUND(SUM(TO_NUMBER(
            REGEXP_SUBSTR(VALEUR, '<HomeAmount[^>]*>([^<]+)</HomeAmount>', 1, 1, NULL, 1)
        )), 2), 0)
    INTO v_total_valuehome
    FROM Traitement_EXTRAIT_COMPTA_HIST
    WHERE VALEUR LIKE '%<HomeAmount%'
      AND (FROM_DATETIME LIKE v_from_datetime_search || '%'
           OR TO_DATETIME LIKE v_to_datetime_search || '%'
           OR (FROM_DATETIME IS NULL AND TO_DATETIME IS NULL));

    DBMS_OUTPUT.PUT_LINE('[ETAPE 4] TOTAL_VALUEHOME : ' || v_total_valuehome);

    -- =======================================================================
    -- ETAPE 5 : Verification structure XML
    -- =======================================================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('[ETAPE 5] Verification structure XML...');

    SELECT
        NVL(SUM(CASE WHEN VALEUR LIKE '%<Flux>%' THEN 1 ELSE 0 END), 0),
        NVL(SUM(CASE WHEN VALEUR LIKE '%</Flux>%' THEN 1 ELSE 0 END), 0),
        NVL(SUM(REGEXP_COUNT(VALEUR, '<MouvementComptable>')), 0),
        NVL(SUM(REGEXP_COUNT(VALEUR, '</MouvementComptable>')), 0)
    INTO v_flux_ouvert, v_flux_ferme, v_mvt_ouvert, v_mvt_ferme
    FROM Traitement_EXTRAIT_COMPTA_HIST
    WHERE FROM_DATETIME LIKE v_from_datetime_search || '%'
       OR TO_DATETIME LIKE v_to_datetime_search || '%'
       OR (FROM_DATETIME IS NULL AND TO_DATETIME IS NULL);

    DBMS_OUTPUT.PUT_LINE('[ETAPE 5] Balises <Flux> ouvertes  : ' || v_flux_ouvert);
    DBMS_OUTPUT.PUT_LINE('[ETAPE 5] Balises </Flux> fermees  : ' || v_flux_ferme);
    DBMS_OUTPUT.PUT_LINE('[ETAPE 5] Balises <MouvementComptable> ouvertes  : ' || v_mvt_ouvert);
    DBMS_OUTPUT.PUT_LINE('[ETAPE 5] Balises </MouvementComptable> fermees : ' || v_mvt_ferme);

    -- =======================================================================
    -- AFFICHAGE FORMAT KSH (identique au fichier de controle)
    -- =======================================================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=======================================================================');
    DBMS_OUTPUT.PUT_LINE('RESULTAT FINAL (format KSH)');
    DBMS_OUTPUT.PUT_LINE('=======================================================================');
    DBMS_OUTPUT.PUT_LINE('# Fichier de controle - Extrait Compta CODA');
    DBMS_OUTPUT.PUT_LINE('# Source: Table Traitement_EXTRAIT_COMPTA_HIST');
    DBMS_OUTPUT.PUT_LINE('# Plage: FROM=' || v_from_datetime_search || ' TO=' || v_to_datetime_search);
    DBMS_OUTPUT.PUT_LINE('#');
    DBMS_OUTPUT.PUT_LINE('DATE_DEBUT=' || REPLACE(v_date_debut_xml, 'T', ' '));
    DBMS_OUTPUT.PUT_LINE('DATE_FIN=' || REPLACE(v_date_fin_xml, 'T', ' '));
    DBMS_OUTPUT.PUT_LINE('DATE_GENERATION=' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('#');
    DBMS_OUTPUT.PUT_LINE('NB_MOUVEMENTS=' || v_nb_mouvements);
    DBMS_OUTPUT.PUT_LINE('NB_DOCUMENTS=' || v_nb_documents);
    DBMS_OUTPUT.PUT_LINE('NB_SOCIETES=' || v_nb_societes);
    DBMS_OUTPUT.PUT_LINE('TOTAL_VALUEDOC=' || TRIM(TO_CHAR(v_total_valuedoc, '999999999999.99')));
    DBMS_OUTPUT.PUT_LINE('TOTAL_VALUEHOME=' || TRIM(TO_CHAR(v_total_valuehome, '999999999999.99')));

    -- Verification structure
    DBMS_OUTPUT.PUT_LINE('#');
    DBMS_OUTPUT.PUT_LINE('# VERIFICATION STRUCTURE XML');
    IF v_flux_ouvert > 0 AND v_flux_ferme > 0 THEN
        DBMS_OUTPUT.PUT_LINE('STRUCTURE_FLUX=OK');
    ELSE
        DBMS_OUTPUT.PUT_LINE('STRUCTURE_FLUX=ERREUR (ouvert=' || v_flux_ouvert || ', ferme=' || v_flux_ferme || ')');
    END IF;

    IF v_mvt_ouvert = v_mvt_ferme THEN
        DBMS_OUTPUT.PUT_LINE('STRUCTURE_MVT=OK (' || v_mvt_ouvert || ' balises)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('STRUCTURE_MVT=ERREUR (ouvert=' || v_mvt_ouvert || ', ferme=' || v_mvt_ferme || ')');
    END IF;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=======================================================================');
    DBMS_OUTPUT.PUT_LINE('FIN DU SCRIPT DE CONTROLE');
    DBMS_OUTPUT.PUT_LINE('=======================================================================');

END;
/
EXIT
