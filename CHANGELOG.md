# Journal de la méthode

Chaque amélioration de la méthode, avec son pourquoi. La plus récente en haut.

## 2026-10-27 : économiser les tokens

Sur RogueHack, Claude a lancé un workflow de cinq agents pour relire un paquet tiers avant de l'installer, alors que quelques recherches ciblées suffisaient. L'utilisateur l'a arrêté et a demandé que la méthode serve aussi à économiser les tokens :
- une sixième idée, et une section « Économiser les tokens » : un projet rangé qui se lit comme un livre ouvert, lire juste ce qu'il faut, l'effort qui suit la difficulté de la tâche, des réponses courtes ;
- pas d'agents ni de workflows pour une tâche simple, même en mode ultracode ;
- le modèle de CLAUDE.md le rappelle à chaque session.

## 2026-10-27 : leçons d'un service web mené des mois avec des agents

L'utilisateur a demandé de reporter dans la méthode ce qu'un autre de ses projets, un service web en ligne depuis des mois et construit par de nombreux agents, a appris à ses dépens :
- **le geste des trente secondes** : remettre le défaut et voir le test échouer. Sur ce projet, des dizaines de tests étaient verts sur la version fautive, et quelques-uns faisaient passer le défaut pour voulu ;
- un test vise le comportement, pas une ligne recopiée : une dizaine de fois, un test a échoué sur du code juste, seulement parce qu'il avait été réécrit ;
- un test d'absence prouve qu'il a lu quelque chose ;
- une mesure porte sa machine, son paramètre et sa date : deux fois le même jour, une mesure juste a mené à une conclusion fausse, une fois parce qu'il y avait deux bases « de production », une fois à cause d'un filtre mal réglé ;
- comparer deux versions en alternant, et se méfier de ce qu'un système annonce savoir faire ;
- une ligne de mémoire qui décrit un état porte sa date : plusieurs fois, une ligne périmée a survécu et a découragé de vérifier ;
- `docs/decisions/` et `docs/pieges/`, quand le projet grandit : un choix qui n'existe que dans un commentaire a été défait par l'agent suivant.

## 2026-10-27 : disque venu d'un autre PC

Sur le second PC, le disque de RogueHack appartenait encore au compte du premier PC. Git refusait donc ses dépôts (« dubious ownership »), et `preparer-projet.ps1` s'arrêtait dessus :
- `preparer-projet.ps1` ajoute le dépôt du projet à `safe.directory` quand git le refuse pour cette raison, et seulement dans ce cas ;
- `preparer-pc.ps1` fait de même pour le dépôt du skill ;
- pour se connecter à GitHub, `preparer-pc.ps1` donne le chemin complet de `gh`. Un terminal ouvert avant l'installation ne trouvait pas la commande `gh` ;
- une fois connecté, `preparer-pc.ps1` fait passer git par GitHub CLI (`gh auth setup-git`) et affiche le compte. Sur le second PC, git poussait avec un ancien compte resté enregistré, et le navigateur avait connecté `gh` à ce même ancien compte ;
- une modification du skill est commitée et poussée tout de suite, sans attendre la fin de la tâche du projet, pour qu'il reste à jour sur chaque PC. L'utilisateur l'a demandé.

## 2026-10-25 : génération par IA

Un modèle d'IA générative donne de bien meilleurs résultats quand on lui parle comme son éditeur le conseille, et chaque modèle a sa façon. L'utilisateur veut que Claude se renseigne toujours avant de générer :
- le hook `garde-generation-ia.ps1` (PreToolUse) refuse une génération d'image, de vidéo, de modèle 3D ou de son tant que le modèle appelé n'a pas de fiche datée de moins de 60 jours dans `docs/generation-ia/modeles/`. Son message dit comment se renseigner et quoi écrire. Une estimation de coût et la reprise d'un travail passent ;
- le modèle de fiche `_modele.md` : sources, forme de prompt, images de référence, paramètres, astuces de la communauté, forces et faiblesses, prompt qui a marché ;
- on se renseigne dans les guides officiels, puis dans ceux de la communauté (Reddit, Discord, tutoriels) : l'utilisateur sait qu'on y trouve souvent les meilleures astuces. Chacune est notée avec sa source et son résultat une fois essayée ;
- la bible de style `docs/generation-ia/style.md`, pour que les contenus d'un même produit se ressemblent ;
- une section « Génération par IA » dans le skill : les réflexes, la façon d'obtenir des contenus cohérents, les outils, les droits ;
- le modèle de CLAUDE.md et la carte en parlent.

## 2026-10-25 : dépôt public

Pour qu'une personne récupère la méthode sans compte GitHub ni invitation :
- le dépôt du skill devient public, et le `README.md` donne la commande `git clone` ;
- son historique porte l'adresse anonyme de GitHub au lieu d'une vraie adresse e-mail, et ses prochains commits aussi ;
- les dépôts des projets restent privés.

## 2026-10-25 : feuille de route

Les phases disaient où va le projet, mais pas quelle session vient ensuite. RogueHack a gagné une feuille de route étape par étape, reprise ici pour tout projet :
- le modèle `docs/feuille-de-route.md` : une case par session, regroupées par phase de 0 à 7, et une section « Où on en est » ;
- les phases lointaines restent en grands blocs, découpées en sessions juste avant de les commencer, avec les leçons de la phase précédente ;
- ce qu'on fait à chaque jalon tient au même endroit : tag, version livrée profilée, export des documents hors du dossier, copie du dossier, découpage de la phase suivante ;
- en début de session, la prochaine étape est la première case non cochée. En fin de tâche, on coche sa case et on met à jour « Où on en est » ;
- la carte, le modèle de CLAUDE.md et le démarrage d'un projet en parlent. La fiche projet de la mémoire renvoie à la feuille de route, pour ne pas tenir la suite à deux endroits.

## 2026-10-25 : tout type de projet de code

La méthode était écrite autour d'un jeu Steam. L'utilisateur la veut aussi utile pour un jeu mobile, une appli, un logiciel ou tout autre projet de code :
- les règles générales sont réécrites sans vocabulaire de jeu : appareil minimal, version livrée, code chaud « à chaque image, à chaque requête ou pour chaque élément », données enregistrées de l'utilisateur ;
- une section « Selon le type de projet » donne, pour un jeu, une appli mobile, un logiciel de bureau, un site ou service web, et un outil ou une bibliothèque, ce qu'on mesure, ce qu'on teste, la sécurité propre et la publication ;
- les phases deviennent celles de tout projet, avec une phase de suivi après le lancement ;
- le démarrage demande le type du projet, et `architecture.md` le note ;
- une techno sans modèle se crée à partir de `base` et du modèle officiel `github/gitignore` ;
- `verifier.ps1` donne des exemples pour .NET, le web, Python et Android ;
- le registre des licences couvre aussi les dépendances de code (licences copyleft).

## 2026-10-25 : sécurité, sauvegarde, licences, et juste ce qu'il faut

L'utilisateur a demandé la sécurité, et les autres points importants d'un projet pro :
- une section « Sécurité » : les secrets, les dépendances, la validation de tout ce qui entre, les données personnelles, les comptes ;
- le hook `garde-secrets.ps1`, lancé par le `pre-commit` avant `garde-tests`, bloque un commit qui contient un fichier de clé ou un secret reconnaissable ;
- une section « Sauvegarde du projet », et une colonne « Sauvegarde » dans la carte pour ce qui vit hors de git ;
- une section « Licences et droits », et le registre `docs/licences.md`, qui note aussi les contenus générés par IA à déclarer à Steam ;
- deux règles de code : aucun texte visible en dur, et des sauvegardes du joueur versionnées avec une migration ;
- une cinquième idée, « juste ce qu'il faut, au bon moment », pour que la méthode ne complique pas un projet pour rien.

## 2026-10-25 : performance, jamais de ralentissement

L'utilisateur veut un programme optimisé, qui ne rame jamais à cause de ce qu'on ajoute :
- une section « Performance » dans le skill : des budgets chiffrés pour la configuration minimale et pour le PC de développement, mesurer avant d'optimiser, des tests de performance dans `outils/verifier.ps1` qui échouent au-delà du budget ou à plus de 10 % de régression, un build profilé à chaque jalon, et les règles du code chaud ;
- le plan de chaque fonctionnalité dit ce qu'elle coûte en performance ;
- une section dans le modèle de CLAUDE.md, un tableau des budgets dans `architecture.md`, et `outils/perf-reference.json` ignoré par git.

## 2026-10-25 : logs pour retrouver un bug vite

L'utilisateur veut retrouver tout bug vite, à partir des logs, et plus il y en a, mieux c'est :
- une section « Logs » dans le skill : un seul module de log, des lignes structurées en JSON avec leur contexte, ce qu'on loggue, des identifiants pour suivre un événement d'un bout à l'autre, un fichier par session, les dernières lignes jointes aux rapports de crash ;
- deux règles dans le modèle de CLAUDE.md, et un tableau des choix de log du projet dans `architecture.md`.

## 2026-10-25 : qualité, zéro bug

Le but est un projet sans bug, donc les tests ne reposent plus sur la bonne volonté :
- `outils/verifier.ps1` est la commande unique de vérification d'un projet. Son modèle est dans `modeles/outils/` ;
- le hook git `pre-commit`, dans `.githooks/` et activé par `preparer-projet.ps1`, bloque tout commit qui ne passe pas la vérification ;
- le hook Claude Code `garde-tests` empêche Claude de finir avec du code non vérifié ;
- le cycle passe aux tests d'abord, avec une relecture du diff avant chaque commit. Un bug corrigé commence par un test, et chaque bug devient une issue GitHub ;
- une section « Qualité : zéro bug » dans le skill et dans le modèle de CLAUDE.md, et un tableau des niveaux de test dans `architecture.md`.

## 2026-10-25 : installation par scripts

Pour obtenir le même résultat sur chaque PC et pour chaque personne, sans dépendre d'une copie faite à la main par Claude :
- `preparer-pc.ps1` remplace `install.ps1`. Il installe git, Git LFS et GitHub CLI avec winget, relie le skill, vérifie la compaction et liste ce que l'utilisateur doit faire lui-même ;
- `preparer-projet.ps1` crée ou complète un projet sans rien écraser. Il règle la mémoire sur le PC en cours et liste les `{{...}}` à remplir ;
- les modèles sont rangés en `modeles/projet/` (communs) et `modeles/techno/<techno>/` (git par techno, avec `base` et `unity`). Le modèle de fiche projet de la mémoire est ajouté ;
- la carte gagne une section « Outils du PC », pour réinstaller les outils propres au projet sur un autre PC ;
- un `README.md` explique l'installation à une personne qui découvre la méthode.

## 2026-10-25 : première version

Tirée du projet RogueHack :
- un sujet par document, et une carte du projet chargée par CLAUDE.md, pour que chaque info ait une seule place ;
- la mémoire versionnée dans le projet via `autoMemoryDirectory`, pour qu'elle suive le disque et chaque PC ;
- une fonctionnalité par session avec une checklist de fin de tâche, pour garder les docs à jour ;
- le hook `rappel-clear` et des consignes de compaction, pour économiser les tokens ;
- les décisions techniques tracées dans `architecture.md`, pour ne pas les rediscuter.
