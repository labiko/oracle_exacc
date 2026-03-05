# 🔍 GUIDE D'INVESTIGATION - Pourquoi 22.36 est inséré mais pas 2817 ?

## Date : 07/02/2026

---

## 📊 PROBLÈME

**Situation :**
- ✅ Transaction 22.36 EUR **est insérée** dans `BANKREC.BR_DATA`
- ❌ Transaction 2817 EUR **n'est PAS insérée** dans `BANKREC.BR_DATA`
- ✅ Les DEUX transactions **sont présentes** dans `TA_RN_IMPORT_GESTION_JC`

**Tables intermédiaires vides :**
- `TA_RN_EXPORT_JC` = VIDE (TYPE_RAPPRO='B' bloque les deux comptes)
- `BR_DATA_TEMP` = VIDE (table de travail uniquement)

**Question :** Quel code insère 22.36 dans BR_DATA et pourquoi exclut-il 2817 ?

---

## 🎯 PLAN D'EXÉCUTION

### PHASE 1 : Vérification du paramétrage (PRIORITAIRE)

**Script à exécuter :**
```sql
@VERIF_PARAM_GESTION_JC_394_342.sql
```

**Objectif :** Vérifier si le compte accurate 394 (22.36) est paramétré dans `TA_RN_GESTION_JC` mais pas le compte 342 (2817).

**Résultats attendus :**

| Résultat                          | Interprétation                                    | Action                                |
|-----------------------------------|---------------------------------------------------|---------------------------------------|
| 394 présent, 342 absent           | ✅ Cause identifiée : Paramétrage manquant        | Ajouter 342 dans TA_RN_GESTION_JC     |
| Les deux absents                  | ⚠️ Autre logique de filtrage                     | Passer à PHASE 2                      |
| Les deux présents                 | ⚠️ Problème ailleurs                             | Passer à PHASE 2 + PHASE 3            |

---

### PHASE 2 : Comparaison complète des transactions

**Script à exécuter :**
```sql
@COMPARAISON_COMPLETE_22.36_vs_2817.sql
```

**Objectif :** Comparer TOUS les attributs des deux transactions pour identifier les différences.

**Ce script vérifie :**
1. Attributs d'import (NumeroClient, SettlementMode, BankCode, etc.)
2. Comptes bancaires et leur statut (FLAG_ACTIF)
3. Comptes accurate et TYPE_RAPPRO
4. Paramétrage GESTION_JC
5. Présence dans BR_DATA

---

### PHASE 3 : Recherche du code source d'insertion

**Script à exécuter :**
```sql
@ANALYSE_CODE_PKG_BR_PURGE.sql
```

**Objectif :** Analyser les packages suspects qui pourraient insérer dans BR_DATA.

**Packages analysés :**
1. `PKG_BR_PURGE` (227 références à BR_DATA)
2. `BRT_FILTERED_ITEM` (49 références)
3. `PKG_NXGCRT_SUBMISSION` (42 références)

**Ce script cherche :**
- INSERT...SELECT dans BR_DATA
- Références à TA_RN_IMPORT_GESTION_JC
- Références à COMPTE_ACCURATE
- Filtrage par TYPE_RAPPRO
- Synonymes et DB Links

---

### PHASE 4 : Recherche dans les fichiers SQL (si PHASE 3 échoue)

**A. Sur Windows (PowerShell) :**
```powershell
cd c:\Users\diall\Documents\IonicProjects\Claude\RECHERCHER\DIVERS\BNNP_SQL
.\GREP_RECHERCHE_INSERTION_BR_DATA.ps1
```

**B. Sur Linux (Bash) :**
```bash
cd /path/to/BNNP_SQL
chmod +x GREP_RECHERCHE_INSERTION_BR_DATA.sh
./GREP_RECHERCHE_INSERTION_BR_DATA.sh
```

**C. Commandes manuelles rapides :**

**Windows PowerShell :**
```powershell
# Trouver INSERT dans BR_DATA
Select-String -Path "*.sql" -Pattern "INSERT.*BR_DATA" -Context 10,10

# Trouver fichiers avec les deux tables
$files = Select-String -Path "*.sql" -Pattern "TA_RN_IMPORT" | Select -Unique -ExpandProperty Path
$files | Where-Object { (Select-String -Path $_ -Pattern "BR_DATA" -Quiet) }
```

**Linux :**
```bash
# Trouver INSERT dans BR_DATA avec contexte
grep -rn -A 10 -B 10 "INSERT.*BR_DATA" . --include="*.sql"

# Trouver fichiers avec les deux tables
grep -l "TA_RN_IMPORT_GESTION_JC" *.sql | xargs grep -l "BR_DATA"
```

---

### PHASE 5 : Recherche avancée dans le dictionnaire Oracle

**Script à exécuter :**
```sql
@CHERCHER_LIEN_IMPORT_BRDATA.sql
```

**Objectif :** Chercher dans le dictionnaire Oracle (DBA_SOURCE, DBA_SYNONYMS, DBA_VIEWS, etc.)

**Ce script cherche :**
1. Packages référençant TA_RN_IMPORT_GESTION_JC ET BR_DATA
2. Packages dans EXP_RNAPA qui référencent BR_DATA
3. DB Links entre EXP_RNAPA et BANKREC
4. Synonymes pointant vers BR_DATA
5. Vues joignant les tables
6. Jobs scheduler

---

## 📋 FICHIERS CRÉÉS

| Fichier                                       | Type      | Objectif                                          |
|-----------------------------------------------|-----------|---------------------------------------------------|
| `PLAN_INVESTIGATION_INSERTION_BR_DATA.md`     | Doc       | Plan stratégique d'investigation                  |
| `VERIF_PARAM_GESTION_JC_394_342.sql`          | SQL       | **PRIORITAIRE** - Vérif paramétrage comptes       |
| `COMPARAISON_COMPLETE_22.36_vs_2817.sql`      | SQL       | Comparaison détaillée des transactions            |
| `ANALYSE_CODE_PKG_BR_PURGE.sql`               | SQL       | Analyse packages suspects                         |
| `GREP_RECHERCHE_INSERTION_BR_DATA.ps1`        | PowerShell| Recherche dans fichiers SQL (Windows)             |
| `GREP_RECHERCHE_INSERTION_BR_DATA.sh`         | Bash      | Recherche dans fichiers SQL (Linux)               |
| `CHERCHER_LIEN_IMPORT_BRDATA.sql`             | SQL       | Recherche dans dictionnaire Oracle                |
| `README_INVESTIGATION_BR_DATA.md`             | Doc       | **CE FICHIER** - Guide complet                    |

**Fichiers existants utilisés :**
- `STRUCTURE_TABLES_REFERENCE.txt` - Structure des tables
- `DIAGNOSTIC_INSERTION_22.36_vs_2817.md` - Diagnostic initial
- `ANALYSE_INSERTION_BR_DATA.sql` - Première analyse
- `ANALYSE_FLUX_BR_DATA.sql` - Analyse des flux

---

## ⚡ DÉMARRAGE RAPIDE

**Exécution en séquence (recommandé) :**

```sql
-- Dans SQL Developer ou SQL*Plus
@VERIF_PARAM_GESTION_JC_394_342.sql
-- Analyser le résultat, puis :

@COMPARAISON_COMPLETE_22.36_vs_2817.sql
-- Analyser le résultat, puis :

@ANALYSE_CODE_PKG_BR_PURGE.sql
-- Analyser le résultat, puis si besoin :

@CHERCHER_LIEN_IMPORT_BRDATA.sql
```

**Puis recherche dans les fichiers (si besoin) :**

```powershell
# Windows
.\GREP_RECHERCHE_INSERTION_BR_DATA.ps1 > resultats_grep.txt
```

---

## 🎯 HYPOTHÈSES PRINCIPALES

### Hypothèse 1 : Paramétrage manquant (PLUS PROBABLE)

Le compte accurate **394** (BNPP05492-EUR) est paramétré dans `TA_RN_GESTION_JC`, mais pas le compte **342** (BBNP83292-EUR).

**Solution :** Ajouter le compte 342 dans TA_RN_GESTION_JC :

```sql
-- Vérifier d'abord les ID_PRODUIT et ID_MODE_REGLEMENT pour 'ALL'
SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = 'ALL';        -- Ex: 999
SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'ALL';  -- Ex: 999

-- Insérer le paramétrage pour le compte 342
INSERT INTO TA_RN_GESTION_JC (ID_COMPTE_ACCURATE, ID_PRODUIT, ID_MODE_REGLEMENT)
VALUES (342, 999, 999);  -- Remplacer 999 par les vrais ID

COMMIT;
```

### Hypothèse 2 : Package spécifique pour TYPE_RAPPRO='B'

Il existe un package qui traite spécifiquement les comptes avec `TYPE_RAPPRO='B'` (au lieu de 'J'), avec une logique de filtrage basée sur le compte accurate.

**Indicateurs :**
- Rechercher dans les packages `PKG_BR_PURGE`, `BRT_FILTERED_ITEM`, `PKG_NXGCRT_SUBMISSION`
- Chercher les références à `TYPE_RAPPRO='B'`

### Hypothèse 3 : Processus externe

Une application Java ou un batch externe lit `TA_RN_IMPORT_GESTION_JC` et écrit dans `BANKREC.BR_DATA` via JDBC.

**Indicateurs :**
- Aucun package Oracle trouvé avec INSERT dans BR_DATA
- Présence de jobs externes dans le scheduler
- Logs applicatifs externes

---

## 📊 MATRICE DE DÉCISION

```
PHASE 1 : VERIF_PARAM_GESTION_JC_394_342.sql
    │
    ├─→ 394 présent, 342 absent
    │       → ✅ CAUSE IDENTIFIÉE : Ajouter 342 dans GESTION_JC
    │
    ├─→ Les deux absents
    │       → PHASE 2 + PHASE 3 : Analyser packages
    │
    └─→ Les deux présents
            → PHASE 2 : Comparer transactions complètes
            → PHASE 3 : Analyser code packages
            → PHASE 5 : Recherche dictionnaire Oracle
```

---

## 🔧 COMMANDES UTILES

### Vérifier l'état actuel

```sql
-- Vérifier TA_RN_IMPORT_GESTION_JC
SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '22.36';  -- Doit être > 0
SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION_JC WHERE OPERATIONNETAMOUNT = '2817';   -- Doit être > 0

-- Vérifier TA_RN_EXPORT_JC
SELECT COUNT(*) FROM TA_RN_EXPORT_JC WHERE ORAMT IN ('22.36', '2817');  -- Devrait être 0

-- Vérifier BR_DATA
SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE AMOUNT = 22.36;   -- Doit être > 0
SELECT COUNT(*) FROM BANKREC.BR_DATA WHERE AMOUNT = 2817;    -- Doit être 0
```

### Analyser les logs

```sql
-- Vérifier les logs d'exécution
SELECT *
FROM TA_RN_LOG_EXECUTION
WHERE COMMENTAIRE LIKE '%22.36%' OR COMMENTAIRE LIKE '%2817%'
ORDER BY DATE_EXECUTION DESC;
```

### Chercher les triggers

```sql
-- Vérifier s'il existe des triggers sur TA_RN_IMPORT_GESTION_JC
SELECT
    TRIGGER_NAME,
    TRIGGER_TYPE,
    TRIGGERING_EVENT,
    STATUS
FROM DBA_TRIGGERS
WHERE TABLE_NAME = 'TA_RN_IMPORT_GESTION_JC'
  AND TABLE_OWNER = 'EXP_RNAPA';
```

---

## 📝 NOTES IMPORTANTES

1. **TYPE_RAPPRO='B' vs 'J' :**
   - Les deux comptes (394 et 342) ont `TYPE_RAPPRO='B'`
   - Le script `RNADGENJUCGES01.sql` filtre uniquement `TYPE_RAPPRO='J'`
   - Donc il existe FORCÉMENT un autre chemin d'insertion

2. **Tables intermédiaires vides :**
   - `TA_RN_EXPORT_JC` est vide (normal, les comptes sont bloqués par TYPE_RAPPRO)
   - `BR_DATA_TEMP` est vide (table de travail uniquement)
   - L'insertion se fait directement depuis `TA_RN_IMPORT_GESTION_JC` vers `BR_DATA`

3. **Schémas concernés :**
   - `EXP_RNAPA` : Schéma source (TA_RN_IMPORT_GESTION_JC, TA_RN_COMPTE_ACCURATE, etc.)
   - `BANKREC` : Schéma cible (BR_DATA)
   - Possible DB Link ou synonyme entre les deux

---

## 🚀 PROCHAINES ÉTAPES

1. ✅ **IMMÉDIAT** : Exécuter `VERIF_PARAM_GESTION_JC_394_342.sql`
2. ⏳ **SI BESOIN** : Exécuter `COMPARAISON_COMPLETE_22.36_vs_2817.sql`
3. ⏳ **SI BESOIN** : Exécuter `ANALYSE_CODE_PKG_BR_PURGE.sql`
4. ⏳ **SI BESOIN** : Recherche grep dans les fichiers SQL
5. ⏳ **SI BESOIN** : Exécuter `CHERCHER_LIEN_IMPORT_BRDATA.sql`

---

## ✅ RÉSULTAT ATTENDU

À la fin de cette investigation, vous devriez avoir identifié :

1. **LE FICHIER** : Package/Procédure/Script exact qui insère dans BR_DATA
2. **LA CONDITION** : Logique de filtrage qui accepte 394 mais refuse 342
3. **LA SOLUTION** : Action corrective (paramétrage, correction code, etc.)

---

**Bon courage ! 🚀**
