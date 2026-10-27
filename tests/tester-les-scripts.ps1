# The method's tests that need no Claude session, so no token: the skill itself, the scripts,
# the templates, the control, the hooks and the scenarios played dry, run on throwaway projects. The skill's pre-commit runs
# them before each of its commits. On a failure the throwaway folder is kept, and its path printed.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File tests/tester-les-scripts.ps1

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$OutputEncoding = New-Object Text.UTF8Encoding $false

$Skill = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Work = Join-Path ([IO.Path]::GetTempPath()) ('methode-projet-tests-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $Work | Out-Null
$script:Failures = 0

function Assert([bool]$Condition, [string]$Text) {
    if ($Condition) { Write-Host "[ok] $Text" }
    else { $script:Failures++; Write-Host "[échec] $Text" }
}

# Runs a PowerShell script in a child process, with an optional standard input.
function Invoke-Ps([string]$Script, [string[]]$Arguments = @(), [string]$InputText) {
    $ErrorActionPreference = 'Continue'
    $all = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Script) + $Arguments
    $output = if ($PSBoundParameters.ContainsKey('InputText')) { $InputText | & powershell.exe @all 2>&1 } else { & powershell.exe @all 2>&1 }
    [pscustomobject]@{ Code = $LASTEXITCODE; Text = ($output | Out-String) }
}

function Invoke-Git([string]$Dir, [string[]]$Arguments) {
    $ErrorActionPreference = 'Continue'
    $output = & git -C $Dir -c user.name=Test -c user.email=test@example.com @Arguments 2>&1
    [pscustomobject]@{ Code = $LASTEXITCODE; Text = ($output | Out-String) }
}

function New-Project([string]$Folder, [string[]]$Arguments) {
    $dir = Join-Path $Work $Folder
    [pscustomobject]@{ Dir = $dir; Run = (Invoke-Ps (Join-Path $Skill 'preparer-projet.ps1') (@('-Chemin', $dir) + $Arguments)) }
}

function Read-Text([string]$Path) { [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8) }
function Get-Hash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash }
function Add-Line([string]$Path, [string]$Line) { [IO.File]::AppendAllText($Path, "`n$Line`n", (New-Object Text.UTF8Encoding $false)) }

Write-Host '--- Le skill'
$scripts = @(Get-ChildItem -LiteralPath $Skill -Recurse -File -Filter '*.ps1' | Where-Object { $_.FullName -notmatch '\\\.git\\' })
$broken = @(foreach ($file in $scripts) {
    $errors = $null
    [void][Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$null, [ref]$errors)
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    $bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    if ($errors.Count -gt 0 -or -not $bom) { $file.FullName.Substring($Skill.Length + 1) }
})
Assert ($broken.Count -eq 0) "les $($scripts.Count) scripts PowerShell s'analysent et commencent par un BOM UTF-8 $($broken -join ', ')"

$skillLines = @(Get-Content -LiteralPath (Join-Path $Skill 'SKILL.md') -Encoding UTF8)
$skillText = $skillLines -join "`n"
Assert ($skillLines.Count -lt 200) "SKILL.md : $($skillLines.Count) lignes, moins de 200"
Assert ($skillText -match '(?s)^---\nname: methode-projet\ndescription: ([^\n]+)\n---' -and $Matches[1].Length -le 1024) 'SKILL.md : un nom, et une description de 1 024 caractères au plus'
$cited = @([regex]::Matches($skillText, 'reference/([\w-]+\.md)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
$present = @(Get-ChildItem -LiteralPath (Join-Path $Skill 'reference') -File -Filter '*.md' | ForEach-Object Name)
Assert (@($cited | Where-Object { $present -notcontains $_ }).Count -eq 0) 'chaque fichier de reference/ que cite SKILL.md existe'
Assert (@($present | Where-Object { $cited -notcontains $_ }).Count -eq 0) "chaque fichier de reference/ est cité par SKILL.md ($($present.Count))"
$mute = @($present | Where-Object { -not (Select-String -LiteralPath (Join-Path $Skill "reference\$_") -Quiet -Encoding UTF8 -Pattern '^À lire') })
Assert ($mute.Count -eq 0) "chaque fichier de reference/ dit quand le lire $($mute -join ', ')"

$fullRoadmap = @(Get-Content -LiteralPath (Join-Path $Skill 'modeles\projet\docs\feuille-de-route.md') -Encoding UTF8)
$lightRoadmap = @(Get-Content -LiteralPath (Join-Path $Skill 'modeles\leger\docs\feuille-de-route.md') -Encoding UTF8)
$rules = @($lightRoadmap | Where-Object { $_ -match '^- (?!\[)' -or $_ -match '^Réécrit à la fin' })
$drifted = @($rules | Where-Object { $fullRoadmap -notcontains $_ })
Assert ($rules.Count -ge 5 -and $drifted.Count -eq 0) "la feuille de route légère reprend mot pour mot les $($rules.Count) règles de la complète"

Write-Host '--- preparer-projet.ps1'
$project = New-Project 'essai-complet' @('-Nom', 'Essai')
$d = $project.Dir
Assert ($project.Run.Code -eq 0) "un projet neuf se prépare (code $($project.Run.Code))"
$expected = @('CLAUDE.md', '.gitignore', '.gitattributes', '.githooks\pre-commit', '.claude\settings.json', '.claude\settings.local.json',
    '.claude\hooks\garde-methode.ps1', '.claude\hooks\garde-secrets.ps1', '.claude\hooks\garde-tests.ps1', '.claude\hooks\rappel-clear.ps1',
    '.claude\hooks\garde-generation-ia.ps1', '.claude\agents\leger.md', '.claude\agents\moyen.md', '.claude\agents\haut.md',
    'docs\README.md', 'docs\architecture.md', 'docs\feuille-de-route.md', 'docs\memoire\MEMORY.md', 'docs\memoire\project-essai.md')
$missing = @($expected | Where-Object { -not (Test-Path -LiteralPath (Join-Path $d $_)) })
Assert ($missing.Count -eq 0) "les $($expected.Count) fichiers attendus sont là $($missing -join ', ')"
Assert ((Read-Text (Join-Path $d 'CLAUDE.md')) -notmatch '@docs/memoire/MEMORY\.md') "CLAUDE.md n'importe pas MEMORY.md"
$agents = @('leger', 'moyen', 'haut' | ForEach-Object { Read-Text (Join-Path $d ".claude\agents\$_.md") })
Assert (@($agents | Where-Object { $_ -match '(?m)^effort:\s*(low|medium|high)\s*$' -and $_ -notmatch '\{\{' -and $_.Contains('projet Essai') }).Count -eq 3) "les trois types d'agents ont leur effort et le nom du projet"
$memoryDir = (Read-Text (Join-Path $d '.claude\settings.local.json') | ConvertFrom-Json).autoMemoryDirectory
Assert ($memoryDir -eq ((Join-Path $d 'docs\memoire') -replace '\\', '/')) 'la mémoire automatique écrit dans le docs/memoire du projet'
Assert ((Invoke-Git $d @('config', '--get', 'core.hooksPath')).Text.Trim() -eq '.githooks') 'les hooks git du projet sont actifs'
Assert ((Read-Text (Join-Path $d 'docs\feuille-de-route.md')) -match '## Phase 7') "la feuille de route complète va jusqu'à la phase 7"

$claudeHash = Get-Hash (Join-Path $d 'CLAUDE.md')
$rerun = Invoke-Ps (Join-Path $Skill 'preparer-projet.ps1') @('-Chemin', $d)
$sheets = @(Get-ChildItem -LiteralPath (Join-Path $d 'docs\memoire') -File -Filter 'project-*.md')
Assert ($rerun.Code -eq 0 -and $sheets.Count -eq 1) "relancé sans -Nom dans un dossier d'un autre nom, il garde une seule fiche projet ($($sheets.Count))"
Assert ((Get-Hash (Join-Path $d 'CLAUDE.md')) -eq $claudeHash) "relancé, il n'écrase rien"

$light = New-Project 'essai-leger' @('-Nom', 'Petit', '-Leger')
$lightText = Read-Text (Join-Path $light.Dir 'docs\feuille-de-route.md')
Assert ($light.Run.Code -eq 0 -and $lightText -match '## Phase 2 : livraison' -and $lightText -notmatch '## Phase 3') '-Leger donne la feuille de route en trois phases'
Assert ($light.Run.Text -notmatch 'déjà présent') "-Leger ne compte pas le modèle qu'il remplace comme déjà présent"

# As at the start of a project: « Où on en est » is dated before the first commit, which makes the
# control read the git history of a repository that has none yet.
$roadmapPath = Join-Path $d 'docs\feuille-de-route.md'
$roadmapText = (Read-Text $roadmapPath).Replace('{{DATE}} : {{CE QUI EST FINI}}. Prochaine session : {{ÉTAPE}}.', "$((Get-Date).ToString('yyyy-MM-dd')) : le démarrage est fait. Prochaine session : 0.2.")
[IO.File]::WriteAllText($roadmapPath, $roadmapText, (New-Object Text.UTF8Encoding $false))
Assert ($roadmapText -match '\d{4}-\d\d-\d\d : le démarrage est fait') '« Où on en est » daté avant le premier commit'
[void](Invoke-Git $d @('add', '-A'))
$commit = Invoke-Git $d @('commit', '-q', '-m', 'premier commit')
Assert ($commit.Code -eq 0) "un projet neuf se commite, hooks compris $(if ($commit.Code) { $commit.Text.Trim() })"

Write-Host '--- preparer-pc.ps1'
# Launched from inside a repository (a double click in the skill's folder does it), it leaves that
# repository as it was: git lfs install wrote its four hooks into .githooks. Played only on a PC
# where every tool is installed, so that the test never installs anything.
function Test-ToolsInstalled {
    $ErrorActionPreference = 'Continue'
    & git lfs version 2>&1 | Out-Null
    $LASTEXITCODE -eq 0 -and [bool](Get-Command gh -ErrorAction SilentlyContinue)
}
if (Test-ToolsInstalled) {
    $pcRepo = Join-Path $Work 'depot-pc'
    [void](Invoke-Git $Work @('init', '-q', $pcRepo))
    [void](Invoke-Git $pcRepo @('config', 'core.hooksPath', '.githooks'))
    New-Item -ItemType Directory -Path (Join-Path $pcRepo '.githooks') | Out-Null
    [IO.File]::WriteAllText((Join-Path $pcRepo '.githooks\pre-commit'), "#!/bin/sh`nexit 0`n")
    Push-Location -LiteralPath $pcRepo
    try { [void](Invoke-Ps (Join-Path $Skill 'preparer-pc.ps1')) }
    finally { Pop-Location }
    $pcHooks = @(Get-ChildItem -LiteralPath (Join-Path $pcRepo '.githooks') -Force | ForEach-Object Name)
    Assert ($pcHooks.Count -eq 1) "lancé depuis un dépôt, preparer-pc.ps1 n'y écrit rien $(if ($pcHooks.Count -ne 1) { $pcHooks -join ', ' })"
}
else { Write-Host "[ignoré] preparer-pc.ps1 : git-lfs ou gh manque sur ce PC, et ce test n'installe rien" }

Write-Host '--- controler-projet.ps1'
$control = Join-Path $Skill 'controler-projet.ps1'
$clean = Invoke-Ps $control @('-Chemin', $d)
Assert ($clean.Code -eq 0 -and $clean.Text -match '\b0 à corriger') "un projet neuf commité n'a rien à corriger"

$claudePath = Join-Path $d 'CLAUDE.md'
$memoryPath = Join-Path $d 'docs\memoire\MEMORY.md'
$settingsPath = Join-Path $d '.claude\settings.local.json'
$saved = @{}
foreach ($file in @($claudePath, $memoryPath, $settingsPath)) { $saved[$file] = [IO.File]::ReadAllBytes($file) }
function Restore-Project {
    foreach ($file in $saved.Keys) { [IO.File]::WriteAllBytes($file, $saved[$file]) }
    foreach ($extra in @('src', '.claude\rules', 'notes.txt')) { $path = Join-Path $d $extra; if (Test-Path -LiteralPath $path) { Remove-Item -Recurse -Force -LiteralPath $path } }
    [void](Invoke-Git $d @('config', 'core.hooksPath', '.githooks'))
}

# The thirty-second gesture, for the control: each defect put back alone must be caught.
$defects = @(
    @{ Name = 'CLAUDE.md importe MEMORY.md'; Expect = 'deux fois'; Break = { Add-Line $claudePath '@docs/memoire/MEMORY.md' } }
    @{ Name = 'CLAUDE.md dépasse le budget'; Expect = 'budget 200'; Break = { foreach ($i in 1..60) { Add-Line $claudePath "Ligne $i." } } }
    @{ Name = 'MEMORY.md dépasse ce que Claude Code charge'; Expect = 'le coupe'; Break = { [IO.File]::WriteAllLines($memoryPath, [string[]](1..210 | ForEach-Object { "- ligne $_" })) } }
    @{ Name = 'MEMORY.md renvoie vers une fiche absente'; Expect = "absente\.md, qui n'existe pas"; Break = { Add-Line $memoryPath '- [Absente](absente.md) — essai' } }
    @{ Name = "la mémoire n'écrit plus dans le projet"; Expect = 'autoMemoryDirectory'; Break = { Remove-Item -LiteralPath $settingsPath } }
    @{ Name = 'les hooks git ne sont plus actifs'; Expect = 'hooksPath'; Break = { [void](Invoke-Git $d @('config', '--unset', 'core.hooksPath')) } }
    @{ Name = 'du code sans outils/verifier.ps1'; Expect = 'verifier\.ps1'; Break = { New-Item -ItemType Directory -Path (Join-Path $d 'src') | Out-Null; [IO.File]::WriteAllText((Join-Path $d 'src\main.py'), "print('ok')`n") } }
    @{ Name = 'une règle renvoie vers un document absent'; Expect = 'règle essai\.md'; Break = { New-Item -ItemType Directory -Path (Join-Path $d '.claude\rules') | Out-Null; [IO.File]::WriteAllText((Join-Path $d '.claude\rules\essai.md'), "---`npaths:`n  - `"src/**`"`n---`n`nLis le sommaire de ``docs/absent/piege.md``.`n") } }
)
foreach ($defect in $defects) {
    & $defect.Break
    $run = Invoke-Ps $control @('-Chemin', $d)
    Assert ($run.Code -eq 1 -and $run.Text -match $defect.Expect) "défaut remis, le contrôle rougit : $($defect.Name)"
    Restore-Project
}
$restored = Invoke-Ps $control @('-Chemin', $d)
Assert ($restored.Code -eq 0) 'chaque défaut retiré, le contrôle redevient vert'

$advice = @(
    @{ Name = 'MEMORY.md de 70 lignes'; Expect = 'à surveiller\] MEMORY\.md'; Break = { [IO.File]::WriteAllLines($memoryPath, [string[]](1..70 | ForEach-Object { "- ligne $_" })) } }
    @{ Name = 'un fichier de travail à la racine'; Expect = 'hors de git : notes\.txt'; Break = { [IO.File]::WriteAllText((Join-Path $d 'notes.txt'), "brouillon`n") } }
)
foreach ($case in $advice) {
    & $case.Break
    $run = Invoke-Ps $control @('-Chemin', $d)
    Assert ($run.Code -eq 0 -and $run.Text -match $case.Expect) "un conseil ne bloque pas : $($case.Name)"
    Restore-Project
}

Write-Host '--- Les hooks'
$hooks = Join-Path $d '.claude\hooks'
$keyFile = Join-Path $d 'cle.txt'
[IO.File]::WriteAllText($keyFile, ('-----BEGIN ' + 'RSA PRIVATE KEY-----') + "`nabc`n")
[void](Invoke-Git $d @('add', 'cle.txt'))
$secrets = Invoke-Ps (Join-Path $hooks 'garde-secrets.ps1')
Assert ($secrets.Code -ne 0 -and $secrets.Text -match 'cle\.txt') 'garde-secrets bloque une clé privée indexée'
[void](Invoke-Git $d @('rm', '-q', '--cached', 'cle.txt'))
Remove-Item -LiteralPath $keyFile
Assert ((Invoke-Ps (Join-Path $hooks 'garde-secrets.ps1')).Code -eq 0) 'garde-secrets laisse passer sans secret'

$stop = Invoke-Ps (Join-Path $hooks 'garde-tests.ps1') @() '{"stop_hook_active":false}'
Assert ($stop.Code -eq 0 -and $stop.Text.Trim() -eq '') "garde-tests laisse finir tant que le projet n'a pas de verifier.ps1"

$generation = '{"tool_name":"mcp__essai__generate_image","tool_input":{"model":"flux-2-pro","prompt":"un chat"}}'
$refused = Invoke-Ps (Join-Path $hooks 'garde-generation-ia.ps1') @() $generation
Assert ($refused.Text -match '"permissionDecision":\s*"deny"') 'garde-generation-ia refuse un modèle sans fiche'
$guide = Join-Path $d 'docs\generation-ia\modeles\flux-2-pro.md'
[IO.File]::WriteAllText($guide, "# FLUX 2 Pro`n`nVérifiée le : $((Get-Date).ToString('yyyy-MM-dd'))`n", (New-Object Text.UTF8Encoding $false))
$allowed = Invoke-Ps (Join-Path $hooks 'garde-generation-ia.ps1') @() $generation
Assert ($allowed.Code -eq 0 -and $allowed.Text.Trim() -eq '') 'garde-generation-ia laisse passer un modèle à la fiche du jour'
Remove-Item -LiteralPath $guide

$stopInput = @{ session_id = 'essai-' + [guid]::NewGuid().ToString('N'); transcript_path = ''; cwd = $d } | ConvertTo-Json -Compress
Assert ((Invoke-Ps (Join-Path $hooks 'rappel-clear.ps1') @() $stopInput).Code -eq 0) 'rappel-clear passe sans transcript'

$installed = Join-Path $HOME '.claude\skills\methode-projet\controler-projet.ps1'
if ((Test-Path -LiteralPath $installed) -and (Get-Hash $installed) -eq (Get-Hash $control)) {
    Add-Line $claudePath '@docs/memoire/MEMORY.md'
    Assert ((Invoke-Ps (Join-Path $hooks 'garde-methode.ps1')).Code -eq 1) "garde-methode refuse le commit d'un projet qui ne suit plus la méthode"
    Restore-Project
    Assert ((Invoke-Ps (Join-Path $hooks 'garde-methode.ps1')).Code -eq 0) 'garde-methode laisse passer un projet en règle'
}
else { Write-Host "[ignoré] garde-methode : le skill installé sur ce PC n'est pas cette copie" }

Write-Host '--- Les scénarios, à sec'
$dry = Invoke-Ps (Join-Path $PSScriptRoot 'jouer-les-scenarios.ps1') @('-ASec')
Assert ($dry.Code -eq 0) "chaque scénario se prépare, ses vérifications échouent à vide et passent sur une session idéale $(if ($dry.Code) { $dry.Text.Trim() })"

if ($script:Failures -eq 0) {
    Remove-Item -Recurse -Force -LiteralPath $Work
    Write-Host 'Tout est vert.'
    exit 0
}
Write-Host "$($script:Failures) échec(s) ; les projets d'essai sont gardés dans $Work"
exit 1
