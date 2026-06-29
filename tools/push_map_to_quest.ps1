# push_map_to_quest.ps1 — push ONE map's map_data.json to the Quest + relaunch, no APK rebuild.
#
# Pairs with GridDataComponent._map_override_path: on Android the game prefers
#     <app-external-files>/override_map/<Map>/map_data.json   over the baked res:// copy.
#
# LAYOUT ONLY — new/changed artifacts (.gd/.tscn) are compiled into the PCK and still need a full
# APK export + install. Use this for fast map-LAYOUT iteration in standalone (untethered) VR.
# (For new art, or the fastest loop overall, use Oculus Link + run the project on the PC instead.)
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\push_map_to_quest.ps1 -Map Proto_Fractal_Recursion

param([Parameter(Mandatory = $true)][string]$Map)

$adb = "C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$pkg = "com.example.adaresearchzeroone"          # matches export_presets.cfg / pull_quest_logs.ps1
$repo = Split-Path $PSScriptRoot -Parent
$local = Join-Path $repo "commons\maps\$Map\map_data.json"
$remoteDir = "/sdcard/Android/data/$pkg/files/override_map/$Map"

if (-not (Test-Path $adb))   { Write-Host "adb not found at $adb" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $local)) { Write-Host "No map_data.json for '$Map' at $local" -ForegroundColor Red; exit 1 }

$online = (& $adb devices | Where-Object { $_ -match "\tdevice$" }).Count
if ($online -lt 1) {
    Write-Host "No Quest connected/authorized — plug in USB and accept the in-headset debugging prompt." -ForegroundColor Red
    exit 1
}

Write-Host "Pushing '$Map' -> $remoteDir/map_data.json" -ForegroundColor Cyan
& $adb shell "mkdir -p '$remoteDir'" | Out-Null
& $adb push "$local" "$remoteDir/map_data.json"
if ($LASTEXITCODE -ne 0) {
    Write-Host "adb push to Android/data failed — your device may block it. Tell me and I'll switch this" -ForegroundColor Yellow
    Write-Host "script to the run-as method (writes the app's internal user:// dir, which your logs script uses)." -ForegroundColor Yellow
    exit 1
}

Write-Host "Relaunching $pkg ..." -ForegroundColor Cyan
& $adb shell "am force-stop $pkg" | Out-Null
& $adb shell "monkey -p $pkg -c android.intent.category.LAUNCHER 1" | Out-Null
Write-Host "Done. In the headset, open '$Map' via the map switcher to see the pushed layout." -ForegroundColor Green
