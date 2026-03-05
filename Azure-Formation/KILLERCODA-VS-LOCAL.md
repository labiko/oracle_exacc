# Killercoda vs Installation Locale - Guide Complet

## Pour tes Certifications Azure

### Réponse Courte

| Certification | Plateforme Recommandée |
|---------------|------------------------|
| **AZ-104** | Microsoft Learn Sandbox + Azure Free Tier |
| **AZ-305** | Microsoft Learn + Azure Free Tier |
| **AZ-400** | Azure DevOps (gratuit) + Azure Free Tier |
| **Kubernetes (bonus)** | Killercoda + Minikube local |

**Killercoda n'est PAS pour Azure, c'est pour Kubernetes !**

---

## Comparaison Détaillée

### Option 1 : Microsoft Learn Sandbox (RECOMMANDÉ pour Azure)

| Aspect | Détail |
|--------|--------|
| **Coût** | 100% Gratuit |
| **Durée** | Environnements temporaires (1-4h selon le module) |
| **Ressources** | Azure réel avec restrictions |
| **Avantages** | Intégré aux cours, rien à configurer |
| **Inconvénients** | Limité aux exercices du module |

**Parfait pour** : Suivre les modules Microsoft Learn

### Option 2 : Azure Free Tier (RECOMMANDÉ pour pratique libre)

| Aspect | Détail |
|--------|--------|
| **Coût** | Gratuit (200$ crédits 30 jours + services gratuits 12 mois) |
| **Durée** | Illimité (attention aux coûts après crédits) |
| **Ressources** | Azure complet |
| **Avantages** | Liberté totale, environnement réel |
| **Inconvénients** | Risque de facturation si mal géré |

**Parfait pour** : Labs personnalisés, projets POC

### Option 3 : Killercoda (Pour Kubernetes uniquement)

| Aspect | Détail |
|--------|--------|
| **Coût** | Gratuit |
| **Durée** | Sessions de 60 minutes |
| **Ressources** | Clusters Kubernetes temporaires |
| **Avantages** | Prêt en 30 secondes, scénarios guidés |
| **Inconvénients** | Pas d'Azure, limité à K8s |

**Parfait pour** : Apprendre Kubernetes avant AKS

### Option 4 : Installation Locale

| Aspect | Détail |
|--------|--------|
| **Coût** | Gratuit (outils open source) |
| **Durée** | Illimité |
| **Ressources** | Dépend de ton PC |
| **Avantages** | Hors ligne, personnalisable |
| **Inconvénients** | Installation complexe, ressources PC |

**Parfait pour** : Pratique quotidienne Azure CLI, Docker, Minikube

---

## Ma Recommandation pour Toi

### Semaine Type de Formation

```
┌─────────────────────────────────────────────────────────────┐
│                    SEMAINE DE FORMATION                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Lundi-Jeudi (1h30/soir)                                   │
│  └── Microsoft Learn + Sandbox intégré                     │
│      (Cours théorique + pratique guidée)                   │
│                                                             │
│  Samedi (3-4h)                                             │
│  └── Azure Free Tier                                       │
│      (Labs personnalisés, exploration libre)               │
│                                                             │
│  Local (quotidien)                                         │
│  └── Azure CLI installé sur ton PC                         │
│      (Commandes rapides, scripts)                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Setup Recommandé

### 1. Microsoft Learn (Rien à installer)
```
1. Créer compte : https://learn.microsoft.com
2. Suivre les parcours AZ-104/305/400
3. Les sandboxes se lancent automatiquement dans les modules
```

### 2. Azure Free Account
```
1. S'inscrire : https://azure.microsoft.com/fr-fr/free/
2. Carte bancaire requise (mais pas débitée si tu restes dans le free tier)
3. 200$ de crédits pendant 30 jours
4. Services gratuits pendant 12 mois :
   - 750h de VM B1s
   - 5 GB Blob storage
   - 250 GB SQL Database
   - Et plus...
```

### 3. Installation Locale (Windows)

```powershell
# Ouvrir PowerShell en Admin

# Azure CLI
winget install Microsoft.AzureCLI

# Vérifier
az --version

# Se connecter à Azure
az login

# Visual Studio Code
winget install Microsoft.VisualStudioCode

# Git
winget install Git.Git

# Docker Desktop (pour conteneurs)
winget install Docker.DockerDesktop
```

### 4. Killercoda (Pour Kubernetes plus tard)
```
1. Aller sur https://killercoda.com
2. Créer un compte gratuit
3. Choisir un scénario Kubernetes
4. Le cluster est prêt en 30 secondes !

Scénarios recommandés :
- Kubernetes for Beginners
- CKAD Preparation
- Kubernetes Networking
```

---

## Quand Utiliser Quoi ?

### AZ-104 : Azure Administrator

| Tâche | Plateforme |
|-------|------------|
| Apprendre Azure AD | Microsoft Learn Sandbox |
| Créer des VMs | Azure Free Tier |
| Pratiquer Azure CLI | Local (CLI installé) |
| Configurer VNets | Azure Free Tier |
| Faire les quiz | Microsoft Learn |

### AZ-305 : Azure Architect

| Tâche | Plateforme |
|-------|------------|
| Études de cas théoriques | Microsoft Learn |
| Dessiner architectures | Draw.io (local) |
| Tester architectures réelles | Azure Free Tier |
| Calculer les coûts | Azure Pricing Calculator (web) |

### AZ-400 : DevOps Engineer

| Tâche | Plateforme |
|-------|------------|
| Azure Boards/Repos | Azure DevOps (gratuit) |
| Pipelines YAML | Azure DevOps |
| Docker builds | Local (Docker Desktop) |
| Déploiement AKS | Azure Free Tier + Killercoda pour K8s |

---

## Gestion des Coûts Azure

### Éviter les Mauvaises Surprises

```bash
# Toujours supprimer les ressources après les labs !

# Option 1 : Supprimer le groupe de ressources
az group delete --name RG-Formation --yes --no-wait

# Option 2 : Supprimer toutes les ressources d'un coup
az group list --query "[].name" -o tsv | xargs -I {} az group delete --name {} --yes --no-wait
```

### Bonnes Pratiques

1. **Créer un budget Azure**
   - Azure Portal > Cost Management > Budgets
   - Mettre une alerte à 10€

2. **Utiliser des ressources gratuites**
   - VM : B1s (750h/mois gratuit)
   - Storage : 5 GB gratuit
   - App Service : F1 (gratuit)

3. **Arrêter les VMs quand pas utilisées**
   ```bash
   az vm deallocate --resource-group RG-Formation --name VM-Test
   ```

4. **Supprimer après chaque session de lab**

---

## Conclusion

### Pour tes Certifications Azure (AZ-104, AZ-305, AZ-400)

```
Microsoft Learn Sandbox = Cours théorique + pratique guidée
Azure Free Tier = Labs personnalisés + POC
Local (Azure CLI) = Commandes quotidiennes
```

### Pour Kubernetes (après les certifications Azure)

```
Killercoda = Apprendre les bases K8s (60min sessions)
Minikube local = Pratique approfondie
AKS (Azure) = Production réelle
```

### Réponse à ta Question

**"Je peux me former sur Killercoda ou mieux d'installer en local ?"**

→ **Pour Azure** : Killercoda n'est pas adapté. Utilise Microsoft Learn + Azure Free Tier.

→ **Pour Kubernetes** : Commence par Killercoda (plus simple), puis installe Minikube quand tu veux aller plus loin.

→ **Pour le quotidien** : Installe Azure CLI en local pour t'entraîner aux commandes.

---

*Prêt à commencer ? Lance le premier module Microsoft Learn AZ-104 !*
