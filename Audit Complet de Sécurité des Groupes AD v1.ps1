# Chargement du module Active Directory (si nécessaire)
Import-Module ActiveDirectory

# Dictionnaires pour optimiser la recherche et éviter les requêtes multiples
$VisitedGroups = @{}
$Report = @()  # Liste pour stocker toutes les informations du rapport

# Fonction principale pour explorer la hiérarchie des groupes avec détection des cycles
function Get-GroupHierarchy {
    param (
        [string]$GroupName,
        [int]$Level = 0, # Niveau d'indentation pour l'affichage
        [string]$ParentGroup = ""  # Groupe parent pour détecter les cycles
    )

    # Si le groupe est déjà visité dans cette branche, cela indique un cycle
    if ($VisitedGroups.ContainsKey("$ParentGroup|$GroupName")) {
        $Report += [PSCustomObject]@{
            Niveau        = $Level
            Groupe        = $GroupName
            Type          = "Cycle détecté"
            Description   = "Le groupe '$GroupName' crée une boucle avec le parent '$ParentGroup'"
        }
        return
    }

    # Marquer le groupe comme visité dans cette branche
    $VisitedGroups["$ParentGroup|$GroupName"] = $true

    # Récupérer le groupe actuel avec ses propriétés
    $group = Get-ADGroup -Identity $GroupName -Properties MemberOf, Members, GroupCategory, GroupScope
    if (!$group) {
        $Report += [PSCustomObject]@{
            Niveau        = $Level
            Groupe        = $GroupName
            Type          = "Erreur"
            Description   = "Le groupe '$GroupName' n'existe pas ou n'est pas accessible."
        }
        return
    }

    # Ajouter le groupe au rapport avec ses propriétés
    $Report += [PSCustomObject]@{
        Niveau        = $Level
        Groupe        = $group.Name
        Type          = "Groupe de sécurité"
        Description   = "Catégorie: $($group.GroupCategory), Portée: $($group.GroupScope)"
    }

    # Parcourir chaque membre du groupe
    foreach ($member in $group.Members) {
        # Récupérer les informations du membre
        $memberObject = Get-ADObject -Identity $member -Properties ObjectClass, Name, LastLogonDate, PasswordLastSet
        $memberType = $memberObject.ObjectClass

        if ($memberType -eq "group") {
            # Si le membre est un groupe, récursion pour lister sa hiérarchie
            Get-GroupHierarchy -GroupName $memberObject.Name -Level ($Level + 4) -ParentGroup $GroupName
        } elseif ($memberType -eq "user") {
            # Vérification de l’activité et sécurité de l’utilisateur
            $lastLogon = $memberObject.LastLogonDate
            $passwordLastSet = $memberObject.PasswordLastSet
            $isInactive = ($lastLogon -lt (Get-Date).AddDays(-90)) # Inactif si dernier logon > 90 jours

            $Report += [PSCustomObject]@{
                Niveau        = $Level + 4
                Groupe        = $GroupName
                Type          = "Utilisateur"
                Description   = "Nom: $($memberObject.Name), Dernier logon: $lastLogon, Mot de passe modifié: $passwordLastSet, Inactif: $isInactive"
            }
        }
    }

    # Vérification des groupes parents pour détecter les inclusions multiples
    if ($group.MemberOf) {
        $Report += [PSCustomObject]@{
            Niveau        = $Level + 4
            Groupe        = $GroupName
            Type          = "Membre de"
            Description   = "Groupes parents: $($group.MemberOf -join ', ')"
        }
    }

    # Nettoyage du groupe de la branche pour la détection des cycles
    $VisitedGroups.Remove("$ParentGroup|$GroupName")
}

# Fonction pour lancer l’audit complet des groupes de sécurité AD
function AuditAllGroups {
    $allGroups = Get-ADGroup -Filter 'Name -like "GG_*"' | Select-Object -ExpandProperty Name

    foreach ($groupName in $allGroups) {
        Write-Output "Analyse du groupe $groupName ..."
        Get-GroupHierarchy -GroupName $groupName
        Write-Output ""
    }
}

# Lancement de l’audit complet
Write-Output "Début de l’audit des groupes de sécurité AD..."
AuditAllGroups
Write-Output "Audit terminé."

# Exporter le rapport détaillé en fichier CSV
$Report | Export-Csv -Path "C:\AD_SecurityGroups_Audit_Report.csv" -NoTypeInformation -Encoding UTF8

# Résumé des problèmes détectés
Write-Output "---------------------------------------------"
Write-Output "Récapitulatif des problèmes détectés :"
$Report | Where-Object { $_.Type -like "*Cycle*" -or $_.Description -like "*Inactif*" } | Format-Table -AutoSize
