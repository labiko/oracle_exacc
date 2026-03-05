# GUIDE DE MODIFICATION - RNADGENEXPGES01_TRACE_COMPLETE.sql

## Date : 07/02/2026

---

## MODIFICATIONS À APPORTER

### ✅ MODIFICATION 1 : Ajouter la procédure P_LOG (après la ligne 548 - après "Fin de declaration des fonctions")

```sql
/* ============================================================================ */
/* PROCEDURE P_LOG : Enregistrement dans la table de logs                       */
/* ============================================================================ */
PROCEDURE P_LOG (
    p_type_log       IN VARCHAR2,
    p_message        IN VARCHAR2,
    p_nom_balise     IN VARCHAR2 DEFAULT NULL,
    p_valeur         IN VARCHAR2 DEFAULT NULL,
    p_code_erreur    IN VARCHAR2 DEFAULT NULL,
    p_stack_trace    IN CLOB DEFAULT NULL,
    p_etape          IN NUMBER DEFAULT NULL
) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO TA_RN_LOG_EXECUTION (
        DT_EXECUTION,
        NOM_PROCEDURE,
        TYPE_LOG,
        NOM_BALISE,
        VALEUR_EXTRAITE,
        MESSAGE,
        CODE_ERREUR,
        STACK_TRACE,
        ID_CHARGEMENT,
        ETAPE
    ) VALUES (
        SYSTIMESTAMP,
        'PR_RN_IMPORT_GESTION_TRACE',  -- Nom différent pour identifier ce script
        p_type_log,
        p_nom_balise,
        SUBSTR(p_valeur, 1, 4000),
        SUBSTR(p_message, 1, 4000),
        p_code_erreur,
        p_stack_trace,
        Var_ID_CHARGEMENT_GESTION,
        p_etape
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END P_LOG;
```

---

### ✅ MODIFICATION 2 : Ajouter des variables de comptage (après ligne 142 - après "Var_N_Uncommitted NUMBER := 0;")

```sql
-- Variables pour traçage --
v_total_transactions_lues NUMBER := 0;
v_found_22_36 BOOLEAN := FALSE;
v_found_2817 BOOLEAN := FALSE;
```

---

### ✅ MODIFICATION 3 : Logger le début de traitement (chercher "DEBUT Recuperation de l'ID chargement" vers ligne 550-560)

AJOUTER après le calcul de Var_ID_CHARGEMENT_GESTION :

```sql
DBMS_OUTPUT.PUT_LINE('========== DEBUT TRAITEMENT AVEC TRACAGE COMPLET ==========');
DBMS_OUTPUT.PUT_LINE('ID_CHARGEMENT_GESTION: ' || Var_ID_CHARGEMENT_GESTION);
P_LOG('INFO', 'Debut traitement PR_RN_IMPORT_GESTION_TRACE', NULL,
      'ID_CHARGEMENT=' || Var_ID_CHARGEMENT_GESTION, NULL, NULL, 10);
```

---

### ✅ MODIFICATION 4 : Logger la lecture du XML (chercher "Lecture donnees XML" vers ligne 580)

AJOUTER après "FETCH Curseur_Lignes_XML BULK COLLECT INTO tab_REG_XML;" :

```sql
DBMS_OUTPUT.PUT_LINE('Debut lecture donnees XML TX_REGLT_GEST');
P_LOG('INFO', 'Nombre de lignes XML chargees', NULL,
      TO_CHAR(tab_REG_XML.COUNT) || ' lignes', NULL, NULL, 25);
```

---

### ✅ MODIFICATION 5 : Rechercher 22.36 et 2817 dans le XML (AJOUTER après le BULK COLLECT, avant la boucle FOR idx_XML)

```sql
-- ============================================================================
-- RECHERCHE DES TRANSACTIONS CIBLES DANS LE XML
-- ============================================================================
DBMS_OUTPUT.PUT_LINE('---------- RECHERCHE TRANSACTIONS CIBLES DANS LE XML ----------');

FOR i IN tab_REG_XML.FIRST .. tab_REG_XML.LAST LOOP
    IF INSTR(tab_REG_XML(i).xml_line, '22.36') > 0 THEN
        v_found_22_36 := TRUE;
        P_LOG('INFO', '✅ Transaction 22.36 TROUVEE dans le XML',
              'LIGNE_XML', TO_CHAR(i) || ' | ' || SUBSTR(tab_REG_XML(i).xml_line, 1, 100),
              NULL, NULL, 25);
        DBMS_OUTPUT.PUT_LINE('✅ Transaction 22.36 TROUVEE ligne ' || i);
    END IF;

    IF INSTR(tab_REG_XML(i).xml_line, '2817') > 0 THEN
        v_found_2817 := TRUE;
        P_LOG('INFO', '✅ Transaction 2817 TROUVEE dans le XML',
              'LIGNE_XML', TO_CHAR(i) || ' | ' || SUBSTR(tab_REG_XML(i).xml_line, 1, 100),
              NULL, NULL, 25);
        DBMS_OUTPUT.PUT_LINE('✅ Transaction 2817 TROUVEE ligne ' || i);
    END IF;
END LOOP;

IF NOT v_found_22_36 THEN
    P_LOG('WARNING', '❌ Transaction 22.36 NON TROUVEE dans le XML', NULL, NULL, NULL, NULL, 25);
    DBMS_OUTPUT.PUT_LINE('❌ Transaction 22.36 NON TROUVEE dans le XML');
END IF;

IF NOT v_found_2817 THEN
    P_LOG('WARNING', '❌ Transaction 2817 NON TROUVEE dans le XML', NULL, NULL, NULL, NULL, 25);
    DBMS_OUTPUT.PUT_LINE('❌ Transaction 2817 NON TROUVEE dans le XML');
END IF;

DBMS_OUTPUT.PUT_LINE('---------- FIN RECHERCHE TRANSACTIONS CIBLES ----------');
-- ============================================================================
```

---

### ✅ MODIFICATION 6 : Logger chaque insertion dans TA_RN_IMPORT_GESTION

Chercher le bloc qui fait :
```sql
BEGIN
    EXECUTE IMMEDIATE 'INSERT INTO TA_RN_IMPORT_GESTION '||ListeChampsImport||' '||'VALUES '||ListeValeursImport;
```

REMPLACER par :

```sql
BEGIN
    EXECUTE IMMEDIATE 'INSERT INTO TA_RN_IMPORT_GESTION '||ListeChampsImport||' '||'VALUES '||ListeValeursImport;

    -- ============================================================================
    -- MODIFICATION 1 : LOG DE CHAQUE TRANSACTION INSÉRÉE
    -- ============================================================================
    v_total_transactions_lues := v_total_transactions_lues + 1;

    P_LOG('INFO', 'Transaction inseree dans TA_RN_IMPORT_GESTION',
          'PAYMENTREFERENCE',
          Var_PAYMENTREFERENCE || ' | MONTANT=' || Var_OPERATIONNETAMOUNT || ' | CLIENT=' || Var_NUMEROCLIENT || ' | RIB=' || Var_IDENTIFICATIONRIB,
          NULL, NULL, v_step);

    -- Log spécifique si c'est une de nos transactions cibles
    IF Var_OPERATIONNETAMOUNT = '22.36' THEN
        P_LOG('INFO', '🎯 TRANSACTION CIBLE 22.36 INSEREE',
              'PAYMENTREF', Var_PAYMENTREFERENCE,
              NULL, NULL, v_step);
        DBMS_OUTPUT.PUT_LINE('🎯 TRANSACTION CIBLE 22.36 INSEREE | PAYMENTREF=' || Var_PAYMENTREFERENCE || ' | MONTANT=22.36 | CLIENT=' || Var_NUMEROCLIENT);
    ELSIF Var_OPERATIONNETAMOUNT = '2817' THEN
        P_LOG('INFO', '🎯 TRANSACTION CIBLE 2817 INSEREE',
              'PAYMENTREF', Var_PAYMENTREFERENCE,
              NULL, NULL, v_step);
        DBMS_OUTPUT.PUT_LINE('🎯 TRANSACTION CIBLE 2817 INSEREE | PAYMENTREF=' || Var_PAYMENTREFERENCE || ' | MONTANT=2817 | CLIENT=' || Var_NUMEROCLIENT);
    END IF;
    -- ============================================================================
```

---

### ✅ MODIFICATION 7 : Logger le COMMIT final

Chercher "COMMIT;" après la boucle d'insertion, AJOUTER avant :

```sql
DBMS_OUTPUT.PUT_LINE('COMMIT final import - Total transactions insérées: ' || v_total_transactions_lues);
P_LOG('INFO', 'COMMIT final import',
      'TOTAL_TRANSACTIONS', TO_CHAR(v_total_transactions_lues) || ' transactions inserees',
      NULL, NULL, v_step);
```

---

### ✅ MODIFICATION 8 : Logger le traitement des comptes accurate (chercher le bloc OPEN Curseur_ZonesParCompte vers ligne 900)

AJOUTER après "OPEN Curseur_ZonesParCompte;" :

```sql
DBMS_OUTPUT.PUT_LINE('---------- TRAITEMENT DES COMPTES ACCURATE (TYPE_RAPPRO=B) ----------');
P_LOG('INFO', 'Debut traitement comptes accurate TYPE_RAPPRO=B', NULL, NULL, NULL, NULL, 30);
```

---

### ✅ MODIFICATION 9 : Logger le test EXISTS avec TA_RN_GESTION_ACCURATE

Chercher les blocs "EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT" (vers lignes 993, 1029, 1078, etc.)

AVANT chaque EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT', AJOUTER :

```sql
-- ============================================================================
-- LOG DU TEST EXISTS AVEC TA_RN_GESTION_ACCURATE
-- ============================================================================
DECLARE
    v_count_test NUMBER := 0;
    v_id_compte_accurate NUMBER;
    v_num_compte_accurate VARCHAR2(128);
BEGIN
    -- Récupérer l'ID et NUM du compte accurate pour ce RIB
    SELECT DISTINCT GA.ID_COMPTE_ACCURATE, CA.NUM_COMPTE_ACCURATE
    INTO v_id_compte_accurate, v_num_compte_accurate
    FROM TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
        JOIN TA_RN_GESTION_ACCURATE GA ON GA.ID_COMPTE_BANCAIRE_SYSTEME = CBS.ID_COMPTE_BANCAIRE_SYSTEME
        JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = GA.ID_COMPTE_ACCURATE
    WHERE CBS.ID_COMPTE_BANCAIRE_SYSTEME = Var_Ref_ID_COMPTE_BANC_SYST
      AND ROWNUM = 1;

    -- Compter combien de transactions correspondent
    SELECT COUNT(*) INTO v_count_test
    FROM TA_RN_IMPORT_GESTION T
    WHERE T.IDENTIFICATIONRIB = Var_Ref_RIBIDENTIFICATION
      AND T.RIBCHECKDIGIT = Var_Ref_RIBCHECKDIGIT
      AND T.BANKCODE = Var_Ref_RIBBANKCODE
      AND T.BRANCHCODE = Var_Ref_RIBBRANCHCODE
      AND T.ID_CHARGEMENT_GESTION = Var_ID_CHARGEMENT_GESTION;

    P_LOG('INFO', 'Test EXISTS TA_RN_GESTION_ACCURATE pour compte accurate',
          'ID_COMPTE_ACCURATE',
          TO_CHAR(v_id_compte_accurate) || ' (' || v_num_compte_accurate || ') - ' || TO_CHAR(v_count_test) || ' transactions a inserer',
          NULL, NULL, v_step);

    DBMS_OUTPUT.PUT_LINE('Test EXISTS - Compte ' || v_id_compte_accurate || ' (' || v_num_compte_accurate || ') - ' || v_count_test || ' transactions');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        P_LOG('WARNING', 'Compte bancaire systeme NON trouve dans TA_RN_GESTION_ACCURATE',
              'ID_COMPTE_BANC_SYST', TO_CHAR(Var_Ref_ID_COMPTE_BANC_SYST),
              NULL, NULL, v_step);
    WHEN OTHERS THEN
        P_LOG('ERROR', 'Erreur lors du test EXISTS',
              NULL, SQLERRM, SQLCODE, DBMS_UTILITY.FORMAT_ERROR_STACK, v_step);
END;
-- ============================================================================
```

---

### ✅ MODIFICATION 10 : Logger après l'INSERT dans TA_RN_EXPORT

APRÈS chaque bloc "EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT...'", AJOUTER :

```sql
P_LOG('INFO', 'INSERT dans TA_RN_EXPORT complete',
      'COMPTE',
      TO_CHAR(Var_Ref_ID_COMPTE_BANC_SYST) || ' - ' || SQL%ROWCOUNT || ' lignes inserees',
      NULL, NULL, v_step);
DBMS_OUTPUT.PUT_LINE('INSERT TA_RN_EXPORT - Compte ' || Var_Ref_ID_COMPTE_BANC_SYST || ' - ' || SQL%ROWCOUNT || ' lignes');
```

---

### ✅ MODIFICATION 11 : NE PAS purger TA_RN_IMPORT_GESTION (commenter les DELETE)

Si le script contient des DELETE de TA_RN_IMPORT_GESTION ou TA_RN_EXPORT, les COMMENTER avec -- pour pouvoir analyser après :

```sql
-- DELETE FROM TA_RN_IMPORT_GESTION;  -- COMMENTÉ pour analyse post-exécution
-- DELETE FROM TA_RN_EXPORT WHERE SOURCE='GEST';  -- COMMENTÉ pour analyse post-exécution
```

---

## RÉSUMÉ DES CHANGEMENTS

1. ✅ Ajout procédure P_LOG (autonome) avec nom 'PR_RN_IMPORT_GESTION_TRACE'
2. ✅ Log de début de traitement
3. ✅ Recherche de 22.36 et 2817 dans le XML
4. ✅ Log de chaque transaction insérée dans TA_RN_IMPORT_GESTION
5. ✅ Log spécifique pour 22.36 et 2817
6. ✅ Log du COMMIT final
7. ✅ Log du test EXISTS avec TA_RN_GESTION_ACCURATE
8. ✅ Log après INSERT dans TA_RN_EXPORT
9. ✅ Commenter les DELETE pour analyse post-exécution

---

## UTILISATION APRÈS MODIFICATION

1. Exécuter : `@RNADGENEXPGES01_TRACE_COMPLETE.sql`
2. Analyser les logs : `SELECT * FROM TA_RN_LOG_EXECUTION WHERE NOM_PROCEDURE='PR_RN_IMPORT_GESTION_TRACE' ORDER BY DT_EXECUTION;`
3. Vérifier les données : Tables TA_RN_IMPORT_GESTION et TA_RN_EXPORT non purgées

---

**Voulez-vous que je crée le fichier complet modifié ou préférez-vous appliquer ces modifications manuellement ?**
