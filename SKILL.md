---
name: methode-projet
description: Méthode de travail pro avec Claude Code, commune à tous les projets de code de l'utilisateur, quel que soit leur type (jeu PC, console ou mobile, appli mobile, logiciel de bureau, site ou service web, outil en ligne de commande, bibliothèque). Structure de doc (CLAUDE.md, carte du projet, architecture, feuille de route, mémoire versionnée dans le projet), une fonctionnalité par session, checklist de fin de tâche, gestion du contexte (/clear, compaction), hooks et git. À utiliser pour démarrer un nouveau projet, remettre de l'ordre dans un projet existant, vérifier qu'un projet suit la méthode, ou améliorer la méthode elle-même.
---

# Méthode projet

Une méthode pour mener un gros projet de code avec Claude Code sans perdre en qualité ni en mémoire, que ce soit un jeu, une appli mobile, un logiciel, un site web ou un outil. Les règles valent pour tous ; ce qui change d'un type à l'autre est dans « Selon le type de projet ». Elle tient en six idées :
1. **Tout ce qui compte est écrit sur le disque.** Une session neuve ne perd rien, donc on repart de zéro à chaque fonctionnalité.
2. **Un sujet par document, sans doublon.** Chaque info a une seule place, et une carte dit laquelle.
3. **Petit bout par petit bout.** Une fonctionnalité par session, testée et commitée avant la suivante.
4. **Automatiser plutôt que se fier aux consignes.** Ce qui doit arriver à coup sûr passe par un hook ou un réglage.
5. **Juste ce qu'il faut, au bon moment.** Chaque outil se met en place quand le premier code en a besoin, pas avant : le vérificateur avec le premier code, les tests de performance avec le premier écran utilisable, les tests réseau avec le premier échange réseau. Une règle qui coûte plus qu'elle ne rapporte est signalée à l'utilisateur.
6. **Économiser les tokens.** Le projet est rangé pour que Claude y lise comme dans un livre ouvert, l'effort suit la difficulté de la tâche, et les réponses vont droit au but. Voir « Économiser les tokens ».

## Les scripts

Deux scripts du dossier de ce skill font l'installation. Les lancer avec `powershell -NoProfile -ExecutionPolicy Bypass -File "<dossier du skill>\<script>.ps1"`. Ils ne détruisent rien et se relancent sans risque. Les scripts et les hooks tournent sous Windows (PowerShell 5.1) : sur Mac ou Linux, il faut d'abord les porter. Chaque ligne de leur sortie commence par un état : `[ok]`, `[créé]`, `[installé]`, `[réglé]`, `[à faire]` ou `[à remplir]`.

- **`preparer-pc.ps1`**, une fois par PC :
  - il installe avec winget ce qui manque (git, Git LFS, GitHub CLI) et active Git LFS ;
  - il relie le skill à Claude Code et vérifie la compaction automatique ;
  - si le skill est sur un disque venu d'un autre PC, il le fait accepter par git (`safe.directory`).

  Avant de le lancer, prévenir l'utilisateur que Windows peut lui demander d'autoriser une installation. Puis l'aider sur chaque `[à faire]` :
  - **identité git** : lui demander un nom et un e-mail, puis relancer avec `-NomGit` et `-EmailGit`. Si un dépôt peut devenir public, proposer l'adresse « noreply » de GitHub ;
  - **connexion à GitHub** : `gh auth login`, lancé par l'utilisateur, jamais par Claude. Le script donne le chemin complet de `gh`, qui marche aussi dans un terminal ouvert avant l'installation. Une fois connecté, il fait passer git par ce compte et l'affiche : vérifier avec l'utilisateur que c'est bien celui qui possède ses dépôts. Sinon, il se reconnecte au bon compte dans le navigateur, relance `gh auth login`, puis `gh auth switch` ;
  - **compaction** : `/autocompact 300k`, que l'utilisateur tape lui-même.

  Relancer le script jusqu'à ce qu'il ne reste rien à faire.
- **`preparer-projet.ps1 -Chemin <dossier> [-Nom <nom>] [-Techno <techno>]`**, pour chaque projet et sur chaque PC. Les technos disponibles sont les dossiers de `modeles/techno/` ; `base` convient à toutes en attendant la leur :
  - il copie les modèles sans écraser un fichier existant ;
  - il dirige la mémoire de Claude Code vers `docs/memoire`, et corrige le chemin si le disque a changé de lettre ;
  - il initialise git, avec LFS si la techno en a besoin ;
  - si le dépôt est sur un disque venu d'un autre PC, il le fait accepter par git (`safe.directory`) : sinon git le refuse, car ses dossiers appartiennent au compte de l'autre PC ;
  - il liste les `{{...}}` qui restent à remplir.

Les modèles :
- `modeles/projet/` contient les fichiers communs à tous les projets ;
- `modeles/techno/<techno>/` contient le `.gitignore` et le `.gitattributes` de chaque techno ;
- le script remplit `{{NOM}}` et `{{nom}}`, et Claude remplit les autres `{{...}}`.

## Démarrer un projet

1. Demander à l'utilisateur le nom du projet, son pitch en une phrase, son type (voir « Selon le type de projet »), la techno, et le document de conception (GDD, cahier des charges…) s'il existe.
2. Lancer `preparer-pc.ps1`. Si tout est `[ok]`, passer à la suite.
3. Si la techno n'a pas encore de modèle dans `modeles/techno/`, le créer d'abord (voir « Améliorer la méthode »). Puis lancer `preparer-projet.ps1` sur le dossier du projet, avec `-Techno`.
4. Remplir chaque `{{...}}` listé, retirer ce qui ne sert pas, et compléter la fiche projet de la mémoire et la section « Outils du PC » de la carte (moteur, SDK, logiciels, MCP). Les sections « Tests et qualité », « Performance » et « Sécurité » de `architecture.md` se remplissent d'après le type du projet. La feuille de route découpe en sessions les phases 0 à 2, d'après le document de conception, et laisse les suivantes en grands blocs.
5. Cocher l'étape 0.1 de la feuille de route, faire un premier commit, puis sauvegarder hors du disque : `gh repo create <nom> --private --source . --push`.
6. Dire à l'utilisateur que les hooks et la mémoire prennent effet à la session suivante.

## Reprendre un projet sur un autre PC

1. Lancer `preparer-pc.ps1`.
2. Récupérer le projet : brancher le disque, ou `gh repo clone <nom>`.
3. Lancer `preparer-projet.ps1 -Chemin <dossier du projet>`. Il ne crée que ce qui manque, dont `.claude/settings.local.json`, que git ne suit pas.
4. Installer avec l'utilisateur les outils de la section « Outils du PC » de la carte du projet.
5. Ouvrir une nouvelle session, pour activer les hooks et la mémoire.

## Partager la méthode

- La méthode tient dans le dossier de ce skill, dans un dépôt GitHub public : on la partage par son lien, https://github.com/Syze-Rubard/methode-projet, ou en copie du dossier. Les dépôts des projets, eux, restent privés.
- Ce dépôt étant public, ses commits portent l'adresse anonyme de GitHub (`…@users.noreply.github.com`), jamais une vraie adresse e-mail.
- La personne installe Claude Code, puis suit le `README.md` du dossier : il lui fait lancer `preparer-pc.ps1`.
- Elle a sa propre identité git et son propre compte GitHub. Ses projets ont leur propre mémoire.

## Le cycle d'une fonctionnalité

1. **Session neuve** (`/clear` ou nouvelle session) : CLAUDE.md charge la carte et l'index de la mémoire. La prochaine étape est la première case non cochée de `docs/feuille-de-route.md`.
2. **Mode plan** : lire les fiches et docs utiles, puis proposer un plan court. Le plan dit comment la fonctionnalité sera testée (tests automatiques et essai à la main) et ce qu'elle coûte en performance. Attendre l'accord.
3. **Tests d'abord** : écrire les tests du comportement voulu et les voir échouer. Puis construire en petites fonctions génériques jusqu'à ce qu'ils passent.
4. **Vérifier** :
   - `outils/verifier.ps1` au vert ;
   - la fonctionnalité essayée en vrai ;
   - le diff relu avec `/code-review`, et ses trouvailles corrigées.
5. **Checklist de fin de tâche** :
   - mettre à jour chaque document concerné, d'après le tableau « Qui tient quoi à jour » de la carte ;
   - cocher la case de la feuille de route, et mettre à jour « Où on en est » ;
   - ajouter à la mémoire toute info durable (décision, préférence, état du projet) ;
   - commiter, puis pousser.
6. **`/clear`** : le hook `rappel-clear` prévient l'utilisateur après un commit, ou quand le contexte dépasse 150k tokens.

Aucune phase de production ne démarre sans le feu vert explicite de l'utilisateur.

## Qualité : zéro bug

Le but est un projet sans bug. Chaque moyen ci-dessous attrape des bugs que les autres laissent passer, donc on les cumule.

**À chaque changement :**
- **Tests d'abord** pour chaque brique de logique. Un test décrit un comportement, pas le code.
- **Un bug corrigé commence par un test** qui le reproduit et échoue. La correction le fait passer, et le bug ne revient plus.
- **Le geste des trente secondes** : après une correction, remettre le défaut un instant, vérifier que le test échoue, puis restaurer. Un test qui reste vert sur la version fautive ne protège de rien, et peut même faire passer le défaut pour voulu.
- **Un test vise le comportement, jamais une ligne de code recopiée mot pour mot** : il échouerait le jour où on réécrit la ligne sans en changer le sens.
- **Un test qui vérifie une absence** (« aucun fichier ne contient X ») vérifie aussi qu'il a bien lu des fichiers : sinon il est vert sur le vide.
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

**Pour tout produit livré :**
- tout l'aléatoire passe par une graine, notée dans chaque rapport de bug et dans chaque log : tout bug se rejoue à l'identique ;
- un test de fumée lance le produit et parcourt chaque écran sans erreur ;
- la version livrée écrit un log et un rapport de crash, avec sa version.

Les tests propres à chaque type de projet sont dans « Selon le type de projet ».

## Logs : retrouver un bug vite

Quand un bug arrive, les logs doivent dire ce qui s'est passé, où et pourquoi, sans avoir à le reproduire. Plus il y en a, mieux c'est. Les niveaux et les catégories permettent de n'afficher que ce qu'on cherche.

**Un seul module de log**, créé avec le premier code. Jamais d'appel direct à `print` ou à `Debug.Log`. Le format, les filtres et les destinations se changent alors à un seul endroit.

**Chaque ligne contient :**
- l'heure à la milliseconde ;
- le niveau (`Trace`, `Debug`, `Info`, `Warning`, `Error`, `Fatal`) ;
- la catégorie, c'est-à-dire le module ;
- le message ;
- le contexte en `clé=valeur` : version, session, et ce qui situe l'événement. Pour un jeu, c'est la graine, l'image et le joueur ; pour un service web, la requête et l'utilisateur.

Les fichiers sont en JSON, une ligne par entrée, pour que Claude les filtre en une commande. La console garde une version lisible.

**Ce qu'on loggue :**
- **les changements d'état**, chacun avec l'état d'avant et l'état d'après ;
- **les décisions**, avec leur pourquoi : « remise refusée car… », « ennemi passé en fuite car… » ;
- **les entrées et sorties des modules**, et chaque appel externe : réseau, fichiers, sauvegarde ;
- **les erreurs**, chacune avec tout son contexte et la pile d'appels ;
- **la durée des opérations lentes.**

**On suit un événement d'un bout à l'autre** grâce à un identifiant commun :
- la session ;
- la partie, la requête ou la transaction ;
- le message réseau. Les logs de plusieurs machines se fusionnent alors en une seule chronologie.

**Les fichiers :**
- un fichier par session, à un emplacement noté dans `docs/architecture.md` ;
- on garde les N dernières sessions ;
- les dernières lignes sont aussi gardées en mémoire, et écrites dans chaque rapport de crash ou de bug.

**Pour les performances :**
- le message n'est construit que si son niveau est actif ;
- ce qui se répète à chaque image ou à chaque requête passe au niveau `Trace`, activable par catégorie.

**Jamais de secret ni de donnée personnelle** dans un log : mot de passe, jeton, e-mail.

**Pour un bug :**
1. lire d'abord les logs ;
2. si les logs ne suffisaient pas à comprendre, ajouter les logs qui ont manqué, en plus du test qui reproduit le bug ;
3. joindre les logs à l'issue.

## Performance : jamais de ralentissement

Rien de ce qu'on ajoute ne doit faire ramer le programme. Un ralentissement est un bug comme un autre : il a son issue, son test et sa correction.

**Des budgets chiffrés**, notés dans `docs/architecture.md` et décidés avec l'utilisateur. Ce qu'on mesure dépend du type de projet (voir « Selon le type de projet ») : la réactivité (temps par image, temps de réponse), le démarrage ou le chargement, la mémoire, et les allocations dans le code chaud. Chaque budget a deux valeurs :
- sur l'appareil minimal visé, en médiane et sur le 1 % des pires cas (les saccades comptent) ;
- sur le PC de développement, plus serrée : c'est elle que les tests de chaque commit vérifient.

**Mesurer, pas deviner :**
- on profile avant d'optimiser, et on optimise là où la mesure le montre ;
- les vrais chiffres se prennent sur la version livrée (build de production), sur l'appareil minimal : l'éditeur, le mode debug et un PC puissant les faussent ;
- une mesure s'écrit avec la machine, le paramètre qui l'a produite et sa date : « 461 éléments, filtre année ≥ 2026, base de test, 27/10 » se relit et se conteste, « 461 éléments » non. Une mesure juste, prise sur la mauvaise machine ou avec le mauvais réglage, mène à une conclusion fausse sans que rien ne cloche dans le relevé ;
- deux versions se comparent en alternant, dans la même fenêtre de temps, et un écart plus petit que la dispersion d'une même version ne compte pas ;
- ce qu'un système annonce savoir faire n'est pas une mesure : on essaie en vrai.

**Tests de performance automatiques**, dans `outils/verifier.ps1`, après les autres tests :
- des scénarios de pire cas, joués quelques secondes chacun ;
- chacun échoue s'il dépasse le budget du PC de développement, ou s'il alloue de la mémoire là où il ne doit pas ;
- chacun échoue aussi s'il régresse de plus de 10 % par rapport à la référence de ce PC (`outils/perf-reference.json`, ignorée par git) ;
- une amélioration voulue met la référence à jour, avec l'accord de l'utilisateur.

**À chaque fonctionnalité :**
- le plan dit ce qu'elle coûte en performance ;
- le diff relu cherche aussi les coûts cachés : allocations, recherches répétées, boucles sur tout le monde.

**À chaque jalon**, la version livrée passée au profiler sur l'appareil minimal, avec les chiffres notés dans `architecture.md`.

**Du code générique et rapide à la fois :** les petites fonctions génériques restent la règle. Dans le code chaud, c'est-à-dire ce qui tourne à chaque image, à chaque requête ou pour chaque élément d'une longue liste :
- aucune allocation ;
- des références gardées en cache ;
- des pools d'objets au lieu de créer et détruire ;
- des événements plutôt que des vérifications répétées ;
- des structures de données adaptées au volume ;
- rien de lent sur le fil de l'interface : disque, réseau et gros calculs passent en tâche de fond.

**En développement**, un affichage permanent ou un tableau de bord montre les mesures clés : images par seconde et allocations pour un jeu, temps de réponse pour un service.

## Sécurité

Rien de secret ne sort du PC, et rien de ce qui entre n'est cru sur parole.

**Les secrets** (mots de passe, clés d'API, jetons, certificats, clés de signature) :
- jamais dans le dépôt, même privé : ils vivent dans un fichier ignoré par git, ou dans le coffre du service (les secrets de GitHub Actions) ;
- jamais dans ce qui est livré (jeu, appli, page web) : un utilisateur peut lire tout ce qu'il contient ;
- le hook git `pre-commit` bloque un commit qui contient un fichier de clé ou un secret reconnaissable ;
- un secret qui a fuité est révoqué et remplacé tout de suite : l'effacer de l'historique ne suffit pas ;
- Claude ne saisit jamais un secret : l'utilisateur le fait lui-même.

**Les dépendances** (packages, plugins, assets, serveurs MCP) :
- seulement de sources connues, avec une version fixée ;
- mises à jour volontairement, une à la fois, suivies de la vérification complète ;
- jamais de script ni d'exécutable téléchargé lancé sans l'avoir lu.

**Les données qui entrent** sont validées à la frontière, comme si elles étaient hostiles :
- un fichier chargé (sauvegarde, configuration, mod) abîmé ou modifié ne fait jamais planter : il est signalé dans les logs et écarté ;
- jamais de désérialisation capable de créer n'importe quel type, comme `BinaryFormatter` en C# ;
- en réseau, l'hôte ou le serveur fait autorité et vérifie chaque message d'un client : son type, ses bornes, sa fréquence.

**Les données personnelles** : aucune collectée sans besoin ni sans accord. Rapports de crash et statistiques sont annoncés et désactivables.

**Les comptes** : double authentification sur GitHub et sur chaque compte de publication, et dépôts privés par défaut.

## Sauvegarde du projet

- Le code, les docs, la mémoire et les assets suivis par Git LFS sont sur GitHub dès que le commit est poussé.
- Le quota Git LFS du compte GitHub est surveillé : les assets lourds le remplissent vite.
- Ce qui vit hors de git est listé dans la carte (« Hors du dossier »), avec l'endroit où c'est sauvegardé.
- À chaque jalon, une copie complète du dossier sur un autre support.

## Licences et droits

Un produit vendu ne doit contenir que des choses qu'on a le droit de publier :
- `docs/licences.md` liste chaque contenu externe (asset, police, son, musique, code) avec sa source, sa licence et l'attribution demandée. Sa ligne est ajoutée dans la même session que lui ;
- un contenu sans licence claire n'entre pas dans le projet ;
- les dépendances de code y sont notées aussi : une licence copyleft (GPL) peut obliger à publier son propre code ;
- les contenus générés par IA aussi : des boutiques, comme Steam, demandent de les déclarer ;
- les crédits du produit sont tirés de ce fichier ;
- aucune marque, aucun logo ni nom de produit d'autrui sans en avoir le droit.

## Génération par IA

Une image, une vidéo, un modèle 3D ou un son généré par IA est bien meilleur quand on parle au modèle comme son éditeur le conseille. Chaque modèle a sa façon : phrases ou mots-clés, prompt négatif compris ou ignoré, rôle des images de référence. Les modèles changent tous les quelques mois, et certains disparaissent.

**Avant de générer**
- Lire la fiche du modèle dans `docs/generation-ia/modeles/`. Si elle manque ou a plus de 60 jours, se renseigner (recherche web, puis lecture des pages), puis écrire la fiche d'après `_modele.md`, avec ses sources et la date. Le hook `garde-generation-ia` refuse la génération sinon.
  - D'abord les guides officiels de l'éditeur. Beaucoup de docs ont un `llms.txt`.
  - Puis les guides de la communauté : le subreddit du modèle, son Discord, les tutoriels de créateurs reconnus. Ils ont souvent les meilleures astuces, que la doc ne donne pas.
  - Chaque astuce de la communauté entre dans la fiche avec sa source, et son résultat une fois essayée sur le projet. En cas de désaccord, la doc officielle fait foi jusqu'à ce qu'un essai donne raison à la communauté.
- Tout contenu destiné au produit part de la bible de style `docs/generation-ia/style.md`. Elle est écrite avec l'utilisateur pendant la phase d'identité visuelle, avant la première génération pour le produit. Les essais d'exploration peuvent la précéder.
- Estimer le coût quand l'outil le permet, et le dire à l'utilisateur avant une série.

**Écrire le prompt**
- Décrire ce qu'on voit, le sujet d'abord, puis l'action, le lieu, la composition, la lumière et le style. Pas de mots creux comme « masterpiece » ou « 8k ».
- Formuler en positif : plusieurs modèles ignorent les prompts négatifs. « Fond uni gris » plutôt que « sans décor ».
- Le texte à afficher entre guillemets, avec sa police et sa position, puis relu sur l'image.
- Les couleurs en hexadécimal, rattachées à un objet.
- Court d'abord, un changement à la fois. Les brouillons en basse qualité, la version finale en haute.
- Pour retoucher : « ne change que X, garde tout le reste ».
- Aucun nom d'artiste, de marque ou de personnage protégé.
- Le prompt qui a marché, avec ses réglages et sa graine, va dans la fiche du modèle.

**Des contenus cohérents, dans l'ordre**
1. La bible de style : palette en hexadécimal, lumière, matières, cadrage, ce qu'on évite, et un bloc de style commun ajouté à chaque prompt. Le sujet varie, le style non.
2. Trois à cinq images ancres validées par l'utilisateur, passées en références à chaque génération, avec le rôle de chacune (style, personnage, décor). Le nombre de références admis dépend du modèle.
3. En gros volume, un style entraîné : un LoRA sur 20 à 40 images légendées, ou le style entraîné d'un service (Scenario, Recraft, Krea).
4. Une graine fixe aide à comparer deux prompts, mais ne remplace ni les références ni un style entraîné.
5. Pour un personnage : une planche (face, profil, dos, pose en A ou en T, fond neutre), puis le modèle 3D à partir de plusieurs vues.
6. Pour une texture : « seamless tileable », vue de dessus, lumière diffuse, et le raccord vérifié dans le moteur.
7. Pour des icônes ou une interface : du vectoriel (SVG) ou un fond transparent, avec la palette imposée.
8. Toujours finir à la main : détourage, agrandissement, retouche, puis un essai en situation, dans le produit.

**Outils, par besoin** (état au 25/10/2026 ; la fiche du modèle fait foi)

| Besoin | Point de départ | Guide officiel |
|---|---|---|
| Image et retouche par instructions | GPT Image, Nano Banana (Gemini), FLUX | [OpenAI](https://developers.openai.com/cookbook/examples/multimodal/image-gen-models-prompting-guide), [Google](https://ai.google.dev/gemini-api/docs/image-generation), [Black Forest Labs](https://docs.bfl.ai/guides/prompting_guide_flux2) |
| Texte dans l'image, logo | Ideogram | [Ideogram](https://docs.ideogram.ai/prompting/prompting.md) |
| Vectoriel, icônes, interface | Recraft | [Recraft](https://www.recraft.ai/docs/api-reference/models/recraft-v4) |
| Recherche de direction artistique | Midjourney (références de style, moodboards) | [Midjourney](https://updates.midjourney.com/) |
| Vidéo | Kling, Veo (Gemini), Seedance, Hailuo, Runway | [Kling](https://kling.ai/quickstart/klingai-video-3-model-user-guide), [Google](https://ai.google.dev/gemini-api/docs/video), [MiniMax](https://platform.minimax.io/docs/guides/video-generation), [Runway](https://docs.dev.runwayml.com/guides/models/) |
| Modèle 3D | Meshy, Tripo, Rodin ; Hunyuan3D en local, licence restreinte | [Meshy](https://docs.meshy.ai/en/webapp/text-to-3d), [Tripo par Scenario](https://help.scenario.com/articles/4692888910-tripo-family-the-complete-guide) |
| Voix, bruitages | ElevenLabs | [voix](https://elevenlabs.io/docs/overview/capabilities/text-to-speech/best-practices), [bruitages](https://elevenlabs.io/docs/overview/capabilities/sound-effects) |
| Musique | Suno, Lyria (Gemini) | [Suno](https://help.suno.com/en/articles/13924481), [Google](https://ai.google.dev/gemini-api/docs/interactions/music-generation) |
| Un style maison en volume | Scenario, Krea, ComfyUI en local | [Scenario](https://docs.scenario.com/), [Krea](https://www.krea.ai/docs/), [ComfyUI](https://docs.comfy.org/) |

**Droits**
- Vérifier, pour chaque modèle et chaque formule d'abonnement : usage commercial, crédit obligatoire, territoires, seuils de revenus. Au 25/10/2026, par exemple : les formules gratuites d'ElevenLabs et de Suno sont non commerciales, celle de Meshy oblige à créditer (CC BY 4.0), et la licence de Hunyuan3D 2.1 exclut l'Union européenne, le Royaume-Uni et la Corée du Sud.
- Chaque contenu généré qui entre dans le produit a sa ligne dans `docs/licences.md`, avec le modèle, la formule et la date dans la colonne « Généré par IA ».
- Steam demande de déclarer les contenus générés par IA dans son questionnaire de contenu, avant la soumission, et l'affiche sur la page du jeu. Un contenu généré pendant le jeu demande aussi de décrire ses garde-fous.
- Une création purement IA peut ne pas être protégée par le droit d'auteur, aux États-Unis au moins. Ce qui fait l'identité du produit garde une vraie part humaine.

## Documents

| Document | Rôle | Règle |
|---|---|---|
| `CLAUDE.md` | Règles chargées à chaque session | Moins de 200 lignes ; importe la carte et l'index de mémoire avec `@` |
| `docs/README.md` | La carte : arborescence, documents hors du dossier, « qui tient quoi à jour » | Mise à jour dès qu'un dossier ou un doc bouge |
| `docs/architecture.md` | Principes de code, structure, conventions, décisions techniques avec leur pourquoi | Mise à jour quand un module, une convention ou une décision change |
| `docs/feuille-de-route.md` | Les étapes jusqu'au lancement, une case par session, regroupées par phase, et « Où on en est » | Case cochée à la fin de sa session. Les phases lointaines restent en grands blocs, découpées en sessions juste avant de les commencer |
| `docs/memoire/` | Mémoire de Claude : index `MEMORY.md`, une fiche par sujet | Voir « Mémoire » |
| `docs/decisions/` | Quand les décisions débordent d'`architecture.md` : un fichier par choix, `AAAA-MM-JJ-sujet.md`, avec son pourquoi | Jamais supprimé ni renommé : une décision plus récente le remplace. Une décision qui n'existe que dans un commentaire sera défaite par le prochain agent |
| `docs/pieges/` | Quand le projet grandit : un fichier par domaine (base de données, interface, réseau…), ouvert par son sommaire. Chaque entrée est une leçon payée cher, avec sa date et son chiffre | Une entrée ajoutée dès qu'un piège coûte du temps. On lit le sommaire du domaine avant d'y toucher |
| `docs/licences.md` | Licence de chaque contenu externe ou généré par IA | Une ligne ajoutée dans la même session que le contenu |
| `docs/generation-ia/` | La bible de style (`style.md`) et une fiche par modèle d'IA générative (`modeles/`) | Voir « Génération par IA » |
| Document de conception | Le design, source de vérité | Document vivant : mis à jour à chaque fonctionnalité ou décision, compact, ce qui est abandonné est retiré |

Si le document de conception est un Claude Doc, chaque passe de modifs est marquée : surlignage dans le texte, cellules bleues `#e7f1fb` dans les tableaux. Les marques précédentes sont retirées quand l'utilisateur dit avoir relu.

## Mémoire

- La mémoire vit dans le projet (`docs/memoire/`) et se versionne avec lui : elle suit le disque, le dépôt et chaque PC.
- `.claude/settings.local.json` contient `"autoMemoryDirectory": "<chemin absolu>/docs/memoire"` : la mémoire automatique de Claude Code écrit directement là, sans copie. Claude Code ignore ce réglage dans `settings.json`, d'où le fichier local, que `preparer-projet.ps1` crée sur chaque PC et corrige si le disque change de lettre.
- Une fiche par sujet (frontmatter `name`, `description`, `metadata.type` : user, feedback, project ou reference), une ligne par fiche dans `MEMORY.md`. Mettre à jour plutôt que dupliquer, et ne pas recopier ce que CLAUDE.md ou le code disent déjà.
- Une ligne qui décrit un état (un compte, une taille, où on en est) porte la date de sa mesure : elle se périme, et sans date personne ne pense à la vérifier.
- Fiches en anglais, docs en français.

## Contexte : /clear et compaction

- **`/clear`** vide la conversation et repart de zéro dans la même fenêtre. CLAUDE.md, la carte et la mémoire sont rechargés, rien sur le disque n'est perdu, et l'ancienne conversation reste accessible avec `/resume`. À faire après chaque fonctionnalité commitée, ou quand on change de sujet.
- **`/compact`** résume la conversation au lieu de la vider. Utile au milieu d'une tâche longue, avec une consigne : `/compact garde le plan et les fichiers modifiés`.
- **`/autocompact 300k`** déclenche la compaction automatique à 300k tokens. Plus haut, chaque message coûte cher et la précision baisse ; plus bas, on résume trop souvent.
- La section « Compaction » de CLAUDE.md dit quoi garder quand la conversation est résumée.

## Économiser les tokens

Chaque token lu ou écrit coûte. La méthode sert aussi à en dépenser le moins possible, sans rien perdre en qualité.

- **Un projet rangé se lit vite.** La carte dit où est chaque chose, l'index de la mémoire dit quelle fiche ouvrir, et chaque document traite un seul sujet, en restant compact. Claude va droit à la bonne section, sans tout parcourir.
- **Lire juste ce qu'il faut** : la section utile d'un fichier plutôt que le fichier entier, une recherche ciblée plutôt qu'une lecture complète. Ne pas relire ce qu'on vient de lire ou d'écrire.
- **L'effort suit la difficulté de la tâche.** Une question, un réglage, une installation ou une petite vérification se font seul, en quelques commandes ciblées. Les agents en parallèle et les workflows, même en mode ultracode, sont gardés pour ce qui en a vraiment besoin : un gros audit, une migration, la revue d'une grosse fonctionnalité. Par exemple, relire un paquet tiers avant de l'installer se fait par des recherches ciblées (adresses contactées, fichiers écrits, code exécuté), pas avec cinq agents. En cas de doute, demander à l'utilisateur.
- **Des réponses courtes** : ce qui est fait, ce qui reste, la question à trancher. Pas de récit de chaque étape, ni de liste d'options qu'on ne retiendra pas.
- **`/clear` après chaque fonctionnalité** : une conversation longue fait payer tout son historique à chaque message.

## Code

- Petites fonctions génériques, une seule responsabilité, assemblées par composition.
- Valeurs pilotées par les données, jamais en dur.
- Modules découplés par interfaces et événements, frontières vérifiées par le compilateur quand la techno le permet.
- Logique séparée de l'affichage, pour pouvoir la tester.
- Avant d'écrire du code, chercher une brique existante à réutiliser ou à généraliser.
- Rapide dans le code chaud : voir « Performance ».
- Aucun texte visible en dur : tout passe par des tables de traduction dès le premier écran, même si le produit sort en une seule langue. Ajouter une langue après coup coûte très cher.
- Les données enregistrées de l'utilisateur (sauvegarde de jeu, base locale, préférences) portent un numéro de version, avec une migration depuis chaque version précédente : une mise à jour ne casse jamais ses données.
- « Fini » : `verifier.ps1` vert (tests de performance compris), essayé en vrai, diff relu, docs à jour, commit fait et poussé.

## Hooks

- Écrits en PowerShell 5.1, présent sur tout Windows, et enregistrés en UTF-8 avec BOM : sans BOM, les accents sont cassés.
- Déclarés en forme exec dans `.claude/settings.json` (`"command": "powershell.exe"` et `"args"`), avec un chemin relatif au projet : ça marche que Claude Code passe par Git Bash ou par PowerShell.
- Tester un hook en lui envoyant un JSON d'exemple sur l'entrée standard avant de le déclarer.
- `rappel-clear.ps1` (Stop) affiche un message à l'utilisateur après un nouveau commit, et quand le contexte franchit 150k, 250k, 350k tokens… Les seuils sont en tête du script.
- `garde-tests.ps1` (Stop et `pre-commit`) retient l'empreinte des fichiers qui ont passé `verifier.ps1`. Les docs et les `.md` n'en font pas partie. Il ne fait rien tant que le projet n'a pas de `verifier.ps1`. Il renvoie Claude au travail une seule fois par tour, pour ne pas boucler.
- `garde-secrets.ps1` (`pre-commit`, avant `garde-tests`) bloque un commit qui ajoute un fichier de clé (`.env`, `.pem`, `.pfx`, `.keystore`…) ou une ligne qui ressemble à un secret : clé privée, jeton connu, mot de passe écrit en clair. Il montre l'endroit, jamais le secret. Un faux positif reconnu porte le marqueur `garde-secrets: ignorer` sur sa ligne, avec l'accord de l'utilisateur.
- `garde-generation-ia.ps1` (PreToolUse, sur les outils MCP qui génèrent) refuse une génération d'image, de vidéo, de modèle 3D ou de son tant que le modèle appelé n'a pas de fiche à jour dans `docs/generation-ia/modeles/`. Une estimation de coût et la reprise d'un travail lancé passent. Voir « Génération par IA ».
- Les hooks git vivent dans `.githooks/`, versionnés, avec des fins de ligne LF (règle dans `.gitattributes`). `preparer-projet.ps1` les active, et Git LFS y écrit aussi les siens.

## Selon le type de projet

Les règles ci-dessus valent pour tous les projets de code. Voici ce qui change d'un type à l'autre. Au démarrage, Claude reporte les choix du projet dans les sections « Tests et qualité », « Performance » et « Sécurité » de `architecture.md`.

**Jeu (PC, console ou mobile)**
- Performance : temps par image, aucune allocation par image en jeu, chargements, mémoire. Sur mobile, aussi la chauffe, la batterie et la taille du téléchargement.
- Tests : tests de jeu automatiques, et un test de fumée qui charge chaque scène et joue quelques secondes.
- Sécurité : en réseau, l'hôte fait autorité ; les sauvegardes sont validées au chargement.
- Publication : Steam (page « Coming Soon » tôt, Next Fest, déclaration des contenus IA), App Store et Google Play, ou les programmes de développeur des consoles.

**Appli mobile**
- Performance : démarrage à froid, défilement fluide, mémoire, batterie, données consommées, taille de l'appli.
- Tests : tests d'interface sur émulateur et sur un vrai téléphone d'entrée de gamme, et un test de fumée qui ouvre chaque écran.
- Sécurité : jetons et secrets dans le coffre du système (Keychain, Keystore), jamais en clair. Le moins de permissions possible, demandées au moment où elles servent. HTTPS partout.
- Publication : App Store et Google Play, avec leur fiche de confidentialité. Bêta par TestFlight et par les tests fermés de Google Play. Construire pour iOS demande un Mac ou un service de build en ligne.

**Logiciel de bureau**
- Performance : démarrage, interface qui répond en moins de 100 ms, mémoire au repos et en charge.
- Tests : tests d'interface automatisés, et un test de fumée qui lance le programme et ouvre chaque fenêtre.
- Sécurité : installeur et exécutable signés, mises à jour par un canal signé, fichiers ouverts validés.
- Publication : un installeur, une boutique (Microsoft Store, Steam), ou un gestionnaire de paquets (winget).

**Site ou service web**
- Performance : chargement des pages (Core Web Vitals), temps de réponse au 95e centile, poids des pages, requêtes à la base de données.
- Tests : tests d'API, tests de bout en bout dans un navigateur (Playwright), et un test de fumée après chaque déploiement.
- Sécurité : les risques du Top 10 de l'OWASP (injections, authentification, droits d'accès, XSS, CSRF), mots de passe hachés, HTTPS. Pour les données personnelles, le RGPD : consentement, droits d'accès et d'effacement.
- Publication : un environnement de test avant la production, des déploiements qu'on peut annuler, et des sauvegardes de la base vérifiées par une vraie restauration.

**Outil en ligne de commande ou bibliothèque**
- Performance : temps d'exécution et mémoire, sur une entrée type et sur une très grosse entrée ; des bancs d'essai pour une bibliothèque.
- Tests : tests de l'API publique, et tests de bout en bout des commandes (entrées, sorties, codes de retour).
- Sécurité : entrées et fichiers validés ; jamais de commande shell construite à partir d'une entrée.
- Publication : un gestionnaire de paquets (NuGet, npm, PyPI…), des versions sémantiques et un journal des changements. L'API publique ne casse qu'à une version majeure.

## Phases d'un projet

0. Fondations : git, techno, CLAUDE.md, MCP, skills et hooks.
1. Prototype : le cœur du produit, utilisable de bout en bout en version brute (gray-box pour un jeu), sur une base réseau si le produit en a besoin.
2. Identité visuelle, avec la bible de style des IA génératives, et page de présentation, en parallèle : page Steam « Coming Soon », fiche de boutique, site.
3. Tranche verticale : un parcours complet à la qualité finale, comme un niveau de jeu ou une fonctionnalité phare.
4. Bêta ou démo : Steam Next Fest, TestFlight, bêta fermée.
5. Itérations de contenu et de fonctionnalités, avec un accès anticipé possible.
6. Lancement.
7. Suivi : correctifs, mises à jour et retours des utilisateurs.

`docs/feuille-de-route.md` découpe ces phases en sessions. Le document de conception définit le jalon de chaque phase et son critère de passage. Ce qu'on fait à chaque jalon (tag, version profilée, exports, copie du dossier) est en tête de la feuille de route.

## Améliorer la méthode

La méthode vit dans le dossier de ce skill, un dépôt git que `preparer-pc.ps1` relie à `~/.claude/skills/methode-projet`. Quand une façon de travailler s'améliore sur un projet :
1. modifier ce fichier, les scripts ou les modèles. Un nouveau fichier commun va dans `modeles/projet/`. Une nouvelle techno va dans `modeles/techno/<techno>/` : copier `base`, puis ajouter au `.gitignore` le modèle officiel de la techno (dépôt `github/gitignore`) et au `.gitattributes` ses fichiers lourds, suivis par Git LFS ;
2. noter le changement et son pourquoi dans `CHANGELOG.md` ;
3. commiter tout de suite, sans attendre la fin de la tâche du projet, et pousser si le dépôt a un remote : le skill reste à jour sur chaque PC.

Les projets existants ne sont pas mis à jour d'office : proposer à l'utilisateur de reporter le changement.
