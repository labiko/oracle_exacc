# BNNP_KSH - Scripts KSH pour diagnostic et correction GPG

**Date de creation** : 19/02/2026

---

## Scripts disponibles

| Script | Description | Usage |
|--------|-------------|-------|
| `diagnostic_gpg.ksh` | Diagnostic complet d'un fichier GPG | `./diagnostic_gpg.ksh <fichier>` |
| `fix_gpg_prefix.ksh` | Suppression manuelle d'octets parasites | `./fix_gpg_prefix.ksh <fichier> <nb_octets>` |
| `gpg_auto_fix.ksh` | Reparation automatique (essaie skip 0-10) | `./gpg_auto_fix.ksh <fichier>` |

---

## 1. diagnostic_gpg.ksh

**Objectif** : Analyser un fichier GPG pour determiner :
- Si la cle de dechiffrement est disponible
- Si le fichier est corrompu (octets parasites)
- Quel Key ID a ete utilise pour le chiffrement

**Etapes du diagnostic** :
1. Liste des cles GPG disponibles
2. Analyse hexadecimale des premiers octets
3. Lecture des packets GPG
4. Test de dechiffrement
5. Test avec differents offsets (skip)
6. Verification de la fin du fichier

**Exemple** :
```bash
./diagnostic_gpg.ksh ExtraitComptaGene_B1404071_RNA_RNACPT22.xml
```

---

## 2. fix_gpg_prefix.ksh

**Objectif** : Supprimer les N premiers octets d'un fichier GPG corrompu

**Utilisation** :
```bash
# Supprimer les 2 premiers octets (cas le plus frequent)
./fix_gpg_prefix.ksh ExtraitComptaGene.xml 2
```

**Fichiers generes** :
- `<nom>_FIXED.gpg` : Fichier corrige
- `<nom>_DECRYPTED.xml` : Fichier dechiffre (si succes)

---

## 3. gpg_auto_fix.ksh

**Objectif** : Tenter automatiquement plusieurs offsets (0 a 10) pour trouver la correction

**Utilisation** :
```bash
./gpg_auto_fix.ksh ExtraitComptaGene_B1404071_RNA_RNACPT22.xml
```

---

## Probleme type : Octets parasites au debut

### Symptome
```
gpg: no valid OpenPGP data found
```

### Diagnostic
```bash
xxd fichier.gpg | head -2
# Resultat avec octets parasites :
# 00000000: 1000 8501 0c03 5bb4 58a8...
#           ^^^^
#           Ces 2 octets ne devraient pas etre la
```

### Solution
```bash
# Methode 1 : Script auto-fix
./gpg_auto_fix.ksh fichier.gpg

# Methode 2 : Commande directe
dd if=fichier.gpg bs=1 skip=2 | gpg --decrypt > output.xml
```

---

## Probleme type : Cle inconnue

### Symptome
```
gpg: decryption failed: No secret key
```

### Diagnostic
```bash
# Voir le Key ID requis
gpg --list-packets fichier.gpg

# Voir les cles disponibles
gpg --list-secret-keys --keyid-format long
```

### Solution
```bash
# Importer la cle privee
gpg --import cle_privee.asc
```

---

## Probleme type : Fichier tronque/corrompu

### Symptome
```
gpg: Fatal: zlib inflate problem: invalid stored block lengths
```

### Cause
Le fichier a ete tronque ou corrompu pendant le transfert.

### Solution
**Demander le renvoi du fichier a l'emetteur.**

---

## Commandes utiles

```bash
# Voir les cles disponibles
gpg --list-keys

# Voir les cles secretes
gpg --list-secret-keys

# Analyser un fichier GPG
gpg --list-packets fichier.gpg

# Dechiffrer un fichier
gpg --decrypt fichier.gpg > sortie.xml

# Verifier l'en-tete hexadecimal
xxd fichier.gpg | head -4

# Supprimer N octets au debut
dd if=fichier.gpg bs=1 skip=N of=fichier_fixed.gpg
```

---

## Historique

| Date | Evenement |
|------|-----------|
| 16/02/2026 | Probleme `ExtraitComptaGene_B1404071` - 2 octets parasites + corruption zlib |
| 19/02/2026 | Creation des scripts KSH de diagnostic |
