Explications du Script

    Get-GroupHierarchy : Cette fonction est la base de l'arborescence. Elle prend un groupe en paramètre, liste ses membres et vérifie si ces membres sont des utilisateurs ou des sous-groupes.
        Indentation : Le paramètre $Level permet de définir l'indentation et de structurer l'affichage.
        Membres : Pour chaque membre du groupe, la fonction identifie s’il s’agit d’un utilisateur ou d’un groupe.
        Groupes parents : La section MemberOf affiche dans quels autres groupes le groupe en cours est membre.
    Boucle pour parcourir les groupes "GG_" : Elle récupère tous les groupes de sécurité AD commençant par "GG_" et lance la fonction Get-GroupHierarchy pour chaque groupe.

### Exécute le script et enregistre l'arborescence dans un fichier texte
$allGroups | ForEach-Object { Get-GroupHierarchy -GroupName $_ } | Out-File -FilePath "C:\AD_Group_Hierarchy.txt"
