# CLAUDE.md - Contexte Multi-Projets

Ce fichier permet à Claude de retrouver le contexte des différents projets.

**Derniere mise a jour : 23/02/2026**

---

# TABLE DES MATIÈRES

1. [BNPP SQL - Investigation Transaction 2817 EUR](#projet-1--bnpp-sql---investigation-transaction-2817-eur)
2. [BNPP POWER_SHELL - PAIN Processor & Migration Comptes](#projet-2--bnpp-power_shell---pain-processor--migration-comptes)
3. [MIGRATION-EXACC - Migration UTL_FILE vers OCI](#projet-3--migration-exacc---migration-utl_file-vers-oci)
4. [MICRO-ENTREPRISE ALPHA - Labico I.T Consulting](#projet-4--micro-entreprise-alpha---labico-it-consulting)
5. [MICRO-ENTREPRISE KEITA - CFE VTC Uber](#projet-5--micro-entreprise-keita---cfe-vtc-uber)

---

# PROJET 1 : BNPP SQL - Investigation Transaction 2817 EUR

## Statut : ROOT CAUSE IDENTIFIÉE ET DOCUMENTÉE

## Emplacement : `BNNP_SQL/`

### Résumé
La transaction **2817 EUR** (PAYMENT_REF: 55841990, Client: 90141615) du 17/10/2025 n'apparaît PAS individuellement dans **BANKREC.BR_DATA** alors que la transaction **22.36 EUR** (Compte 394) apparaît bien.

### Root Cause Identifiée
**MODE CUMUL ACTIF** (ALL+VO) pour le compte 342 (BBNP83292-EUR) dans la table **TA_RN_CUMUL_MR**.

### Preuve
La transaction 2817 EUR fait partie de **23 transactions VO** cumulées en une seule ligne de **226838.78 EUR** dans BR_DATA.

### Comptes Concernés

| Compte | Num CBS | ID CBS | RIB | Transaction | Cumul |
|--------|---------|--------|-----|-------------|-------|
| 342 | BBNP83292-EUR | 352 | 00016111832 | 2817 EUR | OUI (ALL+VO) |
| 394 | BNPP05492-EUR | 383 | 00010207054 | 22.36 EUR | NON |

### Solution Recommandée
```sql
DELETE FROM TA_RN_CUMUL_MR
WHERE ID_COMPTE_BANCAIRE_SYSTEME = 352
  AND ID_PRODUIT = (SELECT ID_PRODUIT FROM TA_RN_PRODUIT WHERE CODE_PRODUIT = 'ALL')
  AND ID_MODE_REGLEMENT = (SELECT ID_MODE_REGLEMENT FROM TA_RN_MODE_REGLEMENT WHERE CODE_MODE_REGLEMENT = 'VO');
COMMIT;
```

### Fichiers Principaux
- `BNNP_SQL/ROOT_CAUSE_ANALYSIS.md` - Analyse detaillee
- `BNNP_SQL/SOLUTION_OPTIONS.md` - Options de resolution
- `BNNP_SQL/COMMENTAIRE_JIRA_TRANSACTION_2817.txt` - Commentaire pour JIRA
- `BNNP_SQL/TRANSACTIONS_CUMUL_17102025.csv` - Liste des 23 transactions

### Scripts Diagnostic Rapide (NOUVEAUX)
| Script | Usage |
|--------|-------|
| `BNNP_SQL/DIAGNOSTIC_RAPIDE.sql` | Diagnostic par RIB - detecte si CUMUL actif |
| `BNNP_SQL/LISTE_COMPTES_AVEC_CUMUL.sql` | Liste tous les comptes avec colonne [CUMUL]/[DETAIL] + scripts suppression/rollback |

### Probleme Type : Transaction absente de BR_DATA
```
SYMPTOME: Transaction X n'apparait pas dans BR_DATA
CAUSE: Regle CUMUL dans TA_RN_CUMUL_MR

DIAGNOSTIC:
1. SELECT ID_COMPTE_BANCAIRE_SYSTEME FROM TA_RN_COMPTE_BANCAIRE_SYSTEME WHERE RIBIDENTIFICATION = '<RIB>';
2. SELECT * FROM TA_RN_CUMUL_MR WHERE ID_COMPTE_BANCAIRE_SYSTEME = <ID_CBS>;
   - Si resultat = [CUMUL] -> transactions agregees
   - Si resultat = vide    -> [DETAIL] -> transactions individuelles

SOLUTION: DELETE FROM TA_RN_CUMUL_MR WHERE ID_COMPTE_BANCAIRE_SYSTEME = <ID_CBS>;
```

### Pour reprendre ce contexte
> "On continue sur l'investigation de la transaction 2817 EUR"
> "Transaction manquante dans BR_DATA" (nouveau probleme similaire)

---

# PROJET 2 : BNPP POWER_SHELL - PAIN Processor & Migration Comptes

## Statut : SCRIPTS OPÉRATIONNELS

## Emplacement : `BNNP_POWER_SHELL/`

### Résumé
Scripts PowerShell pour le traitement automatique des fichiers **PAIN.001** (virements) et **PAIN.008** (prélèvements), ainsi que des scripts SQL pour la migration de comptes BNPP.

### Scripts PAIN Processor

| Script | Description |
|--------|-------------|
| `PAIN-Auto-Processor.ps1` | Version de base - Traitement PAIN.001/008 |
| `PAIN-Auto-Processor-Progress.ps1` | Version avec barre de progression |
| `PAIN-Auto-Processor-Optimized.ps1` | Version optimisée pour performance |

### Fonctionnalités PAIN Processor
- **Détection automatique** du namespace (PAIN.001 ou PAIN.008)
- **Recherche automatique** du fichier XML dans le dossier ticket
- **Export CSV** par bloc PmtInf (Payment Information)
- **Support** : PAIN.001 (CstmrCdtTrfInitn) et PAIN.008 (CstmrDrctDbtInitn)

### Types PAIN Supportés
| Type | Namespace | Noeud Racine | Tag Transaction |
|------|-----------|--------------|-----------------|
| **PAIN.001** | `*pain.001*` | CstmrCdtTrfInitn | CdtTrfTxInf (Virement) |
| **PAIN.008** | `*pain.008*` | CstmrDrctDbtInitn | DrctDbtTxInf (Prélèvement) |

### Répertoire de Base
```
C:\DISQUED\TEMP\PAIN-TRANSFORMER\
├── AER_ITFIN-12345\           ← Dossier ticket
│   ├── pain08_fichier.xml     ← Fichier source
│   └── OUTPUT\                ← Répertoire de sortie
│       └── PMTINF-ID-DD-NbTxs-CtrlSum.csv
```

### Migration Compte BBNP75804

**Ticket JIRA** : BBNP75804

**Migration** : `BBNP75804-EUR-CTL` → `BBNP75804-EUR`

**Étapes SQL** :
1. **DELETE** : Suppression balises du compte CTL
2. **UPDATE** : Bascule compte Gestion vers EUR
3. **INSERT** : Ajout balises Gestion (modèle BBNP40692-EUR)

### Fichiers Principaux
- `PAIN-Auto-Processor.ps1` - Script principal
- `JIRA-Comment-BBNP75804.txt` - Commentaire JIRA formaté
- `JIRA-Timeline-BBNP75804.html` - Timeline HTML

### Pour reprendre ce contexte
> "On parle des scripts PAIN PowerShell" ou "On parle de la migration BBNP75804"

---

# PROJET 3 : MIGRATION-EXACC - Migration UTL_FILE vers OCI

## Statut : AUDIT TERMINÉ - REMÉDIATION PRÊTE

## Emplacement : `MIGRATION-EXACC/`

## Index Principal : `index.html` (à la racine pour GitHub Pages)

**Note** : Le fichier `MIGRATION-EXACC/index.html` a été supprimé (commit 6f0aeb0) car doublon. L'index est maintenant à la racine.

### Résumé
Migration de l'application **PARNA (08449-parna-p1)** vers **ExaCC (Exadata Cloud at Customer)**.
Remplacement de **UTL_FILE** (accès fichiers locaux) par **DBMS_CLOUD + Object Storage OCI**.

### Résultats de l'Audit
- **6 directories Oracle** à migrer (DIR_ARCH_RNA, DIR_IN_RNA, DIR_LOG_RNA, DIR_OUT_RNA, DIR_TEMP_RNA, IN_APPLI_DIR)
- **11 packages PL/SQL** impactés
- **111 occurrences UTL_FILE** identifiées
- **100% couvert** par le wrapper UTL_FILE_WRAPPER

### Packages Critiques
| Package | Priorité | Nb lignes UTL_FILE |
|---------|----------|-------------------|
| PKG_TEC_FICHIERS | CRITIQUE | 61 |
| PKG_DTC | IMPORTANT | 21 |
| PKG_LOG | IMPORTANT | 14 |

### Stratégie
1. Créer un package **UTL_FILE_WRAPPER** qui intercepte tous les appels UTL_FILE
2. Créer un synonyme `UTL_FILE → UTL_FILE_WRAPPER`
3. Le wrapper redirige vers **DBMS_CLOUD + Object Storage OCI**
4. **Zéro modification** du code applicatif

### Fichiers Principaux
- `MIGRATION-EXACC/SYNTHESE_AUDIT_REMEDIATION.md` - Plan de remédiation
- `MIGRATION-EXACC/EMAIL_DEMANDE_OCI.txt` - Email pour l'équipe OCI
- `MIGRATION-EXACC/SCRIPT_MAPPING_DIRECTORIES.sql` - Script SQL pour les mappings
- `MIGRATION-EXACC/migration-utl-file-exacc.html` - Guide complet avec code du wrapper
- `index.html` - Interface web principale (GitHub Pages)
- `BNNP_SQL/EXACC_ANALYSE_UTL_FILE_PARNA.md` - **NOUVEAU** Analyse detaillee PKG_TEC_FICHIERS et flux fichiers

### Analyse PKG_TEC_FICHIERS (23/02/2026)

**Flux identifie** :
```
PR_RN_IMPORT_COMPTA
  → F_ECRIRECSV_CLOB_SILENTLY('OUT_APPLI')
    → F_GET_DIR traduit 'OUT_APPLI' en 'DIR_OUT_RNA'
      → UTL_FILE.FOPEN(DIR_OUT_RNA)
        → /applis/08449-parna-p1/out/ExtraitComptaGene.txt
```

**Point cle** : `'OUT_APPLI'` n'est PAS un DIRECTORY Oracle mais un nom logique traduit par F_GET_DIR.

### Pour reprendre ce contexte
> "On continue sur la migration ExaCC / UTL_FILE"
> "On parle de l'analyse PKG_TEC_FICHIERS"

---

# PROJET 4 : MICRO-ENTREPRISE ALPHA - Labico I.T Consulting

## Statut : ENTREPRISE CRÉÉE - MISSION EN COURS

## Emplacement : `C:\Users\diall\Documents\MICRO-ENTREPRISE\ALPHA\`

## INSTRUCTION OBLIGATOIRE

**TOUJOURS lire et analyser le fichier suivant AVANT de répondre sur ce contexte :**
```
C:\Users\diall\Documents\MICRO-ENTREPRISE\ALPHA\AUTO-ENTREPRISE\plan-action.html
```
Ce fichier contient le plan d'action à jour avec les tâches, échéances et statuts.

### Identité Entrepreneur
| Information | Valeur |
|-------------|--------|
| **Nom complet** | Mamadou Alpha DIALLO |
| **Date naissance** | 13/10/1990 |
| **Nationalité** | Française |
| **N° Sécurité Sociale** | 190109934115802 |

### Entreprise
| Information | Valeur |
|-------------|--------|
| **Raison sociale** | Labico I.T Consulting |
| **Forme juridique** | Micro-entreprise (EI) |
| **SIREN** | 993257393 |
| **SIRET** | 99325739300013 |
| **Code APE** | 6202Z (Conseil en systèmes et logiciels informatiques) |
| **Date création** | 29 octobre 2025 |
| **Adresse** | 206 Rue de Séville, Bâtiment B, 77550 MOISSY-CRAMAYEL |
| **Email** | diallo.labico@hotmail.fr |
| **Téléphone** | +33 6 20 95 16 45 |

### Mission en Cours
| Information | Valeur |
|-------------|--------|
| **Client** | EXTIA |
| **TJM** | 540€ |
| **Date début** | 17 novembre 2025 |
| **CA estimé (7.5 mois)** | 81,216€ |
| **NET estimé** | 68,785€ |

### Régime Fiscal & Social
- **Régime** : Micro-BNC
- **Versement libératoire** : OUI (2,2%)
- **ACRE** : Approuvée (taux 10,65% jusqu'au 30/09/2026)
- **TVA** : Franchise jusqu'à ~avril 2026, puis assujetti

### Calculs Mensuels (20 jours)
```
CA Brut               : 10,800€
- Cotisations ACRE    : -1,150€ (10.65%)
- Versement libératoire: -238€ (2.2%)
= NET dans ta poche   : ~9,146€/mois
```

### Points d'Attention TVA
- **Seuil franchise** : 37,500€
- **Dépassement prévu** : ~16 avril 2026
- **Action** : Facturer AVEC TVA 20% après dépassement

### Fichiers Principaux
- `AUTO-ENTREPRISE/INFOS_OFFICIELLES.md` - Toutes les infos officielles
- `AUTO-ENTREPRISE/CHECKLIST_URGENTE_DECEMBRE_2025.md` - Actions urgentes
- `EXTIA/` - Documents mission EXTIA

### Pour reprendre ce contexte
> "On parle de ma micro-entreprise Alpha / Labico"

---

# PROJET 5 : MICRO-ENTREPRISE KEITA - CFE VTC Uber

## Statut : CFE EN PRÉPARATION

## Emplacement : `C:\Users\diall\Documents\MICRO-ENTREPRISE\KEITA\`

### Résumé
Aide à Mohamed KEITA pour remplir le **formulaire CFE (Cotisation Foncière des Entreprises)** pour son activité de **chauffeur VTC Uber**.

### Fichiers Créés
| Fichier | Description |
|---------|-------------|
| `CFE_1447-C-SD_PREPARATION_COMPLETE.md` | Préparation complète du formulaire |
| `GUIDE_CFE_CHAUFFEURS_VTC_UBER.md` | Guide spécifique VTC/Uber |
| `CFE_KEITA_Mohamed_VTC.md` | Infos personnalisées Mohamed |
| `CFE-MKEITA.pdf` | Formulaire CFE rempli |

### Informations VTC
- **Activité** : Chauffeur VTC (Uber)
- **Code APE** : 4932Z (Transport de voyageurs par taxis)
- **CFE** : Obligatoire pour les VTC à partir de la 2ème année

### Pour reprendre ce contexte
> "On parle du CFE de Keita / VTC Uber"

---

# COMMANDES POUR CHANGER DE CONTEXTE

| Projet | Commande |
|--------|----------|
| BNPP SQL | "On continue sur la transaction 2817 EUR" |
| BNPP PowerShell | "On parle des scripts PAIN PowerShell" |
| Migration ExaCC | "On continue sur la migration ExaCC" |
| Micro-entreprise Alpha | "On parle de ma micro-entreprise Alpha" |
| CFE Keita | "On parle du CFE de Keita" |

---

# NOTES IMPORTANTES

## Connexions Oracle
```bash
sqlplus RNAPPL/****@P08449A  # Production PARNA
```

## Dossiers Clés
```
BNNP_SQL/                    → Scripts SQL BNPP + Investigation 2817
BNNP_POWER_SHELL/            → Scripts PowerShell PAIN + Migration comptes
MIGRATION-EXACC/             → Migration UTL_FILE vers OCI
index.html                   → Interface web principale (GitHub Pages)
C:\Users\diall\Documents\MICRO-ENTREPRISE\ALPHA\  → Labico I.T Consulting
C:\Users\diall\Documents\MICRO-ENTREPRISE\KEITA\  → CFE VTC Uber
```

## Derniers Commits Git
```
d4a0977 Ajout 3 DB Links dans Remédiation PARNA (PROD/RECETTE/DEV)
6f0aeb0 Suppression doublon MIGRATION-EXACC/index.html
7192361 Ajout onglet Remédiation PARNA dans index.html racine
455732f Ajout onglet Remédiation PARNA avec scripts DB Link P08449A
430ba56 Amélioration script audit UTL_FILE - toutes fonctions avec directory
```

---

# RÈGLES DE DÉVELOPPEMENT

## Versionnement index.html

**À chaque commit modifiant index.html**, incrémenter le numéro de version dans l'onglet Scripts :

```html
<li><a href="#scripts" onclick="showTab('scripts', this)">📜 Scripts <small style="opacity:0.7">vX.Y.Z</small></a></li>
```

| Format | Usage |
|--------|-------|
| **X** (majeur) | Changement majeur de fonctionnalité |
| **Y** (mineur) | Nouvelle fonctionnalité |
| **Z** (patch) | Correction bug, amélioration mineure |

**Version actuelle : v1.0.7**

---

**Ce fichier sera lu automatiquement au début de chaque conversation pour retrouver le contexte.**
