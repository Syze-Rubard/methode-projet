# Starting a small project. Does Claude call the skill, take the light path, fill every placeholder,
# tick 0.1 and commit, without a GitHub repository since the user said no?
@{
    Demande    = 'Je démarre un nouveau projet dans ce dossier : mets-le en place comme mes autres projets. Nom : Minuteur. Pitch : un petit outil en ligne de commande qui chronomètre des sessions de travail et les note dans un fichier. Type : outil en ligne de commande. Techno : base. Taille : petit, quelques semaines de travail. Pas de document de conception. C''est un essai : ne crée pas de dépôt GitHub et ne pousse rien.'
    PlafondUsd = 3
    Preparer   = { param($Dir) }
    Simuler    = {
        param($Dir)
        New-PreparedProject $Dir 'Minuteur'
        Set-Roadmap $Dir 'le démarrage est fait (0.1). Prochaine session : 0.2.' '0.1'
        Complete-Placeholders $Dir
        [void](Invoke-Git $Dir @('add', '-A'))
        [void](Invoke-Git $Dir @('commit', '-q', '-m', 'Démarrage du projet'))
        New-Session -Skills 'methode-projet' -Commandes 'powershell -File preparer-pc.ps1', 'powershell -File preparer-projet.ps1 -Chemin . -Nom Minuteur -Techno base -Leger'
    }
    Verifier   = {
        param($Dir, $Session)
        $roadmap = Get-Text (Join-Path $Dir 'docs\feuille-de-route.md')
        $left = @(Get-ChildItem -LiteralPath $Dir -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue |
            Where-Object { (Get-Text $_.FullName) -match '\{\{[^}]+\}\}' } | ForEach-Object { $_.FullName.Substring($Dir.Length + 1) })
        $remote = Invoke-Git $Dir @('remote')
        $fix = @(Get-ToFix $Dir)
        Test-Fait (Test-Skill $Session) 'le skill methode-projet est lu'
        Test-Fait (Test-Commande $Session 'preparer-pc\.ps1') 'preparer-pc.ps1 est lancé'
        Test-Fait (Test-Commande $Session 'preparer-projet\.ps1.*-Leger') 'preparer-projet.ps1 est lancé avec -Leger : un petit projet'
        Test-Fait ($roadmap -match '## Phase 2' -and $roadmap -notmatch '## Phase 3') 'la feuille de route est la légère : trois phases'
        Test-Fait ($roadmap -match '- \[x\] \*\*0\.1') "l'étape 0.1 est cochée"
        Test-Fait ((Test-Path -LiteralPath (Join-Path $Dir 'CLAUDE.md')) -and $left.Count -eq 0) "plus aucun {{...}} à remplir $($left -join ', ')"
        Test-Fait ((Invoke-Git $Dir @('rev-parse', '--verify', '-q', 'HEAD')).Code -eq 0) 'un premier commit est fait'
        Test-Fait ($fix.Count -eq 0) "le contrôle de la méthode passe $($fix -join ' ; ')"
        Test-Fait ($remote.Code -eq 0 -and @($remote.Lignes | Where-Object { $_ }).Count -eq 0) 'aucun dépôt distant'
    }
}
