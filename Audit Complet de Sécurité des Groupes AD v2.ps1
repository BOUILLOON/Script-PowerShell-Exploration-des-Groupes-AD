# Chargement du module Active Directory (si nécessaire)
Import-Module ActiveDirectory

# Dictionnaire pour éviter les cycles
$VisitedGroups = @{}
$Output = @()  # Liste pour stocker les informations de sortie

# Fonction principale pour obtenir la hiérarchie sous forme d’arbre
function Get-GroupHierarchy {
    param (
        [string]$GroupName,
        [int]$Level = 0,    # Niveau d'indentation pour affichage en arborescence
        [string]$ParentGroup = ""  # Groupe parent pour détecter les cycles
    )

    # Vérifier si le groupe a déjà été visité pour éviter les cycles
    if ($VisitedGroups.ContainsKey("$ParentGroup|$GroupName")) {
        $Output += (" " * $Level + "- [Cycle détecté] Groupe déjà traité : $GroupName")
        return
    }

    # Marquer le groupe comme visité
    $VisitedGroups["$ParentGroup|$GroupName"] = $true

    # Récupérer les informations du groupe
    $group = Get-ADGroup -Identity $GroupName -Properties MemberOf, Members, GroupCategory, GroupScope
    if (!$group) {
        $Output += (" " * $Level + "- [Erreur] Le groupe '$GroupName' n'existe pas ou n'est pas accessible.")
        return
    }

    # Ajouter le groupe à la sortie
    $Output += (" " * $Level + "- Groupe : " + $group.Name + " (Catégorie: $($group.GroupCategory), Portée: $($group.GroupScope))")

    # Traiter chaque membre du groupe
    foreach ($member in $group.Members) {
        $memberObject = Get-ADObject -Identity $member -Properties ObjectClass, Name, LastLogonDate, PasswordLastSet
        $memberType = $memberObject.ObjectClass

        if ($memberType -eq "group") {
            # Si le membre est un groupe, appel récursif
            Get-GroupHierarchy -GroupName $memberObject.Name -Level ($Level + 4) -ParentGroup $GroupName
        } elseif ($memberType -eq "user") {
            # Vérification de l'inactivité et ajout à la sortie
            $lastLogon = $memberObject.LastLogonDate
            $passwordLastSet = $memberObject.PasswordLastSet
            $isInactive = ($lastLogon -lt (Get-Date).AddDays(-90))

            $Output += (" " * ($Level + 4) + "- Utilisateur : $($memberObject.Name), Dernier logon: $lastLogon, Mot de passe modifié: $passwordLastSet, Inactif: $isInactive")
        }
    }

    # Afficher les groupes parents (appartenance)
    if ($group.MemberOf) {
        $Output += (" " * ($Level + 4) + "- Membre de :")
        foreach ($parentGroup in $group.MemberOf) {
            $Output += (" " * ($Level + 8) + "- " + (Get-ADGroup -Identity $parentGroup).Name)
        }
    }

    # Nettoyage du groupe de la branche pour la détection des cycles
    $VisitedGroups.Remove("$ParentGroup|$GroupName")
}

# Fonction d'audit pour chaque groupe
function AuditAllGroups {
    $allGroups = Get-ADGroup -Filter 'Name -like "GG_*"' | Select-Object -ExpandProperty Name

    foreach ($groupName in $allGroups) {
        $Output += "---------------------------------------------"
        $Output += "Arborescence et analyse pour le groupe $groupName :"
        Get-GroupHierarchy -GroupName $groupName
        $Output += "---------------------------------------------"
    }
}

# Lancer l'audit
Write-Output "Début de l'audit des groupes de sécurité AD..."
AuditAllGroups
Write-Output "Audit terminé."

# Affichage dans PowerShell sous forme d'arborescence
$Output | ForEach-Object { Write-Output $_ }

# Exporter dans un fichier texte
$Output | Out-File -FilePath "C:\AD_Group_Hierarchy_Audit_Report.txt" -Encoding UTF8

# Résumé des problèmes détectés pour une visualisation rapide
Write-Output "---------------------------------------------"
Write-Output "Récapitulatif des problèmes détectés :"
$Output | Where-Object { $_ -match "(Cycle détecté|Erreur|Inactif: True)" } | ForEach-Object { Write-Output $_ }
