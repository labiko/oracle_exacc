# OPTIONS DE SOLUTION - Export Détaillé Transaction 2817 EUR

## Date : 07/02/2026

---

## CONTEXTE

**ROOT CAUSE** : Le compte 342 (BBNP83292-EUR) possède une règle de cumul dans **TA_RN_CUMUL_MR** :
```
ID_COMPTE_BANCAIRE_SYSTEME = 352
CODE_PRODUIT = 'ALL'
CODE_MODE_REGLEMENT = 'VO'
```

Cette règle provoque la **CUMULATION** de toutes les transactions VO au lieu d'un export en détail.

**Objectif** : Permettre l'export de la transaction 2817 EUR **EN DÉTAIL** dans BR_DATA.

---

## OPTION A : SUPPRIMER LA RÈGLE DE CUMUL GLOBALE

### Description
Supprimer complètement la règle de cumul **ALL+VO** pour le compte 342.

### Avantages
- ✅ Solution simple et directe
- ✅ Toutes les transactions VO seront exportées en détail
- ✅ Aucune ambiguïté

### Inconvénients
- ⚠️ Si d'autres transactions VO doivent être cumulées, elles ne le seront plus
- ⚠️ Peut générer un grand volume de transactions en détail
- ⚠️ Nécessite validation fonctionnelle

### Script SQL
```sql
-- ============================================================================
-- OPTION A : Supprimer la règle de cumul ALL+VO pour le compte 342
-- ============================================================================

-- 1. Vérification avant suppression
SELECT
    CMR.ID_COMPTE_BANCAIRE_SYSTEME,
    CBS.NUMERO AS NUM_CBS,
    P.CODE_PRODUIT,
    MR.CODE_MODE_REGLEMENT,
    MR.LIBELLE
FROM TA_RN_CUMUL_MR CMR
    JOIN TA_RN_PRODUIT P ON P.ID_PRODUIT = CMR.ID_PRODUIT
    JOIN TA_RN_MODE_REGLEMENT MR ON MR.ID_MODE_REGLEMENT = CMR.ID_MODE_REGLEMENT
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS ON CBS.ID_COMPTE_BANCAIRE_SYSTEME = CMR.ID_COMPTE_BANCAIRE_SYSTEME
WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = 352;

-- 2. Suppression de la règle
DELETE FROM TA_RN_CUMUL_MR
WHERE ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND ID_PRODUIT = (SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = 'ALL')
  AND ID_MODE_REGLEMENT = (SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'VO');

-- 3. Commit
COMMIT;

-- 4. Vérification après suppression
SELECT COUNT(*) AS NB_REGLES_RESTANTES
FROM TA_RN_CUMUL_MR
WHERE ID_COMPTE_BANCAIRE_SYSTEME = 352;
-- Doit retourner 0
```

### Impact
- **IMMÉDIAT** : Toutes les prochaines transactions VO sur le compte 342 seront exportées en détail
- **RÉVERSIBLE** : Oui, on peut réinsérer la règle

### Recommandation
✅ **À PRIVILÉGIER SI** : Le compte 342 ne doit jamais cumuler les transactions VO

---

## OPTION B : CRÉER UNE EXCLUSION POUR LE PRODUIT 90141615

### Description
Remplacer la règle globale **ALL** par des règles spécifiques pour chaque produit **SAUF** le produit 90141615.

### Avantages
- ✅ Les autres produits continuent d'être cumulés
- ✅ Le produit 90141615 (transaction 2817) est exporté en détail
- ✅ Solution granulaire et précise

### Inconvénients
- ⚠️ Nécessite de connaître la liste de tous les produits à cumuler
- ⚠️ Maintenance plus complexe (ajouter/supprimer des produits)
- ⚠️ Si de nouveaux produits apparaissent, ils ne seront pas cumulés automatiquement

### Script SQL
```sql
-- ============================================================================
-- OPTION B : Exclusion du produit 90141615 du cumul
-- ============================================================================

-- 1. Identifier tous les produits actuellement traités sur le compte 342
SELECT DISTINCT
    IG.NUMEROCLIENT AS CODE_PRODUIT,
    COUNT(*) AS NB_TRANSACTIONS
FROM TA_RN_IMPORT_GESTION IG
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
        ON CBS.RIBBANKCODE||CBS.RIBBRANCHCODE||CBS.RIBIDENTIFICATION||CBS.RIBCHECKDIGIT = IG.IDENTIFICATIONRIB
WHERE CBS.ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND IG.SETTLEMENTMODE = 'VO'
GROUP BY IG.NUMEROCLIENT
ORDER BY 2 DESC;

-- 2. Supprimer la règle ALL
DELETE FROM TA_RN_CUMUL_MR
WHERE ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND ID_PRODUIT = (SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = 'ALL')
  AND ID_MODE_REGLEMENT = (SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'VO');

-- 3. Créer des règles spécifiques pour chaque produit SAUF 90141615
-- Exemple (adapter selon la liste de l'étape 1) :

-- Produit 1 (00838038)
INSERT INTO TA_RN_CUMUL_MR (
    ID_COMPTE_BANCAIRE_SYSTEME,
    ID_PRODUIT,
    ID_MODE_REGLEMENT
)
SELECT
    352,
    P.ID_PRODUIT,
    MR.ID_MODE_REGLEMENT
FROM TA_RN_PRODUIT P
    CROSS JOIN TA_RN_MODE_REGLEMENT MR
WHERE P.CODE_PRODUIT = '00838038'  -- Adapter selon les produits réels
  AND MR.CODE_MODE_REGLEMENT = 'VO'
  AND NOT EXISTS (
      SELECT 1 FROM TA_RN_CUMUL_MR CMR
      WHERE CMR.ID_COMPTE_BANCAIRE_SYSTEME = 352
        AND CMR.ID_PRODUIT = P.ID_PRODUIT
        AND CMR.ID_MODE_REGLEMENT = MR.ID_MODE_REGLEMENT
  );

-- Répéter pour chaque produit SAUF 90141615

-- 4. Commit
COMMIT;

-- 5. Vérification
SELECT
    P.CODE_PRODUIT,
    CASE
        WHEN CMR.ID_PRODUIT IS NOT NULL THEN 'CUMUL ❌'
        ELSE 'DÉTAIL ✅'
    END AS MODE_EXPORT
FROM TA_RN_PRODUIT P
    LEFT JOIN TA_RN_CUMUL_MR CMR
        ON CMR.ID_PRODUIT = P.ID_PRODUIT
       AND CMR.ID_COMPTE_BANCAIRE_SYSTEME = 352
       AND CMR.ID_MODE_REGLEMENT = (SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'VO')
WHERE P.CODE_PRODUIT IN ('00838038', '90141615')  -- Adapter selon produits concernés
ORDER BY P.CODE_PRODUIT;
```

### Impact
- **GRANULAIRE** : Seul le produit 90141615 est exporté en détail
- **RÉVERSIBLE** : Oui, on peut revenir à la règle ALL

### Recommandation
✅ **À PRIVILÉGIER SI** : Plusieurs produits doivent être cumulés SAUF 90141615

---

## OPTION C : VÉRIFIER SI LE CUMUL EST CORRECT

### Description
Avant de modifier le paramétrage, vérifier si la transaction 2817 a été correctement cumulée et exportée dans TA_RN_EXPORT avec un commentaire "cumul".

### Avantages
- ✅ Valide que le processus de cumul fonctionne correctement
- ✅ Permet de confirmer si le problème est dans le cumul ou ailleurs
- ✅ Non destructif (aucune modification)

### Inconvénients
- ⚠️ Ne résout pas le problème si l'objectif est d'avoir un export en détail
- ⚠️ Nécessite d'analyser les cumuls quotidiens

### Script SQL
```sql
-- ============================================================================
-- OPTION C : Vérification du cumul dans TA_RN_EXPORT
-- ============================================================================

-- 1. Rechercher le cumul quotidien pour le compte 342
SELECT
    SOURCE,
    ACCNUM,
    ORAMT AS MONTANT_CUMUL,
    TRDAT AS DATE_TRADE,
    ORAMTCCY AS DEVISE,
    COMMENTAIRE,
    ID_CHARGEMENT
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ACCNUM = 'BBNP83292-EUR'  -- Adapter selon le NUMERO du CBS
  AND COMMENTAIRE LIKE '%cumul%'
ORDER BY TRDAT DESC;

-- 2. Calculer la somme des transactions VO du jour pour vérifier le montant cumul
SELECT
    TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD') AS DATE_TRADE,
    COUNT(*) AS NB_TRANSACTIONS_VO,
    SUM(TO_NUMBER(IG.OPERATIONNETAMOUNT)) AS SOMME_MONTANTS
FROM TA_RN_IMPORT_GESTION IG
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
        ON CBS.RIBBANKCODE||CBS.RIBBRANCHCODE||CBS.RIBIDENTIFICATION||CBS.RIBCHECKDIGIT = IG.IDENTIFICATIONRIB
WHERE CBS.ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND IG.SETTLEMENTMODE = 'VO'
  AND TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD') = '2026-02-07'  -- Adapter selon la date de 2817
GROUP BY TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD');

-- 3. Lister toutes les transactions VO incluses dans le cumul
SELECT
    IG.OPERATIONNETAMOUNT AS MONTANT,
    IG.PAYMENTREFERENCE,
    IG.NUMEROCLIENT AS CODE_CLIENT,
    IG.SETTLEMENTMODE,
    TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD HH24:MI:SS') AS DATE_TRANSACTION
FROM TA_RN_IMPORT_GESTION IG
    JOIN TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
        ON CBS.RIBBANKCODE||CBS.RIBBRANCHCODE||CBS.RIBIDENTIFICATION||CBS.RIBCHECKDIGIT = IG.IDENTIFICATIONRIB
WHERE CBS.ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND IG.SETTLEMENTMODE = 'VO'
  AND TO_CHAR(IG.DATEVALUE, 'YYYY-MM-DD') = '2026-02-07'  -- Adapter selon la date
ORDER BY TO_NUMBER(IG.OPERATIONNETAMOUNT) DESC;

-- 4. Vérifier dans BR_DATA si le cumul y est
SELECT
    ACCNUM,
    ORAMT,
    TRDAT,
    COMMENTAIRE
FROM BANKREC.BR_DATA
WHERE ACCNUM = 'BBNP83292-EUR'  -- Adapter selon le NUMERO du CBS
  AND TRDAT = TO_DATE('2026-02-07', 'YYYY-MM-DD')  -- Adapter selon la date
ORDER BY ORAMT DESC;
```

### Interprétation des Résultats

**CAS 1 : Le cumul est dans TA_RN_EXPORT et BR_DATA**
```
TA_RN_EXPORT:
MONTANT_CUMUL = 5634.72  (2817 + autres VO du jour)
COMMENTAIRE = 'CUMUL VO QUOTIDIEN'

BR_DATA:
ORAMT = 5634.72
```
→ **Le processus fonctionne CORRECTEMENT** mais exporte en CUMUL au lieu de DÉTAIL
→ **Solution** : Appliquer OPTION A ou B pour avoir un export en détail

**CAS 2 : Le cumul est dans TA_RN_EXPORT mais PAS dans BR_DATA**
→ **Problème APRÈS l'export** (processus Oracle Bankrec)
→ **Solution** : Investiguer le processus qui lit TA_RN_EXPORT pour alimenter BR_DATA

**CAS 3 : Le cumul n'est PAS dans TA_RN_EXPORT**
→ **Problème dans le script RNADGENEXPGES01.sql** (logique de cumul défaillante)
→ **Solution** : Exécuter RNADGENEXPGES01_TRACE_COMPLETE.sql pour diagnostiquer

### Recommandation
✅ **À EXÉCUTER EN PREMIER** : Pour comprendre où se situe le problème dans la chaîne

---

## COMPARAISON DES OPTIONS

| Critère | OPTION A | OPTION B | OPTION C |
|---------|----------|----------|----------|
| **Complexité** | ⭐ Simple | ⭐⭐⭐ Complexe | ⭐ Simple |
| **Maintenance** | ⭐⭐⭐ Facile | ⭐ Difficile | N/A |
| **Granularité** | ⚠️ Globale | ✅ Fine | N/A |
| **Réversibilité** | ✅ Oui | ✅ Oui | ✅ Non destructif |
| **Impact Volume** | ⚠️ Augmente | ✅ Contrôlé | N/A |
| **Validation Fonctionnelle** | ✅ Requise | ✅ Requise | ❌ Non requise |

---

## RECOMMANDATION FINALE

### Étape 1 : Diagnostic (OPTION C)
Exécuter les requêtes de l'OPTION C pour comprendre :
1. Si le cumul existe dans TA_RN_EXPORT
2. Si le cumul existe dans BR_DATA
3. Quel est le montant du cumul (somme de toutes les transactions VO du jour)

### Étape 2 : Décision Fonctionnelle
Consulter l'équipe fonctionnelle pour déterminer :
- Le compte 342 doit-il TOUJOURS exporter en détail ? → **OPTION A**
- Le compte 342 doit-il cumuler certains produits mais pas d'autres ? → **OPTION B**
- Le cumul est-il le comportement attendu ? → **Garder le paramétrage actuel**

### Étape 3 : Application de la Solution
Exécuter le script SQL de l'option choisie.

### Étape 4 : Validation
Rejouer le processus d'import et vérifier :
```sql
-- Vérifier que 2817 est dans TA_RN_EXPORT en DÉTAIL
SELECT
    SOURCE,
    ACCNUM,
    ORAMT,
    TRDAT,
    COMMENTAIRE
FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ORAMT = '2817'
  AND COMMENTAIRE NOT LIKE '%cumul%';

-- Vérifier que 2817 est dans BR_DATA
SELECT
    ACCNUM,
    ORAMT,
    TRDAT
FROM BANKREC.BR_DATA
WHERE ORAMT = '2817';
```

---

## SCRIPTS CRÉÉS

1. **VERIF_CUMUL_2817.sql** - Diagnostic de la règle de cumul
2. **ROOT_CAUSE_ANALYSIS.md** - Analyse détaillée de la cause racine
3. **SOLUTION_OPTIONS.md** - Ce fichier
4. **VERIF_EXPORT_CUMUL_342.sql** - Vérification du cumul dans TA_RN_EXPORT (à créer)

---

## POINTS D'ATTENTION

1. ⚠️ **Validation fonctionnelle requise** avant toute modification de TA_RN_CUMUL_MR
2. ⚠️ **Backup recommandé** : Sauvegarder l'état actuel de TA_RN_CUMUL_MR
3. ⚠️ **Test sur environnement de qualification** avant production
4. ⚠️ **Documentation** : Documenter la modification dans un ticket/incident

---

**Version : 1.0**
**Date : 07/02/2026**
**Statut : OPTIONS DOCUMENTÉES ✅**
