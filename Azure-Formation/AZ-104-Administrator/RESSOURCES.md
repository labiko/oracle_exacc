# Ressources AZ-104 - Azure Administrator

## Liens Officiels Microsoft

### Documentation
- [Page officielle AZ-104](https://learn.microsoft.com/fr-fr/certifications/exams/az-104)
- [Compétences mesurées](https://learn.microsoft.com/fr-fr/certifications/resources/study-guides/az-104)
- [Azure Documentation](https://docs.microsoft.com/fr-fr/azure/)

### Parcours d'Apprentissage (Gratuit)
1. [Prérequis pour les administrateurs Azure](https://learn.microsoft.com/fr-fr/training/paths/az-104-administrator-prerequisites/)
2. [Gérer les identités et la gouvernance](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-identities-governance/)
3. [Implémenter et gérer le stockage](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-storage/)
4. [Déployer et gérer les ressources de calcul](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-compute-resources/)
5. [Configurer et gérer les réseaux virtuels](https://learn.microsoft.com/fr-fr/training/paths/az-104-manage-virtual-networks/)
6. [Surveiller et sauvegarder les ressources](https://learn.microsoft.com/fr-fr/training/paths/az-104-monitor-backup-resources/)

---

## Examens Blancs

### Gratuits
- [Microsoft Learn - Practice Assessment](https://learn.microsoft.com/fr-fr/certifications/practice-assessments-for-microsoft-certifications)

### Payants (Recommandés)
| Plateforme | Prix | Qualité |
|------------|------|---------|
| [MeasureUp](https://www.measureup.com/az-104-microsoft-azure-administrator.html) | ~100€ | ⭐⭐⭐⭐⭐ (Officiel) |
| [Whizlabs](https://www.whizlabs.com/microsoft-azure-certification-az-104/) | ~30€ | ⭐⭐⭐⭐ |
| [Udemy Practice Tests](https://www.udemy.com/course/az-104-azure-administrator-practice-tests/) | ~15€ | ⭐⭐⭐ |

---

## Vidéos YouTube (Gratuites)

### En Français
- Rechercher "AZ-104 français" sur YouTube

### En Anglais (Excellente qualité)
- [John Savill's Technical Training](https://www.youtube.com/c/intikimsansazure) - Playlist AZ-104 complète
- [Adam Marczak - Azure for Everyone](https://www.youtube.com/c/AdamMarczakYT)
- [freeCodeCamp AZ-104 Full Course](https://www.youtube.com/watch?v=10PbGbTUSAg)

---

## Labs Pratiques

### Microsoft Learn Sandboxes (Gratuit)
Les modules Microsoft Learn incluent des sandboxes Azure gratuits pour pratiquer.

### Azure Free Account
```
URL : https://azure.microsoft.com/fr-fr/free/
Crédits : 200$ pendant 30 jours
Services gratuits : 12 mois pour certains services
```

### Labs GitHub
- [MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator](https://github.com/MicrosoftLearning/AZ-104-MicrosoftAzureAdministrator)

---

## Outils Indispensables

### Azure CLI - Commandes Fréquentes

```bash
# Connexion
az login

# Lister les abonnements
az account list --output table

# Changer d'abonnement
az account set --subscription "Nom ou ID"

# Créer un groupe de ressources
az group create --name RG-Formation --location westeurope

# Lister les ressources
az resource list --resource-group RG-Formation --output table

# Supprimer un groupe (et toutes ses ressources)
az group delete --name RG-Formation --yes --no-wait
```

### Azure PowerShell - Commandes Fréquentes

```powershell
# Connexion
Connect-AzAccount

# Lister les abonnements
Get-AzSubscription

# Changer de contexte
Set-AzContext -Subscription "Nom ou ID"

# Créer un groupe de ressources
New-AzResourceGroup -Name RG-Formation -Location westeurope

# Lister les VMs
Get-AzVM -ResourceGroupName RG-Formation

# Supprimer un groupe
Remove-AzResourceGroup -Name RG-Formation -Force
```

---

## Cheat Sheets

### Tailles de VM Communes
```
| Série | Usage | Exemple |
|-------|-------|---------|
| B | Burstable (dev/test) | B2s |
| D | General Purpose | D4s_v5 |
| E | Memory Optimized | E4s_v5 |
| F | Compute Optimized | F4s_v2 |
| N | GPU | NC6s_v3 |
```

### Types de Stockage
```
| Type | Latence | Durabilité | Usage |
|------|---------|------------|-------|
| Premium SSD | < 1ms | 99.9% | Production DB |
| Standard SSD | < 10ms | 99.9% | Web servers |
| Standard HDD | < 20ms | 99.9% | Backup, archive |
| Ultra Disk | < 0.5ms | 99.9% | SAP HANA, SQL |
```

### Réplication Stockage
```
| Type | Description | Durabilité |
|------|-------------|------------|
| LRS | Local (3 copies même datacenter) | 11 nines |
| ZRS | Zone (3 copies zones différentes) | 12 nines |
| GRS | Geo (6 copies 2 régions) | 16 nines |
| GZRS | Geo-Zone (meilleur) | 16 nines |
```

---

## Planning Révision Express (Dernière Semaine)

### J-7 : Identités et Gouvernance
- [ ] Azure AD : users, groups, devices
- [ ] RBAC : built-in roles, custom roles
- [ ] Azure Policy : definitions, assignments
- [ ] Management Groups

### J-6 : Stockage
- [ ] Storage accounts : types, tiers
- [ ] Blob storage : containers, access levels
- [ ] Azure Files : shares, sync
- [ ] SAS tokens, access keys

### J-5 : Compute
- [ ] VMs : sizes, disks, availability
- [ ] VMSS : scaling, update domains
- [ ] App Service : plans, slots
- [ ] Container Instances

### J-4 : Networking
- [ ] VNets : subnets, peering
- [ ] NSG : rules, ASG
- [ ] Load Balancer : SKUs, probes
- [ ] Application Gateway : WAF

### J-3 : Monitoring
- [ ] Azure Monitor : metrics, logs
- [ ] Log Analytics : KQL queries
- [ ] Alerts : action groups
- [ ] Diagnostics settings

### J-2 : Backup
- [ ] Recovery Services Vault
- [ ] VM Backup : policies
- [ ] Azure Site Recovery
- [ ] Soft delete

### J-1 : Examen Blanc Final
- [ ] Score > 80% ?
- [ ] Points faibles identifiés
- [ ] Dernières révisions
- [ ] Repos !

---

## Le Jour de l'Examen

### Avant
```
- Vérifier l'équipement (si examen en ligne)
- Pièce d'identité valide
- Arriver 15 min en avance
- Aller aux toilettes avant !
```

### Pendant
```
- 100 minutes pour 40-60 questions
- ~2 minutes par question max
- Marquer les questions difficiles
- Ne pas rester bloqué
- Relire avant de valider
```

### Après
```
- Résultat immédiat (Pass/Fail)
- Score détaillé par domaine
- Certificat sur Credly sous 24-48h
- Célébrer ! 🎉
```

---

*Bonne préparation !*
