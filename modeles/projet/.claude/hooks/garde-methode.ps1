# Before each commit, checks that the project still follows the method: the controler-projet.ps1
# script of the methode-projet skill (the budget of what every session loads, the memory, the
# hooks, the map). Skipped where the skill is not installed, as on a CI machine.
# Usage (from .githooks/pre-commit): powershell -NoProfile -ExecutionPolicy Bypass -File .claude/hooks/garde-methode.ps1

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$control = Join-Path $HOME '.claude\skills\methode-projet\controler-projet.ps1'
if (-not (Test-Path -LiteralPath $control)) { exit 0 }
$projectDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $control -Chemin $projectDir -Silencieux
if ($LASTEXITCODE -ne 0) {
    Write-Output 'Commit refusé : le projet ne suit plus la méthode. Corriger les lignes « à corriger » ci-dessus, jamais les contourner.'
    exit 1
}
exit 0
