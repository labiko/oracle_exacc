# DIAGNOSTIC GPG - Anomalie Fichier ExtraitComptaGene

**Date d'analyse** : 16/02/2026
**Fichier concerné** : `ExtraitComptaGene_B1404071_RNA_RNACPT22.xml`
**Taille** : 1,987,548 octets

---

## 1. PROBLEME CONSTATE

### Symptome
La commande de déchiffrement GPG échoue :
```bash
gpg --decrypt ExtraitComptaGene_B1404071_RNA_RNACPT22.xml
```

**Erreur retournée** :
```
gpg: no valid OpenPGP data found.
gpg: decrypt_message failed: Unknown system error
```

---

## 2. COMMANDES DE DIAGNOSTIC EXECUTEES

### Commande unique de diagnostic
```bash
echo "=== 1. INFO FICHIER ===" && \
ls -la ExtraitComptaGene_B1404071_RNA_RNACPT22.xml && \
file ExtraitComptaGene_B1404071_RNA_RNACPT22.xml && \
echo "=== 2. CLES SECRETES ===" && \
gpg --list-secret-keys --keyid-format LONG && \
echo "=== 3. CLES PUBLIQUES ===" && \
gpg --list-keys --keyid-format LONG && \
echo "=== 4. ANALYSE PACKETS ===" && \
gpg --list-packets ExtraitComptaGene_B1404071_RNA_RNACPT22.xml 2>&1
```

---

## 3. RESULTATS OBTENUS

### 3.1 Information fichier
```
-rw-r--r-- 1 rnappl cpsprod 1987548 Feb 16 10:04 ExtraitComptaGene_B1404071_RNA_RNACPT22.xml
ExtraitComptaGene_B1404071_RNA_RNACPT22.xml: data
```

**Analyse** : Le fichier est reconnu comme "data" (binaire générique) et NON comme "GPG encrypted data".

### 3.2 Clés secrètes sur le serveur
```
/home/rnappl/.gnupg/pubring.kbx
-------------------------------

sec   rsa2048/C2E15C5C5E6617AE 2023-11-28 [SC] [expired: 2026-01-01]
      BB3CF9F0531E69DD3E8F2208C2E15C5C5E6617AE
uid                 [expired] BNPPF_DG_CPS_A08449 <BNPPF_DG_CPS_A08449@bnpparibasfortis.com>

sec   rsa4096/8C06CB5581203AED 2024-11-27 [SC] [expires: 2027-11-27]
      C06810E1DBB835101A7E4D478C06CB5581203AED
uid                 [ultimate] BNPPF_DG_CPS_A08449 <BNPPF_DG_CPS_A08449@bnpparibasfortis.com>
ssb   rsa4096/5BB458A8D1918D5B 2024-11-27 [E] [expires: 2027-11-27]
```

**Analyse** :
| Clé | ID | Statut | Expiration |
|-----|-----|--------|------------|
| ANCIENNE | C2E15C5C5E6617AE | EXPIREE | 01/01/2026 |
| NOUVELLE | 8C06CB5581203AED | VALIDE | 27/11/2027 |
| Sous-clé (encryption) | **5BB458A8D1918D5B** | VALIDE | 27/11/2027 |

### 3.3 Analyse des packets GPG
```
gpg: no valid OpenPGP data found
```

**Analyse** : GPG ne reconnaît pas le format du fichier comme étant du OpenPGP valide.

### 3.4 Analyse hexadécimale (xxd)
```bash
xxd ExtraitComptaGene_B1404071_RNA_RNACPT22.xml | head -5
```

**Résultat** :
```
00000000: 1000 8501 0c03 5bb4 58a8 d191 8d5b 0107  ......[.X....[..
00000010: ff7a 19c5 0836 8e06 baa9 f27e e0a2 4e96  .z...6.....~..N.
```

### Explication du flux hexadécimal

**Décomposition de la ligne :**
```
00000000: 1000 8501 0c03 5bb4 58a8 d191 8d5b 0107  ......[.X....[..
│         │    │              │                    │
│         │    │              │                    └── Représentation ASCII (les . = non imprimables)
│         │    │              │
│         │    │              └── Key ID GPG : 5BB458A8D1918D5B
│         │    │
│         │    └── En-tête GPG normal (packet tag)
│         │
│         └── 2 OCTETS EN TROP (cause du problème)
│
└── Position dans le fichier (octet 0 = début)
```

**Détail des octets :**

| Position | Octets hex | Signification |
|----------|------------|---------------|
| 0-1 | `10 00` | **ANOMALIE** - Ces 2 octets ne devraient pas être là |
| 2-5 | `85 01 0c 03` | En-tête GPG standard (packet tag) |
| 6-13 | `5b b4 58 a8 d1 91 8d 5b` | **Key ID** = `5BB458A8D1918D5B` (clé valide) |

**Schéma comparatif :**
```
FICHIER REÇU (corrompu) :
┌─────────┬──────────────────────────────────────────┐
│ 10 00   │ 85 01 0c 03 5b b4 58 a8 ... données GPG │
│ ERREUR  │ ← Données GPG valides commencent ICI    │
└─────────┴──────────────────────────────────────────┘
  ↑
  Ces 2 octets empêchent GPG de reconnaître le fichier

FICHIER NORMAL (attendu) :
┌──────────────────────────────────────────────────┐
│ 85 01 0c 03 5b b4 58 a8 ... données GPG         │
└──────────────────────────────────────────────────┘
  ↑
  GPG reconnaît immédiatement le format OpenPGP
```

**Conclusion de l'analyse xxd :**
Le Key ID `5BB458A8D1918D5B` trouvé dans le fichier correspond exactement à la sous-clé de chiffrement valide sur le serveur. Le fichier a donc été chiffré avec la bonne clé, mais il contient 2 octets parasites (`10 00`) au début.

---

## 4. ANALYSE DE L'ANOMALIE

### 4.1 Identification du Key ID dans le fichier

En analysant les octets hexadécimaux :
```
Position 6-13 : 5bb4 58a8 d191 8d5b
```

Cela correspond EXACTEMENT à la **sous-clé de chiffrement valide** :
```
ssb   rsa4096/5BB458A8D1918D5B 2024-11-27 [E] [expires: 2027-11-27]
```

**Conclusion** : Le fichier a bien été chiffré avec la NOUVELLE clé valide.

### 4.2 Problème identifié : En-tête corrompu

Les **2 premiers octets** (`10 00`) ne correspondent pas au format OpenPGP standard :

| Format OpenPGP standard | Fichier actuel |
|------------------------|----------------|
| `85 01 0c 03 ...` | `10 00 85 01 0c 03 ...` |

**Le fichier contient 2 octets supplémentaires au début** qui empêchent GPG de reconnaître le format.

### 4.3 Structure attendue vs Structure actuelle

```
STRUCTURE ATTENDUE (OpenPGP):
┌────────────────────────────────────────────────────────┐
│ 85 01 0c 03 │ 5bb4 58a8 d191 8d5b │ données chiffrées │
│ (packet tag) │ (key ID)           │                   │
└────────────────────────────────────────────────────────┘

STRUCTURE ACTUELLE (fichier corrompu):
┌───────────┬────────────────────────────────────────────────────────┐
│ 10 00     │ 85 01 0c 03 │ 5bb4 58a8 d191 8d5b │ données chiffrées │
│ (PREFIXE) │ (packet tag) │ (key ID)           │                   │
└───────────┴────────────────────────────────────────────────────────┘
     ↑
  2 octets en trop (wrapper/header ajouté)
```

---

## 5. SOLUTION PROPOSEE

### 5.1 Commande de correction

Supprimer les 2 premiers octets avec `dd` puis déchiffrer :

```bash
# Etape 1 : Supprimer les 2 premiers octets
dd if=ExtraitComptaGene_B1404071_RNA_RNACPT22.xml of=fichier_fixed.gpg bs=1 skip=2

# Etape 2 : Vérifier le fichier corrigé
file fichier_fixed.gpg
# Attendu : "GPG encrypted data" ou "PGP RSA encrypted session key"

# Etape 3 : Déchiffrer
gpg --decrypt fichier_fixed.gpg > ExtraitComptaGene_B1404071_RNA_RNACPT22_DECRYPTED.xml
```

### 5.2 Commande en une seule ligne

```bash
dd if=ExtraitComptaGene_B1404071_RNA_RNACPT22.xml bs=1 skip=2 2>/dev/null | gpg --decrypt > output.xml
```

---

## 6. CAUSE PROBABLE DE L'ANOMALIE

L'ajout des 2 octets `10 00` au début du fichier peut provenir de :

1. **Transfert SFTP/FTP mal configuré** : Certains protocoles ajoutent un header
2. **Wrapper applicatif** : Le système émetteur encapsule le fichier GPG
3. **Corruption lors de la copie** : Caractères de contrôle ajoutés
4. **Format propriétaire** : L'émetteur utilise peut-être un format enveloppé

---

## 7. ACTIONS A MENER

| N° | Action | Statut |
|----|--------|--------|
| 1 | Exécuter la commande `dd skip=2` | A FAIRE |
| 2 | Vérifier que le fichier corrigé est reconnu GPG | A FAIRE |
| 3 | Déchiffrer le fichier | A FAIRE |
| 4 | Investiguer l'origine des 2 octets avec l'émetteur | A FAIRE |
| 5 | Automatiser le fix si récurrent | OPTIONNEL |

---

## 8. COMMANDE DE FIX COMPLETE

```bash
# Créer le fichier corrigé et déchiffrer
dd if=ExtraitComptaGene_B1404071_RNA_RNACPT22.xml of=ExtraitComptaGene_FIXED.gpg bs=1 skip=2 && \
echo "=== Vérification du fichier corrigé ===" && \
file ExtraitComptaGene_FIXED.gpg && \
xxd ExtraitComptaGene_FIXED.gpg | head -2 && \
echo "=== Déchiffrement ===" && \
gpg --decrypt ExtraitComptaGene_FIXED.gpg > ExtraitComptaGene_B1404071_RNA_RNACPT22_DECRYPTED.xml && \
echo "=== Résultat ===" && \
ls -la ExtraitComptaGene_B1404071_RNA_RNACPT22_DECRYPTED.xml && \
head -5 ExtraitComptaGene_B1404071_RNA_RNACPT22_DECRYPTED.xml
```

---

## 9. RESULTATS DU FIX (16/02/2026)

### Commande exécutée
```bash
dd if=ExtraitComptaGene_B1404071_RNA_RNACPT22.xml bs=1 skip=2 2>/dev/null | gpg --decrypt > output.xml
```

### Résultat
```
gpg: WARNING: unsafe permissions on homedir '/applis/04688-parna-p1/.gnupg'
gpg: encrypted with 2048-bit RSA key, ID 5BB458A8D1918D5B, created 2025-11-27
      "CN=S01VL9976318-PROD-GPG-CFT, OU=Applications, O=Group"
gpg: Fatal: zlib inflate problem: invalid stored block lengths
```

### Analyse du résultat

| Élément | Statut | Commentaire |
|---------|--------|-------------|
| Reconnaissance clé | ✅ OK | GPG identifie la clé `5BB458A8D1918D5B` |
| Déchiffrement | ❌ ECHEC | Erreur zlib inflate |

### Nouvelle erreur identifiée

**`zlib inflate problem: invalid stored block lengths`**

Cette erreur indique que les **données compressées** à l'intérieur du fichier GPG sont **corrompues ou incomplètes**.

### Causes possibles

1. **Fichier tronqué** : Le transfert s'est interrompu avant la fin
2. **Corruption en transit** : Données altérées pendant le transfert SFTP/FTP
3. **Plus de 2 octets à supprimer** : Le préfixe pourrait être plus long
4. **Corruption du fichier source** : Le fichier a été corrompu avant chiffrement

### Commandes de diagnostic supplémentaires

```bash
# 1. Vérifier la taille du fichier original vs attendu
ls -la ExtraitComptaGene_B1404071_RNA_RNACPT22.xml

# 2. Comparer avec d'autres fichiers similaires (même émetteur)
ls -la ExtraitComptaGene_*.xml

# 3. Vérifier l'intégrité avec différents skip
for skip in 0 1 2 3 4 5 10; do
    echo "=== Skip $skip octets ==="
    dd if=ExtraitComptaGene_B1404071_RNA_RNACPT22.xml bs=1 skip=$skip 2>/dev/null | gpg --list-packets 2>&1 | head -5
done

# 4. Vérifier si le fichier est complet (recherche fin de fichier GPG)
xxd ExtraitComptaGene_B1404071_RNA_RNACPT22.xml | tail -5

# 5. Demander le renvoi du fichier à l'émetteur
```

### Actions recommandées

| Priorité | Action |
|----------|--------|
| 1 | **Demander le renvoi du fichier** à l'émetteur (probable corruption) |
| 2 | Vérifier si d'autres fichiers du même jour ont le même problème |
| 3 | Comparer la taille avec des fichiers similaires précédents |
| 4 | Vérifier les logs de transfert SFTP pour des erreurs |

---

## 10. CONCLUSION PROVISOIRE

Le fichier présente **deux anomalies** :

1. **2 octets en trop au début** (`10 00`) - CORRIGÉ avec `dd skip=2`
2. **Données compressées corrompues** - NON RÉPARABLE

**Recommandation** : Demander le **renvoi du fichier** à l'émetteur car les données internes sont corrompues et ne peuvent pas être récupérées.

---

**Document mis à jour le 16/02/2026**
