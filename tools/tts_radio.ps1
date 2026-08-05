# tts_radio.ps1 -- render an Ada Radio script to speech with Windows SAPI.
#
# The macOS sibling (tools/tts_technical.sh) uses `say`; this uses System.Speech,
# which ships with Windows and needs no install.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools/tts_radio.ps1
#   powershell -ExecutionPolicy Bypass -File tools/tts_radio.ps1 -Script doc/radio/x.md -Rate 1
#
# Input format: lines of "SPEAKER: text". Everything else (markdown, front matter,
# rules, notes) is ignored, so the script file stays readable as a document.
#
# Output: one WAV per speaker turn in <outdir>/parts/, plus a single joined WAV.

param(
    [string]$Script  = "doc/radio/ada_radio_2026-08-03.md",
    [string]$OutDir  = "",
    [int]   $Rate    = 0,       # SAPI rate, -10..10. 0 is ~180 wpm.
    [switch]$PartsOnly,
    [switch]$JoinOnly           # re-join existing parts/ without re-speaking
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Speech

$repo = Split-Path -Parent $PSScriptRoot
$src  = if ([System.IO.Path]::IsPathRooted($Script)) { $Script } else { Join-Path $repo $Script }
if (-not (Test-Path $src)) { throw "Script not found: $src" }

$stem = [System.IO.Path]::GetFileNameWithoutExtension($src)
if ($OutDir -eq "") { $OutDir = Join-Path $repo "doc/radio/audio/$stem" }
$parts = Join-Path $OutDir "parts"
New-Item -ItemType Directory -Force -Path $parts | Out-Null

# Speaker -> voice. Falls back to the first installed voice if one is missing.
$synth     = New-Object System.Speech.Synthesis.SpeechSynthesizer
$installed = $synth.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo.Name }
function Pick-Voice([string[]]$wanted) {
    foreach ($w in $wanted) {
        $hit = $installed | Where-Object { $_ -like "*$w*" } | Select-Object -First 1
        if ($hit) { return $hit }
    }
    return $installed[0]
}
$voiceFor = @{
    "HOST"   = Pick-Voice @("Hazel", "Zira", "David")
    "FIELD"  = Pick-Voice @("David", "Zira", "Hazel")
    "LEDGER" = Pick-Voice @("Zira", "Hazel", "David")
}

Write-Host "Ada Radio TTS"
Write-Host "  script : $src"
Write-Host "  out    : $OutDir"
foreach ($k in $voiceFor.Keys) { Write-Host ("  {0,-6} -> {1}" -f $k, $voiceFor[$k]) }
Write-Host ""

# SAPI reads bare markdown emphasis and links as noise; strip what survives a turn.
function Clean-Line([string]$t) {
    $t = $t -replace '\*\*', '' -replace '(?<!\w)\*(?!\w)', ''
    $t = $t -replace '\[([^\]]*)\]\([^)]*\)', '$1'
    $t = $t -replace '`([^`]*)`', '$1'
    return $t.Trim()
}

$turns = @()
foreach ($line in Get-Content -LiteralPath $src -Encoding UTF8) {
    if ($line -match '^(HOST|FIELD|LEDGER):\s*(.+)$') {
        $turns += [pscustomobject]@{ Speaker = $Matches[1]; Text = Clean-Line $Matches[2] }
    }
}
if ($turns.Count -eq 0) { throw "No 'SPEAKER: text' lines found in $src" }

$words = ($turns | ForEach-Object { ($_.Text -split '\s+').Count } | Measure-Object -Sum).Sum
Write-Host ("{0} turns, {1} words (~{2:N1} min at 180 wpm)" -f $turns.Count, $words, ($words / 180))
Write-Host ""

if ($JoinOnly) {
    $files = Get-ChildItem -LiteralPath $parts -Filter *.wav | Sort-Object Name | ForEach-Object { $_.FullName }
    if ($files.Count -eq 0) { throw "No parts in $parts -- run without -JoinOnly first" }
    Write-Host ("  reusing {0} existing parts" -f $files.Count)
    $synth.Dispose()
} else {
    $synth.Rate = $Rate
    $i = 0
    $files = @()
    foreach ($t in $turns) {
        $i++
        $out = Join-Path $parts ("{0:d3}_{1}.wav" -f $i, $t.Speaker.ToLower())
        $synth.SelectVoice($voiceFor[$t.Speaker])
        $synth.SetOutputToWaveFile($out)
        $synth.Speak($t.Text)
        $synth.SetOutputToNull()
        $files += $out
        if ($i % 10 -eq 0) { Write-Host ("  ... {0}/{1}" -f $i, $turns.Count) }
    }
    $synth.Dispose()
    Write-Host ("  {0} parts written" -f $files.Count)
}

if ($PartsOnly) { Write-Host "Done (parts only)."; exit 0 }

# Join. Every part shares one PCM format, so concatenating the data chunks and
# writing a fresh header is enough -- no ffmpeg dependency.
#
# Do NOT assume the canonical 44-byte header: SAPI emits WAVEFORMATEX, an
# 18-byte 'fmt ' chunk, so data starts at 46. Walk the chunk table instead.
function Read-WavChunks([byte[]]$b) {
    $fmt = $null; $dataOff = -1; $dataLen = 0
    $pos = 12                                    # past "RIFF" + size + "WAVE"
    while ($pos -lt $b.Length - 8) {
        $id  = [System.Text.Encoding]::ASCII.GetString($b, $pos, 4)
        $sz  = [BitConverter]::ToInt32($b, $pos + 4)
        # Cast: slicing a byte[] in PowerShell yields Object[], which binds
        # BinaryWriter.Write to the wrong overload and corrupts the header.
        if ($id -eq "fmt ") { $fmt = [byte[]]($b[$pos..($pos + 7 + $sz)]) }   # header + body
        elseif ($id -eq "data") { $dataOff = $pos + 8; $dataLen = $sz }
        $pos += 8 + $sz + ($sz % 2)              # chunks are word-aligned
    }
    if ($null -eq $fmt -or $dataOff -lt 0) { throw "malformed wav" }
    return @{ Fmt = $fmt; Offset = $dataOff; Length = $dataLen }
}

$joined = Join-Path $OutDir "$stem.wav"
$fmtChunk = $null
$pcm      = New-Object System.IO.MemoryStream
foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $c = Read-WavChunks $bytes
    if ($null -eq $fmtChunk) { $fmtChunk = $c.Fmt }
    $pcm.Write($bytes, $c.Offset, $c.Length)
}
$data = $pcm.ToArray()
$pcm.Dispose()

$fs = [System.IO.File]::Create($joined)
$bw = New-Object System.IO.BinaryWriter($fs)
$bw.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
$bw.Write([int](4 + $fmtChunk.Length + 8 + $data.Length))   # "WAVE" + fmt + data hdr + pcm
$bw.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
$bw.Write($fmtChunk)
$bw.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
$bw.Write([int]$data.Length)
$bw.Write($data)
$bw.Dispose()
$fs.Dispose()

# Verify what was actually written, rather than trusting that we wrote it.
# This joiner shipped broken twice -- once assuming a 44-byte header, once
# losing the byte[] type on a slice -- and both times the file looked fine
# by size alone. Re-walk the output's chunk table and check it against the input.
$check = Read-WavChunks ([System.IO.File]::ReadAllBytes($joined))
$size  = (Get-Item $joined).Length
$riff  = [BitConverter]::ToInt32([System.IO.File]::ReadAllBytes($joined), 4)
$rate  = [BitConverter]::ToInt32($fmtChunk, 16)          # byte rate, fmt body offset 8
$fail  = @()
if ($riff -ne $size - 8)            { $fail += "RIFF size $riff != $($size - 8)" }
if ($check.Length -ne $data.Length) { $fail += "data chunk $($check.Length) != $($data.Length) written" }
if ($check.Offset + $check.Length -ne $size) { $fail += "data chunk overruns file" }
if ($fail.Count -gt 0) {
    Write-Host ""
    foreach ($f in $fail) { Write-Host "  FAIL: $f" }
    throw "Joined WAV failed verification -- do not trust it"
}

Write-Host ""
Write-Host ("Done: {0}" -f $joined)
Write-Host ("  {0:N1} MB, {1:N0}:{2:d2}, verified ({3} parts joined)" -f `
    ($size / 1MB), [math]::Floor($check.Length / $rate / 60), [int](($check.Length / $rate) % 60), $files.Count)
