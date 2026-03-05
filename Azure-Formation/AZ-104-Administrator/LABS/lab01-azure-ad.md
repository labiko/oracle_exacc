# LAB 01 : Gestion des Identités Azure AD

## Objectif
Créer et gérer des utilisateurs, groupes et configurer le Self-Service Password Reset.

## Prérequis
- Compte Azure avec abonnement actif
- Azure CLI installé
- Accès Azure Portal

---

## Partie 1 : Créer des Utilisateurs (Portal)

### Étapes

1. Aller sur [Azure Portal](https://portal.azure.com)
2. Rechercher "Azure Active Directory"
3. Cliquer sur "Utilisateurs" > "Nouvel utilisateur"
4. Créer les utilisateurs suivants :

| Nom | UPN | Rôle |
|-----|-----|------|
| Alice Martin | alice@tondomaine.onmicrosoft.com | User |
| Bob Dupont | bob@tondomaine.onmicrosoft.com | User |
| Carol Admin | carol@tondomaine.onmicrosoft.com | Global Admin |

### Notes
```
[Prends des notes ici pendant le lab]
```

---

## Partie 2 : Créer des Utilisateurs (Azure CLI)

```bash
# Se connecter
az login

# Créer un utilisateur
az ad user create \
  --display-name "David Test" \
  --user-principal-name david@tondomaine.onmicrosoft.com \
  --password "P@ssw0rd123!" \
  --force-change-password-next-sign-in true

# Vérifier
az ad user list --query "[].{Name:displayName, UPN:userPrincipalName}" --output table
```

### Résultat Attendu
```
Name          UPN
------------  ------------------------------------
Alice Martin  alice@tondomaine.onmicrosoft.com
Bob Dupont    bob@tondomaine.onmicrosoft.com
Carol Admin   carol@tondomaine.onmicrosoft.com
David Test    david@tondomaine.onmicrosoft.com
```

### Notes
```
[Prends des notes ici pendant le lab]
```

---

## Partie 3 : Créer des Groupes

### Via Portal
1. Azure AD > Groupes > Nouveau groupe
2. Créer les groupes :

| Nom | Type | Membres |
|-----|------|---------|
| GRP-Developers | Security | Alice, Bob |
| GRP-Admins | Security | Carol |
| GRP-AllUsers | Microsoft 365 | Tous |

### Via Azure CLI
```bash
# Créer un groupe de sécurité
az ad group create \
  --display-name "GRP-Developers" \
  --mail-nickname "developers"

# Obtenir l'ID du groupe
GROUP_ID=$(az ad group show --group "GRP-Developers" --query id -o tsv)

# Obtenir l'ID d'un utilisateur
USER_ID=$(az ad user show --id alice@tondomaine.onmicrosoft.com --query id -o tsv)

# Ajouter un membre
az ad group member add --group $GROUP_ID --member-id $USER_ID

# Vérifier les membres
az ad group member list --group "GRP-Developers" --query "[].displayName" -o tsv
```

### Notes
```
[Prends des notes ici pendant le lab]
```

---

## Partie 4 : Configurer SSPR (Self-Service Password Reset)

### Étapes
1. Azure AD > Réinitialisation de mot de passe
2. Activer SSPR pour "Tous" ou "Sélectionné" (GRP-AllUsers)
3. Configurer les méthodes d'authentification :
   - [ ] Email
   - [ ] Téléphone mobile
   - [ ] Questions de sécurité

4. Nombre de méthodes requises : 2

### Test
1. Se déconnecter
2. Aller sur https://aka.ms/sspr
3. Tester avec un utilisateur

### Notes
```
[Prends des notes ici pendant le lab]
```

---

## Partie 5 : Assigner des Rôles Azure AD

### Via Portal
1. Azure AD > Rôles et administrateurs
2. Chercher "User Administrator"
3. Ajouter Carol comme membre

### Via Azure CLI
```bash
# Lister les rôles disponibles
az ad role definition list --query "[].{Name:displayName, ID:id}" --output table

# Assigner un rôle (exemple : User Administrator)
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignments" \
  --headers "Content-Type=application/json" \
  --body '{
    "principalId": "USER_OBJECT_ID",
    "roleDefinitionId": "ROLE_ID",
    "directoryScopeId": "/"
  }'
```

### Notes
```
[Prends des notes ici pendant le lab]
```

---

## Partie 6 : Nettoyage

```bash
# Supprimer les utilisateurs de test
az ad user delete --id david@tondomaine.onmicrosoft.com

# Supprimer les groupes
az ad group delete --group "GRP-Developers"

# OU garder pour les prochains labs !
```

---

## Checklist de Validation

- [ ] 4 utilisateurs créés
- [ ] 3 groupes créés avec membres
- [ ] SSPR configuré et testé
- [ ] Rôle User Administrator assigné
- [ ] Compris la différence Azure AD roles vs Azure RBAC

---

## Questions de Révision

1. Quelle est la différence entre un groupe Security et Microsoft 365 ?
2. Combien de méthodes d'authentification minimum pour SSPR ?
3. Peut-on assigner des rôles Azure AD via Azure CLI ?
4. Qu'est-ce que le "User Administrator" peut faire ?

### Réponses
```
1. Security = accès ressources Azure, M365 = aussi email, Teams, SharePoint
2. 1 ou 2 (configurable)
3. Oui, via az rest ou Microsoft Graph
4. Créer/modifier/supprimer users et groups, reset passwords
```

---

## Temps Estimé
**1h30 - 2h**

---

*Lab terminé ? Passe au Lab 02 : RBAC et Gouvernance*
