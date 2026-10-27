# Feuille de route

Les étapes du projet, de l'état actuel au lancement, dans l'ordre où on les construit. Le contenu de chaque jalon et son critère de passage sont dans {{DOCUMENT DE CONCEPTION}} : ce document ne les répète pas.

- Une case est une session : une fonctionnalité, construite selon les règles de CLAUDE.md. On la coche quand elle est finie au sens de `architecture.md`, dans le même commit.
- Les cases sont numérotées par phase (1.1, 1.2…), pour pouvoir les citer.
- Chaque phase démarre sur le feu vert de l'utilisateur.
- Les phases lointaines restent en grands blocs. On les découpe en sessions juste avant de les commencer, avec les leçons de la phase précédente.
- Une étape ajoutée, déplacée ou abandonnée est reportée ici dans la même session.

À chaque jalon :
- un tag git ;
- la version livrée passée au profiler sur l'appareil minimal, avec les chiffres notés dans `architecture.md` ;
- un export de chaque document qui vit hors du dossier (voir la carte) ;
- une copie complète du dossier sur un autre support ;
- la phase suivante découpée en sessions, puis le feu vert de l'utilisateur.

## Où on en est

Réécrit à la fin de chaque session, jamais allongé : c'est la première chose qu'on lit en reprenant. L'histoire est dans `git log`.

{{DATE}} : {{CE QUI EST FINI}}. Prochaine session : {{ÉTAPE}}.

## Phase 0 : fondations

- [ ] **0.1 Démarrage.** `preparer-projet.ps1`, les docs remplies, git, les hooks et le dépôt GitHub.
- [ ] **0.2 Décisions techniques.** Les bibliothèques clés, l'appareil minimal et les budgets de performance, l'intégration continue. Une discussion sans code, dont le résultat va dans `architecture.md`.
- [ ] **0.3 Squelette du code.** La structure d'`architecture.md` et les dépendances en version fixée. Si le produit affiche du texte, une première table de traduction.
- [ ] **0.4 MCP et outils de Claude**, si le projet en a besoin : les brancher, puis vérifier que Claude s'en sert.
- [ ] **0.5 `outils/verifier.ps1`.** Compilation sans warning, premiers tests et test de fumée. Les hooks Claude et git l'appellent.
- [ ] **0.6 Logs.** Le module de log du projet, tests d'abord.
- [ ] **0.7 Graine**, si le produit a de l'aléatoire : le service d'aléatoire, tests d'abord. Une graine rejoue tout à l'identique.
- [ ] **0.8 Intégration continue**, si 0.2 la retient. L'utilisateur saisit lui-même les secrets.
- [ ] **0.9 Skills et agents** propres au projet, d'après les besoins vus pendant la phase.

## Phase 1 : prototype

{{CE QUE LE PROTOTYPE DOIT PROUVER, ET SA DURÉE ESTIMÉE}}. Le produit se lance et s'utilise à la fin de chaque étape.

- [ ] **1.1 {{FONCTIONNALITÉ}}.** {{CE QUE LA SESSION CONSTRUIT}}
- [ ] **Performance.** Les scénarios de pire cas d'`architecture.md`, puis la version livrée profilée sur l'appareil minimal.
- [ ] **Test utilisateurs** avec quelques personnes, jugé sur le critère de {{DOCUMENT DE CONCEPTION}}.

## Phase 2 : identité visuelle et page de présentation

En parallèle du prototype.

- [ ] **2.1 Identité visuelle.** Ambiance, palette, typographies, logo. Le résultat va dans {{DOCUMENT DE CONCEPTION}}.
- [ ] **2.2 Chaîne des contenus.** De l'outil de création au projet : nommage, format, export, et l'avertissement de licence (« ⚠⚠ » pour un contenu généré par IA). Essayée sur un premier contenu.
- [ ] **2.3 Nom définitif**, vérifié : libre, et sans marque d'autrui.
- [ ] **2.4 Comptes de publication.** L'utilisateur crée les comptes et paie lui-même les frais.
- [ ] **2.5 Page de présentation** en ligne, pour récolter des personnes intéressées.

## Phase 3 : tranche verticale

{{LE PARCOURS COMPLET, ET SA DURÉE ESTIMÉE}}, à la qualité finale. Les blocs, dans l'ordre prévu :

- [ ] **3.1 {{BLOC}}.**
- [ ] **Test utilisateurs**, jugé sur le critère de {{DOCUMENT DE CONCEPTION}}.

## Phase 4 : bêta ou démo

- [ ] **4.1 Réglages et accessibilité**, et les traductions prévues.
- [ ] **4.2 Version de bêta** : son périmètre, les rapports de crash, une passe de QA, la version livrée profilée sur l'appareil minimal.
- [ ] **4.3 Diffusion** par {{CANAL DE BÊTA OU DE DÉMO}}. L'utilisateur fait lui-même les inscriptions.
- [ ] **4.4 Retours** triés en issues GitHub.

## Phase 5 : itérations

- [ ] **5.1 Accès anticipé ou sortie directe**, décidé d'après les retours de la bêta.
- [ ] **5.2 {{BLOC DE CONTENU OU DE FONCTIONNALITÉ}}.**

## Phase 6 : lancement

- [ ] **6.1 Version candidate** : QA complète, version livrée profilée sur l'appareil minimal, traductions.
- [ ] **6.2 Sortie** : prix, date, page de présentation à jour, annonce.

## Phase 7 : suivi

Les correctifs, depuis les issues GitHub, et les mises à jour prévues dans {{DOCUMENT DE CONCEPTION}}.
