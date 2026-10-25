# Links this skill into ~/.claude/skills so every Claude Code project on this PC can use it.
# Run once per PC: powershell -ExecutionPolicy Bypass -File install.ps1

$skillsDir = Join-Path $HOME '.claude\skills'
$link = Join-Path $skillsDir 'methode-projet'

New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null
if (Test-Path -LiteralPath $link) {
    Write-Output "Already installed: $link"
    return
}
New-Item -ItemType Junction -Path $link -Target $PSScriptRoot | Out-Null
Write-Output "Installed: $link -> $PSScriptRoot"
