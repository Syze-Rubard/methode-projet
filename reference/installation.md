# Installer, démarrer, reprendre, partager

À lire pour démarrer un projet, le reprendre sur un autre PC, partager la méthode, ou toucher aux scripts et aux hooks.

Sommaire : les scripts · démarrer un projet · reprendre sur un autre PC · partager la méthode · les hooks · pièges du poste Windows.

## Les scripts

Deux scripts du dossier du skill font l'installation. Les lancer avec `powershell -NoProfile -ExecutionPolicy Bypass -File "<dossier du skill>\<script>.ps1"`. Ils ne détruisent rien et se relancent sans risque. Les scripts et les hooks tournent sous Windows (PowerShell 5.1) : sur Mac ou Linux, il faut d'abord les porter. Chaque ligne de leur sortie commence par un état : `[ok]`, `[créé]`, `[installé]`, `[réglé]`, `[à faire]` ou `[à remplir]`.

- **`preparer-pc.ps1`**, une fois par PC :
  - il installe avec winget ce qui manque (git, Git LFS, GitHub CLI) et active Git LFS ;
  - il relie le skill à Claude Code et vérifie la compaction automatique ;
  - si le skill est sur un disque venu d'un autre PC, il le fait accepter par git (`safe.directory`).

  Avant de le lancer, prévenir l'utilisateur que Windows peut lui demander d'autoriser une installation. Puis l'aider sur chaque `[à faire]` :
  - **identité git** : lui demander un nom et un e-mail, puis relancer avec `-NomGit` et `-EmailGit`. Si un dépôt peut devenir public, proposer l'adresse « noreply » de GitHub ;
  - **connexion à GitHub** : `gh auth login`, lancé par l'utilisateur, jamais par Claude. Le script donne le chemin complet de `gh`, qui marche aussi dans un terminal ouvert avant l'installation. Une fois connecté, il fait passer git par ce compte et l'affiche : vérifier avec l'utilisateur que c'est bien celui qui possède ses dépôts. Sinon, il se reconnecte au bon compte dans le navigateur, relance `gh auth login`, puis `gh auth switch` ;
  - **compaction** : `/autocompact 300k`, que l'utilisateur tape lui-même.

  Relancer le script jusqu'à ce qu'il ne reste rien à faire.
- **`preparer-projet.ps1 -Chemin <dossier> [-Nom <nom>] [-Techno <techno>] [-Leger]`**, pour chaque projet et sur chaque PC. Les technos disponibles sont les dossiers de `modeles/techno/` ; `base` convient à toutes en attendant la leur. `-Leger`, pour un petit projet, prend les modèles de `modeles/leger/` à la place des communs : une feuille de route en trois phases. Le script :
  - il copie les modèles sans écraser un fichier existant ;
  - il dirige la mémoire de Claude Code vers `docs/memoire`, et corrige le chemin si le disque a changé de lettre ;
  - il initialise git, avec LFS si la techno en a besoin ;
  - si le dépôt est sur un disque venu d'un autre PC, il le fait accepter par git (`safe.directory`) : sinon git le refuse, car ses dossiers appartiennent au compte de l'autre PC ;
  - il liste les `{{...}}` qui restent à remplir.
- **`controler-projet.ps1 -Chemin <dossier> [-Silencieux]`** vérifie, en lecture seule, qu'un projet suit toujours la méthode (voir « Contrôle » dans `SKILL.md`). Il sort à 1 s'il reste une ligne `[à corriger]`. Le hook `garde-methode` le lance avant chaque commit du projet, en silence s'il n'y a rien à dire.

Les modèles :
- `modeles/projet/` contient les fichiers communs à tous les projets, dont les trois types d'agents de `.claude/agents/` ;
- `modeles/leger/` contient ce qui change pour un petit projet ; un fichier qui y porte le même chemin remplace celui de `modeles/projet/` ;
- `modeles/techno/<techno>/` contient le `.gitignore` et le `.gitattributes` de chaque techno ;
- le script remplit `{{NOM}}` et `{{nom}}`, et Claude remplit les autres `{{...}}`.

## Démarrer un projet

1. Demander à l'utilisateur le nom du projet, son pitch en une phrase, son type (voir `types-de-projet.md`), la techno, sa taille, et le document de conception (GDD, cahier des charges…) s'il existe. Un petit projet, c'est un outil, une bibliothèque ou un essai de quelques semaines : il prend le chemin léger.
2. Lancer `preparer-pc.ps1`. Si tout est `[ok]`, passer à la suite.
3. Si la techno n'a pas encore de modèle dans `modeles/techno/`, le créer d'abord (voir « Améliorer la méthode » dans `SKILL.md`). Puis lancer `preparer-projet.ps1` sur le dossier du projet, avec `-Techno`, et `-Leger` pour un petit projet.
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

- La méthode tient dans le dossier du skill, dans un dépôt GitHub public : on la partage par son lien, https://github.com/Syze-Rubard/methode-projet, ou en copie du dossier. Les dépôts des projets, eux, restent privés.
- Ce dépôt étant public, ses commits portent l'adresse anonyme de GitHub (`…@users.noreply.github.com`), jamais une vraie adresse e-mail, et rien d'un projet privé n'y entre : ni nom de serveur, ni chemin, ni secret.
- La personne installe Claude Code, puis suit le `README.md` du dossier : il lui fait lancer `preparer-pc.ps1`.
- Elle a sa propre identité git et son propre compte GitHub. Ses projets ont leur propre mémoire.

## Les hooks

- Écrits en PowerShell 5.1, présent sur tout Windows, et enregistrés en UTF-8 avec BOM : sans BOM, les accents sont cassés.
- Déclarés en forme exec dans `.claude/settings.json` (`"command": "powershell.exe"` et `"args"`), avec un chemin relatif au projet : ça marche que Claude Code passe par Git Bash ou par PowerShell.
- Tester un hook en lui envoyant un JSON d'exemple sur l'entrée standard avant de le déclarer.
- `rappel-clear.ps1` (Stop) affiche un message à l'utilisateur après un nouveau commit, et quand le contexte franchit 150k, 250k, 350k tokens… Les seuils sont en tête du script.
- `garde-tests.ps1` (Stop et `pre-commit`) retient l'empreinte des fichiers qui ont passé `verifier.ps1`. Les docs et les `.md` n'en font pas partie. Il ne fait rien tant que le projet n'a pas de `verifier.ps1`. Il renvoie Claude au travail une seule fois par tour, pour ne pas boucler.
- `garde-secrets.ps1` (`pre-commit`, avant `garde-tests`) bloque un commit qui ajoute un fichier de clé (`.env`, `.pem`, `.pfx`, `.keystore`…) ou une ligne qui ressemble à un secret : clé privée, jeton connu, mot de passe écrit en clair. Il montre l'endroit, jamais le secret. Un faux positif reconnu porte le marqueur `garde-secrets: ignorer` sur sa ligne, avec l'accord de l'utilisateur.
- `garde-methode.ps1` (`pre-commit`, entre `garde-secrets` et `garde-tests`) lance `controler-projet.ps1` du skill et bloque le commit s'il reste une ligne `[à corriger]`. Sur une machine sans le skill, comme l'intégration continue, il ne fait rien.
- `garde-generation-ia.ps1` (PreToolUse, sur les outils MCP qui génèrent) refuse une génération d'image, de vidéo, de modèle 3D ou de son tant que le modèle appelé n'a pas de fiche à jour dans `docs/generation-ia/modeles/`. Une estimation de coût et la reprise d'un travail lancé passent. Voir `generation-ia.md`.
- Les hooks git vivent dans `.githooks/`, versionnés, avec des fins de ligne LF (règle dans `.gitattributes`). `preparer-projet.ps1` les active, et Git LFS y écrit aussi les siens.
- Le skill a aussi son `pre-commit`, que `preparer-pc.ps1` active : il lance `tests/tester-les-scripts.ps1` avant chaque commit de la méthode.

## Pièges du poste Windows

- **Un patch de code ne passe jamais par un heredoc de Bash** : il y perd un niveau d'antislash. Passer par l'outil d'édition, ou écrire un script sur le disque et le lancer.
- Dans un texte inséré par Bash, un backtick **s'exécute** ; dans le remplacement de `String.replace` (JavaScript), un `$` est lu comme un motif : passer une fonction.
- **Un script PowerShell qui contient des accents s'enregistre en UTF-8 avec BOM**, même jetable : sans BOM, PowerShell 5.1 le lit en ANSI, ses textes avec accents ne trouvent plus rien à remplacer, et il écrit du charabia (« Ã  » pour « à ») dans les fichiers qu'il touche.
- PowerShell 5.1 coupe les guillemets doubles internes d'une commande passée à un programme : pour piloter un serveur par `ssh`, préférer Git Bash avec `MSYS_NO_PATHCONV=1`.
- Un disque peut changer de lettre d'un PC à l'autre : `preparer-projet.ps1` corrige le chemin de la mémoire ; les jonctions et les dossiers de travail qui portent la lettre se réparent à la main.
