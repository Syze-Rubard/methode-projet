# Qualité : le code, les tests, les logs, la performance

À lire au démarrage (pour remplir `architecture.md`), en créant `outils/verifier.ps1`, en écrivant les premiers tests, le module de log ou les premiers tests de performance. Les règles de tous les jours tiennent dans « Vérifier » de `SKILL.md` et dans le CLAUDE.md du projet.

Sommaire :
1. Le code
2. Zéro bug : à chaque changement, les garde-fous automatiques, les bugs trouvés, le produit livré
3. Les logs : retrouver un bug vite
4. La performance : jamais de ralentissement

## 1. Le code

- Petites fonctions génériques, une seule responsabilité, assemblées par composition.
- Valeurs pilotées par les données, jamais en dur.
- Modules découplés par interfaces et événements, frontières vérifiées par le compilateur quand la techno le permet.
- Logique séparée de l'affichage, pour pouvoir la tester.
- Avant d'écrire du code, chercher une brique existante à réutiliser ou à généraliser.
- Deux valeurs du même type se confondent sans une seule erreur (l'identifiant d'un compte et celui d'un profil, deux paramètres facultatifs voisins) : rendre la confusion impossible à écrire, par un type marqué, un objet nommé ou un paramètre nommé. Le compilateur trouve alors chaque endroit.
- Un geste a un seul point d'entrée. Deux copies d'un même geste finissent par diverger, et c'est la copie non testée qui dérive.
- Aucun texte visible en dur : tout passe par des tables de traduction dès le premier écran, même si le produit sort en une seule langue. Ajouter une langue après coup coûte très cher.
- Les données enregistrées de l'utilisateur (sauvegarde de jeu, base locale, préférences) portent un numéro de version, avec une migration depuis chaque version précédente : une mise à jour ne casse jamais ses données.
- Rapide dans le code chaud : voir la partie 4.
- « Fini » : `verifier.ps1` vert (tests de performance compris), essayé en vrai, diff relu, docs à jour, commit fait et poussé.

## 2. Zéro bug

Le but est un projet sans bug. Chaque moyen ci-dessous attrape des bugs que les autres laissent passer, donc on les cumule.

**À chaque changement :**
- **Tests d'abord** pour chaque brique de logique. Un test décrit un comportement, pas le code.
- **Un bug corrigé commence par un test** qui le reproduit et échoue. La correction le fait passer, et le bug ne revient plus.
- **Le geste des trente secondes** : après une correction, remettre le défaut un instant, vérifier que le test échoue, puis restaurer. Un test qui reste vert sur la version fautive ne protège de rien, et peut même faire passer le défaut pour voulu.
- **Un test vise le comportement, jamais une ligne de code recopiée mot pour mot** : il échouerait le jour où on réécrit la ligne sans en changer le sens.
- **Un test qui vérifie une absence** (« aucun fichier ne contient X ») vérifie aussi qu'il a bien lu des fichiers : sinon il est vert sur le vide.
- **Toute la suite de tests**, pas seulement ceux du jour. C'est elle qui voit ce qu'un changement casse ailleurs.
- **Les données testées comme le code** : un test charge chaque fichier de données et vérifie ses références et ses bornes.
- **Zéro warning et zéro erreur dans les logs.** Un warning toléré en cache un autre.
- **Échouer bruyamment.** On vérifie les entrées aux frontières des modules, on met des assertions sur ce qui « ne peut pas arriver », et jamais de `catch` vide.
- **Une étape distingue « rien à faire » de « travail sans effet »** : sinon elle n'est pas observable, et un défaut s'y cache des semaines.
- **Relire le diff** avec `/code-review` avant de commiter une fonctionnalité, et corriger ce qu'il trouve.
- **Jamais `--no-verify`**, jamais un test désactivé ou affaibli pour passer. Si un test gêne, on corrige le code ou le test, avec l'accord de l'utilisateur.

**Les garde-fous automatiques :**
- **`outils/verifier.ps1`** est la commande unique qui lance toutes les vérifications du projet : compilation, analyse (lint), tests, données. Il ne sort à 0 que si tout passe.
  - Il est créé dès le premier code, à partir de `modeles/outils/verifier.ps1`.
  - Chaque nouvelle sorte de vérification y est ajoutée. Si le build de production refuse quelque chose que les tests acceptent (une règle de lint, un import), cette vérification y entre aussi.
- **Le hook git `pre-commit`** le lance avant chaque commit, de Claude comme de l'utilisateur, et bloque le commit si c'est rouge.
- **Le hook Claude Code `garde-tests`** renvoie Claude au travail s'il veut finir alors que du code a changé depuis la dernière vérification réussie.
- **L'intégration continue** (GitHub Actions) est à mettre en place dès que le projet a du code : elle relance la vérification à chaque push, sur une machine propre.
- Une suite lancée pendant un build ou un autre gros calcul rend de faux rouges de lenteur : avant de crier à la régression, regarder ce qui tourne à côté, puis relancer.

**Les bugs trouvés :** chacun suit le même chemin.
1. Une issue GitHub (`gh issue create`), avec les étapes pour le reproduire.
2. Un test qui le reproduit.
3. La correction.
4. Un commit qui ferme l'issue (`Fixes #N`).

**Pour tout produit livré :**
- tout l'aléatoire passe par une graine, notée dans chaque rapport de bug et dans chaque log : tout bug se rejoue à l'identique ;
- un test de fumée lance le produit et parcourt chaque écran sans erreur ;
- la version livrée écrit un log et un rapport de crash, avec sa version.

Les tests propres à chaque type de projet sont dans `types-de-projet.md`.

## 3. Les logs : retrouver un bug vite

Quand un bug arrive, les logs doivent dire ce qui s'est passé, où et pourquoi, sans avoir à le reproduire. Plus il y en a, mieux c'est. Les niveaux et les catégories permettent de n'afficher que ce qu'on cherche.

**Un seul module de log**, créé avec le premier code. Jamais d'appel direct à `print` ou à `Debug.Log`. Le format, les filtres et les destinations se changent alors à un seul endroit.

**Chaque ligne contient :**
- l'heure à la milliseconde ;
- le niveau (`Trace`, `Debug`, `Info`, `Warning`, `Error`, `Fatal`) ;
- la catégorie, c'est-à-dire le module ;
- le message ;
- le contexte en `clé=valeur` : version, session, et ce qui situe l'événement. Pour un jeu, c'est la graine, l'image et le joueur ; pour un service web, la requête et l'utilisateur.

Les fichiers sont en JSON, une ligne par entrée, pour que Claude les filtre en une commande. La console garde une version lisible.

**Ce qu'on loggue :**
- **les changements d'état**, chacun avec l'état d'avant et l'état d'après ;
- **les décisions**, avec leur pourquoi : « remise refusée car… », « ennemi passé en fuite car… » ;
- **les entrées et sorties des modules**, et chaque appel externe : réseau, fichiers, sauvegarde ;
- **les erreurs**, chacune avec tout son contexte et la pile d'appels ;
- **la durée des opérations lentes.**

**On suit un événement d'un bout à l'autre** grâce à un identifiant commun :
- la session ;
- la partie, la requête ou la transaction ;
- le message réseau. Les logs de plusieurs machines se fusionnent alors en une seule chronologie.

**Les fichiers :**
- un fichier par session, à un emplacement noté dans `docs/architecture.md` ;
- on garde les N dernières sessions ;
- les dernières lignes sont aussi gardées en mémoire, et écrites dans chaque rapport de crash ou de bug.

**Pour les performances :**
- le message n'est construit que si son niveau est actif ;
- ce qui se répète à chaque image ou à chaque requête passe au niveau `Trace`, activable par catégorie.

**Jamais de secret ni de donnée personnelle** dans un log : mot de passe, jeton, e-mail, adresse IP.

**Pour un bug :**
1. lire d'abord les logs ;
2. si les logs ne suffisaient pas à comprendre, ajouter les logs qui ont manqué, en plus du test qui reproduit le bug ;
3. joindre les logs à l'issue.

## 4. La performance : jamais de ralentissement

Rien de ce qu'on ajoute ne doit faire ramer le programme. Un ralentissement est un bug comme un autre : il a son issue, son test et sa correction.

**Des budgets chiffrés**, notés dans `docs/architecture.md` et décidés avec l'utilisateur. Ce qu'on mesure dépend du type de projet (voir `types-de-projet.md`) : la réactivité (temps par image, temps de réponse), le démarrage ou le chargement, la mémoire, et les allocations dans le code chaud. Chaque budget a deux valeurs :
- sur l'appareil minimal visé, en médiane et sur le 1 % des pires cas (les saccades comptent) ;
- sur le PC de développement, plus serrée : c'est elle que les tests de chaque commit vérifient.

**Mesurer, pas deviner :**
- on profile avant d'optimiser, et on optimise là où la mesure le montre ;
- les vrais chiffres se prennent sur la version livrée (build de production), sur l'appareil minimal : l'éditeur, le mode debug et un PC puissant les faussent ;
- une mesure s'écrit avec la machine, le paramètre qui l'a produite et sa date : « 461 éléments, filtre année ≥ 2026, base de test, 27/10 » se relit et se conteste, « 461 éléments » non. Une mesure juste, prise sur la mauvaise machine ou avec le mauvais réglage, mène à une conclusion fausse sans que rien ne cloche dans le relevé ;
- deux versions se comparent en alternant, dans la même fenêtre de temps, et un écart plus petit que la dispersion d'une même version ne compte pas ;
- ce qu'un système annonce savoir faire n'est pas une mesure : on essaie en vrai ;
- une base de données se mesure sur son plan d'exécution (`EXPLAIN`), sur la requête que la production exécute : un test de résultat reste vert sur un plan cassé ;
- avant un banc d'essai coûteux (temps, réseau, données), dire à l'utilisateur ce qu'il coûte.

**Tests de performance automatiques**, dans `outils/verifier.ps1`, après les autres tests :
- des scénarios de pire cas, joués quelques secondes chacun ;
- chacun échoue s'il dépasse le budget du PC de développement, ou s'il alloue de la mémoire là où il ne doit pas ;
- chacun échoue aussi s'il régresse de plus de 10 % par rapport à la référence de ce PC (`outils/perf-reference.json`, ignorée par git) ;
- une amélioration voulue met la référence à jour, avec l'accord de l'utilisateur.

**À chaque fonctionnalité :**
- le plan dit ce qu'elle coûte en performance ;
- le diff relu cherche aussi les coûts cachés : allocations, recherches répétées, boucles sur tout le monde.

**À chaque jalon**, la version livrée passée au profiler sur l'appareil minimal, avec les chiffres notés dans `architecture.md`.

**Du code générique et rapide à la fois :** les petites fonctions génériques restent la règle. Dans le code chaud, c'est-à-dire ce qui tourne à chaque image, à chaque requête ou pour chaque élément d'une longue liste :
- aucune allocation ;
- des références gardées en cache ;
- des pools d'objets au lieu de créer et détruire ;
- des événements plutôt que des vérifications répétées ;
- des structures de données adaptées au volume ;
- rien de lent sur le fil de l'interface : disque, réseau et gros calculs passent en tâche de fond. Une bibliothèque synchrone (une base SQLite, par exemple) bloque tout le fil pendant sa requête.

**En développement**, un affichage permanent ou un tableau de bord montre les mesures clés : images par seconde et allocations pour un jeu, temps de réponse pour un service.
