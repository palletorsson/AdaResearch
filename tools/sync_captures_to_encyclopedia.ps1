#
# sync_captures_to_encyclopedia.ps1
#
# Copies Godot capture screenshots to the Ada Encyclopedia public folder
# and generates a JSON manifest of all available captures.
#
# Usage:
#   .\sync_captures_to_encyclopedia.ps1                    # normal sync
#   .\sync_captures_to_encyclopedia.ps1 -DryRun            # preview only
#   .\sync_captures_to_encyclopedia.ps1 -Force             # overwrite all
#   .\sync_captures_to_encyclopedia.ps1 -EncyclopediaPath "D:\other\path"
#

param(
    [string]$EncyclopediaPath = "C:\Users\palle\Documents\GitHub\ada_encyclopedia",
    [switch]$DryRun,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$GodotUserData = Join-Path $env:APPDATA "Godot\app_userdata\Ada Research Zero One"

# Source directories to scan. Each entry maps a source folder to a capture
# category ("artifacts" or "maps"). Files land under
#   public/captures/<category>/<name>/<angle>.png
$SourceDirs = @(
    @{ Path = Join-Path $GodotUserData "multi_shots";              Category = $null }   # auto-detect
    @{ Path = Join-Path $GodotUserData "capture_output\artifacts"; Category = "artifacts" }
    @{ Path = Join-Path $GodotUserData "capture_output\maps";      Category = "maps" }
)

$DestBase = Join-Path $EncyclopediaPath "public\captures"
$ManifestPath = Join-Path $DestBase "capture-manifest.json"

# Recognised angle filenames (without extension)
$KnownAngles = @("front", "left", "right", "top", "above", "back")

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------

$copied  = 0
$skipped = 0

# Manifest accumulators — keyed by name
$artifactEntries = @{}
$mapEntries      = @{}

# ---------------------------------------------------------------------------
# Helper: decide category for a name from multi_shots (heuristic)
# Map names are typically UPPER or Title_Case with underscores and digits,
# while artifact names are lowercase_with_underscores. We also check if
# the name already appeared in a known category folder.
# ---------------------------------------------------------------------------

function Guess-Category([string]$Name) {
    # If it looks like a map name (starts with uppercase, contains uppercase
    # letters after the first character, or matches common map prefixes)
    if ($Name -cmatch '^[A-Z]') {
        return "maps"
    }
    return "artifacts"
}

# ---------------------------------------------------------------------------
# Helper: sync a single source directory
# ---------------------------------------------------------------------------

function Sync-SourceDir([string]$SourcePath, [string]$FixedCategory) {
    if (-not (Test-Path $SourcePath)) {
        Write-Host "  [skip] Source not found: $SourcePath"
        return
    }

    # Each subdirectory is a capture target (artifact or map name)
    $subDirs = Get-ChildItem -Path $SourcePath -Directory

    foreach ($sub in $subDirs) {
        $name = $sub.Name

        # Determine category
        if ($FixedCategory) {
            $category = $FixedCategory
        } else {
            $category = Guess-Category $name
        }

        # Collect angle images
        $images = Get-ChildItem -Path $sub.FullName -File -Filter "*.png"

        foreach ($img in $images) {
            $angle = [System.IO.Path]::GetFileNameWithoutExtension($img.Name).ToLower()

            if ($KnownAngles -notcontains $angle) {
                # Still copy unknown angles; they just get included as-is
            }

            $destDir  = Join-Path $DestBase "$category\$name"
            $destFile = Join-Path $destDir $img.Name.ToLower()

            # Decide whether to copy
            $shouldCopy = $true

            if ((Test-Path $destFile) -and -not $Force) {
                $destInfo = Get-Item $destFile
                if ($destInfo.LastWriteTimeUtc -ge $img.LastWriteTimeUtc) {
                    # Destination is same age or newer — skip
                    $shouldCopy = $false
                }
            }

            if ($shouldCopy) {
                if ($DryRun) {
                    Write-Host "  [dry-run] $($img.FullName) -> $destFile"
                } else {
                    if (-not (Test-Path $destDir)) {
                        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    }
                    Copy-Item -Path $img.FullName -Destination $destFile -Force
                }
                $script:copied++
            } else {
                $script:skipped++
            }

            # Record in manifest regardless of copy (file exists at dest)
            $webPath = "/captures/$category/$name/$($img.Name.ToLower())"
            if ($category -eq "artifacts") {
                if (-not $script:artifactEntries.ContainsKey($name)) {
                    $script:artifactEntries[$name] = @{}
                }
                $script:artifactEntries[$name][$angle] = $webPath
            } else {
                if (-not $script:mapEntries.ContainsKey($name)) {
                    $script:mapEntries[$name] = @{}
                }
                $script:mapEntries[$name][$angle] = $webPath
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Also scan existing destination for previously-synced files not in source
# (so the manifest is complete even if source dirs are missing)
# ---------------------------------------------------------------------------

function Scan-ExistingCaptures([string]$Category) {
    $catDir = Join-Path $DestBase $Category
    if (-not (Test-Path $catDir)) { return }

    $subDirs = Get-ChildItem -Path $catDir -Directory
    foreach ($sub in $subDirs) {
        $name = $sub.Name
        $images = Get-ChildItem -Path $sub.FullName -File -Filter "*.png"

        foreach ($img in $images) {
            $angle   = [System.IO.Path]::GetFileNameWithoutExtension($img.Name).ToLower()
            $webPath = "/captures/$Category/$name/$($img.Name.ToLower())"

            if ($Category -eq "artifacts") {
                if (-not $script:artifactEntries.ContainsKey($name)) {
                    $script:artifactEntries[$name] = @{}
                }
                if (-not $script:artifactEntries[$name].ContainsKey($angle)) {
                    $script:artifactEntries[$name][$angle] = $webPath
                }
            } else {
                if (-not $script:mapEntries.ContainsKey($name)) {
                    $script:mapEntries[$name] = @{}
                }
                if (-not $script:mapEntries[$name].ContainsKey($angle)) {
                    $script:mapEntries[$name][$angle] = $webPath
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

Write-Host "=== Ada Capture Sync ==="
Write-Host "Encyclopedia: $EncyclopediaPath"
Write-Host "Destination:  $DestBase"
if ($DryRun) { Write-Host "Mode:         DRY RUN (no files will be written)" }
elseif ($Force) { Write-Host "Mode:         FORCE (overwrite all)" }
else { Write-Host "Mode:         incremental (skip if destination newer)" }
Write-Host ""

# Ensure destination base exists
if (-not $DryRun -and -not (Test-Path $DestBase)) {
    New-Item -ItemType Directory -Path $DestBase -Force | Out-Null
}

# Process each source directory
foreach ($src in $SourceDirs) {
    Write-Host "Scanning: $($src.Path)"
    Sync-SourceDir -SourcePath $src.Path -FixedCategory $src.Category
}

# Pick up any previously-synced captures already at the destination
Write-Host ""
Write-Host "Scanning existing captures at destination..."
Scan-ExistingCaptures "artifacts"
Scan-ExistingCaptures "maps"

# ---------------------------------------------------------------------------
# Build manifest
# ---------------------------------------------------------------------------

$totalImages = 0
foreach ($k in $artifactEntries.Keys) { $totalImages += $artifactEntries[$k].Count }
foreach ($k in $mapEntries.Keys)      { $totalImages += $mapEntries[$k].Count }

# Convert hashtables to ordered dictionaries for clean JSON output
$artifactsOrdered = [ordered]@{}
foreach ($k in ($artifactEntries.Keys | Sort-Object)) {
    $inner = [ordered]@{}
    foreach ($a in ($artifactEntries[$k].Keys | Sort-Object)) {
        $inner[$a] = $artifactEntries[$k][$a]
    }
    $artifactsOrdered[$k] = $inner
}

$mapsOrdered = [ordered]@{}
foreach ($k in ($mapEntries.Keys | Sort-Object)) {
    $inner = [ordered]@{}
    foreach ($a in ($mapEntries[$k].Keys | Sort-Object)) {
        $inner[$a] = $mapEntries[$k][$a]
    }
    $mapsOrdered[$k] = $inner
}

$manifest = [ordered]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    artifacts   = $artifactsOrdered
    maps        = $mapsOrdered
    stats       = [ordered]@{
        totalArtifacts  = $artifactEntries.Count
        totalMaps       = $mapEntries.Count
        totalImages     = $totalImages
        copiedThisRun   = $copied
        skippedThisRun  = $skipped
    }
}

if ($DryRun) {
    Write-Host ""
    Write-Host "[dry-run] Would write manifest to: $ManifestPath"
} else {
    $json = $manifest | ConvertTo-Json -Depth 4
    # Ensure destination directory exists
    $manifestDir = Split-Path $ManifestPath -Parent
    if (-not (Test-Path $manifestDir)) {
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    }
    Set-Content -Path $ManifestPath -Value $json -Encoding UTF8
    Write-Host ""
    Write-Host "Manifest written: $ManifestPath"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "  Artifacts:  $($artifactEntries.Count)"
Write-Host "  Maps:       $($mapEntries.Count)"
Write-Host "  Copied:     $copied"
Write-Host "  Skipped:    $skipped"
Write-Host "  Total imgs: $totalImages"
Write-Host ""
