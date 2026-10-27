# Feuille de route

Les étapes du projet, de l'état actuel à la livraison, dans l'ordre où on les construit. C'est le chemin léger, pour un petit projet (un outil, une bibliothèque, un essai de quelques semaines) : trois phases. S'il grandit, on passe à la feuille de route complète du skill.

- Une case est une session : une fonctionnalité, construite selon les règles de CLAUDE.md. On la coche quand elle est finie au sens de `architecture.md`, dans le même commit.
- Les cases sont numérotées par phase (1.1, 1.2…), pour pouvoir les citer.
- Chaque phase démarre sur le feu vert de l'utilisateur.
- Une étape ajoutée, déplacée ou abandonnée est reportée ici dans la même session.

## Où on en est

Réécrit à la fin de chaque session, jamais allongé : c'est la première chose qu'on lit en reprenant. L'histoire est dans `git log`.

{{DATE}} : {{CE QUI EST FINI}}. Prochaine session : {{ÉTAPE}}.

## Phase 0 : fondations

- [ ] **0.1 Démarrage.** `preparer-projet.ps1`, les docs remplies, git, les hooks et le dépôt GitHub.
- [ ] **0.2 Squelette et vérification.** La structure d'`architecture.md`, les dépendances en version fixée, `outils/verifier.ps1` avec les premiers tests, et le module de log.

## Phase 1 : construction

{{CE QUE LE PROJET DOIT FAIRE, EN UNE PHRASE}}. Il s'utilise à la fin de chaque étape.

- [ ] **1.1 {{FONCTIONNALITÉ}}.** {{CE QUE LA SESSION CONSTRUIT}}

## Phase 2 : livraison

- [ ] **2.1 Version 1.0.** Le README dit comment l'installer et s'en servir, la version est taguée, et elle est publiée : {{OÙ : un paquet, une release GitHub, ou nulle part}}.
