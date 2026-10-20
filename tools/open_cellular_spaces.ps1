param([ValidateSet('womb','commons')][string]$Form = 'womb')
$projectRoot = Split-Path -Parent $PSScriptRoot
$godotBinary = if ($env:GODOT_EXE) { $env:GODOT_EXE } else { 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe' }
if (-not (Test-Path -LiteralPath $godotBinary -PathType Leaf)) {
    throw 'Set GODOT_EXE to the Godot 4.6 executable before launching.'
}
& $godotBinary --path $projectRoot --xr-mode off --rendering-method gl_compatibility res://commons/artifacts/cellular_spaces/museum.tscn -- --no-bridges "--cellular-form=$Form"
