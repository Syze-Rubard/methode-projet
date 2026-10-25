# Guards the project against unverified code. outils/verifier.ps1 runs every check of the
# project; this script remembers which state of the files passed it, and:
# - as a Claude Code Stop hook (no switch), sends Claude back to work while changed code is unverified;
# - with -AvantCommit (git pre-commit hook), runs the checks and blocks the commit when they fail;
# - with -Enregistrer (called by verifier.ps1 on success), records the current state as verified.
# Does nothing while the project has no outils/verifier.ps1.

param(
    [switch]$AvantCommit,
    [switch]$Enregistrer
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$VerifierPath = Join-Path $ProjectDir 'outils\verifier.ps1'

# Top-level entries left out of the fingerprint: editing them never breaks the code.
$IgnoredEntryPattern = "`t(docs|[^/]+\.md)$"

function Invoke-Git([string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    $output = git -C $ProjectDir @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') a échoué (code $LASTEXITCODE)" }
    $output
}

function Get-Sha256([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
    -join ($hash | ForEach-Object { $_.ToString('x2') })
}

function Get-TreeFingerprint([string]$Tree) {
    $entries = Invoke-Git @('ls-tree', $Tree) | Where-Object { $_ -notmatch $IgnoredEntryPattern }
    Get-Sha256 ($entries -join "`n")
}

# Tree of the working folder as it is now, built in a copy of the index so the real one is untouched.
function Get-WorkingTree {
    $gitDir = Invoke-Git @('rev-parse', '--absolute-git-dir')
    $tempIndex = Join-Path $env:TEMP ("garde-tests-{0}.index" -f [guid]::NewGuid())
    $realIndex = Join-Path $gitDir 'index'
    if (Test-Path -LiteralPath $realIndex) { Copy-Item -LiteralPath $realIndex -Destination $tempIndex }
    $env:GIT_INDEX_FILE = $tempIndex
    try {
        Invoke-Git @('add', '--all') | Out-Null
        Invoke-Git @('write-tree')
    }
    finally {
        Remove-Item Env:\GIT_INDEX_FILE
        Remove-Item -LiteralPath $tempIndex -ErrorAction SilentlyContinue
    }
}

function Get-HeadFingerprint {
    $ErrorActionPreference = 'Continue'
    git -C $ProjectDir rev-parse --verify -q HEAD 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { return $null }
    Get-TreeFingerprint 'HEAD'
}

function Get-StampPath {
    Join-Path (Invoke-Git @('rev-parse', '--absolute-git-dir')) 'garde-tests.txt'
}

function Read-VerifiedFingerprint {
    $stampPath = Get-StampPath
    if (Test-Path -LiteralPath $stampPath) { return (Get-Content -Raw -LiteralPath $stampPath).Trim() }
    $null
}

# Committed code went through the pre-commit check, so it counts as verified too.
function Test-Verified([string]$Fingerprint) {
    ($Fingerprint -eq (Read-VerifiedFingerprint)) -or ($Fingerprint -eq (Get-HeadFingerprint))
}

function Save-Verified {
    Set-Content -LiteralPath (Get-StampPath) -Value (Get-TreeFingerprint (Get-WorkingTree)) -Encoding ASCII
}

# Returns the exit code for git; messages go to the host so they never mix with it.
function Invoke-PreCommit {
    if (-not (Test-Path -LiteralPath $VerifierPath)) { return 0 }
    if (Test-Verified (Get-TreeFingerprint (Get-WorkingTree))) { return 0 }
    Write-Host 'Vérification du projet avant le commit...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $VerifierPath | Out-Host
    if ($LASTEXITCODE -eq 0) { return 0 }
    Write-Host 'Commit bloqué : la vérification a échoué. Corrige le problème, puis recommite.'
    1
}

function Invoke-StopGuard {
    $hookInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
    # Claude was already sent back once this turn: let it stop and tell the user what blocks.
    if ($hookInput.stop_hook_active) { return }
    if (-not (Test-Path -LiteralPath $VerifierPath)) { return }
    if (Test-Verified (Get-TreeFingerprint (Get-WorkingTree))) { return }
    $reason = 'Le code a changé depuis la dernière vérification réussie. Lance outils/verifier.ps1 et corrige tout ce qui casse avant de finir. Si la vérification ne peut pas tourner, explique pourquoi à l''utilisateur.'
    @{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress | Write-Output
}

if ($Enregistrer) { Save-Verified; return }
if ($AvantCommit) { exit (Invoke-PreCommit) }
Invoke-StopGuard
