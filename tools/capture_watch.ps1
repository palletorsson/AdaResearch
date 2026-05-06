# capture_watch.ps1 — File watcher that auto-captures when scenes change
#
# Watches .tscn and .gd files for changes and automatically runs
# perfect_shot on the affected artifact. Zero tokens, zero humans.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools/capture_watch.ps1
#   # Leave it running — it captures automatically when you save files

param(
    [string]$GodotExe = "C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe",
    [string]$ProjectPath = $PSScriptRoot + "\..",
    [int]$Debounce = 5  # seconds to wait before capturing (prevents rapid re-fires)
)

$ProjectPath = (Resolve-Path $ProjectPath).Path
$RegistryDir = Join-Path $ProjectPath "commons\artifacts\registry"

Write-Host "=== Perfect Shot File Watcher ===" -ForegroundColor Cyan
Write-Host "Watching: $ProjectPath"
Write-Host "Debounce: ${Debounce}s"
Write-Host "Press Ctrl+C to stop`n"

# Build reverse lookup: scene_path -> lookup_name
$sceneLookup = @{}
$registryFiles = Get-ChildItem $RegistryDir -Filter "*.json"
foreach ($file in $registryFiles) {
    $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
    $artifacts = $json.artifacts
    if (-not $artifacts) { continue }
    foreach ($prop in $artifacts.PSObject.Properties) {
        $scene = $prop.Value.scene
        if ($scene) {
            # Convert res:// to filesystem path
            $fsPath = $scene -replace "^res://", (Join-Path $ProjectPath "")
            $fsPath = $fsPath -replace "/", "\"
            $sceneLookup[$fsPath] = $prop.Name
        }
    }
}
Write-Host "Indexed $($sceneLookup.Count) artifact scene paths"

# Track last capture time per target
$lastCapture = @{}

# Set up file watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $ProjectPath
$watcher.IncludeSubdirectories = $true
$watcher.Filter = "*.*"
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $ext = [System.IO.Path]::GetExtension($path)

    if ($ext -notin ".tscn", ".gd") { return }

    # Check if this file matches a registered artifact
    $lookupName = $null

    # Direct .tscn match
    if ($sceneLookup.ContainsKey($path)) {
        $lookupName = $sceneLookup[$path]
    }

    # .gd file — check if corresponding .tscn is registered
    if (-not $lookupName -and $ext -eq ".gd") {
        $tscnPath = $path -replace "\.gd$", ".tscn"
        if ($sceneLookup.ContainsKey($tscnPath)) {
            $lookupName = $sceneLookup[$tscnPath]
        }
    }

    if (-not $lookupName) { return }

    # Debounce
    $now = Get-Date
    if ($lastCapture.ContainsKey($lookupName)) {
        $elapsed = ($now - $lastCapture[$lookupName]).TotalSeconds
        if ($elapsed -lt $Debounce) { return }
    }
    $lastCapture[$lookupName] = $now

    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Changed: $lookupName" -ForegroundColor Yellow
    Write-Host "  File: $path"

    # Run perfect_shot
    $args = @(
        "--path", "`"$($ProjectPath)`"",
        "--xr-mode", "off",
        "--no-window",
        "--script", "res://commons/testing/perfect_shot.gd",
        "--",
        "--mode=artifact",
        "--target=$lookupName",
        "--hero-only",
        "--wait=1.5",
        "--settle=0.2"
    )

    Start-Process -FilePath $GodotExe -ArgumentList $args -NoNewWindow -Wait
    Write-Host "  Captured: $lookupName" -ForegroundColor Green
}

Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null
$watcher.EnableRaisingEvents = $true

Write-Host "Watching for changes... (Ctrl+C to stop)" -ForegroundColor Green

# Keep running
try {
    while ($true) { Start-Sleep -Seconds 1 }
} finally {
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Write-Host "`nWatcher stopped."
}
