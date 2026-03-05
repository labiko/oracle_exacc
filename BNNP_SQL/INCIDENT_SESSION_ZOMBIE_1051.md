# INCIDENT : Session Zombie SID 1051 - Cause du blocage DTC670

**Date de l'incident** : 13/02/2026 20:53
**Date de detection** : 20/02/2026
**Duree du blocage** : 7 jours
**Impact** : Batch DTC670/BAATGS ne termine plus depuis le 13/02

---

## 1. CONTEXTE

Le batch DTC670 (extraction BAATGS) fonctionnait correctement jusqu'au **13/02/2026 a 06:21**.
Depuis cette date, le batch ne termine plus et reste bloque pendant des heures.

### Symptomes observes
- Batch DTC670 lance a 04:05 toujours en cours a 09:30 (5h+ d'execution)
- I/O disque a 98% d'utilisation (iostat)
- iowait a 34-36%

---

## 2. DIAGNOSTIC

### 2.1 Requete de diagnostic des sessions actives

```sql
SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.STATUS,
    s.EVENT,
    s.SECONDS_IN_WAIT AS WAIT_SEC,
    s.SQL_ID,
    SUBSTR(s.PROGRAM, 1, 30) AS PROGRAM,
    SUBSTR(s.MACHINE, 1, 20) AS MACHINE,
    TO_CHAR(s.LOGON_TIME, 'DD/MM HH24:MI') AS LOGON
FROM V$SESSION s
WHERE s.STATUS = 'ACTIVE'
  AND s.USERNAME IS NOT NULL
  AND s.TYPE = 'USER'
ORDER BY s.SECONDS_IN_WAIT DESC;
```

### 2.2 Resultat

| SID | SERIAL# | USERNAME | STATUS | EVENT | WAIT_SEC | SQL_ID | PROGRAM | MACHINE | LOGON |
|-----|---------|----------|--------|-------|----------|--------|---------|---------|-------|
| 1050 | 3990 | SYS | ACTIVE | PL/SQL lock timer | 27 | g0bggfqrddc4w | emagent | s01vl9976319 | 07/01 15:26 |
| 1088 | 65042 | SYS | ACTIVE | SQL*Net message from client | 8 | | rman@s01vl9976319 | s01vl9976319 | 20/02 07:37 |
| 29 | 32420 | SYS | ACTIVE | resmgr:cpu quantum | 6 | | rman@s01vl9976319 | s01vl9976319 | 20/02 08:30 |
| 24 | 8819 | SYS | ACTIVE | control file parallel write | 2 | | rman@s01vl9976319 | s01vl9976319 | 20/02 08:30 |
| 560 | 35485 | SYS | ACTIVE | control file parallel write | 0 | | rman@s01vl9976319 | s01vl9976319 | 20/02 08:30 |
| **600** | **35485** | **EXP_RNAPA** | **ACTIVE** | **db file sequential read** | **0** | **7prpuy907rpz2** | **sqlplus@s01vl9976318** | s01vl9976318 | **20/02 04:05** |
| 1104 | 58940 | BANKREC | ACTIVE | db file sequential read | 0 | crnunu9u7www0 | JDBC Thin Client | s01vl9986184 | 20/02 08:02 |
| **1051** | **16792** | **NXGREC** | **ACTIVE** | **db file scattered read** | **0** | **6qtw83zkc6whg** | **autoclient@s01vl9976318** | s01vl9976318 | **13/02 20:53** |
| 1055 | 40337 | EXP_RNAPA | ACTIVE | SQL*Net message to client | 0 | 44wrky8g0uuz9 | SQL Developer | PARM00763539 | 20/02 09:34 |

### 2.3 Analyse

**Session suspecte identifiee : SID 1051**

| Attribut | Valeur | Signification |
|----------|--------|---------------|
| SID | 1051 | Identifiant session |
| SERIAL# | 16792 | Serial number |
| USERNAME | NXGREC | Compte applicatif |
| LOGON | **13/02 20:53** | **Session active depuis 7 JOURS !** |
| EVENT | db file scattered read | Full table scan permanent |
| PROGRAM | autoclient | Application cliente |

---

## 3. IDENTIFICATION DE LA REQUETE ZOMBIE

### 3.1 Requete pour voir le SQL execute

```sql
SELECT SQL_FULLTEXT FROM V$SQL WHERE SQL_ID = '6qtw83zkc6whg';
```

### 3.2 Resultat

```sql
UPDATE br_data
SET flag_c = 'C', user_two = 6485
WHERE acct_id = 16
  AND state = 4
  AND rec_group = 483601
```

### 3.3 Analyse

Cette requete UPDATE simple devrait s'executer en **quelques secondes**.
Le fait qu'elle tourne depuis **7 jours** indique un probleme grave :
- Full table scan sur BR_DATA (millions de lignes)
- Probablement pas d'index sur les colonnes (acct_id, state, rec_group)

---

## 4. VERIFICATION DES VERROUS

### 4.1 Requete pour verifier si la session est bloquee

```sql
SELECT
    blocking_session AS BLOQUEUR_SID,
    sid AS BLOQUE_SID,
    wait_class,
    event,
    seconds_in_wait
FROM V$SESSION
WHERE SID = 1051;
```

### 4.2 Resultat

| BLOQUEUR_SID | BLOQUE_SID | WAIT_CLASS | EVENT | SECONDS_IN_WAIT |
|--------------|------------|------------|-------|-----------------|
| NULL | 1051 | User I/O | db file scattered read | 0 |

### 4.3 Analyse

- `blocking_session = NULL` : La session n'est PAS bloquee par une autre
- `event = db file scattered read` : Full table scan actif en continu
- La session fait des lectures disque permanentes depuis 7 jours

---

## 5. IDENTIFICATION DU PROGRAMME SOURCE

### 5.1 Requete pour identifier le programme

```sql
SELECT
    s.SID,
    s.SERIAL#,
    s.USERNAME,
    s.OSUSER,
    s.MACHINE,
    s.TERMINAL,
    s.PROGRAM,
    s.MODULE,
    s.ACTION,
    s.CLIENT_INFO,
    s.CLIENT_IDENTIFIER,
    s.PROCESS AS CLIENT_PROCESS,
    p.SPID AS SERVER_PROCESS,
    TO_CHAR(s.LOGON_TIME, 'DD/MM/YYYY HH24:MI:SS') AS LOGON_TIME
FROM V$SESSION s
LEFT JOIN V$PROCESS p ON p.ADDR = s.PADDR
WHERE s.SID = 1051;
```

### 5.2 Resultat

| Attribut | Valeur |
|----------|--------|
| SID | 1051 |
| SERIAL# | 16792 |
| USERNAME | NXGREC |
| **OSUSER** | **aparnap1** |
| **MACHINE** | **s01vl9976318** |
| TERMINAL | (vide) |
| **PROGRAM** | **autoclient@s01vl9976318 (TNS V1-V3)** |
| MODULE | autoclient@s01vl9976318 (TNS V1-V3) |
| ACTION | (vide) |
| CLIENT_INFO | (vide) |
| CLIENT_IDENTIFIER | (vide) |
| **CLIENT_PROCESS** | **2466800** |
| **SERVER_PROCESS** | **148147** |
| LOGON_TIME | 13/02/2026 20:53:17 |

### 5.3 Analyse

| Element | Description |
|---------|-------------|
| `autoclient` | Client Oracle batch automatise (utilise avec Control-M ou autre ordonnanceur) |
| `aparnap1` | Compte Unix applicatif PARNA sur le serveur client |
| `s01vl9976318` | Serveur d'application PARNA |
| `2466800` | PID du process client (a verifier s'il existe encore) |
| `148147` | PID du process Oracle serveur (SPID) |

### 5.4 Verification du process client

```bash
# Sur le serveur client s01vl9976318
ps -ef | grep 2466800
```

### 5.5 Resultat process CLIENT (s01vl9976318)

```
aparnap1 2466800       1  0 Feb13 ?        00:01:53 autoclient --credentials=/apps/accurate/current/conf/creds.ini -mBNP_Parisbas_Ass_Prelettrage_acs_cs.acs GESTION
```

| Attribut | Valeur | Signification |
|----------|--------|---------------|
| USER | aparnap1 | Compte applicatif PARNA |
| PID | 2466800 | Process ID client |
| **PPID** | **1** | **Process ORPHELIN (parent mort)** |
| START | Feb13 | Lance le 13 fevrier |
| TIME | 00:01:53 | Seulement 2 min de CPU en 7 jours |
| COMMAND | autoclient | Client Accurate |
| Script | BNP_Parisbas_Ass_Prelettrage_acs_cs.acs | Script de **prelettrage** |
| Parametre | GESTION | Service concerne |

### 5.6 Verification du process serveur Oracle

```bash
# Sur le serveur Oracle s01vl9976319
ps -ef | grep 148147
```

### 5.7 Resultat process SERVEUR (s01vl9976319)

```
oracle    148147       1 49 Feb13 ?        3-06:21:13 oracleP08449AP10 (LOCAL=NO)
```

| Attribut | Valeur | Signification |
|----------|--------|---------------|
| USER | oracle | Compte Oracle |
| PID | 148147 | Process ID serveur Oracle (SPID) |
| **PPID** | **1** | **Process ORPHELIN cote serveur aussi !** |
| **%CPU** | **49%** | **Consomme 49% du CPU en permanence !** |
| START | Feb13 | Lance le 13 fevrier |
| **TIME** | **3-06:21:13** | **78+ heures de CPU consommees en 7 jours !** |
| COMMAND | oracleP08449AP10 | Process serveur base P08449A |

### 5.8 Analyse CRITIQUE

```
┌─────────────────────────────────────────────────────────────┐
│  DOUBLE ORPHELIN : CLIENT + SERVEUR                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Client (s01vl9976318):                                     │
│    PID 2466800 - PPID=1 - 2 min CPU - autoclient            │
│    Script: BNP_Parisbas_Ass_Prelettrage_acs_cs.acs          │
│                                                             │
│  Serveur Oracle (s01vl9976319):                            │
│    PID 148147 - PPID=1 - 78+ HEURES CPU - 49% CPU actuel   │
│                                                             │
│  Les deux processus sont ORPHELINS (PPID=1)                │
│  Le process parent (Control-M/shell) est mort              │
│  Mais les enfants continuent de tourner indefiniment       │
└─────────────────────────────────────────────────────────────┘
```

### 5.9 Precision terminologique : Zombie vs Orphelin

| Type | Definition | Etat process | Ressources consommees |
|------|------------|--------------|----------------------|
| **Zombie (Z)** | Process termine, parent n'a pas fait `wait()` | STATE = Z | Aucune (juste entree dans table) |
| **Orphelin** | Parent mort, enfant adopte par init (PID 1) | STATE = R/S (actif) | **Continue de consommer !** |

**Dans notre cas :**

- `PPID = 1` → Le parent est MORT, les enfants ont ete adoptes par init
- `STATE = actif` (pas Z) → Les processus CONTINUENT de tourner

**Ce sont des ORPHELINS ACTIFS**, pas des zombies au sens strict Unix.

Le terme "zombie" est utilise ici comme **abus de langage courant** pour designer un processus qui :
- Ne devrait plus tourner (le batch parent est termine)
- Continue de consommer des ressources indefiniment
- N'a plus de supervision (personne ne le surveille)

**C'est PIRE qu'un zombie** car ca **consomme activement des ressources** (49% CPU + 98% I/O) depuis 7 jours !

---

## 6. CONFIRMATION : SESSION ZOMBIE TOUJOURS ACTIVE

### 6.1 Requete de verification (20/02/2026 ~10h)

```sql
SELECT SID, SERIAL#, USERNAME, STATUS, EVENT, SQL_ID,
       TO_CHAR(LOGON_TIME, 'DD/MM HH24:MI') AS LOGON
FROM V$SESSION
WHERE SID = 1051;
```

### 6.2 Resultat

| SID | SERIAL# | USERNAME | STATUS | EVENT | SQL_ID | LOGON |
|-----|---------|----------|--------|-------|--------|-------|
| 1051 | 16792 | NXGREC | ACTIVE | db file scattered read | 6qtw83zkc6whg | 13/02 20:53 |

**CONFIRMATION : La session zombie tourne TOUJOURS depuis 7 jours !**

---

## 7. VERIFICATION : MEME TABLE UTILISEE

### 7.1 Requete pour verifier les synonymes

```sql
-- Verifier si BR_DATA est un synonyme
SELECT OWNER, SYNONYM_NAME, TABLE_OWNER, TABLE_NAME
FROM ALL_SYNONYMS
WHERE SYNONYM_NAME = 'BR_DATA';
```

### 7.2 Resultat

| OWNER | SYNONYM_NAME | TABLE_OWNER | TABLE_NAME |
|-------|--------------|-------------|------------|
| EXP_RNAPA | BR_DATA | BANKREC | BR_DATA |
| NXGREC | BR_DATA | BANKREC | BR_DATA |

### 7.3 Requete pour verifier la table reelle

```sql
SELECT OWNER, TABLE_NAME
FROM ALL_TABLES
WHERE TABLE_NAME = 'BR_DATA';
```

### 7.4 Resultat

| OWNER | TABLE_NAME |
|-------|------------|
| BANKREC | BR_DATA |

### 7.5 Analyse CRITIQUE

```
┌─────────────────────────────────────────────────────────────────┐
│          CONFIRMATION : MEME TABLE BANKREC.BR_DATA              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Schema EXP_RNAPA ──→ Synonyme BR_DATA ──→ BANKREC.BR_DATA     │
│  Schema NXGREC    ──→ Synonyme BR_DATA ──→ BANKREC.BR_DATA     │
│                                                                 │
│  Les DEUX sessions accedent a la MEME table physique !         │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│  SID 1051 (NXGREC)    → UPDATE sur BANKREC.BR_DATA (7 jours!)  │
│  SID 600  (EXP_RNAPA) → SELECT sur BANKREC.BR_DATA (DTC670)    │
│                                                                 │
│  Les deux sessions saturent les I/O sur les MEMES blocs !      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. IMPACT SUR LE SYSTEME

### 8.1 Chronologie

| Date | Heure | Evenement |
|------|-------|-----------|
| 13/02/2026 | 06:21 | DTC670 fonctionne normalement (derniere execution OK) |
| 13/02/2026 | 20:53 | **SID 1051 demarre** (et ne s'arrete jamais) |
| 14/02 - 20/02 | - | DTC670 ne termine plus (timeout ou abandon) |
| 20/02/2026 | 04:05 | DTC670 relance, toujours en cours a 09:30 |

### 8.2 Metriques I/O (iostat)

```
Device    r/s     w/s   rkB/s    wkB/s  %util
sda      245.0   89.5  12456.0  4523.0   97.8
sdb      312.0   45.2  18234.0  2345.0   98.2
```

- **%util = 97-98%** : Disques satures
- **iowait = 34-36%** : CPU attend les I/O
- Cause : Session zombie SID 1051 fait des full scans en continu

---

## 9. ROOT CAUSE

```
┌─────────────────────────────────────────────────────────────┐
│ ROOT CAUSE : Session zombie SID 1051                        │
├─────────────────────────────────────────────────────────────┤
│ - Requete UPDATE sans index fait un full scan permanent     │
│ - Consomme 100% des I/O disque depuis 7 jours               │
│ - Accede a la MEME table que DTC670 (BANKREC.BR_DATA)       │
│ - Empeche tous les autres batchs de s'executer normalement  │
│ - Le DTC670 (SID 600) ne peut pas progresser                │
└─────────────────────────────────────────────────────────────┘
```

---

## 10. SOLUTION

### 10.1 Action immediate : Killer les processus zombie

**ETAPE 1 : Kill cote CLIENT (s01vl9976318)**

```bash
# Se connecter sur le serveur client
ssh aparnap1@s01vl9976318

# Killer le process autoclient
kill -9 2466800

# Verifier que le process est bien tue
ps -ef | grep 2466800
```

**ETAPE 2 : Kill cote ORACLE (s01vl9976319) - si necessaire**

```sql
-- Methode SQL (preferee)
ALTER SYSTEM KILL SESSION '1051,16792' IMMEDIATE;
```

OU si le kill SQL ne fonctionne pas :

```bash
# Se connecter sur le serveur Oracle
ssh oracle@s01vl9976319

# Killer le process Oracle serveur
kill -9 148147

# Verifier que le process est bien tue
ps -ef | grep 148147
```

### 10.2 Verification apres le kill

**Verification Oracle :**

```sql
-- Verifier que la session est bien tuee
SELECT SID, STATUS FROM V$SESSION WHERE SID = 1051;
-- Resultat attendu : aucune ligne
```

**Verification I/O (Linux) :**

```bash
# Sur le serveur Oracle s01vl9976319
iostat -x 2 3
```

**Resultat attendu :**
- `%util` devrait passer de **98%** a **< 50%**
- `iowait` devrait passer de **34-36%** a **< 10%**

### 10.3 Verification process client

```bash
# Sur le serveur client s01vl9976318
ps -ef | grep 2466800
# Resultat attendu : aucune ligne (ou seulement le grep)
```

### 10.4 Relance DTC670

Apres avoir tue la session zombie, le DTC670 actuel (SID 600) devrait :
- Soit accelerer significativement
- Soit etre relance manuellement avec la version optimisee

```bash
# Relancer le batch DTC670 avec le standalone optimise
sqlplus EXP_RNAPA/****@P08449A @DTC670_EXTRACTION_COMPLETE.sql
```

### 10.5 Action preventive : Creer un index

```sql
-- Pour eviter que ca se reproduise
-- A executer en heures creuses (impact sur les performances pendant la creation)
CREATE INDEX IDX_BR_DATA_ACCT_STATE_REC
ON BANKREC.BR_DATA(ACCT_ID, STATE, REC_GROUP);

-- Mettre a jour les statistiques
EXEC DBMS_STATS.GATHER_TABLE_STATS('BANKREC', 'BR_DATA', CASCADE => TRUE);
```

### 10.6 Monitoring futur

```sql
-- Ajouter une alerte pour les sessions actives > 24h
-- A integrer dans le monitoring Oracle
SELECT SID, SERIAL#, USERNAME, STATUS, PROGRAM,
       ROUND((SYSDATE - LOGON_TIME) * 24, 1) AS HEURES_ACTIF
FROM V$SESSION
WHERE STATUS = 'ACTIVE'
  AND USERNAME IS NOT NULL
  AND (SYSDATE - LOGON_TIME) > 1  -- Plus de 24h
ORDER BY LOGON_TIME;
```

---

## 11. LECONS APPRISES

1. **Monitoring des sessions longues** : Mettre en place une alerte pour les sessions > 24h
2. **Index manquants** : La table BR_DATA manque d'index sur les colonnes de filtrage
3. **Impact des full scans** : Un seul full scan permanent peut bloquer tout le systeme
4. **RMAN concurrence** : Les backups RMAN (vus dans le diagnostic) ajoutent de la charge I/O
5. **Synonymes** : Attention aux synonymes qui masquent l'acces a la meme table physique

---

## 12. FICHIERS ASSOCIES

| Fichier | Description |
|---------|-------------|
| DIAGNOSTIC_CONTROLM_BATCH.sql | Script de diagnostic des sessions Control-M |
| DTC670_EXTRACTION_COMPLETE.sql | Script standalone optimise (CTE) |
| PKG_RNADEXTAUTO01_DEPLOY_FULL_OPTIM.sql | Curseur CTE optimise pour le package |
| VERIFICATION_DTC670_FULL_OPTIM.sql | Script de verification non-regression |

---

## 13. STATUT

| Action | Statut | Date |
|--------|--------|------|
| Identification session zombie | FAIT | 20/02/2026 |
| Identification requete SQL | FAIT | 20/02/2026 |
| Verification verrous | FAIT | 20/02/2026 |
| Identification programme source | FAIT | 20/02/2026 |
| Verification process client (PID 2466800) | FAIT | 20/02/2026 |
| Verification process serveur (PID 148147) | FAIT | 20/02/2026 |
| Confirmation double orphelin (PPID=1) | FAIT | 20/02/2026 |
| Confirmation meme table | FAIT | 20/02/2026 |
| Kill process client (kill -9 2466800) | **A FAIRE** | - |
| Kill session Oracle (ALTER SYSTEM KILL) | **A FAIRE** | - |
| Verification I/O apres kill (iostat) | **A FAIRE** | - |
| Relance DTC670 | **A FAIRE** | - |
| Creation index preventif | **A FAIRE** | - |

---

## 14. RESUME EXECUTIF

```
┌─────────────────────────────────────────────────────────────────┐
│  INCIDENT : Session zombie bloquant DTC670 depuis 7 jours      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CAUSE : Batch prelettrage (autoclient) lance le 13/02/2026    │
│          Le process parent est mort, les enfants continuent    │
│          UPDATE sans index = full scan permanent sur BR_DATA   │
│                                                                 │
│  IMPACT :                                                       │
│    - 78+ heures de CPU consommees                              │
│    - 49% CPU + 98% I/O disque monopolises                      │
│    - Tous les batchs sur BR_DATA bloques                       │
│    - DTC670 ne termine plus depuis 7 jours                     │
│                                                                 │
│  SOLUTION :                                                     │
│    1. kill -9 2466800  (client s01vl9976318)                   │
│    2. ALTER SYSTEM KILL SESSION '1051,16792' IMMEDIATE;        │
│    3. Verifier iostat (%util < 50%)                            │
│    4. Relancer DTC670                                          │
│                                                                 │
│  PREVENTION :                                                   │
│    - Creer index sur BR_DATA(ACCT_ID, STATE, REC_GROUP)        │
│    - Monitoring sessions > 24h                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

**Redige par** : Equipe DBA/DEV
**Date** : 20/02/2026
**Derniere mise a jour** : 20/02/2026 10:50
