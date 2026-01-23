-- ============================================================================
-- PROCEDURE : SP_UPDATE_COMPTE_ACCURATE
-- Description : Met à jour les informations d'un compte ACCURATE
-- Paramètres :
--   p_num_compte_accurate  : Numéro du compte ACCURATE (ex: 'BBNP42304-EUR') - OBLIGATOIRE
--   p_id_compte_accurate   : ID du compte ACCURATE (facultatif) - Si spécifié, filtre supplémentaire
--   p_flag_actif           : Flag actif O/N (nullable)
--   p_num_compte_comptable : Numéro compte comptable (nullable)
--   p_codes_societe        : Liste des codes société séparés par virgule (nullable)
--
-- SCRIPT IDEMPOTENT : Peut être exécuté plusieurs fois sans erreur
-- ============================================================================

-- ============================================================================
-- ETAPE 1 : SUPPRESSION DE LA PROCEDURE SI ELLE EXISTE
-- ============================================================================
BEGIN
    EXECUTE IMMEDIATE 'DROP PROCEDURE EXP_RNAPA.SP_UPDATE_COMPTE_ACCURATE';
    DBMS_OUTPUT.PUT_LINE('Procédure SP_UPDATE_COMPTE_ACCURATE supprimée.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -4043 THEN -- ORA-04043: object does not exist
            DBMS_OUTPUT.PUT_LINE('Procédure SP_UPDATE_COMPTE_ACCURATE n''existe pas - OK');
        ELSE
            RAISE;
        END IF;
END;
/

-- ============================================================================
-- ETAPE 2 : CREATION DE LA PROCEDURE
-- ============================================================================
CREATE OR REPLACE PROCEDURE EXP_RNAPA.SP_UPDATE_COMPTE_ACCURATE (
    p_num_compte_accurate   IN VARCHAR2,
    p_id_compte_accurate    IN NUMBER   DEFAULT NULL,
    p_flag_actif            IN VARCHAR2 DEFAULT NULL,
    p_num_compte_comptable  IN VARCHAR2 DEFAULT NULL,
    p_codes_societe         IN VARCHAR2 DEFAULT NULL
)
AS
    v_count                 NUMBER := 0;
    v_id_compte_accurate    NUMBER;
    v_compte_bancaire       VARCHAR2(100);
    v_code_societe          VARCHAR2(50);
    v_position              NUMBER;
    v_codes_restants        VARCHAR2(4000);
    v_rows_updated          NUMBER := 0;
BEGIN
    -- =========================================================================
    -- VALIDATION : Vérifier que le compte ACCURATE existe
    -- =========================================================================
    IF p_id_compte_accurate IS NOT NULL THEN
        -- Si ID spécifié, vérifier avec ID + NUM_COMPTE
        SELECT COUNT(*)
        INTO v_count
        FROM EXP_RNAPA.TA_RN_COMPTE_ACCURATE RCA
        WHERE RCA.NUM_COMPTE_ACCURATE = p_num_compte_accurate
          AND RCA.ID_COMPTE_ACCURATE = p_id_compte_accurate;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'ERREUR: Compte ACCURATE "' || p_num_compte_accurate || '" avec ID ' || p_id_compte_accurate || ' non trouvé.');
        END IF;

        v_id_compte_accurate := p_id_compte_accurate;
    ELSE
        -- Si ID non spécifié, vérifier avec NUM_COMPTE uniquement
        SELECT COUNT(*)
        INTO v_count
        FROM EXP_RNAPA.TA_RN_COMPTE_ACCURATE RCA
        WHERE RCA.NUM_COMPTE_ACCURATE = p_num_compte_accurate;

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'ERREUR: Compte ACCURATE "' || p_num_compte_accurate || '" non trouvé.');
        END IF;

        -- Récupérer l'ID du compte ACCURATE
        SELECT ID_COMPTE_ACCURATE
        INTO v_id_compte_accurate
        FROM EXP_RNAPA.TA_RN_COMPTE_ACCURATE
        WHERE NUM_COMPTE_ACCURATE = p_num_compte_accurate
        AND ROWNUM = 1;
    END IF;

    DBMS_OUTPUT.PUT_LINE('=== DEBUT MISE A JOUR COMPTE ACCURATE ===');
    DBMS_OUTPUT.PUT_LINE('Compte: ' || p_num_compte_accurate);
    DBMS_OUTPUT.PUT_LINE('ID Compte Accurate: ' || v_id_compte_accurate);

    -- =========================================================================
    -- UPDATE 1 : FLAG_ACTIF dans TA_RN_COMPTE_ACCURATE
    -- =========================================================================
    IF p_flag_actif IS NOT NULL THEN
        IF p_id_compte_accurate IS NOT NULL THEN
            -- Mise à jour avec filtre ID
            UPDATE EXP_RNAPA.TA_RN_COMPTE_ACCURATE
            SET FLAG_ACTIF = p_flag_actif
            WHERE NUM_COMPTE_ACCURATE = p_num_compte_accurate
              AND ID_COMPTE_ACCURATE = p_id_compte_accurate;
        ELSE
            -- Mise à jour sans filtre ID
            UPDATE EXP_RNAPA.TA_RN_COMPTE_ACCURATE
            SET FLAG_ACTIF = p_flag_actif
            WHERE NUM_COMPTE_ACCURATE = p_num_compte_accurate;
        END IF;

        v_rows_updated := SQL%ROWCOUNT;
        DBMS_OUTPUT.PUT_LINE('UPDATE FLAG_ACTIF: ' || v_rows_updated || ' ligne(s) mise(s) à jour');
    END IF;

    -- =========================================================================
    -- UPDATE 2 : NUM_COMPTE_COMPTABLE dans TA_RN_GEST_COMPTE_COMPTABLE
    -- =========================================================================
    IF p_num_compte_comptable IS NOT NULL THEN
        -- Récupérer le COMPTE_BANCAIRE associé
        BEGIN
            SELECT BCM.COMPTE_BANCAIRE
            INTO v_compte_bancaire
            FROM EXP_RNAPA.BA_COMPTE_METHODE BCM
            WHERE BCM.COMPTE_COMPTABLE = p_num_compte_accurate
            AND ROWNUM = 1;

            -- Mettre à jour le NUM_COMPTE_COMPTABLE
            UPDATE EXP_RNAPA.TA_RN_GEST_COMPTE_COMPTABLE
            SET NUM_COMPTE_COMPTABLE = p_num_compte_comptable
            WHERE COMPTE_BANCAIRE = v_compte_bancaire;

            v_rows_updated := SQL%ROWCOUNT;
            DBMS_OUTPUT.PUT_LINE('UPDATE NUM_COMPTE_COMPTABLE: ' || v_rows_updated || ' ligne(s) mise(s) à jour');
            DBMS_OUTPUT.PUT_LINE('  -> COMPTE_BANCAIRE: ' || v_compte_bancaire);
            DBMS_OUTPUT.PUT_LINE('  -> Nouveau NUM_COMPTE_COMPTABLE: ' || p_num_compte_comptable);

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('ATTENTION: Aucun COMPTE_BANCAIRE trouvé pour ce compte ACCURATE');
        END;
    END IF;

    -- =========================================================================
    -- UPDATE 3 : CODE SOCIETE (liste séparée par virgule)
    -- Met à jour la table de liaison via TA_RN_PERIMETRE_COMPTA
    -- =========================================================================
    IF p_codes_societe IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Traitement des codes société: ' || p_codes_societe);

        -- Parcourir la liste des codes société
        v_codes_restants := p_codes_societe;

        WHILE v_codes_restants IS NOT NULL LOOP
            -- Trouver la position de la virgule
            v_position := INSTR(v_codes_restants, ',');

            IF v_position > 0 THEN
                v_code_societe := TRIM(SUBSTR(v_codes_restants, 1, v_position - 1));
                v_codes_restants := SUBSTR(v_codes_restants, v_position + 1);
            ELSE
                v_code_societe := TRIM(v_codes_restants);
                v_codes_restants := NULL;
            END IF;

            -- Traiter ce code société
            IF v_code_societe IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('  -> Traitement code société: ' || v_code_societe);

                -- Mettre à jour ID_SOCIETE dans TA_RN_PERIMETRE_COMPTA
                -- pour les enregistrements liés à ce compte ACCURATE
                UPDATE EXP_RNAPA.TA_RN_PERIMETRE_COMPTA RPC
                SET RPC.ID_SOCIETE = (
                    SELECT RS.ID_SOCIETE
                    FROM EXP_RNAPA.TA_RN_SOCIETE RS
                    WHERE RS.CODE = v_code_societe
                    AND ROWNUM = 1
                )
                WHERE RPC.ID_PERIMETRE_COMPTA IN (
                    SELECT CtaA.ID_PERIMETRE_COMPTA
                    FROM EXP_RNAPA.TA_RN_COMPTA_ACCURATE CtaA
                    WHERE CtaA.ID_COMPTE_ACCURATE = v_id_compte_accurate
                )
                AND EXISTS (
                    SELECT 1 FROM EXP_RNAPA.TA_RN_SOCIETE RS
                    WHERE RS.CODE = v_code_societe
                );

                v_rows_updated := SQL%ROWCOUNT;
                IF v_rows_updated > 0 THEN
                    DBMS_OUTPUT.PUT_LINE('     ' || v_rows_updated || ' ligne(s) mise(s) à jour pour société ' || v_code_societe);
                ELSE
                    DBMS_OUTPUT.PUT_LINE('     ATTENTION: Code société "' || v_code_societe || '" non trouvé ou pas de mise à jour');
                END IF;
            END IF;
        END LOOP;
    END IF;

    -- =========================================================================
    -- COMMIT
    -- =========================================================================
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('=== FIN MISE A JOUR - COMMIT EFFECTUE ===');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERREUR: ' || SQLERRM);
        RAISE;
END SP_UPDATE_COMPTE_ACCURATE;
/

-- ============================================================================
-- VERIFICATION DE LA COMPILATION
-- ============================================================================
SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'SP_UPDATE_COMPTE_ACCURATE';

-- ============================================================================
-- EXEMPLES D'UTILISATION
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Exemple 1: Mettre à jour uniquement le FLAG_ACTIF (sans ID)
-- ----------------------------------------------------------------------------
/*
BEGIN
    EXP_RNAPA.SP_UPDATE_COMPTE_ACCURATE(
        p_num_compte_accurate => 'BBNP42304-EUR',
        p_flag_actif => 'N'
    );
END;
/
*/

-- ----------------------------------------------------------------------------
-- Exemple 2: Mettre à jour le FLAG_ACTIF avec ID spécifique
-- ----------------------------------------------------------------------------
/*
BEGIN
    EXP_RNAPA.SP_UPDATE_COMPTE_ACCURATE(
        p_num_compte_accurate => 'BBNP42304-EUR',
        p_id_compte_accurate => 12345,
        p_flag_actif => 'O'
    );
END;
/
*/

-- ----------------------------------------------------------------------------
-- Exemple 3: Mettre à jour le NUM_COMPTE_COMPTABLE
-- ----------------------------------------------------------------------------
/*
BEGIN
    EXP_RNAPA.SP_UPDATE_COMPTE_ACCURATE(
        p_num_compte_accurate => 'BBNP42304-EUR',
        p_num_compte_comptable => '512100'
    );
END;
/
*/

-- ----------------------------------------------------------------------------
-- Exemple 4: Mettre à jour les codes société (liste séparée par virgule)
-- ----------------------------------------------------------------------------
/*
BEGIN
    EXP_RNAPA.SP_UPDATE_COMPTE_ACCURATE(
        p_num_compte_accurate => 'BBNP42304-EUR',
        p_codes_societe => 'SOC1,SOC2,SOC3'
    );
END;
/
*/

-- ----------------------------------------------------------------------------
-- Exemple 5: Mettre à jour plusieurs champs en même temps (sans ID)
-- ----------------------------------------------------------------------------
/*
BEGIN
    EXP_RNAPA.SP_UPDATE_COMPTE_ACCURATE(
        p_num_compte_accurate => 'BBNP42304-EUR',
        p_flag_actif => 'O',
        p_num_compte_comptable => '512100',
        p_codes_societe => 'FR01,FR02'
    );
END;
/
*/

-- ----------------------------------------------------------------------------
-- Exemple 6: Mettre à jour plusieurs champs avec ID spécifique
-- ----------------------------------------------------------------------------
/*
BEGIN
    EXP_RNAPA.SP_UPDATE_COMPTE_ACCURATE(
        p_num_compte_accurate => 'BBNP42304-EUR',
        p_id_compte_accurate => 12345,
        p_flag_actif => 'O',
        p_num_compte_comptable => '512100',
        p_codes_societe => 'FR01,FR02'
    );
END;
/
*/
