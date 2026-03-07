# TRACE - Balance Carree Compte 1906

**Date investigation : 07/03/2026**
**Compte : BBNP06492-EUR-ST (acct_id = 1906)**
**Probleme : Ecart de 2,66€ dans la Balance Carree**

---

## 1. Historique des Chargements (depuis l'interface)

| Charger etat | ID Chargement | Compte | Cote | Resultat | Nb Ops | Solde Initial | Solde Final | Fichier |
|--------------|---------------|--------|------|----------|--------|---------------|-------------|---------|
| | 346621 | BBNP06492-EUR-ST | Banque | Reussi | 1 | 102 501,44 | -46 599,56 | ReleveCompteEspece.txt |
| | 346587 | BBNP06492-EUR-ST | Banque | Reussi | 0 | 102 501,44 | 102 501,44 | ReleveCompteEspece.txt |
| | 346577 | BBNP06492-EUR-ST | Banque | Reussi | 1 | -109,81 | 102 501,44 | ReleveCompteEspece.txt |
| | 346527 | BBNP06492-EUR-ST | Banque | Reussi | 1 | -388 345,81 | -109,81 | ReleveCompteEspece.txt |
| | 346491 | BBNP06492-EUR-ST | Banque | Reussi | 2 | 2,55 | -388 345,81 | ReleveCompteEspece.txt |
| **Rollback effectue** | **346285** | BBNP06492-EUR-ST | Banque | Reussi | 2 | 2,55 | 5,21 | ReleveCompteEspece.txt |

---

## 2. Donnees BR_AUDIT du 25/02/2026

### Types d'operations
| TYPE | Nb Occurrences | Signification |
|------|----------------|---------------|
| 0 | 450 | STATE_CHANGE |
| 1 | 461 | LOAD |
| 2 | 39 | ? |
| 5 | 322 | BALANCE |
| 15 | 215 | BALANCE_UPDATE |
| 16 | 207 | EXEC_ROLLBACK |
| 17 | 2 | ? |
| 18 | 207 | DEBUT_ROLLBACK |

### Colonnes BR_AUDIT
```
ACCT_ID, AUDIT_ID, TYPE, TIMESTAMP, CS_FLAG, RECORD_ID, USER_ID,
BFR_STATE, AFT_STATE, NOTE_ID, ORIG_ID, BFR_DATE, AFT_DATE,
WHICHONE, RECMETHOD, BFR_AMT, AFT_AMT, NUM_IN_GRP, PASS_ID,
SPARE_ONE, SPARE_TWO, SEQUENCE_NUM, ATTACHMENT_ID
```

**Important : WHICHONE = identifiant du chargement (= load_id dans BR_DATA)**

### Rollbacks detectes le 25/02/2026
```
TYPE  AUDIT_ID  WHICHONE  HEURE
18    3241      346199    04:05:37  (DEBUT_ROLLBACK)
16    3245      346199    04:05:52  (EXEC_ROLLBACK)
18    3259      346241    15:57:11  (DEBUT_ROLLBACK)
16    3263      346241    15:58:24  (EXEC_ROLLBACK)
```

### Evolution du solde (TYPE=15) le 25/02/2026
```
AUDIT_ID  CS_FLAG  WHICHONE  BFR_AMT       AFT_AMT       HEURE
3244      C        346199    1277822,49    1201112,49    04:05:37
3262      S        346241    -0,11         2,55          15:57:11
3276      S        346285    2,55          5,21          22:39:56
```

---

## 3. Chronologie du probleme

| Heure | TYPE | Action | WHICHONE | Solde AVANT | Solde APRES |
|-------|------|--------|----------|-------------|-------------|
| 04:05:37 | 1 | LOAD | 346199 | - | - |
| 04:05:37 | 18 | DEBUT_ROLLBACK | 346199 | - | - |
| 04:05:52 | 16 | EXEC_ROLLBACK | 346199 | - | - |
| 15:57:11 | 1 | LOAD | 346241 | - | - |
| 15:57:11 | 15 | Balance S | 346241 | **-0,11** | **2,55** |
| 15:57:11 | 18 | DEBUT_ROLLBACK | 346241 | - | - |
| 15:58:24 | 16 | EXEC_ROLLBACK | 346241 | - | - |
| 22:39:56 | 1 | LOAD | 346285 | - | - |
| 22:39:56 | 15 | Balance S | 346285 | **2,55** | **5,21** |

---

## 4. Root Cause

Le **load_id 346241** (15h57) a ete rollbacke mais :
- Les records n'ont PAS ete supprimes de BR_DATA
- Le solde n'a PAS ete reinitialise de 2,55€ a -0,11€

Quand le load 346285 (22h39) est arrive, il a trouve un solde de depart errone (2,55€ au lieu de -0,11€).

---

## 5. Records orphelins trouves dans BR_DATA

```sql
SELECT record_id, state, amount, cs_flag, trans_date, load_id
FROM BR_DATA
WHERE acct_id = 1906 AND load_id = 346241;
```

| record_id | state | amount | cs_flag | trans_date | load_id |
|-----------|-------|--------|---------|------------|---------|
| 878 | 3 (SUSPENS) | 248 800,25 | S | 25/02/26 | 346241 |
| 879 | 3 (SUSPENS) | 248 802,91 | S | 25/02/26 | 346241 |

```sql
-- Compter les records
SELECT COUNT(*) as nb_records, SUM(amount) as total_amount
FROM BR_DATA
WHERE acct_id = 1906 AND load_id = 346241;
```

| nb_records | total_amount |
|------------|--------------|
| 2 | 497 603,16 |

### Explication du calcul de l'ecart

**Pourquoi 2 records de 497 603,16€ au total causent un ecart de 2,66€ ?**

Dans un systeme de reconciliation bancaire :
- Les montants peuvent representer des debits et credits
- L'effet NET sur le solde = difference entre les montants

```
Record 879 : 248 802,91 € (credit ou montant positif)
Record 878 : 248 800,25 € (debit ou montant negatif en contrepartie)
─────────────────────────────────────────────────────────────────
Effet NET : 248 802,91 - 248 800,25 = +2,66 €
```

**C'est exactement l'ecart de la Balance Carree !**

Ces 2 records appartiennent au load rollbacke (346241) mais sont restes dans BR_DATA.
Leur effet NET de +2,66€ cause l'ecart dans la Balance Carree.

---

## 6. Solution

### Script de suppression
```sql
DELETE FROM BR_DATA
WHERE acct_id = 1906
  AND load_id = 346241;

COMMIT;
```

Puis relancer le calcul de la Balance Carree.

### Script de retour arriere (si besoin de restaurer)
```sql
-- ============================================================
-- SCRIPT RETOUR ARRIERE - Compte 1906, Load 346241
-- A executer UNIQUEMENT si besoin de restaurer les records
-- ============================================================

INSERT INTO BR_DATA (record_id, acct_id, state, amount, cs_flag, trans_date, load_id)
VALUES (878, 1906, 3, 248800.25, 'S', TO_DATE('2026-02-25', 'YYYY-MM-DD'), 346241);

INSERT INTO BR_DATA (record_id, acct_id, state, amount, cs_flag, trans_date, load_id)
VALUES (879, 1906, 3, 248802.91, 'S', TO_DATE('2026-02-25', 'YYYY-MM-DD'), 346241);

COMMIT;

-- Verification
SELECT record_id, state, amount, cs_flag, trans_date, load_id
FROM BR_DATA
WHERE acct_id = 1906 AND load_id = 346241;
```

---

## 7. Resume

| Element | Valeur |
|---------|--------|
| Compte | 1906 (BBNP06492-EUR-ST) |
| Date rollback | 25/02/2026 a 15:58:24 |
| Load rollbacke | 346241 |
| Records orphelins | 878, 879 |
| Ecart | 2,66€ |
| Cause | Records non supprimes apres rollback |
| Solution | DELETE load_id=346241 de BR_DATA |
