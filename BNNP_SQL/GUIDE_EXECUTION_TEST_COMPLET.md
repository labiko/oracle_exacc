# 🎯 GUIDE D'EXÉCUTION - Test Complet avec Traçage

## Date : 07/02/2026

---

## 📋 OBJECTIF

Identifier **précisément** pourquoi la transaction 2817 n'est pas insérée dans BR_DATA alors que 22.36 l'est, en traçant chaque étape du traitement.

---

## 📦 FICHIERS CRÉÉS

| Fichier | Description |
|---------|-------------|
| `RNADGENJUCGES01_TRACE_COMPLETE.sql` | Script modifié avec logs complets |
| `PURGE_AVANT_TEST.sql` | Nettoyage avant test |
| `ANALYSER_LOGS_22.36_vs_2817.sql` | Analyse des logs post-exécution |
| `GUIDE_EXECUTION_TEST_COMPLET.md` | **CE FICHIER** - Guide d'exécution |

---

## ⚡ PROCÉDURE D'EXÉCUTION (ÉTAPE PAR ÉTAPE)

### ÉTAPE 1 : PURGER LES DONNÉES EXISTANTES

```sql
-- Dans SQL Developer ou SQL*Plus
@PURGE_AVANT_TEST.sql
```

**Résultat attendu :**
```
✅ TA_RN_IMPORT_GESTION_JC: X lignes supprimées
✅ TA_RN_EXPORT_JC: X lignes supprimées
✅ TA_RN_LOG_EXECUTION: X lignes supprimées
✅ TW_EXPORT_GEST_JC: X lignes supprimées
```

**⚠️ IMPORTANT :** Toutes les tables doivent être à 0 lignes après purge.

---

### ÉTAPE 2 : VÉRIFIER QUE LE FICHIER XML EST CHARGÉ DANS TX_REGLT_GEST

```sql
-- Vérifier que la table TX_REGLT_GEST contient le XML
SELECT COUNT(*) FROM TX_REGLT_GEST;

-- Si vide, charger le fichier XML source
-- (voir votre procédure de chargement habituelle)
```

**Résultat attendu :** Au moins 1 ligne (le XML chargé)

---

### ÉTAPE 3 : EXÉCUTER LE SCRIPT AVEC TRAÇAGE COMPLET

```sql
@RNADGENJUCGES01_TRACE_COMPLETE.sql
```

**Pendant l'exécution, vous verrez :**
```
========== DEBUT TRAITEMENT AVEC TRACAGE COMPLET ==========
Debut lecture donnees XML TX_REGLT_GEST
Nombre de lignes XML chargees
---------- RECHERCHE TRANSACTIONS CIBLES DANS LE XML ----------
✅ Transaction 22.36 TROUVEE dans le XML
✅ Transaction 2817 TROUVEE dans le XML (ou ❌ si absente)
---------- FIN RECHERCHE TRANSACTIONS CIBLES ----------
...
🎯 TRANSACTION CIBLE 22.36 INSEREE
🎯 TRANSACTION CIBLE 2817 INSEREE (ou pas)
...
COMMIT final import
========== FIN TRAITEMENT AVEC TRACAGE COMPLET ==========
```

**Durée estimée :** 1-5 minutes selon le nombre de transactions

---

### ÉTAPE 4 : ANALYSER LES LOGS

```sql
@ANALYSER_LOGS_22.36_vs_2817.sql
```

**Ce script affiche 10 sections d'analyse :**

1. **Recherche des transactions cibles dans les logs**
2. **Vérification si 22.36 et 2817 sont dans le XML**
3. **Vérification si insérés dans TA_RN_IMPORT_GESTION_JC**
4. **Vérification des COMMIT**
5. **Analyse du test EXISTS pour chaque compte accurate**
6. **Comptes qui ont des transactions à insérer**
7. **Comptes avec 0 transactions (bloqués)**
8. **Insertions réelles dans TA_RN_EXPORT_JC**
9. **Erreurs et warnings**
10. **Résumé global**

---

## 📊 INTERPRÉTATION DES RÉSULTATS

### CAS 1 : Les deux transactions sont dans le XML mais PAS insérées

**Log attendu :**
```
Section 2:
✅ Transaction 22.36 TROUVEE dans le XML
✅ Transaction 2817 TROUVEE dans le XML

Section 3:
(vide ou seulement 22.36)
```

**Diagnostic :** Problème lors de l'INSERT dans TA_RN_IMPORT_GESTION_JC
**Action :** Vérifier Section 9 (Erreurs) pour voir les messages d'exception

---

### CAS 2 : Les deux sont insérées mais seulement 22.36 passe le filtre EXISTS

**Log attendu :**
```
Section 3:
✅ 22.36 | PAYMENTREF=XXX | MONTANT=22.36 | CLIENT=00838038 | RIB=00010207054
✅ 2817  | PAYMENTREF=YYY | MONTANT=2817 | CLIENT=90141615 | RIB=00016111832

Section 5:
394 (BNPP05492-EUR) - 1 transactions a inserer
342 (BBNP83292-EUR) - 0 transactions a inserer  ← 🔴 PROBLÈME ICI
```

**Diagnostic :** Le compte 342 n'est PAS paramétré dans TA_RN_GESTION_JC
**Action :** Exécuter le script suivant pour confirmer :

```sql
SELECT * FROM TA_RN_GESTION_JC WHERE ID_COMPTE_ACCURATE IN (394, 342);
```

**Si 394 présent mais pas 342 → SOLUTION :**

```sql
-- Récupérer les ID pour 'ALL'
SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = 'ALL';          -- Ex: 999
SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'ALL';  -- Ex: 999

-- Ajouter le compte 342 dans GESTION_JC
INSERT INTO TA_RN_GESTION_JC (ID_COMPTE_ACCURATE, ID_PRODUIT, ID_MODE_REGLEMENT)
VALUES (342, 999, 999);  -- Remplacer 999 par les vrais ID

COMMIT;

-- Relancer le test
```

---

### CAS 3 : Seulement 22.36 est dans le XML

**Log attendu :**
```
Section 2:
✅ Transaction 22.36 TROUVEE dans le XML
❌ Transaction 2817 NON TROUVEE dans le XML
```

**Diagnostic :** Le fichier XML source ne contient pas 2817
**Action :** Vérifier le fichier XML source sur le serveur

---

### CAS 4 : Les deux passent le filtre EXISTS mais problème lors de l'INSERT dans TA_RN_EXPORT_JC

**Log attendu :**
```
Section 5:
394 (BNPP05492-EUR) - 2 transactions a inserer
342 (BBNP83292-EUR) - 1 transactions a inserer

Section 8:
394 - 2 lignes effectivement inserees
342 - 0 lignes effectivement inserees  ← 🔴 PROBLÈME ICI
```

**Diagnostic :** Erreur lors de l'INSERT dynamique (contrainte, privilège, etc.)
**Action :** Vérifier Section 9 (Erreurs et warnings)

---

## 🔍 VÉRIFICATIONS SUPPLÉMENTAIRES

### Vérifier manuellement dans les tables

```sql
-- 1. Vérifier dans TA_RN_IMPORT_GESTION_JC
SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '22.36';
SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '2817';

-- 2. Vérifier dans TA_RN_EXPORT_JC
SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT IN ('22.36', '2817');

-- 3. Vérifier le lien RIB → Compte Accurate pour 22.36
SELECT
    RCB.IDENTIFICATION AS RIB,
    RCA.ID_COMPTE_ACCURATE,
    RCA.NUM_COMPTE_ACCURATE,
    RCA.TYPE_RAPPRO
FROM TA_RN_COMPTE_BANCAIRE RCB
    JOIN TA_RN_PERIMETRE_BANQUE RPB ON RPB.ID_COMPTE_BANCAIRE = RCB.ID_COMPTE_BANCAIRE
    JOIN TA_RN_BANQUE_ACCURATE RBA ON RBA.ID_PERIMETRE_BANQUE = RPB.ID_PERIMETRE_BANQUE
    JOIN TA_RN_COMPTE_ACCURATE RCA ON RCA.ID_COMPTE_ACCURATE = RBA.ID_COMPTE_ACCURATE
WHERE RCB.IDENTIFICATION = '00010207054';  -- RIB de 22.36

-- 4. Vérifier le lien RIB → Compte Accurate pour 2817
SELECT
    RCB.IDENTIFICATION AS RIB,
    RCA.ID_COMPTE_ACCURATE,
    RCA.NUM_COMPTE_ACCURATE,
    RCA.TYPE_RAPPRO
FROM TA_RN_COMPTE_BANCAIRE RCB
    JOIN TA_RN_PERIMETRE_BANQUE RPB ON RPB.ID_COMPTE_BANCAIRE = RCB.ID_COMPTE_BANCAIRE
    JOIN TA_RN_BANQUE_ACCURATE RBA ON RBA.ID_PERIMETRE_BANQUE = RPB.ID_PERIMETRE_BANQUE
    JOIN TA_RN_COMPTE_ACCURATE RCA ON RCA.ID_COMPTE_ACCURATE = RBA.ID_COMPTE_ACCURATE
WHERE RCB.IDENTIFICATION = '00016111832';  -- RIB de 2817
```

---

## 📝 CHECKLIST DE VÉRIFICATION

- [ ] ÉTAPE 1 : Purge effectuée (toutes les tables à 0)
- [ ] ÉTAPE 2 : TX_REGLT_GEST contient le XML
- [ ] ÉTAPE 3 : Script RNADGENJUCGES01_TRACE_COMPLETE.sql exécuté sans erreur
- [ ] ÉTAPE 4 : Logs analysés avec ANALYSER_LOGS_22.36_vs_2817.sql
- [ ] Section 2 : 22.36 et 2817 trouvés dans le XML ?
- [ ] Section 3 : 22.36 et 2817 insérés dans TA_RN_IMPORT_GESTION_JC ?
- [ ] Section 4 : COMMIT final effectué ?
- [ ] Section 5 : Test EXISTS - combien de transactions pour chaque compte ?
- [ ] Section 6 : Quels comptes ont des transactions à insérer ?
- [ ] Section 7 : Quels comptes sont bloqués (0 transactions) ?
- [ ] Section 9 : Y a-t-il des erreurs ou warnings ?

---

## 🎯 RÉSULTAT ATTENDU FINAL

À la fin de cette procédure, vous saurez **EXACTEMENT** :

1. ✅ Si 22.36 et 2817 sont dans le fichier XML source
2. ✅ Si les deux sont insérés dans TA_RN_IMPORT_GESTION_JC
3. ✅ Si les deux sont committés
4. ✅ Quel est l'ID_COMPTE_ACCURATE associé à chaque transaction
5. ✅ Si ces comptes accurate sont paramétrés dans TA_RN_GESTION_JC
6. ✅ Combien de transactions passent le filtre EXISTS pour chaque compte
7. ✅ **LA RAISON EXACTE** du blocage de 2817

---

## 🔧 SOLUTION PROBABLE

**Si le résultat de Section 5 montre :**
```
394 (BNPP05492-EUR) - X transactions a inserer  (X > 0)
342 (BBNP83292-EUR) - 0 transactions a inserer
```

**Alors la solution est :**

```sql
-- 1. Vérifier les ID pour 'ALL'
SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = 'ALL';
SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'ALL';

-- 2. Ajouter le compte 342 dans TA_RN_GESTION_JC
INSERT INTO TA_RN_GESTION_JC (ID_COMPTE_ACCURATE, ID_PRODUIT, ID_MODE_REGLEMENT)
VALUES (342, <ID_PRODUIT_ALL>, <ID_MODE_REGLEMENT_ALL>);

COMMIT;

-- 3. Relancer le test complet pour vérifier
@PURGE_AVANT_TEST.sql
@RNADGENJUCGES01_TRACE_COMPLETE.sql
@ANALYSER_LOGS_22.36_vs_2817.sql
```

---

## 📞 SUPPORT

En cas de problème :
1. Vérifier Section 9 (Erreurs et warnings) du script d'analyse
2. Consulter les logs dans TA_RN_LOG_EXECUTION directement :
   ```sql
   SELECT * FROM TA_RN_LOG_EXECUTION
   WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_JC_TRACE'
   ORDER BY DT_EXECUTION DESC;
   ```
3. Vérifier les structures de tables avec STRUCTURE_TABLES_REFERENCE.txt

---

**Bonne chance ! 🚀**
