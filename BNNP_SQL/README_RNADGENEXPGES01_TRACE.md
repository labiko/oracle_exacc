# RNADGENEXPGES01_TRACE_COMPLETE.sql - Documentation

## Date : 07/02/2026

---

## RÉSUMÉ DES MODIFICATIONS

Le fichier **RNADGENEXPGES01_TRACE_COMPLETE.sql** est une version modifiée de **RNADGENEXPGES01.sql** avec traçage complet pour diagnostiquer pourquoi la transaction **2817 EUR** n'est pas insérée dans **BANKREC.BR_DATA** alors que **22.36 EUR** l'est.

---

## ✅ MODIFICATIONS APPLIQUÉES

### 1. Variables de Traçage (ligne ~373)
- `v_total_transactions_lues NUMBER := 0;`
- `v_found_22_36 BOOLEAN := FALSE;`
- `v_found_2817 BOOLEAN := FALSE;`

### 2. Procédure P_LOG (après ligne ~554)
- Procédure autonome pour logging
- **NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'** (différent du script JC)
- Insère dans TA_RN_LOG_EXECUTION

### 3. Log Début de Traitement (ligne ~622)
- Log de l'ID_CHARGEMENT_GESTION
- Étape 10

### 4. Recherche 22.36 et 2817 dans XML (ligne ~680)
- Boucle FOR sur tab_REG_XML
- Log si transaction trouvée ou non trouvée
- Étape 25

### 5. Log Chaque Transaction Insérée (ligne ~938)
- Incrémente `v_total_transactions_lues`
- Log PAYMENTREFERENCE, MONTANT, CLIENT, RIB
- **Log spécifique avec 🎯 si montant = 22.36 ou 2817**

### 6. Log COMMIT Final (ligne ~1017)
- Log du nombre total de transactions insérées
- Avant le COMMIT final de TA_RN_IMPORT_GESTION

### 7. Log Traitement Comptes Accurate (ligne ~1042)
- Log au début du traitement TYPE_RAPPRO='B'
- Étape 30

### 8. Log Test EXISTS avec TA_RN_GESTION_ACCURATE (ligne ~1116)
- **CRITIQUE** : Vérifie si le compte est dans TA_RN_GESTION_ACCURATE
- Compte le nombre de transactions à insérer
- Log ID_COMPTE_ACCURATE, NUM_COMPTE_ACCURATE, nombre de transactions
- **WARNING si compte non trouvé**
- Étape 32

### 9. Log Après INSERT TA_RN_EXPORT (ligne ~1139)
- Log du nombre de lignes insérées (SQL%ROWCOUNT)
- Pour chaque compte traité
- Étape 32

### 10. DELETE Commentés (lignes 1530, 1891, 1894)
- **DELETE FROM TA_RN_EXPORT** → commenté
- **DELETE FROM TA_RN_IMPORT_GESTION** → commenté
- Permet l'analyse post-exécution

---

## DIFFÉRENCES AVEC LE SCRIPT ORIGINAL

| Aspect | RNADGENEXPGES01.sql (Original) | RNADGENEXPGES01_TRACE_COMPLETE.sql |
|--------|--------------------------------|------------------------------------|
| **Nom procédure log** | N/A | 'PR_RN_IMPORT_GESTION_TRACE' |
| **Variables traçage** | Aucune | 3 variables (v_total_transactions_lues, v_found_22_36, v_found_2817) |
| **Recherche XML** | Aucune | Boucle FOR sur XML avant traitement |
| **Log insertions** | DBMS_OUTPUT minimal | P_LOG + DBMS_OUTPUT détaillé |
| **Log EXISTS test** | Aucun | Test + log pour chaque compte accurate |
| **DELETE tables** | Exécutés | Commentés |

---

## DIFFÉRENCES AVEC RNADGENJUCGES01_TRACE_COMPLETE.sql

| Aspect | RNADGENJUCGES01 (TYPE_RAPPRO='J') | RNADGENEXPGES01 (TYPE_RAPPRO='B') |
|--------|-----------------------------------|-----------------------------------|
| **Table source** | TX_REGLT_JC | TX_REGLT_GEST |
| **Table import** | TA_RN_IMPORT_GESTION_JC | TA_RN_IMPORT_GESTION |
| **Table export** | TA_RN_EXPORT_JC | TA_RN_EXPORT |
| **Table param** | TA_RN_GESTION_JC | TA_RN_GESTION_ACCURATE |
| **Nom procédure log** | 'PR_RN_IMPORT_GESTION_JC_TRACE' | 'PR_RN_IMPORT_GESTION_TRACE' |
| **Comptes traités** | TYPE_RAPPRO='J' | TYPE_RAPPRO='B' ou 'C' |

---

## UTILISATION

### 1. Purger les Logs Précédents (optionnel)
```sql
DELETE FROM TA_RN_LOG_EXECUTION WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE';
COMMIT;
```

### 2. Exécuter le Script
```sql
@RNADGENEXPGES01_TRACE_COMPLETE.sql
```

### 3. Analyser les Logs
```sql
-- Voir tous les logs
SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    ETAPE,
    TYPE_LOG,
    NOM_BALISE,
    VALEUR_EXTRAITE,
    MESSAGE
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
ORDER BY DT_EXECUTION;

-- Voir uniquement les transactions 22.36 et 2817
SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    TYPE_LOG,
    MESSAGE,
    VALEUR_EXTRAITE
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND (MESSAGE LIKE '%22.36%' OR MESSAGE LIKE '%2817%')
ORDER BY DT_EXECUTION;

-- Vérifier les comptes dans TA_RN_GESTION_ACCURATE
SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    TYPE_LOG,
    NOM_BALISE,
    VALEUR_EXTRAITE,
    MESSAGE
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND MESSAGE LIKE '%TA_RN_GESTION_ACCURATE%'
ORDER BY DT_EXECUTION;
```

### 4. Vérifier les Données Non Purgées
```sql
-- TA_RN_IMPORT_GESTION
SELECT COUNT(*) FROM TA_RN_IMPORT_GESTION
WHERE ID_CHARGEMENT_GESTION = (SELECT MAX(ID_CHARGEMENT_GESTION) FROM TA_RN_IMPORT_GESTION);

SELECT * FROM TA_RN_IMPORT_GESTION
WHERE OPERATIONNETAMOUNT IN ('22.36', '2817')
ORDER BY OPERATIONNETAMOUNT;

-- TA_RN_EXPORT
SELECT COUNT(*) FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ID_CHARGEMENT = (SELECT MAX(ID_CHARGEMENT_GESTION) FROM TA_RN_IMPORT_GESTION);

SELECT * FROM TA_RN_EXPORT
WHERE SOURCE = 'GEST'
  AND ACCNUM IN (394, 342)
ORDER BY ACCNUM;
```

---

## SCÉNARIOS DE DIAGNOSTIC

### Scénario A : 22.36 et 2817 TOUTES DEUX trouvées dans XML
✅ **Bon signe** : Les deux transactions sont dans le fichier source

Prochaine étape : Vérifier si les deux sont insérées dans TA_RN_IMPORT_GESTION
- Si OUI → Problème dans le traitement TA_RN_EXPORT
- Si NON → Problème dans le parsing XML ou filtres d'insertion

### Scénario B : Seulement 22.36 trouvée dans XML
❌ **Problème source** : 2817 n'est pas dans TX_REGLT_GEST

Action : Vérifier la table TX_REGLT_GEST directement

### Scénario C : Les deux insérées dans TA_RN_IMPORT_GESTION
✅ **Bon signe** : Le parsing fonctionne

Prochaine étape : Analyser le log "Test EXISTS TA_RN_GESTION_ACCURATE"
- **Compte 394 (22.36)** : Doit apparaître avec "X transactions a inserer"
- **Compte 342 (2817)** :
  - Si "NON trouve dans TA_RN_GESTION_ACCURATE" → **ROOT CAUSE TROUVÉE**
  - Si trouvé → Vérifier les filtres d'exclusion

### Scénario D : Seulement 22.36 insérée dans TA_RN_IMPORT_GESTION
❌ **Problème parsing ou filtres** : 2817 a été filtrée

Action : Analyser les logs d'insertion (étape ~938)

### Scénario E : Compte 342 NON trouvé dans TA_RN_GESTION_ACCURATE
🎯 **ROOT CAUSE** : Le compte accurate 342 n'est pas paramétré pour le traitement TYPE_RAPPRO='B'

Action :
1. Exécuter `@VERIF_GESTION_ACCURATE_394_342.sql`
2. Vérifier avec l'équipe fonctionnelle si le compte 342 doit être paramétré

### Scénario F : Les deux comptes dans TA_RN_GESTION_ACCURATE mais une seule ligne dans TA_RN_EXPORT
❌ **Filtres d'exclusion** : 2817 est exclue par un des 5 filtres

Action :
- Vérifier TA_RN_EXCLUSION_SOCIETE
- Vérifier TA_RN_EXCLUSION_DEVISE
- Vérifier TA_RN_EXCLUSION_MR (Mode Règlement)
- Vérifier TA_RN_EXCLUSION_TR (Type Règlement)
- Vérifier TA_RN_CUMUL_MR (Mode cumul)

---

## FICHIERS ASSOCIÉS

- **RNADGENEXPGES01.sql** : Version originale (NE PAS MODIFIER)
- **RNADGENEXPGES01_TRACE_COMPLETE.sql** : Version tracée (ce fichier)
- **GUIDE_MODIFICATION_EXPGES01_TRACE.md** : Guide des modifications appliquées
- **VERIF_GESTION_ACCURATE_394_342.sql** : Vérification comptes 394 et 342
- **VERIF_TABLES_IMPORT.sql** : Vérification présence données

---

## APRÈS DIAGNOSTIC

Une fois le diagnostic terminé, vous pouvez :

1. **Nettoyer les logs** :
```sql
DELETE FROM TA_RN_LOG_EXECUTION WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE';
COMMIT;
```

2. **Purger les tables de travail** :
```sql
DELETE FROM TA_RN_EXPORT WHERE SOURCE = 'GEST';
DELETE FROM TA_RN_IMPORT_GESTION;
COMMIT;
```

3. **Revenir au script original** une fois le problème résolu

---

## SUPPORT

En cas de problème, vérifier :
1. La table TA_RN_LOG_EXECUTION existe et est accessible
2. L'ID_CHARGEMENT_GESTION est généré correctement
3. Les données sources (TX_REGLT_GEST) contiennent bien les transactions
4. Les comptes 394 et 342 sont dans TA_RN_COMPTE_ACCURATE avec TYPE_RAPPRO='B'

---

**Version : 1.0**
**Date création : 07/02/2026**
