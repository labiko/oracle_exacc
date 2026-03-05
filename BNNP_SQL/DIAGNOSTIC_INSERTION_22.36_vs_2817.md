# 🔍 DIAGNOSTIC : Pourquoi 22.36 est inséré mais pas 2817 ?

## Date : 07/02/2026

---

## 📊 Résultats de l'analyse

### ✅ Section 1 - Les deux comptes bancaires EXISTENT
```
22.36 : ID=267, IDENTIFICATION=00010207054, CARDIF RETRAITE
2817  : ID=237, IDENTIFICATION=00016111832, CARDIF VIE
```

### ✅ Section 2 - Paramétrage GESTION_JC
Les deux transactions matchent avec les MÊMES comptes accurate :
- Comptes accurate : 276, 277, 280, 292
- Produit : ALL (ID=999)
- Mode règlement : ALL (ID=999)

### ✅ Section 3 - Lien COMPTE_BANCAIRE → COMPTE_ACCURATE

**Transaction 22.36 :**
```
RIB 00010207054 (ID=267)
  → PERIMETRE_BANQUE 345 (ACTIF=O)
    → COMPTE_ACCURATE 394 (BNPP05492-EUR, ACTIF=O)
```

**Transaction 2817 :**
```
RIB 00016111832 (ID=237)
  → PERIMETRE_BANQUE 293 (ACTIF=O)
    → COMPTE_ACCURATE 342 (BBNP83292-EUR, ACTIF=O)
```

### ❌ Section 4 - TEST CONDITION : **LES DEUX ÉCHOUENT !**

```
22.36 : CONDITION NON VALIDE - 0 matches
2817  : CONDITION NON VALIDE - 0 matches
```

### ✅ Section 5 - Les deux transactions SONT dans TA_RN_IMPORT_GESTION_JC
```
22.36 : NumeroClient=00838038, SettlementMode=VO
2817  : NumeroClient=90141615, SettlementMode=VO
```

---

## 🔴 PROBLÈME IDENTIFIÉ

### Le test de condition manque la vérification du compte accurate !

La condition complète du script RNADGENJUCGES01.sql (ligne 895-900) est :

```sql
EXISTS (
  SELECT 1
  FROM TA_RN_MODE_REGLEMENT, TA_RN_PRODUIT, TA_RN_GESTION_JC
  WHERE TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT = TA_RN_GESTION_JC.ID_MODE_REGLEMENT
    AND TA_RN_PRODUIT.ID_PRODUIT = TA_RN_GESTION_JC.ID_PRODUIT
    AND TA_RN_GESTION_JC.ID_COMPTE_ACCURATE = [ID_COMPTE]  ← CRITIQUE !
    AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT='ALL' OR CODE='VO')
    AND (TA_RN_PRODUIT.CODE_PRODUIT='ALL' OR CODE='NUMEROCLIENT')
)
```

Le `[ID_COMPTE]` doit être le **compte accurate lié au compte bancaire** de la transaction.

### Comparaison :

| Transaction | Compte Bancaire | Compte Accurate Lié | Comptes dans GESTION_JC |
|-------------|-----------------|---------------------|-------------------------|
| **22.36**   | 00010207054     | **394**             | 276, 277, 280, 292      |
| **2817**    | 00016111832     | **342**             | 276, 277, 280, 292      |

**PROBLÈME** : Ni le compte 394 ni le compte 342 ne sont dans la liste des comptes paramétrés dans TA_RN_GESTION_JC !

---

## 🎯 CONCLUSION

**Les DEUX transactions devraient être REJETÉES** selon la logique du script RNADGENJUCGES01.sql.

Si la transaction 22.36 est effectivement insérée, cela signifie :

### Option 1 : Il y a un autre chemin d'insertion
Il existe peut-être une autre règle ou un autre script qui insère les transactions indépendamment de TA_RN_GESTION_JC.

### Option 2 : Le compte 394 est paramétré ailleurs
Vérifier si le compte accurate 394 (BNPP05492-EUR) existe dans TA_RN_GESTION_JC :

```sql
SELECT * FROM TA_RN_GESTION_JC WHERE ID_COMPTE_ACCURATE = 394;
SELECT * FROM TA_RN_GESTION_JC WHERE ID_COMPTE_ACCURATE = 342;
```

### Option 3 : La transaction 22.36 n'est PAS insérée
Vérifier si la transaction 22.36 est réellement dans TA_RN_EXPORT_JC :

```sql
SELECT * FROM TA_RN_EXPORT_JC
WHERE ORAMT = '22.36'
  AND NARR LIKE '%HUBAIL%';
```

---

## 🔧 ACTIONS RECOMMANDÉES

1. **Vérifier si 22.36 est vraiment insérée :**
   ```sql
   SELECT * FROM TA_RN_EXPORT_JC WHERE ORAMT LIKE '%22.36%';
   ```

2. **Vérifier le paramétrage complet de GESTION_JC :**
   ```sql
   SELECT RGJ.*, RCA.NUM_COMPTE_ACCURATE, RCA.NOM
   FROM TA_RN_GESTION_JC RGJ
   JOIN TA_RN_COMPTE_ACCURATE RCA ON RCA.ID_COMPTE_ACCURATE = RGJ.ID_COMPTE_ACCURATE
   WHERE RGJ.ID_COMPTE_ACCURATE IN (394, 342)
      OR RCA.NUM_COMPTE_ACCURATE IN ('BNPP05492-EUR', 'BBNP83292-EUR');
   ```

3. **Analyser le log d'exécution :**
   ```sql
   SELECT * FROM TA_RN_LOG_EXECUTION
   WHERE COMMENTAIRE LIKE '%22.36%' OR COMMENTAIRE LIKE '%2817%'
   ORDER BY DATE_EXECUTION DESC;
   ```

---

## 📝 HYPOTHÈSE FINALE

**Si 22.36 est insérée mais pas 2817, alors :**
- Le compte accurate 394 (BNPP05492-EUR) est probablement paramétré dans TA_RN_GESTION_JC
- Le compte accurate 342 (BBNP83292-EUR) n'est PAS paramétré

**SOLUTION** : Ajouter le compte 342 dans TA_RN_GESTION_JC avec le couple (PRODUIT=ALL, MODE_REGLEMENT=ALL) :

```sql
INSERT INTO TA_RN_GESTION_JC (ID_COMPTE_ACCURATE, ID_PRODUIT, ID_MODE_REGLEMENT)
VALUES (342, 999, 999);  -- 999 = ID pour 'ALL'
```

