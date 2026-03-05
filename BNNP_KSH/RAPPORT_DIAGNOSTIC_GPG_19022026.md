# RAPPORT DIAGNOSTIC GPG

**Date du diagnostic** : 19/02/2026 11:22
**Serveur** : s01vl9976318
**Utilisateur** : aparnap1
**Dossier** : /applis/04688-parna-p1/temp

---

## 1. FICHIER ANALYSE

| Propriete | Valeur |
|-----------|--------|
| **Nom** | `ExtraitComptaGene_B1814331_RNA_RNACPT22.xml` |
| **Taille** | 4.3 MB (4 506 314 octets) |
| **Date creation** | 18/02/2026 14:33 |
| **Proprietaire** | cft:cft |
| **Permissions** | -rw-r--r-- |
| **Type detecte** | `data` (binaire non reconnu) |

---

## 2. PROBLEME IDENTIFIE

### 2.1 Symptome
```
gpg: no valid OpenPGP data found
gpg: decrypt_message failed: Unknown system error
```

### 2.2 Cause racine
**2 octets parasites** (`10 00`) au debut du fichier empechent GPG de reconnaitre le format OpenPGP.

### 2.3 Analyse hexadecimale

```
Position   Hex                                       ASCII
00000000:  1000 8501 0c03 5bb4 58a8 d191 8d5b 0108  ......[.X....[..
           ││││ │
           ││││ └── En-tete GPG valide (0x85)
           └┴┴┴──── OCTETS PARASITES (10 00)
```

| Position | Octets | Signification |
|----------|--------|---------------|
| 0-1 | `10 00` | **ANOMALIE** - Ne devrait pas etre la |
| 2 | `85` | En-tete GPG standard (packet tag) |
| 3-5 | `01 0c 03` | Longueur du paquet |
| 6-13 | `5b b4 58 a8 d1 91 8d 5b` | **Key ID** = `5BB458A8D1918D5B` |

### 2.4 Comparaison fichier corrompu vs normal

```
FICHIER RECU (corrompu) :
+--------+------------------------------------------+
| 10 00  | 85 01 0c 03 5b b4 58 a8 ... donnees GPG  |
| ERREUR | <-- Donnees GPG valides commencent ICI   |
+--------+------------------------------------------+

FICHIER NORMAL (attendu) :
+--------------------------------------------------+
| 85 01 0c 03 5b b4 58 a8 ... donnees GPG          |
+--------------------------------------------------+
  ^
  GPG reconnait immediatement le format OpenPGP
```

---

## 3. CLES GPG DISPONIBLES

### 3.1 Cles publiques valides

| Key ID | CN | Expiration | Statut |
|--------|-----|------------|--------|
| `606C95CE5EA9E78D` | PARVA2410960-PROD-SAFIR-CFT | 2027-11-27 | OK |
| `8C06CB5581203AED` | S01VL9976318-PROD-GPG-CFT | 2027-11-27 | OK |
| `1E683AE96D8AF35B` | S02VL9906742_PROD_CFT_ICE | 2027-11-13 | OK |
| `D4E009A22F34438F` | AP06609-GPG-CFT | 2027-12-17 | OK |

### 3.2 Cles secretes disponibles

| Key ID (principale) | Sous-cle chiffrement | Expiration |
|---------------------|---------------------|------------|
| `8C06CB5581203AED` | **`5BB458A8D1918D5B`** | 2027-11-27 |

### 3.3 Cle utilisee pour chiffrer le fichier

```
Key ID trouvee dans le fichier : 5BB458A8D1918D5B
Cle secrete correspondante    : DISPONIBLE
Statut                        : OK - Dechiffrement possible
```

---

## 4. TESTS EFFECTUES

### 4.1 Test avec differents offsets (skip)

| Skip | Resultat |
|------|----------|
| 0 | `no valid OpenPGP data found` |
| 1 | `no valid OpenPGP data found` |
| **2** | **SUCCES** - Fichier reconnu comme GPG |
| 3 | `no valid OpenPGP data found` |
| 4 | `no valid OpenPGP data found` |
| 5 | `no valid OpenPGP data found` |

### 4.2 Resultat avec skip=2

```
gpg: encrypted with 2048-bit RSA key, ID 5BB458A8D1918D5B, created 2025-11-27
      "CN=S01VL9976318-PROD-GPG-CFT, OU=Applications, O=Group"
```

---

## 5. SOLUTION

### 5.1 Commande de dechiffrement

```bash
dd if=ExtraitComptaGene_B1814331_RNA_RNACPT22.xml bs=1 skip=2 | gpg --decrypt > ExtraitComptaGene_B1814331_DECRYPTED.xml
```

### 5.2 Verification apres dechiffrement

```bash
# Verifier que le fichier est un XML valide
head -10 ExtraitComptaGene_B1814331_DECRYPTED.xml

# Verifier la taille
ls -lh ExtraitComptaGene_B1814331_DECRYPTED.xml
```

### 5.3 Resultats possibles

| Resultat | Signification | Action |
|----------|---------------|--------|
| Fichier XML valide | Dechiffrement reussi | Traiter le fichier |
| `zlib inflate problem` | Fichier corrompu en interne | Demander renvoi a l'emetteur |
| `No secret key` | Cle manquante | Importer la cle privee |

---

## 6. HISTORIQUE DES FICHIERS AVEC CE PROBLEME

| Date | Fichier | Probleme | Resolution |
|------|---------|----------|------------|
| 16/02/2026 | `ExtraitComptaGene_B1404071_RNA_RNACPT22.xml` | 2 octets parasites + zlib corrupt | Renvoi demande |
| 19/02/2026 | `ExtraitComptaGene_B1814331_RNA_RNACPT22.xml` | 2 octets parasites | A tester |

---

## 7. CAUSE PROBABLE

Les 2 octets parasites `10 00` au debut du fichier sont probablement ajoutes par :
1. **Le systeme de transfert CFT** (CFT = Cross File Transfer)
2. **Une conversion de format** lors du transfert
3. **Un bug dans le processus de chiffrement** cote emetteur

### Recommandation
Contacter l'equipe qui envoie les fichiers pour verifier leur processus de chiffrement/transfert.

---

## 8. RESUME EXECUTIF

```
+------------------------------------------------------------------+
|                    DIAGNOSTIC GPG - RESUME                        |
+------------------------------------------------------------------+
| Fichier        : ExtraitComptaGene_B1814331_RNA_RNACPT22.xml     |
| Taille         : 4.3 MB                                           |
| Date           : 18/02/2026 14:33                                 |
+------------------------------------------------------------------+
| PROBLEME       : 2 octets parasites (10 00) au debut              |
| SOLUTION       : dd skip=2 | gpg --decrypt                        |
| CLE GPG        : 5BB458A8D1918D5B (disponible, valide)            |
+------------------------------------------------------------------+
| STATUT         : REPARABLE (si pas de corruption interne)         |
+------------------------------------------------------------------+
```

---

**Rapport genere le 19/02/2026**
**Script de diagnostic** : `diagnostic_gpg_complet.ksh`
