# Exploration des Groupes AD
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

# Audit Avancé des Groupes AD
Explications et Optimisations

    Utilisation d’un dictionnaire ($VisitedGroups) : Ce dictionnaire garde trace des groupes déjà visités pour éviter les cycles infinis dus aux imbrications circulaires.

    Vérification des cycles : Si un groupe est revisité dans sa propre hiérarchie, le script marque cela comme un cycle détecté. Cela permet de repérer rapidement les imbrications circulaires (problème fréquent).

    Collecte de tous les groupes : Le script commence par collecter tous les groupes de sécurité qui répondent à un filtre donné, ce qui simplifie et optimise le processus de recherche.

    Fonction dédiée pour la détection des problèmes (DetectGroupIssues) : Cette fonction assure un appel clair à chaque groupe pour détecter les cycles et les problématiques d’imbrication, en réinitialisant le dictionnaire des groupes visités à chaque nouveau groupe analysé.
### Exécute le script et exporte dans un fichier
.\NomDuScript.ps1 | Out-File -FilePath "C:\AD_Group_Hierarchy_Analysis.txt"

Exemple de sortie : 

    ---------------------------------------------
    Arborescence et analyse pour le groupe GG_Admins :
    Vérification des imbrications pour le groupe : GG_Admins
    - Groupe : GG_Admins
        - Utilisateur : John Smith
        - Groupe : GG_IT_Team
            - Utilisateur : Alice Brown
            - Groupe : GG_Dev_Team
                - Utilisateur : Dave White
                - [Cycle détecté] Groupe déjà traité : GG_Admins
        - Membre de :
            - GG_UpperManagement
    
    ---------------------------------------------
    Arborescence et analyse pour le groupe GG_IT_Team :
    Vérification des imbrications pour le groupe : GG_IT_Team
    - Groupe : GG_IT_Team
        - Utilisateur : Alice Brown
        - Utilisateur : Charlie Green
        - Groupe : GG_Dev_Team
            - Utilisateur : Emma Black
            - Membre de :
                - GG_Project_A
                - GG_IT_Team
        - Membre de :
            - GG_Admins
    ---------------------------------------------

# Audit Complet de Sécurité des Groupes AD v1 
Explication du script 

    Explorer les hiérarchies des groupes et détecter les cycles d’imbrication circulaire et autres structures redondantes.
    Lister les permissions et rôles des utilisateurs et groupes pour identifier les permissions potentiellement excessives.
    Analyser les utilisateurs inactifs ou n’ayant pas changé leur mot de passe depuis longtemps.
    Distinguer les groupes de sécurité et de distribution ainsi que leurs appartenances respectives.
    Générer un rapport complet et exportable pour faciliter la correction des anomalies.
    Détails et Optimisations
Détails et Optimisations

    Dictionnaire $VisitedGroups pour détecter les cycles : Cette méthode permet de noter chaque groupe parent pour identifier les cycles au sein de la même branche, évitant ainsi les imbrications circulaires.
    Analyse de l’activité des utilisateurs : La vérification de la date du dernier logon et du dernier changement de mot de passe permet de détecter les utilisateurs potentiellement inactifs ou qui présentent un risque de sécurité.
    Propriétés des groupes : La capture des propriétés GroupCategory et GroupScope (catégorie et portée) pour chaque groupe permet de distinguer les groupes de sécurité des groupes de distribution et d'identifier les groupes globaux et universels.
    Liste des groupes parents pour chaque groupe : Pour les membres imbriqués, cette section aide à repérer les appartenances multiples qui peuvent être sources de complexité ou de conflits de permissions.
    Export détaillé en CSV : L’export des résultats en fichier CSV permet de garder une trace des groupes analysés et des anomalies détectées, facilitant le partage des résultats et l’analyse ultérieure.
    Résumés et Récapitulatif : À la fin, un résumé des problèmes détectés (cycles, utilisateurs inactifs, etc.) est affiché en format tableau pour une vue rapide des points d’attention.


# Audit Complet de Sécurité des Groupes AD v2
Explications des Étapes du Script

    Collecte de l’arborescence sous forme d’arbre :
        La fonction Get-GroupHierarchy est appelée pour chaque groupe trouvé, et elle structure les informations avec des indentations pour simuler une vue d’arborescence.
        Les cycles et utilisateurs inactifs sont marqués pour une détection rapide dans la hiérarchie.
    Audit de tous les groupes de sécurité (fonction AuditAllGroups) :
        Cette fonction appelle Get-GroupHierarchy pour chaque groupe de sécurité dont le nom commence par "GG_".
    Affichage dans PowerShell :
        Le tableau $Output stocke toutes les lignes de l’audit et est affiché en une seule fois à la fin pour éviter les ralentissements dus aux écritures répétées.
    Export dans un fichier texte :
        L’audit complet est exporté dans un fichier texte via Out-File, ce qui permet de garder une trace permanente des résultats.
    Résumé des problèmes détectés :
        À la fin du script, un filtre rapide permet d’afficher les lignes contenant les mots-clés d'erreur ou de cycle dans PowerShell, offrant une vue d'ensemble rapide sur les problèmes.

Exemple de sortie : 

    ---------------------------------------------
    Arborescence et analyse pour le groupe GG_Admins :
    - Groupe : GG_Admins (Catégorie: Security, Portée: Global)
        - Utilisateur : John Doe, Dernier logon: 2023-05-14, Mot de passe modifié: 2022-09-20, Inactif: True
        - Groupe : GG_IT_Team (Catégorie: Security, Portée: Global)
            - Utilisateur : Alice Brown, Dernier logon: 2023-10-01, Mot de passe modifié: 2024-01-01, Inactif: False
            - Groupe : GG_Dev_Team
                - [Cycle détecté] Groupe déjà traité : GG_Admins
        - Membre de :
            - GG_UpperManagement
    ---------------------------------------------


