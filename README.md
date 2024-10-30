Explications du Script

    Get-GroupHierarchy : Cette fonction est la base de l'arborescence. Elle prend un groupe en paramètre, liste ses membres et vérifie si ces membres sont des utilisateurs ou des sous-groupes.
        Indentation : Le paramètre $Level permet de définir l'indentation et de structurer l'affichage.
        Membres : Pour chaque membre du groupe, la fonction identifie s’il s’agit d’un utilisateur ou d’un groupe.
        Groupes parents : La section MemberOf affiche dans quels autres groupes le groupe en cours est membre.
    Boucle pour parcourir les groupes "GG_" : Elle récupère tous les groupes de sécurité AD commençant par "GG_" et lance la fonction Get-GroupHierarchy pour chaque groupe.

### Exécute le script et enregistre l'arborescence dans un fichier texte
$allGroups | ForEach-Object { Get-GroupHierarchy -GroupName $_ } | Out-File -FilePath "C:\AD_Group_Hierarchy.txt"

Exemple de sortie : 

        Arborescence pour le groupe GG_Admins :
    - Groupe : GG_Admins
        - Utilisateur : John Smith
        - Groupe : GG_IT_Team
            - Utilisateur : Alice Brown
            - Utilisateur : Charlie Green
            - Groupe : GG_Dev_Team
                - Utilisateur : Dave White
                - Utilisateur : Emma Black
                - Membre de :
                    - GG_Project_A
        - Membre de :
            - GG_UpperManagement
    
    Arborescence pour le groupe GG_IT_Team :
    - Groupe : GG_IT_Team
        - Utilisateur : Alice Brown
        - Utilisateur : Charlie Green
        - Groupe : GG_Dev_Team
            - Utilisateur : Dave White
            - Utilisateur : Emma Black
            - Membre de :
                - GG_Project_A
        - Membre de :
            - GG_Admins
    
    Arborescence pour le groupe GG_Dev_Team :
    - Groupe : GG_Dev_Team
        - Utilisateur : Dave White
        - Utilisateur : Emma Black
        - Membre de :
            - GG_IT_Team
            - GG_Project_A
    
    Arborescence pour le groupe GG_Project_A :
    - Groupe : GG_Project_A
        - Groupe : GG_Dev_Team
            - Utilisateur : Dave White
            - Utilisateur : Emma Black
            - Membre de :
                - GG_IT_Team
        - Membre de :
            - GG_UpperManagement



