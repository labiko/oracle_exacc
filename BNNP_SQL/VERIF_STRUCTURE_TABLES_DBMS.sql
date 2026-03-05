-- ============================================================================
-- VERIFICATION STRUCTURE DES TABLES - VERSION DBMS_OUTPUT
-- ============================================================================
-- Date: 07/02/2025
-- Usage: Executez dans SQL Developer et copiez le resultat depuis l'onglet DBMS Output
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
DECLARE
    v_separator VARCHAR2(100) := RPAD('=', 80, '=');
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('VERIFICATION STRUCTURE DES TABLES - ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('');

    -- Liste des tables à analyser
    FOR table_rec IN (
        SELECT TABLE_NAME, NUM_ROWS, LAST_ANALYZED
        FROM USER_TABLES
        WHERE TABLE_NAME IN (
            'TA_RN_COMPTE_BANCAIRE',
            'TA_RN_COMPTE_ACCURATE',
            'TA_RN_GESTION_JC',
            'TA_RN_PRODUIT',
            'TA_RN_MODE_REGLEMENT',
            'TA_RN_PERIMETRE_BANQUE',
            'TA_RN_BANQUE_ACCURATE',
            'TA_RN_IMPORT_GESTION_JC',
            'TA_RN_EXPORT_JC'
        )
        ORDER BY TABLE_NAME
    ) LOOP
        v_count := v_count + 1;

        DBMS_OUTPUT.PUT_LINE(v_count || '. TABLE: ' || table_rec.TABLE_NAME);
        DBMS_OUTPUT.PUT_LINE('   Lignes: ' || NVL(TO_CHAR(table_rec.NUM_ROWS), 'N/A') ||
                           ' | Analysee: ' || NVL(TO_CHAR(table_rec.LAST_ANALYZED, 'DD/MM/YYYY'), 'N/A'));
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('-', 76, '-'));
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('COLONNE', 35) || RPAD('TYPE', 20) || RPAD('TAILLE', 10) || 'NULL?');
        DBMS_OUTPUT.PUT_LINE('   ' || RPAD('-', 76, '-'));

        -- Colonnes de la table
        FOR col_rec IN (
            SELECT
                COLUMN_NAME,
                DATA_TYPE,
                DATA_LENGTH,
                DATA_PRECISION,
                DATA_SCALE,
                NULLABLE
            FROM USER_TAB_COLUMNS
            WHERE TABLE_NAME = table_rec.TABLE_NAME
            ORDER BY COLUMN_ID
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('   ' ||
                RPAD(col_rec.COLUMN_NAME, 35) ||
                RPAD(col_rec.DATA_TYPE ||
                    CASE
                        WHEN col_rec.DATA_TYPE = 'NUMBER' AND col_rec.DATA_PRECISION IS NOT NULL
                        THEN '(' || col_rec.DATA_PRECISION ||
                             CASE WHEN col_rec.DATA_SCALE > 0 THEN ',' || col_rec.DATA_SCALE ELSE '' END || ')'
                        WHEN col_rec.DATA_TYPE IN ('VARCHAR2', 'CHAR')
                        THEN '(' || col_rec.DATA_LENGTH || ')'
                        ELSE ''
                    END, 20) ||
                RPAD(NVL(TO_CHAR(col_rec.DATA_LENGTH), '-'), 10) ||
                col_rec.NULLABLE
            );
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('RESUME - TOUTES LES TABLES TA_RN_*');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE(RPAD('TABLE_NAME', 40) || RPAD('NB_LIGNES', 15) || 'LAST_ANALYZED');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 75, '-'));

    FOR t IN (
        SELECT TABLE_NAME, NUM_ROWS, LAST_ANALYZED
        FROM USER_TABLES
        WHERE TABLE_NAME LIKE 'TA_RN_%'
        ORDER BY TABLE_NAME
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(t.TABLE_NAME, 40) ||
            RPAD(NVL(TO_CHAR(t.NUM_ROWS), 'N/A'), 15) ||
            NVL(TO_CHAR(t.LAST_ANALYZED, 'DD/MM/YYYY'), 'N/A')
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('FIN VERIFICATION - Total tables analysees: ' || v_count);
    DBMS_OUTPUT.PUT_LINE(v_separator);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERREUR: ' || SQLERRM);
END;
/
