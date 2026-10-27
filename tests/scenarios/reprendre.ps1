# Picking a project up on another PC: the disk is plugged in, without this PC's own settings. Does
# Claude call the skill, put the project back in working order, and name the next step?
@{
    Demande  = 'Je viens de brancher le disque de ce projet sur un autre PC. Remets-le en route ici, puis dis-moi où on en est et quelle est la prochaine étape.'
    Preparer = {
        param($Dir)
        New-PreparedProject $Dir 'Carnet'
        Edit-Text (Join-Path $Dir 'docs\feuille-de-route.md') '- [ ] **1.1 {{FONCTIONNALITÉ}}.** {{CE QUE LA SESSION CONSTRUIT}}' "- [ ] **1.1 Saisie des notes.** Une note s'ajoute en une commande.`n- [ ] **1.2 Export CSV des notes.** Les notes sortent dans un fichier CSV, une ligne par note."
        Set-Roadmap $Dir 'la saisie des notes marche (1.1). Prochaine session : 1.2.' '0.1', '0.2', '1.1'
        Complete-Placeholders $Dir
        Save-Start $Dir
        # This PC's settings are not in git: a disk from another PC comes without them.
        Remove-Item -LiteralPath (Join-Path $Dir '.claude\settings.local.json')
    }
    Simuler  = {
        param($Dir)
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Skill 'preparer-projet.ps1') -Chemin $Dir | Out-Null
        New-Session -Skills 'methode-projet' -Commandes 'powershell -File preparer-pc.ps1', 'powershell -File preparer-projet.ps1 -Chemin .' -Reponse 'Le projet est remis en route. Prochaine étape : 1.2, Export CSV des notes. Ouvre une nouvelle session pour activer les hooks et la mémoire.'
    }
    Verifier = {
        param($Dir, $Session)
        $settings = Join-Path $Dir '.claude\settings.local.json'
        $memory = if (Test-Path -LiteralPath $settings) { "$((Get-Text $settings | ConvertFrom-Json).autoMemoryDirectory)" -replace '\\', '/' } else { '' }
        $head = Invoke-Git $Dir @('rev-parse', 'HEAD')
        $start = Invoke-Git $Dir @('rev-parse', 'depart')
        $modified = @((Invoke-Git $Dir @('status', '--porcelain', '--untracked-files=no')).Lignes | Where-Object { $_ })
        Test-Fait (Test-Skill $Session) 'le skill methode-projet est lu'
        Test-Fait (Test-Commande $Session 'preparer-pc\.ps1') 'preparer-pc.ps1 est lancé'
        Test-Fait (Test-Commande $Session 'preparer-projet\.ps1') 'preparer-projet.ps1 est relancé sur le projet'
        Test-Fait ($memory -ne '' -and $memory -ieq (($Dir -replace '\\', '/') + '/docs/memoire')) 'la mémoire de Claude Code pointe de nouveau dans le projet'
        Test-Fait ($Session.Reponse -match 'Export CSV') 'la réponse donne la prochaine étape : 1.2, Export CSV des notes'
        Test-Fait ($Session.Reponse -match '(?i)nouvelle (session|conversation)|session neuve|(relance|redémarre|rouvre|rouvrir)\w* claude') "la réponse dit qu'une nouvelle session active les hooks et la mémoire"
        Test-Fait ($head.Code -eq 0 -and "$($head.Lignes)" -eq "$($start.Lignes)" -and $modified.Count -eq 0) 'aucun fichier suivi ne change, aucun commit'
    }
}
