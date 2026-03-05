# AZ-400 : Designing and Implementing Microsoft DevOps Solutions

## Informations Examen

| Information | Détail |
|-------------|--------|
| **Code** | AZ-400 |
| **Nom** | Designing and Implementing Microsoft DevOps Solutions |
| **Durée** | 120 minutes |
| **Questions** | 40-60 questions (+ labs pratiques possibles) |
| **Score minimum** | 700/1000 |
| **Prix** | 165 EUR |
| **Langue** | Français disponible |
| **Validité** | 1 an (renouvellement gratuit en ligne) |
| **Prérequis** | AZ-104 recommandé + expérience DevOps |

---

## Profil Cible

Cette certification est **parfaite pour ton profil** :
- Chefs de projet techniques
- Développeurs .NET expérimentés
- DevOps Engineers
- Personnes visant la transformation DevOps

**Ton avantage** : 7 ans d'expérience ASP.NET MVC = base solide pour AZ-400 !

---

## Compétences Évaluées

| Domaine | Pourcentage |
|---------|-------------|
| Configurer les processus et communications | 10-15% |
| Concevoir et implémenter le contrôle de code source | 15-20% |
| Concevoir et implémenter les pipelines de build et release | 40-45% |
| Développer un plan de sécurité et de conformité | 10-15% |
| Implémenter une stratégie d'instrumentation | 10-15% |

---

## Plan d'Étude - 8 Semaines

### SEMAINE 1 : Culture et Processus DevOps

#### Objectifs
- [ ] Comprendre la philosophie DevOps
- [ ] Planifier la transformation DevOps
- [ ] Choisir les outils de gestion de projet
- [ ] Configurer Azure Boards

#### Modules Microsoft Learn
1. [Démarrer avec DevOps](https://learn.microsoft.com/fr-fr/training/paths/az-400-get-started-devops-transformation-journey/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Qu'est-ce que DevOps ? | 1h30 | [ ] |
| Mardi | Module : Planifier la transformation Agile | 1h30 | [ ] |
| Mercredi | Module : Azure DevOps vs GitHub | 1h30 | [ ] |
| Jeudi | Module : Azure Boards - Work Items | 1h30 | [ ] |
| Vendredi | Module : Azure Boards - Sprints et Backlogs | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : Créer projet Azure DevOps | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Lab Pratique Semaine 1
```
LAB 01: Premiers pas Azure DevOps
1. Créer une organisation Azure DevOps
2. Créer un projet "Formation-AZ400"
3. Configurer Azure Boards :
   - Créer 10 User Stories
   - Créer 5 Bugs
   - Créer 3 Epics
   - Organiser un Sprint de 2 semaines
4. Inviter un collaborateur
5. Configurer les dashboards

URL : https://dev.azure.com
```

#### Concepts Clés
```
- Lead Time vs Cycle Time
- DORA Metrics (Deployment Frequency, Lead Time, MTTR, Change Failure Rate)
- Shift-Left Testing
- Continuous Improvement
```

---

### SEMAINE 2 : Contrôle de Code Source avec Git

#### Objectifs
- [ ] Maîtriser Git avancé
- [ ] Configurer les politiques de branche
- [ ] Implémenter GitFlow et trunk-based development
- [ ] Gérer les Pull Requests

#### Modules Microsoft Learn
1. [Développer avec Git](https://learn.microsoft.com/fr-fr/training/paths/az-400-develop-source-control-strategy/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Git internals (blobs, trees, commits) | 1h30 | [ ] |
| Mardi | Module : Stratégies de branchement | 1h30 | [ ] |
| Mercredi | Module : Pull Requests et code reviews | 1h30 | [ ] |
| Jeudi | Module : Branch policies | 1h30 | [ ] |
| Vendredi | Module : Git hooks et automation | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : Workflow Git complet | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Lab Pratique Semaine 2
```
LAB 02: Gestion avancée du code source
1. Créer un repo Azure Repos
2. Configurer les branch policies :
   - Require PR for main
   - Minimum 1 reviewer
   - Build validation
   - Linked work items required
3. Implémenter GitFlow :
   - main, develop, feature/*, release/*, hotfix/*
4. Créer une Pull Request
5. Effectuer un code review
6. Merge avec squash

COMMANDES GIT À MAÎTRISER :
git rebase -i HEAD~3
git cherry-pick <commit>
git bisect start
git reflog
```

#### Stratégies de Branchement
```
GITFLOW :
main ─────●────────●────────●───── (releases)
           \      /          \
develop ────●────●────●────●──●── (intégration)
             \  /      \    /
feature ──────●────     ●──●     (features)

TRUNK-BASED :
main ────●────●────●────●────●── (tout le monde)
          \  / \  /      |
feature ───●    ●    (short-lived, < 1 jour)
```

---

### SEMAINE 3 : Pipelines de Build (CI)

#### Objectifs
- [ ] Créer des pipelines YAML
- [ ] Configurer les agents (Microsoft-hosted vs self-hosted)
- [ ] Implémenter la compilation .NET
- [ ] Gérer les artefacts

#### Modules Microsoft Learn
1. [Implémenter l'intégration continue](https://learn.microsoft.com/fr-fr/training/paths/az-400-implement-ci-azure-pipelines-github-actions/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Pipeline YAML vs Classic | 1h30 | [ ] |
| Mardi | Module : Agents et pools | 1h30 | [ ] |
| Mercredi | Module : Build .NET (restore, build, test) | 1h30 | [ ] |
| Jeudi | Module : Build Docker images | 1h30 | [ ] |
| Vendredi | Module : Artefacts et feeds | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : Pipeline CI complet | 4h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Lab Pratique Semaine 3
```
LAB 03: Pipeline CI pour application .NET

1. Créer une application ASP.NET MVC simple
2. Pousser vers Azure Repos
3. Créer azure-pipelines.yml :

```yaml
trigger:
  - main
  - develop

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
        projects: '**/*.csproj'
        arguments: '--configuration $(buildConfiguration)'

    - task: DotNetCoreCLI@2
      displayName: 'Test'
      inputs:
        command: 'test'
        projects: '**/*Tests.csproj'
        arguments: '--configuration $(buildConfiguration) --collect:"XPlat Code Coverage"'

    - task: PublishCodeCoverageResults@1
      inputs:
        codeCoverageTool: 'Cobertura'
        summaryFileLocation: '$(Agent.TempDirectory)/**/coverage.cobertura.xml'

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

4. Exécuter et valider le pipeline
5. Vérifier les artefacts publiés
```

---

### SEMAINE 4 : Pipelines de Release (CD)

#### Objectifs
- [ ] Créer des pipelines de déploiement multi-stages
- [ ] Implémenter les approbations et gates
- [ ] Déployer vers Azure App Service
- [ ] Configurer les slots de déploiement

#### Modules Microsoft Learn
1. [Implémenter le déploiement continu](https://learn.microsoft.com/fr-fr/training/paths/az-400-implement-cd-azure-pipelines/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Stages et environments | 1h30 | [ ] |
| Mardi | Module : Approvals et gates | 1h30 | [ ] |
| Mercredi | Module : Deployment vers App Service | 1h30 | [ ] |
| Jeudi | Module : Deployment slots (blue-green) | 1h30 | [ ] |
| Vendredi | Module : Rollback strategies | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : Pipeline CD complet | 4h | [ ] |
| Dimanche | Quiz + Notes + EXAMEN BLANC #1 | 2h | [ ] |

#### Lab Pratique Semaine 4
```
LAB 04: Pipeline CD Multi-environnement

Ajouter au pipeline existant :

```yaml
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
              appType: 'webApp'
              appName: 'app-formation-dev'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'

- stage: DeployStaging
  dependsOn: DeployDev
  jobs:
  - deployment: DeployStaging
    environment: 'Staging'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureWebApp@1
            inputs:
              azureSubscription: 'Azure-Connection'
              appName: 'app-formation-staging'
              deployToSlotOrASE: true
              slotName: 'staging'
              package: '$(Pipeline.Workspace)/drop/**/*.zip'

- stage: DeployProd
  dependsOn: DeployStaging
  condition: succeeded()
  jobs:
  - deployment: DeployProd
    environment: 'Production'
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureAppServiceManage@0
            inputs:
              azureSubscription: 'Azure-Connection'
              Action: 'Swap Slots'
              WebAppName: 'app-formation-prod'
              SourceSlot: 'staging'
```

CONFIGURER :
1. Service Connection vers Azure
2. Environment "Development" (auto-approval)
3. Environment "Staging" (1 approver)
4. Environment "Production" (2 approvers + business hours gate)
```

---

### SEMAINE 5 : Infrastructure as Code (IaC)

#### Objectifs
- [ ] Maîtriser les templates ARM
- [ ] Apprendre Bicep
- [ ] Utiliser Terraform avec Azure
- [ ] Implémenter GitOps

#### Modules Microsoft Learn
1. [Gérer l'infrastructure as code](https://learn.microsoft.com/fr-fr/training/paths/az-400-manage-infrastructure-as-code-using-azure/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : ARM Templates basics | 1h30 | [ ] |
| Mardi | Module : Bicep - le successeur d'ARM | 1h30 | [ ] |
| Mercredi | Module : Terraform avec Azure | 1h30 | [ ] |
| Jeudi | Module : Azure CLI scripting | 1h30 | [ ] |
| Vendredi | Module : GitOps avec Flux | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : IaC complet | 4h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Lab Pratique Semaine 5
```
LAB 05: Infrastructure as Code

PARTIE 1 - BICEP :

// main.bicep
param location string = resourceGroup().location
param appName string = 'app-formation'
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
    siteConfig: {
      netFrameworkVersion: 'v6.0'
    }
  }
}

resource stagingSlot 'Microsoft.Web/sites/slots@2022-03-01' = {
  parent: webApp
  name: 'staging'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}

output webAppUrl string = webApp.properties.defaultHostName

PARTIE 2 - Pipeline IaC :
- Valider les templates (what-if)
- Déployer l'infrastructure
- Déployer l'application
```

#### Comparaison IaC Tools
```
| Outil | Avantages | Inconvénients |
|-------|-----------|---------------|
| ARM | Natif Azure, complet | Verbeux, JSON complexe |
| Bicep | Simple, natif Azure | Azure uniquement |
| Terraform | Multi-cloud, état | Outil tiers, HCL |
| Pulumi | Code réel (C#, Python) | Courbe d'apprentissage |
```

---

### SEMAINE 6 : Gestion des Dépendances et Conteneurs

#### Objectifs
- [ ] Configurer Azure Artifacts
- [ ] Créer des packages NuGet
- [ ] Build et push Docker images
- [ ] Déployer vers AKS

#### Modules Microsoft Learn
1. [Gérer les dépendances](https://learn.microsoft.com/fr-fr/training/paths/az-400-manage-dependencies-security/)
2. [Implémenter des conteneurs](https://learn.microsoft.com/fr-fr/training/paths/az-400-develop-implement-containers/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Azure Artifacts - Feeds | 1h30 | [ ] |
| Mardi | Module : NuGet packages | 1h30 | [ ] |
| Mercredi | Module : Docker multi-stage builds | 1h30 | [ ] |
| Jeudi | Module : Azure Container Registry | 1h30 | [ ] |
| Vendredi | Module : Deployment vers AKS | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : CI/CD Conteneurs | 4h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Lab Pratique Semaine 6
```
LAB 06: Pipeline Conteneurs

PARTIE 1 - Dockerfile multi-stage :

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MyApp.csproj", "."]
RUN dotnet restore
COPY . .
RUN dotnet publish -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 80
ENTRYPOINT ["dotnet", "MyApp.dll"]

PARTIE 2 - Pipeline Docker + AKS :

```yaml
stages:
- stage: BuildDocker
  jobs:
  - job: Build
    steps:
    - task: Docker@2
      inputs:
        containerRegistry: 'ACR-Connection'
        repository: 'myapp'
        command: 'buildAndPush'
        Dockerfile: '**/Dockerfile'
        tags: |
          $(Build.BuildId)
          latest

- stage: DeployAKS
  jobs:
  - job: Deploy
    steps:
    - task: KubernetesManifest@0
      inputs:
        action: 'deploy'
        kubernetesServiceConnection: 'AKS-Connection'
        namespace: 'production'
        manifests: |
          k8s/deployment.yaml
          k8s/service.yaml
        containers: |
          myacr.azurecr.io/myapp:$(Build.BuildId)
```

PARTIE 3 - Kubernetes manifests (k8s/deployment.yaml)
```

---

### SEMAINE 7 : Sécurité DevSecOps

#### Objectifs
- [ ] Implémenter la sécurité dans les pipelines
- [ ] Scanner les vulnérabilités (SAST, DAST)
- [ ] Gérer les secrets avec Azure Key Vault
- [ ] Configurer les Service Principals

#### Modules Microsoft Learn
1. [Implémenter la sécurité DevOps](https://learn.microsoft.com/fr-fr/training/paths/az-400-develop-security-compliance-plan/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : DevSecOps principes | 1h30 | [ ] |
| Mardi | Module : SAST avec SonarQube | 1h30 | [ ] |
| Mercredi | Module : Dependency scanning (WhiteSource) | 1h30 | [ ] |
| Jeudi | Module : Azure Key Vault integration | 1h30 | [ ] |
| Vendredi | Module : Service Principals et Managed Identity | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : Pipeline sécurisé | 4h | [ ] |
| Dimanche | Quiz + Notes + EXAMEN BLANC #2 | 2h | [ ] |

#### Lab Pratique Semaine 7
```
LAB 07: Pipeline DevSecOps

1. Ajouter analyse de sécurité au pipeline :

```yaml
- stage: SecurityScan
  jobs:
  - job: SAST
    steps:
    - task: SonarQubePrepare@5
      inputs:
        SonarQube: 'SonarQube-Connection'
        scannerMode: 'MSBuild'
        projectKey: 'my-app'

    - task: DotNetCoreCLI@2
      inputs:
        command: 'build'

    - task: SonarQubeAnalyze@5

    - task: SonarQubePublish@5
      inputs:
        pollingTimeoutSec: '300'

  - job: DependencyCheck
    steps:
    - task: WhiteSource@21
      inputs:
        cwd: '$(System.DefaultWorkingDirectory)'
        projectName: 'my-app'
```

2. Intégrer Key Vault :

```yaml
- task: AzureKeyVault@2
  inputs:
    azureSubscription: 'Azure-Connection'
    KeyVaultName: 'kv-formation'
    SecretsFilter: 'ConnectionString,ApiKey'
    RunAsPreJob: true

- script: |
    echo "Using secret from Key Vault"
  env:
    CONNECTION_STRING: $(ConnectionString)
```

3. Configurer les quality gates
```

#### Outils de Sécurité
```
| Type | Outil | Usage |
|------|-------|-------|
| SAST | SonarQube | Analyse code statique |
| DAST | OWASP ZAP | Test pénétration |
| SCA | WhiteSource/Snyk | Dépendances vulnérables |
| Container | Trivy/Aqua | Scan images Docker |
| Secrets | GitGuardian | Détection secrets dans code |
```

---

### SEMAINE 8 : Monitoring et Révision Finale

#### Objectifs
- [ ] Implémenter Application Insights
- [ ] Créer des dashboards
- [ ] Configurer les alertes
- [ ] Réussir l'examen

#### Modules Microsoft Learn
1. [Implémenter une stratégie d'instrumentation](https://learn.microsoft.com/fr-fr/training/paths/az-400-implement-app-monitoring/)

#### Programme Final

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Application Insights | 1h30 | [ ] |
| Mardi | Module : Distributed tracing | 1h30 | [ ] |
| Mercredi | Module : Alertes et dashboards | 1h30 | [ ] |
| Jeudi | Révision : Pipelines CI/CD | 2h | [ ] |
| Vendredi | **EXAMEN BLANC #3** | 2h | [ ] |
| Samedi | Révision points faibles | 3h | [ ] |
| Dimanche | **EXAMEN AZ-400** | - | [ ] |

#### Lab Pratique Semaine 8
```
LAB 08: Monitoring Application

1. Configurer Application Insights :

// Program.cs
builder.Services.AddApplicationInsightsTelemetry();

2. Ajouter au pipeline :

```yaml
- task: AzureCLI@2
  inputs:
    azureSubscription: 'Azure-Connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      az monitor app-insights component create \
        --app myapp-insights \
        --location westeurope \
        --resource-group RG-Formation
```

3. Créer un workbook Azure Monitor
4. Configurer alertes :
   - Response time > 2s
   - Error rate > 5%
   - Availability < 99%
5. Créer dashboard DevOps avec widgets
```

---

## Projet Fil Rouge

### Architecture Complète à Implémenter

```
┌─────────────────────────────────────────────────────────────────┐
│                     AZURE DEVOPS PROJECT                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐        │
│  │ Azure Boards │   │ Azure Repos  │   │   Artifacts  │        │
│  │   (Agile)    │   │    (Git)     │   │   (NuGet)    │        │
│  └──────────────┘   └──────────────┘   └──────────────┘        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      CI/CD PIPELINE                             │
├─────────────────────────────────────────────────────────────────┤
│  Build → Test → Scan → Package → Deploy Dev → Deploy Prod      │
│    │        │      │       │           │            │          │
│    ▼        ▼      ▼       ▼           ▼            ▼          │
│  .NET   xUnit  SonarQube Docker    App Service  App Service    │
│                          ACR       (Dev slot)   (Prod + staging)│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       AZURE RESOURCES                           │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │ App Service │  │  Key Vault  │  │ App Insights│             │
│  │  (2 slots)  │  │  (secrets)  │  │ (monitoring)│             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   SQL DB    │  │     ACR     │  │    AKS      │             │
│  │             │  │  (images)   │  │ (optional)  │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Ressources Complémentaires

### Liens Officiels
- [Page officielle AZ-400](https://learn.microsoft.com/fr-fr/certifications/exams/az-400)
- [Azure DevOps Documentation](https://docs.microsoft.com/fr-fr/azure/devops/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Labs Gratuits
- [Azure DevOps Labs](https://azuredevopslabs.com/)
- [Microsoft Learn Sandboxes](https://learn.microsoft.com/fr-fr/training/)

### Outils à Installer
```
- Visual Studio Code
- Azure CLI
- Docker Desktop
- Git
- Bicep CLI
- Terraform (optional)
```

---

## Checklist Avant Examen

- [ ] Expérience pratique Azure DevOps (2+ projets)
- [ ] Tous les modules Microsoft Learn complétés
- [ ] 3+ examens blancs avec score > 80%
- [ ] Pipeline CI/CD complet implémenté
- [ ] IaC maîtrisé (Bicep ou Terraform)
- [ ] Sécurité DevSecOps comprise
- [ ] Examen programmé

---

## Suivi de Progression

| Semaine | Domaine | Statut | Score Quiz |
|---------|---------|--------|------------|
| 1 | Culture DevOps + Boards | [ ] À faire | /100 |
| 2 | Git avancé | [ ] À faire | /100 |
| 3 | Pipelines CI | [ ] À faire | /100 |
| 4 | Pipelines CD | [ ] À faire | /100 |
| 5 | Infrastructure as Code | [ ] À faire | /100 |
| 6 | Conteneurs + Artifacts | [ ] À faire | /100 |
| 7 | DevSecOps | [ ] À faire | /100 |
| 8 | Monitoring + Révision | [ ] À faire | /100 |

---

## Pourquoi AZ-400 est Parfait pour Toi

| Ton Profil | Avantage AZ-400 |
|------------|-----------------|
| 7 ans ASP.NET MVC | Pipelines .NET natifs |
| Chef de projet technique | Azure Boards + Agile |
| Mission EXTIA (DevOps/Cloud) | Compétences directement applicables |
| Objectif AKS | Module conteneurs inclus |

**Cette certification te positionne comme Expert DevOps Azure !**

---

*Dernière mise à jour : Novembre 2025*
*Préparé pour : Alpha Diallo*
*Prérequis : AZ-104 + expérience développement*
