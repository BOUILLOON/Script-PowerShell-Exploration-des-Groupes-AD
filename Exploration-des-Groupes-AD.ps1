# Fonction récursive pour afficher les groupes et les membres
function Get-GroupHierarchy {
    param (
        [string]$GroupName,
        [int]$Level = 0  # Pour définir l'indentation
    )

    # Récupère le groupe en cours
    $group = Get-ADGroup -Identity $GroupName -Properties MemberOf, Members
    if (!$group) {
        Write-Output (" " * $Level + "- [Erreur] Le groupe '$GroupName' n'existe pas.")
        return
    }

    # Affiche le nom du groupe avec un niveau d'indentation
    Write-Output (" " * $Level + "- Groupe : " + $group.Name)

    # Affiche les membres du groupe
    foreach ($member in $group.Members) {
        # Vérifie si le membre est un groupe ou un utilisateur
        $memberType = (Get-ADObject -Identity $member -Properties ObjectClass).ObjectClass
        if ($memberType -eq "group") {
            # Si c'est un groupe, on rappelle la fonction pour afficher sa hiérarchie
            Get-GroupHierarchy -GroupName (Get-ADGroup -Identity $member).Name -Level ($Level + 4)
        } else {
            # Si c'est un utilisateur, on l'affiche simplement
            Write-Output (" " * ($Level + 4) + "- Utilisateur : " + (Get-ADUser -Identity $member).Name)
        }
    }

    # Affiche les groupes parents (où le groupe est membre de)
    if ($group.MemberOf) {
        Write-Output (" " * ($Level + 4) + "- Membre de :")
        foreach ($parentGroup in $group.MemberOf) {
            Write-Output (" " * ($Level + 8) + "- " + (Get-ADGroup -Identity $parentGroup).Name)
        }
    }
}

# Récupère tous les groupes AD commençant par "GG_"
$allGroups = Get-ADGroup -Filter 'Name -like "GG_*"' | Select-Object -ExpandProperty Name

# Parcourt chaque groupe pour afficher l'arborescence
foreach ($groupName in $allGroups) {
    Write-Output "Arborescence pour le groupe $groupName :"
    Get-GroupHierarchy -GroupName $groupName
    Write-Output ""
}
