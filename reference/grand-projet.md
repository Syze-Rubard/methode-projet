# Quand le projet grandit

À lire quand l'un de ces signes apparaît, pas avant :
- CLAUDE.md approche 200 lignes, ou `MEMORY.md` 50 lignes ;
- les décisions débordent d'`architecture.md` ;
- un même piège a coûté du temps deux fois ;
- plusieurs sessions ou agents travaillent en même temps sur le dépôt ;
- le produit est en ligne, avec de vrais utilisateurs.

Tout ce qui suit vient d'un service web en ligne depuis des mois et construit par de nombreux agents. Chaque règle y a coûté des heures avant d'être écrite.

Sommaire :
1. Ce qui se charge, et quand
2. Un rangement qui tient
3. Les décisions, les invariants et les pièges
4. L'état courant
5. Plusieurs sessions en parallèle
6. L'effort et les agents
7. La production

## 1. Ce qui se charge, et quand

Ce qui est chargé à chaque session est payé à chaque message, et par chaque sous-agent. C'est un budget.

| Quoi | Chargé | Budget |
|---|---|---|
| `CLAUDE.md`, ses `@imports` et les règles sans `paths:` | chaque session, chaque sous-agent, et de nouveau après `/compact` | moins de 200 lignes en tout : les commandes, les invariants, la façon de travailler, où chercher |
| `docs/memoire/MEMORY.md` | chaque session principale, pas les sous-agents ; coupé au-delà de 200 lignes ou 25 Ko | une cinquantaine de lignes : ce qui sert à chaque session ; la liste complète des fiches dans `index-complet.md`, lu à la demande |
| une règle `.claude/rules/*.md` avec `paths:` | quand Claude lit ou modifie un fichier qui correspond | quelques lignes, qui renvoient au bon sommaire |
| un skill | quand il est appelé, puis jusqu'à la fin de la session ; seul son début survit à une compaction | `SKILL.md` court, le détail dans des fichiers lus à la demande |
| tout le reste | quand Claude l'ouvre | un sommaire d'un écran en tête de chaque gros fichier |

- Un `@import` range un long CLAUDE.md, mais ne réduit pas ce qu'il coûte.
- `MEMORY.md` ne s'importe jamais dans CLAUDE.md : la mémoire automatique le charge déjà, il serait lu deux fois.
- Pas d'histoire dans une carte, un index ou un sommaire : `git log` la garde. Un en-tête dit ce qu'on trouve dans le fichier, pas comment il a été recompté.
- Une ligne qui décrit un état (un compte, une taille, une durée) porte la date de sa mesure, et n'existe qu'à un endroit : deux copies d'un chiffre divergent au premier passage.
- Un gros fichier (journal, log) se fouille avec `grep`, il ne se lit jamais en entier.

## 2. Un rangement qui tient

- La carte (`docs/README.md`) dit où vit chaque chose. Claude lit la carte, pas la liste des dossiers.
- La racine ne garde que ce que les outils exigent d'y trouver (manifeste, configurations, CLAUDE.md, README) et les grands dossiers : le code, les tests, `docs/`, les outils, le déploiement.
- Les fichiers de travail vont dans `brouillons/AAAA-MM-JJ/<sujet>/`, ce qui est vieux dans `archives/`. Jamais à la racine d'un disque, ni à côté du dépôt. Claude vérifie ce rangement de temps en temps, sans attendre qu'on le demande.
- On ne déplace un fichier que si le gain dépasse le coût : un fichier déplacé casse chaque chemin qui le cite, dans le code, les tests, les docs et les décisions.

## 3. Les décisions, les invariants et les pièges

**Les décisions** : `docs/decisions/AAAA-MM-JJ-sujet.md`, un fichier par choix, avec son contexte, son pourquoi et ce qu'on a écarté.
- Jamais déplacé, renommé ni supprimé : le code et les tests les citent par leur chemin. Une décision plus récente remplace l'ancienne et le dit.
- Une décision qui n'existe que dans un commentaire sera défaite par le prochain agent.

**Les invariants** : en tête de CLAUDE.md, les quelques règles qu'on ne casse pas sans une décision écrite et datée, chacune avec le lien de sa décision.

**Les pièges** : `docs/pieges/<domaine>.md`, un fichier par domaine (données, interface, réseau, build, déploiement, tests, outillage…).
- Chaque fichier s'ouvre sur un sommaire d'un écran, qui dit ce qu'on y trouve et s'il faut lire la suite.
- Une entrée s'ajoute dès qu'un piège a coûté du temps. Les entrées sont numérotées dans l'ordre d'écriture, et jamais renumérotées : on les cite. Chacune a sa date, le symptôme, la cause, le chiffre mesuré et la parade.
- Les dix leçons les plus chères tiennent en une ligne chacune dans CLAUDE.md, avec le lien de leur domaine.
- Une règle par domaine dans `.claude/rules/` fait ouvrir le bon sommaire au bon moment, et ne coûte rien le reste du temps :

```markdown
---
paths:
  - "src/db/**"
  - "**/*.sql"
---

Tu touches la base de données. Avant d'écrire, lis le sommaire de `docs/pieges/donnees.md`, puis ouvre seulement les entrées qui concernent ton geste.
```

## 4. L'état courant

- Un fichier court dit où on en est : en production, ce qui tourne (branches, travaux lancés et leur identifiant), la suite dans l'ordre, les questions ouvertes à l'utilisateur. C'est « Où on en est » de la feuille de route ; quand beaucoup de choses sont en vol, `docs/memoire/etat-courant.md`, avec sa ligne dans `MEMORY.md`.
- Moins de 60 lignes, daté, et **réécrit** à chaque étape, jamais allongé. L'histoire va dans un journal à part, qu'on fouille avec `grep`.
- On le lit en premier à chaque reprise.
- Une date s'écrit d'après l'horloge (`date`, `git log -1 --date=iso`), jamais de tête.
- Avant d'écrire « c'est arrêté » ou « c'est fini », lire ce qui le prouve (un horodatage, l'état d'un travail), pas un drapeau qui peut vouloir dire autre chose.

## 5. Plusieurs sessions en parallèle

- CLAUDE.md est le seul contexte que les sessions partagent : le tenir à jour, c'est se coordonner.
- Chaque chantier dans sa branche, ou son arbre de travail (`git worktree`). Il entre dans la branche principale une fois la vérification complète au vert.
- Une fonctionnalité neuve s'écrit dans des fichiers neufs. Un travail de robustesse ne touche pas au contrat de données sans une décision.
- Un test rouge ou une erreur de compilation appartient au travail en cours, jamais à « l'autre session » : on répare, on ne filtre pas.
- Avant de modifier un fichier partagé, relire `git status` et `git log` ; commiter petit et vite.

## 6. L'effort et les agents

- **Seul par défaut.** Un sous-agent sert quand le travail lit beaucoup de fichiers dont seule la conclusion compte, ou quand il est long et indépendant.
- **Les trois types d'agents du modèle** (`.claude/agents/`) fixent l'effort, que l'outil Agent ne règle pas autrement :
  - `leger` (effort bas) : le mécanique, comme lancer la vérification et rapporter, compter, lister, renommer, fusionner sans conflit ;
  - `moyen` : exécuter un plan détaillé, corriger des constats clairs, tester selon un protocole écrit ;
  - `haut` : une logique non triviale, la relecture adverse de ce qui touche aux données, aux droits, à la sécurité ou à la concurrence.

  Au-delà, l'agent général, qui hérite de l'effort de la session.
- **Un workflow** (plusieurs agents orchestrés) seulement si l'utilisateur le demande ou si la tâche le justifie vraiment : sept agents au plus, chaque étape avec son effort. Le mode ultracode ne vaut pas autorisation. Un workflow interrompu se reprend sans rien refaire, si son script et ses arguments n'ont pas changé.
- **Le résultat d'un agent se relit** avant d'être rapporté : son résumé n'est pas une preuve.
- Un agent purement mécanique, qui n'écrit rien, peut partir sans CLAUDE.md (`omitClaudeMd: true`).

## 7. La production

- Chaque déploiement attend le feu vert explicite de l'utilisateur, pour ce déploiement-là. Le numéro de version monte à chaque livraison.
- Une mesure porte le nom de sa machine : avec une copie locale et un serveur, « vérifié sur la production » ne veut rien dire.
- Un build ou un test n'ouvre jamais la base de production : une garde le refuse, et seul le vrai lanceur porte le laissez-passer.
- Le script de déploiement refuse de tourner pendant une tâche planifiée du serveur (cycle de nuit, sauvegarde).
- À chaque changement visible, une page de recette pour l'utilisateur : les étapes, le résultat attendu exact, et une case « OK / pas OK » qu'il coche. Claude lit les résultats, sans demander de récit.
