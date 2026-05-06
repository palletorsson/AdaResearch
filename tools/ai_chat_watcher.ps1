# ai_chat_watcher.ps1
# Watches ai_chat.json for changes and forwards new messages to Clawdbot.
# Zero token burn when idle. Only fires when user types in the Godot AI panel.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\ai_chat_watcher.ps1
# Stop:   Ctrl+C

$chatFile = "$env:APPDATA\Godot\app_userdata\Ada Research Zero One\ai_chat.json"
$watchDir = Split-Path $chatFile -Parent
$watchFile = Split-Path $chatFile -Leaf

# Track how many messages we've already processed
$lastMessageCount = 0
if (Test-Path $chatFile) {
    $json = Get-Content $chatFile -Raw | ConvertFrom-Json
    $lastMessageCount = $json.messages.Count
    Write-Host "[watcher] Starting. $lastMessageCount existing messages (will ignore)." -ForegroundColor Cyan
}

Write-Host "[watcher] Watching: $chatFile" -ForegroundColor Green
Write-Host "[watcher] Press Ctrl+C to stop." -ForegroundColor DarkGray
Write-Host ""

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchDir
$watcher.Filter = $watchFile
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
$watcher.EnableRaisingEvents = $false

while ($true) {
    try {
        $result = $watcher.WaitForChanged([System.IO.WatcherChangeTypes]::Changed, 5000)
        if ($result.TimedOut) { continue }

        Start-Sleep -Milliseconds 300

        if (-not (Test-Path $chatFile)) { continue }
        $content = Get-Content $chatFile -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }

        $json = $content | ConvertFrom-Json
        $messageCount = $json.messages.Count
        if ($messageCount -le $lastMessageCount) { continue }

        for ($i = $lastMessageCount; $i -lt $messageCount; $i++) {
            $msg = $json.messages[$i]
            $text = $msg.text
            $snap = $msg.state_snapshot
            $song = $snap.song_id
            $section = $snap.section
            $track = $snap.selected_track.name
            $bar = [int]$snap.bar
            $bpm = $snap.bpm
            $playing = $snap.playing

            $timestamp = Get-Date -Format "HH:mm:ss"
            Write-Host "[$timestamp] " -NoNewline -ForegroundColor DarkGray
            Write-Host "$text" -ForegroundColor White
            Write-Host "         $song / $section / $track (bar $bar)" -ForegroundColor DarkYellow

            # Build compact context
            $ctx = "song=$song sec=$section trk=$track bar=$bar bpm=$bpm"
            if ($playing -eq $true) { $ctx += " [playing]" }

            # Add spec summary if available
            $spec = $snap.json_spec
            if ($spec) {
                $specParts = @()
                if ($spec.has_chords) { $specParts += "chords:$($spec.chord_count)" }
                if ($spec.has_patterns) { $specParts += "patterns:$($spec.pattern_count)" }
                if ($spec.has_melody) { $specParts += "melodies:$($spec.melody_count)" }
                if ($spec.key) { $specParts += "key:$($spec.key)" }
                if ($specParts.Count -gt 0) {
                    $ctx += " spec=[$($specParts -join ',')]"
                } else {
                    $ctx += " spec=[empty]"
                }
            }

            $agentMsg = "[godot-music] $ctx | `"$text`""

            Write-Host "         -> sending..." -ForegroundColor DarkCyan
            & clawdbot system event --text $agentMsg --mode now 2>&1 | Out-Null
            Write-Host "         -> sent" -ForegroundColor Green
        }

        $lastMessageCount = $messageCount
        Write-Host ""

    } catch {
        Write-Host "[watcher] Error: $_" -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}
