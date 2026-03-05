-- ============================================================================
-- CHERCHER DANS TOUTES LES TABLES - PAYMENTREFERENCE de 22.36 vs 2817
-- ============================================================================
-- Date: 07/02/2026
-- Objectif: Scanner TOUTES les tables pour trouver où le PAYMENTREFERENCE
--           de 22.36 est présent mais pas celui de 2817
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
    v_paymentref_22 VARCHAR2(128);
    v_paymentref_2817 VARCHAR2(128);
    v_sql VARCHAR2(4000);
    v_count_22 NUMBER;
    v_count_2817 NUMBER;
    v_separator VARCHAR2(100) := RPAD('=', 80, '=');
    v_table_found BOOLEAN := FALSE;

BEGIN
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('RECHERCHE PAYMENTREFERENCE DANS TOUTES LES TABLES');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('');

    -- Récupérer les PAYMENTREFERENCE
    BEGIN
        SELECT PAYMENTREFERENCE INTO v_paymentref_22
        FROM TA_RN_IMPORT_GESTION_JC
        WHERE OPERATIONNETAMOUNT = '22.36' AND ROWNUM = 1;

        DBMS_OUTPUT.PUT_LINE('✅ PAYMENTREFERENCE 22.36  : ' || v_paymentref_22);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('❌ ERREUR: Transaction 22.36 non trouvée dans TA_RN_IMPORT_GESTION_JC');
            RETURN;
    END;

    BEGIN
        SELECT PAYMENTREFERENCE INTO v_paymentref_2817
        FROM TA_RN_IMPORT_GESTION_JC
        WHERE OPERATIONNETAMOUNT = '2817' AND ROWNUM = 1;

        DBMS_OUTPUT.PUT_LINE('✅ PAYMENTREFERENCE 2817   : ' || v_paymentref_2817);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('❌ ERREUR: Transaction 2817 non trouvée dans TA_RN_IMPORT_GESTION_JC');
            RETURN;
    END;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('SCAN DES TABLES DU SCHÉMA COURANT');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('');

    -- Scanner toutes les tables du schéma avec des colonnes VARCHAR2
    FOR table_rec IN (
        SELECT DISTINCT TABLE_NAME
        FROM USER_TAB_COLUMNS
        WHERE DATA_TYPE IN ('VARCHAR2', 'CHAR')
          AND TABLE_NAME NOT LIKE 'BIN$%'  -- Exclure la corbeille
          AND TABLE_NAME NOT LIKE '%$%'     -- Exclure les tables système
        ORDER BY TABLE_NAME
    ) LOOP

        v_count_22 := 0;
        v_count_2817 := 0;
        v_table_found := FALSE;

        -- Pour chaque colonne VARCHAR2 de la table
        FOR col_rec IN (
            SELECT COLUMN_NAME
            FROM USER_TAB_COLUMNS
            WHERE TABLE_NAME = table_rec.TABLE_NAME
              AND DATA_TYPE IN ('VARCHAR2', 'CHAR')
            ORDER BY COLUMN_ID
        ) LOOP

            -- Chercher PAYMENTREFERENCE 22.36
            BEGIN
                v_sql := 'SELECT COUNT(*) FROM ' || table_rec.TABLE_NAME ||
                        ' WHERE ' || col_rec.COLUMN_NAME || ' = :1';
                EXECUTE IMMEDIATE v_sql INTO v_count_22 USING v_paymentref_22;

                IF v_count_22 > 0 THEN
                    v_table_found := TRUE;
                    EXIT;  -- Trouvé, pas besoin de chercher dans d'autres colonnes
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;  -- Ignorer les erreurs (table verrouillée, etc.)
            END;
        END LOOP;

        -- Si trouvé dans cette table, chercher aussi 2817
        IF v_table_found THEN
            FOR col_rec IN (
                SELECT COLUMN_NAME
                FROM USER_TAB_COLUMNS
                WHERE TABLE_NAME = table_rec.TABLE_NAME
                  AND DATA_TYPE IN ('VARCHAR2', 'CHAR')
                ORDER BY COLUMN_ID
            ) LOOP

                BEGIN
                    v_sql := 'SELECT COUNT(*) FROM ' || table_rec.TABLE_NAME ||
                            ' WHERE ' || col_rec.COLUMN_NAME || ' = :1';
                    EXECUTE IMMEDIATE v_sql INTO v_count_2817 USING v_paymentref_2817;

                    IF v_count_2817 > 0 THEN
                        EXIT;
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            END LOOP;

            -- Afficher le résultat
            IF v_count_22 > 0 AND v_count_2817 > 0 THEN
                DBMS_OUTPUT.PUT_LINE('✅ ' || RPAD(table_rec.TABLE_NAME, 30) ||
                                   ' → LES DEUX PRÉSENTES');
            ELSIF v_count_22 > 0 THEN
                DBMS_OUTPUT.PUT_LINE('🔴 ' || RPAD(table_rec.TABLE_NAME, 30) ||
                                   ' → SEULEMENT 22.36 ⚠️ PROBLÈME ICI!');
            ELSIF v_count_2817 > 0 THEN
                DBMS_OUTPUT.PUT_LINE('🔵 ' || RPAD(table_rec.TABLE_NAME, 30) ||
                                   ' → SEULEMENT 2817');
            END IF;
        END IF;

    END LOOP;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('SCAN DES TABLES BANKREC (si accès)');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('');

    -- Scanner les tables BANKREC si accès disponible
    BEGIN
        FOR table_rec IN (
            SELECT DISTINCT TABLE_NAME
            FROM ALL_TAB_COLUMNS
            WHERE OWNER = 'BANKREC'
              AND DATA_TYPE IN ('VARCHAR2', 'CHAR', 'NUMBER')
              AND TABLE_NAME LIKE 'BR_%'
            ORDER BY TABLE_NAME
        ) LOOP

            v_count_22 := 0;
            v_count_2817 := 0;
            v_table_found := FALSE;

            -- Chercher dans toutes les colonnes
            FOR col_rec IN (
                SELECT COLUMN_NAME
                FROM ALL_TAB_COLUMNS
                WHERE OWNER = 'BANKREC'
                  AND TABLE_NAME = table_rec.TABLE_NAME
                  AND DATA_TYPE IN ('VARCHAR2', 'CHAR')
                ORDER BY COLUMN_ID
            ) LOOP

                BEGIN
                    v_sql := 'SELECT COUNT(*) FROM BANKREC.' || table_rec.TABLE_NAME ||
                            ' WHERE ' || col_rec.COLUMN_NAME || ' = :1';
                    EXECUTE IMMEDIATE v_sql INTO v_count_22 USING v_paymentref_22;

                    IF v_count_22 > 0 THEN
                        v_table_found := TRUE;

                        -- Chercher aussi 2817
                        EXECUTE IMMEDIATE v_sql INTO v_count_2817 USING v_paymentref_2817;
                        EXIT;
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            END LOOP;

            IF v_table_found THEN
                IF v_count_22 > 0 AND v_count_2817 > 0 THEN
                    DBMS_OUTPUT.PUT_LINE('✅ BANKREC.' || RPAD(table_rec.TABLE_NAME, 25) ||
                                       ' → LES DEUX PRÉSENTES');
                ELSIF v_count_22 > 0 THEN
                    DBMS_OUTPUT.PUT_LINE('🔴 BANKREC.' || RPAD(table_rec.TABLE_NAME, 25) ||
                                       ' → SEULEMENT 22.36 ⚠️ PROBLÈME ICI!');
                ELSIF v_count_2817 > 0 THEN
                    DBMS_OUTPUT.PUT_LINE('🔵 BANKREC.' || RPAD(table_rec.TABLE_NAME, 25) ||
                                       ' → SEULEMENT 2817');
                END IF;
            END IF;

        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('⚠️  Erreur accès schéma BANKREC: ' || SQLERRM);
    END;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ');
    DBMS_OUTPUT.PUT_LINE(v_separator);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Les tables marquées 🔴 contiennent SEULEMENT 22.36');
    DBMS_OUTPUT.PUT_LINE('→ Ces tables sont le POINT DE FILTRAGE que nous cherchons!');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Prochaine étape :');
    DBMS_OUTPUT.PUT_LINE('1. Identifier le script SQL qui INSERT dans cette table');
    DBMS_OUTPUT.PUT_LINE('2. Analyser la condition WHERE de ce INSERT');
    DBMS_OUTPUT.PUT_LINE('3. Comprendre pourquoi 2817 est filtré');

END;
/

PROMPT
PROMPT ============================================================================
PROMPT VÉRIFICATION MANUELLE - Tables spécifiques
PROMPT ============================================================================

-- Vérifier manuellement les tables clés
PROMPT Table: TA_RN_IMPORT_GESTION_JC

SELECT
    'TA_RN_IMPORT_GESTION_JC' AS TABLE_NAME,
    OPERATIONNETAMOUNT AS MONTANT,
    PAYMENTREFERENCE,
    COUNT(*) AS NB_LIGNES
FROM TA_RN_IMPORT_GESTION_JC
WHERE OPERATIONNETAMOUNT IN ('22.36', '2817')
GROUP BY OPERATIONNETAMOUNT, PAYMENTREFERENCE
ORDER BY OPERATIONNETAMOUNT DESC;

PROMPT
PROMPT Table: TA_RN_EXPORT_JC

SELECT
    'TA_RN_EXPORT_JC' AS TABLE_NAME,
    ORAMT AS MONTANT,
    INTREF AS PAYMENTREFERENCE,
    COUNT(*) AS NB_LIGNES
FROM TA_RN_EXPORT_JC
WHERE ORAMT IN ('22.36', '2817')
GROUP BY ORAMT, INTREF
ORDER BY ORAMT DESC;

PROMPT
PROMPT Table: BANKREC.BR_DATA (recherche par montant)

SELECT
    'BANKREC.BR_DATA' AS TABLE_NAME,
    AMOUNT AS MONTANT,
    INTL_REF,
    EXTL_REF,
    COUNT(*) AS NB_LIGNES
FROM BANKREC.BR_DATA
WHERE AMOUNT IN (22.36, 2817, -22.36, -2817)
GROUP BY AMOUNT, INTL_REF, EXTL_REF
ORDER BY AMOUNT DESC;

PROMPT
PROMPT ============================================================================
PROMPT FIN DE L'ANALYSE
PROMPT ============================================================================
