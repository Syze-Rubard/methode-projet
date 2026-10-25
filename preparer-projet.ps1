# Creates or completes a project that follows the methode-projet method.
# Never overwrites a file, so it is safe to rerun. On a new project it creates the whole
# structure; on an existing one (new PC, new drive letter) it only adds what is missing
# and points the Claude Code memory at docs/memoire.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File preparer-projet.ps1 -Chemin <dossier> [-Nom <nom>] [-Techno base|unity]

param(
    [string]$Chemin = (Get-Location).Path,
    [string]$Nom,
    [string]$Techno = 'base'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$ModelesDir = Join-Path $PSScriptRoot 'modeles'
$PlaceholderPattern = '\{\{[^}]+\}\}'

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

# Lists the template files with the path each one takes in the project.
function Get-Templates([string]$TechnoName, [string]$Name) {
    $roots = @((Join-Path $ModelesDir 'projet'), (Join-Path $ModelesDir "techno\$TechnoName"))
    foreach ($root in $roots) {
        foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -Force -File) {
            $relative = $file.FullName.Substring($root.Length + 1) -replace '\.modele\.', '.'
            [pscustomobject]@{ Source = $file.FullName; Target = Expand-Placeholders $relative $Name }
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

# autoMemoryDirectory is only read from the local settings, which git does not track,
# so every PC needs this file, with the path of the project on that PC.
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

function Initialize-Git([string]$ProjectDir) {
    if (Test-Path -LiteralPath (Join-Path $ProjectDir '.git')) { Write-Status 'ok' 'dépôt git déjà là' }
    else { Invoke-Git $ProjectDir @('init', '-b', 'main'); Write-Status 'créé' 'dépôt git (branche main)' }
    # Set before Git LFS, so LFS writes its hooks next to the versioned pre-commit hook.
    if (Test-Path -LiteralPath (Join-Path $ProjectDir '.githooks')) {
        Invoke-Git $ProjectDir @('config', 'core.hooksPath', '.githooks')
        Write-Status 'ok' 'hooks git du projet actifs (.githooks : vérification avant chaque commit)'
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
if (-not $Nom) { $Nom = Split-Path -Leaf $Chemin }

Write-Output "Projet $Nom dans $Chemin"
$templates = @(Get-Templates $Techno $Nom)
Add-MissingFiles $templates $Chemin $Nom
Set-MemoryDirectory $Chemin
Initialize-Git $Chemin
Show-BackupStatus $Chemin $Nom
Show-Placeholders $templates $Chemin
Write-Output 'Les hooks et la mémoire dans le projet prennent effet à la prochaine session de Claude Code.'
