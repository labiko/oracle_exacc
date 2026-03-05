# GUIDE D'EXÉCUTION - RNADGENEXPGES01_TRACE_COMPLETE.sql

## Date : 07/02/2026

---

## CONTEXTE

**Problème** : La transaction **2817 EUR** n'apparaît pas dans **BANKREC.BR_DATA** alors que **22.36 EUR** y est.

**Hypothèse** : Le problème est dans le script **RNADGENEXPGES01.sql** qui traite les comptes **TYPE_RAPPRO='B'** (Banque) et utilise **TA_RN_GESTION_ACCURATE**.

**Comptes concernés** :
- **Compte 394** (BNPP05492-EUR) → Transaction 22.36 EUR ✅
- **Compte 342** (BBNP83292-EUR) → Transaction 2817 EUR ❌

---

## FICHIERS CRÉÉS

### Scripts SQL

1. **RNADGENEXPGES01.sql** → Version originale (NE PAS MODIFIER)
2. **RNADGENEXPGES01_TRACE_COMPLETE.sql** → Version tracée avec logging complet
3. **VERIF_GESTION_ACCURATE_394_342.sql** → Vérification paramétrage comptes
4. **VERIF_LOGS_EXPGES01_TRACE.sql** → Analyse des logs après exécution
5. **VERIF_TABLES_IMPORT.sql** → Vérification présence données

### Documentation

6. **GUIDE_MODIFICATION_EXPGES01_TRACE.md** → Détail des modifications
7. **README_RNADGENEXPGES01_TRACE.md** → Documentation complète
8. **GUIDE_EXECUTION_EXPGES01_TRACE.md** → Ce fichier

---

## ÉTAPES D'EXÉCUTION

### ÉTAPE 0 : Vérification Préalable (OPTIONNEL)

Vérifier si les comptes 394 et 342 sont dans TA_RN_GESTION_ACCURATE :

```bash
cd /home/oracle/scripts/BNNP_SQL
sqlplus RNAPPL/****@P08449A @VERIF_GESTION_ACCURATE_394_342.sql
```

**Résultat attendu** :
- Si les deux comptes sont absents de TA_RN_GESTION_ACCURATE → **ROOT CAUSE IMMÉDIATE**
- Si compte 342 absent mais 394 présent → **ROOT CAUSE IMMÉDIATE**
- Si les deux présents → Continuer avec l'étape 1

---

### ÉTAPE 1 : Purger les Logs Précédents

```bash
cd /home/oracle/scripts/BNNP_SQL
sqlplus RNAPPL/****@P08449A
```

```sql
-- Purger uniquement les logs du script EXPGES01
DELETE FROM TA_RN_LOG_EXECUTION WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE';
COMMIT;

-- Vérifier
SELECT COUNT(*) FROM TA_RN_LOG_EXECUTION WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE';
-- Doit retourner 0

EXIT;
```

---

### ÉTAPE 2 : Exécuter le Script Tracé

```bash
cd /home/oracle/scripts/BNNP_SQL
sqlplus RNAPPL/****@P08449A @RNADGENEXPGES01_TRACE_COMPLETE.sql
```

**Surveiller la sortie DBMS_OUTPUT** :
- ✅ "Transaction 22.36 TROUVEE ligne X"
- ✅ "Transaction 2817 TROUVEE ligne Y"
- ✅ "🎯 TRANSACTION CIBLE 22.36 INSEREE"
- ❓ "🎯 TRANSACTION CIBLE 2817 INSEREE" → Si absent, problème d'insertion
- ✅ "Test EXISTS - Compte 394 (BNPP05492-EUR) - X transactions"
- ❓ "Test EXISTS - Compte 342 (BBNP83292-EUR) - Y transactions" → Si absent, ROOT CAUSE

---

### ÉTAPE 3 : Analyser les Logs

```bash
cd /home/oracle/scripts/BNNP_SQL
sqlplus RNAPPL/****@P08449A @VERIF_LOGS_EXPGES01_TRACE.sql > resultats_trace_expges01.txt
```

**Analyser resultats_trace_expges01.txt** :

#### Section 2 : Recherche dans XML
```
22.36 dans XML ?    OUI ✅
2817 dans XML ?     OUI ✅  ← Si NON, problème source
```

#### Section 3 : Insertion dans TA_RN_IMPORT_GESTION
```
TRANSACTION CIBLE 22.36 INSEREE    ✅
TRANSACTION CIBLE 2817 INSEREE     ✅  ← Si absent, problème parsing
```

#### Section 5 : Test EXISTS - CRITIQUE
```
INFO | ID_COMPTE_ACCURATE | 394 (BNPP05492-EUR) - 1 transactions a inserer    ✅
INFO | ID_COMPTE_ACCURATE | 342 (BBNP83292-EUR) - 1 transactions a inserer    ✅
```

**OU**

```
WARNING | ID_COMPTE_BANC_SYST | Compte bancaire systeme NON trouve dans TA_RN_GESTION_ACCURATE
```

→ **Si WARNING pour compte 342 = ROOT CAUSE TROUVÉE** 🎯

#### Section 9 : Données TA_RN_EXPORT
```
ORAMT
-------
22.36    ✅
2817     ✅  ← Si absent, vérifier pourquoi
```

---

### ÉTAPE 4 : Diagnostic selon le Résultat

#### CAS A : Compte 342 NON trouvé dans TA_RN_GESTION_ACCURATE ❌

**ROOT CAUSE** : Le compte accurate 342 n'est pas paramétré pour TYPE_RAPPRO='B'.

**Action** :
1. Vérifier avec l'équipe fonctionnelle si le compte doit être paramétré
2. Si OUI, ajouter le lien dans TA_RN_GESTION_ACCURATE :
```sql
INSERT INTO TA_RN_GESTION_ACCURATE (
    ID_COMPTE_BANCAIRE_SYSTEME,
    ID_COMPTE_ACCURATE
)
SELECT
    CBS.ID_COMPTE_BANCAIRE_SYSTEME,
    342
FROM TA_RN_COMPTE_BANCAIRE_SYSTEME CBS
WHERE CBS.NUMERO = 'BNPP-BBNP83292-EUR'  -- Adapter selon le vrai numéro
  AND NOT EXISTS (
      SELECT 1 FROM TA_RN_GESTION_ACCURATE GA
      WHERE GA.ID_COMPTE_BANCAIRE_SYSTEME = CBS.ID_COMPTE_BANCAIRE_SYSTEME
        AND GA.ID_COMPTE_ACCURATE = 342
  );
COMMIT;
```

#### CAS B : Les deux comptes trouvés mais 2817 pas dans TA_RN_EXPORT ❌

**Hypothèse** : Filtre d'exclusion actif.

**Action** : Analyser les logs étape 32 pour voir quelle exclusion s'applique :
```sql
SELECT
    TO_CHAR(DT_EXECUTION, 'HH24:MI:SS.FF3') AS HEURE,
    ETAPE,
    TYPE_LOG,
    MESSAGE,
    VALEUR_EXTRAITE
FROM TA_RN_LOG_EXECUTION
WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE'
  AND ETAPE = 32
ORDER BY DT_EXECUTION;
```

Vérifier :
1. **TA_RN_EXCLUSION_SOCIETE** : Code société 90141615 exclu ?
2. **TA_RN_EXCLUSION_DEVISE** : EUR exclu ?
3. **TA_RN_EXCLUSION_MR** : Mode VO exclu ?
4. **TA_RN_EXCLUSION_TR** : Type DEC exclu ?
5. **TA_RN_CUMUL_MR** : Mode cumul actif pour VO ?

#### CAS C : Les deux dans TA_RN_EXPORT mais 2817 pas dans BR_DATA ✅❌

**Hypothèse** : Le problème est APRÈS l'export (processus Oracle Bankrec).

**Action** : Vérifier les processus suivants dans la chaîne de traitement.

---

## APRÈS DIAGNOSTIC

### Nettoyer les Données de Test

```sql
-- Purger les logs
DELETE FROM TA_RN_LOG_EXECUTION WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE';

-- Purger les tables de travail
DELETE FROM TA_RN_EXPORT WHERE SOURCE = 'GEST';
DELETE FROM TA_RN_IMPORT_GESTION;

COMMIT;
```

### Revenir au Script Original

Une fois le problème résolu, utiliser à nouveau **RNADGENEXPGES01.sql** (version sans trace) pour les exécutions normales.

---

## RÉSUMÉ DES COMMANDES

```bash
# Vérification préalable
cd /home/oracle/scripts/BNNP_SQL
sqlplus RNAPPL/****@P08449A @VERIF_GESTION_ACCURATE_394_342.sql

# Purger logs
sqlplus RNAPPL/****@P08449A << EOF
DELETE FROM TA_RN_LOG_EXECUTION WHERE NOM_PROCEDURE = 'PR_RN_IMPORT_GESTION_TRACE';
COMMIT;
EXIT;
EOF

# Exécuter script tracé
sqlplus RNAPPL/****@P08449A @RNADGENEXPGES01_TRACE_COMPLETE.sql

# Analyser résultats
sqlplus RNAPPL/****@P08449A @VERIF_LOGS_EXPGES01_TRACE.sql > resultats_trace_expges01.txt

# Lire résultats
cat resultats_trace_expges01.txt
```

---

## POINTS D'ATTENTION

1. ⚠️ **NE PAS MODIFIER** RNADGENEXPGES01.sql (version originale)
2. ⚠️ Les DELETE sont commentés → Les tables ne seront pas purgées
3. ⚠️ Vérifier que TA_RN_LOG_EXECUTION existe et est accessible
4. ⚠️ Les logs utilisent NOM_PROCEDURE='PR_RN_IMPORT_GESTION_TRACE' (différent de 'PR_RN_IMPORT_GESTION_JC_TRACE')

---

## SUPPORT

En cas de problème :
1. Vérifier que TX_REGLT_GEST contient bien les données
2. Vérifier que TA_RN_LOG_EXECUTION est accessible
3. Consulter README_RNADGENEXPGES01_TRACE.md pour plus de détails

---

**Version : 1.0**
**Date : 07/02/2026**
