# Stop hook: tells the user when it is a good time to /clear,
# either after a new commit or when the context gets heavy.
# Saved as UTF-8 with BOM so Windows PowerShell 5.1 reads the accents.

$FirstWarningTokens = 150000
$WarningStepTokens = 100000

function Read-HookInput {
    [Console]::InputEncoding = [Text.Encoding]::UTF8
    [Console]::In.ReadToEnd() | ConvertFrom-Json
}

function Get-ContextTokens([string]$TranscriptPath) {
    if (-not $TranscriptPath -or -not (Test-Path -LiteralPath $TranscriptPath)) { return 0 }
    $lines = @(Get-Content -LiteralPath $TranscriptPath -Tail 100 -Encoding UTF8)
    [array]::Reverse($lines)
    foreach ($line in $lines) {
        if ($line -notmatch '"usage"') { continue }
        $entry = $line | ConvertFrom-Json
        $usage = $entry.message.usage
        if ($entry.type -eq 'assistant' -and $usage -and -not $entry.isSidechain) {
            return [int]$usage.input_tokens + [int]$usage.cache_creation_input_tokens + [int]$usage.cache_read_input_tokens
        }
    }
    return 0
}

function Get-GitHead([string]$ProjectDir) {
    if (-not (Test-Path -LiteralPath (Join-Path $ProjectDir '.git'))) { return $null }
    $head = git -C $ProjectDir rev-parse --verify -q HEAD
    if ($LASTEXITCODE -ne 0) { return $null }
    return $head
}

function Get-StatePath([string]$SessionId) {
    $dir = Join-Path $env:TEMP 'claude-rappel-clear'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Join-Path $dir "$SessionId.json"
}

function Read-State([string]$Path) {
    if (Test-Path -LiteralPath $Path) { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
    return $null
}

function Write-State([string]$Path, $State) {
    $State | ConvertTo-Json -Compress | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-WarningLevel([int]$Tokens) {
    if ($Tokens -lt $FirstWarningTokens) { return 0 }
    return 1 + [math]::Floor(($Tokens - $FirstWarningTokens) / $WarningStepTokens)
}

function Write-UserMessage([string[]]$Messages) {
    if ($Messages.Count -eq 0) { return }
    [Console]::OutputEncoding = [Text.Encoding]::UTF8
    @{ systemMessage = ($Messages -join ' ') } | ConvertTo-Json -Compress
}

$hook = Read-HookInput
$projectDir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $hook.cwd }
$statePath = Get-StatePath $hook.session_id
$previous = Read-State $statePath
$head = Get-GitHead $projectDir
$tokens = Get-ContextTokens $hook.transcript_path
$level = Get-WarningLevel $tokens
$previousLevel = if ($previous) { [int]$previous.level } else { 0 }

$messages = @()
if ($previous -and $head -and $head -ne $previous.head) {
    $messages += "Nouveau commit : si la fonctionnalité est finie et sa checklist faite, c'est le bon moment pour /clear."
}
if ($level -gt $previousLevel) {
    $messages += "Contexte à environ $([math]::Round($tokens / 1000)) k tokens : termine la fonctionnalité, commite, puis /clear pour repartir léger."
}

Write-State $statePath @{ head = $head; level = $level }
Write-UserMessage $messages
