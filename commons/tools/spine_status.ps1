param([string]$Root = "")

if ($Root -eq "") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $Root = (Resolve-Path (Join-Path $scriptDir "..\..")).Path
}

$spine = @(
    'primitives','transformation','color','forces','array_tutorial',
    'wavefunctions','randomness','noise','cellularautomata','fractals',
    'lsystems','proceduralgeneration','softbodies','swarmintelligence',
    'machinelearning','foundationscrisis','qfeplaboratory',
    'postfoundationscrisis','graphtheory'
)

$reqPath = Join-Path $Root "commons\maps\sequence_requirements.json"
$req = Get-Content $reqPath -Raw | ConvertFrom-Json

Write-Output "=== SPINE SEQUENCES - Main Progression - Completeness Status ==="
Write-Output ""
$header = "  {0,-25} {1,7}  {2,5} {3,5} {4,5} {5,5}  {6,-15} {7,5}" -f "Sequence","Missing","Blurb","Summ","Tech","Crit","Phase","Order"
Write-Output $header
$sep = "  {0} {1}  {2} {3} {4} {5}  {6} {7}" -f ("-"*25),("-"*7),("-"*5),("-"*5),("-"*5),("-"*5),("-"*15),("-"*5)
Write-Output $sep

$results = @()

foreach ($name in $spine) {
    $seqData = $req.spine_sequences.$name
    $phase = if ($seqData.phase) { $seqData.phase } else { "?" }
    $order = if ($seqData.spine_order) { $seqData.spine_order } else { "?" }

    $seqFile = $null
    $seqDir = Join-Path $Root "commons\maps\sequences"
    foreach ($f in (Get-ChildItem $seqDir -Filter "*.json")) {
        $content = Get-Content $f.FullName -Raw | ConvertFrom-Json
        if ($content.sequences.PSObject.Properties.Name -contains $name) {
            $seqFile = $f
            break
        }
    }
    if (-not $seqFile) { continue }

    $seqJson = Get-Content $seqFile.FullName -Raw | ConvertFrom-Json
    $maps = $seqJson.sequences.$name.maps

    $bMiss = 0; $sMiss = 0; $tMiss = 0; $cMiss = 0
    foreach ($m in $maps) {
        $base = Join-Path $Root "commons\maps\$m"
        if (-not (Test-Path (Join-Path $base "blurb.md"))) { $bMiss++ }
        if (-not (Test-Path (Join-Path $base "summary.md"))) { $sMiss++ }
        if (-not (Test-Path (Join-Path $base "technical.md"))) { $tMiss++ }
        if (-not (Test-Path (Join-Path $base "critical.md"))) { $cMiss++ }
    }
    $total = $bMiss + $sMiss + $tMiss + $cMiss
    $mapCount = $maps.Count

    if ($bMiss -eq 0) { $bStr = "  OK " } else { $bStr = $bMiss.ToString().PadLeft(5) }
    if ($sMiss -eq 0) { $sStr = "  OK " } else { $sStr = $sMiss.ToString().PadLeft(5) }
    if ($tMiss -eq 0) { $tStr = "  OK " } else { $tStr = $tMiss.ToString().PadLeft(5) }
    if ($cMiss -eq 0) { $cStr = "  OK " } else { $cStr = $cMiss.ToString().PadLeft(5) }
    if ($total -eq 0) { $totalStr = "   OK " } else { $totalStr = $total.ToString().PadLeft(7) }
    $marker = if ($total -eq 0) { " DONE" } else { "" }

    $line = "  {0,-25} {1}  {2} {3} {4} {5}  {6,-15} {7,5}{8}" -f $name, $totalStr, $bStr, $sStr, $tStr, $cStr, $phase, $order, $marker

    $results += @{
        name = $name
        total = $total
        bMiss = $bMiss
        sMiss = $sMiss
        tMiss = $tMiss
        cMiss = $cMiss
        phase = $phase
        order = $order
        mapCount = $mapCount
        line = $line
    }
}

$done = $results | Where-Object { $_.total -eq 0 } | Sort-Object { [int]$_.order }
$incomplete = $results | Where-Object { $_.total -gt 0 } | Sort-Object { $_.total }

foreach ($r in $done) { Write-Output $r.line }
if ($done.Count -gt 0 -and $incomplete.Count -gt 0) {
    Write-Output "  --- incomplete below, sorted by fewest missing ---"
}
foreach ($r in $incomplete) { Write-Output $r.line }

Write-Output ""
Write-Output "=== SPINE PRIORITY: Top targets for .md writing ==="
Write-Output ""
$top = $incomplete | Select-Object -First 10
foreach ($r in $top) {
    $types = @()
    if ($r.bMiss -gt 0) { $types += $r.bMiss.ToString() + " blurb" }
    if ($r.sMiss -gt 0) { $types += $r.sMiss.ToString() + " summary" }
    if ($r.tMiss -gt 0) { $types += $r.tMiss.ToString() + " technical" }
    if ($r.cMiss -gt 0) { $types += $r.cMiss.ToString() + " critical" }
    $detail = $types -join ", "
    $orderNum = $r.order.ToString().PadLeft(2)
    $seqName = $r.name.PadRight(25)
    $fileCount = $r.total.ToString()
    $mCount = $r.mapCount.ToString()
    $pTag = $r.phase
    Write-Output "  #$orderNum $seqName $fileCount files / $mCount maps -- $detail  <$pTag>"
}
