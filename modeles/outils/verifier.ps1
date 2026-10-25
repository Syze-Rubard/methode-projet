# Runs every check of the project, in order, and stops at the first failure.
# Exit code 0 only when all of them pass; then the state of the files is recorded as verified,
# so the guards (.claude/hooks/garde-tests.ps1) let Claude finish and git commit.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File outils/verifier.ps1

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

# The checks of this project, from the fastest to the slowest. Each Run block calls a command
# that fails with a non-zero exit code. Reports go to an ignored folder, never to tracked files.
# Example: @{ Name = 'Tests'; Run = { dotnet test "$ProjectDir\Tests" } }
$Checks = @(
)

function Invoke-Check($Check) {
    Write-Output "[vérification] $($Check.Name)"
    $global:LASTEXITCODE = 0
    & $Check.Run
    if ($LASTEXITCODE -ne 0) { throw "Échec : $($Check.Name) (code $LASTEXITCODE)" }
}

if ($Checks.Count -eq 0) { throw 'Aucune vérification définie dans outils/verifier.ps1.' }
foreach ($check in $Checks) { Invoke-Check $check }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ProjectDir '.claude\hooks\garde-tests.ps1') -Enregistrer
Write-Output 'Tout est vert.'
