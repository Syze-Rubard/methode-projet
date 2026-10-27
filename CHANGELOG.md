# Journal de la méthode

Chaque amélioration de la méthode, avec son pourquoi. La plus récente en haut.

## 2026-10-27 : ce que de vraies sessions ont trouvé

Trois passages des scénarios avec de vraies sessions de Claude (Sonnet ; 0,73 $, 1,13 $, puis 0,49 $ pour trois scénarios) ont trouvé ce que les tests sans Claude ne voyaient pas :
- **`preparer-pc.ps1` écrivait les hooks de Git LFS dans le dépôt d'où on le lançait** : sans `--skip-repo`, `git lfs install` pose ses quatre hooks dans le dépôt courant, dans `.githooks` pour un projet de la méthode. Il prend maintenant `--skip-repo`, et un test le lance depuis un dépôt pour le prouver ;
- **la compaction choisie par l'utilisateur est respectée** : `preparer-pc.ps1` réclamait 300k, à chaque lancement, à qui avait choisi 500k. Il dit maintenant ce que la méthode conseille, sans en faire un `[à faire]` ;
- **les scripts se lancent avec le PowerShell de Windows** : une session a d'abord essayé `pwsh`, qui n'est pas toujours installé. `SKILL.md` dit où sont les trois scripts et comment les lancer ;
- **un script PowerShell avec des accents s'enregistre en UTF-8 avec BOM**, même jetable : une session en a écrit un sans BOM pour remplir `docs/architecture.md`, ses remplacements avec accents n'ont rien trouvé, il a écrit « Ã  » pour « à », et elle a dû recréer le fichier. L'installation le note dans ses pièges ;
- **reprendre sur un autre PC** : une session a sauté `preparer-pc.ps1` sans le dire, et n'a pas dit qu'il fallait une nouvelle session. `SKILL.md` dit maintenant pourquoi il faut l'un et l'autre, même quand le skill répond déjà ; au passage suivant, la session a fait les deux ;
- **une consigne d'un jour ne réécrit pas les règles du projet** : à qui disait « ne pousse rien », une session a retiré « pousser » de la fin de tâche de CLAUDE.md. Le scénario « démarrer » le vérifie maintenant ;
- **ce qui est commité est poussé, ou la session demande s'il faut pousser** : une session a commité sans pousser en écrivant « Pas de remote configuré », sans avoir regardé. Les scénarios « contrôler » et « petite tâche » ont maintenant un dépôt distant, local au PC, et vérifient que le commit y arrive, ou que la réponse pose la question sans prétendre qu'il n'y a pas de dépôt distant ;
- **des projets d'essai plus vrais** : une fiche projet remplie, les outils du PC dans la carte, un `verifier.ps1` qui vérifie le code. Les sessions relevaient à raison les incohérences des premiers (une étape cochée sans `verifier.ps1`, une fiche projet vide) et y passaient des tours ;
- **les gardes des scénarios sont prouvées avant chaque passage** : `gh` ne lance que des commandes qui lisent, Claude Code lui-même lisant `gh pr view` après un commit ; un `git push` vers GitHub part vers une adresse qui n'existe pas. Le script vérifie les deux gardes avant la première session, et s'arrête si l'une ne tient pas ;
- « une nouvelle session active les hooks et la mémoire » se cherche maintenant phrase par phrase : « je peux la remplir lors de la prochaine session » passait l'ancienne vérification.

## 2026-10-27 : un contrôle, un chemin léger, et des preuves que la méthode marche

À la question « le skill est-il utile, sur 10 ? », la réponse a été 8 : il lui manquait des preuves qu'il marche, pas seulement des consignes, et un chemin pour les petits projets. Ce qu'on a ajouté :
- **`controler-projet.ps1`** vérifie, en lecture seule, qu'un projet suit toujours la méthode : le budget de ce que chaque session charge, la mémoire, les hooks, `verifier.ps1` dès qu'il y a du code, la carte, « Où on en est », la racine, les règles de `.claude/rules/`. Une ligne `[à corriger]` bloque, `[à surveiller]` conseille. Sur un projet en cours, il a trouvé `MEMORY.md` importé dans CLAUDE.md, donc chargé deux fois à chaque session ;
- **le hook `garde-methode`** le lance avant chaque commit d'un projet, entre `garde-secrets` et `garde-tests` : un projet ne dérive plus sans qu'on le voie ;
- **le chemin léger** : `preparer-projet.ps1 -Leger` prend les modèles de `modeles/leger/`, une feuille de route en trois phases (fondations, construction, livraison) au lieu de huit, pour un outil, une bibliothèque ou un essai de quelques semaines ;
- **`tests/tester-les-scripts.ps1`** teste le skill lui-même, sans Claude et sans token : ses scripts, ses modèles, le contrôle et les hooks, sur des projets jetables. Le pre-commit du skill, que `preparer-pc.ps1` active, le lance avant chaque commit de la méthode ;
- **`tests/jouer-les-scenarios.ps1`** lance de vraies sessions de Claude dans des dossiers jetables (démarrer un projet, le reprendre sur un autre PC, le contrôler, une petite tâche), et vérifie ce qu'elles ont fait : le skill lu, les commandes lancées, les fichiers laissés, le nombre de tours. Chaque session est plafonnée en dollars, `gh` y est bridé (aucune ne crée de dépôt ni ne pousse), et il faut Claude Code connecté une fois dans un terminal. `-ASec` joue chaque scénario sans Claude : ses vérifications doivent échouer sur un dossier intact et passer sur une session idéale, sinon elles ne prouvent rien. Le pre-commit du skill le joue aussi ;
- dès son premier passage à sec, le scénario « démarrer » a trouvé un vrai défaut : sur un projet sans commit, le contrôle s'arrêtait au premier message de git sur stderr dès que « Où on en est » était daté, et `garde-methode` aurait refusé le premier commit de chaque projet neuf. Les tests ne l'avaient pas vu, car leur projet d'essai n'avait pas encore rempli « Où on en est ». Le contrôle est corrigé, et ce test date maintenant « Où on en est » avant le premier commit, comme au vrai démarrage.

## 2026-10-27 : une seule fiche projet, même sans `-Nom`

`preparer-projet.ps1` nommait la fiche projet de la mémoire d'après `-Nom`, ou d'après le nom du dossier quand `-Nom` manquait. Relancé sans `-Nom`, comme le prescrit la reprise sur un autre PC, il créait donc une seconde fiche dès que le dossier ne porte pas le nom du projet : sur un essai créé avec `-Nom Essai` dans un dossier `essai-projet`, `project-essai-projet.md` est apparu à côté de `project-essai.md`. Désormais :
- sans `-Nom`, le script reprend le nom du projet dans le titre de `CLAUDE.md` (« # <NOM> : instructions pour Claude »), sinon dans le nom de sa fiche projet, sinon dans le nom du dossier. La commande `gh repo create` qu'il propose porte donc aussi le bon nom ;
- il ne crée jamais la fiche projet quand `docs/memoire` contient déjà un `project-*.md`, même sous un autre nom ou avec un autre `-Nom` ;
- un projet qui a déjà deux fiches les fusionne à la main : le script n'en supprime aucune.

## 2026-10-27 : un skill court, le détail à la demande

L'utilisateur veut que la méthode serve d'abord à avoir le meilleur projet possible, avec le moins de tokens possible, sans trop en faire. Un skill appelé reste dans le contexte jusqu'à la fin de la session, et seul son début survit à une compaction : à 416 lignes (40 Ko), il coûtait cher et son essentiel risquait d'être coupé. Ce qu'on a changé, d'après la documentation de Claude Code et les leçons d'un service web mené des mois par de nombreux agents :
- **`SKILL.md` garde l'essentiel**, en 127 lignes (14 Ko au lieu de 40) : les six idées, le cycle, la vérification, les tokens, les documents, la mémoire, le contexte, un contrôle de conformité, l'amélioration de la méthode. Le détail passe dans `reference/` (installation, qualité, sécurité et droits, génération par IA, types de projet), un niveau de profondeur, chaque fichier ouvert par une ligne qui dit quand le lire. Un script a vérifié qu'aucune ligne de l'ancienne version ne s'est perdue sans le vouloir ;
- **`reference/grand-projet.md`**, neuf : ce qui se charge à chaque session et son budget, le rangement, les décisions, les invariants, les pièges par domaine et les règles `.claude/rules/` à `paths:` qui les font lire au bon moment, l'état courant réécrit plutôt qu'allongé, les sessions en parallèle, l'effort des agents, la production. À lire quand le projet grandit, pas avant ;
- **`MEMORY.md` n'est plus importé dans CLAUDE.md** : la mémoire automatique le charge déjà à chaque session, il l'était donc deux fois. La documentation de Claude Code le confirme ;
- **trois types d'agents dans les modèles** (`.claude/agents/leger.md`, `moyen.md`, `haut.md`), chacun avec son champ `effort` : c'est la seule façon de régler l'effort d'un sous-agent, et l'utilisateur veut que l'effort suive la difficulté de chaque tâche ;
- **les licences deviennent des avertissements** : l'utilisateur ne veut pas que Claude tienne un registre ni bloque un contenu. Claude prévient d'une ligne (« ⚠ ») pour un contenu externe, une licence inconnue ou copyleft, des crédits, une marque d'autrui ; pour un contenu généré par IA destiné au produit, un avertissement renforcé (« ⚠⚠ ») rappelle la déclaration aux boutiques comme Steam, les droits de la formule, la protection et la trace à garder. `docs/licences.md` n'est plus créé d'office, seulement si l'utilisateur veut garder la trace ;
- des budgets écrits : CLAUDE.md et la carte sous 200 lignes, la carte sous 80, `MEMORY.md` une cinquantaine de lignes ; pas d'histoire dans une carte, un index ou un sommaire ; « Où on en est » réécrit à chaque session ;
- le modèle de CLAUDE.md gagne le geste des trente secondes, la mesure qui porte sa machine, son paramètre et sa date, et l'identifiant des travaux en fond dans la consigne de compaction ; la fiche d'un modèle d'IA note les droits de sa formule.

## 2026-10-27 : économiser les tokens

Sur RogueHack, Claude a lancé un workflow de cinq agents pour relire un paquet tiers avant de l'installer, alors que quelques recherches ciblées suffisaient. L'utilisateur l'a arrêté et a demandé que la méthode serve aussi à économiser les tokens :
- une sixième idée, et une section « Économiser les tokens » : un projet rangé qui se lit comme un livre ouvert, lire juste ce qu'il faut, l'effort qui suit la difficulté de la tâche, des réponses courtes ;
- pas d'agents ni de workflows pour une tâche simple, même en mode ultracode ;
- le modèle de CLAUDE.md le rappelle à chaque session.

## 2026-10-27 : leçons d'un service web mené des mois avec des agents

L'utilisateur a demandé de reporter dans la méthode ce qu'un autre de ses projets, un service web en ligne depuis des mois et construit par de nombreux agents, a appris à ses dépens :
- **le geste des trente secondes** : remettre le défaut et voir le test échouer. Sur ce projet, des dizaines de tests étaient verts sur la version fautive, et quelques-uns faisaient passer le défaut pour voulu ;
- un test vise le comportement, pas une ligne recopiée : une dizaine de fois, un test a échoué sur du code juste, seulement parce qu'il avait été réécrit ;
- un test d'absence prouve qu'il a lu quelque chose ;
- une mesure porte sa machine, son paramètre et sa date : deux fois le même jour, une mesure juste a mené à une conclusion fausse, une fois parce qu'il y avait deux bases « de production », une fois à cause d'un filtre mal réglé ;
- comparer deux versions en alternant, et se méfier de ce qu'un système annonce savoir faire ;
- une ligne de mémoire qui décrit un état porte sa date : plusieurs fois, une ligne périmée a survécu et a découragé de vérifier ;
- `docs/decisions/` et `docs/pieges/`, quand le projet grandit : un choix qui n'existe que dans un commentaire a été défait par l'agent suivant.

## 2026-10-27 : disque venu d'un autre PC

Sur le second PC, le disque de RogueHack appartenait encore au compte du premier PC. Git refusait donc ses dépôts (« dubious ownership »), et `preparer-projet.ps1` s'arrêtait dessus :
- `preparer-projet.ps1` ajoute le dépôt du projet à `safe.directory` quand git le refuse pour cette raison, et seulement dans ce cas ;
- `preparer-pc.ps1` fait de même pour le dépôt du skill ;
- pour se connecter à GitHub, `preparer-pc.ps1` donne le chemin complet de `gh`. Un terminal ouvert avant l'installation ne trouvait pas la commande `gh` ;
- une fois connecté, `preparer-pc.ps1` fait passer git par GitHub CLI (`gh auth setup-git`) et affiche le compte. Sur le second PC, git poussait avec un ancien compte resté enregistré, et le navigateur avait connecté `gh` à ce même ancien compte ;
- une modification du skill est commitée et poussée tout de suite, sans attendre la fin de la tâche du projet, pour qu'il reste à jour sur chaque PC. L'utilisateur l'a demandé.

## 2026-10-25 : génération par IA

Un modèle d'IA générative donne de bien meilleurs résultats quand on lui parle comme son éditeur le conseille, et chaque modèle a sa façon. L'utilisateur veut que Claude se renseigne toujours avant de générer :
- le hook `garde-generation-ia.ps1` (PreToolUse) refuse une génération d'image, de vidéo, de modèle 3D ou de son tant que le modèle appelé n'a pas de fiche datée de moins de 60 jours dans `docs/generation-ia/modeles/`. Son message dit comment se renseigner et quoi écrire. Une estimation de coût et la reprise d'un travail passent ;
- le modèle de fiche `_modele.md` : sources, forme de prompt, images de référence, paramètres, astuces de la communauté, forces et faiblesses, prompt qui a marché ;
- on se renseigne dans les guides officiels, puis dans ceux de la communauté (Reddit, Discord, tutoriels) : l'utilisateur sait qu'on y trouve souvent les meilleures astuces. Chacune est notée avec sa source et son résultat une fois essayée ;
- la bible de style `docs/generation-ia/style.md`, pour que les contenus d'un même produit se ressemblent ;
- une section « Génération par IA » dans le skill : les réflexes, la façon d'obtenir des contenus cohérents, les outils, les droits ;
- le modèle de CLAUDE.md et la carte en parlent.

## 2026-10-25 : dépôt public

Pour qu'une personne récupère la méthode sans compte GitHub ni invitation :
- le dépôt du skill devient public, et le `README.md` donne la commande `git clone` ;
- son historique porte l'adresse anonyme de GitHub au lieu d'une vraie adresse e-mail, et ses prochains commits aussi ;
- les dépôts des projets restent privés.

## 2026-10-25 : feuille de route

Les phases disaient où va le projet, mais pas quelle session vient ensuite. RogueHack a gagné une feuille de route étape par étape, reprise ici pour tout projet :
- le modèle `docs/feuille-de-route.md` : une case par session, regroupées par phase de 0 à 7, et une section « Où on en est » ;
- les phases lointaines restent en grands blocs, découpées en sessions juste avant de les commencer, avec les leçons de la phase précédente ;
- ce qu'on fait à chaque jalon tient au même endroit : tag, version livrée profilée, export des documents hors du dossier, copie du dossier, découpage de la phase suivante ;
- en début de session, la prochaine étape est la première case non cochée. En fin de tâche, on coche sa case et on met à jour « Où on en est » ;
- la carte, le modèle de CLAUDE.md et le démarrage d'un projet en parlent. La fiche projet de la mémoire renvoie à la feuille de route, pour ne pas tenir la suite à deux endroits.

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
