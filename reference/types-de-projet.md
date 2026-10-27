# Selon le type de projet, et les phases

À lire au démarrage d'un projet, et à chaque changement de phase.

Les règles du skill valent pour tous les projets de code. Voici ce qui change d'un type à l'autre. Au démarrage, Claude reporte les choix du projet dans les sections « Tests et qualité », « Performance » et « Sécurité » de `architecture.md`.

## Jeu (PC, console ou mobile)

- Performance : temps par image, aucune allocation par image en jeu, chargements, mémoire. Sur mobile, aussi la chauffe, la batterie et la taille du téléchargement.
- Tests : tests de jeu automatiques, et un test de fumée qui charge chaque scène et joue quelques secondes.
- Sécurité : en réseau, l'hôte fait autorité ; les sauvegardes sont validées au chargement.
- Publication : Steam (page « Coming Soon » tôt, Next Fest, déclaration des contenus IA), App Store et Google Play, ou les programmes de développeur des consoles.

## Appli mobile

- Performance : démarrage à froid, défilement fluide, mémoire, batterie, données consommées, taille de l'appli.
- Tests : tests d'interface sur émulateur et sur un vrai téléphone d'entrée de gamme, et un test de fumée qui ouvre chaque écran. Ce qu'un appareil annonce savoir lire ou décoder n'est pas une mesure : on essaie sur l'appareil.
- Sécurité : jetons et secrets dans le coffre du système (Keychain, Keystore), jamais en clair. Le moins de permissions possible, demandées au moment où elles servent. HTTPS partout.
- Publication : App Store et Google Play, avec leur fiche de confidentialité. Bêta par TestFlight et par les tests fermés de Google Play. Construire pour iOS demande un Mac ou un service de build en ligne.

## Logiciel de bureau

- Performance : démarrage, interface qui répond en moins de 100 ms, mémoire au repos et en charge.
- Tests : tests d'interface automatisés, et un test de fumée qui lance le programme et ouvre chaque fenêtre.
- Sécurité : installeur et exécutable signés, mises à jour par un canal signé, fichiers ouverts validés.
- Publication : un installeur, une boutique (Microsoft Store, Steam), ou un gestionnaire de paquets (winget).

## Site ou service web

- Performance : chargement des pages (Core Web Vitals), temps de réponse au 95e centile, poids des pages, requêtes à la base de données.
- Tests : tests d'API, tests de bout en bout dans un navigateur (Playwright), et un test de fumée après chaque déploiement. Toute vue neuve se prouve par des captures en 375, 768, 1 024 et 1 280 px de large, plein écran compris. Au navigateur, rien ne se conclut sans mesure : un onglet masqué fige les animations et les minuteries.
- Build : le build de production voit ce que ni le compilateur ni les tests ne voient (un composant client qui importe du code serveur, une règle de lint traitée en erreur) : il fait partie de la vérification avant une livraison.
- Sécurité : les risques du Top 10 de l'OWASP (injections, authentification, droits d'accès, XSS, CSRF), mots de passe hachés, HTTPS. Pour les données personnelles, le RGPD : consentement, droits d'accès et d'effacement.
- Publication : un environnement de test avant la production, des déploiements qu'on peut annuler, et des sauvegardes de la base vérifiées par une vraie restauration. Un numéro de version monte à chaque livraison, et se voit dans le produit. Jamais de déploiement pendant une tâche planifiée du serveur (cycle de nuit, sauvegarde) : elle serait tuée en plein vol.

## Outil en ligne de commande ou bibliothèque

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

Un petit projet (un outil, une bibliothèque, un essai de quelques semaines) prend le chemin léger, `preparer-projet.ps1 -Leger` : trois phases, fondations, construction et livraison. S'il grandit, on passe à la feuille de route complète, en gardant les cases déjà cochées.
