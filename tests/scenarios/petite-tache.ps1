# A small task in a project that has code. Does Claude fix it in a few steps, verify, and touch
# nothing else: no document, no memory, no setting?
@{
    Demande    = 'Petite correction : dans src/accueil.ps1, le message dit « Bienvenu », il faut « Bienvenue ».'
    PlafondUsd = 1
    Preparer   = {
        param($Dir)
        New-PreparedProject $Dir 'Accueil'
        Set-Roadmap $Dir 'le squelette et la vérification sont faits (0.2). Prochaine session : 1.1.' '0.1', '0.2'
        Edit-Text (Join-Path $Dir 'docs\README.md') '  {{DOSSIERS DU CODE ET DES CONTENUS}}' "  outils/                   verifier.ps1 : la commande unique qui vérifie tout`n  src/                      le code de l'outil"
        Complete-Placeholders $Dir
        New-Item -ItemType Directory -Path (Join-Path $Dir 'src'), (Join-Path $Dir 'outils') | Out-Null
        Set-Text (Join-Path $Dir 'src\accueil.ps1') "param([string]`$Nom = 'toi')`r`nWrite-Output `"Bienvenu dans Accueil, `$Nom.`"`r`n"
        $verifier = Join-Path $Dir 'outils\verifier.ps1'
        Copy-Item -LiteralPath (Join-Path $Skill 'modeles\outils\verifier.ps1') -Destination $verifier
        $eol = if ((Get-Text $verifier).Contains("`r`n")) { "`r`n" } else { "`n" }
        Edit-Text $verifier "`$Checks = @($eol)" "`$Checks = @($eol    @{ Name = 'Accueil'; Run = { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"`$ProjectDir\src\accueil.ps1`" -Nom Test | Out-Null } }$eol)"
        Save-Start $Dir
    }
    Simuler    = {
        param($Dir)
        Edit-Text (Join-Path $Dir 'src\accueil.ps1') 'Bienvenu dans' 'Bienvenue dans'
        New-Session -Commandes 'powershell -NoProfile -ExecutionPolicy Bypass -File outils/verifier.ps1' -Tours 6
    }
    Verifier   = {
        param($Dir, $Session)
        $code = Get-Text (Join-Path $Dir 'src\accueil.ps1')
        $outside = @(Get-Changed $Dir | Where-Object { $_ -notmatch '^(src|outils|tests)/' })
        Test-Fait ($code -match 'Bienvenue dans Accueil' -and $code -notmatch 'Bienvenu(?!e)') 'la faute est corrigée'
        Test-Fait (Test-Commande $Session 'verifier\.ps1') 'outils/verifier.ps1 est lancé'
        Test-Fait ($outside.Count -eq 0) "rien d'autre n'est touché : ni document, ni mémoire, ni réglage $($outside -join ', ')"
        Test-Fait ($Session.Tours -ge 1 -and $Session.Tours -le 15) "une petite tâche reste petite : $($Session.Tours) tour(s), 15 au plus"
    }
}
