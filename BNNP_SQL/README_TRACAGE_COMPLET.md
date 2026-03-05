# 📦 PACKAGE COMPLET - TRAÇAGE 22.36 vs 2817

## Date : 07/02/2026

---

## 🎯 OBJECTIF

Identifier **exactement** pourquoi la transaction 2817 n'est PAS insérée dans BANKREC.BR_DATA alors que 22.36 l'est.

---

## 📋 LISTE DES FICHIERS CRÉÉS

### 1. Script principal avec traçage
📄 **RNADGENJUCGES01_TRACE_COMPLETE.sql** (PRINCIPAL)
- Version modifiée du script d'import avec logs complets
- 4 améliorations majeures :
  1. Log de CHAQUE transaction insérée avec PAYMENTREFERENCE + MONTANT + NUMEROCLIENT
  2. Log des COMMIT avec compteur de transactions traitées
  3. Log du test EXISTS avec TA_RN_GESTION_JC (avant chaque INSERT)
  4. Recherche spécifique de 22.36 et 2817 dans le XML

### 2. Script de purge
📄 **PURGE_AVANT_TEST.sql**
- Nettoie toutes les données avant de relancer le test
- Purge : TA_RN_IMPORT_GESTION_JC, TA_RN_EXPORT_JC, TA_RN_LOG_EXECUTION, TW_EXPORT_GEST_JC

### 3. Script d'analyse des logs
📄 **ANALYSER_LOGS_22.36_vs_2817.sql**
- 10 sections d'analyse :
  1. Recherche des transactions cibles dans les logs
  2. Vérification si 22.36 et 2817 sont dans le XML
  3. Vérification si insérés dans TA_RN_IMPORT_GESTION_JC
  4. Vérification des COMMIT
  5. Analyse du test EXISTS pour chaque compte accurate
  6. Comptes qui ont des transactions à insérer
  7. Comptes avec 0 transactions (bloqués)
  8. Insertions réelles dans TA_RN_EXPORT_JC
  9. Erreurs et warnings
  10. Résumé global

### 4. Guide d'exécution
📄 **GUIDE_EXECUTION_TEST_COMPLET.md**
- Procédure étape par étape
- Interprétation des résultats
- Solutions recommandées
- Checklist de vérification

### 5. Ce fichier
📄 **README_TRACAGE_COMPLET.md** (CE FICHIER)
- Index de tous les fichiers
- Vue d'ensemble du package

---

## ⚡ DÉMARRAGE RAPIDE

### Étape 1 : Purger les données
```sql
@PURGE_AVANT_TEST.sql
```

### Étape 2 : Exécuter le script avec traçage
```sql
@RNADGENJUCGES01_TRACE_COMPLETE.sql
```

### Étape 3 : Analyser les logs
```sql
@ANALYSER_LOGS_22.36_vs_2817.sql
```

### Étape 4 : Consulter le guide pour l'interprétation
Ouvrir `GUIDE_EXECUTION_TEST_COMPLET.md`

---

## 🔍 CE QUE LE TRAÇAGE VA RÉVÉLER

### 1. Présence dans le XML
```
✅ Transaction 22.36 TROUVEE dans le XML
✅ Transaction 2817 TROUVEE dans le XML  (ou ❌ si absente)
```

### 2. Insertion dans TA_RN_IMPORT_GESTION_JC
```
🎯 TRANSACTION CIBLE 22.36 INSEREE | PAYMENTREF=XXX | MONTANT=22.36 | CLIENT=00838038
🎯 TRANSACTION CIBLE 2817 INSEREE  | PAYMENTREF=YYY | MONTANT=2817  | CLIENT=90141615
```

### 3. Test EXISTS avec TA_RN_GESTION_JC
```
Test EXISTS pour compte 394 (BNPP05492-EUR) - 1 transactions a inserer  ✅
Test EXISTS pour compte 342 (BBNP83292-EUR) - 0 transactions a inserer  ❌
```

**→ Si 394 a des transactions mais pas 342, alors le problème est dans TA_RN_GESTION_JC**

### 4. Insertion dans TA_RN_EXPORT_JC
```
INSERT dans TA_RN_EXPORT_JC complete - Compte 394 - 1 lignes inserees  ✅
INSERT dans TA_RN_EXPORT_JC complete - Compte 342 - 0 lignes inserees  ❌
```

---

## 🎯 SCÉNARIOS POSSIBLES

### Scénario A : 2817 n'est PAS dans le XML
**Symptôme :**
```
❌ Transaction 2817 NON TROUVEE dans le XML
```
**Solution :** Vérifier le fichier XML source

---

### Scénario B : 2817 est dans le XML mais pas inséré dans TA_RN_IMPORT_GESTION_JC
**Symptôme :**
```
✅ Transaction 2817 TROUVEE dans le XML
(aucun log "TRANSACTION CIBLE 2817 INSEREE")
```
**Solution :** Vérifier Section 9 (Erreurs) pour voir l'exception lors de l'INSERT

---

### Scénario C : 2817 inséré mais compte 342 NON paramétré dans TA_RN_GESTION_JC ⭐ PLUS PROBABLE
**Symptôme :**
```
✅ Transaction 2817 TROUVEE dans le XML
🎯 TRANSACTION CIBLE 2817 INSEREE
Test EXISTS pour compte 342 - 0 transactions a inserer  ❌
```

**Solution :**
```sql
-- Vérifier le paramétrage
SELECT * FROM TA_RN_GESTION_JC WHERE ID_COMPTE_ACCURATE = 342;
-- Si vide:

-- Récupérer les ID pour 'ALL'
SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = 'ALL';
SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'ALL';

-- Ajouter le compte 342
INSERT INTO TA_RN_GESTION_JC (ID_COMPTE_ACCURATE, ID_PRODUIT, ID_MODE_REGLEMENT)
VALUES (342, <ID_PRODUIT_ALL>, <ID_MODE_REGLEMENT_ALL>);
COMMIT;
```

---

### Scénario D : 2817 passe le test EXISTS mais erreur lors de l'INSERT dans TA_RN_EXPORT_JC
**Symptôme :**
```
Test EXISTS pour compte 342 - 1 transactions a inserer  ✅
INSERT dans TA_RN_EXPORT_JC complete - Compte 342 - 0 lignes inserees  ❌
```
**Solution :** Vérifier Section 9 (Erreurs) pour voir l'exception SQL

---

## 📊 FICHIERS ANNEXES (déjà créés précédemment)

Ces fichiers peuvent être utiles pour l'investigation :

- `VERIF_PARAM_GESTION_JC_394_342.sql` - Vérification du paramétrage TA_RN_GESTION_JC
- `COMPARAISON_COMPLETE_22.36_vs_2817.sql` - Comparaison détaillée des transactions
- `ANALYSE_FLUX_PAYMENTREFERENCE.md` - Analyse du flux PAYMENTREFERENCE dans le script
- `STRUCTURE_TABLES_REFERENCE.txt` - Référence des structures de tables

---

## 🔄 WORKFLOW COMPLET

```
1. PURGE_AVANT_TEST.sql
   ↓
2. Vérifier TX_REGLT_GEST contient le XML
   ↓
3. RNADGENJUCGES01_TRACE_COMPLETE.sql
   ↓
4. ANALYSER_LOGS_22.36_vs_2817.sql
   ↓
5. Interpréter les résultats (GUIDE_EXECUTION_TEST_COMPLET.md)
   ↓
6. Appliquer la solution
   ↓
7. Relancer le test pour vérifier
```

---

## 📝 NOTES IMPORTANTES

### À propos du script RNADGENJUCGES01_TRACE_COMPLETE.sql

**Différences avec le script original :**
- Nom de procédure changé : `PR_RN_IMPORT_GESTION_JC_TRACE` (au lieu de `PR_RN_IMPORT_GESTION_JC`)
- Logs autonomes (PRAGMA AUTONOMOUS_TRANSACTION) pour garder les traces même en cas d'erreur
- Traçage spécifique pour 22.36 et 2817

**⚠️ IMPORTANT :**
- Ce script est une version de TEST, pas de production
- Utilisez-le uniquement en environnement DEV/RECETTE
- Les logs sont verbeux et peuvent ralentir le traitement

### À propos de la table TA_RN_LOG_EXECUTION

**Structure requise :**
```sql
CREATE TABLE TA_RN_LOG_EXECUTION (
    ID_LOG          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    DT_EXECUTION    TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    NOM_PROCEDURE   VARCHAR2(100) NOT NULL,
    TYPE_LOG        VARCHAR2(20) NOT NULL,  -- INFO, DEBUG, WARNING, ERROR, EXCEPTION
    NOM_BALISE      VARCHAR2(100),
    VALEUR_EXTRAITE VARCHAR2(4000),
    MESSAGE         VARCHAR2(4000),
    CODE_ERREUR     VARCHAR2(20),
    STACK_TRACE     CLOB,
    ID_CHARGEMENT   NUMBER,
    ETAPE           NUMBER,
    ID_SESSION      NUMBER DEFAULT SYS_CONTEXT('USERENV','SESSIONID'),
    UTILISATEUR     VARCHAR2(50) DEFAULT USER
);
```

**Si la table n'existe pas :** Créez-la avec le script fourni dans RNADGENJUCGES01_TRACE_COMPLETE.sql (commentaire en début de fichier)

---

## 🎯 RÉSULTAT FINAL ATTENDU

À la fin du test, vous aurez :

1. ✅ Confirmation si 22.36 et 2817 sont dans le XML
2. ✅ Confirmation si les deux sont insérés dans TA_RN_IMPORT_GESTION_JC
3. ✅ Identification du compte accurate associé à chaque transaction
4. ✅ Vérification si ces comptes sont paramétrés dans TA_RN_GESTION_JC
5. ✅ **LA RAISON EXACTE** du blocage de 2817

**Et vous pourrez alors :**
- Corriger le paramétrage (ajout du compte 342 dans TA_RN_GESTION_JC)
- Ou identifier un autre problème technique (contrainte SQL, privilège, etc.)

---

## 📞 TROUBLESHOOTING

### Problème : "Table TA_RN_LOG_EXECUTION does not exist"
**Solution :** Créer la table avec le script fourni en commentaire dans RNADGENJUCGES01_TRACE_COMPLETE.sql

### Problème : "Insufficient privileges"
**Solution :** Demander à votre DBA les privilèges INSERT sur TA_RN_LOG_EXECUTION

### Problème : "Le script prend trop de temps"
**Solution :** C'est normal si vous avez beaucoup de transactions. Les logs sont verbeux.

### Problème : "Aucun log dans TA_RN_LOG_EXECUTION après exécution"
**Solution :** Vérifier que le NOM_PROCEDURE est bien 'PR_RN_IMPORT_GESTION_JC_TRACE' dans la requête d'analyse

---

**Bon test ! 🚀**
