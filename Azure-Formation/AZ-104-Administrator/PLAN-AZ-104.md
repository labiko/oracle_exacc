# AZ-104 : Microsoft Azure Administrator

## Informations Examen

| Information | Détail |
|-------------|--------|
| **Code** | AZ-104 |
| **Nom** | Microsoft Azure Administrator |
| **Durée** | 100 minutes |
| **Questions** | 40-60 questions |
| **Score minimum** | 700/1000 |
| **Prix** | 165 EUR |
| **Langue** | Français disponible |
| **Validité** | 1 an (renouvellement gratuit en ligne) |
| **Prérequis** | Aucun (AZ-900 recommandé) |

---

## Liens Essentiels - COMMENCER ICI

### Créer tes Comptes (Gratuit)

| Étape | Action | Lien |
|-------|--------|------|
| 1 | **Créer compte Microsoft Learn** | [S'inscrire](https://learn.microsoft.com/fr-fr/) |
| 2 | **Créer compte Azure gratuit** | [Azure Free](https://azure.microsoft.com/fr-fr/free/) |
| 3 | **Créer compte Pearson VUE** | [Pearson VUE](https://home.pearsonvue.com/microsoft) |

### Parcours Officiel Microsoft Learn (Français - Gratuit)

| Module | Lien Direct | Durée |
|--------|-------------|-------|
| **Prérequis** | [Prérequis pour les administrateurs Azure](https://learn.microsoft.com/fr-fr/training/paths/az-104-administrator-prerequisites/) | 6h |
| **Module 1** | [Gérer les identités et la gouvernance](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-identities-governance/) | 7h |
| **Module 2** | [Implémenter et gérer le stockage](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-storage/) | 5h |
| **Module 3** | [Déployer et gérer les ressources de calcul](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-compute-resources/) | 10h |
| **Module 4** | [Configurer et gérer les réseaux virtuels](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-virtual-networks/) | 9h |
| **Module 5** | [Surveiller et sauvegarder les ressources](https://learn.microsoft.com/fr-fr/training/paths/az-104-monitor-backup-resources/) | 5h |

**Durée totale : ~42 heures de formation**

### Autres Ressources Importantes

| Ressource | Lien |
|-----------|------|
| **Page officielle examen AZ-104** | [Microsoft Learn](https://learn.microsoft.com/fr-fr/certifications/exams/az-104) |
| **Examen blanc GRATUIT** | [Practice Assessment](https://learn.microsoft.com/fr-fr/certifications/practice-assessments-for-microsoft-certifications) |
| **Labs pratiques GitHub** | [AZ-104 Labs](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/) |
| **Documentation Azure** | [Docs Azure FR](https://learn.microsoft.com/fr-fr/azure/) |
| **Programmer l'examen** | [Inscription examen](https://examregistration.microsoft.com/) |

---

## Compétences Évaluées

| Domaine | Pourcentage |
|---------|-------------|
| Gérer les identités et la gouvernance Azure | 15-20% |
| Implémenter et gérer le stockage | 15-20% |
| Déployer et gérer les ressources de calcul Azure | 20-25% |
| Configurer et gérer les réseaux virtuels | 20-25% |
| Surveiller et sauvegarder les ressources Azure | 10-15% |

---

## Plan d'Étude - 8 Semaines

### SEMAINE 0 : Prérequis (Avant de commencer)

#### À faire MAINTENANT

- [ ] Créer compte Microsoft Learn : https://learn.microsoft.com/fr-fr/
- [ ] Créer compte Azure gratuit : https://azure.microsoft.com/fr-fr/free/
- [ ] Installer Azure CLI : `winget install Microsoft.AzureCLI`
- [ ] Suivre le module prérequis

#### Module Prérequis
🔗 **Lien** : [Prérequis pour les administrateurs Azure](https://learn.microsoft.com/fr-fr/training/paths/az-104-administrator-prerequisites/)

| Sous-module | Lien | Durée |
|-------------|------|-------|
| Configurer les ressources Azure avec des outils | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-resources-tools/) | 1h |
| Utiliser Azure Resource Manager | [Lien](https://learn.microsoft.com/fr-fr/training/modules/use-azure-resource-manager/) | 1h |
| Configurer les ressources avec des modèles ARM | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-resources-arm-templates/) | 1h |
| Automatiser les tâches Azure avec PowerShell | [Lien](https://learn.microsoft.com/fr-fr/training/modules/automate-azure-tasks-with-powershell/) | 1h30 |
| Contrôler les services Azure avec CLI | [Lien](https://learn.microsoft.com/fr-fr/training/modules/control-azure-services-with-cli/) | 1h30 |

---

### SEMAINE 1 : Identités Azure AD (Partie 1)

#### 🔗 Parcours Complet
[Gérer les identités et la gouvernance Azure](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-identities-governance/)

#### Objectifs
- [ ] Comprendre Azure Active Directory
- [ ] Créer et gérer des utilisateurs
- [ ] Créer et gérer des groupes
- [ ] Configurer le self-service password reset

#### Modules Détaillés

| Module | Lien | Durée |
|--------|------|-------|
| Configurer Microsoft Entra ID | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-active-directory/) | 45min |
| Configurer les comptes d'utilisateurs | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-user-group-accounts/) | 45min |
| Configurer les abonnements | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-subscriptions/) | 30min |
| Configurer Azure Policy | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-policy/) | 45min |
| Configurer RBAC | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-role-based-access-control/) | 45min |

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Configurer Azure AD | 1h30 | [ ] |
| Mardi | Module : Configurer les comptes utilisateur | 1h30 | [ ] |
| Mercredi | Module : Configurer les groupes | 1h30 | [ ] |
| Jeudi | Module : Configurer Azure AD Identity Protection | 1h30 | [ ] |
| Vendredi | Révision semaine | 1h | [ ] |
| Samedi | **LAB PRATIQUE** : Créer users, groupes, SSPR | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Labs Pratiques Semaine 1

🔗 **Lab officiel** : [Lab 01 - Manage Microsoft Entra ID Identities](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_01-Manage_Entra_ID_Identities.html)

```
LAB 01: Gérer les identités Azure AD
- Créer un tenant Azure AD (si pas existant)
- Créer 5 utilisateurs test
- Créer 3 groupes (Admins, Developers, Users)
- Assigner les utilisateurs aux groupes
- Configurer SSPR pour le groupe Users
```

#### Notes personnelles
```
[Espace pour tes notes]
```

---

### SEMAINE 2 : Gouvernance et RBAC

#### 🔗 Parcours
Continuation de [Gérer les identités et la gouvernance Azure](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-identities-governance/)

#### Objectifs
- [ ] Comprendre les abonnements Azure
- [ ] Configurer RBAC (Role-Based Access Control)
- [ ] Créer des stratégies Azure (Policies)
- [ ] Utiliser les blueprints

#### Modules Détaillés

| Module | Lien | Durée |
|--------|------|-------|
| Configurer les abonnements | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-subscriptions/) | 30min |
| Configurer Azure Policy | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-policy/) | 45min |
| Configurer RBAC | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-role-based-access-control/) | 45min |

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Abonnements et groupes de gestion | 1h30 | [ ] |
| Mardi | Module : RBAC - Rôles intégrés | 1h30 | [ ] |
| Mercredi | Module : RBAC - Rôles personnalisés | 1h30 | [ ] |
| Jeudi | Module : Azure Policy | 1h30 | [ ] |
| Vendredi | Révision semaine | 1h | [ ] |
| Samedi | **LAB PRATIQUE** : RBAC + Policies | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Labs Pratiques Semaine 2

🔗 **Lab officiel** : [Lab 02a - Manage Subscriptions and RBAC](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_02a_Manage_Subscriptions_and_RBAC.html)

🔗 **Lab officiel** : [Lab 02b - Manage Governance via Azure Policy](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_02b-Manage_Governance_via_Azure_Policy.html)

```
LAB 02: Gérer les abonnements et RBAC
- Créer un groupe de ressources "RG-Formation"
- Assigner le rôle "Contributor" à un utilisateur
- Créer un rôle personnalisé "VM Operator"
- Créer une Policy "Require tag on resources"
- Tester les restrictions
```

#### Commandes Azure CLI importantes
```bash
# Lister les rôles
az role definition list --output table

# Assigner un rôle
az role assignment create --assignee user@domain.com \
  --role "Contributor" \
  --resource-group RG-Formation

# Créer une policy
az policy definition create --name 'require-tag' \
  --display-name 'Require Tag' \
  --rules policy-rules.json
```

---

### SEMAINE 3 : Stockage Azure (Partie 1)

#### 🔗 Parcours Complet
[Implémenter et gérer le stockage Azure](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-storage/)

#### Objectifs
- [ ] Créer des comptes de stockage
- [ ] Configurer la réplication (LRS, GRS, ZRS)
- [ ] Gérer le stockage Blob
- [ ] Comprendre les niveaux d'accès (Hot, Cool, Archive)

#### Modules Détaillés

| Module | Lien | Durée |
|--------|------|-------|
| Configurer les comptes de stockage | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-storage-accounts/) | 45min |
| Configurer le stockage Blob | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-blob-storage/) | 45min |
| Configurer la sécurité du stockage | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-storage-security/) | 45min |

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Types de comptes de stockage | 1h30 | [ ] |
| Mardi | Module : Réplication et redondance | 1h30 | [ ] |
| Mercredi | Module : Stockage Blob - Conteneurs | 1h30 | [ ] |
| Jeudi | Module : Niveaux d'accès et lifecycle | 1h30 | [ ] |
| Vendredi | Révision semaine | 1h | [ ] |
| Samedi | **LAB PRATIQUE** : Créer stockage + Blob | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Labs Pratiques Semaine 3

🔗 **Lab officiel** : [Lab 07 - Manage Azure Storage](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_07-Manage_Azure_Storage.html)

```
LAB 03: Stockage Azure
- Créer un compte de stockage Standard_LRS
- Créer un compte de stockage Premium
- Créer 3 conteneurs Blob (public, private, logs)
- Uploader des fichiers
- Configurer lifecycle management (Hot → Cool après 30 jours)
- Tester les niveaux d'accès
```

#### Commandes Azure CLI importantes
```bash
# Créer un compte de stockage
az storage account create \
  --name stformationalpha \
  --resource-group RG-Formation \
  --location westeurope \
  --sku Standard_LRS

# Créer un conteneur
az storage container create \
  --name documents \
  --account-name stformationalpha

# Uploader un fichier
az storage blob upload \
  --account-name stformationalpha \
  --container-name documents \
  --name test.txt \
  --file ./test.txt
```

---

### SEMAINE 4 : Stockage Azure (Partie 2)

#### Objectifs
- [ ] Configurer Azure Files
- [ ] Comprendre les SAS tokens
- [ ] Configurer la sécurité du stockage
- [ ] Utiliser Azure Storage Explorer

#### Modules Détaillés

| Module | Lien | Durée |
|--------|------|-------|
| Configurer Azure Files | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-files-file-sync/) | 45min |
| Configurer la sécurité du stockage | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-storage-security/) | 45min |

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Azure Files - Partages | 1h30 | [ ] |
| Mardi | Module : Azure File Sync | 1h30 | [ ] |
| Mercredi | Module : SAS tokens et clés d'accès | 1h30 | [ ] |
| Jeudi | Module : Chiffrement et sécurité réseau | 1h30 | [ ] |
| Vendredi | Révision semaine | 1h | [ ] |
| Samedi | **LAB PRATIQUE** : Files + SAS + Sécurité | 3h | [ ] |
| Dimanche | Quiz + Notes + EXAMEN BLANC #1 | 2h | [ ] |

#### Labs Pratiques Semaine 4
```
LAB 04: Azure Files et Sécurité
- Créer un partage Azure Files
- Monter le partage sur Windows (net use)
- Générer un SAS token avec expiration 24h
- Tester l'accès avec SAS
- Configurer le firewall du compte de stockage
- Activer le chiffrement avec clé gérée client
```

#### 📝 EXAMEN BLANC #1
🔗 [Practice Assessment AZ-104](https://learn.microsoft.com/fr-fr/certifications/practice-assessments-for-microsoft-certifications)

---

### SEMAINE 5 : Machines Virtuelles Azure

#### 🔗 Parcours Complet
[Déployer et gérer les ressources de calcul Azure](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-compute-resources/)

#### Objectifs
- [ ] Créer et configurer des VMs
- [ ] Gérer les disques (OS, Data, Temp)
- [ ] Configurer la haute disponibilité
- [ ] Utiliser les VM Scale Sets

#### Modules Détaillés

| Module | Lien | Durée |
|--------|------|-------|
| Configurer les machines virtuelles | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-virtual-machines/) | 1h |
| Configurer la disponibilité des VMs | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-virtual-machine-availability/) | 45min |
| Configurer Azure App Service | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-app-services/) | 45min |
| Configurer Azure Container Instances | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-container-instances/) | 30min |

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Créer une VM (Portal + CLI) | 1h30 | [ ] |
| Mardi | Module : Tailles de VM et familles | 1h30 | [ ] |
| Mercredi | Module : Disques managés | 1h30 | [ ] |
| Jeudi | Module : Availability Sets et Zones | 1h30 | [ ] |
| Vendredi | Module : VM Scale Sets | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : Déployer infrastructure VM | 4h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Labs Pratiques Semaine 5

🔗 **Lab officiel** : [Lab 08 - Manage Virtual Machines](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_08-Manage_Virtual_Machines.html)

```
LAB 05: Machines Virtuelles
- Créer une VM Windows Server 2022
- Créer une VM Ubuntu 22.04
- Ajouter un disque de données à chaque VM
- Créer un Availability Set avec 2 VMs
- Créer un VM Scale Set (2-5 instances)
- Configurer l'autoscaling basé sur CPU
- Se connecter en RDP/SSH
```

#### Commandes Azure CLI importantes
```bash
# Créer une VM Windows
az vm create \
  --resource-group RG-Formation \
  --name VM-Windows \
  --image Win2022AzureEditionCore \
  --admin-username azureuser \
  --admin-password 'P@ssw0rd123!'

# Créer une VM Linux
az vm create \
  --resource-group RG-Formation \
  --name VM-Linux \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys

# Ajouter un disque
az vm disk attach \
  --resource-group RG-Formation \
  --vm-name VM-Windows \
  --name DataDisk1 \
  --size-gb 128 \
  --new
```

---

### SEMAINE 6 : Réseaux Virtuels Azure

#### 🔗 Parcours Complet
[Configurer et gérer les réseaux virtuels Azure](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-virtual-networks/)

#### Objectifs
- [ ] Créer des VNets et sous-réseaux
- [ ] Configurer les NSG (Network Security Groups)
- [ ] Implémenter le VNet Peering
- [ ] Configurer Azure DNS

#### Modules Détaillés

| Module | Lien | Durée |
|--------|------|-------|
| Configurer les réseaux virtuels | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-virtual-networks/) | 45min |
| Configurer les NSG | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-network-security-groups/) | 45min |
| Configurer Azure Firewall | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-firewall/) | 30min |
| Configurer Azure DNS | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-dns/) | 30min |
| Configurer le peering VNet | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-vnet-peering/) | 30min |

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : VNets, sous-réseaux, CIDR | 1h30 | [ ] |
| Mardi | Module : NSG - Règles entrantes/sortantes | 1h30 | [ ] |
| Mercredi | Module : VNet Peering | 1h30 | [ ] |
| Jeudi | Module : Azure DNS public et privé | 1h30 | [ ] |
| Vendredi | Module : Service Endpoints | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : Architecture réseau complète | 4h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Labs Pratiques Semaine 6

🔗 **Lab officiel** : [Lab 04 - Configure Virtual Networking](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_04-Implement_Virtual_Networking.html)

🔗 **Lab officiel** : [Lab 05 - Implement Intersite Connectivity](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_05-Implement_Intersite_Connectivity.html)

```
LAB 06: Réseaux Virtuels
- Créer VNet-Hub (10.0.0.0/16) avec 2 sous-réseaux
- Créer VNet-Spoke (10.1.0.0/16) avec 2 sous-réseaux
- Configurer VNet Peering bidirectionnel
- Créer NSG pour autoriser RDP/SSH uniquement
- Créer une zone DNS privée
- Lier la zone DNS aux VNets
- Tester la résolution DNS entre VMs
```

#### Commandes Azure CLI importantes
```bash
# Créer un VNet
az network vnet create \
  --resource-group RG-Formation \
  --name VNet-Hub \
  --address-prefix 10.0.0.0/16 \
  --subnet-name Subnet-Web \
  --subnet-prefix 10.0.1.0/24

# Créer un NSG
az network nsg create \
  --resource-group RG-Formation \
  --name NSG-Web

# Ajouter une règle NSG
az network nsg rule create \
  --resource-group RG-Formation \
  --nsg-name NSG-Web \
  --name Allow-HTTP \
  --priority 100 \
  --destination-port-ranges 80 443 \
  --access Allow
```

---

### SEMAINE 7 : Load Balancing et App Service

#### Objectifs
- [ ] Configurer Azure Load Balancer
- [ ] Configurer Application Gateway
- [ ] Déployer Azure App Service
- [ ] Comprendre les slots de déploiement

#### Modules Détaillés

| Module | Lien | Durée |
|--------|------|-------|
| Configurer Azure Load Balancer | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-load-balancer/) | 45min |
| Configurer Azure Application Gateway | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-application-gateway/) | 45min |
| Configurer Azure App Service | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-app-services/) | 45min |
| Configurer Azure App Service Plans | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-app-service-plans/) | 30min |

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Load Balancer (L4) | 1h30 | [ ] |
| Mardi | Module : Application Gateway (L7) | 1h30 | [ ] |
| Mercredi | Module : App Service Plans | 1h30 | [ ] |
| Jeudi | Module : App Service - Déploiement | 1h30 | [ ] |
| Vendredi | Module : Slots et Traffic Manager | 1h30 | [ ] |
| Samedi | **LAB PRATIQUE** : LB + App Service | 4h | [ ] |
| Dimanche | Quiz + Notes + EXAMEN BLANC #2 | 2h | [ ] |

#### Labs Pratiques Semaine 7

🔗 **Lab officiel** : [Lab 06 - Implement Traffic Management](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_06-Implement_Network_Traffic_Management.html)

🔗 **Lab officiel** : [Lab 09a - Implement Web Apps](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_09a-Implement_Web_Apps.html)

```
LAB 07: Load Balancing et App Service
- Créer 2 VMs avec IIS/Nginx
- Créer un Load Balancer Standard
- Configurer le backend pool avec les 2 VMs
- Créer une health probe HTTP
- Tester le load balancing

- Créer un App Service Plan (Standard S1)
- Déployer une Web App
- Créer un slot "staging"
- Déployer une nouvelle version sur staging
- Effectuer un swap staging ↔ production
```

#### 📝 EXAMEN BLANC #2
🔗 [Practice Assessment AZ-104](https://learn.microsoft.com/fr-fr/certifications/practice-assessments-for-microsoft-certifications)

---

### SEMAINE 8 : Monitoring, Backup et Révision Finale

#### 🔗 Parcours Complet
[Surveiller et sauvegarder les ressources Azure](https://learn.microsoft.com/fr-fr/training/paths/az-104-monitor-backup-resources/)

#### Objectifs
- [ ] Configurer Azure Monitor
- [ ] Créer des alertes
- [ ] Configurer Azure Backup
- [ ] Réussir les examens blancs

#### Modules Détaillés

| Module | Lien | Durée |
|--------|------|-------|
| Configurer Azure Monitor | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-monitor/) | 45min |
| Configurer Log Analytics | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-log-analytics/) | 30min |
| Configurer Azure Alerts | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-azure-alerts/) | 30min |
| Configurer Azure Backup | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-file-folder-backups/) | 45min |
| Configurer la récupération des VMs | [Lien](https://learn.microsoft.com/fr-fr/training/modules/configure-virtual-machine-backups/) | 45min |

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Azure Monitor et métriques | 1h30 | [ ] |
| Mardi | Module : Log Analytics | 1h30 | [ ] |
| Mercredi | Module : Alertes et Action Groups | 1h30 | [ ] |
| Jeudi | Module : Azure Backup | 1h30 | [ ] |
| Vendredi | **EXAMEN BLANC #3** | 2h | [ ] |
| Samedi | Révision points faibles | 3h | [ ] |
| Dimanche | **EXAMEN AZ-104** | - | [ ] |

#### Labs Pratiques Semaine 8

🔗 **Lab officiel** : [Lab 11 - Implement Monitoring](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_11-Implement_Monitoring.html)

🔗 **Lab officiel** : [Lab 10 - Backup Virtual Machines](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/Instructions/Labs/LAB_10-Implement_Data_Protection.html)

```
LAB 08: Monitoring et Backup
- Activer les diagnostics sur les VMs
- Créer un workspace Log Analytics
- Écrire une requête KQL simple
- Créer une alerte CPU > 80%
- Configurer un Action Group (email)

- Créer un Recovery Services Vault
- Configurer la sauvegarde des VMs
- Exécuter une sauvegarde manuelle
- Tester une restauration de fichier
```

#### 📝 EXAMEN BLANC #3
🔗 [Practice Assessment AZ-104](https://learn.microsoft.com/fr-fr/certifications/practice-assessments-for-microsoft-certifications)

---

## Ressources Complémentaires

### Liens Officiels (Français)

| Ressource | Lien |
|-----------|------|
| **Page officielle AZ-104** | [Microsoft Learn](https://learn.microsoft.com/fr-fr/certifications/exams/az-104) |
| **Parcours d'apprentissage complet** | [Learning Path](https://learn.microsoft.com/fr-fr/training/paths/az-104-administrator-prerequisites/) |
| **Documentation Azure** | [Docs Azure](https://learn.microsoft.com/fr-fr/azure/) |
| **Calculateur de prix Azure** | [Azure Calculator](https://azure.microsoft.com/fr-fr/pricing/calculator/) |

### Examens Blancs

| Ressource | Lien | Coût |
|-----------|------|------|
| **Microsoft Learn** | [Practice Assessment](https://learn.microsoft.com/fr-fr/certifications/practice-assessments-for-microsoft-certifications) | Gratuit |
| **MeasureUp** (officiel) | [MeasureUp](https://www.measureup.com/az-104-microsoft-azure-administrator.html) | ~100€ |
| **Whizlabs** | [Whizlabs](https://www.whizlabs.com/microsoft-azure-certification-az-104/) | ~30€ |

### Labs Pratiques

| Ressource | Lien |
|-----------|------|
| **Labs GitHub officiels** | [AZ-104 Labs](https://microsoftlearning.github.io/AZ-104-MicrosoftAzureAdministrator/) |
| **Azure Free Account** | [200$ crédits](https://azure.microsoft.com/fr-fr/free/) |

### Vidéos (Bonus)

| Chaîne | Contenu | Langue |
|--------|---------|--------|
| Microsoft France | Webinaires Azure | Français |
| John Savill | Cours AZ-104 complet | Anglais |
| Adam Marczak | Azure for Everyone | Anglais |

---

## Checklist Avant Examen

- [ ] Tous les modules Microsoft Learn complétés
- [ ] 3+ examens blancs avec score > 80%
- [ ] Labs pratiques tous réalisés
- [ ] Notes personnelles relues
- [ ] Compte Pearson VUE créé
- [ ] Examen programmé
- [ ] Environnement de test préparé (si en ligne)

---

## Suivi de Progression

| Semaine | Domaine | Statut | Score Quiz |
|---------|---------|--------|------------|
| 0 | Prérequis | [ ] À faire | /100 |
| 1 | Identités Azure AD | [ ] À faire | /100 |
| 2 | Gouvernance et RBAC | [ ] À faire | /100 |
| 3 | Stockage (Partie 1) | [ ] À faire | /100 |
| 4 | Stockage (Partie 2) | [ ] À faire | /100 |
| 5 | Machines Virtuelles | [ ] À faire | /100 |
| 6 | Réseaux Virtuels | [ ] À faire | /100 |
| 7 | Load Balancing & App Service | [ ] À faire | /100 |
| 8 | Monitoring & Backup | [ ] À faire | /100 |

**Examens Blancs**

| Examen | Date | Score | Objectif |
|--------|------|-------|----------|
| Examen Blanc #1 | | /1000 | >700 |
| Examen Blanc #2 | | /1000 | >750 |
| Examen Blanc #3 | | /1000 | >800 |
| **EXAMEN FINAL** | | /1000 | **>700** |

---

## Programmer l'Examen

1. **Créer compte Pearson VUE** : https://home.pearsonvue.com/microsoft
2. **Choisir l'examen** : AZ-104
3. **Choisir la langue** : Français
4. **Choisir le lieu** : Centre d'examen OU en ligne depuis chez toi
5. **Prix** : 165€ (parfois promos -50%)

---

*Dernière mise à jour : Novembre 2025*
*Préparé pour : Alpha Diallo*
*Tous les liens sont en français*
