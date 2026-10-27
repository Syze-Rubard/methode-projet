# Sécurité, sauvegarde, licences

À lire au démarrage (pour la section « Sécurité » de `architecture.md`), avant d'ajouter une dépendance ou un contenu externe, et avant de toucher à un secret, à un compte ou à un déploiement.

## Sécurité

Rien de secret ne sort du PC, et rien de ce qui entre n'est cru sur parole.

**Les secrets** (mots de passe, clés d'API, jetons, certificats, clés de signature) :
- jamais dans le dépôt, même privé : ils vivent dans un fichier ignoré par git, ou dans le coffre du service (les secrets de GitHub Actions) ;
- jamais dans ce qui est livré (jeu, appli, page web) : un utilisateur peut lire tout ce qu'il contient ;
- jamais affichés : dans une sortie de commande, un log ou une réponse, on montre qu'un secret est posé, jamais sa valeur ;
- le hook git `pre-commit` bloque un commit qui contient un fichier de clé ou un secret reconnaissable ;
- un secret qui a fuité est révoqué et remplacé tout de suite : l'effacer de l'historique ne suffit pas ;
- Claude ne saisit jamais un secret : l'utilisateur le fait lui-même.

**Les dépendances** (packages, plugins, assets, serveurs MCP) :
- seulement de sources connues, avec une version fixée ;
- mises à jour volontairement, une à la fois, suivies de la vérification complète ;
- jamais de script ni d'exécutable téléchargé lancé sans l'avoir lu. Pour relire un paquet tiers, des recherches ciblées suffisent : adresses contactées, fichiers écrits, code exécuté à l'installation.

**Les données qui entrent** sont validées à la frontière, comme si elles étaient hostiles :
- un fichier chargé (sauvegarde, configuration, mod) abîmé ou modifié ne fait jamais planter : il est signalé dans les logs et écarté ;
- jamais de désérialisation capable de créer n'importe quel type, comme `BinaryFormatter` en C# ;
- en réseau, l'hôte ou le serveur fait autorité et vérifie chaque message d'un client : son type, ses bornes, sa fréquence ;
- un droit se lit à un seul endroit, et chaque droit se pèse pour lui-même : en aligner un sur son voisin ouvre ou ferme une porte sans qu'on le voie.

**Les données personnelles** : aucune collectée sans besoin ni sans accord. Rapports de crash et statistiques sont annoncés et désactivables.

**Les comptes** : double authentification sur GitHub et sur chaque compte de publication, et dépôts privés par défaut.

**La production** : aucun déploiement sans le feu vert explicite de l'utilisateur, donné pour ce déploiement-là. Un build ou un test ne touche jamais la base de production : une garde le refuse, et seul le vrai lanceur porte le laissez-passer.

## Sauvegarde du projet

- Le code, les docs, la mémoire et les assets suivis par Git LFS sont sur GitHub dès que le commit est poussé.
- Le quota Git LFS du compte GitHub est surveillé : les assets lourds le remplissent vite.
- Ce qui vit hors de git est listé dans la carte (« Hors du dossier »), avec l'endroit où c'est sauvegardé.
- À chaque jalon, une copie complète du dossier sur un autre support.
- Une sauvegarde de base de données ne compte qu'une fois restaurée pour de vrai.
- Ne rien effacer qu'on ne comprend pas encore : un fichier partiel reprend, un fichier effacé recommence.

## Licences et droits : des avertissements

Claude ne tient pas de registre des licences et ne bloque rien. Quand l'un de ces cas se présente, il prévient l'utilisateur d'une ligne, au moment même, et l'utilisateur décide :

| Le cas | L'avertissement |
|---|---|
| Un contenu externe entre dans le projet : asset, police, son, musique, code | « ⚠ Licence : *contenu* vient de *source*, sous *licence* ; attribution demandée : *…*. » Si l'utilisateur veut en garder la trace, une ligne dans `docs/licences.md`, créé à ce moment-là. |
| Un contenu sans licence claire | « ⚠ Licence inconnue : *contenu* ne pourra pas être publié tant qu'on ne sait pas qui l'autorise. » |
| Une dépendance sous licence copyleft (GPL, AGPL…) | « ⚠ Copyleft : *dépendance* est sous *licence* ; la livrer peut obliger à publier le code du projet. » |
| Une livraison, ou la page des crédits | « ⚠ Crédits : chaque contenu externe y figure, avec l'attribution que sa licence demande. » |
| Une marque, un logo ou un nom de produit d'autrui | « ⚠ Marque : *nom* appartient à *titulaire* ; l'utiliser demande son accord. » |

### ⚠⚠ L'avertissement renforcé : un contenu généré par IA

Chaque fois qu'un contenu généré par IA est destiné au produit, Claude donne cet avertissement en entier, même s'il l'a déjà donné pour un autre contenu. Un essai d'exploration n'en a pas besoin.

> ⚠⚠ **Contenu généré par IA** : *contenu*, par *modèle*, formule *…*, le *date*.
> - **À déclarer.** Steam demande de déclarer les contenus générés par IA dans son questionnaire de contenu, avant la soumission, et l'affiche sur la page du jeu. Un contenu généré pendant le jeu demande aussi de décrire ses garde-fous. Les autres boutiques ont, ou auront, leurs propres règles.
> - **Les droits de la formule.** Usage commercial permis ? Crédit obligatoire ? Territoires exclus, seuil de revenus ? Les formules gratuites sont souvent non commerciales (exemples dans `generation-ia.md`, partie « Droits »).
> - **La protection.** Une création purement IA peut ne pas être protégée par le droit d'auteur, aux États-Unis au moins : ce qui fait l'identité du produit garde une vraie part humaine.
> - **La trace.** Le modèle, la formule et la date : sans eux, la déclaration est impossible à remplir le jour de la publication.
