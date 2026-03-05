# Parcours Certification Azure - Alpha Diallo

## Vue d'Ensemble

Ce dossier contient les plans de formation complets pour obtenir les certifications Microsoft Azure.

```
📅 Durée totale : 6 mois
🎯 Objectif : Expert Azure DevOps & Cloud
💰 Investissement : ~500€ (3 examens)
```

---

## Parcours Recommandé

```
┌─────────────────────────────────────────────────────────────────┐
│                     PARCOURS CERTIFICATION                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   AZ-104              AZ-305              AZ-400               │
│   Administrator  →    Architect     →     DevOps               │
│   (8 semaines)        (8 semaines)        (8 semaines)         │
│                                                                 │
│   Janvier 2026        Mars 2026           Mai 2026             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Structure des Dossiers

```
Azure-Formation/
├── README.md                          ← Ce fichier
├── AZ-104-Administrator/
│   ├── PLAN-AZ-104.md                ← Plan détaillé 8 semaines
│   ├── NOTES/                        ← Tes notes personnelles
│   └── LABS/                         ← Scripts et configs des labs
├── AZ-305-Architect/
│   ├── PLAN-AZ-305.md                ← Plan détaillé 8 semaines
│   ├── NOTES/                        ← Tes notes personnelles
│   └── ETUDES-DE-CAS/                ← Exercices architecture
└── AZ-400-DevOps/
    ├── PLAN-AZ-400.md                ← Plan détaillé 8 semaines
    ├── NOTES/                        ← Tes notes personnelles
    └── PIPELINES/                    ← Exemples YAML
```

---

## Planning Global

### Phase 1 : AZ-104 - Azure Administrator (Janvier - Février 2026)

| Semaine | Période | Thème |
|---------|---------|-------|
| 1 | 06-12 Jan | Identités Azure AD |
| 2 | 13-19 Jan | Gouvernance et RBAC |
| 3 | 20-26 Jan | Stockage (Partie 1) |
| 4 | 27 Jan - 02 Fév | Stockage (Partie 2) |
| 5 | 03-09 Fév | Machines Virtuelles |
| 6 | 10-16 Fév | Réseaux Virtuels |
| 7 | 17-23 Fév | Load Balancing & App Service |
| 8 | 24 Fév - 02 Mar | Monitoring & Examen |

**Examen AZ-104** : Première semaine de Mars 2026

---

### Phase 2 : AZ-305 - Azure Architect (Mars - Avril 2026)

| Semaine | Période | Thème |
|---------|---------|-------|
| 1 | 03-09 Mar | Architecture Identité |
| 2 | 10-16 Mar | Gouvernance et Monitoring |
| 3 | 17-23 Mar | Architecture Stockage |
| 4 | 24-30 Mar | Bases de Données |
| 5 | 31 Mar - 06 Avr | Continuité d'Activité |
| 6 | 07-13 Avr | Architecture Compute |
| 7 | 14-20 Avr | Architecture Réseau |
| 8 | 21-27 Avr | Révision & Examen |

**Examen AZ-305** : Dernière semaine d'Avril 2026

---

### Phase 3 : AZ-400 - DevOps Engineer (Mai - Juin 2026)

| Semaine | Période | Thème |
|---------|---------|-------|
| 1 | 04-10 Mai | Culture DevOps + Boards |
| 2 | 11-17 Mai | Git Avancé |
| 3 | 18-24 Mai | Pipelines CI |
| 4 | 25-31 Mai | Pipelines CD |
| 5 | 01-07 Juin | Infrastructure as Code |
| 6 | 08-14 Juin | Conteneurs + Artifacts |
| 7 | 15-21 Juin | DevSecOps |
| 8 | 22-28 Juin | Monitoring & Examen |

**Examen AZ-400** : Dernière semaine de Juin 2026

---

## Ressources Globales

### Comptes à Créer (Gratuits)

| Service | URL | Usage |
|---------|-----|-------|
| Microsoft Learn | learn.microsoft.com | Cours officiels |
| Azure Free Account | azure.microsoft.com/free | Labs pratiques (200$ crédits) |
| Azure DevOps | dev.azure.com | Labs AZ-400 |
| Pearson VUE | pearsonvue.com | Passer les examens |

### Outils à Installer

```bash
# Windows (PowerShell Admin)

# Azure CLI
winget install Microsoft.AzureCLI

# Visual Studio Code
winget install Microsoft.VisualStudioCode

# Git
winget install Git.Git

# Docker Desktop
winget install Docker.DockerDesktop

# Bicep CLI
az bicep install

# kubectl
az aks install-cli
```

### Extensions VS Code Recommandées

```
- Azure Account
- Azure Tools
- Bicep
- Docker
- YAML
- GitLens
- Kubernetes
```

---

## Coûts Estimés

| Item | Coût |
|------|------|
| Examen AZ-104 | 165€ |
| Examen AZ-305 | 165€ |
| Examen AZ-400 | 165€ |
| Azure (avec Free Tier) | 0€ - 50€ |
| **TOTAL** | **~500€** |

### Réductions Possibles
- Microsoft Learn Cloud Skills Challenge (examens gratuits parfois)
- Promotions -50% régulières
- Enterprise Skills Initiative (si éligible via EXTIA)

---

## Suivi de Progression Global

| Certification | Début | Fin Prévue | Statut | Score |
|---------------|-------|------------|--------|-------|
| AZ-104 | Janvier 2026 | Mars 2026 | [ ] À commencer | /1000 |
| AZ-305 | Mars 2026 | Avril 2026 | [ ] À venir | /1000 |
| AZ-400 | Mai 2026 | Juin 2026 | [ ] À venir | /1000 |

---

## Conseils pour Réussir

### 1. Routine Quotidienne
```
Lundi-Jeudi : 1h30 de formation le soir
Vendredi : Repos ou rattrapage
Samedi : 3-4h de labs pratiques
Dimanche : Quiz et révision
```

### 2. Méthode d'Apprentissage
```
1. Regarder le module Microsoft Learn
2. Prendre des notes dans le dossier NOTES/
3. Faire le lab pratique correspondant
4. Faire le quiz de fin de module
5. Réviser les points faibles
```

### 3. Avant Chaque Examen
```
- 3+ examens blancs avec score > 80%
- Révision des labs pratiques
- Relecture des notes
- Bonne nuit de sommeil !
```

---

## Contacts Utiles

- **Support Microsoft Learn** : Via le site
- **Support Pearson VUE** : Pour les examens
- **Communauté Azure** : tech.microsoft.com/azure

---

## Notes Personnelles

```
[Espace pour tes notes générales sur le parcours]
```

---

*Dernière mise à jour : Novembre 2025*
*Préparé pour : Alpha Diallo*
*Mission : EXTIA (2025-2028)*
