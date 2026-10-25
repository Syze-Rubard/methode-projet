# Claude Code PreToolUse hook: before a tool generates an image, a video, a 3D model or a sound,
# checks that the project holds an up-to-date guide on how to prompt the model it calls:
# docs/generation-ia/modeles/<model>.md, dated by its "Vérifiée le : YYYY-MM-DD" line.
# A missing or stale guide refuses the call and tells Claude to research the model first.
# Cost estimates, resumed jobs and tools that generate no media go through.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# Models change fast: past this age, a guide is checked again against the official docs.
$MaxAgeDays = 60

$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$GuidesDir = Join-Path $ProjectDir 'docs\generation-ia\modeles'
$StylePath = Join-Path $ProjectDir 'docs\generation-ia\style.md'

# Input fields that name the model; a provider left on "auto" names none.
$ModelFields = @('model', 'model_id', 'provider')
# Without a model field, a tool counts as a media generator only if its name says so.
$MediaToolPattern = 'image|video|audio|3d|speech|music|sound|voice|influencer|scene|outpaint|inpaint|motion'

# Values of the named fields, at any depth. Some tools take their params as a JSON string.
function Get-FieldValues($Value, [string[]]$Names) {
    if ($null -eq $Value) { return }
    if ($Value -is [string]) {
        if ($Value.TrimStart() -match '^[\[{]') {
            try { Get-FieldValues ($Value | ConvertFrom-Json) $Names } catch { }
        }
        return
    }
    if ($Value -is [Array]) {
        foreach ($item in $Value) { Get-FieldValues $item $Names }
        return
    }
    if ($Value -isnot [Management.Automation.PSCustomObject]) { return }
    foreach ($property in $Value.PSObject.Properties) {
        if ($Names -contains $property.Name) { $property.Value }
        else { Get-FieldValues $property.Value $Names }
    }
}

function Get-ModelKeys($ToolName, $ToolInput) {
    $models = @(Get-FieldValues $ToolInput $ModelFields |
        Where-Object { $_ -is [string] -and $_ -and $_ -ne 'auto' } | Select-Object -Unique)
    if ($models.Count -gt 0) { return $models }
    # No model named: the guide is the tool's, e.g. blender-generate-3d.md.
    # A server id that is a random code stays out of the name.
    $parts = $ToolName -split '__'
    $shortName = $parts[-1]
    if ($shortName -notmatch $MediaToolPattern) { return @() }
    if ($parts.Count -ge 3 -and $parts[1] -notmatch '^[0-9a-f]{8}-') { return @("$($parts[1])-$shortName") }
    @($shortName)
}

function Get-GuideFileName([string]$Model) {
    (($Model.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')) + '.md'
}

# Returns why the guide of this model is not good enough, or nothing when it is.
function Get-GuideProblem([string]$Model) {
    $relative = "docs/generation-ia/modeles/$(Get-GuideFileName $Model)"
    $path = Join-Path $GuidesDir (Get-GuideFileName $Model)
    if (-not (Test-Path -LiteralPath $path)) { return "la fiche du modèle « $Model » n'existe pas ($relative)" }
    $text = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
    if ($text -notmatch '(?m)^V\S*rifi\S*e le\s*:\s*(\d{4}-\d{2}-\d{2})') {
        return "la fiche $relative n'a pas de ligne « Vérifiée le : AAAA-MM-JJ »"
    }
    $checked = [datetime]::MinValue
    if (-not [datetime]::TryParseExact($Matches[1], 'yyyy-MM-dd', $null, 'None', [ref]$checked)) {
        return "la fiche $relative a une date « Vérifiée le » qui n'existe pas ($($Matches[1]))"
    }
    $age = ((Get-Date).Date - $checked).Days
    if ($age -gt $MaxAgeDays) { return "la fiche $relative a été vérifiée il y a $age jours (plus de $MaxAgeDays)" }
}

function Get-Refusal([string[]]$Problems) {
    $reason = "Génération refusée : $($Problems -join ' ; ').`n" +
        "Avant de générer :`n" +
        "1. Renseigne-toi sur ce modèle (recherche web, puis lecture des pages) : d'abord les guides officiels de son éditeur, puis ceux de la communauté (Reddit, Discord, tutoriels de créateurs reconnus), qui ont souvent les meilleures astuces. Cherche la forme de prompt qu'il préfère, ses forces et faiblesses, ses paramètres, le rôle des images de référence.`n" +
        "2. Écris ou mets à jour sa fiche d'après docs/generation-ia/modeles/_modele.md, avec la date du jour sur la ligne « Vérifiée le » et les sources lues, officielles et communautaires.`n" +
        "3. Écris le prompt selon cette fiche et docs/generation-ia/style.md, puis relance la génération.`n" +
        "Méthode complète : section « Génération par IA » du skill methode-projet."
    $styleWritten = (Test-Path -LiteralPath $StylePath) -and
        -not ([IO.File]::ReadAllText($StylePath, [Text.Encoding]::UTF8).Contains('<bloc de style>'))
    if (-not $styleWritten) {
        $reason += "`nLa bible de style docs/generation-ia/style.md n'est pas encore écrite : pour des contenus cohérents, propose à l'utilisateur de l'écrire avant la première génération destinée au produit."
    }
    $reason
}

try {
    $hookInput = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $toolInput = $hookInput.tool_input
    if (@(Get-FieldValues $toolInput @('get_cost')) -contains $true) { exit 0 }
    if (@(Get-FieldValues $toolInput @('job') | Where-Object { $_ }).Count -gt 0) { exit 0 }

    $problems = @(Get-ModelKeys $hookInput.tool_name $toolInput | ForEach-Object { Get-GuideProblem $_ } | Where-Object { $_ })
    if ($problems.Count -eq 0) { exit 0 }

    $decision = @{ hookEventName = 'PreToolUse'; permissionDecision = 'deny'; permissionDecisionReason = (Get-Refusal $problems) }
    @{ hookSpecificOutput = $decision } | ConvertTo-Json -Compress -Depth 4 | Write-Output
}
catch {
    # Never block on a bug of this hook, but say it loud.
    @{ systemMessage = "garde-generation-ia : $($_.Exception.Message). La génération n'a pas été vérifiée." } |
        ConvertTo-Json -Compress | Write-Output
}
