# Checking a project that drifted: its CLAUDE.md imports MEMORY.md, which Claude Code then loads
# twice. Does Claude run the control, remove that import, and leave everything else as it was?
@{
    Demande  = 'Vérifie que ce projet suit toujours bien la méthode, et corrige ce qui ne va pas.'
    Preparer = {
        param($Dir)
        New-PreparedProject $Dir 'Atelier'
        Set-Roadmap $Dir 'le démarrage est fait (0.1). Prochaine session : 0.2.' '0.1'
        Complete-Placeholders $Dir
        $claudeMd = Join-Path $Dir 'CLAUDE.md'
        Set-Text $claudeMd ((Get-Text $claudeMd).TrimEnd() + "`n@docs/memoire/MEMORY.md`n")
        Save-Start $Dir
    }
    Simuler  = {
        param($Dir)
        $claudeMd = Join-Path $Dir 'CLAUDE.md'
        Set-Text $claudeMd ((Get-Text $claudeMd) -replace '(?m)^@docs/memoire/MEMORY\.md\r?\n', '')
        New-Session -Skills 'methode-projet' -Commandes 'powershell -File controler-projet.ps1 -Chemin .'
    }
    Verifier = {
        param($Dir, $Session)
        $claudeMd = Get-Text (Join-Path $Dir 'CLAUDE.md')
        $others = @(Get-Changed $Dir | Where-Object { $_ -ne 'CLAUDE.md' })
        $fix = @(Get-ToFix $Dir)
        Test-Fait (Test-Skill $Session) 'le skill methode-projet est lu'
        Test-Fait (Test-Commande $Session 'controler-projet\.ps1') 'controler-projet.ps1 est lancé'
        Test-Fait ($claudeMd -match '(?m)^@docs/README\.md' -and $claudeMd -notmatch '(?m)^\s*@\S*MEMORY\.md') "CLAUDE.md n'importe plus MEMORY.md, et importe toujours la carte"
        Test-Fait ($fix.Count -eq 0) "le contrôle passe à la fin $($fix -join ' ; ')"
        Test-Fait ((Test-Path -LiteralPath (Join-Path $Dir 'docs\memoire\MEMORY.md')) -and $others.Count -eq 0) "rien d'autre ne change, l'index de la mémoire compris $($others -join ', ')"
    }
}
