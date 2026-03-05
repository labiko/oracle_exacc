# ORA-01555 : Snapshot Too Old - Analyse et Correction

**Date d'analyse** : 16/02/2026
**Traitement concerné** : `RNADDEBAUTO01.RNADEXTAUTO01`
**Erreur** : ORA-01555: snapshot too old

---

## 1. ERREUR CONSTATEE

```
Id. message   : 8257242
Date          : 2026-02-16 07:31:26
Id. Execution : 671-32691
Type message  : ORA - ERREUR ORACLE
Exception     : -1555
Message       : ORA-01555: snapshot too old: rollback segment number 7
                with name "_SYSSMU7_328987667$" too small
Traitement    : RNADDEBAUTO01.RNADEXTAUTO01
```

---

## 2. DIAGNOSTIC

### Paramètres actuels

| Paramètre | Valeur | Conversion |
|-----------|--------|------------|
| **UNDO_RETENTION** | 1800 sec | **30 minutes** |
| **MAX Query Length** | 14033 sec | **~3h54** |
| **Tuned Retention** | 9918 sec | **~2h45** |
| **UNDOTBS1 Size** | 57471 MB | **~56 GB** |

### Problème identifié

```
Requête la plus longue   : 3h54
UNDO configuré           : 30 min
                          ↓
         ÉCART DE 3h24 → ORA-01555 garanti !
```

---

## 3. EXPLICATION DU MECANISME UNDO

### Comment fonctionne l'UNDO ?

Quand une requête SELECT longue s'exécute, Oracle doit montrer les données **telles qu'elles étaient au début** de la requête, même si d'autres utilisateurs les modifient pendant ce temps.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        TABLESPACE UNDO (56 GB)                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Anciennes valeurs des données modifiées par d'autres users    │    │
│  │  (conservées pendant UNDO_RETENTION = 30 min actuellement)     │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Ce qui s'est passé

```
07:00  ─────► Début du traitement RNADEXTAUTO01
              Oracle garde un "snapshot" des données à cet instant
              │
              │  Pendant ce temps, d'autres transactions modifient
              │  les mêmes tables. Oracle stocke les anciennes
              │  valeurs dans l'UNDO.
              │
07:30  ─────► UNDO_RETENTION = 30 min atteint
              Oracle commence à EFFACER les anciennes valeurs
              pour faire de la place (même si ta requête tourne encore !)
              │
              │
10:54  ─────► Après ~4h, ta requête a besoin d'une donnée de 07:00
              Oracle cherche dans l'UNDO... mais c'est EFFACÉ !
              │
              └──► ORA-01555: snapshot too old
```

### Pourquoi modifier UNDO_RETENTION ?

| Paramètre | Signification |
|-----------|---------------|
| `UNDO_RETENTION = 1800` | "Garde les anciennes valeurs pendant **30 min** max" |
| `UNDO_RETENTION = 18000` | "Garde les anciennes valeurs pendant **5 heures** max" |

En augmentant cette valeur, Oracle **conserve plus longtemps** l'historique des modifications, ce qui permet à la requête de 4 heures de retrouver les données dont elle a besoin.

---

## 4. SOLUTION

### Commande de correction

```sql
-- Augmenter UNDO_RETENTION à 5 heures (18000 secondes)
-- pour couvrir les requêtes de 4h avec marge de sécurité
ALTER SYSTEM SET UNDO_RETENTION = 18000 SCOPE=BOTH;
```

### Vérification après correction

```sql
-- Vérifier la nouvelle valeur
SHOW PARAMETER UNDO_RETENTION;

-- Résultat attendu :
-- NAME           TYPE    VALUE
-- -------------- ------- -----
-- undo_retention integer 18000
```

---

## 5. COMPARAISON AVANT/APRES

```
AVANT (UNDO_RETENTION = 1800 sec = 30 min)
├── Requête de 4h
├── UNDO effacé après 30 min
└── ❌ ORA-01555

APRÈS (UNDO_RETENTION = 18000 sec = 5h)
├── Requête de 4h
├── UNDO conservé 5h
└── ✅ La requête peut finir
```

| Situation | UNDO_RETENTION | Durée | Résultat |
|-----------|----------------|-------|----------|
| **Avant** | 1800 sec | 30 min | ORA-01555 |
| **Après** | 18000 sec | 5 heures | OK |

---

## 6. SCRIPTS DE DIAGNOSTIC

### Vérifier la configuration UNDO

```sql
-- Paramètre UNDO_RETENTION
SHOW PARAMETER UNDO_RETENTION;

-- Taille du tablespace UNDO
SELECT tablespace_name, SUM(bytes)/1024/1024 AS MB_TOTAL
FROM dba_data_files
WHERE tablespace_name LIKE '%UNDO%'
GROUP BY tablespace_name;

-- Statistiques UNDO (durée max requête, rétention auto-ajustée)
SELECT MAX(maxquerylen) AS QUERY_MAX_SECONDS,
       MAX(tuned_undoretention) AS RETENTION_AUTO_SECONDS
FROM v$undostat;
```

### Surveiller les erreurs ORA-01555

```sql
-- Nombre d'erreurs ORA-01555 récentes
SELECT begin_time, end_time, ssolderrcnt AS NB_ORA_01555
FROM v$undostat
WHERE ssolderrcnt > 0
ORDER BY begin_time DESC;
```

---

## 7. RECOMMANDATIONS

| Priorité | Action | Responsable |
|----------|--------|-------------|
| 1 | Appliquer `ALTER SYSTEM SET UNDO_RETENTION = 18000` | DBA |
| 2 | Vérifier que le changement est effectif | DBA |
| 3 | Relancer le traitement `RNADEXTAUTO01` | Exploitation |
| 4 | Surveiller les prochaines exécutions | Équipe |

---

## 8. NOTES IMPORTANTES

- **Impact** : Le changement est immédiat et ne nécessite pas de redémarrage
- **Espace disque** : L'UNDO de 56 GB est suffisant pour 5h de rétention
- **Réversible** : On peut revenir à 1800 si besoin avec la même commande
- **Permanent** : `SCOPE=BOTH` rend le changement persistant après redémarrage

---

**Document créé le 16/02/2026**
