# 🔍 ANALYSE FLUX PAYMENTREFERENCE - Script RNADGENJUCGES01.sql

## Date : 07/02/2026

---

## 📋 OBJECTIF

Tracer le flux du PAYMENTREFERENCE de 22.36 vs 2817 à travers le script d'intégration pour identifier **où** et **pourquoi** 22.36 est inséré dans BR_DATA mais pas 2817.

---

## 🔄 FLUX IDENTIFIÉ DANS RNADGENJUCGES01.sql

### ÉTAPE 1 : INSERT INTO TA_RN_IMPORT_GESTION_JC (Ligne 762)

**Code :**
```sql
EXECUTE IMMEDIATE 'INSERT INTO TA_RN_IMPORT_GESTION_JC '||ListeChampsImport||' '||'VALUES '||ListeValeursImport;
```

**Variables utilisées :**
- `Var_PAYMENTREFERENCE` (ligne 770) ← **PAYMENTREFERENCE du XML**
- `Var_OPERATIONNETAMOUNT` (ligne 782) ← **Montant (22.36 ou 2817)**
- `Var_NUMEROCLIENT` (ligne 772) ← **NumeroClient**
- `Var_SETTLEMENTMODE` (ligne 774) ← **SettlementMode (VO)**

**Résultat :**
- ✅ **22.36** inséré dans TA_RN_IMPORT_GESTION_JC avec son PAYMENTREFERENCE
- ✅ **2817** inséré dans TA_RN_IMPORT_GESTION_JC avec son PAYMENTREFERENCE

**→ LES DEUX TRANSACTIONS SONT IMPORTÉES**

---

### ÉTAPE 2 : Curseur Curseur_ZonesParCompte (Ligne 173-192)

**Code :**
```sql
CURSOR Curseur_ZonesParCompte IS
SELECT DISTINCT
    TA_RN_COMPTE_ACCURATE.ID_COMPTE_ACCURATE,
    TA_RN_COMPTE_ACCURATE.NUM_COMPTE_ACCURATE,
    ...
WHERE TA_RN_COMPTE_ACCURATE.FLAG_ACTIF='O'
  AND TA_RN_COMPTE_ACCURATE.TYPE_RAPPRO='J'  ← ⚠️ FILTRE CRITIQUE !
  ...
```

**Filtrage :**
- Ligne 184 : `TYPE_RAPPRO='J'`
- Nos comptes :
  - Compte 394 (22.36) : TYPE_RAPPRO='**B**' ❌
  - Compte 342 (2817) : TYPE_RAPPRO='**B**' ❌

**Résultat :**
- ❌ **22.36** : Compte accurate 394 **NON traité** par ce curseur
- ❌ **2817** : Compte accurate 342 **NON traité** par ce curseur

**→ LE CURSEUR NE TRAITE PAS NOS COMPTES**

---

### ÉTAPE 3 : INSERT INTO TA_RN_EXPORT_JC (Ligne 891-902)

**Code :**
```sql
EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT_JC (SOURCE,ACCNUM,'||ListeChampsExport||')'
    ||' ('
    ||'SELECT '||''''||Var_Source||''''||','||''''||Var_Ref_NUM_COMPTE_ACCURATE||''''||','||ListeValeursImport
    ||' FROM TA_RN_IMPORT_GESTION_JC WHERE '
    ||' EXISTS (SELECT 1 FROM TA_RN_MODE_REGLEMENT, TA_RN_PRODUIT, TA_RN_GESTION_JC'
            ||' WHERE  TA_RN_MODE_REGLEMENT.ID_MODE_REGLEMENT = TA_RN_GESTION_JC.ID_MODE_REGLEMENT'
            ||' AND TA_RN_PRODUIT.ID_PRODUIT = TA_RN_GESTION_JC.ID_PRODUIT'
            ||' AND TA_RN_GESTION_JC.ID_COMPTE_ACCURATE = '||Var_Ref_ID_COMPTE_ACCURATE  ← ⚠️ FILTRE PAR COMPTE
            ||' AND (TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=''ALL'' OR TA_RN_MODE_REGLEMENT.CODE_MODE_REGLEMENT=SETTLEMENTMODE)'
            ||' AND (TA_RN_PRODUIT.CODE_PRODUIT=''ALL'' OR TA_RN_PRODUIT.CODE_PRODUIT=NUMEROCLIENT))'
    ||' AND ID_CHARGEMENT_GESTION = '||Var_ID_CHARGEMENT_GESTION
    ||')';
```

**Condition EXISTS (lignes 895-900) :**
1. Jointure avec `TA_RN_GESTION_JC`
2. Filtre : `ID_COMPTE_ACCURATE = Var_Ref_ID_COMPTE_ACCURATE` (ligne 898)
3. Filtre : `CODE_MODE_REGLEMENT='ALL' OR CODE_MODE_REGLEMENT=SETTLEMENTMODE` (ligne 899)
4. Filtre : `CODE_PRODUIT='ALL' OR CODE_PRODUIT=NUMEROCLIENT` (ligne 900)

**Variable `Var_Ref_ID_COMPTE_ACCURATE` :**
- Cette variable provient du curseur `Curseur_ZonesParCompte`
- Comme le curseur filtre par `TYPE_RAPPRO='J'`, ce INSERT n'est **JAMAIS exécuté** pour nos comptes !

**Résultat :**
- ❌ **22.36** : **PAS inséré** dans TA_RN_EXPORT_JC
- ❌ **2817** : **PAS inséré** dans TA_RN_EXPORT_JC

**→ TA_RN_EXPORT_JC RESTE VIDE (confirmé par l'utilisateur)**

---

### ÉTAPE 4 : INSERT écriture de contrepartie (Ligne 925-934)

**Code :**
```sql
EXECUTE IMMEDIATE 'INSERT INTO TA_RN_EXPORT_JC (SOURCE,ACCNUM,'||ListeChampsExport||')'
    ||' FROM '
    ||' (SELECT DATECREATION,...,'
    ||''''||''''||' AS PAYMENTREFERENCE,'  ← ⚠️ PAYMENTREFERENCE VIDÉ !
    ...
```

**Ligne 930 :** PAYMENTREFERENCE est mis à vide (`''''||''''`)

**Raison :** C'est une écriture de cumul/extourne (ligne 934: 'Ecriture extourne')

**Résultat :**
- Cette insertion ne conserve PAS le PAYMENTREFERENCE d'origine
- Comme elle est aussi dans la boucle du curseur TYPE_RAPPRO='J', elle n'est pas exécutée pour nos comptes

---

## 🔴 CONCLUSION CRITIQUE

### Ce que le script RNADGENJUCGES01.sql fait :

1. ✅ **Importe TOUTES les transactions** (22.36 et 2817) dans `TA_RN_IMPORT_GESTION_JC`
2. ❌ **N'exporte AUCUNE** de nos transactions dans `TA_RN_EXPORT_JC` car :
   - Le curseur `Curseur_ZonesParCompte` filtre par `TYPE_RAPPRO='J'`
   - Nos comptes ont `TYPE_RAPPRO='B'`
3. ❌ **Ne touche PAS** à `BANKREC.BR_DATA`

### Ce que le script NE fait PAS :

- **N'insère RIEN dans BR_DATA**
- **Aucune référence à BR_DATA** dans tout le script

---

## ⚠️ PROBLÈME IDENTIFIÉ

**Si 22.36 est dans BANKREC.BR_DATA, alors il existe FORCÉMENT un AUTRE script/package qui :**

1. **Lit** `TA_RN_IMPORT_GESTION_JC`
2. **Filtre** les comptes avec `TYPE_RAPPRO='B'` (ou sans filtrage TYPE_RAPPRO)
3. **Applique un filtrage** basé sur `TA_RN_GESTION_JC` :
   - ✅ Compte 394 (22.36) → **paramétré** dans TA_RN_GESTION_JC
   - ❌ Compte 342 (2817) → **NON paramétré** dans TA_RN_GESTION_JC
4. **Insère** dans `BANKREC.BR_DATA`

---

## 🎯 HYPOTHÈSE FORTE

### Le filtrage se fait dans un autre package/script qui contient :

```sql
INSERT INTO BANKREC.BR_DATA (...)
SELECT ...
FROM TA_RN_IMPORT_GESTION_JC IMP
    JOIN TA_RN_COMPTE_BANCAIRE CB ON CB.IDENTIFICATION = SUBSTR(IMP.IDENTIFICATIONRIB, -11)
    JOIN TA_RN_PERIMETRE_BANQUE PB ON PB.ID_COMPTE_BANCAIRE = CB.ID_COMPTE_BANCAIRE
    JOIN TA_RN_BANQUE_ACCURATE BA ON BA.ID_PERIMETRE_BANQUE = PB.ID_PERIMETRE_BANQUE
    JOIN TA_RN_COMPTE_ACCURATE CA ON CA.ID_COMPTE_ACCURATE = BA.ID_COMPTE_ACCURATE
WHERE CA.TYPE_RAPPRO = 'B'  ← Filtre pour les comptes bancaires
  AND EXISTS (
      SELECT 1
      FROM TA_RN_GESTION_JC GJ
      WHERE GJ.ID_COMPTE_ACCURATE = CA.ID_COMPTE_ACCURATE  ← ⚠️ FILTRAGE ICI !
        AND ...
  )
```

**Le filtrage se produit sur la ligne :** `WHERE GJ.ID_COMPTE_ACCURATE = CA.ID_COMPTE_ACCURATE`

**Résultat :**
- Compte 394 présent dans TA_RN_GESTION_JC → 22.36 **passe** ✅
- Compte 342 absent de TA_RN_GESTION_JC → 2817 **bloqué** ❌

---

## 🔧 ACTIONS IMMÉDIATES

### 1. Vérifier le paramétrage TA_RN_GESTION_JC

```sql
-- Exécuter immédiatement :
@VERIF_PARAM_GESTION_JC_394_342.sql
```

**Si résultat = "394 présent, 342 absent" → CAUSE IDENTIFIÉE !**

### 2. Chercher le package qui insère dans BR_DATA

**Méthode 1 : Recherche dans DBA_SOURCE**
```sql
SELECT OWNER, NAME, TYPE, LINE, TEXT
FROM DBA_SOURCE
WHERE UPPER(TEXT) LIKE '%INSERT%BR_DATA%'
  AND UPPER(TEXT) LIKE '%TA_RN_IMPORT%'
  AND TYPE IN ('PACKAGE BODY', 'PROCEDURE')
ORDER BY OWNER, NAME, LINE;
```

**Méthode 2 : Recherche dans fichiers SQL (PowerShell)**
```powershell
Select-String -Path "*.sql","*.pkb","*.prc" -Pattern "INSERT.*BR_DATA" -Context 10,10
```

### 3. Chercher les packages qui traitent TYPE_RAPPRO='B'

```sql
SELECT DISTINCT OWNER, NAME, TYPE
FROM DBA_SOURCE
WHERE UPPER(TEXT) LIKE '%TYPE_RAPPRO%'
  AND UPPER(TEXT) LIKE '%''B''%'
  AND TYPE IN ('PACKAGE BODY', 'PROCEDURE')
ORDER BY OWNER, NAME;
```

---

## 📊 RÉSUMÉ VISUEL DU FLUX

```
XML FILE
   │
   ├─→ PAYMENTREFERENCE (22.36) = "REF_22_36"
   │   PAYMENTREFERENCE (2817)  = "REF_2817"
   │
   ▼
┌─────────────────────────────────────────┐
│ TA_RN_IMPORT_GESTION_JC                 │
│ ✅ 22.36 + PAYMENTREFERENCE             │
│ ✅ 2817  + PAYMENTREFERENCE             │
└─────────────────────────────────────────┘
   │
   │ RNADGENJUCGES01.sql (TYPE_RAPPRO='J')
   │ → Curseur filtre TYPE_RAPPRO='J'
   │ → Nos comptes ont TYPE_RAPPRO='B'
   │ → Rien n'est exporté
   │
   ▼
┌─────────────────────────────────────────┐
│ TA_RN_EXPORT_JC                         │
│ ❌ VIDE (TYPE_RAPPRO='J' requis)        │
└─────────────────────────────────────────┘

   ⚠️ CHEMIN ALTERNATIF (à identifier) ⚠️

┌─────────────────────────────────────────┐
│ TA_RN_IMPORT_GESTION_JC                 │
│ ✅ 22.36 + PAYMENTREFERENCE             │
│ ✅ 2817  + PAYMENTREFERENCE             │
└─────────────────────────────────────────┘
   │
   │ SCRIPT/PACKAGE INCONNU (TYPE_RAPPRO='B')
   │ → Filtre par TA_RN_GESTION_JC
   │ → Compte 394 (22.36) DANS GESTION_JC ✅
   │ → Compte 342 (2817) PAS DANS GESTION_JC ❌
   │
   ▼
┌─────────────────────────────────────────┐
│ BANKREC.BR_DATA                         │
│ ✅ 22.36 INSÉRÉ                         │
│ ❌ 2817 BLOQUÉ                          │
└─────────────────────────────────────────┘
```

---

## ✅ SOLUTION PROBABLE

**Si le compte 394 est paramétré dans TA_RN_GESTION_JC mais pas le 342 :**

```sql
-- Récupérer les ID pour 'ALL'
SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = 'ALL';
SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'ALL';

-- Ajouter le compte 342 dans GESTION_JC
INSERT INTO TA_RN_GESTION_JC (ID_COMPTE_ACCURATE, ID_PRODUIT, ID_MODE_REGLEMENT)
VALUES (342, <ID_PRODUIT_ALL>, <ID_MODE_REGLEMENT_ALL>);

COMMIT;
```

---

## 📝 FICHIERS À EXÉCUTER (dans l'ordre)

1. ✅ **VERIF_PARAM_GESTION_JC_394_342.sql** - PRIORITAIRE
2. ✅ **CHERCHER_INSERT_DANS_SCRIPTS.ps1** - Trouver le script qui insère dans BR_DATA
3. ✅ **ANALYSE_CODE_PKG_BR_PURGE.sql** - Analyser les packages suspects

---

**CONCLUSION : Le script RNADGENJUCGES01.sql n'insère PAS dans BR_DATA. Il faut identifier le script/package qui le fait.**
