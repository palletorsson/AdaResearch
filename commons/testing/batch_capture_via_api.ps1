# batch_capture_via_api.ps1
#
# Wraps the encyclopedia's /api/scenes/capture-first-person endpoint
# for batch artifact captures. Two-stage flow:
#
#   1. Run research_artifact_in_map.gd in --scan-only mode -> writes
#      user://artifact_positions.json with every (map, artifact, index,
#      position, label) it finds. Fast, no rendering.
#   2. Read that JSON and POST one capture per entry to the encyclopedia
#      API. The API drives capture_first_person.gd in the MapCatalog
#      pipeline (the GOOD one: proper biome, lighting, no overlays).
#      Resulting PNGs land in public/captures/first-person/<map>/<ts>.png
#      and we copy each to
#        public/artifact-in-map/<map>/<artifact>/<idx>_<label>.png
#      so the gallery picks them up automatically.
#
# Default camera framing -- "above, away, slight angle down":
#   - 1 m back from artifact along -Z (south)
#   - 0.5 m above the artifact's y
#   - 27 deg downward pitch
#   - yaw 180 deg (camera faces +Z toward artifact)
#   - FOV 60 deg
#
# Usage:
#   .\batch_capture_via_api.ps1 -Artifacts catalyst_foe,catalyst_vent
#   .\batch_capture_via_api.ps1 -Artifacts orb_test_rig -PitchDeg -20

param(
  [Parameter(Mandatory=$true)]
  [string]$Artifacts,                 # comma-separated lookup names
  [string]$EncyclopediaUrl = "http://localhost:3003",
  [string]$RepoPath = "C:\Users\palle\Documents\GitHub\AdaResearch_46",
  [string]$GodotExe = "",             # auto-detected if blank
  [string]$EncyclopediaPath = "C:\Users\palle\Documents\GitHub\ada_encyclopedia",
  [double]$StepBack = 1.0,            # horizontal distance from artifact (m)
  [double]$EyeRise = 0.5,             # how far above artifact's y the eye sits
  [double]$PitchDeg = -27,            # downward look
  [double]$YawDeg = 180,              # face +Z (toward artifact)
  [double]$Fov = 60,
  [int]$MaxPerArtifact = -1            # cap per (map, artifact); -1 = unlimited
)

if (-not $GodotExe) {
  $tries = @(
    $env:GODOT_EXE,
    "C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe",
    "C:\Users\palle\Desktop\Godot_v4.6-stable_win64_console.exe"
  )
  foreach ($t in $tries) {
    if ($t -and (Test-Path $t)) { $GodotExe = $t; break }
  }
  if (-not $GodotExe) { throw "Godot exe not found, pass -GodotExe" }
}
Write-Host "  godot: $GodotExe"

$userData = Join-Path $env:APPDATA "Godot\app_userdata\Ada Research Zero One"
$scanFile = Join-Path $userData "artifact_positions.json"

# Stage 1: discover positions
Write-Host "=== Stage 1: scanning maps for artifacts ===" -ForegroundColor Cyan
Write-Host "  artifacts: $Artifacts"

Remove-Item $scanFile -ErrorAction SilentlyContinue
$scanLog = Join-Path $env:TEMP "scan_$(Get-Date -Format yyyyMMddHHmmss).log"
$scanErr = "$scanLog.err"
$scanArgs = @(
    "--path", $RepoPath,
    "--xr-mode", "off",
    "--no-window",
    "--script", "res://commons/testing/research_artifact_in_map.gd",
    "--", "--scan-only", "--artifacts=$Artifacts"
)
if ($MaxPerArtifact -gt 0) {
  $scanArgs += "--max-per-artifact=$MaxPerArtifact"
}
Start-Process -FilePath $GodotExe `
  -ArgumentList $scanArgs `
  -RedirectStandardOutput $scanLog `
  -RedirectStandardError $scanErr `
  -Wait -NoNewWindow

if (-not (Test-Path $scanFile)) {
  Write-Host "scan failed, no positions written" -ForegroundColor Red
  Write-Host "log tail:"
  Get-Content $scanLog -Tail 15
  exit 1
}

$entries = Get-Content $scanFile -Raw | ConvertFrom-Json
Write-Host ("  scan found {0} placements" -f $entries.Count) -ForegroundColor Green

# Stage 2: group by map, one batch API call per map
Write-Host "=== Stage 2: batch captures via /api/scenes/capture-first-person-batch ===" -ForegroundColor Cyan

$apiUrl = "$EncyclopediaUrl/api/scenes/capture-first-person-batch"
$galleryRoot = Join-Path $EncyclopediaPath "public\artifact-in-map"
$publicRoot = Join-Path $EncyclopediaPath "public"

# Group entries by map so we can submit one batch per map (one Godot
# startup + map-load per map, regardless of how many shots).
$byMap = $entries | Group-Object -Property map

$succeeded = 0
$failed = 0

foreach ($g in $byMap) {
  $mapName = $g.Name
  $mapEntries = @($g.Group)
  Write-Host ("  --- map '{0}' ({1} shots) ---" -f $mapName, $mapEntries.Count) -ForegroundColor Yellow

  # Build shot list. shot.name carries the (artifact, index, label)
  # routing info so we can copy the result PNG back to the right
  # gallery folder.
  $shots = @()
  $shotMeta = @{}   # shot_name -> { artifact, idx, label }

  foreach ($e in $mapEntries) {
    $ax = [double]$e.position[0]
    $ay = [double]$e.position[1]
    $az = [double]$e.position[2]
    $camX = $ax
    $camY = $ay + $EyeRise
    $camZ = $az - $StepBack

    $shortName = if ($e.label) {
      "{0:D2}_{1}" -f $e.index, $e.label
    } else {
      "{0:D2}" -f $e.index
    }
    # Compose a shot name unique within the batch: artifact + shortname.
    $shotName = "{0}__{1}" -f $e.artifact, $shortName
    $shotMeta[$shotName] = @{
      artifact = $e.artifact
      shortName = $shortName
    }

    $shots += @{
      name = $shotName
      position = @($camX, $camY, $camZ)
      yawDeg = $YawDeg
      pitchDeg = $PitchDeg
      fov = $Fov
    }
  }

  $body = @{
    map = $mapName
    shots = $shots
  } | ConvertTo-Json -Depth 6

  try {
    $r = Invoke-RestMethod -Uri $apiUrl -Method POST -Body $body `
                           -ContentType "application/json" -TimeoutSec 600
    Write-Host ("    batch OK: {0}/{1} shots saved ({2:N0} ms total, {3:N0} ms/shot)" -f `
      $r.savedCount, $r.requestedCount, $r.durationMs, ($r.durationMs / [Math]::Max(1, $r.savedCount))) -ForegroundColor Green

    foreach ($outShot in $r.shots) {
      $meta = $shotMeta[$outShot.name]
      if (-not $meta) {
        Write-Host ("      WARN: no meta for shot '{0}'" -f $outShot.name) -ForegroundColor Yellow
        continue
      }
      $srcUrlPath = $outShot.url -replace '/', '\'
      $srcAbs = Join-Path $publicRoot $srcUrlPath.TrimStart('\')
      if (-not (Test-Path $srcAbs)) {
        Write-Host ("      FAIL: source PNG missing: {0}" -f $srcAbs) -ForegroundColor Red
        $failed++
        continue
      }
      $dstDir = Join-Path $galleryRoot "$mapName\$($meta.artifact)"
      New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
      $dstFile = Join-Path $dstDir "$($meta.shortName).png"
      Copy-Item $srcAbs $dstFile -Force
      $succeeded++
    }
  } catch {
    Write-Host ("    BATCH FAIL: {0}" -f $_.Exception.Message) -ForegroundColor Red
    $failed += $mapEntries.Count
  }
}

Write-Host ""
Write-Host ("=== done: {0} succeeded, {1} failed ===" -f $succeeded, $failed) -ForegroundColor Cyan

# Stage 3: regenerate manifest so the /artifact-in-map gallery picks up
# the new captures automatically.
Write-Host "=== Stage 3: regenerating gallery manifest ===" -ForegroundColor Cyan
$registryDir = Join-Path $RepoPath "commons\artifacts\registry"
$registryMap = @{}
Get-ChildItem $registryDir -Filter "*.json" -ErrorAction SilentlyContinue | Where-Object { -not $_.Name.EndsWith(".bak") } | ForEach-Object {
  try {
    $data = Get-Content $_.FullName -Raw | ConvertFrom-Json
    if ($data.PSObject.Properties.Name -contains "artifacts") {
      $data.artifacts.PSObject.Properties | ForEach-Object {
        $registryMap[$_.Name] = @{
          name = $_.Value.name
          description = $_.Value.description
          category = $_.Value.category
        }
      }
    }
  } catch {}
}

$maps = @{}
# Use `foreach` keyword (not the pipeline ForEach-Object) so $caps and
# $artifacts accumulate in the SAME scope — the pipeline form creates
# child scopes and the parent's $artifacts never sees the +=.
$mapDirs = @(Get-ChildItem $galleryRoot -Directory -ErrorAction SilentlyContinue)
foreach ($mapDir in $mapDirs) {
  $mapName = $mapDir.Name
  $artifacts = @()
  $artDirs = @(Get-ChildItem $mapDir.FullName -Directory)
  foreach ($artDir in $artDirs) {
    $lookup = $artDir.Name
    $caps = @()
    $pngs = @(Get-ChildItem $artDir.FullName -Filter "*.png" | Sort-Object Name)
    foreach ($png in $pngs) { $caps += $png.BaseName }
    if ($caps.Count -gt 0) {
      $entry = $registryMap[$lookup]
      $artifacts += [pscustomobject]@{
        lookup_name = $lookup
        label = if ($entry) { $entry.name } else { $lookup }
        description = if ($entry) { $entry.description } else { "" }
        category = if ($entry) { $entry.category } else { "" }
        captures = $caps
      }
    }
  }
  if ($artifacts.Count -gt 0) {
    $maps[$mapName] = [pscustomobject]@{
      map_name = $mapName
      artifact_count = $artifacts.Count
      artifacts = $artifacts
    }
  }
}

$out = [pscustomobject]@{
  generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
  maps = $maps
}
$out | ConvertTo-Json -Depth 10 | Out-File (Join-Path $galleryRoot "manifest.json") -Encoding utf8

$totalArtifacts = 0
$totalCaps = 0
foreach ($entry in $maps.GetEnumerator()) {
  $totalArtifacts += $entry.Value.artifact_count
  $totalCaps += ($entry.Value.artifacts | ForEach-Object { $_.captures.Count } | Measure-Object -Sum).Sum
}
Write-Host ("  manifest: {0} maps, {1} artifacts, {2} captures" -f $maps.Count, $totalArtifacts, $totalCaps) -ForegroundColor Green
Write-Host ("  gallery: $EncyclopediaUrl/artifact-in-map") -ForegroundColor Green
