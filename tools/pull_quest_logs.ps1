# pull_quest_logs.ps1 - Pull logs from Quest to Desktop
# Usage: .\pull_quest_logs.ps1

$adb = "C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$pkg = "com.example.adaresearchzeroone"
$outDir = "C:\Users\palle\Desktop\quest_logs"

# Create output directory
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

# Check ADB connection
$devices = & $adb devices
if ($devices -notmatch "device$") {
    Write-Host "❌ No Quest connected. Make sure it's plugged in and authorized." -ForegroundColor Red
    exit 1
}

Write-Host "📱 Quest connected" -ForegroundColor Green

# List and pull logs
$logs = & $adb shell "run-as $pkg ls files/logs/ 2>/dev/null"
if (-not $logs) {
    Write-Host "❌ No logs found or permission denied" -ForegroundColor Red
    exit 1
}

Write-Host "📂 Pulling logs to $outDir" -ForegroundColor Cyan

foreach ($log in $logs) {
    $log = $log.Trim()
    if ($log) {
        & $adb shell "run-as $pkg cat files/logs/$log" | Out-File -FilePath "$outDir\$log" -Encoding utf8
        $size = (Get-Item "$outDir\$log").Length
        Write-Host "  ✅ $log ($size bytes)" -ForegroundColor Green
    }
}

Write-Host "`n📁 Logs saved to: $outDir" -ForegroundColor Cyan
Write-Host "Opening folder..." -ForegroundColor Gray
Start-Process explorer.exe $outDir
