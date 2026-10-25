# Architecture et conventions de code

Ce document évolue avec le code.

## Principes

1. **Petit et générique.** Une fonction fait une seule chose, en quelques lignes, et ne dépend que de ce qu'on lui passe. Une classe a une seule responsabilité.
2. **Composer plutôt qu'hériter.** Un comportement est un assemblage de briques réutilisables, décrit par des données. Une nouveauté se fait en assemblant des briques existantes quand c'est possible.
3. **Piloté par les données.** Valeurs et contenus vivent dans des données (ScriptableObjects sous Unity), et l'équilibrage ne touche pas au code.
4. **Modules découplés.** Les modules se parlent par interfaces et par événements. Le compilateur vérifie les frontières quand la techno le permet (Assembly Definitions sous Unity).
5. **Logique séparée de l'affichage.** L'état vit dans des classes pures, testables ; l'affichage ne fait qu'afficher et relayer.
6. **Échouer bruyamment.** Aucune erreur silencieuse : références vérifiées à l'initialisation, assertions et logs explicites.
7. **Testé.** Chaque brique de logique pure a ses tests.

## Structure

```
{{ARBORESCENCE DU CODE, un commentaire par dossier}}
```

## Règles de dépendance

- {{Qui dépend de qui ; ce qui ne dépend de rien}}
- Pas de singleton caché : les services sont créés au démarrage et transmis à ceux qui en ont besoin.

## Conventions

- Code en anglais, docs en français.
- {{Nommage, un type par fichier, namespace qui suit le dossier}}
- Git : une branche par fonctionnalité, de petits commits, Git LFS pour les assets lourds, un tag par jalon.

## Décisions techniques

Une ligne par décision, avec son pourquoi, pour ne pas la rediscuter.

| Date | Décision | Pourquoi |
|---|---|---|

## Tests et qualité

| Niveau | Quoi | Outil |
|---|---|---|
| {{NIVEAU : logique, données, intégration, fumée…}} | {{CE QUI EST TESTÉ}} | {{OUTIL DE TEST}} |

`outils/verifier.ps1` lance tous ces niveaux, du plus rapide au plus lent.

## Définition de « fini »

`outils/verifier.ps1` vert (compilation sans warning, tous les tests), essayé en vrai, diff relu, docs à jour, commit fait et poussé.
