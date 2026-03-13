# TRACE INVESTIGATION - Compte 1906 (BBNP06492-EUR)

**Date debut investigation** : 07/03/2026
**Date mise a jour** : 13/03/2026
**Statut** : SOLUTION IDENTIFIEE - EN ATTENTE EXECUTION

---

## 1. IDENTIFICATION DU PROBLEME

| Element | Valeur |
|---------|--------|
| **Compte** | 1906 |
| **Nom compte** | BBNP06492-EUR-ST |
| **Devise** | EUR |
| **Ecart Balance Carree** | 2,66 EUR |
| **Periode** | 202602 (Fevrier 2026) |

---

## 2. CHRONOLOGIE DES EVENEMENTS

### 2.1 Historique des chargements (25/02/2026)

| Heure | Load ID | Action | Solde Avant | Solde Apres | Statut |
|-------|---------|--------|-------------|-------------|--------|
| 15:57:11 | 346241 | LOAD | -0,11 | 2,55 | **ROLLBACK** |
| 15:57:11 | 346241 | BALANCE_UPDATE (TYPE=15) | -0,11 | 2,55 | - |
| 15:58:24 | 346241 | EXEC_ROLLBACK (TYPE=16) | - | - | - |
| 22:39:56 | 346285 | LOAD | 2,55 | 5,21 | Reussi |

### 2.2 Le probleme

Le rollback du load **346241** a echoue partiellement :
- Les records 878 et 879 n'ont PAS ete supprimes de BR_DATA
- Le solde n'a PAS ete reinitialise de 2,55 a -0,11

Le load suivant **346285** a pris comme base un solde deja faux (2,55 au lieu de -0,11).

---

## 3. DONNEES TECHNIQUES

### 3.1 Records orphelins dans BR_DATA

```sql
SELECT record_id, state, amount, cs_flag, pr_flag, trans_date, load_id
FROM BR_DATA
WHERE acct_id = 1906 AND load_id = 346241;
```

| record_id | state | amount | cs_flag | pr_flag | trans_date | load_id |
|-----------|-------|--------|---------|---------|------------|---------|
| 878 | 3 | 248800,25 | S | P | 25/02/26 | 346241 |
| 879 | 3 | 248802,91 | S | R | 25/02/26 | 346241 |

**Effet NET** : 248802,91 - 248800,25 = **+2,66 EUR** (= ecart Balance Carree)

### 3.2 BRD_EU_JC_ITEMS (periode 202602)

| period_JC | record_id | state | amount | cs_flag | pr_flag | load_id |
|-----------|-----------|-------|--------|---------|---------|---------|
| 202602 | 862 | 3 | 360 | S | P | 345379 |
| 202602 | 864 | 4 | 1316963,84 | S | R | 345577 |
| 202602 | 869 | 4 | 30062578,93 | S | R | 345943 |
| 202602 | 872 | 3 | 120000 | S | P | 346095 |
| 202602 | 874 | 3 | 119996,23 | S | R | 346159 |
| 202602 | **878** | 3 | **248800,25** | S | **P** | **346241** |
| 202602 | **879** | 3 | **248802,91** | S | **R** | **346241** |
| 202602 | 906 | 4 | 30062578,93 | C | P | 346483 |

### 3.3 BRD_EU_JC_SUMMARY (periode 202602)

```
PERIOD_JC : 202602
ACCT_ID   : 1906
BAL_ST    : 5,21        <-- Solde Bank (FAUX - devrait etre 2,55)
BAL_CB    : 61441758,04 <-- Solde Compta
SUM_ST_P  : -369160,25  <-- Somme Payments Statement (inclut 248800,25)
SUM_ST_R  : 31748341,91 <-- Somme Receipts Statement (inclut 248802,91)
SUM_CB_P  : 30062578,93
SUM_CB_R  : 0
DIFF      : 2,66        <-- ECART
```

---

## 4. FORMULE DE CALCUL DE L'ECART

```
SUM_REC_ST = BAL_ST - (SUM_ST_P + SUM_ST_R)
           = 5,21 - (-369160,25 + 31748341,91)
           = 5,21 - 31379181,66
           = -31379176,45

SUM_REC_CB = BAL_CB - (SUM_CB_P + SUM_CB_R)
           = 61441758,04 - (30062578,93 + 0)
           = 31379179,11

DIFF = SUM_REC_ST + SUM_REC_CB
     = -31379176,45 + 31379179,11
     = 2,66 EUR
```

---

## 5. TENTATIVE DE CORRECTION ECHOUEE

### 5.1 Ce qui a ete fait

```sql
DELETE FROM BR_DATA WHERE acct_id = 1906 AND load_id = 346241;
-- Puis recalcul Balance Carree
```

### 5.2 Resultat

**L'ecart a DOUBLE de 2,66 EUR a 5,32 EUR !**

### 5.3 Explication

Apres suppression des records 878/879 :
```
SUM_ST_P nouveau = -369160,25 + 248800,25 = -120360
SUM_ST_R nouveau = 31748341,91 - 248802,91 = 31499539

SUM_REC_ST = 5,21 - (-120360 + 31499539) = -31379173,79
SUM_REC_CB = 31379179,11 (inchange)

DIFF = -31379173,79 + 31379179,11 = 5,32 EUR (double!)
```

**Cause** : BAL_ST (5,21) n'a pas ete corrige lors de la suppression.

### 5.4 Rollback effectue

Restauration des records via Data Pump pour revenir a l'etat initial (ecart 2,66 EUR).

---

## 6. SOLUTION DEFINITIVE

### 6.1 Option 1 : Corriger uniquement BAL_ST (RECOMMANDEE)

**Principe** : Garder les records orphelins, corriger le solde pour compenser.

```sql
UPDATE BRD_EU_JC_SUMMARY
SET BAL_ST = 2.55
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
COMMIT;
```

**Verification** :
```
SUM_REC_ST = 2,55 - (-369160,25 + 31748341,91) = -31379179,11
SUM_REC_CB = 31379179,11
DIFF = -31379179,11 + 31379179,11 = 0 EUR
```

**Avantages** :
- Simple (une seule UPDATE)
- Pas de risque de perte de donnees
- Tracabilite conservee

### 6.2 Option 2 : Supprimer les records ET corriger BAL_ST

**Principe** : Nettoyer les donnees orphelines et ajuster le solde.

```sql
-- Etape 1 : Supprimer les records orphelins
DELETE FROM BR_DATA WHERE acct_id = 1906 AND load_id = 346241;
DELETE FROM BRD_EU_JC_ITEMS WHERE acct_id = 1906 AND load_id = 346241;

-- Etape 2 : Corriger BAL_ST
UPDATE BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

COMMIT;
```

**Avantages** :
- Donnees propres
- Pas de records orphelins

**Inconvenients** :
- Plus risque
- Necessite sauvegarde prealable

---

## 7. FICHIERS DU DOSSIER

| Fichier | Description |
|---------|-------------|
| `TRACE_INVESTIGATION.md` | Ce fichier - Historique complet |
| `correction_definitive.sql` | Script de correction (Option 1) |
| `correction_option2.sql` | Script de correction (Option 2) |
| `rollback_correction.sql` | Script pour annuler la correction |
| `delete_ecart_solde.sql` | Ancien script DELETE (NE PAS UTILISER SEUL) |
| `rollback_ecart_solde.sql` | Script pour generer les INSERT de rollback |
| `datapump_export.sh` | Export Data Pump des records |
| `datapump_import.sh` | Import Data Pump des records |

---

## 8. INSTRUCTIONS D'EXECUTION

### Avant execution

1. Lire ce fichier en entier
2. Verifier les donnees actuelles avec le script de verification
3. Choisir l'option de correction
4. Sauvegarder les donnees si necessaire

### Commande d'execution

```bash
# Connexion
sesu - oracle

# Execution
sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/correction_definitive.sql
```

### Apres execution

1. Verifier que DIFF = 0 dans BRD_EU_JC_SUMMARY
2. Verifier l'affichage dans l'interface Balance Carree
3. Documenter le resultat dans ce fichier

---

## 9. HISTORIQUE DES ACTIONS

| Date | Action | Resultat | Operateur |
|------|--------|----------|-----------|
| 25/02/2026 | Rollback load 346241 | Echec partiel | Systeme |
| 07/03/2026 | Investigation debut | Root cause identifiee | - |
| 11/03/2026 | DELETE BR_DATA | Ecart double (5,32) | - |
| 11/03/2026 | Rollback Data Pump | Retour 2,66 EUR | - |
| 12/03/2026 | Analyse formule calcul | Solution identifiee | - |
| ??/??/???? | Correction definitive | EN ATTENTE | - |

---

## 10. RESULTATS REQUETES (13/03/2026)

### 10.1 BRD_EU_JC_SUMMARY - Valeurs actuelles

| Colonne | Valeur |
|---------|--------|
| PERIOD_JC | 202602 |
| ACCT_ID | 1906 |
| BAL_ST | 5,21 |
| BAL_CB | 61441758,04 |
| SUM_ST_P | -369160,25 |
| SUM_ST_R | 31748341,91 |
| SUM_CB_P | 30062578,93 |
| SUM_CB_R | 0 |
| **DIFF** | **2,66** |
| SUM_ST_P + SUM_ST_R | 31379181,66 |
| SUM_CB_P + SUM_CB_R | 30062578,93 |
| SUM_REC_ST (calcule) | -31379176,45 |
| SUM_REC_CB (calcule) | 31379179,11 |
| DIFF (recalcule) | 2,66 ✓ |

### 10.2 BRD_EU_JC_ITEMS - Records orphelins (load_id=346241)

⚠️ **ATTENTION : Records presents dans 2 periodes !**

| PERIOD_JC | RECORD_ID | STATE | CS_FLAG | PR_FLAG | AMOUNT | LOAD_ID |
|-----------|-----------|-------|---------|---------|--------|---------|
| **202602** | 878 | 3 | S | P | 248800,25 | 346241 |
| **202602** | 879 | 3 | S | R | 248802,91 | 346241 |
| **202603** | 878 | 3 | S | P | 248800,25 | 346241 |
| **202603** | 879 | 3 | S | R | 248802,91 | 346241 |

**NET par periode** : 248802,91 - 248800,25 = **2,66 EUR**

### 10.3 Calcul du doublement de DIFF apres DELETE

```
AVANT DELETE (periode 202602):
  SUM_ST_P = -369160,25  (inclut -248800,25 du record 878)
  SUM_ST_R = 31748341,91 (inclut +248802,91 du record 879)

  SUM_ST_P + SUM_ST_R = 31379181,66
  SUM_REC_ST = BAL_ST - 31379181,66 = 5,21 - 31379181,66 = -31379176,45
  SUM_REC_CB = 31379179,11
  DIFF = -31379176,45 + 31379179,11 = 2,66 ✓

APRES DELETE des records 878/879:
  SUM_ST_P_new = -369160,25 + 248800,25 = -120360,00
  SUM_ST_R_new = 31748341,91 - 248802,91 = 31499539,00

  SUM_ST_P + SUM_ST_R = 31379179,00  (change de -2,66)
  SUM_REC_ST = 5,21 - 31379179,00 = -31379173,79  (augmente de +2,66)
  SUM_REC_CB = 31379179,11 (inchange)
  DIFF = -31379173,79 + 31379179,11 = 5,32 ✓

EXPLICATION:
  - Les records orphelins ont un NET de 2,66 sur les sommes
  - Quand on les supprime, ce NET disparait des sommes
  - Mais BAL_ST reste inchange (5,21)
  - Donc DIFF augmente de 2,66 (passe de 2,66 a 5,32)
  - Formule: DIFF_apres = DIFF_avant + NET_orphelins = 2,66 + 2,66 = 5,32
```

---

## 11. REQUETES DE DIAGNOSTIC

### 10.1 Valeurs BRD_EU_JC_SUMMARY avec calculs intermediaires

```sql
-- =====================================================
-- VALEURS BRD_EU_JC_SUMMARY - Compte 1906, Periode 202602
-- =====================================================
-- FORMULES DE CALCUL :
--   SUM_REC_ST = BAL_ST - (SUM_ST_P + SUM_ST_R)
--   SUM_REC_CB = BAL_CB - (SUM_CB_P + SUM_CB_R)
--   DIFF       = SUM_REC_ST + SUM_REC_CB
-- =====================================================

SELECT
    PERIOD_JC,
    ACCT_ID,
    ACCT_NAME,
    '--- VALEURS STOCKEES ---' AS section1,
    BAL_ST,
    BAL_CB,
    SUM_ST_P,
    SUM_ST_R,
    SUM_CB_P,
    SUM_CB_R,
    DIFF,
    '--- CALCULS INTERMEDIAIRES ---' AS section2,
    (SUM_ST_P + SUM_ST_R) AS "SUM_ST_P + SUM_ST_R",
    (SUM_CB_P + SUM_CB_R) AS "SUM_CB_P + SUM_CB_R",
    BAL_ST - (SUM_ST_P + SUM_ST_R) AS "SUM_REC_ST (calcule)",
    BAL_CB - (SUM_CB_P + SUM_CB_R) AS "SUM_REC_CB (calcule)",
    '--- VERIFICATION ---' AS section3,
    (BAL_ST - (SUM_ST_P + SUM_ST_R)) + (BAL_CB - (SUM_CB_P + SUM_CB_R)) AS "DIFF (recalcule)"
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906
  AND PERIOD_JC = '202602';
```

### 10.2 Records orphelins BR_DATA

```sql
SELECT record_id, state, amount, cs_flag, pr_flag, trans_date, load_id
FROM BANKREC.BR_DATA
WHERE acct_id = 1906 AND load_id = 346241;
```

### 10.3 Records BRD_EU_JC_ITEMS

```sql
SELECT period_jc, record_id, state, amount, cs_flag, pr_flag, load_id
FROM BANKREC.BRD_EU_JC_ITEMS
WHERE acct_id = 1906 AND load_id = 346241;
```

---

## 11. CONTACTS

Pour toute question sur ce dossier, contacter l'equipe DBA.

---

*Derniere mise a jour : 13/03/2026*
