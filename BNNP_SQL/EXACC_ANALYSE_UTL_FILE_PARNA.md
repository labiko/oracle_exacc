# Analyse UTL_FILE pour Migration ExaCC - PARNA

**Date** : 23/02/2026
**Application** : 08449-parna-p1 (PARNA)

---

## 1. Flux de Création de Fichiers Identifié

```
PR_RN_IMPORT_COMPTA (RNADGENEXPCPT01.sql)
  │
  ├─► Etape 1: Lecture TX_COMPTA_GENE (table externe)
  ├─► Etape 2: INSERT INTO TA_RN_IMPORT_COMPTA
  ├─► Etape 3: INSERT INTO TA_RN_EXPORT
  ├─► Etape 4: Génération TW_EXPORT_COMPTA_GENE
  │
  └─► Etape 5: PKG_TEC_FICHIERS.F_ECRIRECSV_CLOB_SILENTLY
                    │
                    ├─► Stockage CLOB dans TA_CLOB (base de données)
                    │
                    └─► F_GET_DIR('OUT_APPLI')
                          │
                          └─► Traduit en 'DIR_OUT_RNA'
                                │
                                └─► UTL_FILE.FOPEN('DIR_OUT_RNA', filename)
                                      │
                                      └─► /applis/08449-parna-p1/out/ExtraitComptaGene.txt.*
```

---

## 2. Fonction F_GET_DIR - Traduction des Noms Logiques

La fonction `F_GET_DIR` dans `PKG_TEC_FICHIERS` traduit les noms logiques :

| Nom Logique | Code Appli | Directory Oracle | Chemin Physique |
|-------------|------------|------------------|-----------------|
| `OUT_APPLI` | RNA | `DIR_OUT_RNA` | `/applis/08449-parna-p1/out` |
| `IN_APPLI` | RNA | `DIR_IN_RNA` | `/applis/08449-parna-p1/in` |
| `TEMP_APPLI` | RNA | `DIR_TEMP_RNA` | `/applis/08449-parna-p1/temp` |
| `LOG_APPLI` | RNA | `DIR_LOG_RNA` | `/applis/logs/08449-parna-p1` |
| `ARCH_APPLI` | RNA | `DIR_ARCH_RNA` | `/applis/08449-parna-p1/archive` |

**Logique de traduction** :
```plsql
-- Extrait le code appli depuis t_InfoTrait (ex: 'RNA')
s_CodeAppli := PKG_TEC_GLOBAL.s_CODE_APPLI;  -- 'RNA'

-- Construit le nom du DIRECTORY Oracle
CASE s_Dir
  WHEN 'OUT_APPLI'  THEN s_DirComplet := 'DIR_OUT_'  || s_CodeAppli;  -- DIR_OUT_RNA
  WHEN 'IN_APPLI'   THEN s_DirComplet := 'DIR_IN_'   || s_CodeAppli;  -- DIR_IN_RNA
  WHEN 'TEMP_APPLI' THEN s_DirComplet := 'DIR_TEMP_' || s_CodeAppli;  -- DIR_TEMP_RNA
  WHEN 'LOG_APPLI'  THEN s_DirComplet := 'DIR_LOG_'  || s_CodeAppli;  -- DIR_LOG_RNA
  WHEN 'ARCH_APPLI' THEN s_DirComplet := 'DIR_ARCH_' || s_CodeAppli;  -- DIR_ARCH_RNA
END CASE;
```

---

## 3. Double Stockage (Important pour Migration)

Le fichier est stocké en **double** :

1. **Dans la base** : Table `TA_CLOB` (CLOB)
2. **Sur le filesystem** : Via `UTL_FILE.PUT_LINE` dans le DIRECTORY Oracle

Pour ExaCC, seul le stockage UTL_FILE doit être migré vers Object Storage.

---

## 4. Directories Oracle PARNA

```sql
-- Query pour vérifier les directories
SELECT directory_name, directory_path
FROM dba_directories
WHERE directory_name LIKE 'DIR_%RNA%'
ORDER BY directory_name;
```

| DIRECTORY_NAME | DIRECTORY_PATH |
|----------------|----------------|
| DIR_ARCH_RNA | /applis/08449-parna-p1/archive |
| DIR_IN_RNA | /applis/08449-parna-p1/in |
| DIR_LOG_RNA | /applis/logs/08449-parna-p1 |
| DIR_OUT_RNA | /applis/08449-parna-p1/out |
| DIR_TEMP_RNA | /applis/08449-parna-p1/temp |
| IN_APPLI_DIR | /applis/08449-parna-p1/in |

---

## 5. Scripts de Mapping pour ExaCC Migration

### 5.1 Création de la Table de Mapping

```sql
-- Table pour mapper DIRECTORY Oracle → Object Storage OCI
CREATE TABLE UTL_FILE_DIRECTORY_MAPPING (
    oracle_directory   VARCHAR2(128) PRIMARY KEY,
    object_storage_uri VARCHAR2(4000) NOT NULL,
    credential_name    VARCHAR2(128) DEFAULT 'OCI_PARNA_CREDENTIAL',
    is_active          NUMBER(1) DEFAULT 1,
    created_date       DATE DEFAULT SYSDATE,
    comments           VARCHAR2(500)
);
```

### 5.2 INSERT des Mappings PARNA

```sql
-- Mappings pour PARNA (à adapter avec les vrais URLs OCI)
INSERT INTO UTL_FILE_DIRECTORY_MAPPING (oracle_directory, object_storage_uri, credential_name, comments)
VALUES ('DIR_OUT_RNA',
        'https://objectstorage.eu-paris-1.oraclecloud.com/n/<namespace>/b/parna-out/o/',
        'OCI_PARNA_CREDENTIAL',
        'Fichiers sortie PARNA - ExtraitComptaGene.txt, etc.');

INSERT INTO UTL_FILE_DIRECTORY_MAPPING (oracle_directory, object_storage_uri, credential_name, comments)
VALUES ('DIR_IN_RNA',
        'https://objectstorage.eu-paris-1.oraclecloud.com/n/<namespace>/b/parna-in/o/',
        'OCI_PARNA_CREDENTIAL',
        'Fichiers entree PARNA');

INSERT INTO UTL_FILE_DIRECTORY_MAPPING (oracle_directory, object_storage_uri, credential_name, comments)
VALUES ('DIR_TEMP_RNA',
        'https://objectstorage.eu-paris-1.oraclecloud.com/n/<namespace>/b/parna-temp/o/',
        'OCI_PARNA_CREDENTIAL',
        'Fichiers temporaires PARNA');

INSERT INTO UTL_FILE_DIRECTORY_MAPPING (oracle_directory, object_storage_uri, credential_name, comments)
VALUES ('DIR_LOG_RNA',
        'https://objectstorage.eu-paris-1.oraclecloud.com/n/<namespace>/b/parna-logs/o/',
        'OCI_PARNA_CREDENTIAL',
        'Logs PARNA');

INSERT INTO UTL_FILE_DIRECTORY_MAPPING (oracle_directory, object_storage_uri, credential_name, comments)
VALUES ('DIR_ARCH_RNA',
        'https://objectstorage.eu-paris-1.oraclecloud.com/n/<namespace>/b/parna-archive/o/',
        'OCI_PARNA_CREDENTIAL',
        'Archives PARNA');

INSERT INTO UTL_FILE_DIRECTORY_MAPPING (oracle_directory, object_storage_uri, credential_name, comments)
VALUES ('IN_APPLI_DIR',
        'https://objectstorage.eu-paris-1.oraclecloud.com/n/<namespace>/b/parna-in/o/',
        'OCI_PARNA_CREDENTIAL',
        'Alias pour DIR_IN_RNA');

COMMIT;
```

### 5.3 Vérification des Mappings

```sql
SELECT oracle_directory,
       SUBSTR(object_storage_uri, 1, 60) AS uri_preview,
       credential_name,
       CASE is_active WHEN 1 THEN 'ACTIF' ELSE 'INACTIF' END AS statut
FROM UTL_FILE_DIRECTORY_MAPPING
ORDER BY oracle_directory;
```

---

## 6. Impact sur le Code Applicatif

### Aucune modification requise !

Grâce à la stratégie **UTL_FILE_WRAPPER** :

1. Le package `UTL_FILE_WRAPPER` intercepte tous les appels UTL_FILE
2. Un synonyme `CREATE PUBLIC SYNONYM UTL_FILE FOR UTL_FILE_WRAPPER` redirige les appels
3. Le wrapper consulte `UTL_FILE_DIRECTORY_MAPPING` et utilise `DBMS_CLOUD`
4. Le code applicatif (`PKG_TEC_FICHIERS`, `PR_RN_IMPORT_COMPTA`, etc.) reste **inchangé**

---

## 7. Packages Impactés (pour information)

| Package | Nb appels UTL_FILE | Priorité |
|---------|-------------------|----------|
| PKG_TEC_FICHIERS | 61 | CRITIQUE |
| PKG_DTC | 21 | IMPORTANT |
| PKG_LOG | 14 | IMPORTANT |

---

## 8. Prochaines Etapes

1. [ ] Obtenir les URLs Object Storage OCI de l'équipe infrastructure
2. [ ] Créer le credential OCI : `DBMS_CLOUD.CREATE_CREDENTIAL`
3. [ ] Créer la table `UTL_FILE_DIRECTORY_MAPPING`
4. [ ] Insérer les mappings avec les vrais URLs
5. [ ] Déployer `UTL_FILE_WRAPPER` sur ExaCC
6. [ ] Tester avec un fichier de sortie (ExtraitComptaGene.txt)
7. [ ] Valider les lectures/écritures Object Storage

---

## Références

- Documentation principale : [index.html](../index.html) (GitHub Pages)
- Package wrapper : [migration-utl-file-exacc.html](../MIGRATION-EXACC/migration-utl-file-exacc.html)
- Synthèse audit : [SYNTHESE_AUDIT_REMEDIATION.md](../MIGRATION-EXACC/SYNTHESE_AUDIT_REMEDIATION.md)
