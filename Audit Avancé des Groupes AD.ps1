# Chargement du module Active Directory (si nécessaire)
Import-Module ActiveDirectory

# Dictionnaire pour stocker les groupes déjà visités et éviter les cycles infinis
$VisitedGroups = @{}

# Fonction récursive pour lister les membres et les groupes parents
function Get-GroupHierarchy {
    param (
        [string]$GroupName,
        [int]$Level = 0  # Niveau d'indentation
    )

    # Vérifier si le groupe a déjà été traité (éviter les cycles circulaires)
    if ($VisitedGroups.ContainsKey($GroupName)) {
        Write-Output (" " * $Level + "- [Cycle détecté] Groupe déjà traité : $GroupName")
        return
    }
    
    # Ajouter le groupe au dictionnaire des groupes visités
    $VisitedGroups[$GroupName] = $true

    # Récupérer le groupe et ses propriétés
    $group = Get-ADGroup -Identity $GroupName -Properties MemberOf, Members
    if (!$group) {
        Write-Output (" " * $Level + "- [Erreur] Le groupe '$GroupName' n'existe pas.")
        return
    }

    # Afficher le nom du groupe
    Write-Output (" " * $Level + "- Groupe : " + $group.Name)

    # Traiter chaque membre du groupe
    foreach ($member in $group.Members) {
        # Vérifier le type de membre
        $memberType = (Get-ADObject -Identity $member -Properties ObjectClass).ObjectClass
        if ($memberType -eq "group") {
            # Si c'est un groupe, appel récursif pour lister sa hiérarchie
            Get-GroupHierarchy -GroupName (Get-ADGroup -Identity $member).Name -Level ($Level + 4)
        } else {
            # Sinon, afficher le membre utilisateur
            Write-Output (" " * ($Level + 4) + "- Utilisateur : " + (Get-ADUser -Identity $member).Name)
        }
    }

    # Afficher les groupes dans lesquels ce groupe est membre (s'il y en a)
    if ($group.MemberOf) {
        Write-Output (" " * ($Level + 4) + "- Membre de :")
        foreach ($parentGroup in $group.MemberOf) {
            Write-Output (" " * ($Level + 8) + "- " + (Get-ADGroup -Identity $parentGroup).Name)
        }
    }

    # Retirer le groupe du dictionnaire après traitement
    $VisitedGroups.Remove($GroupName)
}

# Fonction pour détecter les problèmes d'imbrications multiples et circulaires
function DetectGroupIssues {
    param (
        [string]$GroupName
    )

    Write-Output "Vérification des imbrications pour le groupe : $GroupName"
    # Initialiser les groupes visités et lancer la fonction de hiérarchie
    $VisitedGroups.Clear()
    Get-GroupHierarchy -GroupName $GroupName
    Write-Output ""
}

# Récupérer tous les groupes de sécurité (avec un préfixe ou filtre)
$allGroups = Get-ADGroup -Filter 'Name -like "GG_*"' | Select-Object -ExpandProperty Name

# Afficher la hiérarchie pour chaque groupe et détecter les problèmes potentiels
foreach ($groupName in $allGroups) {
    Write-Output "---------------------------------------------"
    Write-Output "Arborescence et analyse pour le groupe $groupName :"
    DetectGroupIssues -GroupName $groupName
    Write-Output "---------------------------------------------"
}
