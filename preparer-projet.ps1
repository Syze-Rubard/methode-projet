# Creates or completes a project that follows the methode-projet method.
# Never overwrites a file, so it is safe to rerun. On a new project it creates the whole
# structure; on an existing one (new PC, new drive letter) it only adds what is missing
# and points the Claude Code memory at docs/memoire.
# -Leger: a small project (a tool, a library, a few weeks' trial) gets the light templates of
# modeles/leger, which take the place of those of modeles/projet: a roadmap in three phases.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File preparer-projet.ps1 -Chemin <dossier> [-Nom <nom>] [-Techno base|unity] [-Leger]

param(
    [string]$Chemin = (Get-Location).Path,
    [string]$Nom,
    [string]$Techno = 'base',
    [switch]$Leger
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$ModelesDir = Join-Path $PSScriptRoot 'modeles'
$PlaceholderPattern = '\{\{[^}]+\}\}'
$SheetTemplate = 'docs\memoire\project-{{nom}}.md'

function Write-Status([string]$State, [string]$Text) {
    Write-Output ("[{0}] {1}" -f $State, $Text)
}

function Get-Slug([string]$Text) {
    ($Text.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
}

# Fills the placeholders the script knows; the others are left for Claude.
function Expand-Placeholders([string]$Text, [string]$Name) {
    $Text.Replace('{{NOM}}', $Name).Replace('{{nom}}', (Get-Slug $Name))
}

function Test-Utf8Bom([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
}

function Write-Utf8File([string]$Path, [string]$Text, [bool]$WithBom) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding $WithBom))
}

function Assert-Techno([string]$Name) {
    if (Test-Path -LiteralPath (Join-Path $ModelesDir "techno\$Name")) { return }
    $available = (Get-ChildItem -Directory -LiteralPath (Join-Path $ModelesDir 'techno')).Name -join ', '
    throw "Techno inconnue : $Name. Disponibles : $available"
}

# The project sheets the memory already holds (docs\memoire\project-*.md).
function Get-ProjectSheets([string]$ProjectDir) {
    $memoryDir = Join-Path $ProjectDir 'docs\memoire'
    if (Test-Path -LiteralPath $memoryDir) { Get-ChildItem -LiteralPath $memoryDir -File -Filter 'project-*.md' | Sort-Object Name }
}

# Without -Nom, the name the project was created with, which its folder may not bear: the title
# of CLAUDE.md, else the slug of its project sheet when it has a single one, else the folder name.
function Find-ProjectName([string]$ProjectDir, $Sheets) {
    $claudeMd = Join-Path $ProjectDir 'CLAUDE.md'
    if (Test-Path -LiteralPath $claudeMd) {
        $title = Get-Content -LiteralPath $claudeMd -TotalCount 1 -Encoding UTF8
        if ($title -match '^#\s+(.+?)\s*:\s*instructions pour Claude\s*$') { return $Matches[1] }
    }
    if ($Sheets.Count -eq 1) { return $Sheets[0].BaseName.Substring('project-'.Length) }
    Split-Path -Leaf $ProjectDir
}

# A project has a single project sheet: when the memory already holds one under another name,
# the sheet template points to it, so that a rerun never adds a second one.
function Get-SheetTarget([string]$Expected, $Sheets) {
    if (-not $Sheets -or $Sheets.Name -contains (Split-Path -Leaf $Expected)) { return $Expected }
    Join-Path 'docs\memoire' $Sheets[0].Name
}

# Lists the template files with the path each one takes in the project. When two roots hold the
# same path, the first one wins: the light templates come before the common ones.
function Get-Templates([string]$TechnoName, [string]$Name, $Sheets, [bool]$Light) {
    $roots = @((Join-Path $ModelesDir 'projet'), (Join-Path $ModelesDir "techno\$TechnoName"))
    if ($Light) { $roots = @(Join-Path $ModelesDir 'leger') + $roots }
    $seen = @{}
    foreach ($root in $roots) {
        foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -Force -File) {
            $relative = $file.FullName.Substring($root.Length + 1) -replace '\.modele\.', '.'
            $target = Expand-Placeholders $relative $Name
            if ($relative -eq $SheetTemplate) { $target = Get-SheetTarget $target $Sheets }
            if ($seen.ContainsKey($target)) { continue }
            $seen[$target] = $true
            [pscustomobject]@{ Source = $file.FullName; Target = $target }
        }
    }
}

function Copy-Template([string]$Source, [string]$Destination, [string]$Name) {
    $text = Expand-Placeholders ([IO.File]::ReadAllText($Source, [Text.Encoding]::UTF8)) $Name
    Write-Utf8File $Destination $text (Test-Utf8Bom $Source)
}

function Add-MissingFiles($Templates, [string]$ProjectDir, [string]$Name) {
    $kept = 0
    foreach ($template in $Templates) {
        $destination = Join-Path $ProjectDir $template.Target
        if (Test-Path -LiteralPath $destination) { $kept++; continue }
        Copy-Template $template.Source $destination $Name
        Write-Status 'créé' $template.Target
    }
    if ($kept) { Write-Status 'ok' "$kept fichier(s) déjà présent(s), laissé(s) tels quels" }
}

# autoMemoryDirectory must be an absolute path, which differs from one PC to another
# (the disk letter changes), so it lives in the local settings, which git does not track.
function Set-MemoryDirectory([string]$ProjectDir) {
    $settingsPath = Join-Path $ProjectDir '.claude\settings.local.json'
    $memoryPath = (Join-Path $ProjectDir 'docs\memoire') -replace '\\', '/'
    $settings = $null
    if (Test-Path -LiteralPath $settingsPath) { $settings = Get-Content -Raw -Encoding UTF8 -LiteralPath $settingsPath | ConvertFrom-Json }
    if (-not $settings) { $settings = New-Object psobject }
    if ($settings.autoMemoryDirectory -eq $memoryPath) { Write-Status 'ok' "mémoire de Claude Code dans $memoryPath"; return }
    $settings | Add-Member -NotePropertyName autoMemoryDirectory -NotePropertyValue $memoryPath -Force
    Write-Utf8File $settingsPath (ConvertTo-Json -InputObject $settings -Depth 20) $false
    Write-Status 'réglé' "mémoire de Claude Code dans $memoryPath (.claude/settings.local.json)"
}

function Invoke-Git([string]$ProjectDir, [string[]]$Arguments) {
    git -C $ProjectDir @Arguments | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') a échoué (code $LASTEXITCODE)" }
}

# A drive moved from another PC still belongs to that PC's account, and git refuses its
# repos ("dubious ownership") until they are listed in safe.directory.
function Confirm-SafeDirectory([string]$RepoDir) {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoDir '.git'))) { return }
    $ErrorActionPreference = 'Continue'
    $output = git -C $RepoDir rev-parse --git-dir 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -or $output -notmatch 'safe\.directory') { return }
    git config --global --add safe.directory ($RepoDir -replace '\\', '/')
    Write-Status 'réglé' "git accepte ce dépôt venu d'un autre PC (safe.directory)"
}

function Initialize-Git([string]$ProjectDir) {
    Confirm-SafeDirectory $ProjectDir
    if (Test-Path -LiteralPath (Join-Path $ProjectDir '.git')) { Write-Status 'ok' 'dépôt git déjà là' }
    else { Invoke-Git $ProjectDir @('init', '-b', 'main'); Write-Status 'créé' 'dépôt git (branche main)' }
    # Set before Git LFS, so LFS writes its hooks next to the versioned pre-commit hook.
    if (Test-Path -LiteralPath (Join-Path $ProjectDir '.githooks')) {
        Invoke-Git $ProjectDir @('config', 'core.hooksPath', '.githooks')
        Write-Status 'ok' 'hooks git du projet actifs (.githooks : secrets et vérification avant chaque commit)'
    }
    $attributes = Join-Path $ProjectDir '.gitattributes'
    if ((Test-Path -LiteralPath $attributes) -and (Select-String -Quiet -LiteralPath $attributes -Pattern 'filter=lfs')) {
        Invoke-Git $ProjectDir @('lfs', 'install', '--local')
        Write-Status 'ok' 'Git LFS actif dans ce dépôt'
    }
}

function Show-BackupStatus([string]$ProjectDir, [string]$Name) {
    if (@(git -C $ProjectDir remote) -contains 'origin') { Write-Status 'ok' 'dépôt distant origin configuré'; return }
    $repoName = $Name -replace '[^A-Za-z0-9._-]+', '-'
    Write-Status 'à faire' "sauvegarde : après le premier commit, gh repo create $repoName --private --source . --push"
}

function Show-Placeholders($Templates, [string]$ProjectDir) {
    foreach ($template in $Templates) {
        $path = Join-Path $ProjectDir $template.Target
        foreach ($hit in Select-String -LiteralPath $path -Pattern $PlaceholderPattern -AllMatches -Encoding UTF8) {
            foreach ($match in $hit.Matches) {
                Write-Status 'à remplir' ("{0}:{1} {2}" -f $template.Target, $hit.LineNumber, $match.Value)
            }
        }
    }
}

Assert-Techno $Techno
New-Item -ItemType Directory -Force -Path $Chemin | Out-Null
$Chemin = (Resolve-Path -LiteralPath $Chemin).Path.TrimEnd('\')
$sheets = @(Get-ProjectSheets $Chemin)
if (-not $Nom) { $Nom = Find-ProjectName $Chemin $sheets }

Write-Output "Projet $Nom dans $Chemin"
$templates = @(Get-Templates $Techno $Nom $sheets $Leger.IsPresent)
Add-MissingFiles $templates $Chemin $Nom
Set-MemoryDirectory $Chemin
Initialize-Git $Chemin
Show-BackupStatus $Chemin $Nom
Show-Placeholders $templates $Chemin
Write-Output 'Les hooks et la mémoire dans le projet prennent effet à la prochaine session de Claude Code.'
