# Journal de la méthode

Chaque amélioration de la méthode, avec son pourquoi. La plus récente en haut.

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
