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

## Démarrer un projet

1. Demander à l'utilisateur le nom du projet, son pitch en une phrase, la techno, et le document de conception (GDD, cahier des charges…) s'il existe.
2. Créer la structure à partir des modèles de `modeles/`, en remplaçant les `{{...}}` et en retirant ce qui ne sert pas :

   | Fichier du projet | Modèle |
   |---|---|
   | `CLAUDE.md` | `modeles/CLAUDE.modele.md` |
   | `docs/README.md` (la carte) | `modeles/docs/README.md` |
   | `docs/architecture.md` | `modeles/docs/architecture.md` |
   | `docs/memoire/MEMORY.md` et une fiche `project-<nom>.md` | `modeles/docs/memoire/MEMORY.md` |
   | `.claude/settings.json` (hooks) | `modeles/.claude/settings.json` |
   | `.claude/settings.local.json` | `modeles/.claude/settings.local.json`, avec le chemin absolu du projet |
   | `.claude/hooks/rappel-clear.ps1` | `modeles/.claude/hooks/rappel-clear.ps1`, copié avec `Copy-Item` pour garder le BOM |
   | `.gitignore`, `.gitattributes` | `modeles/unity/` pour Unity ; sinon les adapter à la techno |

3. `git init -b main`, puis `git lfs install --local` si le projet a des assets lourds, puis un premier commit.
4. Sauvegarde hors du disque : `gh repo create <nom> --private --source . --push`. Si `gh` manque : `winget install --id GitHub.cli`, puis l'utilisateur lance lui-même `gh auth login`.
5. Conseiller `/autocompact 300k` si l'utilisateur ne l'a pas réglé.

Les hooks et `autoMemoryDirectory` ne prennent effet qu'à la session suivante.

## Le cycle d'une fonctionnalité

1. **Session neuve** (`/clear` ou nouvelle session) : CLAUDE.md charge la carte et l'index de la mémoire.
2. **Mode plan** : lire les fiches et docs utiles, proposer un plan court, attendre l'accord.
3. **Construire** en petites fonctions génériques, puis **tester**.
4. **Checklist de fin de tâche** :
   - mettre à jour chaque document concerné, d'après le tableau « Qui tient quoi à jour » de la carte ;
   - ajouter à la mémoire toute info durable (décision, préférence, état du projet) ;
   - commiter, puis pousser.
5. **`/clear`** : le hook `rappel-clear` prévient l'utilisateur après un commit, ou quand le contexte dépasse 150k tokens.

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
- `.claude/settings.local.json` contient `"autoMemoryDirectory": "<chemin absolu>/docs/memoire"` : la mémoire automatique de Claude Code écrit directement là, sans copie. Claude Code ignore ce réglage dans `settings.json`, d'où le fichier local, à recréer sur chaque PC et à corriger si le disque change de lettre.
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
- Logique séparée de l'affichage, et testée.
- Aucune erreur silencieuse.
- Avant d'écrire du code, chercher une brique existante à réutiliser ou à généraliser.
- « Fini » : compile sans warning, tests verts, vérifié en vrai, docs à jour, commit fait.

## Hooks

- Écrits en PowerShell 5.1, présent sur tout Windows, et enregistrés en UTF-8 avec BOM : sans BOM, les accents sont cassés.
- Déclarés en forme exec dans `.claude/settings.json` (`"command": "powershell.exe"` et `"args"`), avec un chemin relatif au projet : ça marche que Claude Code passe par Git Bash ou par PowerShell.
- Tester un hook en lui envoyant un JSON d'exemple sur l'entrée standard avant de le déclarer.
- `rappel-clear.ps1` (Stop) affiche un message à l'utilisateur après un nouveau commit, et quand le contexte franchit 150k, 250k, 350k tokens… Les seuils sont en tête du script.

## Phases d'un jeu vidéo (exemple Steam)

0. Fondations : git, moteur, CLAUDE.md, MCP, skills et hooks.
1. Prototype gray-box jouable, sur une base réseau si le jeu a de la coop.
2. Direction artistique et page Steam « Coming Soon », en parallèle.
3. Tranche verticale : un niveau complet, à la qualité finale.
4. Démo et Steam Next Fest.
5. Sprints de contenu, accès anticipé possible.
6. Lancement.

## Améliorer la méthode

La méthode vit dans `I:\Projets\methode-projet`, un dépôt git relié à `~/.claude/skills/methode-projet` par `install.ps1` (à lancer une fois par PC). Quand une façon de travailler s'améliore sur un projet :
1. modifier ce fichier ou les modèles ;
2. noter le changement et son pourquoi dans `CHANGELOG.md` ;
3. commiter, et pousser si le dépôt a un remote.

Les projets existants ne sont pas mis à jour d'office : proposer à l'utilisateur de reporter le changement.
