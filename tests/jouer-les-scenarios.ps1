# The method's scenarios: real Claude Code sessions in throwaway folders, each given a request worded
# as the user would, then checked on what they did (the skill read, the commands run, the files
# left). They answer what the scripts' tests cannot: does Claude call the skill at the right moment,
# and follow it? Each session spends tokens: its cost is shown, and capped.
# -ASec plays each scenario without Claude and without a token: its checks must fail on an untouched
# folder and pass on an ideal session. tests/tester-les-scripts.ps1 runs it before each commit.
# A real run needs Claude Code signed in once, from a terminal: claude, then /login.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File tests/jouer-les-scenarios.ps1
#        [-Scenarios demarrer,reprendre] [-Modele sonnet] [-PlafondUsd 1.5] [-ASec] [-Garder]

param(
    [string[]]$Scenarios,
    [string]$Modele = 'sonnet',
    [double]$PlafondUsd = 1.5,
    [switch]$ASec,
    [switch]$Garder
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$OutputEncoding = New-Object Text.UTF8Encoding $false

$Skill = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Work = Join-Path ([IO.Path]::GetTempPath()) ('methode-projet-scenarios-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$Today = Get-Date -Format 'yyyy-MM-dd'

# --- What the scenarios share: their starting state, and what a session left behind.

function Get-Text([string]$Path) { if (Test-Path -LiteralPath $Path) { [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8) } else { '' } }
function Set-Text([string]$Path, [string]$Text, [switch]$Bom) { [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding $Bom.IsPresent)) }

# Replaces a template's text, keeping its BOM, and fails loudly when the template no longer has it.
function Edit-Text([string]$Path, [string]$Old, [string]$New) {
    $text = Get-Text $Path
    if (-not $text.Contains($Old)) { throw "le modèle a changé : « $Old » n'est plus dans $Path" }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    Set-Text $Path $text.Replace($Old, $New) -Bom:$bom
}

# Lignes holds git's output alone, Erreurs its messages: a warning about line endings is not a file.
function Invoke-Git([string]$Dir, [string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    $output = @(& git -C $Dir -c core.quotePath=false -c user.name=Test -c user.email=test@example.com @Arguments 2>&1)
    [pscustomobject]@{
        Code    = $LASTEXITCODE
        Lignes  = @($output | Where-Object { $_ -isnot [Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
        Erreurs = @($output | Where-Object { $_ -is [Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
    }
}

# preparer-projet.ps1 on a small project, as Claude launches it to start one.
function Invoke-PreparerProjet([string]$Dir, [string]$Name) {
    $ErrorActionPreference = 'Continue'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Skill 'preparer-projet.ps1') -Chemin $Dir -Nom $Name -Leger 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "preparer-projet.ps1 a échoué sur $Dir" }
}

# A small project as a project in use has it: prepared by the skill, with its remote (a bare
# repository next to it, so that nothing leaves the PC) and the tools of the PC in its map.
function New-PreparedProject([string]$Dir, [string]$Name) {
    Invoke-PreparerProjet $Dir $Name
    $origin = "$Dir-origine.git"
    [void](Invoke-Git $Dir @('init', '-q', '--bare', $origin))
    [void](Invoke-Git $Dir @('remote', 'add', 'origin', $origin))
    $sheet = (Get-ChildItem -LiteralPath (Join-Path $Dir 'docs\memoire') -Filter 'project-*.md' | Select-Object -First 1).FullName
    Edit-Text $sheet '{{WHAT THE PROJECT IS, IN TWO OR THREE SENTENCES}}' "$Name is a small PowerShell command-line tool. It keeps its data in plain files next to it."
    Edit-Text $sheet "{{CURRENT STATE: what exists and what waits for the user's go-ahead; the next steps live in docs/feuille-de-route.md}}" "State ($Today): in use, nothing waits for a go-ahead; the next steps live in docs/feuille-de-route.md."
    $map = Join-Path $Dir 'docs\README.md'
    Edit-Text $map '{{OUTIL}}' 'PowerShell'
    Edit-Text $map '{{VERSION}}' '5.1'
    Edit-Text $map '{{À QUOI IL SERT}}' 'lance les scripts et la vérification'
}

# Code in src/, with its outils/verifier.ps1 made from the skill's template (each script of src
# runs without arguments and succeeds), and both folders cited by the map.
function Add-Code([string]$Dir, [string]$Name, [string]$Content) {
    New-Item -ItemType Directory -Force -Path (Join-Path $Dir 'src'), (Join-Path $Dir 'outils') | Out-Null
    Set-Text (Join-Path $Dir "src\$Name") $Content -Bom
    $verifier = Join-Path $Dir 'outils\verifier.ps1'
    Copy-Item -LiteralPath (Join-Path $Skill 'modeles\outils\verifier.ps1') -Destination $verifier
    $eol = if ((Get-Text $verifier).Contains("`r`n")) { "`r`n" } else { "`n" }
    $check = "    @{ Name = 'Scripts de src'; Run = { foreach (`$file in Get-ChildItem `"`$ProjectDir\src`" -Filter *.ps1) { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `$file.FullName | Out-Null; if (`$LASTEXITCODE -ne 0) { return } } } }"
    Edit-Text $verifier "`$Checks = @($eol)" "`$Checks = @($eol$check$eol)"
    Edit-Text (Join-Path $Dir 'docs\README.md') '  {{DOSSIERS DU CODE ET DES CONTENUS}}' "  outils/                   verifier.ps1 : la commande unique qui vérifie tout`n  src/                      le code"
}

# Ticks the given steps of the roadmap, and writes « Où on en est », dated today.
function Set-Roadmap([string]$Dir, [string]$State, [string[]]$Done) {
    $path = Join-Path $Dir 'docs\feuille-de-route.md'
    Edit-Text $path '{{DATE}} : {{CE QUI EST FINI}}. Prochaine session : {{ÉTAPE}}.' "$Today : $State"
    foreach ($step in $Done) { Edit-Text $path "- [ ] **$step" "- [x] **$step" }
}

# A project in use has no placeholder left: each one becomes its own label, in lower case.
function Complete-Placeholders([string]$Dir) {
    $evaluator = [Text.RegularExpressions.MatchEvaluator] { param($m) $m.Groups[1].Value.ToLowerInvariant() }
    foreach ($file in Get-ChildItem -LiteralPath $Dir -Recurse -File -Filter '*.md') {
        $text = Get-Text $file.FullName
        if ($text.Contains('{{')) { Set-Text $file.FullName ([regex]::Replace($text, '\{\{([^}]+)\}\}', $evaluator)) }
    }
}

# The starting state, committed and tagged « depart ». Committed without the hooks: it may carry
# the defect that a scenario plants.
function Save-Start([string]$Dir) {
    [void](Invoke-Git $Dir @('add', '-A'))
    $commit = Invoke-Git $Dir @('commit', '-q', '--no-verify', '-m', 'état de départ')
    if ($commit.Code -ne 0) { throw "l'état de départ ne se commite pas : $(($commit.Lignes + $commit.Erreurs) -join ' ')" }
    [void](Invoke-Git $Dir @('tag', 'depart'))
    if ((Invoke-Git $Dir @('remote')).Lignes -contains 'origin') { [void](Invoke-Git $Dir @('push', '-q', '--no-verify', '-u', 'origin', 'main')) }
}

# The files changed since the starting state, committed or not, new ones included.
function Get-Changed([string]$Dir) {
    $tracked = (Invoke-Git $Dir @('diff', '--name-only', 'depart')).Lignes
    $new = (Invoke-Git $Dir @('ls-files', '--others', '--exclude-standard')).Lignes
    @(@($tracked) + @($new) | Where-Object { $_ } | Sort-Object -Unique)
}

# What a session commits, it pushes too when the project has a remote: the method ends each task so.
# Asking first is fine, the user decides (« Veux-tu que je pousse vers GitHub ? »); claiming there is
# no remote is not. On 2026-10-27, a session committed, wrote « Pas de remote configuré, donc pas de
# push » without looking, and pushed nothing.
function Test-Pousse([string]$Dir, [string]$Reponse) {
    $head = "$((Invoke-Git $Dir @('rev-parse', 'HEAD')).Lignes)"
    if ($head -eq "$((Invoke-Git $Dir @('rev-parse', 'depart')).Lignes)") { return $true }
    $pushed = "$((Invoke-Git $Dir @('ls-remote', 'origin', 'refs/heads/main')).Lignes)" -replace '\s.*$', ''
    if ($pushed -eq $head) { return $true }
    $asks = @([regex]::Split($Reponse, '(?<=[.!?])\s+') | Where-Object { $_ -match '(?i)\b(pousse|push)' -and $_.TrimEnd() -match '\?$' }).Count -gt 0
    $asks -and $Reponse -notmatch '(?i)\b(pas de|aucun|sans) (remote|dépôt distant|origin)'
}

# The [à corriger] lines of the method's control: none when the project follows the method.
function Get-ToFix([string]$Dir) {
    $ErrorActionPreference = 'Continue'
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Skill 'controler-projet.ps1') -Chemin $Dir -Silencieux 2>&1
    $fix = @($output | ForEach-Object { "$_" } | Where-Object { $_ -match '^\[à corriger\]' })
    if ($LASTEXITCODE -ne 0 -and $fix.Count -eq 0) { $fix = @("le contrôle a échoué (code $LASTEXITCODE)") }
    $fix
}

function Test-Fait([bool]$Ok, [string]$Texte) { [pscustomobject]@{ Ok = $Ok; Texte = $Texte } }

# The skill counts as used when the Skill tool loads it, or when its SKILL.md is read directly.
function Test-Skill($Session) {
    @(@($Session.Skills) -match 'methode-projet').Count -gt 0 -or @(@($Session.Lectures) -match 'methode-projet[\\/]SKILL\.md$').Count -gt 0
}

function Test-Commande($Session, [string]$Pattern) { @(@($Session.Commandes) -match $Pattern).Count -gt 0 }

# The hooks and the memory take effect at the next session: does the answer say so, in any words? One
# sentence must name both. « Je peux la remplir lors de la prochaine session » passed a looser check.
function Test-NouvelleSession([string]$Reponse) {
    $sentences = [regex]::Split($Reponse, '(?<=[.!?])\s+')
    @($sentences | Where-Object {
        $_ -match '(?i)(nouvelle|prochaine|autre) (session|conversation)|session (neuve|suivante)|(relance|redémarre|rouvre|rouvrir)\w* claude' -and
        $_ -match '(?i)hooks?\b|mémoire'
    }).Count -gt 0
}

function New-Session([string[]]$Skills = @(), [string[]]$Commandes = @(), [string]$Reponse = '', [int]$Tours = 1) {
    [pscustomobject]@{ Skills = $Skills; Commandes = $Commandes; Lectures = [string[]]@(); Reponse = $Reponse
        Cout = 0.0; Tours = $Tours; Fin = 'success'; Erreur = $false; Refus = 0 }
}

# --- Running Claude Code.

function Find-Claude {
    $command = Get-Command claude -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    # The desktop app ships its own Claude Code, one folder per version.
    $bundled = Get-ChildItem (Join-Path $env:APPDATA 'Claude\claude-code') -Directory -ErrorAction SilentlyContinue |
        Sort-Object { [version]($_.Name -replace '[^\d.]', '') } -Descending |
        ForEach-Object { Join-Path $_.FullName 'claude.exe' } | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($bundled) { return $bundled }
    throw "Claude Code introuvable : ni « claude » dans le PATH, ni la copie de l'application de bureau."
}

# The sessions run alone: without the variables of a host session (the desktop app, or the Claude
# Code that runs this script), so that they neither attach to it nor borrow its sign-in, and
# without its local relay to the API.
function Clear-HostSession {
    $names = @(Get-ChildItem Env: | Where-Object {
        $_.Name -match '^(CLAUDE|MCP_)' -or ($_.Name -eq 'ANTHROPIC_BASE_URL' -and $_.Value -match '^https?://(127\.0\.0\.1|localhost|\[::1\])')
    } | ForEach-Object Name)
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $null, 'Process') }
}

# A scenario never writes to GitHub: gh runs only the commands that read (Claude Code itself reads
# « gh pr view » after a commit) and the ones preparer-pc.ps1 asks; any other call is refused and
# logged.
$GhAllowed = @('auth status', 'auth setup-git', 'api user', 'pr view', 'pr list', 'pr status', 'repo view', 'issue view', 'issue list')

function New-GhGuard([string]$Bin) {
    $real = "$((Get-Command gh -ErrorAction SilentlyContinue).Source)"
    New-Item -ItemType Directory -Force -Path $Bin | Out-Null
    $log = Join-Path $Bin 'gh-refus.log'
    $cmdChecks = ($GhAllowed | ForEach-Object { "if /i `"%~1 %~2`"==`"$_`" goto real" }) -join "`r`n"
    $cmd = "@echo off`r`nif /i `"%~1`"==`"--version`" goto real`r`n$cmdChecks`r`necho gh %* >>`"$log`"`r`necho gh est desactive pendant un scenario de test 1>&2`r`nexit /b 1`r`n:real`r`n`"$real`" %*`r`n"
    [IO.File]::WriteAllText((Join-Path $Bin 'gh.cmd'), $cmd)
    $shCases = ($GhAllowed | ForEach-Object { "`"$_`"" }) -join '|'
    $realSh = $real -replace '\\', '/'
    $sh = "#!/bin/sh`ncase `"`$1 `$2`" in $shCases) exec `"$realSh`" `"`$@`" ;; esac`ncase `"`$1`" in --version) exec `"$realSh`" `"`$@`" ;; esac`necho `"gh `$*`" >> `"$($log -replace '\\', '/')`"`necho 'gh est desactive pendant un scenario de test' >&2`nexit 1`n"
    [IO.File]::WriteAllText((Join-Path $Bin 'gh'), $sh)
    $log
}

# Nor pushes with git: for the sessions' git, every push to GitHub goes to an address that does not
# exist (variables of this process alone, nothing written to a git configuration).
function Block-GitPush {
    $rules = @('https://github.com/', 'git@github.com:', 'ssh://git@github.com/')
    $env:GIT_CONFIG_COUNT = "$($rules.Count)"
    for ($i = 0; $i -lt $rules.Count; $i++) {
        Set-Item "Env:GIT_CONFIG_KEY_$i" 'url.https://scenario.invalid/.pushInsteadOf'
        Set-Item "Env:GIT_CONFIG_VALUE_$i" $rules[$i]
    }
}

# The guards are checked before any session, never assumed: a push to GitHub must be rewritten to
# nowhere, and gh must refuse a command off its list, through cmd (PowerShell, Claude Code) as
# through Git Bash. The probe asks « gh help », harmless if a guard failed.
function Test-Guards([string]$GhLog) {
    $probe = Join-Path $Work 'sonde-des-gardes'
    [void](Invoke-Git $Work @('init', '-q', $probe))
    [void](Invoke-Git $probe @('remote', 'add', 'origin', 'https://github.com/exemple/depot.git'))
    $push = "$((Invoke-Git $probe @('remote', 'get-url', '--push', 'origin')).Lignes)"
    Remove-Item -Recurse -Force -LiteralPath $probe
    if ($push -notmatch '^https://scenario\.invalid/') { throw "la garde de git push ne marche pas (adresse de push : $push)" }
    $ErrorActionPreference = 'Continue'
    & cmd.exe /d /c 'gh help' 2>&1 | Out-Null
    $bash = Join-Path $env:ProgramFiles 'Git\bin\bash.exe'
    if (Test-Path -LiteralPath $bash) { & $bash -c 'gh help' 2>&1 | Out-Null }
    $refused = @(Get-Content -LiteralPath $GhLog -ErrorAction SilentlyContinue)
    Remove-Item -LiteralPath $GhLog -ErrorAction SilentlyContinue
    $expected = if (Test-Path -LiteralPath $bash) { 2 } else { 1 }
    if ($refused.Count -ne $expected) { throw "la garde de gh ne refuse pas « gh help » ($($refused.Count) refus notés sur $expected)" }
}

function Invoke-Claude([string]$Claude, [string]$Dir, [string]$Request, [double]$Cap) {
    $arguments = @('-p', '--output-format', 'stream-json', '--verbose', '--model', $Modele,
        '--max-budget-usd', $Cap.ToString([Globalization.CultureInfo]::InvariantCulture),
        '--strict-mcp-config', '--no-session-persistence', '--permission-mode', 'acceptEdits',
        '--allowedTools', 'Bash', 'PowerShell', 'Read', 'Write', 'Edit', 'Glob', 'Grep', 'Skill',
        '--disallowedTools', 'Agent', 'Workflow', 'WebFetch', 'WebSearch')
    Push-Location -LiteralPath $Dir
    try {
        $ErrorActionPreference = 'Continue'
        $lines = @($Request | & $Claude @arguments 2>&1 | ForEach-Object { "$_" })
    }
    finally { Pop-Location }
    Set-Text (Join-Path $Work ('flux-{0}.jsonl' -f (Split-Path -Leaf $Dir))) ($lines -join "`n")
    $lines
}

# What a session did, read from its stream: the skills, the commands, the files read, the final
# answer, the cost.
function Read-Session([string[]]$Lines) {
    $session = New-Session -Tours 0
    $session.Fin = 'aucune'
    foreach ($line in $Lines) {
        if (-not $line.StartsWith('{')) { continue }
        try { $event = $line | ConvertFrom-Json } catch { continue }
        if ($event.type -eq 'assistant') {
            foreach ($part in @($event.message.content)) {
                if ($part.type -ne 'tool_use') { continue }
                if ($part.name -eq 'Skill') { $session.Skills += "$($part.input.skill)" }
                if ($part.name -eq 'Read') { $session.Lectures += "$($part.input.file_path)" }
                if ($part.input.command) { $session.Commandes += "$($part.input.command)" }
            }
        }
        elseif ($event.type -eq 'result') {
            $session.Reponse = "$($event.result)"
            $session.Cout = [double]$event.total_cost_usd
            $session.Tours = [int]$event.num_turns
            $session.Fin = "$($event.subtype)"
            $session.Erreur = [bool]$event.is_error
            if ($event.permission_denials) { $session.Refus = @($event.permission_denials).Count }
        }
    }
    $session
}

# --- The run.

$files = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'scenarios') -File -Filter '*.ps1' | Sort-Object Name)
$wanted = @($Scenarios | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
if ($wanted.Count) { $files = @($files | Where-Object { $wanted -contains $_.BaseName }) }
if ($files.Count -eq 0) { throw 'aucun scénario à jouer' }
New-Item -ItemType Directory -Path $Work | Out-Null
$failures = 0

if ($ASec) {
    foreach ($file in $files) {
        $scenario = & $file.FullName
        $untouched = Join-Path $Work "$($file.BaseName)-vide"
        $ideal = Join-Path $Work "$($file.BaseName)-ideal"
        New-Item -ItemType Directory -Path $untouched, $ideal | Out-Null
        & $scenario.Preparer $untouched
        $empty = @(& $scenario.Verifier $untouched (New-Session))
        $red = @($empty | Where-Object { -not $_.Ok }).Count
        & $scenario.Preparer $ideal
        $missed = @(& $scenario.Verifier $ideal (& $scenario.Simuler $ideal) | Where-Object { -not $_.Ok } | ForEach-Object Texte)
        if ($red -eq 0) { $failures++; Write-Output "[échec] $($file.BaseName) : ses vérifications passent sur un dossier où rien n'a été fait" }
        if ($missed.Count) { $failures++; Write-Output "[échec] $($file.BaseName) : la session idéale échoue : $($missed -join ' ; ')" }
        if ($red -gt 0 -and $missed.Count -eq 0) { Write-Output "[ok] $($file.BaseName) : $red vérification(s) sur $($empty.Count) échouent à vide, toutes passent sur la session idéale" }
    }
}
else {
    $claude = Find-Claude
    Clear-HostSession
    Block-GitPush
    $ghLog = New-GhGuard (Join-Path $Work 'bin')
    $env:PATH = (Join-Path $Work 'bin') + ';' + $env:PATH
    Test-Guards $ghLog
    Write-Output "Claude Code : $claude ; modèle $Modele ; dossier $Work ; gardes de git et de gh vérifiées"
    $total = 0.0
    foreach ($file in $files) {
        $scenario = & $file.FullName
        $dir = Join-Path $Work $file.BaseName
        New-Item -ItemType Directory -Path $dir | Out-Null
        & $scenario.Preparer $dir
        $cap = if ($scenario.PlafondUsd) { [double]$scenario.PlafondUsd } else { $PlafondUsd }
        Write-Output ('--- {0} (plafond {1} $) : {2}' -f $file.BaseName, $cap, $scenario.Demande)
        $lines = Invoke-Claude $claude $dir $scenario.Demande $cap
        $session = Read-Session $lines
        $total += $session.Cout
        if ($session.Fin -eq 'aucune' -or ($session.Erreur -and $session.Cout -eq 0)) {
            $why = if ($session.Reponse) { $session.Reponse } else { ($lines | Select-Object -Last 3) -join ' ' }
            Write-Output "[arrêt] la session n'a pas démarré : $why"
            Write-Output "Claude Code doit être connecté une fois, dans un terminal : lancer « $claude », taper /login, puis relancer ce script."
            $failures++
            break
        }
        $refused = @(Get-Content -LiteralPath $ghLog -ErrorAction SilentlyContinue)
        $checks = @(& $scenario.Verifier $dir $session) + @(Test-Fait ($refused.Count -eq 0) "aucun appel à gh refusé $($refused -join ' ; ')")
        foreach ($check in $checks) {
            if ($check.Ok) { Write-Output "[ok] $($check.Texte)" } else { $failures++; Write-Output "[échec] $($check.Texte)" }
        }
        Write-Output ('coût {0:N2} $, {1} tours, fin : {2}, refus de permission : {3}' -f $session.Cout, $session.Tours, $session.Fin, $session.Refus)
        if (Test-Path -LiteralPath $ghLog) { Remove-Item -LiteralPath $ghLog }
    }
    Write-Output ('Coût total : {0:N2} $' -f $total)
}

if ($failures -eq 0 -and -not $Garder) {
    Remove-Item -Recurse -Force -LiteralPath $Work
    # The sessions' default memory folders, named after their folders, go with them.
    $projects = Join-Path $HOME '.claude\projects'
    Get-ChildItem -LiteralPath $projects -Directory -Filter ('*' + (Split-Path -Leaf $Work) + '*') -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}
else { Write-Output "Les dossiers des scénarios et les flux des sessions sont gardés dans $Work" }
Write-Output ('{0} scénario(s), {1} échec(s)' -f $files.Count, $failures)
if ($failures -gt 0) { exit 1 }
exit 0
