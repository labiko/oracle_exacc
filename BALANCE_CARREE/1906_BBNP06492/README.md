# Compte 1906 - BBNP06492-EUR - Correction Ecart Balance Carree

## RESUME EXECUTIF

| Element | Valeur |
|---------|--------|
| **Compte** | 1906 (BBNP06492-EUR-ST) |
| **Periode** | 202602 (Fevrier 2026) |
| **Probleme** | Ecart de 2,66 EUR dans la Balance Carree |
| **Cause racine** | Rollback incomplet du load 346241 (25/02/2026) |
| **Solution** | DELETE records orphelins + UPDATE BAL_ST |

---

## LE PROBLEME EN 3 POINTS

1. **Ce qui s'est passe** : Un fichier bancaire (load 346241) a ete charge puis rollbacke, mais les records 878 et 879 sont restes dans BR_DATA.

2. **Pourquoi l'ecart** : Ces 2 records ont un effet NET de +2,66 EUR (248802,91 - 248800,25) qui decale la Balance Carree.

3. **Pourquoi DELETE seul ne suffit pas** : Supprimer les records SANS corriger BAL_ST dans BRD_EU_JC_SUMMARY DOUBLE l'ecart (5,32 au lieu de 0).

---

## LA SOLUTION DEFINITIVE (Option 2)

### Etape 1 : Supprimer les records orphelins
```sql
DELETE FROM BANKREC.BR_DATA WHERE acct_id = 1906 AND load_id = 346241;
DELETE FROM BANKREC.BRD_EU_JC_ITEMS WHERE acct_id = 1906 AND load_id = 346241;
```

### Etape 2 : Corriger BAL_ST (OBLIGATOIRE)
```sql
-- Apres DELETE, DIFF a double. Cette formule le corrige :
UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = BAL_ST - DIFF
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
COMMIT;
```

### Resultat attendu
- DIFF = 0 (ecart corrige)
- Aucun record dans BR_DATA/BRD_EU_JC_ITEMS pour load_id=346241

**Script complet** : `correction_definitive.sql`

---

## FORMULE DE CALCUL

```
DIFF = SUM_REC_ST + SUM_REC_CB

Ou :
  SUM_REC_ST = BAL_ST - (SUM_ST_P + SUM_ST_R)
  SUM_REC_CB = BAL_CB - (SUM_CB_P + SUM_CB_R)

Pour mettre DIFF a 0 :
  BAL_ST_nouveau = BAL_ST_actuel - DIFF_actuel
```

---

## FICHIERS DU DOSSIER

| Fichier | Description | Usage |
|---------|-------------|-------|
| `README.md` | Ce fichier - Resume global | Lecture |
| `TRACE_INVESTIGATION.md` | Historique complet de l'investigation | Reference |
| `correction_definitive.sql` | **Script de correction (Option 2)** | **EXECUTER** |
| `rollback_correction.sql` | Pour annuler la correction BAL_ST | Si probleme |
| `rollback_ecart_solde.sql` | Genere les INSERT pour rollback BR_DATA | Sauvegarde |
| `datapump_export.sh` | Export Data Pump des records | Sauvegarde |
| `datapump_import.sh` | Import Data Pump des records | Restauration |

---

## PROCEDURE D'EXECUTION

### Etape 1 : Preparation
```bash
# Connexion serveur
sesu - oracle

# Copier les scripts
scp 1906_BBNP06492/*.sql oracle@server:/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/
```

### Etape 2 : Sauvegarder les donnees (optionnel mais recommande)
```bash
sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/rollback_ecart_solde.sql > insert_backup.sql
```

### Etape 3 : Execution
```bash
sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/correction_definitive.sql
```

### Etape 4 : Verification
- DIFF doit etre 0
- Verifier dans l'interface Balance Carree

### En cas de probleme (ROLLBACK)
```bash
# 1. Restaurer les records
sqlplus -S / as sysdba @insert_backup.sql

# 2. Restaurer BAL_ST
sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/rollback_correction.sql
```

---

## PROCEDURE GENERIQUE (pour autres comptes)

Voir l'onglet **"Rollback Fichier (Generique)"** dans `index.html` pour la procedure complete applicable a tous les comptes.

**Checklist rapide :**
1. Identifier ACCT_ID, PERIOD_JC, LOAD_ID
2. Sauvegarder les INSERT (Etape 5)
3. DELETE les records orphelins (Etape 4)
4. **Corriger BAL_ST (Etape 4 bis)** ← OBLIGATOIRE !
5. Verifier DIFF = 0

---

*Mis a jour le 12/03/2026 - Version 2.0*
