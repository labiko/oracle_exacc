# TICKET CFT - Corruption fichiers GPG

**Date** : 19/02/2026
**Priorite** : Haute
**Environnement** : Production

---

## RESUME DU PROBLEME

Les fichiers GPG recus via CFT contiennent **2 octets parasites (`10 00`)** au debut, empechant le dechiffrement.

---

## FICHIERS IMPACTES

| Date | Fichier | Taille | Statut |
|------|---------|--------|--------|
| 16/02/2026 | `ExtraitComptaGene_B1404071_RNA_RNACPT22.xml` | ~4 MB | Corrompu (zlib) |
| 19/02/2026 | `ExtraitComptaGene_B1814331_RNA_RNACPT22.xml` | 4.3 MB | Reparable (skip=2) |

---

## SYMPTOME

```
gpg: no valid OpenPGP data found
gpg: decrypt_message failed: Unknown system error
```

---

## DIAGNOSTIC TECHNIQUE

### Analyse hexadecimale du fichier recu

```
Position   Hex
00000000:  10 00 85 01 0c 03 5b b4 58 a8 d1 91 8d 5b
           ││││ │
           ││││ └── En-tete GPG valide (0x85)
           └┴┴┴──── OCTETS PARASITES (10 00) - NE DEVRAIENT PAS ETRE LA
```

### Comparaison

| Fichier | Premiers octets | Resultat GPG |
|---------|-----------------|--------------|
| **Recu via CFT** | `10 00 85 01 0c 03...` | ECHEC |
| **Attendu (normal)** | `85 01 0c 03...` | OK |

### Test effectue

```bash
# Sans correction : ECHEC
gpg --decrypt fichier.xml
# Resultat: "no valid OpenPGP data found"

# Avec suppression des 2 premiers octets : SUCCES
dd if=fichier.xml bs=1 skip=2 | gpg --decrypt > output.xml
# Resultat: Fichier dechiffre correctement
```

---

## INFORMATIONS SERVEUR

| Element | Valeur |
|---------|--------|
| Serveur destinataire | `s01vl9976318` |
| Utilisateur | `aparnap1` |
| Dossier reception | `/applis/04688-parna-p1/temp` |
| Cle GPG | `5BB458A8D1918D5B` (valide jusqu'au 27/11/2027) |

---

## HYPOTHESES

1. **Transformation CFT** : Le transfert CFT ajoute un prefixe de 2 octets (`10 00`)
2. **Parametre record length** : Configuration CFT incorrecte
3. **Mode transfert** : Transfert en mode texte au lieu de binaire

---

## ACTIONS DEMANDEES A L'EQUIPE CFT

1. **Verifier la configuration du flux** de transfert des fichiers `ExtraitComptaGene_*.xml`

2. **Verifier le mode de transfert** : doit etre en mode **BINAIRE** (pas texte)

3. **Verifier les parametres** :
   - Record length
   - Prefixe/suffixe automatique
   - Transformation de donnees

4. **Comparer avec un fichier sain** :
   - Demander a l'emetteur d'envoyer le fichier par SFTP manuel
   - Comparer les checksums et premiers octets

---

## COMMANDES DE DIAGNOSTIC POUR CFT

```bash
# Verifier les premiers octets du fichier cote emetteur AVANT envoi CFT
xxd fichier.xml | head -2

# Resultat attendu (fichier GPG valide) :
# 00000000: 8501 0c03 5bb4 58a8 ...

# Si on voit :
# 00000000: 1000 8501 0c03 5bb4 ...
# => Les octets parasites sont ajoutes AVANT le transfert CFT
```

---

## WORKAROUND TEMPORAIRE

En attendant la resolution, les fichiers peuvent etre dechiffres avec :

```bash
dd if=fichier_recu.xml bs=1 skip=2 | gpg --decrypt > fichier_decrypte.xml
```

---

## CONTACTS

| Role | Information |
|------|-------------|
| Equipe destinataire | PARNA / RNA |
| Emetteur | A preciser |
| Reference flux CFT | A preciser |

---

## PIECES JOINTES

- `RAPPORT_DIAGNOSTIC_GPG_19022026.md` - Rapport diagnostic complet
- `PLAN_DIAGNOSTIC_ORIGINE_CORRUPTION.md` - Plan de diagnostic detaille

---

**Ticket cree le 19/02/2026**
