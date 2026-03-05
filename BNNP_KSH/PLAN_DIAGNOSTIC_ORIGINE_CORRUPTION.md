# PLAN DIAGNOSTIC - Origine des octets parasites GPG

**Date** : 19/02/2026
**Fichier concerne** : `ExtraitComptaGene_B1814331_RNA_RNACPT22.xml`
**Probleme** : 2 octets parasites `10 00` au debut du fichier

---

## OBJECTIF

Determiner a quel moment les 2 octets parasites `10 00` sont ajoutes :
- **Hypothese A** : Pendant le chiffrement (cote emetteur)
- **Hypothese B** : Pendant le transfert CFT

---

## ETAPE 1 : Demander informations a l'emetteur

### Email/Message a envoyer

```
Bonjour,

Nous rencontrons un probleme de dechiffrement sur le fichier :
ExtraitComptaGene_B1814331_RNA_RNACPT22.xml

Pour diagnostic, pourriez-vous executer ces commandes sur le fichier
AVANT envoi et nous communiquer les resultats ?

1. Checksum MD5 :
   md5sum ExtraitComptaGene_B1814331_RNA_RNACPT22.xml

2. Checksum SHA256 :
   sha256sum ExtraitComptaGene_B1814331_RNA_RNACPT22.xml

3. Premiers octets hexadecimaux :
   xxd ExtraitComptaGene_B1814331_RNA_RNACPT22.xml | head -2

4. Taille du fichier :
   ls -l ExtraitComptaGene_B1814331_RNA_RNACPT22.xml

Merci de nous renvoyer egalement le fichier par un canal alternatif
(SFTP manuel, email securise, etc.) pour comparaison.

Cordialement,
```

### Resultats attendus cote emetteur

| Information | Valeur attendue (fichier sain) |
|-------------|-------------------------------|
| Premier octet | `85` (en-tete GPG standard) |
| Premiers octets hex | `85 01 0c 03 5b b4 58 a8...` |
| Taille | A comparer avec fichier recu |

---

## ETAPE 2 : Recevoir le fichier par canal alternatif

### Options de transfert manuel

| Methode | Commande |
|---------|----------|
| SFTP | `sftp user@serveur_emetteur` puis `get fichier.xml` |
| SCP | `scp user@serveur_emetteur:/chemin/fichier.xml .` |
| Email securise | Piece jointe (si taille < limite) |

### Stockage sur ton serveur

```bash
# Creer un dossier pour le test
mkdir -p /applis/04688-parna-p1/temp/TEST_MANUEL

# Placer le fichier recu manuellement dans ce dossier
cd /applis/04688-parna-p1/temp/TEST_MANUEL
```

---

## ETAPE 3 : Comparer les fichiers

### 3.1 Comparer les checksums

```bash
# Sur le fichier recu par CFT (original)
cd /applis/04688-parna-p1/temp
md5sum ExtraitComptaGene_B1814331_RNA_RNACPT22.xml
sha256sum ExtraitComptaGene_B1814331_RNA_RNACPT22.xml

# Sur le fichier recu manuellement
cd /applis/04688-parna-p1/temp/TEST_MANUEL
md5sum ExtraitComptaGene_B1814331_RNA_RNACPT22.xml
sha256sum ExtraitComptaGene_B1814331_RNA_RNACPT22.xml
```

### 3.2 Comparer les premiers octets

```bash
# Fichier CFT
echo "=== FICHIER CFT ==="
xxd /applis/04688-parna-p1/temp/ExtraitComptaGene_B1814331_RNA_RNACPT22.xml | head -2

# Fichier manuel
echo "=== FICHIER MANUEL ==="
xxd /applis/04688-parna-p1/temp/TEST_MANUEL/ExtraitComptaGene_B1814331_RNA_RNACPT22.xml | head -2
```

### 3.3 Comparer les tailles

```bash
ls -l /applis/04688-parna-p1/temp/ExtraitComptaGene_B1814331_RNA_RNACPT22.xml
ls -l /applis/04688-parna-p1/temp/TEST_MANUEL/ExtraitComptaGene_B1814331_RNA_RNACPT22.xml
```

---

## ETAPE 4 : Tester le dechiffrement du fichier manuel

```bash
cd /applis/04688-parna-p1/temp/TEST_MANUEL
FICHIER="ExtraitComptaGene_B1814331_RNA_RNACPT22.xml"

# Test direct (sans skip)
gpg --decrypt "$FICHIER" > test_decrypted.xml 2>&1
echo "Code retour: $?"

# Verifier le resultat
head -5 test_decrypted.xml
```

---

## ETAPE 5 : Interpretation des resultats

### Tableau de decision

| Fichier MANUEL | Fichier CFT | Conclusion |
|----------------|-------------|------------|
| Commence par `85...` | Commence par `10 00 85...` | **CFT ajoute les octets** |
| Commence par `10 00 85...` | Commence par `10 00 85...` | **Probleme cote emetteur** |
| Dechiffrement OK | Dechiffrement KO | **CFT corrompt le fichier** |
| Dechiffrement KO | Dechiffrement KO | **Fichier corrompu a la source** |

### Scenarios possibles

```
SCENARIO A : CFT est coupable
+------------------+     +------------------+     +------------------+
|   EMETTEUR       |     |      CFT         |     |   TON SERVEUR    |
|   85 01 0c 03... | --> | Ajoute 10 00     | --> | 10 00 85 01 0c...|
|   (fichier OK)   |     | (transformation) |     | (fichier KO)     |
+------------------+     +------------------+     +------------------+

ACTION : Contacter equipe CFT pour verifier configuration transfert


SCENARIO B : Emetteur est coupable
+------------------+     +------------------+     +------------------+
|   EMETTEUR       |     |      CFT         |     |   TON SERVEUR    |
| 10 00 85 01 0c...| --> | Transfert OK     | --> | 10 00 85 01 0c...|
|   (fichier KO)   |     | (pas de modif)   |     | (fichier KO)     |
+------------------+     +------------------+     +------------------+

ACTION : Contacter emetteur pour corriger son processus de chiffrement
```

---

## ETAPE 6 : Actions correctives

### Si CFT est coupable

1. Verifier la configuration du flux CFT
2. Chercher un parametre de "record length" ou "prefix"
3. Verifier le mode de transfert (binaire vs texte)
4. Contacter l'equipe CFT avec les preuves

### Si l'emetteur est coupable

1. Partager le diagnostic avec l'emetteur
2. Demander verification de leur processus GPG
3. Suggerer de tester avec : `gpg --list-packets fichier.xml`
4. Demander correction et renvoi

---

## CHECKLIST RAPIDE

- [ ] Email envoye a l'emetteur avec demandes (md5, xxd, taille)
- [ ] Reponse recue avec les informations
- [ ] Fichier recu par canal alternatif (SFTP/SCP)
- [ ] Checksums compares (CFT vs Manuel vs Emetteur)
- [ ] Premiers octets compares (xxd)
- [ ] Test dechiffrement fichier manuel
- [ ] Conclusion tiree
- [ ] Action corrective engagee

---

## HISTORIQUE

| Date | Action | Resultat |
|------|--------|----------|
| 19/02/2026 | Diagnostic initial | 2 octets `10 00` detectes |
| 19/02/2026 | Plan de diagnostic cree | En attente execution |
| | | |

---

**Fichier cree le 19/02/2026**
