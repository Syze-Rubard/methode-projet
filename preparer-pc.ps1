# Prepares a Windows PC for the methode-projet method: installs what winget can install,
# links the skill into Claude Code, and lists what the user must do by hand.
# Safe to rerun: each step checks first and only acts when something is missing.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File preparer-pc.ps1 [-NomGit "Prénom Nom"] [-EmailGit "adresse"]

param(
    [string]$NomGit,
    [string]$EmailGit
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$AutoCompactTokens = 300000
$script:TodoCount = 0

function Write-Status([string]$State, [string]$Text) {
    Write-Output ("[{0}] {1}" -f $State, $Text)
}

function Add-Todo([string]$Text) {
    $script:TodoCount++
    Write-Status 'à faire' $Text
}

function Test-Command([string]$Name) {
    [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# Runs a native command, hides its output and tells whether it succeeded.
function Invoke-Quiet([scriptblock]$Command) {
    $ErrorActionPreference = 'Continue'
    & $Command 2>&1 | Out-Null
    $LASTEXITCODE -eq 0
}

# Reloads PATH from the registry, so tools installed by this script are found right away.
function Update-SessionPath {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Install-WithWinget([string]$PackageId) {
    if (-not (Test-Command 'winget')) { return $false }
    $installed = Invoke-Quiet { winget install --id $PackageId --exact --silent --accept-package-agreements --accept-source-agreements }
    Update-SessionPath
    $installed
}

function Test-GitLfs {
    (Test-Command 'git') -and (Invoke-Quiet { git lfs version })
}

function Confirm-Tool([string]$Label, [scriptblock]$IsPresent, [string]$PackageId) {
    if (& $IsPresent) { Write-Status 'ok' $Label; return }
    Write-Status 'installation' "$Label avec winget (Windows peut demander d'autoriser)"
    if ((Install-WithWinget $PackageId) -and (& $IsPresent)) { Write-Status 'installé' $Label; return }
    Add-Todo "installer $Label : winget install --id $PackageId, ou depuis son site officiel"
}

function Enable-GitLfs {
    if (-not (Test-GitLfs)) { return }
    if (Invoke-Quiet { git lfs install }) { Write-Status 'ok' 'Git LFS activé pour cet utilisateur' }
    else { Add-Todo 'activer Git LFS : git lfs install' }
}

function Get-GlobalGitValue([string]$Key) {
    $ErrorActionPreference = 'Continue'
    git config --global --get $Key 2>$null
}

function Confirm-GitIdentity([string]$Name, [string]$Email) {
    if (-not (Test-Command 'git')) { return }
    if ($Name) { git config --global user.name $Name }
    if ($Email) { git config --global user.email $Email }
    $currentName = Get-GlobalGitValue 'user.name'
    $currentEmail = Get-GlobalGitValue 'user.email'
    if ($currentName -and $currentEmail) { Write-Status 'ok' "identité git : $currentName <$currentEmail>"; return }
    Add-Todo "identité git : donner à Claude un nom et un e-mail, il relance ce script avec -NomGit et -EmailGit"
}

function Confirm-GitHubLogin {
    if (-not (Test-Command 'gh')) { return }
    if (Invoke-Quiet { gh auth status }) { Write-Status 'ok' 'connecté à GitHub'; return }
    Add-Todo 'se connecter à GitHub : ouvrir un nouveau terminal, lancer gh auth login, puis répondre GitHub.com, HTTPS, Yes, Login with a web browser'
}

# Follows a junction to the folder it points to.
function Get-RealPath([string]$Path) {
    $item = Get-Item -LiteralPath $Path -Force
    if ($item.LinkType) { return (@($item.Target)[0]).TrimEnd('\') }
    $item.FullName.TrimEnd('\')
}

# A drive moved from another PC still belongs to that PC's account, and git refuses its
# repos ("dubious ownership") until they are listed in safe.directory.
function Confirm-SafeDirectory([string]$RepoDir) {
    if (-not (Test-Command 'git') -or -not (Test-Path -LiteralPath (Join-Path $RepoDir '.git'))) { return }
    $ErrorActionPreference = 'Continue'
    $output = git -C $RepoDir rev-parse --git-dir 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -or $output -notmatch 'safe\.directory') { return }
    git config --global --add safe.directory ($RepoDir -replace '\\', '/')
    Write-Status 'réglé' "git accepte le dépôt du skill venu d'un autre PC (safe.directory)"
}

function Confirm-SkillLink {
    $skillsDir = Join-Path $HOME '.claude\skills'
    $link = Join-Path $skillsDir 'methode-projet'
    $skillDir = Get-RealPath $PSScriptRoot
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing -and -not $existing.LinkType) {
        Add-Todo "un dossier $link existe déjà et n'est pas un lien vers ce skill : le renommer, puis relancer ce script"
        return
    }
    if ($existing -and ((Get-RealPath $link) -eq $skillDir)) { Write-Status 'ok' "skill relié à Claude Code ($link)"; return }
    # Non-recursive delete removes the junction itself, never the folder it points to.
    if ($existing) { [IO.Directory]::Delete($link) }
    New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null
    New-Item -ItemType Junction -Path $link -Target $skillDir | Out-Null
    Write-Status 'installé' "skill relié à Claude Code ($link -> $skillDir)"
}

function Get-AutoCompactValues {
    $settingsPath = Join-Path $HOME '.claude\settings.json'
    if (-not (Test-Path -LiteralPath $settingsPath)) { return }
    $settings = Get-Content -Raw -Encoding UTF8 -LiteralPath $settingsPath | ConvertFrom-Json
    if ($settings.autoCompactWindow) { $settings.autoCompactWindow }
    if ($settings.modelSettings) {
        foreach ($model in $settings.modelSettings.PSObject.Properties) {
            if ($model.Value.autoCompactWindow) { $model.Value.autoCompactWindow }
        }
    }
}

function Confirm-AutoCompact([int]$Tokens) {
    if (@(Get-AutoCompactValues) -contains $Tokens) { Write-Status 'ok' "compaction automatique à $($Tokens / 1000)k tokens"; return }
    Add-Todo "régler la compaction automatique : taper /autocompact $($Tokens / 1000)k dans Claude Code"
}

# Keeps the window open when a person runs the script by hand.
function Wait-IfRunByHand {
    if (-not [Console]::IsInputRedirected) { Read-Host 'Appuie sur Entrée pour fermer' | Out-Null }
}

Update-SessionPath
Confirm-Tool 'git' { Test-Command 'git' } 'Git.Git'
Confirm-Tool 'Git LFS' { Test-GitLfs } 'GitHub.GitLFS'
Enable-GitLfs
Confirm-Tool 'GitHub CLI' { Test-Command 'gh' } 'GitHub.cli'
Confirm-GitIdentity $NomGit $EmailGit
Confirm-GitHubLogin
Confirm-SkillLink
Confirm-SafeDirectory (Get-RealPath $PSScriptRoot)
Confirm-AutoCompact $AutoCompactTokens

if ($script:TodoCount -eq 0) { Write-Output 'PC prêt pour la méthode.' }
else { Write-Output "Encore $($script:TodoCount) chose(s) à faire, puis relancer ce script pour vérifier." }
Wait-IfRunByHand
