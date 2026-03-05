# 🎯 PLAN D'INVESTIGATION - Insertion 22.36 dans BR_DATA

## Date : 07/02/2026

---

## 📋 RÉSUMÉ DE LA SITUATION

### ✅ Ce que nous savons :

1. **Les deux transactions sont importées :**
   - 22.36 EUR (NumeroClient=00838038, RIB=00010207054) → Compte Accurate 394 (BNPP05492-EUR)
   - 2817 EUR (NumeroClient=90141615, RIB=00016111832) → Compte Accurate 342 (BBNP83292-EUR)

2. **Tables vides :**
   - TA_RN_EXPORT_JC = VIDE (les deux comptes ont TYPE_RAPPRO='B', pas 'J')
   - BR_DATA_TEMP = VIDE (table de travail uniquement)

3. **Résultat final :**
   - BANKREC.BR_DATA contient **UNIQUEMENT 22.36**
   - BANKREC.BR_DATA ne contient **PAS 2817**

4. **Script RNADGENJUCGES01.sql NE PEUT PAS être la source :**
   ```sql
   -- Ligne 173-188 : Filtre TYPE_RAPPRO='J'
   WHERE TA_RN_COMPTE_ACCURATE.TYPE_RAPPRO='J'
   ```
   → Les deux comptes (342 et 394) ont TYPE_RAPPRO='**B**', donc ce script les bloque.

---

## 🔍 HYPOTHÈSES

### Hypothèse 1 : Paramétrage différent dans TA_RN_GESTION_JC

Le compte accurate 394 (BNPP05492-EUR) est paramétré dans TA_RN_GESTION_JC, mais pas le compte 342 (BBNP83292-EUR).

**À vérifier :**
```sql
SELECT * FROM TA_RN_GESTION_JC WHERE ID_COMPTE_ACCURATE IN (394, 342);
```

### Hypothèse 2 : Un autre package lit directement TA_RN_IMPORT_GESTION_JC

Il existe un package dans BANKREC ou EXP_RNAPA qui :
1. Lit TA_RN_IMPORT_GESTION_JC
2. Applique un filtre basé sur le compte accurate
3. Insère dans BR_DATA via un DB Link ou un synonyme

**Packages suspects (trouvés via DBA_SOURCE) :**
- PKG_BR_PURGE (227 références à BR_DATA)
- BRT_FILTERED_ITEM (49 références)
- PKG_NXGCRT_SUBMISSION (42 références)

### Hypothèse 3 : Processus externe (Java/Batch)

Une application externe lit TA_RN_IMPORT_GESTION_JC et écrit dans BANKREC.BR_DATA directement via JDBC.

---

## 🎯 PLAN D'ACTION

### ÉTAPE 1 : Vérifier le paramétrage GESTION_JC pour les comptes 394 et 342

**Script :**
```sql
SELECT
    RGJ.ID_COMPTE_ACCURATE,
    RCA.NUM_COMPTE_ACCURATE,
    RCA.NOM,
    RCA.TYPE_RAPPRO,
    RP.CODE_PRODUIT,
    RMR.CODE_MODE_REGLEMENT
FROM TA_RN_GESTION_JC RGJ
    JOIN TA_RN_COMPTE_ACCURATE RCA ON RCA.ID_COMPTE_ACCURATE = RGJ.ID_COMPTE_ACCURATE
    JOIN TA_RN_PRODUIT RP ON RP.ID_PRODUIT = RGJ.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT RMR ON RMR.ID_MODE_REGLEMENT = RGJ.ID_MODE_REGLEMENT
WHERE RGJ.ID_COMPTE_ACCURATE IN (394, 342)
ORDER BY RGJ.ID_COMPTE_ACCURATE;
```

**Résultat attendu :**
- Si 394 est présent mais pas 342 → **HYPOTHÈSE 1 CONFIRMÉE**
- Si aucun n'est présent → Autre logique de filtrage
- Si les deux sont présents → Problème ailleurs

---

### ÉTAPE 2 : Chercher les packages qui insèrent dans BR_DATA

**Exécuter CHERCHER_LIEN_IMPORT_BRDATA.sql** pour identifier :
1. Packages avec références à TA_RN_IMPORT_GESTION_JC ET BR_DATA
2. DB Links entre EXP_RNAPA et BANKREC
3. Synonymes pointant vers BR_DATA
4. Vues joignant les tables
5. Jobs scheduler

---

### ÉTAPE 3 : Analyser le code source des packages suspects

Pour chaque package trouvé, chercher les INSERT/SELECT :

```sql
-- Exemple pour PKG_BR_PURGE
SELECT
    LINE,
    TEXT
FROM DBA_SOURCE
WHERE OWNER = 'BANKREC'
  AND NAME = 'PKG_BR_PURGE'
  AND TYPE = 'PACKAGE BODY'
  AND (
      UPPER(TEXT) LIKE '%INSERT%BR_DATA%'
      OR UPPER(TEXT) LIKE '%TA_RN_IMPORT%'
      OR UPPER(TEXT) LIKE '%COMPTE_ACCURATE%'
  )
ORDER BY LINE;
```

---

### ÉTAPE 4 : Grep Linux pour trouver tous les scripts SQL

```bash
# Chercher tous les fichiers .sql qui référencent BR_DATA
grep -rn "BR_DATA" . --include="*.sql" | grep -i "INSERT"

# Chercher tous les fichiers qui référencent TA_RN_IMPORT_GESTION_JC
grep -rn "TA_RN_IMPORT_GESTION_JC" . --include="*.sql"

# Chercher les scripts qui référencent les deux tables
grep -l "TA_RN_IMPORT_GESTION_JC" *.sql | xargs grep -l "BR_DATA"
```

---

### ÉTAPE 5 : Analyse comparative des deux transactions

Créer un script qui compare TOUS les attributs des deux transactions pour identifier quelle différence cause le filtrage.

**Fichier à créer : COMPARAISON_22.36_vs_2817.sql**

---

## 🔧 SCRIPTS À EXÉCUTER (dans l'ordre)

1. ✅ **STRUCTURE_TABLES_REFERENCE.txt** - Déjà fait
2. ✅ **ANALYSE_INSERTION_BR_DATA.sql** - Déjà fait
3. ✅ **DIAGNOSTIC_INSERTION_22.36_vs_2817.md** - Déjà fait
4. 🔄 **CHERCHER_LIEN_IMPORT_BRDATA.sql** - À exécuter
5. 🆕 **VERIF_PARAM_GESTION_JC_394_342.sql** - À créer
6. 🆕 **ANALYSE_CODE_PKG_BR_PURGE.sql** - À créer
7. 🆕 **COMPARAISON_22.36_vs_2817.sql** - À créer

---

## 📊 MATRICE DE DÉCISION

| Résultat ÉTAPE 1                     | Conclusion                                        | Action                          |
|--------------------------------------|---------------------------------------------------|---------------------------------|
| 394 présent, 342 absent              | Filtrage par paramétrage GESTION_JC               | Ajouter 342 dans GESTION_JC     |
| Les deux absents                     | Autre logique (package, vue, ou processus externe)| Analyser code packages          |
| Les deux présents                    | Filtrage basé sur autre critère                   | Analyser transaction complète   |

---

## 🎯 OBJECTIF FINAL

Identifier le fichier/package exact qui contient la ligne de code :

```sql
INSERT INTO BANKREC.BR_DATA (...)
SELECT ...
FROM TA_RN_IMPORT_GESTION_JC
WHERE [CONDITION QUI EXCLUT 2817 MAIS ACCEPTE 22.36]
```

Puis comprendre la condition `[...]` pour corriger le paramétrage.

---

## 📝 NOTES

- Si aucun package Oracle ne fait l'insertion, vérifier les applications Java/externes
- Vérifier les logs d'exécution : `SELECT * FROM TA_RN_LOG_EXECUTION ORDER BY DATE_EXECUTION DESC`
- Vérifier les triggers sur TA_RN_IMPORT_GESTION_JC qui pourraient déclencher l'insertion
