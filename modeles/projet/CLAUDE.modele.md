# {{NOM}} : instructions pour Claude

{{PITCH EN UNE PHRASE}}. La méthode de travail complète est décrite dans le skill `methode-projet`.

## En début de session

1. La carte du projet et l'index de la mémoire sont chargés en bas de ce fichier. Lire dans `docs/memoire/` les fiches utiles à la tâche.
2. Pour toute question de conception, {{DOCUMENT DE CONCEPTION ET SON LIEN}} fait foi.
3. Avant d'écrire du code, lire `docs/architecture.md`.

## Règles de travail

- Petit bout par petit bout : une fonctionnalité par session, en mode plan d'abord, puis construire, tester, commiter.
- Aucune phase de production ne démarre sans le feu vert explicite de l'utilisateur.
- Le document de conception est vivant : chaque fonctionnalité construite met à jour sa section dans la même session, et ce qui est abandonné est retiré. Il reste compact.
- Réponses courtes et directes.
- Français avec l'utilisateur et dans les docs, anglais dans le code et dans les fiches de mémoire.

## En fin de tâche

Une tâche n'est finie qu'après ces étapes :
1. `outils/verifier.ps1` au vert, la fonctionnalité essayée en vrai, et le diff relu avec `/code-review`.
2. Mettre à jour chaque document concerné par le changement, d'après le tableau « Qui tient quoi à jour » de la carte.
3. Commiter, puis pousser vers GitHub.
4. Si la fonctionnalité est terminée, dire à l'utilisateur que c'est le bon moment pour `/clear`. Le hook `rappel-clear` le lui rappelle aussi.

## Mémoire

- La mémoire du projet vit dans `docs/memoire/` et voyage avec le disque et le dépôt git.
- Sur chaque PC, `.claude/settings.local.json` (non versionné) y dirige la mémoire automatique de Claude Code avec le réglage `autoMemoryDirectory`. Le script `preparer-projet.ps1` du skill le crée, et corrige le chemin si le disque change de lettre.
- Toute info durable (décision, préférence, état du projet) y est ajoutée : une fiche par sujet et une ligne dans `MEMORY.md`. On met à jour une fiche existante plutôt que d'en créer une en double.

## Compaction

Quand la conversation est résumée, garder : la tâche en cours et son plan, les décisions prises et leur pourquoi, les fichiers créés ou modifiés, les erreurs rencontrées et leur correction, ce qui reste à faire. Laisser de côté le contenu des fichiers et les longues sorties d'outils : on peut les relire.

## Code, en résumé (détails dans `docs/architecture.md`)

- Petites fonctions génériques, une seule responsabilité chacune, assemblées par composition.
- Valeurs pilotées par les données, aucune valeur en dur.
- Modules découplés par interfaces et événements.
- Logique séparée de l'affichage, pour pouvoir la tester.
- « Fini » veut dire : `verifier.ps1` vert, essayé en vrai, diff relu, docs à jour, commit fait et poussé.

## Qualité : zéro bug

- Tests d'abord : chaque brique de logique a ses tests, écrits avant le code.
- Un bug corrigé commence par un test qui le reproduit. Chaque bug trouvé devient une issue GitHub, avec les étapes pour le reproduire.
- `outils/verifier.ps1` lance toutes les vérifications. Il doit être vert avant de finir une tâche et avant chaque commit : les hooks y veillent. On y ajoute chaque nouvelle sorte de vérification.
- Zéro warning, zéro erreur dans les logs, aucune erreur silencieuse.
- Jamais `--no-verify`, jamais un test désactivé ou affaibli pour passer.

## Carte du projet

@docs/README.md

## Index de la mémoire (fiches dans docs/memoire/)

@docs/memoire/MEMORY.md
