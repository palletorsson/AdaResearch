param(
    [string]$GodotExe = 'C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe',
    [switch]$PortalPilot,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$adaRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable not found: $GodotExe" }
if ($PortalPilot) {
    $xrBody = Get-Content -LiteralPath (Join-Path $adaRoot 'addons\godot-xr-tools\player\player_body.gd') -Raw
    if (-not $xrBody.Contains('target_move_distance > 0.0001') -or -not $xrBody.Contains('clampf(_fade_value + delta * 3.0, 0.0, 1.0)')) {
        throw 'The portal pilot requires the XRTools head-fade fixes. Run python tools/patch_xrtools_head_fade.py --apply from the project directory.'
    }
}
$runtime = (Get-ItemProperty 'HKLM:\SOFTWARE\Khronos\OpenXR\1' -Name ActiveRuntime -ErrorAction SilentlyContinue).ActiveRuntime
Write-Host "OpenXR runtime: $runtime"
Write-Host 'Connect the Quest through Link or Air Link before launching. Ada runs on this PC.'
$adaArgs = @('--path', $adaRoot, '--xr-mode', 'on', '--rendering-method', 'mobile',
    '--log-file', (Join-Path $adaRoot 'ada_run\quest_link.log'))
if ($PortalPilot) { $adaArgs += @('--', '--em-portals') }
if ($DryRun) {
    Write-Output $GodotExe
    Write-Output $adaArgs
    return
}
& $GodotExe @adaArgs
exit $LASTEXITCODE
