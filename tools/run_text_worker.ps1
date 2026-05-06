param(
    [string]$File = "critical.md",
    [int]$ShardIndex = -1,
    [int]$ShardCount = -1,
    [int]$Start = -1,
    [int]$End = -1,
    [string]$Model = "sonnet",
    [int]$Attempts = 2,
    [int]$TimeoutSeconds = 900,
    [double]$SleepBetween = 2.0,
    [switch]$DryRun,
    [switch]$ListMaps
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCmd) {
    $runner = @("python")
} else {
    $pyCmd = Get-Command py -ErrorAction SilentlyContinue
    if (-not $pyCmd) {
        Write-Error "Neither python nor py was found on PATH."
        exit 1
    }
    $runner = @("py", "-3")
}

$argsList = @(
    (Join-Path $scriptDir "claude_cli_rewriter.py"),
    "--file", $File,
    "--model", $Model,
    "--attempts", "$Attempts",
    "--timeout-s", "$TimeoutSeconds",
    "--sleep-between", "$SleepBetween"
)

if ($DryRun) {
    $argsList += "--dry-run"
}

if ($ListMaps) {
    $argsList += "--list-maps"
}

if ($ShardIndex -ge 0 -and $ShardCount -gt 0) {
    $argsList += @("--shard-index", "$ShardIndex", "--shard-count", "$ShardCount")
} else {
    if ($Start -ge 0) {
        $argsList += @("--start", "$Start")
    }
    if ($End -ge 0) {
        $argsList += @("--end", "$End")
    }
}

Push-Location $repoRoot
try {
    if ($runner.Length -eq 1) {
        & $runner[0] @argsList
    } else {
        & $runner[0] $runner[1] @argsList
    }
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
