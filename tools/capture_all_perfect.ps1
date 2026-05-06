# capture_all_perfect.ps1 — Zero-token automated capture pipeline
#
# Reads all artifacts from the registry, generates a batch targets file,
# runs perfect_shot in batch mode, and syncs results to the encyclopedia.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools/capture_all_perfect.ps1
#   powershell -ExecutionPolicy Bypass -File tools/capture_all_perfect.ps1 -Sequence forces
#   powershell -ExecutionPolicy Bypass -File tools/capture_all_perfect.ps1 -HeroOnly
#   powershell -ExecutionPolicy Bypass -File tools/capture_all_perfect.ps1 -Mode critters

param(
    [string]$Sequence = "",          # Filter to one sequence (e.g. "forces")
    [switch]$HeroOnly,               # Only capture hero angle (fast mode)
    [string]$Mode = "all",           # "all", "artifacts", "critters", "changed"
    [string]$GodotExe = "C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe",
    [string]$ProjectPath = $PSScriptRoot + "\..",
    [string]$EncyclopediaPath = $PSScriptRoot + "\..\..\ada_encyclopedia"
)

$ErrorActionPreference = "Continue"
$ProjectPath = (Resolve-Path $ProjectPath).Path
$RegistryDir = Join-Path $ProjectPath "commons\artifacts\registry"
$SpecimensDir = Join-Path $env:APPDATA "Godot\app_userdata\Ada Research Zero One\pokemon_studio\specimens"
$OutputBase = "user://perfect_shots"
$BatchFile = Join-Path $env:TEMP "perfect_shot_batch.json"
$PublicCaptures = Join-Path $EncyclopediaPath "public\captures\perfect-shot"

Write-Host "=== Perfect Shot Batch Capture ===" -ForegroundColor Cyan
Write-Host "Project: $ProjectPath"
Write-Host "Mode: $Mode"
if ($Sequence) { Write-Host "Sequence filter: $Sequence" }
if ($HeroOnly) { Write-Host "Hero-only: yes" }

# ── Step 1: Build target list from registry ──────────────────────

$targets = @()

if ($Mode -eq "all" -or $Mode -eq "artifacts") {
    Write-Host "`nScanning artifact registry..." -ForegroundColor Yellow
    $registryFiles = Get-ChildItem $RegistryDir -Filter "*.json"

    foreach ($file in $registryFiles) {
        $json = Get-Content $file.FullName -Raw | ConvertFrom-Json
        $artifacts = $json.artifacts
        if (-not $artifacts) { continue }

        foreach ($prop in $artifacts.PSObject.Properties) {
            $entry = $prop.Value
            $lookupName = $prop.Name
            $scenePath = $entry.scene

            # Skip if no scene
            if (-not $scenePath -or $scenePath -eq "") { continue }

            # Filter by sequence if specified
            if ($Sequence -and $entry.sequence -ne $Sequence) {
                # Also check map_sequences array
                $inSeq = $false
                if ($entry.map_sequences) {
                    foreach ($s in $entry.map_sequences) {
                        if ($s -eq $Sequence) { $inSeq = $true; break }
                    }
                }
                if (-not $inSeq) { continue }
            }

            $targets += @{
                mode = "artifact"
                target = $lookupName
            }
        }
    }
    Write-Host "  Found $($targets.Count) artifacts"
}

if ($Mode -eq "all" -or $Mode -eq "critters") {
    Write-Host "Scanning critter specimens..." -ForegroundColor Yellow
    if (Test-Path $SpecimensDir) {
        $dnaFiles = Get-ChildItem $SpecimensDir -Filter "*.json" -ErrorAction SilentlyContinue
        foreach ($dna in $dnaFiles) {
            $targets += @{
                mode = "critter"
                dna = $dna.FullName
                target = $dna.BaseName
            }
        }
        Write-Host "  Found $($dnaFiles.Count) specimens"
    } else {
        Write-Host "  No specimens directory found"
    }
}

if ($targets.Count -eq 0) {
    Write-Host "`nNo targets found. Nothing to capture." -ForegroundColor Red
    exit 0
}

Write-Host "`nTotal targets: $($targets.Count)" -ForegroundColor Green

# ── Step 2: Write batch file ──────────────────────────────────────

$batchJson = $targets | ConvertTo-Json -Depth 3
Set-Content -Path $BatchFile -Value $batchJson -Encoding UTF8
Write-Host "Batch file written: $BatchFile"

# ── Step 3: Run perfect_shot in batch mode ────────────────────────

Write-Host "`nRunning Godot perfect_shot..." -ForegroundColor Yellow

$godotArgs = @(
    "--path", "`"$ProjectPath`"",
    "--xr-mode", "off",
    "--no-window",
    "--script", "res://commons/testing/perfect_shot.gd",
    "--",
    "--mode=batch",
    "--targets=$BatchFile",
    "--out=$OutputBase"
)

if ($HeroOnly) {
    $godotArgs += "--hero-only"
}

$startTime = Get-Date
$process = Start-Process -FilePath $GodotExe -ArgumentList $godotArgs -NoNewWindow -Wait -PassThru
$elapsed = (Get-Date) - $startTime

Write-Host "Godot exited with code $($process.ExitCode) in $([math]::Round($elapsed.TotalSeconds, 1))s"

# ── Step 4: Sync to encyclopedia public dir ───────────────────────

$godotUserDir = Join-Path $env:APPDATA "Godot\app_userdata\Ada Research Zero One\perfect_shots"

if (Test-Path $godotUserDir) {
    Write-Host "`nSyncing captures to encyclopedia..." -ForegroundColor Yellow

    if (-not (Test-Path $PublicCaptures)) {
        New-Item -ItemType Directory -Path $PublicCaptures -Force | Out-Null
    }

    # Copy all capture folders
    $captureDirs = Get-ChildItem $godotUserDir -Directory -Recurse | Where-Object {
        (Get-ChildItem $_.FullName -Filter "*.png" -ErrorAction SilentlyContinue).Count -gt 0
    }

    $synced = 0
    foreach ($dir in $captureDirs) {
        $relativePath = $dir.FullName.Replace($godotUserDir, "").TrimStart("\")
        $destDir = Join-Path $PublicCaptures $relativePath

        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        $files = Get-ChildItem $dir.FullName -File | Where-Object { $_.Extension -in ".png", ".json" }
        foreach ($file in $files) {
            Copy-Item $file.FullName -Destination (Join-Path $destDir $file.Name) -Force
        }
        $synced++
    }

    Write-Host "  Synced $synced capture folders to $PublicCaptures"
} else {
    Write-Host "No captures found at $godotUserDir" -ForegroundColor Red
}

# ── Step 5: Summary ──────────────────────────────────────────────

$reportPath = Join-Path $godotUserDir "capture_report.json"
if (Test-Path $reportPath) {
    $report = Get-Content $reportPath -Raw | ConvertFrom-Json
    Write-Host "`n=== Capture Report ===" -ForegroundColor Cyan
    Write-Host "  Captured: $($report.captured)"
    Write-Host "  Failed: $($report.failed)"
    Write-Host "  Time: $([math]::Round($elapsed.TotalSeconds, 1))s"
}

Write-Host "`nDone. View at: http://localhost:3003/perfect-shot" -ForegroundColor Green

# Cleanup
Remove-Item $BatchFile -ErrorAction SilentlyContinue
