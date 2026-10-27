# Checks that a project still follows the methode-projet method: the budget of what every
# session loads, the memory, the hooks, the map, the current state and the root. Reads only.
# Exit code 1 when something must be fixed ([à corriger]); [à surveiller] lines are advice.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File controler-projet.ps1 [-Chemin <dossier>] [-Silencieux]

param(
    [string]$Chemin = (Get-Location).Path,
    [switch]$Silencieux
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# The budgets of reference/grand-projet.md, part 1.
$BudgetLoaded = 200       # CLAUDE.md, its imports and the rules without paths:, in lines
$BudgetMemoryLines = 60   # MEMORY.md: about fifty lines, plus a margin
$LimitMemoryLines = 200   # beyond either limit, Claude Code cuts MEMORY.md at load
$LimitMemoryBytes = 25KB
$BudgetMapLines = 80      # docs/README.md, the map
$StaleStateDays = 7       # commits newer than the current state by more than this
$CodeExtensions = @('.cs', '.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.py', '.gd', '.c', '.h', '.cpp', '.hpp',
    '.rs', '.go', '.java', '.kt', '.swift', '.lua', '.dart', '.rb', '.php')

$script:ToFix = 0
$script:ToWatch = 0

# Status lines go to the host, so that functions can return values through the pipeline.
function Write-Status([string]$State, [string]$Text) {
    if ($State -eq 'à corriger') { $script:ToFix++ }
    elseif ($State -eq 'à surveiller') { $script:ToWatch++ }
    elseif ($Silencieux) { return }
    Write-Host ("[{0}] {1}" -f $State, $Text)
}

function Get-Lines([string]$Path) { @(Get-Content -LiteralPath $Path -Encoding UTF8) }

function Get-Git([string[]]$Arguments) {
    # Without Continue, PowerShell 5.1 stops at git's first message on stderr: « fatal: ... does
    # not have any commits yet » refused the first commit of every new project.
    $ErrorActionPreference = 'Continue'
    # quotePath=false: paths with accents come out as they are, not quoted in octal.
    $output = git -C $Chemin -c core.quotePath=false @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    $output
}

# The files a CLAUDE.md imports with @path, outside code, as Claude Code reads them: relative to
# the importing file, four hops at most, each file once.
function Get-Imports([string]$File, [int]$Depth, $Seen) {
    if ($Depth -gt 4) { return }
    $dir = Split-Path -Parent $File
    $inFence = $false
    foreach ($line in Get-Lines $File) {
        if ($line -match '^\s*```') { $inFence = -not $inFence; continue }
        if ($inFence) { continue }
        foreach ($m in [regex]::Matches(($line -replace '`[^`]*`', ''), '(?<![\w@])@([~\w./\\-]+)')) {
            $raw = $m.Groups[1].Value.TrimEnd('.')
            if ($raw -notmatch '[/\\.]') { continue }   # @someone, not a path
            $path = if ($raw.StartsWith('~/')) { Join-Path $HOME $raw.Substring(2) }
                    elseif ([IO.Path]::IsPathRooted($raw)) { $raw }
                    else { Join-Path $dir $raw }
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                Write-Status 'à surveiller' "$(Split-Path -Leaf $File) importe @$raw, qui n'existe pas"
                continue
            }
            $full = (Resolve-Path -LiteralPath $path).Path
            if (-not $Seen.Add($full)) { continue }
            $full
            Get-Imports $full ($Depth + 1) $Seen
        }
    }
}

function Test-HasPathsFrontmatter([string]$File) {
    $lines = Get-Lines $File
    if ($lines.Count -eq 0 -or $lines[0] -ne '---') { return $false }
    for ($i = 1; $i -lt $lines.Count -and $lines[$i] -ne '---'; $i++) { if ($lines[$i] -match '^paths\s*:') { return $true } }
    $false
}

function Get-Dates([string[]]$Lines) {
    foreach ($line in $Lines) {
        foreach ($m in [regex]::Matches($line, '\b(\d{4})-(\d{2})-(\d{2})\b')) {
            try { [datetime]::new([int]$m.Groups[1].Value, [int]$m.Groups[2].Value, [int]$m.Groups[3].Value) } catch { }
        }
        foreach ($m in [regex]::Matches($line, '\b(\d{1,2})/(\d{1,2})/(\d{4})\b')) {
            try { [datetime]::new([int]$m.Groups[3].Value, [int]$m.Groups[2].Value, [int]$m.Groups[1].Value) } catch { }
        }
    }
}

# --- What every session loads: CLAUDE.md, CLAUDE.local.md, their imports, the rules without paths:
function Test-LoadedBudget {
    $claudeMd = Join-Path $Chemin 'CLAUDE.md'
    if (-not (Test-Path -LiteralPath $claudeMd)) { Write-Status 'à corriger' "pas de CLAUDE.md : lancer preparer-projet.ps1"; return }
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $loaded = @($claudeMd)
    $local = Join-Path $Chemin 'CLAUDE.local.md'
    if (Test-Path -LiteralPath $local) { $loaded += $local }
    foreach ($file in @($loaded)) { [void]$seen.Add($file); $loaded += @(Get-Imports $file 1 $seen) }
    $rulesDir = Join-Path $Chemin '.claude\rules'
    if (Test-Path -LiteralPath $rulesDir) {
        $loaded += @(Get-ChildItem -LiteralPath $rulesDir -Recurse -File -Filter '*.md' | Where-Object { -not (Test-HasPathsFrontmatter $_.FullName) } | ForEach-Object FullName)
    }
    $total = 0
    foreach ($file in $loaded) { $total += (Get-Lines $file).Count }
    $names = ($loaded | ForEach-Object {
        if ($_.StartsWith($Chemin + '\', [StringComparison]::OrdinalIgnoreCase)) { $_.Substring($Chemin.Length + 1) -replace '\\', '/' } else { $_ }
    }) -join ', '
    if ($total -gt $BudgetLoaded) { Write-Status 'à corriger' "chargé à chaque session : $total lignes (budget $BudgetLoaded) dans $names ; le détail va dans un document lu à la demande, ou dans une règle à paths:" }
    else { Write-Status 'ok' "chargé à chaque session : $total lignes sur $BudgetLoaded ($names)" }
    if ($loaded | Where-Object { (Split-Path -Leaf $_) -eq 'MEMORY.md' }) {
        Write-Status 'à corriger' "CLAUDE.md importe MEMORY.md : la mémoire automatique le charge déjà, il l'est deux fois ; retirer l'import"
    }
    if (-not (Select-String -LiteralPath $claudeMd -Quiet -Encoding UTF8 -Pattern '(?i)compaction|conversation est résumée')) {
        Write-Status 'à surveiller' "CLAUDE.md ne dit pas quoi garder quand la conversation est résumée (section « Compaction » du modèle)"
    }
}

# --- The memory: where the automatic memory writes, and its index.
function Get-MemoryDirectory {
    $settingsPath = Join-Path $Chemin '.claude\settings.local.json'
    $configured = $null
    if (Test-Path -LiteralPath $settingsPath) {
        $configured = (Get-Content -Raw -Encoding UTF8 -LiteralPath $settingsPath | ConvertFrom-Json).autoMemoryDirectory
    }
    if (-not $configured) {
        Write-Status 'à corriger' "la mémoire automatique n'écrit pas dans le projet (pas d'autoMemoryDirectory dans .claude/settings.local.json) : lancer preparer-projet.ps1"
        return (Join-Path $Chemin 'docs\memoire')
    }
    $memoryDir = $configured -replace '/', '\'
    $inside = $memoryDir.StartsWith($Chemin + '\', [StringComparison]::OrdinalIgnoreCase)
    if (-not $inside -or -not (Test-Path -LiteralPath $memoryDir)) {
        Write-Status 'à corriger' "la mémoire automatique écrit dans $configured, hors du projet ou absent (le disque a changé de lettre ?) : relancer preparer-projet.ps1"
        return (Join-Path $Chemin 'docs\memoire')
    }
    Write-Status 'ok' "mémoire automatique dans $($memoryDir.Substring($Chemin.Length + 1) -replace '\\', '/')"
    $memoryDir
}

function Test-MemoryIndex([string]$MemoryDir) {
    $index = Join-Path $MemoryDir 'MEMORY.md'
    if (-not (Test-Path -LiteralPath $index)) { Write-Status 'à surveiller' "pas d'index de la mémoire (MEMORY.md)"; return }
    $lines = Get-Lines $index
    $bytes = (Get-Item -LiteralPath $index).Length
    if ($lines.Count -gt $LimitMemoryLines -or $bytes -gt $LimitMemoryBytes) {
        Write-Status 'à corriger' "MEMORY.md : $($lines.Count) lignes, $([math]::Round($bytes / 1KB)) Ko ; Claude Code le coupe au-delà de $LimitMemoryLines lignes ou 25 Ko, la fin n'est jamais lue"
    }
    elseif ($lines.Count -gt $BudgetMemoryLines) {
        Write-Status 'à surveiller' "MEMORY.md : $($lines.Count) lignes pour une cinquantaine ; garder ce qui sert à chaque session, le reste dans index-complet.md"
    }
    else { Write-Status 'ok' "MEMORY.md : $($lines.Count) ligne(s)" }
    $broken = foreach ($m in [regex]::Matches(($lines -join "`n"), '\]\(([^)#\s:]+\.md)\)')) {
        if (-not (Test-Path -LiteralPath (Join-Path $MemoryDir $m.Groups[1].Value))) { $m.Groups[1].Value }
    }
    foreach ($name in @($broken)) { Write-Status 'à corriger' "MEMORY.md renvoie vers $name, qui n'existe pas" }
}

# --- The hooks: the git pre-commit and the Claude Code hooks of the method.
function Test-Hooks {
    if (Test-Path -LiteralPath (Join-Path $Chemin '.githooks')) {
        if ((Get-Git @('config', '--get', 'core.hooksPath')) -eq '.githooks') { Write-Status 'ok' 'hooks git actifs (.githooks)' }
        else { Write-Status 'à corriger' "les hooks git de .githooks ne sont pas actifs : git config core.hooksPath .githooks (ou relancer preparer-projet.ps1)" }
    }
    else { Write-Status 'à surveiller' "pas de hooks git versionnés (.githooks) : rien ne vérifie avant un commit" }
    $settings = Join-Path $Chemin '.claude\settings.json'
    foreach ($hook in @('rappel-clear', 'garde-tests')) {
        if (-not ((Test-Path -LiteralPath $settings) -and (Select-String -LiteralPath $settings -Quiet -SimpleMatch -Pattern $hook))) {
            Write-Status 'à surveiller' "le hook $hook n'est pas déclaré dans .claude/settings.json"
        }
    }
}

# --- Code needs its single verification command.
function Test-Verifier($Tracked) {
    $code = @($Tracked | Where-Object { $_ -notmatch '^(\.claude|\.githooks|outils)/' -and $CodeExtensions -contains [IO.Path]::GetExtension($_).ToLowerInvariant() })
    if ($code.Count -eq 0) { Write-Status 'ok' "pas encore de code : outils/verifier.ps1 viendra avec le premier"; return }
    if (Test-Path -LiteralPath (Join-Path $Chemin 'outils\verifier.ps1')) { Write-Status 'ok' "$($code.Count) fichier(s) de code, et outils/verifier.ps1" }
    else { Write-Status 'à corriger' "$($code.Count) fichier(s) de code, mais pas de outils/verifier.ps1 : la commande unique qui vérifie tout (modèle dans le skill)" }
}

# --- The map lists every folder, and stays short.
function Test-Map($Tracked) {
    $map = Join-Path $Chemin 'docs\README.md'
    if (-not (Test-Path -LiteralPath $map)) { Write-Status 'à corriger' "pas de carte (docs/README.md)"; return }
    $lines = Get-Lines $map
    if ($lines.Count -gt $BudgetMapLines) { Write-Status 'à surveiller' "la carte fait $($lines.Count) lignes pour $BudgetMapLines au plus" }
    $text = $lines -join "`n"
    $folders = @($Tracked | Where-Object { $_ -match '/' } | ForEach-Object { $_.Split('/')[0] } | Sort-Object -Unique)
    $missing = @($folders | Where-Object { -not $text.Contains("$_/") })
    foreach ($folder in $missing) { Write-Status 'à surveiller' "la carte ne cite pas le dossier $folder/" }
    if ($missing.Count -eq 0) { Write-Status 'ok' "la carte cite les $($folders.Count) dossiers suivis par git" }
}

# --- The current state: dated, and rewritten since the last work.
function Test-CurrentState([string]$MemoryDir) {
    $state = Join-Path $MemoryDir 'etat-courant.md'
    $roadmap = Join-Path $Chemin 'docs\feuille-de-route.md'
    if (Test-Path -LiteralPath $state) { $source = 'etat-courant.md'; $lines = Get-Lines $state }
    elseif (Test-Path -LiteralPath $roadmap) {
        $source = '« Où on en est »'
        $all = Get-Lines $roadmap
        $start = [array]::FindIndex([string[]]$all, [Predicate[string]] { param($l) $l -match '^##\s+Où on en est' })
        if ($start -lt 0) { Write-Status 'à surveiller' "la feuille de route n'a pas de section « Où on en est »"; return }
        $end = [array]::FindIndex([string[]]$all, $start + 1, [Predicate[string]] { param($l) $l -match '^##\s' })
        if ($end -lt 0) { $end = $all.Count }
        $lines = $all[$start..($end - 1)]
        if (($lines -join "`n") -match '\{\{') { Write-Status 'à surveiller' "« Où on en est » n'est pas encore rempli"; return }
    }
    else { Write-Status 'à surveiller' "rien ne dit où on en est (ni « Où on en est » dans la feuille de route, ni etat-courant.md)"; return }
    $dates = @(Get-Dates $lines | Sort-Object)
    if ($dates.Count -eq 0) { Write-Status 'à surveiller' "$source ne porte pas de date"; return }
    $stateDate = $dates[-1]
    $lastCommit = Get-Git @('log', '-1', '--format=%cs')
    if ($lastCommit -and ([datetime]$lastCommit - $stateDate).TotalDays -gt $StaleStateDays) {
        Write-Status 'à surveiller' ("{0} date du {1:yyyy-MM-dd}, le dernier commit du {2} : à réécrire" -f $source, $stateDate, $lastCommit)
    }
    else { Write-Status 'ok' ("{0} daté du {1:yyyy-MM-dd}" -f $source, $stateDate) }
}

# --- The agent types, the path rules, and the root.
function Test-Agents {
    $agentsDir = Join-Path $Chemin '.claude\agents'
    $typed = @()
    if (Test-Path -LiteralPath $agentsDir) { $typed = @(Get-ChildItem -LiteralPath $agentsDir -File -Filter '*.md' | Where-Object { Select-String -LiteralPath $_.FullName -Quiet -Pattern '^effort\s*:' }) }
    if ($typed.Count -eq 0) { Write-Status 'à surveiller' "pas de type d'agent qui fixe son effort (.claude/agents/ : leger, moyen, haut dans le modèle)" }
    else { Write-Status 'ok' "$($typed.Count) type(s) d'agent avec leur effort" }
}

function Test-Rules {
    $rulesDir = Join-Path $Chemin '.claude\rules'
    if (-not (Test-Path -LiteralPath $rulesDir)) { return }
    foreach ($rule in Get-ChildItem -LiteralPath $rulesDir -Recurse -File -Filter '*.md') {
        foreach ($m in [regex]::Matches((Get-Content -Raw -Encoding UTF8 -LiteralPath $rule.FullName), '`([\w.-]+(?:/[\w.-]+)+\.md)`')) {
            if (-not (Test-Path -LiteralPath (Join-Path $Chemin $m.Groups[1].Value))) {
                Write-Status 'à corriger' "la règle $($rule.Name) renvoie vers $($m.Groups[1].Value), qui n'existe pas"
            }
        }
    }
}

function Test-Root {
    # Before the first commit every file is outside git: nothing is loose yet.
    if (-not (Get-Git @('rev-parse', '--verify', '--quiet', 'HEAD'))) { Write-Status 'à surveiller' "pas encore de premier commit"; return }
    $loose = @(Get-Git @('status', '--porcelain', '--untracked-files=normal') | Where-Object { $_ -match '^\?\? ("?)([^/"]+/?)\1$' } | ForEach-Object { $Matches[2] })
    foreach ($item in $loose) { Write-Status 'à surveiller' "à la racine, hors de git : $item (un fichier de travail va dans brouillons/)" }
    if ($loose.Count -eq 0) { Write-Status 'ok' 'racine rangée : rien qui traîne hors de git' }
}

$Chemin = (Resolve-Path -LiteralPath $Chemin).Path.TrimEnd('\')
if (-not $Silencieux) { Write-Host "Contrôle de la méthode dans $Chemin" }
$isRepo = [bool](Get-Git @('rev-parse', '--is-inside-work-tree'))
$tracked = @()
# The project's files: those git tracks, and the new ones it does not ignore.
if ($isRepo) { $tracked = @(Get-Git @('ls-files', '--cached', '--others', '--exclude-standard')) }
else { Write-Status 'à corriger' "pas de dépôt git : lancer preparer-projet.ps1" }

Test-LoadedBudget
$memoryDir = Get-MemoryDirectory
Test-MemoryIndex $memoryDir
if ($isRepo) { Test-Hooks; Test-Verifier $tracked; Test-Map $tracked; Test-Root }
Test-CurrentState $memoryDir
Test-Agents
Test-Rules

if (-not $Silencieux -or $script:ToFix + $script:ToWatch -gt 0) { Write-Host ("{0} à corriger, {1} à surveiller" -f $script:ToFix, $script:ToWatch) }
if ($script:ToFix -gt 0) { exit 1 }
exit 0
