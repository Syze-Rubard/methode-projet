# {{NOM}} : instructions pour Claude

{{PITCH EN UNE PHRASE}}. La méthode de travail complète est décrite dans le skill `methode-projet`.

## En début de session

1. La carte du projet est chargée en bas de ce fichier, et l'index de la mémoire par la mémoire automatique. Lire dans `docs/memoire/` seulement les fiches utiles à la tâche.
2. « Où on en est », dans `docs/feuille-de-route.md`, dit où on en est. La prochaine étape est la première case non cochée.
3. Pour toute question de conception, {{DOCUMENT DE CONCEPTION ET SON LIEN}} fait foi.
4. Avant d'écrire du code, lire `docs/architecture.md`.

## Règles de travail

- Petit bout par petit bout : une fonctionnalité par session, en mode plan d'abord, puis construire, tester, commiter.
- Aucune phase de production ne démarre sans le feu vert explicite de l'utilisateur.
- Le document de conception est vivant : chaque fonctionnalité construite met à jour sa section dans la même session, et ce qui est abandonné est retiré. Il reste compact.
- Réponses courtes et directes : ce qui est fait, ce qui reste, la question à trancher.
- L'effort suit la difficulté de la tâche. Seul par défaut ; un sous-agent du bon type (`leger`, `moyen` ou `haut`, dans `.claude/agents/`) quand le travail le demande ; jamais de workflow pour une tâche simple, même en mode ultracode.
- Lire juste ce qu'il faut : la section utile, une recherche ciblée, jamais un gros fichier en entier.
- Français avec l'utilisateur et dans les docs, anglais dans le code et dans les fiches de mémoire.

## En fin de tâche

Une tâche n'est finie qu'après ces étapes :
1. `outils/verifier.ps1` au vert, la fonctionnalité essayée en vrai, et le diff relu avec `/code-review`.
2. Mettre à jour chaque document concerné, d'après le tableau « Qui tient quoi à jour » de la carte, cocher la case de la feuille de route et réécrire « Où on en est ».
3. Commiter, puis pousser vers GitHub. Le pre-commit vérifie aussi que le projet suit toujours la méthode : une ligne « à corriger » se corrige, jamais ne se contourne.
4. Si la fonctionnalité est terminée, dire à l'utilisateur que c'est le bon moment pour `/clear`. Le hook `rappel-clear` le lui rappelle aussi.

## Mémoire

- La mémoire du projet vit dans `docs/memoire/` et voyage avec le disque et le dépôt git. Sur chaque PC, `.claude/settings.local.json` (non versionné) y dirige la mémoire automatique (`autoMemoryDirectory`) ; `preparer-projet.ps1` le crée.
- `MEMORY.md` est chargé à chaque session : une ligne par fiche, une cinquantaine de lignes au plus. Il ne s'importe jamais dans ce fichier : il serait chargé deux fois.
- Toute info durable (décision, préférence, état du projet) y entre : une fiche par sujet, mise à jour plutôt que dupliquée. Une ligne qui décrit un état porte la date de sa mesure.

## Compaction

Quand la conversation est résumée, garder : la tâche en cours et son plan, les décisions prises et leur pourquoi, les fichiers créés ou modifiés, les erreurs rencontrées et leur correction, ce qui reste à faire, et l'identifiant de tout travail lancé en fond. Laisser de côté le contenu des fichiers et les longues sorties d'outils : on peut les relire.

## Code, en résumé (détails dans `docs/architecture.md`)

- Petites fonctions génériques, une seule responsabilité chacune, assemblées par composition.
- Valeurs pilotées par les données, aucune valeur en dur.
- Modules découplés par interfaces et événements.
- Logique séparée de l'affichage, pour pouvoir la tester.
- Aucun texte visible en dur : tout passe par les tables de traduction.
- Les données enregistrées de l'utilisateur ont un numéro de version et une migration depuis chaque version précédente.
- « Fini » veut dire : `verifier.ps1` vert (performance comprise), essayé en vrai, diff relu, docs à jour, commit fait et poussé.

## Qualité : zéro bug

- Tests d'abord : chaque brique de logique a ses tests, écrits avant le code.
- Un bug corrigé commence par un test qui le reproduit. Chaque bug trouvé devient une issue GitHub, avec les étapes pour le reproduire.
- Le geste des trente secondes : après une correction, remettre le défaut un instant et voir le test échouer. Un test vert sur la version fautive ne protège de rien.
- Un test vise le comportement, jamais une ligne recopiée. Un test qui vérifie une absence prouve qu'il a lu quelque chose.
- `outils/verifier.ps1` lance toutes les vérifications, en entier. Il doit être vert avant de finir une tâche et avant chaque commit : les hooks y veillent. On y ajoute chaque nouvelle sorte de vérification.
- Zéro warning, zéro erreur dans les logs, aucune erreur silencieuse.
- Des logs abondants, et toujours par le module de log du projet. Ils couvrent chaque changement d'état, chaque décision avec son pourquoi, et chaque erreur avec son contexte. Les règles et l'emplacement des fichiers sont dans `docs/architecture.md`.
- Pour un bug, lire d'abord les logs. Si les logs n'ont pas suffi à le comprendre, ajouter ceux qui ont manqué.
- Jamais `--no-verify`, jamais un test désactivé ou affaibli pour passer.

## Performance

- Rien de ce qu'on ajoute ne doit ralentir le programme. Un ralentissement est un bug.
- Les budgets chiffrés sont dans `docs/architecture.md`. Les tests de performance de `outils/verifier.ps1` échouent au-delà du budget du PC de développement, ou si une mesure régresse de plus de 10 %.
- Chaque plan dit ce que la fonctionnalité coûte en performance. On mesure avant d'optimiser, et une mesure s'écrit avec sa machine, son paramètre et sa date.
- Dans le code chaud, c'est-à-dire ce qui tourne à chaque image, à chaque requête ou pour chaque élément d'une longue liste : aucune allocation, des références en cache, des pools d'objets, des événements plutôt que des vérifications répétées.

## Sécurité et droits

- Aucun secret dans le dépôt ni dans ce qui est livré : ils vivent dans un fichier ignoré par git. Le hook `pre-commit` bloque un commit qui en contient un. Claude ne saisit ni n'affiche jamais un secret.
- Toute donnée qui entre (fichier chargé, message réseau) est validée à la frontière, et ne fait jamais planter.
- Dépendances de sources connues, en version fixée, mises à jour une à la fois.
- Licences : Claude ne tient pas de registre, il avertit. Un contenu externe, une licence inconnue ou copyleft, une marque d'autrui : « ⚠ » en une ligne, au moment où ça arrive. Un contenu généré par IA destiné au produit : l'avertissement renforcé « ⚠⚠ », en entier (déclaration aux boutiques, droits de la formule, protection, trace). Le texte des avertissements est dans le skill, `reference/securite-et-droits.md`.

## Génération par IA

- Avant de générer, la fiche à jour du modèle dans `docs/generation-ia/modeles/` (le hook `garde-generation-ia` l'exige), la bible de style `docs/generation-ia/style.md`, et le coût dit avant une série. Détails dans le skill, `reference/generation-ia.md`.

## Carte du projet

@docs/README.md
