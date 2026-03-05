# AZ-305 : Designing Microsoft Azure Infrastructure Solutions

## Informations Examen

| Information | Détail |
|-------------|--------|
| **Code** | AZ-305 |
| **Nom** | Designing Microsoft Azure Infrastructure Solutions |
| **Durée** | 100 minutes |
| **Questions** | 40-60 questions (dont études de cas) |
| **Score minimum** | 700/1000 |
| **Prix** | 165 EUR |
| **Langue** | Français disponible |
| **Validité** | 1 an (renouvellement gratuit en ligne) |
| **Prérequis** | AZ-104 fortement recommandé |

---

## Profil Cible

Cette certification est destinée aux :
- Architectes Solutions Azure
- Chefs de projet techniques (comme toi !)
- Consultants Cloud Senior
- Personnes avec expérience AZ-104

**Niveau** : Expert (conception, pas administration)

---

## Compétences Évaluées

| Domaine | Pourcentage |
|---------|-------------|
| Concevoir des solutions d'identité, de gouvernance et de surveillance | 25-30% |
| Concevoir des solutions de stockage de données | 20-25% |
| Concevoir des solutions de continuité d'activité | 10-15% |
| Concevoir des solutions d'infrastructure | 25-30% |

---

## Différence AZ-104 vs AZ-305

| Aspect | AZ-104 | AZ-305 |
|--------|--------|--------|
| **Focus** | Administration | Conception/Architecture |
| **Questions** | "Comment faire X ?" | "Quelle solution pour le besoin Y ?" |
| **Compétences** | Exécution technique | Prise de décision architecturale |
| **Études de cas** | Rares | Fréquentes (scénarios complexes) |

---

## Plan d'Étude - 8 Semaines

### Prérequis Recommandés
- [ ] AZ-104 réussi
- [ ] 6+ mois d'expérience pratique Azure
- [ ] Compréhension des patterns d'architecture cloud

---

### SEMAINE 1 : Architecture d'Identité

#### Objectifs
- [ ] Concevoir des solutions Azure AD
- [ ] Planifier l'authentification et l'autorisation
- [ ] Concevoir des solutions d'identité hybride
- [ ] Comprendre Azure AD B2B et B2C

#### Modules Microsoft Learn
1. [Concevoir des solutions d'identité et d'accès](https://learn.microsoft.com/fr-fr/training/paths/design-identity-governance-monitor-solutions/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Stratégies d'authentification | 1h30 | [ ] |
| Mardi | Module : Autorisation et RBAC avancé | 1h30 | [ ] |
| Mercredi | Module : Identité hybride (AD Connect) | 1h30 | [ ] |
| Jeudi | Module : Azure AD B2B / B2C | 1h30 | [ ] |
| Vendredi | Module : Privileged Identity Management | 1h30 | [ ] |
| Samedi | **ÉTUDE DE CAS** : Architecture identité | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Étude de Cas Semaine 1
```
SCÉNARIO : Entreprise Contoso
- 5000 employés répartis dans 3 pays
- Active Directory on-premises existant
- Applications SaaS multiples
- Besoin de SSO et MFA

QUESTIONS À RÉSOUDRE :
1. Quelle stratégie de synchronisation AD ?
2. Comment implémenter le SSO pour les apps SaaS ?
3. Quelle solution MFA recommander ?
4. Comment gérer les identités des partenaires externes ?

EXERCICE : Dessiner l'architecture complète
```

#### Patterns d'Architecture à Connaître
```
- Hub-and-Spoke Identity
- Conditional Access Policies
- Just-In-Time Access (PIM)
- Zero Trust Architecture
```

---

### SEMAINE 2 : Gouvernance et Monitoring

#### Objectifs
- [ ] Concevoir des solutions de gouvernance
- [ ] Planifier la gestion des coûts
- [ ] Concevoir des solutions de monitoring
- [ ] Implémenter Azure Lighthouse

#### Modules Microsoft Learn
1. [Concevoir des solutions de gouvernance](https://learn.microsoft.com/fr-fr/training/modules/design-governance/)
2. [Concevoir des solutions de monitoring](https://learn.microsoft.com/fr-fr/training/modules/design-solution-for-logging-monitoring/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Management Groups et hiérarchie | 1h30 | [ ] |
| Mardi | Module : Azure Policy à grande échelle | 1h30 | [ ] |
| Mercredi | Module : Cost Management et budgets | 1h30 | [ ] |
| Jeudi | Module : Azure Monitor architecture | 1h30 | [ ] |
| Vendredi | Module : Log Analytics et KQL | 1h30 | [ ] |
| Samedi | **ÉTUDE DE CAS** : Gouvernance multi-tenant | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Étude de Cas Semaine 2
```
SCÉNARIO : Groupe Fabrikam (holding)
- 10 filiales avec chacune 2-3 abonnements Azure
- Budget IT global à contrôler
- Compliance réglementaire (RGPD, ISO 27001)
- Besoin de reporting centralisé

QUESTIONS À RÉSOUDRE :
1. Comment structurer les Management Groups ?
2. Quelles policies appliquer à quel niveau ?
3. Comment centraliser le monitoring ?
4. Quelle stratégie de tagging pour les coûts ?

EXERCICE : Concevoir la hiérarchie de gouvernance
```

---

### SEMAINE 3 : Architecture de Stockage

#### Objectifs
- [ ] Concevoir des solutions de stockage de données
- [ ] Choisir le bon service de stockage
- [ ] Planifier la réplication et la DR
- [ ] Concevoir des solutions de données non-relationnelles

#### Modules Microsoft Learn
1. [Concevoir des solutions de stockage de données](https://learn.microsoft.com/fr-fr/training/paths/design-data-storage-solutions/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Choisir le stockage (Blob vs Files vs Disks) | 1h30 | [ ] |
| Mardi | Module : Stratégies de réplication | 1h30 | [ ] |
| Mercredi | Module : Azure Data Lake Storage | 1h30 | [ ] |
| Jeudi | Module : Cosmos DB architecture | 1h30 | [ ] |
| Vendredi | Module : Cache et CDN | 1h30 | [ ] |
| Samedi | **ÉTUDE DE CAS** : Architecture data | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Étude de Cas Semaine 3
```
SCÉNARIO : E-commerce GlobalShop
- 10 millions de produits
- 50 000 commandes/jour
- Besoin de recherche rapide
- Données analytiques (BI)
- Présence mondiale (latence faible)

QUESTIONS À RÉSOUDRE :
1. Stockage produits : SQL, Cosmos DB, ou Table Storage ?
2. Stockage images : Blob + CDN ou autre ?
3. Stockage commandes : SQL ou NoSQL ?
4. Comment gérer la réplication multi-région ?

EXERCICE : Concevoir l'architecture de données complète
```

#### Arbre de Décision Stockage
```
Données structurées ?
├── Oui → Relationnelles ?
│   ├── Oui → Azure SQL / SQL MI / PostgreSQL
│   └── Non → Cosmos DB / Table Storage
└── Non → Type de données ?
    ├── Fichiers → Azure Files / Blob
    ├── Messages → Service Bus / Event Hub
    └── Cache → Redis
```

---

### SEMAINE 4 : Bases de Données et Data

#### Objectifs
- [ ] Concevoir des solutions de données relationnelles
- [ ] Choisir entre SQL Database, SQL MI, SQL VM
- [ ] Planifier la haute disponibilité des BDD
- [ ] Concevoir des architectures data analytics

#### Modules Microsoft Learn
1. [Concevoir des solutions de données relationnelles](https://learn.microsoft.com/fr-fr/training/modules/design-data-storage-solution-for-relational-data/)
2. [Concevoir une solution d'intégration de données](https://learn.microsoft.com/fr-fr/training/modules/design-data-integration/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Azure SQL tiers et options | 1h30 | [ ] |
| Mardi | Module : SQL Managed Instance | 1h30 | [ ] |
| Mercredi | Module : HA/DR pour SQL | 1h30 | [ ] |
| Jeudi | Module : Azure Synapse Analytics | 1h30 | [ ] |
| Vendredi | Module : Data Factory et intégration | 1h30 | [ ] |
| Samedi | **ÉTUDE DE CAS** : Migration SQL | 3h | [ ] |
| Dimanche | Quiz + Notes + EXAMEN BLANC #1 | 2h | [ ] |

#### Étude de Cas Semaine 4
```
SCÉNARIO : Banque Woodgrove
- SQL Server 2016 on-premises (500 GB)
- 99.99% SLA requis
- Compliance PCI-DSS
- ETL quotidien vers Data Warehouse

QUESTIONS À RÉSOUDRE :
1. SQL Database, SQL MI, ou SQL sur VM ?
2. Comment atteindre 99.99% de disponibilité ?
3. Quelle stratégie de migration (online/offline) ?
4. Comment architecturer le Data Warehouse ?

EXERCICE : Plan de migration complet
```

---

### SEMAINE 5 : Continuité d'Activité (BCDR)

#### Objectifs
- [ ] Concevoir des solutions de sauvegarde
- [ ] Planifier la reprise après sinistre
- [ ] Définir RTO et RPO
- [ ] Implémenter Azure Site Recovery

#### Modules Microsoft Learn
1. [Concevoir des solutions de continuité d'activité](https://learn.microsoft.com/fr-fr/training/paths/design-business-continuity-solutions/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : RTO, RPO, SLA concepts | 1h30 | [ ] |
| Mardi | Module : Azure Backup architecture | 1h30 | [ ] |
| Mercredi | Module : Azure Site Recovery | 1h30 | [ ] |
| Jeudi | Module : DR multi-région | 1h30 | [ ] |
| Vendredi | Module : HA patterns (Active-Active, Active-Passive) | 1h30 | [ ] |
| Samedi | **ÉTUDE DE CAS** : Plan BCDR | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Étude de Cas Semaine 5
```
SCÉNARIO : Hôpital Lamna Health
- Application critique (dossiers patients)
- RTO = 1 heure, RPO = 15 minutes
- Budget limité
- Compliance HIPAA

QUESTIONS À RÉSOUDRE :
1. Quelle architecture HA (zones, régions) ?
2. Stratégie de backup (fréquence, rétention) ?
3. Comment tester le plan DR ?
4. Coût estimé de la solution ?

EXERCICE : Concevoir le plan BCDR complet
```

#### Tableau RTO/RPO
```
| Solution | RTO | RPO | Coût |
|----------|-----|-----|------|
| Backup seul | 24h | 24h | € |
| Backup + DR région secondaire | 4h | 1h | €€ |
| Active-Passive hot standby | 1h | 15min | €€€ |
| Active-Active multi-région | minutes | minutes | €€€€ |
```

---

### SEMAINE 6 : Architecture Compute

#### Objectifs
- [ ] Concevoir des solutions de calcul
- [ ] Choisir entre VM, App Service, AKS, Functions
- [ ] Concevoir pour la scalabilité
- [ ] Implémenter des conteneurs à grande échelle

#### Modules Microsoft Learn
1. [Concevoir des solutions de calcul](https://learn.microsoft.com/fr-fr/training/paths/design-infra-solutions/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Arbre de décision Compute | 1h30 | [ ] |
| Mardi | Module : VMs vs Containers vs Serverless | 1h30 | [ ] |
| Mercredi | Module : Azure Kubernetes Service (AKS) | 1h30 | [ ] |
| Jeudi | Module : Azure Functions architecture | 1h30 | [ ] |
| Vendredi | Module : Batch computing | 1h30 | [ ] |
| Samedi | **ÉTUDE DE CAS** : Migration conteneurs | 3h | [ ] |
| Dimanche | Quiz + Notes | 1h | [ ] |

#### Étude de Cas Semaine 6
```
SCÉNARIO : Startup TechFlow
- Application monolithique .NET (ton expertise !)
- 100K utilisateurs, pics x10 le week-end
- Besoin de déploiements fréquents (CI/CD)
- Budget : optimiser les coûts

QUESTIONS À RÉSOUDRE :
1. Garder monolithique ou migrer microservices ?
2. App Service vs AKS vs Container Apps ?
3. Comment gérer l'autoscaling ?
4. Stratégie de déploiement blue-green ?

EXERCICE : Architecture cible avec justification
```

#### Arbre de Décision Compute
```
Type de workload ?
├── Web App simple → App Service
├── API/Microservices → Container Apps / AKS
├── Event-driven → Azure Functions
├── Batch/HPC → Azure Batch
├── Legacy Windows → VM Scale Sets
└── Kubernetes expertise → AKS
```

---

### SEMAINE 7 : Architecture Réseau Avancée

#### Objectifs
- [ ] Concevoir des architectures réseau hybrides
- [ ] Implémenter Azure Front Door et Traffic Manager
- [ ] Concevoir des solutions de sécurité réseau
- [ ] Planifier la connectivité ExpressRoute/VPN

#### Modules Microsoft Learn
1. [Concevoir des solutions d'infrastructure réseau](https://learn.microsoft.com/fr-fr/training/modules/design-network-solutions/)

#### Pratique quotidienne

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Module : Hub-Spoke topology | 1h30 | [ ] |
| Mardi | Module : ExpressRoute vs VPN | 1h30 | [ ] |
| Mercredi | Module : Azure Firewall et WAF | 1h30 | [ ] |
| Jeudi | Module : Front Door et Traffic Manager | 1h30 | [ ] |
| Vendredi | Module : Private Link et endpoints | 1h30 | [ ] |
| Samedi | **ÉTUDE DE CAS** : Réseau hybride | 3h | [ ] |
| Dimanche | Quiz + Notes + EXAMEN BLANC #2 | 2h | [ ] |

#### Étude de Cas Semaine 7
```
SCÉNARIO : Entreprise Adatum (hybride)
- Datacenter Paris + Datacenter Londres
- 500 serveurs on-premises
- Migration progressive vers Azure
- Latence < 10ms requise entre sites

QUESTIONS À RÉSOUDRE :
1. ExpressRoute ou VPN S2S ?
2. Architecture Hub-Spoke ou Virtual WAN ?
3. Comment sécuriser le trafic (Firewall, NSG) ?
4. Stratégie DNS hybride ?

EXERCICE : Diagramme réseau complet
```

#### Patterns Réseau Azure
```
1. Hub-and-Spoke
   - Hub central avec services partagés
   - Spokes pour workloads isolés
   - Peering VNet bidirectionnel

2. Azure Virtual WAN
   - Connectivité globale simplifiée
   - Routing automatique
   - Intégration native ExpressRoute/VPN

3. Private Endpoints
   - Accès privé aux services PaaS
   - Élimination de l'exposition Internet
```

---

### SEMAINE 8 : Révision et Études de Cas Complètes

#### Objectifs
- [ ] Maîtriser les études de cas complexes
- [ ] Réviser les points faibles
- [ ] Réussir les examens blancs
- [ ] Passer l'examen

#### Programme Final

| Jour | Activité | Durée | Statut |
|------|----------|-------|--------|
| Lundi | Étude de cas complète #1 | 2h | [ ] |
| Mardi | Étude de cas complète #2 | 2h | [ ] |
| Mercredi | Révision : Identité + Gouvernance | 2h | [ ] |
| Jeudi | Révision : Stockage + BCDR | 2h | [ ] |
| Vendredi | **EXAMEN BLANC #3** | 2h | [ ] |
| Samedi | Révision points faibles | 3h | [ ] |
| Dimanche | **EXAMEN AZ-305** | - | [ ] |

#### Étude de Cas Finale #1
```
SCÉNARIO COMPLET : Tailwind Traders (retail)

CONTEXTE :
- 500 magasins physiques
- Site e-commerce (5M visiteurs/mois)
- ERP SAP on-premises
- Expansion internationale prévue

EXIGENCES :
1. Identité : SSO pour 10K employés + clients B2C
2. Stockage : 50TB de données produits + images
3. Compute : Site web haute disponibilité mondial
4. Réseau : Connexion sécurisée vers SAP
5. BCDR : RTO 2h, RPO 30min

LIVRABLE : Architecture complète avec justification
```

#### Étude de Cas Finale #2
```
SCÉNARIO COMPLET : Relecloud (SaaS)

CONTEXTE :
- Application SaaS multi-tenant
- 200 clients entreprises
- API REST + WebSocket temps réel
- Compliance SOC2, RGPD

EXIGENCES :
1. Isolation des données par tenant
2. Scalabilité de 1K à 1M utilisateurs
3. CI/CD avec zero-downtime deployment
4. Monitoring et alerting avancé
5. Coûts optimisés (pay-per-use)

LIVRABLE : Architecture complète avec diagrammes
```

---

## Méthodologie Études de Cas

### Étape 1 : Analyser les Exigences
```
- Business requirements
- Technical requirements
- Constraints (budget, compliance, temps)
- Current state vs Target state
```

### Étape 2 : Identifier les Composants
```
- Identity & Access
- Compute
- Storage
- Networking
- Security
- Monitoring
- BCDR
```

### Étape 3 : Concevoir la Solution
```
- Diagramme d'architecture
- Justification des choix
- Alternatives considérées
- Estimation des coûts
```

### Étape 4 : Valider
```
- Répond aux exigences ?
- Respecte les contraintes ?
- Solution optimale ou over-engineered ?
```

---

## Ressources Complémentaires

### Liens Officiels
- [Page officielle AZ-305](https://learn.microsoft.com/fr-fr/certifications/exams/az-305)
- [Azure Architecture Center](https://docs.microsoft.com/fr-fr/azure/architecture/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/fr-fr/azure/architecture/framework/)

### Outils de Diagramme
- [Azure Architecture Icons](https://docs.microsoft.com/en-us/azure/architecture/icons/)
- [Draw.io](https://draw.io) avec stencils Azure
- [Visio Online](https://www.microsoft.com/fr-fr/microsoft-365/visio/)

---

## Checklist Avant Examen

- [ ] AZ-104 réussi
- [ ] Tous les modules Microsoft Learn complétés
- [ ] 3+ examens blancs avec score > 80%
- [ ] Études de cas maîtrisées
- [ ] Well-Architected Framework compris
- [ ] Examen programmé

---

## Suivi de Progression

| Semaine | Domaine | Statut | Score Quiz |
|---------|---------|--------|------------|
| 1 | Architecture Identité | [ ] À faire | /100 |
| 2 | Gouvernance et Monitoring | [ ] À faire | /100 |
| 3 | Architecture Stockage | [ ] À faire | /100 |
| 4 | Bases de Données | [ ] À faire | /100 |
| 5 | Continuité d'Activité | [ ] À faire | /100 |
| 6 | Architecture Compute | [ ] À faire | /100 |
| 7 | Architecture Réseau | [ ] À faire | /100 |
| 8 | Révision Finale | [ ] À faire | /100 |

---

*Dernière mise à jour : Novembre 2025*
*Préparé pour : Alpha Diallo*
*Prérequis : AZ-104 réussi*
