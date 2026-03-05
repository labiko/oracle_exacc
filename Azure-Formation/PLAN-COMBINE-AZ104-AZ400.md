# Plan Combiné AZ-104 + AZ-400 - 4 Mois

## Objectif : Devenir Azure DevOps Engineer

```
┌─────────────────────────────────────────────────────────────────┐
│                    PARCOURS OPTIMISÉ 4 MOIS                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   MOIS 1-2              →           MOIS 3-4                   │
│   AZ-104                            AZ-400                      │
│   Administrator                     DevOps Engineer             │
│   (Base infrastructure)             (CI/CD, Pipelines)          │
│                                                                 │
│   Février-Mars 2026                 Avril-Mai 2026             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Profil Cible Final

| Compétence | Source |
|------------|--------|
| Gérer l'infrastructure Azure | AZ-104 |
| Configurer VMs, VNets, Storage | AZ-104 |
| Créer des pipelines CI/CD | AZ-400 |
| Automatiser avec IaC (Bicep/Terraform) | AZ-400 |
| Sécuriser les déploiements | AZ-400 |
| Conteneuriser et déployer sur AKS | AZ-400 |

**Résultat** : Profil DevOps complet, très recherché sur le marché.

---

## Liens Essentiels

### Comptes à Créer (Gratuit)

| Étape | Action | Lien |
|-------|--------|------|
| 1 | Créer compte Microsoft Learn | [S'inscrire](https://learn.microsoft.com/fr-fr/) |
| 2 | Créer compte Azure gratuit | [Azure Free](https://azure.microsoft.com/fr-fr/free/) |
| 3 | Créer organisation Azure DevOps | [Azure DevOps](https://dev.azure.com/) |
| 4 | Créer compte Pearson VUE | [Pearson VUE](https://home.pearsonvue.com/microsoft) |

### Parcours Microsoft Learn (Gratuit)

| Certification | Parcours | Durée |
|---------------|----------|-------|
| **AZ-104** | [Parcours Administrator](https://learn.microsoft.com/fr-fr/certifications/azure-administrator/) | 42h |
| **AZ-400** | [Parcours DevOps Engineer](https://learn.microsoft.com/fr-fr/certifications/devops-engineer/) | 40h |

---

## Formations Vidéo en Français (Recommandées)

### Plateformes de Formation Vidéo

| Plateforme | Formation | Langue | Prix | Lien |
|------------|-----------|--------|------|------|
| **Alphorm** | AZ-104 Administration | 100% Français | ~30€/mois (abonnement) | [Alphorm AZ-104](https://www.alphorm.com/tutoriel/formation-en-ligne-microsoft-azure-az-104-administration) |
| **Udemy** | AZ-104 Certification [2025] | Français | ~15-20€ (promo) | [Udemy AZ-104 FR](https://www.udemy.com/course/az-104-certification-microsoft-azure-administrator-2022/) |
| **Udemy** | Examens AZ-104 Français | Français | ~15-20€ (promo) | [Examens FR](https://www.udemy.com/course/administrateur-ms-azure-az-104-examens-francais/) |
| **Tuto.com** | AZ-104 Administration | 100% Français | Variable | [Tuto.com](https://fr.tuto.com/azure/az-104-administration-formation,162981.html) |

### Détails des Formations

#### Alphorm (Recommandé - 100% Français)
- **Approche** : 70% pratique, 30% théorie
- **Note** : 4.6/5
- **Avantage** : Formateurs francophones, Labs inclus
- **Abonnement** : Accès à tout le catalogue (~400 formations)

#### Udemy (Bon rapport qualité/prix)
- **Prix** : Souvent en promo à 10-20€
- **Avantage** : Accès à vie, certificat de complétion
- **Conseil** : Attendre les promos (très fréquentes)

### Stratégie Recommandée

```
┌─────────────────────────────────────────────────────────────┐
│            COMBINAISON OPTIMALE                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Microsoft Learn (Gratuit)                              │
│     └── Théorie + Sandbox intégrés                         │
│                                                             │
│  2. Alphorm OU Udemy (Payant)                              │
│     └── Vidéos explicatives en français                    │
│     └── Formateur qui explique les concepts                │
│                                                             │
│  3. Azure Free Tier (Gratuit)                              │
│     └── Pratique réelle sur ton compte Azure               │
│                                                             │
│  4. Labs GitHub officiels (Gratuit)                        │
│     └── Exercices pratiques guidés                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Budget Formation

| Option | Coût Total |
|--------|------------|
| **Option Gratuite** | Microsoft Learn + Labs GitHub = 0€ |
| **Option Économique** | + Udemy en promo = ~15€ |
| **Option Complète** | + Alphorm 2 mois = ~60€ |

---

## PHASE 1 : AZ-104 - Azure Administrator (8 semaines)

### Semaine 1-2 : Identités et Gouvernance

#### Modules Microsoft Learn

| Module | Lien | Durée |
|--------|------|-------|
| Configurer Microsoft Entra ID | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-active-directory/) | 45min |
| Configurer les comptes utilisateurs | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-user-group-accounts/) | 45min |
| Configurer les abonnements | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-subscriptions/) | 30min |
| Configurer Azure Policy | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-policy/) | 45min |
| Configurer RBAC | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-role-based-access-control/) | 45min |

#### Planning

| Jour | Activité | Durée |
|------|----------|-------|
| Lun-Jeu | Modules Microsoft Learn | 1h30/soir |
| Sam | Lab pratique : Users, Groups, RBAC | 3h |
| Dim | Quiz + Notes | 1h |

#### Labs
- [Lab 01 - Manage Entra ID Identities](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_01-Manage_Entra_ID_Identities.html)
- [Lab 02a - Manage Subscriptions and RBAC](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_02a_Manage_Subscriptions_and_RBAC.html)

#### Checklist Semaine 1-2
- [ ] Azure AD : créer users et groups
- [ ] RBAC : assigner des rôles
- [ ] Azure Policy : créer une policy
- [ ] Comprendre les Management Groups

---

### Semaine 3-4 : Stockage Azure

#### Modules Microsoft Learn

| Module | Lien | Durée |
|--------|------|-------|
| Configurer les comptes de stockage | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-storage-accounts/) | 45min |
| Configurer le stockage Blob | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-blob-storage/) | 45min |
| Configurer Azure Files | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-files-file-sync/) | 45min |
| Configurer la sécurité du stockage | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-storage-security/) | 45min |

#### Labs
- [Lab 07 - Manage Azure Storage](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_07-Manage_Azure_Storage.html)

#### Checklist Semaine 3-4
- [ ] Créer un compte de stockage
- [ ] Configurer Blob containers
- [ ] Générer des SAS tokens
- [ ] Comprendre la réplication (LRS, GRS, ZRS)
- [ ] **EXAMEN BLANC #1** : [Practice Assessment](https://learn.microsoft.com/fr-fr/certifications/practice-assessments-for-microsoft-certifications)

---

### Semaine 5-6 : Compute et Réseaux

#### Modules Microsoft Learn - Compute

| Module | Lien | Durée |
|--------|------|-------|
| Configurer les machines virtuelles | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-virtual-machines/) | 1h |
| Configurer la disponibilité des VMs | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-virtual-machine-availability/) | 45min |
| Configurer Azure App Service | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-app-services/) | 45min |
| Configurer Azure Container Instances | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-container-instances/) | 30min |

#### Modules Microsoft Learn - Réseaux

| Module | Lien | Durée |
|--------|------|-------|
| Configurer les réseaux virtuels | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-virtual-networks/) | 45min |
| Configurer les NSG | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-network-security-groups/) | 45min |
| Configurer le peering VNet | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-vnet-peering/) | 30min |
| Configurer Azure DNS | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-dns/) | 30min |

#### Labs
- [Lab 08 - Manage Virtual Machines](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_08-Manage_Virtual_Machines.html)
- [Lab 04 - Implement Virtual Networking](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_04-Implement_Virtual_Networking.html)

#### Checklist Semaine 5-6
- [ ] Créer des VMs (Windows + Linux)
- [ ] Configurer des disques managés
- [ ] Créer un VNet avec sous-réseaux
- [ ] Configurer des NSG
- [ ] Implémenter le VNet Peering
- [ ] Déployer une App Service

---

### Semaine 7-8 : Load Balancing, Monitoring et Révision

#### Modules Microsoft Learn

| Module | Lien | Durée |
|--------|------|-------|
| Configurer Azure Load Balancer | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-load-balancer/) | 45min |
| Configurer Azure Application Gateway | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-application-gateway/) | 45min |
| Configurer Azure Monitor | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-monitor/) | 45min |
| Configurer Azure Backup | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-file-folder-backups/) | 45min |

#### Labs
- [Lab 06 - Implement Traffic Management](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_06-Implement_Network_Traffic_Management.html)
- [Lab 11 - Implement Monitoring](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_11-Implement_Monitoring.html)

#### Planning Semaine 8

| Jour | Activité |
|------|----------|
| Lun-Mar | Révision points faibles |
| Mer | **EXAMEN BLANC #2** |
| Jeu | Révision ciblée |
| Ven | **EXAMEN BLANC #3** |
| Sam | Dernière révision |
| **Dim** | **EXAMEN AZ-104** |

#### Checklist Semaine 7-8
- [ ] Configurer un Load Balancer
- [ ] Créer des alertes Azure Monitor
- [ ] Configurer Azure Backup
- [ ] 3 examens blancs > 80%
- [ ] **PASSER EXAMEN AZ-104**

---

## 🎉 TRANSITION : 1 Semaine de Pause

Après avoir réussi AZ-104 :
- Célébrer ta réussite !
- Créer ton projet Azure DevOps
- Préparer ton environnement pour AZ-400

---

## PHASE 2 : AZ-400 - DevOps Engineer (8 semaines)

### Parcours Microsoft Learn AZ-400
🔗 [Parcours complet](https://learn.microsoft.com/fr-fr/certifications/devops-engineer/)

### Semaine 9-10 : Culture DevOps et Contrôle de Code Source

#### Modules Microsoft Learn

| Module | Lien | Durée |
|--------|------|-------|
| Démarrer la transformation DevOps | [Lien](https://learn.microsoft.com/fr-fr/training/paths/az-400-get-started-devops-transformation-journey/) | 3h |
| Développer une stratégie de contrôle de code source | [Lien](https://learn.microsoft.com/fr-fr/training/paths/az-400-develop-source-control-strategy/) | 4h |

#### Pratique

| Activité | Détail |
|----------|--------|
| Créer organisation Azure DevOps | https://dev.azure.com |
| Créer un projet | Avec Azure Repos, Boards, Pipelines |
| Configurer Git | Branch policies, Pull Requests |
| Implémenter GitFlow | main, develop, feature branches |

#### Labs
- [Azure DevOps Labs - Version Control](https://azuredevopslabs.com/labs/azuredevops/git/)

#### Checklist Semaine 9-10
- [ ] Organisation Azure DevOps créée
- [ ] Projet avec Boards configuré
- [ ] Repository Git avec branch policies
- [ ] Pull Request workflow fonctionnel
- [ ] Comprendre GitFlow vs Trunk-based

---

### Semaine 11-12 : Pipelines CI (Intégration Continue)

#### Modules Microsoft Learn

| Module | Lien | Durée |
|--------|------|-------|
| Implémenter l'intégration continue | [Lien](https://learn.microsoft.com/fr-fr/training/paths/az-400-implement-ci-azure-pipelines-github-actions/) | 6h |

#### Pratique - Créer ton premier pipeline

```yaml
# azure-pipelines.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  buildConfiguration: 'Release'

stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - task: DotNetCoreCLI@2
      displayName: 'Restore'
      inputs:
        command: 'restore'
        projects: '**/*.csproj'

    - task: DotNetCoreCLI@2
      displayName: 'Build'
      inputs:
        command: 'build'
        arguments: '--configuration $(buildConfiguration)'

    - task: DotNetCoreCLI@2
      displayName: 'Test'
      inputs:
        command: 'test'
        arguments: '--configuration $(buildConfiguration)'

    - task: DotNetCoreCLI@2
      displayName: 'Publish'
      inputs:
        command: 'publish'
        publishWebProjects: true
        arguments: '--configuration $(buildConfiguration) --output $(Build.ArtifactStagingDirectory)'

    - task: PublishBuildArtifacts@1
      inputs:
        PathtoPublish: '$(Build.ArtifactStagingDirectory)'
        ArtifactName: 'drop'
```

#### Labs
- [Azure DevOps Labs - CI with Azure Pipelines](https://azuredevopslabs.com/labs/azuredevops/continuousintegration/)

#### Checklist Semaine 11-12
- [ ] Pipeline YAML créé
- [ ] Build .NET fonctionnel
- [ ] Tests automatisés
- [ ] Artefacts publiés
- [ ] Comprendre agents (hosted vs self-hosted)

---

### Semaine 13-14 : Pipelines CD (Déploiement Continu)

#### Modules Microsoft Learn

| Module | Lien | Durée |
|--------|------|-------|
| Implémenter le déploiement continu | [Lien](https://learn.microsoft.com/fr-fr/training/paths/az-400-implement-cd-azure-pipelines/) | 6h |

#### Pratique - Ajouter le déploiement

```yaml
# Ajouter après le stage Build
- stage: DeployDev
  dependsOn: Build
  jobs:
  - deployment: DeployDev
    environment: 'Development'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'Azure-Connection'
              appName: 'myapp-dev'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'

- stage: DeployProd
  dependsOn: DeployDev
  jobs:
  - deployment: DeployProd
    environment: 'Production'  # Approbation requise
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureAppServiceManage@0
            inputs:
              Action: 'Swap Slots'
              WebAppName: 'myapp-prod'
              SourceSlot: 'staging'
```

#### Labs
- [Azure DevOps Labs - CD with Azure Pipelines](https://azuredevopslabs.com/labs/azuredevops/continuousdeployment/)

#### Checklist Semaine 13-14
- [ ] Déploiement multi-stages (Dev → Staging → Prod)
- [ ] Environments avec approbations
- [ ] Deployment slots (swap)
- [ ] Service connections configurées
- [ ] **EXAMEN BLANC #1 AZ-400**

---

### Semaine 15-16 : Infrastructure as Code et Conteneurs

#### Modules Microsoft Learn

| Module | Lien | Durée |
|--------|------|-------|
| Gérer l'infrastructure as code | [Lien](https://learn.microsoft.com/fr-fr/training/paths/az-400-manage-infrastructure-as-code-using-azure/) | 5h |
| Implémenter des conteneurs | [Lien](https://learn.microsoft.com/fr-fr/training/paths/az-400-develop-implement-containers/) | 4h |

#### Pratique Bicep

```bicep
// main.bicep
param location string = resourceGroup().location
param appName string = 'myapp'
param environment string = 'dev'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-${appName}-${environment}'
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: '${appName}-${environment}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}
```

#### Pratique Docker

```dockerfile
# Dockerfile multi-stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 80
ENTRYPOINT ["dotnet", "MyApp.dll"]
```

#### Checklist Semaine 15-16
- [ ] Déployer infrastructure avec Bicep
- [ ] Créer une image Docker
- [ ] Pousser vers Azure Container Registry
- [ ] Déployer sur Azure Container Instances
- [ ] Comprendre AKS (bases)

---

### Semaine 17-18 : Sécurité DevSecOps et Révision Finale

#### Modules Microsoft Learn

| Module | Lien | Durée |
|--------|------|-------|
| Sécurité et conformité DevOps | [Lien](https://learn.microsoft.com/fr-fr/training/paths/az-400-develop-security-compliance-plan/) | 4h |
| Stratégie d'instrumentation | [Lien](https://learn.microsoft.com/fr-fr/training/paths/az-400-implement-app-monitoring/) | 3h |

#### Pratique Sécurité

```yaml
# Ajouter scan de sécurité au pipeline
- stage: SecurityScan
  jobs:
  - job: SAST
    steps:
    - task: SonarQubePrepare@5
      inputs:
        SonarQube: 'SonarQube-Connection'
        projectKey: 'my-app'

    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'

    - task: SonarQubeAnalyze@5
    - task: SonarQubePublish@5
```

#### Pratique Key Vault

```yaml
# Utiliser secrets de Key Vault
- task: AzureKeyVault@2
  inputs:
    azureSubscription: 'Azure-Connection'
    KeyVaultName: 'kv-myapp'
    SecretsFilter: 'ConnectionString,ApiKey'
```

#### Planning Semaine 18

| Jour | Activité |
|------|----------|
| Lun-Mar | Révision complète |
| Mer | **EXAMEN BLANC #2** |
| Jeu | Révision points faibles |
| Ven | **EXAMEN BLANC #3** |
| Sam | Dernière révision |
| **Dim** | **EXAMEN AZ-400** |

#### Checklist Semaine 17-18
- [ ] Intégrer Azure Key Vault
- [ ] Comprendre DevSecOps (SAST, DAST)
- [ ] Configurer Application Insights
- [ ] 3 examens blancs > 80%
- [ ] **PASSER EXAMEN AZ-400**

---

## Récapitulatif Planning Global

| Mois | Semaines | Certification | Focus |
|------|----------|---------------|-------|
| **Mois 1** | 1-4 | AZ-104 | Identités, Stockage |
| **Mois 2** | 5-8 | AZ-104 | Compute, Réseaux, **EXAMEN** |
| **Mois 3** | 9-12 | AZ-400 | Git, Pipelines CI |
| **Mois 4** | 13-18 | AZ-400 | Pipelines CD, IaC, **EXAMEN** |

---

## Investissement

### Coût des Examens

| Item | Coût |
|------|------|
| Examen AZ-104 | 165€ |
| Examen AZ-400 | 165€ |
| **Sous-total Examens** | **330€** |

### Coût des Formations (Optionnel)

| Option | Formations | Coût |
|--------|------------|------|
| **Gratuit** | Microsoft Learn + Labs GitHub | 0€ |
| **Économique** | + Udemy AZ-104 + AZ-400 (promo) | ~30€ |
| **Complète** | + Alphorm 4 mois | ~120€ |

### Ressources Gratuites

| Ressource | Coût |
|-----------|------|
| Azure Free Tier (200$ crédits) | 0€ |
| Azure DevOps (jusqu'à 5 users) | 0€ |
| Microsoft Learn + Sandbox | 0€ |
| Labs GitHub officiels | 0€ |

### Budget Total Estimé

| Scénario | Coût Total |
|----------|------------|
| **Minimum** (Learn + Examens) | 330€ |
| **Recommandé** (+ Udemy) | 360€ |
| **Complet** (+ Alphorm) | 450€ |

---

## Routine Hebdomadaire

```
┌─────────────────────────────────────────────────────────────┐
│                    SEMAINE TYPE                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Lundi-Jeudi : 1h30/soir                                   │
│  └── Modules Microsoft Learn                               │
│  └── Prendre des notes                                     │
│                                                             │
│  Vendredi : Repos ou rattrapage                            │
│                                                             │
│  Samedi : 3-4h                                             │
│  └── LABS PRATIQUES (obligatoire !)                        │
│  └── Azure Portal / Azure DevOps                           │
│                                                             │
│  Dimanche : 1-2h                                           │
│  └── Quiz de révision                                      │
│  └── Relecture des notes                                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Total : ~10h/semaine
```

---

## Suivi de Progression

### Phase 1 : AZ-104

| Semaine | Thème | Statut | Score |
|---------|-------|--------|-------|
| 1-2 | Identités et Gouvernance | [ ] | /100 |
| 3-4 | Stockage Azure | [ ] | /100 |
| 5-6 | Compute et Réseaux | [ ] | /100 |
| 7-8 | Monitoring et Révision | [ ] | /100 |
| | **EXAMEN AZ-104** | [ ] | /1000 |

### Phase 2 : AZ-400

| Semaine | Thème | Statut | Score |
|---------|-------|--------|-------|
| 9-10 | DevOps Culture + Git | [ ] | /100 |
| 11-12 | Pipelines CI | [ ] | /100 |
| 13-14 | Pipelines CD | [ ] | /100 |
| 15-16 | IaC + Conteneurs | [ ] | /100 |
| 17-18 | DevSecOps + Révision | [ ] | /100 |
| | **EXAMEN AZ-400** | [ ] | /1000 |

---

## Résultat Final

Après 4 mois, tu seras :

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   Microsoft Certified: Azure Administrator Associate       │
│                         +                                   │
│   Microsoft Certified: DevOps Engineer Expert              │
│                                                             │
│   = Profil TRÈS recherché sur le marché                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Salaire moyen DevOps Engineer certifié Azure : 55-75K€/an en France**

---

## Pour Commencer MAINTENANT

1. **Créer compte Microsoft Learn** : https://learn.microsoft.com/fr-fr/
2. **Créer compte Azure gratuit** : https://azure.microsoft.com/fr-fr/free/
3. **Créer organisation Azure DevOps** : https://dev.azure.com/
4. **Commencer le premier module** : [Prérequis AZ-104](https://learn.microsoft.com/fr-fr/training/paths/az-104-administrator-prerequisites/)

---

*Dernière mise à jour : Novembre 2025*
*Préparé pour : Alpha Diallo*
*Objectif : Azure DevOps Engineer en 4 mois*
