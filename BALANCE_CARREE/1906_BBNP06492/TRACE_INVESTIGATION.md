# TRACE INVESTIGATION - Compte 1906 (BBNP06492-EUR)

**Date debut investigation** : 07/03/2026
**Date mise a jour** : 13/03/2026
**Statut** : ✅ CORRIGE EN DB - APPLICATION A RAFRAICHIR

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

### 6.1 Option 1 : Corriger uniquement BAL_ST (RETENUE ✅)

**Principe** : Garder les records orphelins, corriger le solde pour compenser.

```sql
UPDATE BRD_EU_JC_SUMMARY
SET BAL_ST = 2.55,
    DIFF = 0
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

### 6.2 Option 2 : Supprimer les records ET corriger BAL_ST (NON RETENUE)

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

### 6.3 Justification du choix (Option 1)

| Critere | Option 1 | Option 2 |
|---------|----------|----------|
| Complexite | 1 UPDATE | DELETE + UPDATE |
| Risque | Faible | Moyen |
| Reversibilite | Facile (`BAL_ST + DIFF`) | Necessite Data Pump |
| Tracabilite | Records conserves | Records supprimes |

**Formule appliquee** :
```
BAL_ST_nouveau = BAL_ST_actuel - DIFF
               = 5,21 - 2,66
               = 2,55
```

**Script** : `CORRECTION_GENERIQUE.sql` ou `correction_definitive.sql`

---

## 7. FICHIERS DU DOSSIER

| Fichier | Description |
|---------|-------------|
| `TRACE_INVESTIGATION.md` | Ce fichier - Historique complet |
| `correction_BR_AUDIT_DEFINITIVE.sql` | **✅ SCRIPT PRINCIPAL** - Correction BR_AUDIT + SUMMARY |
| `correction_finale_BAL_ST.sql` | Correction SUMMARY seule (NON VIABLE si loads quotidiens) |
| `correction_complete_option_A.sql` | Correction complete (BAL_ST + SUM_ST_P + SUM_ST_R) |
| `correction_BR_AUDIT_option.sql` | Ancienne version script BR_AUDIT |
| `rollback_correction.sql` | Script pour annuler la correction |
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

# Execution (SCRIPT PRINCIPAL - corrige BR_AUDIT + SUMMARY)
sqlplus -S / as sysdba @/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/correction_BR_AUDIT_DEFINITIVE.sql
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
| 13/03/2026 | UPDATE BAL_ST = BAL_ST - DIFF | BAL_ST = 2,55 | - |
| 13/03/2026 | UPDATE DIFF = 0 | DIFF = 0 ✅ | - |
| 13/03/2026 | Verification DB SUMMARY | OK (2,55 / 0) | - |
| 13/03/2026 | Verification Application | ⚠️ Affiche encore 5,21 / 2,66 | - |
| 13/03/2026 | Cache navigateur vide | Toujours 5,21 / 2,66 | - |
| 13/03/2026 | Analyse script calcul | INSERT JC_ITEMS only, pas SUMMARY | - |
| 13/03/2026 | Hypothese: App recalcule depuis JC_ITEMS | Test DELETE JC_ITEMS | - |
| 13/03/2026 | DELETE BRD_EU_JC_ITEMS (202602, load 346241) | 0 records restants ✅ | - |
| 13/03/2026 | Verification Application | ⚠️ Ecart toujours present | - |
| 13/03/2026 | Verification BR_DATA | Records 878/879 encore presents ! | - |
| 13/03/2026 | DELETE BR_DATA (load 346241) | 0 records restants ✅ | - |
| 13/03/2026 | Etat final 202602 | SUMMARY=0, ITEMS=0, BR_DATA=0 ✅ | - |
| 13/03/2026 | Application | ⚠️ Ecart TOUJOURS present malgre DB OK | - |
| 13/03/2026 | Hypothese | Cache serveur ou Vue materialisee ? | - |
| 13/03/2026 | Analyse capture ecran | Detail OK, Resume cache anciennes valeurs | - |
| 13/03/2026 | Preuve | Detail=120.360 D, Resume=369.160,25 D (diff=248.800,25=record 878) | - |
| 13/03/2026 | Action requise | Regenerer/Recalculer rapport via interface | - |

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

## 12. CAPTURE ECRAN INTERFACE BALANCE CARREE (13/03/2026)

### 12.1 Vue Resume

| Colonne | BANQUE | COMPTABILITE |
|---------|--------|--------------|
| **Solde** | 5,21 C | 61 441 758,04 C |
| **Ecritures en suspens (D)** | 369 160,25 (3 items) | 0,00 |
| **Ecritures en suspens (C)** | 31 748 341,91 (4 items) | 30 062 578,93 (1 item) |
| **Solde de rapprochement** | 31 379 176,45 D | 31 379 179,11 C |

**Difference** : **2,66 C** ✓

### 12.2 Correspondance avec BRD_EU_JC_SUMMARY

| Interface | Colonne SQL | Valeur |
|-----------|-------------|--------|
| Solde BANQUE | BAL_ST | 5,21 |
| Solde COMPTABILITE | BAL_CB | 61 441 758,04 |
| Ecritures suspens D (BANQUE) | SUM_ST_P | -369 160,25 |
| Ecritures suspens C (BANQUE) | SUM_ST_R | 31 748 341,91 |
| Ecritures suspens C (COMPTA) | SUM_CB_P | 30 062 578,93 |
| Ecritures suspens D (COMPTA) | SUM_CB_R | 0 |
| Difference | DIFF | 2,66 |

✅ **Toutes les valeurs correspondent** entre l'interface et la table SQL.

### 12.3 Detail des Ecritures en Suspens (BANQUE)

**Ecritures D (3 items = 369 160,25)** :
- Dont records orphelins load_id 346241 : record 878 = 248 800,25 (25/02/2026)

**Ecritures C (4 items = 31 748 341,91)** :
- Dont records orphelins load_id 346241 : record 879 = 248 802,91 (25/02/2026)

### 12.4 Calcul Solde de Rapprochement

```
BANQUE:
  Solde de rapprochement = Solde - Ecritures D + Ecritures C
                        = 5,21 - 369160,25 + 31748341,91
                        = 31379176,87 (arrondi interface: 31379176,45 D)

  Formule SQL: SUM_REC_ST = BAL_ST - (SUM_ST_P + SUM_ST_R)
             = 5,21 - (-369160,25 + 31748341,91)
             = 5,21 - 31379181,66
             = -31379176,45 (le signe D indique debit)

COMPTABILITE:
  Solde de rapprochement = Solde - Ecritures C + Ecritures D
                        = 61441758,04 - 30062578,93 + 0
                        = 31379179,11 C

  Formule SQL: SUM_REC_CB = BAL_CB - (SUM_CB_P + SUM_CB_R)
             = 61441758,04 - (30062578,93 + 0)
             = 31379179,11
```

### 12.5 Synthese Visuelle

```
BANQUE                          COMPTABILITE
┌─────────────────────┐         ┌─────────────────────┐
│ Solde: 5,21 C       │         │ Solde: 61441758,04 C│
│                     │         │                     │
│ Suspens D: 369160,25│         │ Suspens D: 0        │
│   (3 items)         │         │                     │
│   ├─ 248800,25 ←────┼─────────┼─── Record 878      │
│   └─ autres...      │         │                     │
│                     │         │                     │
│ Suspens C:31748341,91         │ Suspens C:30062578,93
│   (4 items)         │         │   (1 item)          │
│   ├─ 248802,91 ←────┼─────────┼─── Record 879      │
│   └─ autres...      │         │                     │
│                     │         │                     │
│ Rappro: 31379176,45D│         │ Rappro: 31379179,11C│
└─────────────────────┘         └─────────────────────┘
                │                         │
                └────── DIFF = 2,66 C ────┘
```

---

## 13. CONTACTS

Pour toute question sur ce dossier, contacter l'equipe DBA.

---

---

## 14. EXECUTION CORRECTION (13/03/2026)

### 14.1 Commandes executees

```sql
-- Etape 1 : Correction BAL_ST
UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = BAL_ST - DIFF
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
COMMIT;
-- Resultat : BAL_ST = 2,55

-- Etape 2 : Correction DIFF (IMPORTANT - DIFF est stocke, pas calcule)
UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET DIFF = 0
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
COMMIT;
-- Resultat : DIFF = 0
```

### 14.2 Verification DB

```sql
SELECT BAL_ST, DIFF FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
```

| BAL_ST | DIFF |
|--------|------|
| 2,55 | 0 |

✅ **DB correctement mise a jour**

### 14.3 Probleme Application

**Constat** : Apres correction en DB, l'application affiche encore les anciennes valeurs :
- Solde BANQUE : 5,21 (devrait etre 2,55)
- Difference : 2,66 (devrait etre 0)

**Causes possibles** :
1. **Cache applicatif** - L'application garde les valeurs en memoire
2. **Rafraichissement necessaire** - Cliquer sur "Recalculer" ou "Rafraichir" dans l'interface
3. **Session applicative** - Se deconnecter/reconnecter a l'application

### 14.4 Actions a effectuer

1. **Rafraichir l'ecran Balance Carree** dans l'application
2. Si toujours incorrect : **Relancer le calcul Balance Carree** via le bouton "Calculer" ou equivalent
3. Si toujours incorrect : **Verifier qu'aucun batch nocturne** ne recalcule BRD_EU_JC_SUMMARY

**Note** : Le script `Traitement_Balance_Carre_Apres_Le_04.sql` ne modifie PAS BRD_EU_JC_SUMMARY (seulement BRD_EU_JC_ITEMS), donc notre correction devrait persister.

---

---

## 15. ANALYSE CAPTURE ECRAN APPLICATION (13/03/2026 14:43:09)

### 15.1 Resume Balance Carree (periode 28/02/2026)

| Element | BANQUE | COMPTABILITE |
|---------|--------|--------------|
| **Solde** | 5,21 C | 61.441.758,04 C |
| **Ecritures suspens D** | 369.160,25 (3 items) | 0,00 (0 items) |
| **Ecritures suspens C** | 31.748.341,91 (4 items) | 30.062.578,93 (1 item) |
| **Solde rapprochement** | 31.379.176,45 D | 31.379.179,11 C |
| **Difference** | **2,66 C** | |

### 15.2 Detail Ecritures en Suspens (FEB 2026)

| Date | Date Valeur | Type | Montant D | Montant C | Libelle |
|------|-------------|------|-----------|-----------|---------|
| 10/02/2026 | 03/02/2026 | STATEMENT | 360,00 | | FACTURE NUMERO... |
| 09/02/2026 | 09/02/2026 | STATEMENT | | 1.316.963,84 | CARDIF ASSURANCE VIE |
| 04/03/2026 | 12/02/2026 | CASHBOOK | | 30.062.578,93 | Flux APOLLO AGI |
| 17/02/2026 | 17/02/2026 | STATEMENT | | 30.062.578,93 | /DE AG INSURANCE |
| 20/02/2026 | 20/02/2026 | STATEMENT | 120.000,00 | | REMISE 0000001 VIRTS |
| 23/02/2026 | 23/02/2026 | STATEMENT | | 119.996,23 | 1/BNP PARIBAS CARDIF |
| **TOTAL** | | | **120.360,00** | **61.562.117,93** | |

### 15.3 Analyse de l'Incoherence

| Element | Resume | Detail | Ecart |
|---------|--------|--------|-------|
| Ecritures D | 369.160,25 | 120.360,00 | **248.800,25** |
| Ecritures C | 31.748.341,91 | ? | **248.802,91** |

**Ecarts = Records orphelins 878/879 (load 346241)**
- Record 878 : 248.800,25 (P = Payment)
- Record 879 : 248.802,91 (R = Receipt)
- NET : 248.802,91 - 248.800,25 = **2,66** = DIFF affiche

### 15.4 Conclusion

**Le detail est correct** (records orphelins supprimes), mais **le resume utilise les anciennes valeurs stockees** dans BRD_EU_JC_SUMMARY (SUM_ST_P, SUM_ST_R).

**Solution** : Mettre a jour SUM_ST_P et SUM_ST_R dans BRD_EU_JC_SUMMARY ou regenerer le rapport via l'interface.

---

## 16. ROLLBACK DES DELETE EFFECTUES (13/03/2026)

### 16.1 Actions DELETE effectuees

| Table | Criteres | Records supprimes | Methode rollback |
|-------|----------|-------------------|------------------|
| BR_DATA | acct_id=1906, load_id=346241 | 2 (records 878, 879) | **DataPump** |
| BRD_EU_JC_ITEMS | acct_id=1906, load_id=346241, period_jc=202602 | 2 (records 878, 879) | **INSERT ci-dessous** |

### 16.2 Rollback BR_DATA (via DataPump)

**IMPORTANT** : Les donnees BR_DATA sont sauvegardees via DataPump. Pour restaurer :

```bash
# Connexion serveur
sesu - oracle

# Import des donnees BR_DATA
/home/oracle/BALANCE_CARRE_ECART/1906_BBNP06492/datapump_import.sh
```

### 16.3 Rollback BRD_EU_JC_ITEMS (via INSERT)

```sql
-- =====================================================
-- ROLLBACK BRD_EU_JC_ITEMS - Compte 1906, Load 346241
-- Periode 202602 uniquement
-- =====================================================

-- Record 878 (Payment - Debit)
INSERT INTO BANKREC.BRD_EU_JC_ITEMS (
    PERIOD_JC, ACCT_ID, RECORD_ID, STATE, LOAD_ID,
    REC_GROUP, NUM_IN_GROUP, CS_FLAG, PR_FLAG, AMOUNT,
    REC_TIME, ORIG_ID, REFER_DATE
) VALUES (
    '202602', 1906, 878, 3, 346241,
    NULL, NULL, 'S', 'P', 248800.25,
    NULL, NULL, NULL
);

-- Record 879 (Receipt - Credit)
INSERT INTO BANKREC.BRD_EU_JC_ITEMS (
    PERIOD_JC, ACCT_ID, RECORD_ID, STATE, LOAD_ID,
    REC_GROUP, NUM_IN_GROUP, CS_FLAG, PR_FLAG, AMOUNT,
    REC_TIME, ORIG_ID, REFER_DATE
) VALUES (
    '202602', 1906, 879, 3, 346241,
    NULL, NULL, 'S', 'R', 248802.91,
    NULL, NULL, NULL
);

COMMIT;
```

### 16.4 Rollback BRD_EU_JC_SUMMARY (via UPDATE)

Si besoin de revenir aux valeurs avant correction :

```sql
-- Retour aux valeurs initiales (avant correction du 13/03/2026)
UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = 5.21,
    DIFF = 2.66
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
COMMIT;
```

### 16.5 Ordre de rollback complet

Pour un rollback complet dans l'ordre :

1. **Restaurer BR_DATA** via DataPump
2. **Executer INSERT** BRD_EU_JC_ITEMS (section 16.3)
3. **Executer UPDATE** BRD_EU_JC_SUMMARY (section 16.4)
4. **Verifier** que l'ecart est revenu a 2,66 EUR

---

## 17. ETAT ACTUEL ET OPTIONS DE CORRECTION

### 17.1 Etat mixte actuel (problematique)

Apres les actions du 13/03/2026, nous sommes dans un **etat mixte incoherent** :

| Element | Valeur actuelle | Coherence |
|---------|-----------------|-----------|
| BAL_ST | 2,55 | ✅ (Option 1) |
| DIFF | 0 | ✅ (force manuellement) |
| SUM_ST_P | -369160,25 | ❌ (inclut record 878 supprime) |
| SUM_ST_R | 31748341,91 | ❌ (inclut record 879 supprime) |
| JC_ITEMS 878/879 | SUPPRIMES | ❌ (Option 2) |
| BR_DATA 878/879 | SUPPRIMES | ❌ (Option 2) |

**Probleme** : Les records ont ete supprimes (Option 2), mais BAL_ST = 2,55 (Option 1).

### 17.2 Calcul verification

Pour que DIFF = 0 **reellement** (pas juste force), avec records supprimes :

```
SUM_ST_P_new = -120360,00 (sans record 878)
SUM_ST_R_new = 31499539,00 (sans record 879)

Pour DIFF = 0 :
  SUM_REC_ST + SUM_REC_CB = 0
  BAL_ST - (SUM_ST_P + SUM_ST_R) = -SUM_REC_CB
  BAL_ST = (SUM_ST_P + SUM_ST_R) - SUM_REC_CB
  BAL_ST = (-120360 + 31499539) - 31379179,11
  BAL_ST = 31379179 - 31379179,11
  BAL_ST = -0,11
```

### 17.3 Options de correction

#### Option A : Coherence complete (RECOMMANDEE)

Corriger BAL_ST ET SUM_ST pour refleter l'etat sans records orphelins :

```sql
-- =====================================================
-- CORRECTION COHERENTE - Option A
-- Compte 1906, Periode 202602
-- =====================================================

UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11,                    -- Solde avant load 346241
    SUM_ST_P = SUM_ST_P + 248800.25,   -- Retire record 878
    SUM_ST_R = SUM_ST_R - 248802.91,   -- Retire record 879
    DIFF = 0
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

COMMIT;
```

**Resultat attendu** : Application affichera correctement DIFF = 0

#### Option B : Annuler les DELETE et revenir a Option 1

Restaurer les records et garder BAL_ST = 2,55 :

```sql
-- 1. Restaurer BR_DATA via DataPump
-- 2. INSERT BRD_EU_JC_ITEMS (voir section 16.3)
-- 3. Mettre BAL_ST = 2,55, DIFF = 0
-- Les SUM_ST_P/R restent inchanges
```

#### Option C : Regenerer via interface

Utiliser le bouton "Calculer" ou "Recalculer" de l'interface Balance Carree.
L'application recalculera automatiquement toutes les valeurs depuis les donnees source.

### 17.4 Recommandation

**Option A** est la plus propre car elle aligne toutes les valeurs.

Script final a executer :

```sql
-- CORRECTION DEFINITIVE - Compte 1906, Periode 202602
UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11,
    SUM_ST_P = -120360.00,
    SUM_ST_R = 31499539.00,
    DIFF = 0
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

COMMIT;

-- Verification
SELECT PERIOD_JC, BAL_ST, SUM_ST_P, SUM_ST_R, DIFF,
       (BAL_ST - (SUM_ST_P + SUM_ST_R)) + (BAL_CB - (SUM_CB_P + SUM_CB_R)) AS DIFF_CALC
FROM BANKREC.BRD_EU_JC_SUMMARY
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
```

---

## 18. ANALYSE DU BATCH DE CALCUL (13/03/2026 15:30)

### 18.1 Comportement du script Traitement_Balance_Carre_Apres_Le_04.sql

| Element | Comportement |
|---------|--------------|
| **Source principale** | BR_DATA (lecture directe) |
| **Jointure BR_AUDIT** | OUI, uniquement pour state=4 (rec_time) |
| **Calcule BAL_ST ?** | **NON** - valeur STOCKEE |
| **Calcule SUM_ST_P/R ?** | **NON** - insere dans JC_ITEMS seulement |
| **Ignore records supprimes ?** | **OUI** - lit directement BR_DATA |

### 18.2 Provenance de BAL_ST

**BAL_ST est une valeur STOCKEE, pas calculee.**

- Provient du dernier chargement bancaire
- BR_AUDIT type=15 **trace** les changements mais **n'alimente pas** BAL_ST
- Le batch **ne recalcule PAS** BAL_ST

### 18.3 Comportement observe apres "Recalculer" (15:00:09)

| Element | Avant | Apres | Recalcule ? |
|---------|-------|-------|-------------|
| BAL_ST | 5,21 | 5,21 | **NON** |
| SUM_ST_P | -369160,25 | -120360,00 | **OUI** |
| SUM_ST_R | 31748341,91 | 31499539,00 | **OUI** |
| DIFF | 2,66 | **5,32** | **OUI** |

**Conclusion** : Le batch recalcule SUM_ST_P, SUM_ST_R et DIFF depuis JC_ITEMS, mais **garde BAL_ST inchange**.

### 18.4 Faut-il modifier BR_AUDIT ?

**NON** - Table d'audit pour tracabilite uniquement.

Les corrections doivent porter sur :
- BR_DATA (suppression records orphelins) ✓ FAIT
- BRD_EU_JC_ITEMS (suppression records orphelins) ✓ FAIT (via recalcul)
- BRD_EU_JC_SUMMARY (UPDATE BAL_ST et DIFF)

### 18.5 Solution definitive

Puisque BAL_ST n'est pas recalcule par le batch, notre UPDATE sera **persistant** :

```sql
UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11,
    DIFF = 0
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
COMMIT;
```

Lors du prochain batch :
1. SUM_ST_P = -120360 (recalcule, sans records 878/879) ✓
2. BAL_ST = -0.11 (notre valeur, non ecrasee) ✓
3. DIFF recalcule = 0 ✓

---

## 19. STRUCTURE BR_AUDIT ET ANALYSE SOURCE BAL_ST (13/03/2026 16:00)

### 19.1 Structure de la table BR_AUDIT

```sql
Nom           NULL ?   Type
------------- -------- ------------
ACCT_ID       NOT NULL NUMBER(38)   -- ID du compte
AUDIT_ID      NOT NULL NUMBER(38)   -- ID unique de l'audit
TYPE          NOT NULL NUMBER(38)   -- Type d'operation (0,1,15,16,18...)
TIMESTAMP              DATE         -- Date/heure de l'operation
CS_FLAG                CHAR(1 CHAR) -- C=Cashbook, S=Statement
RECORD_ID              NUMBER(38)   -- ID du record concerne
USER_ID                NUMBER(38)   -- ID utilisateur
BFR_STATE              NUMBER(38)   -- Etat avant
AFT_STATE              NUMBER(38)   -- Etat apres
NOTE_ID                NUMBER(38)
ORIG_ID                NUMBER(38)
BFR_DATE               DATE
AFT_DATE               DATE
WHICHONE               NUMBER(38)   -- *** LOAD_ID ***
RECMETHOD              NUMBER(38)
BFR_AMT                NUMBER(23,6) -- Montant AVANT (pour TYPE=15)
AFT_AMT                NUMBER(23,6) -- Montant APRES (pour TYPE=15)
NUM_IN_GRP             NUMBER(38)
PASS_ID                NUMBER(38)
SPARE_ONE              NUMBER(38)
SPARE_TWO              NUMBER(38)
SEQUENCE_NUM  NOT NULL NUMBER(38)
ATTACHMENT_ID          NUMBER(38)
```

### 19.2 Colonnes cles pour le calcul BAL_ST

| Colonne | Usage |
|---------|-------|
| **WHICHONE** | = load_id dans BR_DATA |
| **TYPE** | 15 = BALANCE_UPDATE |
| **BFR_AMT** | Solde AVANT le chargement |
| **AFT_AMT** | Solde APRES le chargement |

**Hypothese** : Le batch recalcule BAL_ST depuis AFT_AMT du dernier TYPE=15.

### 19.3 Requete de verification

```sql
SELECT audit_id, type, timestamp, whichone AS load_id,
       bfr_amt, aft_amt, cs_flag
FROM BANKREC.BR_AUDIT
WHERE acct_id = 1906
  AND whichone IN (346241, 346285)
  AND type = 15
ORDER BY timestamp;
```

---

## 20. DONNEES BR_AUDIT - ANALYSE COMPLETE (13/03/2026 16:15)

### 20.1 Donnees BR_AUDIT pour les loads 346241 et 346285

```sql
SELECT audit_id, type, timestamp, whichone AS load_id,
       bfr_amt, aft_amt, cs_flag
FROM BANKREC.BR_AUDIT
WHERE acct_id = 1906
  AND whichone IN (346241, 346285)
ORDER BY timestamp;
```

| audit_id | type | timestamp | load_id | bfr_amt | aft_amt | cs_flag | Description |
|----------|------|-----------|---------|---------|---------|---------|-------------|
| 3259 | **18** | 25/02/26 | 346241 | 0 | 0 | N | DEBUT_ROLLBACK |
| 3262 | **15** | 25/02/26 | 346241 | **-0,11** | **2,55** | S | BALANCE_UPDATE |
| 3263 | **16** | 25/02/26 | 346241 | 0 | 0 | N | EXEC_ROLLBACK |
| 3276 | **15** | 25/02/26 | 346285 | **2,55** | **5,21** | S | BALANCE_UPDATE |

### 20.2 Types BR_AUDIT identifies

| Type | Signification | Colonnes utilisees |
|------|---------------|-------------------|
| 0 | Changement d'etat (3→4) | bfr_state, aft_state |
| 1 | LOAD | - |
| 15 | BALANCE_UPDATE | bfr_amt, aft_amt |
| 16 | EXEC_ROLLBACK | whichone = load_id rollbacke |
| 18 | DEBUT_ROLLBACK | whichone = load_id a rollbacker |

### 20.3 Analyse du probleme - Chaine des soldes

```
CHRONOLOGIE DES SOLDES (25/02/2026) :

  [AVANT LOAD 346241]
  BAL_ST = -0,11 EUR

  │
  ▼ LOAD 346241 (15:57:11)

  [APRES LOAD 346241]
  BAL_ST = 2,55 EUR (+2,66 EUR = records 878/879)
  BR_AUDIT 3262: bfr_amt=-0,11, aft_amt=2,55

  │
  ▼ ROLLBACK 346241 (15:58:24) - *** ECHEC PARTIEL ***

  BR_AUDIT 3259: type=18 DEBUT_ROLLBACK
  BR_AUDIT 3263: type=16 EXEC_ROLLBACK

  *** MAIS les records 878/879 restent dans BR_DATA ***
  *** ET le solde reste a 2,55 (pas reinitialise a -0,11) ***

  │
  ▼ LOAD 346285 (22:39:56)

  [APRES LOAD 346285]
  BAL_ST = 5,21 EUR (+2,66 EUR)
  BR_AUDIT 3276: bfr_amt=2,55, aft_amt=5,21

  *** Le load 346285 a pris comme base 2,55 (FAUX) au lieu de -0,11 ***
```

### 20.4 Root Cause - Rollback incomplet

Le rollback du load 346241 a **echoue partiellement** :
- ✅ BR_AUDIT a enregistre les operations de rollback (type 18 et 16)
- ❌ Les records 878/879 n'ont PAS ete supprimes de BR_DATA
- ❌ Le solde n'a PAS ete reinitialise de 2,55 a -0,11

Le load suivant 346285 a utilise **bfr_amt = 2,55** (incorrect) au lieu de **bfr_amt = -0,11**.

### 20.5 Impact sur BAL_ST

**Question** : D'ou vient la valeur BAL_ST = 5,21 ?

**Reponse** : Le batch lit la derniere valeur AFT_AMT de type=15 pour ce compte.

```sql
-- Le batch fait probablement :
SELECT AFT_AMT INTO v_BAL_ST
FROM BR_AUDIT
WHERE ACCT_ID = 1906
  AND TYPE = 15
  AND CS_FLAG = 'S'
ORDER BY TIMESTAMP DESC
FETCH FIRST 1 ROW ONLY;

-- Resultat : AFT_AMT = 5,21 (de audit_id 3276, load 346285)
```

### 20.6 Solutions a la source

⚠️ **IMPORTANT** : Des fichiers sont charges quotidiennement sur ce compte.
La correction SUMMARY seule serait ecrasee au prochain load !

#### Solution 1 : Corriger BR_AUDIT + SUMMARY (RECOMMANDEE ✅)

Corriger la chaine des soldes a la source pour une solution **permanente** :

```sql
-- ETAPE 1 : Corriger BR_AUDIT (source du probleme)
UPDATE BANKREC.BR_AUDIT
SET BFR_AMT = -0.11,
    AFT_AMT = 2.55
WHERE ACCT_ID = 1906
  AND AUDIT_ID = 3276
  AND TYPE = 15;

-- ETAPE 2 : Corriger SUMMARY (effet immediat)
UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11,
    DIFF = 0
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';

COMMIT;
```

**Avantages** :
- Solution **permanente** - le prochain load utilisera la bonne base
- Corrige la chaine des soldes a la source
- Les prochains fichiers charges seront corrects

**Script** : `correction_BR_AUDIT_DEFINITIVE.sql`

#### Solution 2 : Corriger uniquement BRD_EU_JC_SUMMARY (NON VIABLE ❌)

```sql
UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = -0.11, DIFF = 0
WHERE ACCT_ID = 1906 AND PERIOD_JC = '202602';
```

**PROBLEME** : Cette correction sera **ecrasee** au prochain chargement de fichier car le systeme lira `aft_amt = 5.21` depuis BR_AUDIT.

### 20.7 Verification post-correction

Apres correction de BAL_ST = -0.11, le batch calculera :

```
SUM_ST_P = -120360,00 (sans record 878)
SUM_ST_R = 31499539,00 (sans record 879)
SUM_ST_P + SUM_ST_R = 31379179,00

SUM_REC_ST = BAL_ST - (SUM_ST_P + SUM_ST_R)
           = -0,11 - 31379179,00
           = -31379179,11

SUM_REC_CB = 31379179,11 (inchange)

DIFF = SUM_REC_ST + SUM_REC_CB
     = -31379179,11 + 31379179,11
     = 0 EUR ✅
```

### 20.8 Script final recommande

Voir fichier : `correction_finale_BAL_ST.sql`

```sql
UPDATE BANKREC.BRD_EU_JC_SUMMARY
SET BAL_ST = BAL_ST - DIFF,  -- 5,21 - 5,32 = -0,11
    DIFF = 0
WHERE ACCT_ID = 1906
  AND PERIOD_JC = '202602'
  AND DIFF != 0;

COMMIT;
```

### 20.9 Resultat attendu

| Colonne | Avant | Apres |
|---------|-------|-------|
| BAL_ST | 5,21 | **-0,11** |
| DIFF | 5,32 | **0** |
| Application | Ecart 5,32 | **Ecart 0** |

---

## 21. HISTORIQUE DES ACTIONS (MISE A JOUR)

| Date | Heure | Action | Resultat |
|------|-------|--------|----------|
| 25/02/2026 | 15:57 | Load 346241 | Solde passe de -0,11 a 2,55 |
| 25/02/2026 | 15:58 | Rollback 346241 | **ECHEC** - records 878/879 restent |
| 25/02/2026 | 22:39 | Load 346285 | Solde passe de 2,55 a 5,21 (base fausse) |
| 07/03/2026 | - | Investigation debut | Root cause identifiee |
| 13/03/2026 | 14:00 | DELETE BR_DATA + JC_ITEMS | Records supprimes |
| 13/03/2026 | 15:00 | "Recalculer" via interface | DIFF passe de 2,66 a 5,32 ! |
| 13/03/2026 | 15:30 | Analyse batch | BAL_ST non recalcule par batch |
| 13/03/2026 | 16:00 | Analyse BR_AUDIT | Source BAL_ST = AFT_AMT type=15 |
| 13/03/2026 | 16:15 | Ajout donnees BR_AUDIT | Solution definitive identifiee |

---

*Derniere mise a jour : 13/03/2026 16:15 - Donnees BR_AUDIT et solution definitive*
