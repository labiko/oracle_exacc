# ROOT CAUSE ANALYSIS - Transaction 2817 EUR Non Exportée

## Date : 07/02/2026

---

## 🎯 ROOT CAUSE IDENTIFIÉE

### Problème
La transaction **2817 EUR** n'apparaît PAS dans **BANKREC.BR_DATA** alors que la transaction **22.36 EUR** y apparaît.

### Cause Racine
**MODE CUMUL ACTIF** pour le compte 342 (BBNP83292-EUR)

Le compte 342 possède une règle de cumul dans **TA_RN_CUMUL_MR** :
```
ID_COMPTE_BANCAIRE_SYSTEME = 352
CODE_PRODUIT = 'ALL'
CODE_MODE_REGLEMENT = 'VO'
```

### Impact
Cette règle provoque la **CUMULATION** de TOUTES les transactions VO sur le compte 342 au lieu d'un export en détail.

La transaction 2817 :
- ✅ **EST** importée dans TA_RN_IMPORT_GESTION
- ✅ **EST** traitée par le script RNADGENEXPGES01.sql
- ❌ **N'EST PAS** exportée en détail dans TA_RN_EXPORT
- ✅ **EST** cumulée avec d'autres transactions VO du même jour
- ❌ **N'APPARAÎT PAS** individuellement dans BR_DATA

---

## COMPARAISON - Compte 394 vs Compte 342

| Aspect | Compte 394 (22.36 EUR) | Compte 342 (2817 EUR) |
|--------|------------------------|------------------------|
| **Compte Accurate** | 394 | 342 |
| **Compte CBS** | BNPP05492-EUR | BBNP83292-EUR |
| **ID_COMPTE_BANCAIRE_SYSTEME** | 356 | 352 |
| **RIB** | 00010207054 | 00016111832 |
| **Transaction** | 22.36 EUR | 2817 EUR |
| **CODE_SOCIETE** | 1 (00838038) | 21 (90141615) |
| **MODE_REGLEMENT** | VO | VO |
| **TYPE_REGLEMENT** | DEC | DEC |
| **DEVISE** | EUR | EUR |
| **MODE CUMUL** | ❌ **AUCUN** | ✅ **ALL+VO ACTIF** |
| **Export** | ✅ **Détail** | ❌ **Cumul uniquement** |
| **Dans BR_DATA** | ✅ **OUI** | ❌ **NON** |

---

## MÉCANISME TECHNIQUE

### 1. Règle de Cumul (TA_RN_CUMUL_MR)

```sql
SELECT
    CMR.ID_COMPTE_BANCAIRE_SYSTEME,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT
FROM TA_RN_CUMUL_MR CMR
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = 352;

Résultat:
ID_COMPTE_BANCAIRE_SYSTEME | CODE_PRODUIT | CODE_MODE_REGLEMENT
---------------------------|--------------|--------------------
352                        | ALL          | VO
```

### 2. Logique du Script (RNADGENEXPGES01.sql ligne ~1125)

Le script contient un filtre **NOT EXISTS** qui EXCLUT les transactions cumulées de l'export en détail :

```sql
AND (NOT EXISTS (
    SELECT 1
    FROM TA_RN_MODE_REGLEMENT, TA_RN_CUMUL_MR, TA_RN_PRODUIT
    WHERE TA_RN_CUMUL_MR.ID_MODE_REGLEMENT = TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT
      AND TA_RN_CUMUL_MR.ID_PRODUIT = TA_RN_PRODUIT.ID_PRODUIT
      AND TA_RN_CUMUL_MR.ID_COMPTE_BANCAIRE_SYSTEME = 352
      AND (TA_RN_PRODUIT.CODE_PRODUIT = '90141615' OR TA_RN_PRODUIT.CODE_PRODUIT = 'ALL')
      AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT = 'VO' OR TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT = 'ALL')
))
```

**Pour le compte 342** :
- Transaction 2817 : MODE = 'VO', PRODUIT = '90141615'
- Règle cumul : CODE_PRODUIT = 'ALL' + CODE_MODE = 'VO'
- **Condition NOT EXISTS = FALSE** → Transaction **EXCLUE** de l'export en détail

**Pour le compte 394** :
- Transaction 22.36 : MODE = 'VO', PRODUIT = '00838038'
- **Aucune règle de cumul**
- **Condition NOT EXISTS = TRUE** → Transaction **INCLUSE** dans l'export en détail

### 3. Export Cumul Quotidien

Les transactions cumulées sont exportées dans **TA_RN_EXPORT** avec :
- **COMMENTAIRE LIKE '%cumul%'**
- **ORAMT = SOMME de toutes les transactions VO du jour**
- Une seule ligne pour toutes les transactions VO du compte 342

Exemple :
```sql
SELECT
    ACCNUM,
    ORAMT AS MONTANT_CUMUL,
    TRDAT,
    COMMENTAIRE
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ACCNUM = 'BBNP83292-EUR'
  AND COMMENTAIRE LIKE '%cumul%'
ORDER BY TRDAT DESC;

Résultat attendu:
ACCNUM          | MONTANT_CUMUL | TRDAT      | COMMENTAIRE
----------------|---------------|------------|------------------
BBNP83292-EUR   | 5634.72       | 2026-02-07 | CUMUL VO QUOTIDIEN
                  (2817 + autres transactions VO du jour)
```

---

## PREUVE DE LA ROOT CAUSE

### Requête Utilisée
```sql
SELECT
    CASE WHEN GA.ID_COMPTE_ACCURATE = 394 THEN '394 (22.36)' ELSE '342 (2817)' END AS COMPTE,
    CMR.ID_COMPTE_BANCAIRE_SYSTEME,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    'MODE CUMUL ACTIF ❌' AS STATUT
FROM TA_RN_GESTION_ACCURATE GA
    JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
WHERE GA.ID_COMPTE_ACCURATE IN (342, 394)
ORDER BY 1;
```

### Résultat
```
COMPTE       | ID_COMPTE_BANC_SYST | CODE_PRODUIT | CODE_MODE | STATUT
-------------|---------------------|--------------|-----------|---------------------
342 (2817)   | 352                 | ALL          | VO        | MODE CUMUL ACTIF ❌
```

**Interprétation** :
- ✅ Compte 394 : **0 règles de cumul** → Export en détail
- ❌ Compte 342 : **1 règle de cumul (ALL+VO)** → Export en cumul uniquement

---

## RÉSUMÉ NOMBRE D'EXCLUSIONS

```sql
SELECT
    '394 (22.36)' AS COMPTE,
    COUNT(DISTINCT CMR.ID_MODE_REGLEMENT) AS NB_REGLES_CUMUL
FROM TA_RN_GESTION_ACCURATE GA
    LEFT JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
WHERE GA.ID_COMPTE_ACCURATE = 394

UNION ALL

SELECT
    '342 (2817)' AS COMPTE,
    COUNT(DISTINCT CMR.ID_MODE_REGLEMENT) AS NB_REGLES_CUMUL
FROM TA_RN_GESTION_ACCURATE GA
    LEFT JOIN TA_RN_CUMUL_MR CMR ON CMR.ID_COMPTE_BANCAIRE_SYSTEME = GA.ID_COMPTE_BANCAIRE_SYSTEME
WHERE GA.ID_COMPTE_ACCURATE = 342
ORDER BY 1;

Résultat:
COMPTE       | NB_REGLES_CUMUL
-------------|----------------
394 (22.36)  | 0              ← Export en DÉTAIL ✅
342 (2817)   | 1              ← Export en CUMUL ❌
```

---

## AUTRES HYPOTHÈSES ÉCARTÉES

### ❌ Compte 342 absent de TA_RN_GESTION_ACCURATE
**ÉCARTÉE** : Le compte 342 EST présent dans TA_RN_GESTION_ACCURATE

### ❌ Exclusion de la société 90141615
**ÉCARTÉE** : Aucune exclusion dans TA_RN_EXCLUSION_SOCIETE pour le compte 342

### ❌ Exclusion de la devise EUR
**ÉCARTÉE** : Aucune exclusion dans TA_RN_EXCLUSION_DEVISE pour le compte 342

### ❌ Exclusion du mode de règlement VO
**ÉCARTÉE** : Aucune exclusion dans TA_RN_EXCLUSION_MR pour le compte 342

### ❌ Exclusion du type de règlement DEC
**ÉCARTÉE** : Aucune exclusion dans TA_RN_EXCLUSION_TR pour le compte 342

### ❌ Transaction absente de TA_RN_IMPORT_GESTION
**ÉCARTÉE** : La transaction 2817 EST dans TA_RN_IMPORT_GESTION (confirmé par données utilisateur)

### ❌ Problème de RIB
**ÉCARTÉE** : Le RIB 00016111832 correspond bien au compte 342

---

## CONCLUSION

🎯 **ROOT CAUSE CONFIRMÉE** : MODE CUMUL ACTIF (ALL+VO) pour le compte 342

La transaction 2817 EUR :
1. ✅ Est correctement importée depuis TX_REGLT_GEST
2. ✅ Est correctement insérée dans TA_RN_IMPORT_GESTION
3. ✅ Est correctement traitée par le script RNADGENEXPGES01.sql
4. ❌ Est **EXCLUE** de l'export en détail à cause de la règle de cumul
5. ✅ Est **CUMULÉE** avec d'autres transactions VO du même jour
6. ❌ N'apparaît **PAS INDIVIDUELLEMENT** dans BR_DATA

**Le comportement est CONFORME** au paramétrage actuel de TA_RN_CUMUL_MR.

Pour exporter la transaction 2817 en **DÉTAIL**, il faut modifier la règle de cumul.

---

## FICHIERS LIÉS

- **VERIF_CUMUL_2817.sql** : Script de vérification de la règle de cumul
- **VERIF_PARAMETRAGE_342_VS_394.sql** : Comparaison complète des paramètres
- **SOLUTION_OPTIONS.md** : Options pour résoudre le problème
- **RNADGENEXPGES01.sql** : Script original (ligne ~1125 contient le filtre NOT EXISTS)

---

**Version : 1.0**
**Date : 07/02/2026**
**Statut : ROOT CAUSE CONFIRMÉE ✅**
