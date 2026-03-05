# GUIDE - Comment Utiliser les Commentaires JIRA

## Date : 07/02/2026

---

## FICHIERS CRÉÉS POUR LE TICKET JIRA

### 1. Version COMPLÈTE (pour documentation technique)
**Fichier** : [COMMENTAIRE_JIRA_TRANSACTION_2817.txt](COMMENTAIRE_JIRA_TRANSACTION_2817.txt)

**Usage** : À copier-coller dans le commentaire JIRA pour documentation complète

**Contenu** :
- Contexte détaillé
- Root cause avec preuves SQL
- Liste complète des 23 transactions cumulées
- 3 options de solution documentées
- Questions pour le métier
- Prochaines étapes
- 10 sections structurées

**Taille** : ~450 lignes

**Quand l'utiliser** : Quand vous voulez une documentation exhaustive dans JIRA

---

### 2. Version COURTE (pour commentaire rapide)
**Fichier** : [COMMENTAIRE_JIRA_COURT.txt](COMMENTAIRE_JIRA_COURT.txt)

**Usage** : À copier-coller pour un commentaire JIRA concis

**Contenu** :
- Root cause résumée
- Preuve (cumul de 226838.78 EUR)
- Solution recommandée
- Validation métier requise

**Taille** : ~70 lignes

**Quand l'utiliser** : Quand vous voulez un commentaire court et direct

---

### 3. Version EMAIL (pour communication métier)
**Fichier** : [EMAIL_METIER.txt](EMAIL_METIER.txt)

**Usage** : À copier-coller dans un email

**Contenu** :
- Format email professionnel
- Ton métier (non technique)
- Structuré avec sections claires
- Demande de validation explicite

**Taille** : ~150 lignes

**Quand l'utiliser** : Quand vous voulez envoyer un email au métier

---

### 4. Fichier CSV (pour pièce jointe)
**Fichier** : [TRANSACTIONS_CUMUL_17102025.csv](TRANSACTIONS_CUMUL_17102025.csv)

**Usage** : À attacher au ticket JIRA comme pièce jointe

**Contenu** :
- Liste des 23 transactions en format Excel
- Colonnes : N°, MONTANT, PAYMENT_REF, CLIENT, SOCIETE, MARQUEUR
- Total : 226838.78 EUR

**Quand l'utiliser** : Pour que le métier puisse ouvrir dans Excel et analyser

---

## COMMENT PROCÉDER

### Étape 1 : Choisir le format

**Si le ticket JIRA a besoin d'une documentation complète** :
→ Utiliser **COMMENTAIRE_JIRA_TRANSACTION_2817.txt**

**Si vous voulez un commentaire court et efficace** :
→ Utiliser **COMMENTAIRE_JIRA_COURT.txt**

**Si vous devez envoyer un email en parallèle** :
→ Utiliser **EMAIL_METIER.txt**

---

### Étape 2 : Copier-coller dans JIRA

1. Ouvrir le fichier choisi
2. Copier tout le contenu (Ctrl+A puis Ctrl+C)
3. Aller dans le ticket JIRA
4. Cliquer sur "Ajouter un commentaire"
5. Coller le contenu (Ctrl+V)
6. **IMPORTANT** : Remplacer `[VOTRE NOM]`, `[VOTRE EMAIL/ÉQUIPE]` par vos informations
7. Vérifier le rendu (aperçu JIRA)
8. Publier le commentaire

---

### Étape 3 : Attacher les pièces jointes

**Pièces jointes recommandées** :
1. **TRANSACTIONS_CUMUL_17102025.csv** - Liste Excel des 23 transactions
2. **ROOT_CAUSE_ANALYSIS.md** - Documentation technique détaillée
3. **SOLUTION_OPTIONS.md** - Options de résolution documentées

**Comment attacher** :
1. Cliquer sur "Attacher un fichier" dans le ticket JIRA
2. Sélectionner les fichiers
3. Ajouter un commentaire : "PJ : Analyse détaillée et liste des transactions"

---

### Étape 4 : Envoyer l'email (optionnel)

Si vous devez aussi envoyer un email au métier :

1. Ouvrir **EMAIL_METIER.txt**
2. Copier le contenu
3. Créer un nouvel email
4. Coller le contenu
5. Remplacer `[VOTRE NOM]`, `[VOTRE FONCTION]`, `[VOTRE ÉQUIPE]`
6. Ajouter les destinataires (métier + responsables)
7. Attacher **TRANSACTIONS_CUMUL_17102025.csv**
8. Envoyer

---

## PERSONNALISATIONS NÉCESSAIRES

Avant de publier, remplacez ces placeholders :

```
[VOTRE NOM]          → Votre nom complet
[VOTRE FONCTION]     → Votre fonction (ex: Ingénieur Support N3)
[VOTRE ÉQUIPE]       → Nom de votre équipe (ex: Équipe Bankrec)
[VOTRE EMAIL/ÉQUIPE] → Votre email ou contact équipe
```

---

## EXEMPLES DE RENDU JIRA

### Format du code SQL dans JIRA

Le format `{code:sql}...{code}` s'affiche comme :
```sql
DELETE FROM TA_RN_CUMUL_MR WHERE...
```

### Format du tableau dans JIRA

Le format `{noformat}...{noformat}` s'affiche comme :
```
N°   | MONTANT    | PAYMENT_REF
-----|------------|-------------
1    | 63345.11   | 55841342
```

---

## RÉPONSES AUX QUESTIONS FRÉQUENTES

### Q1 : Dois-je modifier les scripts SQL avant de publier ?
**R** : NON, les scripts sont prêts à l'emploi. Ils sont documentés et commentés.

### Q2 : Dois-je attacher tous les fichiers .md ?
**R** : NON, seulement les 3 recommandés (voir Étape 3). Les autres sont pour référence.

### Q3 : Le métier va-t-il comprendre ?
**R** : OUI, les versions "COURT" et "EMAIL" sont rédigées en langage métier.

### Q4 : Puis-je modifier le contenu ?
**R** : OUI, vous pouvez adapter selon votre contexte, mais gardez la structure.

### Q5 : Faut-il supprimer les emojis (✅ ❌) ?
**R** : NON, ils s'affichent correctement dans JIRA et rendent le texte plus lisible.

---

## CHECKLIST AVANT PUBLICATION

- [ ] Fichier choisi (complet/court/email)
- [ ] Contenu copié
- [ ] Placeholders `[VOTRE...]` remplacés
- [ ] Aperçu vérifié dans JIRA
- [ ] Pièces jointes attachées (CSV + MD)
- [ ] Ticket assigné au bon interlocuteur métier
- [ ] Statut du ticket mis à jour (ex: "En attente métier")

---

## SUIVI APRÈS PUBLICATION

### Réponse du métier : "Oui, on veut du DÉTAIL"

1. Appliquer la **SOLUTION OPTION A** (supprimer la règle de cumul)
2. Tester sur qualification
3. Déployer en production
4. Vérifier que 2817 apparaît bien individuellement dans BR_DATA
5. Mettre à jour le ticket JIRA : "Résolu - Règle de cumul supprimée"

### Réponse du métier : "Non, on veut garder le CUMUL"

1. Expliquer que le comportement actuel est normal
2. Fermer le ticket JIRA : "Pas d'anomalie - Comportement conforme au paramétrage"
3. Documenter dans la KB

### Réponse du métier : "On veut du DÉTAIL seulement pour certains clients"

1. Appliquer la **SOLUTION OPTION B** (exclusion granulaire)
2. Créer une liste des clients à exporter en détail
3. Adapter le paramétrage
4. Tester et déployer

---

## DOCUMENTATION ASSOCIÉE

Toute la documentation technique est disponible dans :

| Fichier | Utilité |
|---------|---------|
| [INVESTIGATION_COMPLETE_2817.md](INVESTIGATION_COMPLETE_2817.md) | Chronologie complète de l'investigation |
| [ROOT_CAUSE_ANALYSIS.md](ROOT_CAUSE_ANALYSIS.md) | Analyse technique détaillée |
| [SOLUTION_OPTIONS.md](SOLUTION_OPTIONS.md) | 3 options de résolution avec scripts SQL |
| [INDEX_DOCUMENTATION.md](INDEX_DOCUMENTATION.md) | Index de tous les fichiers |

---

## CONTACT SUPPORT

En cas de question sur l'utilisation de ces commentaires :
- Consulter [INDEX_DOCUMENTATION.md](INDEX_DOCUMENTATION.md)
- Relire [INVESTIGATION_COMPLETE_2817.md](INVESTIGATION_COMPLETE_2817.md)

---

**Version : 1.0**
**Date : 07/02/2026**
**Auteur : Claude Sonnet 4.5**
