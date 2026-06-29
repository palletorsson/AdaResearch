# push_map_to_quest.ps1 - push ONE map to the Quest over adb (via run-as) + relaunch into it.
#
# No APK rebuild. Pairs with GridDataComponent._map_override_path + vrStaging._pushed_start_map,
# which read the app's INTERNAL user:// dir (= files/) first - so we write there with run-as, the
# same mechanism pull_quest_logs.ps1 uses (works on the debuggable build; no scoped-storage issues).
#
# LAYOUT ONLY - new/changed artifacts are compiled into the PCK and still need a full APK
# export + install. Use this for fast map-LAYOUT iteration on the standalone headset.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\push_map_to_quest.ps1 -Map Proto_Fractal_Recursion

param([Parameter(Mandatory = $true)][string]$Map)

$adb = "C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$pkg = "com.example.adaresearchzeroone"          # matches pull_quest_logs.ps1
$repo = Split-Path $PSScriptRoot -Parent
$local = Join-Path $repo "commons\maps\$Map\map_data.json"

if (-not (Test-Path $adb))   { Write-Host "adb not found at $adb" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $local)) { Write-Host "No map_data.json for '$Map' at $local" -ForegroundColor Red; exit 1 }

# Make sure the adb server is running (idempotent: starts it if down, no-op if already up).
& $adb start-server | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "adb server is not running and failed to start (exit $LASTEXITCODE)." -ForegroundColor Red
    Write-Host "Try '$adb kill-server' then re-run, or check that no other Android tool holds port 5037." -ForegroundColor Yellow
    exit 1
}

$online = (& $adb devices | Where-Object { $_ -match 'device$' }).Count
if ($online -lt 1) {
    Write-Host "No Quest connected/authorized - plug in USB + accept the in-headset debugging prompt." -ForegroundColor Red
    exit 1
}

# 1) map_data.json -> app's internal files/override_map/<Map>/ via a world-readable temp + run-as cp
#    (binary-safe: adb push handles the file, run-as cp copies into the app's private dir).
$tmpMap = "/data/local/tmp/_ada_push_map.json"
Write-Host "Pushing '$Map' -> files/override_map/$Map/map_data.json (run-as)" -ForegroundColor Cyan
& $adb push "$local" "$tmpMap"
if ($LASTEXITCODE -ne 0) { Write-Host "adb push to /data/local/tmp failed." -ForegroundColor Red; exit 1 }
& $adb shell "run-as $pkg mkdir -p files/override_map/$Map" | Out-Null
& $adb shell "run-as $pkg cp $tmpMap files/override_map/$Map/map_data.json" | Out-Null

# 2) start marker so the app boots straight into this map (read by vrStaging._pushed_start_map).
$startLocal = Join-Path $env:TEMP "_ada_start.txt"
Set-Content -Path $startLocal -Value $Map -NoNewline -Encoding ascii
$tmpStart = "/data/local/tmp/_ada_start.txt"
& $adb push "$startLocal" "$tmpStart" | Out-Null
& $adb shell "run-as $pkg cp $tmpStart files/override_map/_start.txt" | Out-Null

# cleanup transient temps
& $adb shell "rm -f $tmpMap $tmpStart" | Out-Null
Remove-Item $startLocal -ErrorAction SilentlyContinue

# 3) relaunch into the map
Write-Host "Relaunching $pkg ..." -ForegroundColor Cyan
& $adb shell "am force-stop $pkg" | Out-Null
& $adb shell "monkey -p $pkg -c android.intent.category.LAUNCHER 1" | Out-Null

Write-Host "Done. The app will relaunch straight into '$Map'." -ForegroundColor Green
Write-Host "(Back to normal start: adb shell run-as $pkg rm files/override_map/_start.txt)" -ForegroundColor DarkGray
