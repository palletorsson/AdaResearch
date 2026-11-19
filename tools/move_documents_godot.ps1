param([Parameter(Mandatory=$true)][string]$ReceiptDirectory)
$ErrorActionPreference = 'Stop'
$source = 'C:\Users\palle\Documents\godot'
$destination = 'D:\godot'
$receiptRoot = [IO.Path]::GetFullPath($ReceiptDirectory)
if (-not $receiptRoot.StartsWith('D:\.codex-moves\godot-', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected receipt directory' }
$statusPath = Join-Path $receiptRoot 'status.json'
$journalPath = Join-Path $receiptRoot 'verified-files.jsonl'
$tag = Split-Path $receiptRoot -Leaf
$backup = Join-Path (Split-Path $source -Parent) ($tag + '.verified-source')
$phase = 'preflight'
$state = [ordered]@{source=$source;destination=$destination;backup=$backup;phase=$phase;files=0;bytes=0;verifiedFiles=0;verifiedBytes=0;started=[DateTime]::UtcNow.ToString('o')}
function Save-State {
    $state.phase = $script:phase
    $state.updated = [DateTime]::UtcNow.ToString('o')
    $temp = $statusPath + '.tmp'
    [IO.File]::WriteAllText($temp, ($state | ConvertTo-Json -Depth 6))
    Move-Item -LiteralPath $temp -Destination $statusPath -Force
}
function Assert-OriginalPath([string]$candidate) {
    $absolute = [IO.Path]::GetFullPath($candidate)
    if ($absolute -ne $backup -or (Split-Path $absolute -Parent) -ne 'C:\Users\palle\Documents') { throw "Unexpected cleanup target: $absolute" }
    $item = Get-Item -LiteralPath $absolute -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Cleanup target is a link' }
    if (@(Get-ChildItem -LiteralPath $absolute -Force -Recurse | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Cleanup tree contains a link' }
}
function Assert-NoUsers {
    $folderUsers = @(Get-CimInstance Win32_Process | Where-Object {
        $_.ProcessId -ne $PID -and $_.Name -notin @('pwsh.exe','powershell.exe') -and
        ($_.ExecutablePath -like "$source\*" -or $_.CommandLine -like "*$source*" -or $_.CommandLine -like '*C:/Users/palle/Documents/godot*')
    })
    if ($folderUsers.Count) { throw ('Folder is in use by process(es): ' + ($folderUsers.ProcessId -join ',')) }
}
try {
    if (Test-Path -LiteralPath $receiptRoot) { throw 'Receipt directory already exists; inspect its status before resuming' }
    New-Item -ItemType Directory -Path $receiptRoot | Out-Null
    $sourceItem = Get-Item -LiteralPath $source -Force
    if ($sourceItem.FullName -ne $source -or ($sourceItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Source is not the expected ordinary directory' }
    if (Test-Path -LiteralPath $destination) { throw 'Destination already exists; refusing to merge or overwrite it' }
    if (Test-Path -LiteralPath $backup) { throw 'Original-copy cleanup path already exists' }
    Assert-NoUsers
    $entries = @(Get-ChildItem -LiteralPath $source -Force -Recurse)
    if (@($entries | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) { throw 'Source contains links; move requires a link-aware inventory' }
    $files = @($entries | Where-Object { -not $_.PSIsContainer })
    $directories = @($entries | Where-Object { $_.PSIsContainer })
    $state.files = $files.Count
    $state.bytes = [long](($files | Measure-Object Length -Sum).Sum)
    if ((Get-PSDrive D).Free -lt ($state.bytes + 1GB)) { throw 'D: does not have enough free space' }
    $state.cFreeBefore = (Get-PSDrive C).Free
    $state.dFreeBefore = (Get-PSDrive D).Free
    $inventory = @{}
    foreach ($file in $files) {
        $relative = [IO.Path]::GetRelativePath($source, $file.FullName)
        $inventory[$relative] = @($file.Length,$file.LastWriteTimeUtc.Ticks)
    }
    $phase = 'copying'; Save-State
    Write-Output "COPYING $($state.files) files / $($state.bytes) bytes to $destination"
    & robocopy.exe $source $destination /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /MT:8 /NP /NFL /NDL /BYTES "/LOG:$(Join-Path $receiptRoot 'robocopy.log')"
    $copyExit = $LASTEXITCODE
    $state.robocopyExit = $copyExit
    if ($copyExit -ge 8) { throw "Copy failed (robocopy $copyExit); original folder retained" }
    $phase = 'verifying'; Save-State
    Write-Output 'COPY COMPLETE. Verifying SHA-256 of every source and destination file.'
    $writer = [IO.StreamWriter]::new($journalPath,$false,[Text.UTF8Encoding]::new($false))
    try {
        $lastProgress = [DateTime]::UtcNow
        foreach ($file in $files) {
            $relative = [IO.Path]::GetRelativePath($source,$file.FullName)
            $target = Join-Path $destination $relative
            $copy = Get-Item -LiteralPath $target -Force
            if ($copy.Length -ne $inventory[$relative][0]) { throw "Length mismatch: $relative" }
            $sourceHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
            if ($sourceHash -ne $targetHash) { throw "Hash mismatch: $relative" }
            $fresh = Get-Item -LiteralPath $file.FullName -Force
            if ($fresh.Length -ne $inventory[$relative][0] -or $fresh.LastWriteTimeUtc.Ticks -ne $inventory[$relative][1]) { throw "Source changed during copy: $relative" }
            $writer.WriteLine(([ordered]@{path=$relative;bytes=$fresh.Length;sha256=$sourceHash;modified=$fresh.LastWriteTimeUtc.ToString('o')} | ConvertTo-Json -Compress))
            $state.verifiedFiles++
            $state.verifiedBytes += $fresh.Length
            if (([DateTime]::UtcNow-$lastProgress).TotalSeconds -ge 15) {
                $writer.Flush(); Save-State
                Write-Output "VERIFIED $($state.verifiedFiles)/$($state.files) files; $($state.verifiedBytes) bytes"
                $lastProgress = [DateTime]::UtcNow
            }
        }
    } finally { $writer.Dispose() }
    # Catch new files, late writes, and missing/empty directories before cutover.
    $freshEntries = @(Get-ChildItem -LiteralPath $source -Force -Recurse)
    $freshFiles = @($freshEntries | Where-Object { -not $_.PSIsContainer })
    if ($freshFiles.Count -ne $files.Count -or $freshEntries.Count -ne $entries.Count) { throw 'Source inventory changed; no original files removed' }
    foreach ($file in $freshFiles) {
        $relative = [IO.Path]::GetRelativePath($source,$file.FullName)
        if (-not $inventory.ContainsKey($relative) -or $file.Length -ne $inventory[$relative][0] -or $file.LastWriteTimeUtc.Ticks -ne $inventory[$relative][1]) { throw "Source changed before cutover: $relative" }
    }
    foreach ($directory in $directories) {
        if (-not (Test-Path -LiteralPath (Join-Path $destination ([IO.Path]::GetRelativePath($source,$directory.FullName))) -PathType Container)) { throw 'Destination directory missing' }
    }
    $targetEntries = @(Get-ChildItem -LiteralPath $destination -Force -Recurse)
    if ($targetEntries.Count -ne $entries.Count) { throw 'Destination inventory differs' }
    Assert-NoUsers
    $phase = 'verified'; Save-State
    # Rename only the explicitly checked source within its existing parent.
    if (([IO.Path]::GetFullPath($source)) -ne 'C:\Users\palle\Documents\godot' -or (Split-Path $backup -Parent) -ne (Split-Path $source -Parent)) { throw 'Unexpected cutover paths' }
    Rename-Item -LiteralPath $source -NewName (Split-Path $backup -Leaf)
    try {
        New-Item -ItemType Junction -Path $source -Target $destination | Out-Null
        $link = Get-Item -LiteralPath $source -Force
        if ($link.LinkType -ne 'Junction' -or [IO.Path]::GetFullPath($link.Target) -ne $destination) { throw 'Junction verification failed' }
    } catch {
        if (-not (Test-Path -LiteralPath $source)) { Rename-Item -LiteralPath $backup -NewName 'godot' }
        throw
    }
    $phase = 'cleanup'; Save-State
    Write-Output 'ALL FILES VERIFIED. Old C: path now points to D:. Removing the verified original copies.'
    Assert-OriginalPath $backup
    Remove-Item -LiteralPath $backup -Recurse -Force
    $phase = 'complete'
    $state.cFreeAfter = (Get-PSDrive C).Free
    $state.finished = [DateTime]::UtcNow.ToString('o')
    Save-State
    Write-Output "COMPLETE. $destination; old path retained as a junction. C: free bytes: $($state.cFreeAfter)"
} catch {
    $state.error = $_.Exception.Message
    $state.failedPhase = $phase
    $phase = 'needs_attention'
    if (Test-Path -LiteralPath $receiptRoot) { Save-State }
    throw
}
