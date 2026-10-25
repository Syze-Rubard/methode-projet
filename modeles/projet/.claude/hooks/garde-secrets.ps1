# Git pre-commit hook: blocks a commit that would put a secret in the repository, private or not.
# Checks the names of the staged files (key files, .env) and their added lines (private keys,
# known token formats, passwords written in clear). Shows where, never the secret itself.
# A known false positive can carry the marker "garde-secrets: ignorer" on its line, with the
# user's agreement.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$IgnoreMarker = 'garde-secrets: ignorer'

# Files that hold keys or local secrets. Templates such as .env.example stay allowed.
$SecretFilePatterns = @(
    '(^|/)\.env(\.(?!(example|sample|template)$)[^/]+)?$'
    '\.(pem|key|pfx|p12|jks|keystore|ppk)$'
    '(^|/)id_(rsa|dsa|ecdsa|ed25519)$'
)

# Case-sensitive; the clear-text password rule turns case off for itself.
$SecretLinePatterns = [ordered]@{
    'clé privée'            = '-----BEGIN [A-Z ]*PRIVATE KEY'
    'jeton GitHub'          = '\b(gh[pousr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{60,})'
    'clé d''API sk-'        = '\bsk-[A-Za-z0-9_-]{20,}'
    'clé AWS'               = '\bAKIA[0-9A-Z]{16}\b'
    'clé Google'            = '\bAIza[0-9A-Za-z_-]{35}'
    'jeton Slack'           = '\bxox[abposr]-[A-Za-z0-9-]{10,}'
    'clé Stripe'            = '\b[rs]k_live_[A-Za-z0-9]{20,}'
    'mot de passe en clair' = '(?i)\b(password|passwd|pwd|mot_?de_?passe|secret|api_?key|access_?token|auth_?token|client_?secret)\b["'']?\s*[:=]\s*["''](?![$<{%])[^"''\s]{8,}["'']'
}

function Invoke-Git([string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    $output = git -C $ProjectDir -c core.quotepath=off @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') a échoué (code $LASTEXITCODE)" }
    $output
}

function Get-StagedFiles {
    Invoke-Git @('diff', '--cached', '--name-only', '--diff-filter=ACMR')
}

# Added lines of the staged changes, each with its file and line number.
function Get-AddedLines {
    $file = $null
    $number = 0
    $diff = Invoke-Git @('diff', '--cached', '--unified=0', '--no-color', '--no-ext-diff', '--no-textconv', '--diff-filter=ACMR')
    foreach ($text in $diff) {
        if ($text -match '^\+\+\+ (b/(.+)|/dev/null)$') { $file = $Matches[2]; continue }
        if ($text -match '^@@ -\S+ \+(\d+)') { $number = [int]$Matches[1]; continue }
        if ($text.StartsWith('+')) {
            [pscustomobject]@{ File = $file; Line = $number; Text = $text.Substring(1) }
            $number++
        }
    }
}

function Find-SecretFiles {
    foreach ($path in (Get-StagedFiles)) {
        foreach ($pattern in $SecretFilePatterns) {
            if ($path -match $pattern) { "$path : fichier de clé ou de secrets"; break }
        }
    }
}

function Find-SecretLines {
    foreach ($added in (Get-AddedLines)) {
        if ($added.Text.Contains($IgnoreMarker)) { continue }
        foreach ($name in $SecretLinePatterns.Keys) {
            if ($added.Text -cmatch $SecretLinePatterns[$name]) { "$($added.File):$($added.Line) : $name"; break }
        }
    }
}

$findings = @(Find-SecretFiles) + @(Find-SecretLines)
if ($findings.Count -eq 0) { exit 0 }
Write-Host 'Commit bloqué : il contiendrait un secret.'
$findings | ForEach-Object { Write-Host "  $_" }
Write-Host 'Retire le secret du commit et range-le dans un fichier ignoré par git. S''il a déjà quitté ce PC, révoque-le.'
exit 1
