param(
    [string]$Host = "0.0.0.0",
    [int]$Port = 8766,
    [string]$Token = "",
    [string]$Model = "sonnet",
    [int]$TimeoutSeconds = 900
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
    (Join-Path $scriptDir "claude_http_server.py"),
    "--host", $Host,
    "--port", "$Port",
    "--repo-root", $repoRoot,
    "--model", $Model,
    "--timeout-s", "$TimeoutSeconds"
)

if ($Token) {
    $argsList += @("--token", $Token)
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
