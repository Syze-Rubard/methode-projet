---
name: methode-projet
description: Méthode de travail pro avec Claude Code, commune à tous les projets de l'utilisateur. Structure de doc (CLAUDE.md, carte du projet, architecture, mémoire versionnée dans le projet), une fonctionnalité par session, checklist de fin de tâche, gestion du contexte (/clear, compaction), hooks et git. À utiliser pour démarrer un nouveau projet, remettre de l'ordre dans un projet existant, vérifier qu'un projet suit la méthode, ou améliorer la méthode elle-même.
---

# Méthode projet

Une méthode pour mener un gros projet avec Claude Code sans perdre en qualité ni en mémoire. Elle tient en quatre idées :
1. **Tout ce qui compte est écrit sur le disque.** Une session neuve ne perd rien, donc on repart de zéro à chaque fonctionnalité.
2. **Un sujet par document, sans doublon.** Chaque info a une seule place, et une carte dit laquelle.
3. **Petit bout par petit bout.** Une fonctionnalité par session, testée et commitée avant la suivante.
4. **Automatiser plutôt que se fier aux consignes.** Ce qui doit arriver à coup sûr passe par un hook ou un réglage.

## Les scripts

Deux scripts du dossier de ce skill font l'installation. Les lancer avec `powershell -NoProfile -ExecutionPolicy Bypass -File "<dossier du skill>\<script>.ps1"`. Ils ne détruisent rien et se relancent sans risque. Chaque ligne de leur sortie commence par un état : `[ok]`, `[créé]`, `[installé]`, `[réglé]`, `[à faire]` ou `[à remplir]`.

- **`preparer-pc.ps1`**, une fois par PC :
  - il installe avec winget ce qui manque (git, Git LFS, GitHub CLI) et active Git LFS ;
  - il relie le skill à Claude Code et vérifie la compaction automatique.

  Avant de le lancer, prévenir l'utilisateur que Windows peut lui demander d'autoriser une installation. Puis l'aider sur chaque `[à faire]` :
  - **identité git** : lui demander un nom et un e-mail, puis relancer avec `-NomGit` et `-EmailGit`. Si un dépôt peut devenir public, proposer l'adresse « noreply » de GitHub ;
  - **connexion à GitHub** : `gh auth login`, lancé par l'utilisateur dans un nouveau terminal, jamais par Claude ;
  - **compaction** : `/autocompact 300k`, que l'utilisateur tape lui-même.

  Relancer le script jusqu'à ce qu'il ne reste rien à faire.
- **`preparer-projet.ps1 -Chemin <dossier> [-Nom <nom>] [-Techno base|unity]`**, pour chaque projet et sur chaque PC :
  - il copie les modèles sans écraser un fichier existant ;
  - il dirige la mémoire de Claude Code vers `docs/memoire`, et corrige le chemin si le disque a changé de lettre ;
  - il initialise git, avec LFS si la techno en a besoin ;
  - il liste les `{{...}}` qui restent à remplir.

Les modèles :
- `modeles/projet/` contient les fichiers communs à tous les projets ;
- `modeles/techno/<techno>/` contient le `.gitignore` et le `.gitattributes` de chaque techno ;
- le script remplit `{{NOM}}` et `{{nom}}`, et Claude remplit les autres `{{...}}`.

## Démarrer un projet

1. Demander à l'utilisateur le nom du projet, son pitch en une phrase, la techno, et le document de conception (GDD, cahier des charges…) s'il existe.
2. Lancer `preparer-pc.ps1`. Si tout est `[ok]`, passer à la suite.
3. Lancer `preparer-projet.ps1` sur le dossier du projet.
4. Remplir chaque `{{...}}` listé, retirer ce qui ne sert pas, et compléter la fiche projet de la mémoire et la section « Outils du PC » de la carte (moteur, logiciels, MCP).
5. Faire un premier commit, puis sauvegarder hors du disque : `gh repo create <nom> --private --source . --push`.
6. Dire à l'utilisateur que les hooks et la mémoire prennent effet à la session suivante.

## Reprendre un projet sur un autre PC

1. Lancer `preparer-pc.ps1`.
2. Récupérer le projet : brancher le disque, ou `gh repo clone <nom>`.
3. Lancer `preparer-projet.ps1 -Chemin <dossier du projet>`. Il ne crée que ce qui manque, dont `.claude/settings.local.json`, que git ne suit pas.
4. Installer avec l'utilisateur les outils de la section « Outils du PC » de la carte du projet.
5. Ouvrir une nouvelle session, pour activer les hooks et la mémoire.

## Partager la méthode

- La méthode tient dans le dossier de ce skill. On la partage en dépôt GitHub privé, en ajoutant la personne comme collaboratrice, ou en copie du dossier.
- La personne installe Claude Code, puis suit le `README.md` du dossier : il lui fait lancer `preparer-pc.ps1`.
- Elle a sa propre identité git et son propre compte GitHub. Ses projets ont leur propre mémoire.

## Le cycle d'une fonctionnalité

1. **Session neuve** (`/clear` ou nouvelle session) : CLAUDE.md charge la carte et l'index de la mémoire.
2. **Mode plan** : lire les fiches et docs utiles, puis proposer un plan court. Le plan dit comment la fonctionnalité sera testée : tests automatiques et essai à la main. Attendre l'accord.
3. **Tests d'abord** : écrire les tests du comportement voulu et les voir échouer. Puis construire en petites fonctions génériques jusqu'à ce qu'ils passent.
4. **Vérifier** :
   - `outils/verifier.ps1` au vert ;
   - la fonctionnalité essayée en vrai ;
   - le diff relu avec `/code-review`, et ses trouvailles corrigées.
5. **Checklist de fin de tâche** :
   - mettre à jour chaque document concerné, d'après le tableau « Qui tient quoi à jour » de la carte ;
   - ajouter à la mémoire toute info durable (décision, préférence, état du projet) ;
   - commiter, puis pousser.
6. **`/clear`** : le hook `rappel-clear` prévient l'utilisateur après un commit, ou quand le contexte dépasse 150k tokens.

## Qualité : zéro bug

Le but est un projet sans bug. Chaque moyen ci-dessous attrape des bugs que les autres laissent passer, donc on les cumule.

**À chaque changement :**
- **Tests d'abord** pour chaque brique de logique. Un test décrit un comportement, pas le code.
- **Un bug corrigé commence par un test** qui le reproduit et échoue. La correction le fait passer, et le bug ne revient plus.
- **Toute la suite de tests**, pas seulement ceux du jour. C'est elle qui voit ce qu'un changement casse ailleurs.
- **Les données testées comme le code** : un test charge chaque fichier de données et vérifie ses références et ses bornes.
- **Zéro warning et zéro erreur dans les logs.** Un warning toléré en cache un autre.
- **Échouer bruyamment.** On vérifie les entrées aux frontières des modules, on met des assertions sur ce qui « ne peut pas arriver », et jamais de `catch` vide.
- **Relire le diff** avec `/code-review` avant de commiter une fonctionnalité, et corriger ce qu'il trouve.
- **Jamais `--no-verify`**, jamais un test désactivé ou affaibli pour passer. Si un test gêne, on corrige le code ou le test, avec l'accord de l'utilisateur.

**Les garde-fous automatiques :**
- **`outils/verifier.ps1`** est la commande unique qui lance toutes les vérifications du projet : compilation, tests, données, analyse. Il ne sort à 0 que si tout passe.
  - Il est créé dès le premier code, à partir de `modeles/outils/verifier.ps1`.
  - Chaque nouvelle sorte de vérification y est ajoutée.
- **Le hook git `pre-commit`** le lance avant chaque commit, de Claude comme de l'utilisateur, et bloque le commit si c'est rouge.
- **Le hook Claude Code `garde-tests`** renvoie Claude au travail s'il veut finir alors que du code a changé depuis la dernière vérification réussie.
- **L'intégration continue** (GitHub Actions) est à mettre en place dès que le projet a du code : elle relance la vérification à chaque push, sur une machine propre.

**Les bugs trouvés :** chacun suit le même chemin.
1. Une issue GitHub (`gh issue create`), avec les étapes pour le reproduire.
2. Un test qui le reproduit.
3. La correction.
4. Un commit qui ferme l'issue (`Fixes #N`).

**Pour un jeu, en plus :**
- une graine pour tout l'aléatoire, notée dans chaque rapport de bug : tout bug se rejoue à l'identique ;
- des tests de jeu automatiques, et un test de fumée qui charge chaque scène et joue quelques secondes sans erreur ;
- dans les builds, un log et un rapport de crash qui notent la version et la graine.

Aucune phase de production ne démarre sans le feu vert explicite de l'utilisateur.

## Documents

| Document | Rôle | Règle |
|---|---|---|
| `CLAUDE.md` | Règles chargées à chaque session | Moins de 200 lignes ; importe la carte et l'index de mémoire avec `@` |
| `docs/README.md` | La carte : arborescence, documents hors du dossier, « qui tient quoi à jour » | Mise à jour dès qu'un dossier ou un doc bouge |
| `docs/architecture.md` | Principes de code, structure, conventions, décisions techniques avec leur pourquoi | Mise à jour quand un module, une convention ou une décision change |
| `docs/memoire/` | Mémoire de Claude : index `MEMORY.md`, une fiche par sujet | Voir « Mémoire » |
| Document de conception | Le design, source de vérité | Document vivant : mis à jour à chaque fonctionnalité ou décision, compact, ce qui est abandonné est retiré |

Si le document de conception est un Claude Doc, chaque passe de modifs est marquée : surlignage dans le texte, cellules bleues `#e7f1fb` dans les tableaux. Les marques précédentes sont retirées quand l'utilisateur dit avoir relu.

## Mémoire

- La mémoire vit dans le projet (`docs/memoire/`) et se versionne avec lui : elle suit le disque, le dépôt et chaque PC.
- `.claude/settings.local.json` contient `"autoMemoryDirectory": "<chemin absolu>/docs/memoire"` : la mémoire automatique de Claude Code écrit directement là, sans copie. Claude Code ignore ce réglage dans `settings.json`, d'où le fichier local, que `preparer-projet.ps1` crée sur chaque PC et corrige si le disque change de lettre.
- Une fiche par sujet (frontmatter `name`, `description`, `metadata.type` : user, feedback, project ou reference), une ligne par fiche dans `MEMORY.md`. Mettre à jour plutôt que dupliquer, et ne pas recopier ce que CLAUDE.md ou le code disent déjà.
- Fiches en anglais, docs en français.

## Contexte : /clear et compaction

- **`/clear`** vide la conversation et repart de zéro dans la même fenêtre. CLAUDE.md, la carte et la mémoire sont rechargés, rien sur le disque n'est perdu, et l'ancienne conversation reste accessible avec `/resume`. À faire après chaque fonctionnalité commitée, ou quand on change de sujet.
- **`/compact`** résume la conversation au lieu de la vider. Utile au milieu d'une tâche longue, avec une consigne : `/compact garde le plan et les fichiers modifiés`.
- **`/autocompact 300k`** déclenche la compaction automatique à 300k tokens. Plus haut, chaque message coûte cher et la précision baisse ; plus bas, on résume trop souvent.
- La section « Compaction » de CLAUDE.md dit quoi garder quand la conversation est résumée.

## Code

- Petites fonctions génériques, une seule responsabilité, assemblées par composition.
- Valeurs pilotées par les données, jamais en dur.
- Modules découplés par interfaces et événements, frontières vérifiées par le compilateur quand la techno le permet.
- Logique séparée de l'affichage, pour pouvoir la tester.
- Avant d'écrire du code, chercher une brique existante à réutiliser ou à généraliser.
- « Fini » : `verifier.ps1` vert, essayé en vrai, diff relu, docs à jour, commit fait et poussé.

## Hooks

- Écrits en PowerShell 5.1, présent sur tout Windows, et enregistrés en UTF-8 avec BOM : sans BOM, les accents sont cassés.
- Déclarés en forme exec dans `.claude/settings.json` (`"command": "powershell.exe"` et `"args"`), avec un chemin relatif au projet : ça marche que Claude Code passe par Git Bash ou par PowerShell.
- Tester un hook en lui envoyant un JSON d'exemple sur l'entrée standard avant de le déclarer.
- `rappel-clear.ps1` (Stop) affiche un message à l'utilisateur après un nouveau commit, et quand le contexte franchit 150k, 250k, 350k tokens… Les seuils sont en tête du script.
- `garde-tests.ps1` (Stop et `pre-commit`) retient l'empreinte des fichiers qui ont passé `verifier.ps1`. Les docs et les `.md` n'en font pas partie. Il ne fait rien tant que le projet n'a pas de `verifier.ps1`. Il renvoie Claude au travail une seule fois par tour, pour ne pas boucler.
- Les hooks git vivent dans `.githooks/`, versionnés, avec des fins de ligne LF (règle dans `.gitattributes`). `preparer-projet.ps1` les active, et Git LFS y écrit aussi les siens.

## Phases d'un jeu vidéo (exemple Steam)

0. Fondations : git, moteur, CLAUDE.md, MCP, skills et hooks.
1. Prototype gray-box jouable, sur une base réseau si le jeu a de la coop.
2. Direction artistique et page Steam « Coming Soon », en parallèle.
3. Tranche verticale : un niveau complet, à la qualité finale.
4. Démo et Steam Next Fest.
5. Sprints de contenu, accès anticipé possible.
6. Lancement.

## Améliorer la méthode

La méthode vit dans le dossier de ce skill, un dépôt git que `preparer-pc.ps1` relie à `~/.claude/skills/methode-projet`. Quand une façon de travailler s'améliore sur un projet :
1. modifier ce fichier, les scripts ou les modèles. Un nouveau fichier commun va dans `modeles/projet/`, une nouvelle techno dans `modeles/techno/<techno>/` ;
2. noter le changement et son pourquoi dans `CHANGELOG.md` ;
3. commiter, et pousser si le dépôt a un remote.

Les projets existants ne sont pas mis à jour d'office : proposer à l'utilisateur de reporter le changement.
