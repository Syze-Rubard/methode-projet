---
name: methode-projet
description: Méthode de travail avec Claude Code, commune à tous les projets de code de l'utilisateur (jeu PC, console ou mobile, appli mobile, logiciel de bureau, site ou service web, outil, bibliothèque) — un projet rangé que Claude lit comme un livre ouvert, une fonctionnalité par session, zéro bug, le moins de tokens possible. Docs et mémoire versionnées dans le projet, hooks, git, vérification complète avant chaque commit. À utiliser pour démarrer un projet, le reprendre sur un autre PC, remettre de l'ordre dans un projet existant, vérifier qu'il suit la méthode, ou améliorer la méthode elle-même.
---

# Méthode projet

Une méthode pour mener un gros projet de code avec Claude Code sans perdre en qualité ni en mémoire, que ce soit un jeu, une appli mobile, un logiciel, un site web ou un outil. Elle tient en six idées :
1. **Tout ce qui compte est écrit sur le disque.** Une session neuve ne perd rien, donc on repart de zéro à chaque fonctionnalité.
2. **Un sujet par document, sans doublon.** Chaque info a une seule place, et une carte dit laquelle.
3. **Petit bout par petit bout.** Une fonctionnalité par session, testée et commitée avant la suivante.
4. **Automatiser plutôt que se fier aux consignes.** Ce qui doit arriver à coup sûr passe par un hook ou un réglage.
5. **Juste ce qu'il faut, au bon moment.** Chaque outil se met en place quand le premier code en a besoin, pas avant : le vérificateur avec le premier code, les tests de performance avec le premier écran utilisable, les tests réseau avec le premier échange réseau. Une règle qui coûte plus qu'elle ne rapporte est signalée à l'utilisateur.
6. **Économiser les tokens.** Le projet est rangé pour que Claude y lise comme dans un livre ouvert, l'effort suit la difficulté de la tâche, et les réponses vont droit au but. Voir « Économiser les tokens ».

## Où lire la suite

Ce fichier tient l'essentiel. Le détail est dans `reference/`, à ouvrir seulement quand la tâche en a besoin :

| Fichier | À ouvrir pour |
|---|---|
| `reference/installation.md` | démarrer un projet, le reprendre sur un autre PC, partager la méthode ; les scripts, les hooks, les pièges du poste Windows |
| `reference/qualite.md` | remplir `architecture.md` ; créer `verifier.ps1`, les premiers tests, le module de log, les tests de performance |
| `reference/securite-et-droits.md` | un secret, une dépendance, des données qui entrent, la sauvegarde ; le texte des avertissements de licence (⚠ et ⚠⚠) |
| `reference/generation-ia.md` | avant de générer une image, une vidéo, un modèle 3D ou un son |
| `reference/types-de-projet.md` | au démarrage et à chaque phase : ce qui change selon le type de projet |
| `reference/grand-projet.md` | quand le projet grandit : ce qui se charge et son budget, décisions, pièges, règles par chemin, état courant, sessions en parallèle, agents, production |

## Démarrer, reprendre, contrôler

- **Démarrer un projet** : demander le nom, le pitch en une phrase, le type, la techno et le document de conception ; lancer `preparer-pc.ps1`, puis `preparer-projet.ps1` ; remplir les `{{...}}`. Le pas à pas est dans `reference/installation.md`.
- **Reprendre sur un autre PC** : `preparer-pc.ps1`, récupérer le projet, `preparer-projet.ps1`, puis une nouvelle session.
- **Remettre de l'ordre, ou vérifier qu'un projet suit la méthode** : passer le « Contrôle » en bas de ce fichier, puis proposer à l'utilisateur ce qui manque, du plus utile au moins utile. Rien ne s'impose : un projet qui marche ne se casse pas pour coller à la méthode.

## Le cycle d'une fonctionnalité

1. **Session neuve** (`/clear` ou nouvelle session) : CLAUDE.md charge la carte, la mémoire automatique charge son index. « Où on en est » dit où on en est ; la prochaine étape est la première case non cochée de `docs/feuille-de-route.md`.
2. **Mode plan** : lire les fiches et docs utiles, puis proposer un plan court. Le plan dit comment la fonctionnalité sera testée (tests automatiques et essai à la main) et ce qu'elle coûte en performance. Attendre l'accord.
3. **Tests d'abord** : écrire les tests du comportement voulu et les voir échouer. Puis construire en petites fonctions génériques jusqu'à ce qu'ils passent.
4. **Vérifier** :
   - `outils/verifier.ps1` au vert ;
   - la fonctionnalité essayée en vrai ;
   - le diff relu avec `/code-review`, et ses trouvailles corrigées.
5. **Checklist de fin de tâche** :
   - mettre à jour chaque document concerné, d'après le tableau « Qui tient quoi à jour » de la carte ;
   - cocher la case de la feuille de route, et réécrire « Où on en est » ;
   - ajouter à la mémoire toute info durable (décision, préférence, état du projet) ;
   - commiter, puis pousser.
6. **`/clear`** : le hook `rappel-clear` prévient l'utilisateur après un commit, ou quand le contexte dépasse 150k tokens.

Aucune phase de production ne démarre sans le feu vert explicite de l'utilisateur.

## Vérifier : zéro bug

Le détail (le code, les garde-fous, les logs, la performance) est dans `reference/qualite.md`. L'essentiel :
- **Une seule commande vérifie tout** : `outils/verifier.ps1`, créé avec le premier code. Le hook git `pre-commit` la lance avant chaque commit, le hook `garde-tests` empêche Claude de finir sur du code non vérifié.
- **Tests d'abord**, et un bug corrigé commence par un test qui le reproduit.
- **Le geste des trente secondes** : après une correction, remettre le défaut un instant et voir le test échouer. Un test vert sur la version fautive ne protège de rien.
- **Un test vise le comportement**, jamais une ligne recopiée. Un test qui vérifie une absence prouve qu'il a lu quelque chose.
- **Toute la suite**, jamais seulement les tests du jour.
- **Zéro warning**, des erreurs bruyantes, jamais de `catch` vide, jamais `--no-verify`, jamais un test affaibli pour passer.
- **Mesurer, pas deviner** : une mesure porte sa machine, son paramètre et sa date ; deux versions se comparent en alternant ; ce qu'un système annonce savoir faire n'est pas une mesure.

## Économiser les tokens

Chaque token lu ou écrit coûte. La méthode sert aussi à en dépenser le moins possible, sans rien perdre en qualité.

- **Un projet rangé se lit vite.** La carte dit où est chaque chose, l'index de la mémoire dit quelle fiche ouvrir, et chaque document traite un seul sujet, en restant compact. Claude va droit à la bonne section, sans tout parcourir.
- **Ce qui se charge à chaque session est un budget.** CLAUDE.md et la carte qu'il importe : moins de 200 lignes. `MEMORY.md` : une cinquantaine de lignes, et jamais importé dans CLAUDE.md, car la mémoire automatique le charge déjà. Tout le reste se lit à la demande. Le tableau complet est dans `reference/grand-projet.md`.
- **Pas d'histoire dans une carte, un index ou un sommaire** : `git log` la garde. Un état n'est écrit qu'à un endroit, avec sa date.
- **Lire juste ce qu'il faut** : la section utile d'un fichier plutôt que le fichier entier, une recherche ciblée plutôt qu'une lecture complète. Ne pas relire ce qu'on vient de lire ou d'écrire.
- **L'effort suit la difficulté de la tâche.** Une question, un réglage, une installation ou une petite vérification se font seul, en quelques commandes ciblées. Un sous-agent prend le type qui fixe son effort : `leger`, `moyen` ou `haut` (modèles dans `.claude/agents/`). Les agents en parallèle et les workflows, même en mode ultracode, sont gardés pour ce qui en a vraiment besoin : un gros audit, une migration, la revue d'une grosse fonctionnalité. Par exemple, relire un paquet tiers avant de l'installer se fait par des recherches ciblées (adresses contactées, fichiers écrits, code exécuté), pas avec cinq agents. En cas de doute, demander à l'utilisateur.
- **Des réponses courtes** : ce qui est fait, ce qui reste, la question à trancher. Pas de récit de chaque étape, ni de liste d'options qu'on ne retiendra pas.
- **`/clear` après chaque fonctionnalité** : une conversation longue fait payer tout son historique à chaque message.

## Documents

| Document | Rôle | Règle |
|---|---|---|
| `CLAUDE.md` | Règles chargées à chaque session, et dans chaque sous-agent | Moins de 200 lignes avec la carte qu'il importe : les commandes, les règles, la façon de travailler. Ni état, ni histoire |
| `docs/README.md` | La carte : arborescence, documents hors du dossier, « qui tient quoi à jour » | Moins de 80 lignes. Mise à jour dès qu'un dossier ou un doc bouge |
| `docs/architecture.md` | Principes de code, structure, conventions, décisions techniques avec leur pourquoi | Mise à jour quand un module, une convention ou une décision change |
| `docs/feuille-de-route.md` | Les étapes jusqu'au lancement, une case par session, regroupées par phase, et « Où on en est » | Case cochée à la fin de sa session, « Où on en est » réécrit. Les phases lointaines restent en grands blocs, découpées en sessions juste avant de les commencer |
| `docs/memoire/` | Mémoire de Claude : l'index `MEMORY.md`, une fiche par sujet | Voir « Mémoire » |
| `docs/generation-ia/` | La bible de style (`style.md`) et une fiche par modèle d'IA générative (`modeles/`) | Voir `reference/generation-ia.md` |
| Document de conception | Le design, source de vérité | Document vivant : mis à jour à chaque fonctionnalité ou décision, compact, ce qui est abandonné est retiré |
| `docs/decisions/`, `docs/pieges/`, `.claude/rules/` | Quand le projet grandit : les choix datés, les leçons payées cher par domaine, et les règles qui les font lire au bon moment | Voir `reference/grand-projet.md` |

Si le document de conception est un Claude Doc, chaque passe de modifs est marquée : surlignage dans le texte, cellules bleues `#e7f1fb` dans les tableaux. Les marques précédentes sont retirées quand l'utilisateur dit avoir relu.

## Mémoire

- La mémoire vit dans le projet (`docs/memoire/`) et se versionne avec lui : elle suit le disque, le dépôt et chaque PC.
- `.claude/settings.local.json` contient `"autoMemoryDirectory": "<chemin absolu>/docs/memoire"` : la mémoire automatique de Claude Code écrit directement là. Le chemin est absolu et change d'un PC à l'autre, d'où ce fichier local non versionné, que `preparer-projet.ps1` crée sur chaque PC et corrige si le disque change de lettre.
- `MEMORY.md` est chargé à chaque session principale (pas dans les sous-agents), coupé au-delà de 200 lignes ou 25 Ko : une ligne par fiche, une cinquantaine de lignes au plus. Quand les fiches se multiplient, `MEMORY.md` garde ce qui sert à chaque session, et `index-complet.md` les liste toutes, lu à la demande.
- Une fiche par sujet (frontmatter `name`, `description`, `metadata.type` : user, feedback, project ou reference). Mettre à jour plutôt que dupliquer, et ne pas recopier ce que CLAUDE.md ou le code disent déjà.
- Une ligne qui décrit un état (un compte, une taille, où on en est) porte la date de sa mesure : elle se périme, et sans date personne ne pense à la vérifier.
- Fiches en anglais, docs en français.

## Contexte : /clear et compaction

- **`/clear`** vide la conversation et repart de zéro dans la même fenêtre. CLAUDE.md, la carte et la mémoire sont rechargés, rien sur le disque n'est perdu, et l'ancienne conversation reste accessible avec `/resume`. À faire après chaque fonctionnalité commitée, ou quand on change de sujet.
- **`/compact`** résume la conversation au lieu de la vider. Utile au milieu d'une tâche longue, avec une consigne : `/compact garde le plan et les fichiers modifiés`.
- **`/autocompact 300k`** déclenche la compaction automatique à 300k tokens. Plus haut, chaque message coûte cher et la précision baisse ; plus bas, on résume trop souvent.
- La section « Compaction » de CLAUDE.md dit quoi garder quand la conversation est résumée.

## Contrôle : un projet suit-il la méthode ?

- `CLAUDE.md` et la carte tiennent sous 200 lignes, sans état ni histoire, avec la consigne de compaction ; `MEMORY.md` n'y est pas importé.
- `MEMORY.md` tient en une cinquantaine de lignes, et chaque ligne d'état porte sa date.
- La carte liste chaque dossier et chaque document ; la racine ne garde que ce que les outils exigent, les fichiers de travail sont dans `brouillons/`, le vieux dans `archives/`.
- « Où on en est » est à jour et daté.
- `.claude/settings.local.json` dirige la mémoire vers le `docs/memoire` de ce PC ; les hooks sont déclarés, et `git config core.hooksPath` vaut `.githooks`.
- Dès qu'il y a du code : `outils/verifier.ps1` existe, passe au vert, et le `pre-commit` le lance.
- Les trois types d'agents sont dans `.claude/agents/`.
- Si le projet a grandi : `docs/decisions/`, `docs/pieges/` ouverts par leurs sommaires, et `.claude/rules/` (voir `reference/grand-projet.md`).

## Améliorer la méthode

La méthode vit dans le dossier de ce skill, un dépôt git public que `preparer-pc.ps1` relie à `~/.claude/skills/methode-projet`. Quand une façon de travailler s'améliore sur un projet :
1. relire `git status` et `git log` du skill, puis `git pull` : d'autres sessions le modifient peut-être en même temps ;
2. modifier ce fichier, une référence, les scripts ou les modèles. `SKILL.md` garde l'essentiel et reste sous 200 lignes ; le détail va dans `reference/`, un niveau de profondeur, chaque fichier ouvert par une ligne qui dit quand le lire. Un nouveau fichier commun va dans `modeles/projet/`. Une nouvelle techno va dans `modeles/techno/<techno>/` : copier `base`, puis ajouter au `.gitignore` le modèle officiel de la techno (dépôt `github/gitignore`) et au `.gitattributes` ses fichiers lourds, suivis par Git LFS ;
3. rien d'un projet privé n'entre dans ce dépôt public : ni nom de serveur, ni chemin, ni secret ;
4. noter le changement et son pourquoi dans `CHANGELOG.md` ;
5. commiter tout de suite, sans attendre la fin de la tâche du projet, et pousser : le skill reste à jour sur chaque PC.

Les projets existants ne sont pas mis à jour d'office : proposer à l'utilisateur de reporter le changement.
