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

# A small project, prepared the way the skill prepares one.
function New-PreparedProject([string]$Dir, [string]$Name) {
    $ErrorActionPreference = 'Continue'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Skill 'preparer-projet.ps1') -Chemin $Dir -Nom $Name -Leger 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "preparer-projet.ps1 a échoué sur $Dir" }
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
}

# The files changed since the starting state, committed or not, new ones included.
function Get-Changed([string]$Dir) {
    $tracked = (Invoke-Git $Dir @('diff', '--name-only', 'depart')).Lignes
    $new = (Invoke-Git $Dir @('ls-files', '--others', '--exclude-standard')).Lignes
    @(@($tracked) + @($new) | Where-Object { $_ } | Sort-Object -Unique)
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

# A scenario never creates a GitHub repository nor pushes: gh only answers « auth » and « --version »,
# which preparer-pc.ps1 asks, and logs every other call.
function New-GhGuard([string]$Bin) {
    $real = "$((Get-Command gh -ErrorAction SilentlyContinue).Source)"
    New-Item -ItemType Directory -Force -Path $Bin | Out-Null
    $log = Join-Path $Bin 'gh-refus.log'
    $cmd = "@echo off`r`nif /i `"%1`"==`"auth`" goto real`r`nif /i `"%1`"==`"--version`" goto real`r`necho gh %* >>`"$log`"`r`necho gh est desactive pendant un scenario de test 1>&2`r`nexit /b 1`r`n:real`r`n`"$real`" %*`r`n"
    [IO.File]::WriteAllText((Join-Path $Bin 'gh.cmd'), $cmd)
    $sh = "#!/bin/sh`ncase `"`$1`" in auth|--version) exec `"$($real -replace '\\', '/')`" `"`$@`" ;; esac`necho `"gh `$*`" >> `"$($log -replace '\\', '/')`"`necho 'gh est desactive pendant un scenario de test' >&2`nexit 1`n"
    [IO.File]::WriteAllText((Join-Path $Bin 'gh'), $sh)
    $log
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
    $ghLog = New-GhGuard (Join-Path $Work 'bin')
    $env:PATH = (Join-Path $Work 'bin') + ';' + $env:PATH
    Write-Output "Claude Code : $claude ; modèle $Modele ; dossier $Work"
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
