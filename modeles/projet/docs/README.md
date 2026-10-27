# Carte du projet {{NOM}}

Cette carte dit où vit chaque chose et qui la tient à jour. CLAUDE.md la charge à chaque session et dans chaque sous-agent : elle reste sous 80 lignes, et ne raconte aucune histoire. Elle est mise à jour dans la même session dès qu'un dossier ou un document est ajouté, déplacé ou supprimé.

## Dans le dossier

```
{{NOM}}/
  CLAUDE.md                 règles de travail de Claude
  .gitignore                fichiers que git ignore
  .gitattributes            fichiers lourds suivis par Git LFS
  .claude/
    settings.json           hooks du projet (versionné)
    settings.local.json     réglages propres à ce PC, dont le chemin de la mémoire (non versionné)
    agents/                 trois types d'agents, un par niveau d'effort : leger, moyen, haut
    hooks/
      rappel-clear.ps1      prévient quand c'est le bon moment de faire /clear
      garde-tests.ps1       empêche de finir ou de commiter du code non vérifié
      garde-secrets.ps1     empêche de commiter un secret
      garde-generation-ia.ps1  empêche de générer avec une IA sans connaître son modèle
  .githooks/                hooks git versionnés : secrets et vérification avant chaque commit
  outils/
    verifier.ps1            lance toutes les vérifications du projet (créé avec le premier code)
    perf-reference.json     mesures de performance de référence sur ce PC (non versionné)
  docs/
    README.md               cette carte
    architecture.md         principes de code, structure, conventions, décisions techniques
    feuille-de-route.md     les étapes du projet jusqu'au lancement, et où on en est
    generation-ia/
      style.md              bible de style pour les IA génératives
      modeles/              une fiche par modèle d'IA : comment lui parler (modèle : _modele.md)
    memoire/                mémoire de Claude : l'index MEMORY.md et une fiche par sujet
  {{DOSSIERS DU CODE ET DES CONTENUS}}
```

Tout ce dossier est sauvegardé sur GitHub à chaque commit poussé, et copié sur un autre support à chaque jalon.

## Hors du dossier

| Document | Contenu | Sauvegarde |
|---|---|---|
| {{DOCUMENT DE CONCEPTION ET SON LIEN}} | La conception du projet, source de vérité | {{OÙ}} |
| Skill `methode-projet` | La méthode de travail, commune à tous les projets | son dépôt GitHub |

## Outils du PC

Les outils de la méthode (git, Git LFS, GitHub CLI) sont installés par le script `preparer-pc.ps1` du skill. Ceux du projet, à installer sur chaque PC :

| Outil | Version | Pour |
|---|---|---|
| {{OUTIL}} | {{VERSION}} | {{À QUOI IL SERT}} |

## Qui tient quoi à jour

Un sujet par document, sans doublon.

| Sujet | Où | À mettre à jour quand |
|---|---|---|
| Conception du projet | {{DOCUMENT DE CONCEPTION}} | une fonctionnalité est construite ou une décision est prise |
| Principes, structure et conventions du code | [architecture.md](architecture.md) | un module, un dossier de code ou une convention change |
| Décisions techniques | [architecture.md](architecture.md) | une décision technique est prise |
| Étapes du projet et avancement | [feuille-de-route.md](feuille-de-route.md) | une étape est finie, ajoutée ou déplacée |
| Style des contenus générés par IA | [generation-ia/style.md](generation-ia/style.md) | une décision de style est prise |
| Façon de parler à chaque modèle d'IA | [generation-ia/modeles/](generation-ia/modeles/_modele.md) | avant d'utiliser un modèle sans fiche, ou dont la fiche a plus de 60 jours |
| Dossiers et documents | cette carte | on en ajoute, en déplace ou en supprime un |
| Outils du PC | cette carte | un outil ou sa version change |
| Décisions, préférences, état du projet | [memoire/](memoire/MEMORY.md) | une info durable apparaît |
| Règles de travail de Claude | [CLAUDE.md](../CLAUDE.md) | une règle change |
| Méthode de travail | skill `methode-projet` | une façon de travailler s'améliore |
