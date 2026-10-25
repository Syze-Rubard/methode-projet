# Journal de la méthode

Chaque amélioration de la méthode, avec son pourquoi. La plus récente en haut.

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
