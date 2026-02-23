<#
.SYNOPSIS
    Project Dashboard CLI — structured task output for Claude Code.

.DESCRIPTION
    Reads sequence_requirements.json, cross-references filesystem,
    outputs actionable task lists that Claude can parse and execute.

.PARAMETER Mode
    What to output:
      status    - Overview stats (default)
      tasks     - All actionable tasks, sorted by priority
      sequence  - Detail for one sequence (requires -Name)
      missing   - List all missing .md files with full paths
      postlab   - List missing/anomalous post-lab maps
      phase     - Breakdown by QFEP phase
      recommend - Strategic next-action recommendations
      context   - Gather all sources needed to write .md for a map (requires -Name mapname)
      nearwin   - Sequences closest to book/wiki completion

.PARAMETER Name
    Sequence name for -Mode sequence, or map name for -Mode context

.PARAMETER Format
    Output format: text (default), json, csv

.EXAMPLE
    .\project_dashboard_cli.ps1
    .\project_dashboard_cli.ps1 -Mode tasks
    .\project_dashboard_cli.ps1 -Mode sequence -Name forces
    .\project_dashboard_cli.ps1 -Mode missing -Format csv
    .\project_dashboard_cli.ps1 -Mode recommend
    .\project_dashboard_cli.ps1 -Mode context -Name CA_1
    .\project_dashboard_cli.ps1 -Mode nearwin
#>

param(
    [string]$Mode = "status",
    [string]$Name = "",
    [string]$Format = "text"
)

$ErrorActionPreference = "Stop"
$root = "C:\Users\palle\Documents\GitHub\AdaResearch_46"
$mapsDir = Join-Path $root "commons\maps"
$seqDir = Join-Path $mapsDir "sequences"
$labDir = Join-Path $mapsDir "Lab"
$algoDir = Join-Path $root "algorithms"
$reqFile = Join-Path $mapsDir "sequence_requirements.json"

# ── Load requirements.json ──────────────────────────────────────────────
if (-not (Test-Path $reqFile)) {
    Write-Error "sequence_requirements.json not found at $reqFile"
    exit 1
}
$req = Get-Content $reqFile -Raw | ConvertFrom-Json

# ── Pre-scan filesystem for .md files ───────────────────────────────────
$allBlurbs = @{}
$allSummaries = @{}
$allTechnicals = @{}
$allCriticals = @{}

Get-ChildItem -Path $mapsDir -Recurse -Filter 'blurb.md' -File | ForEach-Object {
    $allBlurbs[(Split-Path $_.DirectoryName -Leaf)] = $true
}
Get-ChildItem -Path $mapsDir -Recurse -Filter 'summary.md' -File | ForEach-Object {
    $allSummaries[(Split-Path $_.DirectoryName -Leaf)] = $true
}
Get-ChildItem -Path $mapsDir -Recurse -Filter 'technical.md' -File | ForEach-Object {
    $allTechnicals[(Split-Path $_.DirectoryName -Leaf)] = $true
}
Get-ChildItem -Path $mapsDir -Recurse -Filter 'critical.md' -File | ForEach-Object {
    $allCriticals[(Split-Path $_.DirectoryName -Leaf)] = $true
}

# ── Helper: get map list from sequence file ─────────────────────────────
function Get-SequenceMaps($seqName) {
    $seqFile = Join-Path $seqDir "$seqName.json"
    if (-not (Test-Path $seqFile)) { return @() }
    $content = Get-Content $seqFile -Raw | ConvertFrom-Json
    $seqData = $content.sequences.PSObject.Properties | Select-Object -First 1
    if ($seqData -and $seqData.Value.maps) {
        return @($seqData.Value.maps)
    }
    return @()
}

# ── Helper: validate one sequence ───────────────────────────────────────
function Get-SequenceStatus($seqName, $seqData, $seqType) {
    $maps = Get-SequenceMaps $seqName
    $mapCount = $maps.Count

    # Check deferred
    $isDeferred = $false
    if ($seqData.maps -and $seqData.maps.status -eq "deferred") {
        $isDeferred = $true
    }

    # Phase
    $phase = ""
    if ($seqData.qfep -and $seqData.qfep.phase) { $phase = $seqData.qfep.phase }
    elseif ($seqData.phase) { $phase = $seqData.phase }

    # Count .md coverage
    $missingBlurb = @()
    $missingSummary = @()
    $missingTechnical = @()
    $missingCritical = @()

    if (-not $isDeferred) {
        foreach ($m in $maps) {
            if (-not $allBlurbs.ContainsKey($m)) { $missingBlurb += $m }
            if (-not $allSummaries.ContainsKey($m)) { $missingSummary += $m }
            if (-not $allTechnicals.ContainsKey($m)) { $missingTechnical += $m }
            if (-not $allCriticals.ContainsKey($m)) { $missingCritical += $m }
        }
    }

    $blurbHave = $mapCount - $missingBlurb.Count
    $summaryHave = $mapCount - $missingSummary.Count
    $techHave = $mapCount - $missingTechnical.Count
    $critHave = $mapCount - $missingCritical.Count

    # Post-lab map
    $postLabPath = Join-Path $labDir "map_data_post_$seqName.json"
    $hasPostLab = Test-Path $postLabPath

    # Algorithm directory
    $algoPath = Join-Path $algoDir $seqName
    $hasAlgo = Test-Path $algoPath

    # QFEP completeness
    $qfepOk = ($seqData.qfep -and $seqData.qfep.phase -and $seqData.qfep.contribution)

    # Nature
    $natureOk = ($seqData.nature -and $seqData.nature.element -and $seqData.nature.category)

    # Capability
    $capOk = ($seqData.capability -and $seqData.capability.perception)

    # Book/Wiki ready
    $bookReady = ($techHave -eq $mapCount) -and ($critHave -eq $mapCount) -and ($mapCount -gt 0) -and (-not $isDeferred)
    $wikiReady = ($blurbHave -eq $mapCount) -and ($summaryHave -eq $mapCount) -and ($mapCount -gt 0) -and (-not $isDeferred)

    return [PSCustomObject]@{
        Name = $seqName
        Type = $seqType
        Phase = $phase
        SpineOrder = if ($seqData.spine_order) { $seqData.spine_order } else { 99 }
        Deferred = $isDeferred
        MapCount = $mapCount
        Maps = $maps
        BlurbHave = $blurbHave
        SummaryHave = $summaryHave
        TechHave = $techHave
        CritHave = $critHave
        MissingBlurb = $missingBlurb
        MissingSummary = $missingSummary
        MissingTechnical = $missingTechnical
        MissingCritical = $missingCritical
        TotalMissingMd = $missingBlurb.Count + $missingSummary.Count + $missingTechnical.Count + $missingCritical.Count
        HasPostLab = $hasPostLab
        HasAlgo = $hasAlgo
        QfepOk = [bool]$qfepOk
        NatureOk = [bool]$natureOk
        CapOk = [bool]$capOk
        BookReady = $bookReady
        WikiReady = $wikiReady
    }
}

# ── Gather all sequence statuses ────────────────────────────────────────
$allStatuses = @()

# Spine sequences
if ($req.spine_sequences) {
    $req.spine_sequences.PSObject.Properties | ForEach-Object {
        $allStatuses += Get-SequenceStatus $_.Name $_.Value "spine"
    }
}

# Branch sequences
if ($req.branch_sequences) {
    $req.branch_sequences.PSObject.Properties | ForEach-Object {
        $allStatuses += Get-SequenceStatus $_.Name $_.Value "branch"
    }
}

# Sort: spine by order, branches by phase
$spineStatuses = @($allStatuses | Where-Object { $_.Type -eq "spine" } | Sort-Object SpineOrder)
$branchStatuses = @($allStatuses | Where-Object { $_.Type -eq "branch" } | Sort-Object Phase, Name)
$allStatuses = $spineStatuses + $branchStatuses

# ═══════════════════════════════════════════════════════════════════════════
# MODE: status
# ═══════════════════════════════════════════════════════════════════════════
if ($Mode -eq "status") {
    $totalSeq = $allStatuses.Count
    $totalMaps = ($allStatuses | Where-Object { -not $_.Deferred } | Measure-Object -Property MapCount -Sum).Sum
    $bookReady = @($allStatuses | Where-Object { $_.BookReady }).Count
    $wikiReady = @($allStatuses | Where-Object { $_.WikiReady }).Count
    $totalMissing = ($allStatuses | Measure-Object -Property TotalMissingMd -Sum).Sum
    $missingPostLab = @($allStatuses | Where-Object { -not $_.HasPostLab -and -not $_.Deferred }).Count

    Write-Output "=== PROJECT DASHBOARD STATUS ==="
    Write-Output ""
    Write-Output "Sequences:    $totalSeq ($($spineStatuses.Count) spine + $($branchStatuses.Count) branch)"
    Write-Output "Total maps:   $totalMaps"
    Write-Output "Book ready:   $bookReady / $totalSeq"
    Write-Output "Wiki ready:   $wikiReady / $totalSeq"
    Write-Output "Missing .md:  $totalMissing files"
    Write-Output "Missing post-lab: $missingPostLab"
    Write-Output ""
    Write-Output "--- Per-type missing ---"
    $mb = 0; $ms = 0; $mt = 0; $mc = 0
    foreach ($s in $allStatuses) {
        $mb += $s.MissingBlurb.Count
        $ms += $s.MissingSummary.Count
        $mt += $s.MissingTechnical.Count
        $mc += $s.MissingCritical.Count
    }
    Write-Output "  blurb.md:     $mb missing"
    Write-Output "  summary.md:   $ms missing"
    Write-Output "  technical.md: $mt missing"
    Write-Output "  critical.md:  $mc missing"
    Write-Output ""
    Write-Output "--- Phase breakdown ---"
    $phases = @("F_order","oscillation","E_entropy","lambda_edge","integration","synthesis")
    foreach ($p in $phases) {
        $pSeqs = @($allStatuses | Where-Object { $_.Phase -eq $p })
        $pBook = @($pSeqs | Where-Object { $_.BookReady }).Count
        $pNames = ($pSeqs | ForEach-Object { $_.Name }) -join ", "
        Write-Output "  $($p.PadRight(15)) $($pSeqs.Count) sequences, $pBook book-ready  [$pNames]"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: tasks
# ═══════════════════════════════════════════════════════════════════════════
elseif ($Mode -eq "tasks") {
    $tasks = @()

    foreach ($s in $allStatuses) {
        if ($s.Deferred) { continue }

        # Missing .md files — one task per sequence per type
        foreach ($mdType in @("blurb","summary","technical","critical")) {
            $missing = switch ($mdType) {
                "blurb"     { $s.MissingBlurb }
                "summary"   { $s.MissingSummary }
                "technical"  { $s.MissingTechnical }
                "critical"   { $s.MissingCritical }
            }
            if ($missing.Count -gt 0) {
                $isCritical = ($missing.Count -eq $s.MapCount)
                $tasks += [PSCustomObject]@{
                    Priority = if ($isCritical) { "CRITICAL" } else { "PARTIAL" }
                    Category = "text"
                    Sequence = $s.Name
                    Action = "write_md"
                    MdType = $mdType
                    Count = $missing.Count
                    Total = $s.MapCount
                    Maps = $missing -join ","
                    Description = "$($missing.Count)/$($s.MapCount) $mdType.md missing"
                }
            }
        }

        # Missing post-lab
        if (-not $s.HasPostLab) {
            $tasks += [PSCustomObject]@{
                Priority = "WARNING"
                Category = "post_lab"
                Sequence = $s.Name
                Action = "create_postlab"
                MdType = ""
                Count = 1
                Total = 1
                Maps = ""
                Description = "Missing post-lab map"
            }
        }
    }

    # Sort: CRITICAL first (desc by count), then PARTIAL, then WARNING
    $priorityMap = @{ "CRITICAL" = 0; "PARTIAL" = 1; "WARNING" = 2 }
    $tasks = $tasks | Sort-Object { $priorityMap[$_.Priority] }, { -$_.Count }

    if ($Format -eq "json") {
        $tasks | ConvertTo-Json -Depth 5
    }
    elseif ($Format -eq "csv") {
        Write-Output "PRIORITY|CATEGORY|SEQUENCE|ACTION|MD_TYPE|COUNT|TOTAL|DESCRIPTION|MAPS"
        foreach ($t in $tasks) {
            Write-Output "$($t.Priority)|$($t.Category)|$($t.Sequence)|$($t.Action)|$($t.MdType)|$($t.Count)|$($t.Total)|$($t.Description)|$($t.Maps)"
        }
    }
    else {
        Write-Output "=== ACTIONABLE TASKS ($($tasks.Count) total) ==="
        Write-Output ""
        $currentPriority = ""
        foreach ($t in $tasks) {
            if ($t.Priority -ne $currentPriority) {
                $currentPriority = $t.Priority
                Write-Output "--- $currentPriority ---"
            }
            $icon = switch ($t.Priority) { "CRITICAL" { "!!" } "PARTIAL" { "~~" } default { "--" } }
            Write-Output "  $icon $($t.Sequence.PadRight(22)) $($t.Description)"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: sequence (detail for one sequence)
# ═══════════════════════════════════════════════════════════════════════════
elseif ($Mode -eq "sequence") {
    if (-not $Name) {
        Write-Error "Use -Name <sequence_name> with -Mode sequence"
        exit 1
    }
    $s = $allStatuses | Where-Object { $_.Name -eq $Name }
    if (-not $s) {
        Write-Error "Sequence '$Name' not found"
        exit 1
    }

    if ($Format -eq "json") {
        $s | ConvertTo-Json -Depth 5
    }
    else {
        Write-Output "=== SEQUENCE: $($s.Name) ==="
        Write-Output "Type:       $($s.Type)"
        Write-Output "Phase:      $($s.Phase)"
        Write-Output "Deferred:   $($s.Deferred)"
        Write-Output "Maps:       $($s.MapCount)"
        Write-Output ""
        Write-Output "--- Text Coverage ---"
        Write-Output "  blurb.md:     $($s.BlurbHave)/$($s.MapCount)"
        Write-Output "  summary.md:   $($s.SummaryHave)/$($s.MapCount)"
        Write-Output "  technical.md: $($s.TechHave)/$($s.MapCount)"
        Write-Output "  critical.md:  $($s.CritHave)/$($s.MapCount)"
        Write-Output ""
        Write-Output "--- Layers ---"
        Write-Output "  Post-lab:   $(if ($s.HasPostLab) { 'OK' } else { 'MISSING' })"
        Write-Output "  Algorithm:  $(if ($s.HasAlgo) { 'OK' } else { 'MISSING' })"
        Write-Output "  QFEP:       $(if ($s.QfepOk) { 'OK' } else { 'INCOMPLETE' })"
        Write-Output "  Nature:     $(if ($s.NatureOk) { 'OK' } else { 'INCOMPLETE' })"
        Write-Output "  Capability: $(if ($s.CapOk) { 'OK' } else { 'INCOMPLETE' })"
        Write-Output "  Book ready: $(if ($s.BookReady) { 'YES' } else { 'NO' })"
        Write-Output "  Wiki ready: $(if ($s.WikiReady) { 'YES' } else { 'NO' })"

        if ($s.MissingBlurb.Count -gt 0) {
            Write-Output ""
            Write-Output "--- Missing blurb.md ($($s.MissingBlurb.Count)) ---"
            foreach ($m in $s.MissingBlurb) { Write-Output "  $mapsDir\$m\blurb.md" }
        }
        if ($s.MissingSummary.Count -gt 0) {
            Write-Output ""
            Write-Output "--- Missing summary.md ($($s.MissingSummary.Count)) ---"
            foreach ($m in $s.MissingSummary) { Write-Output "  $mapsDir\$m\summary.md" }
        }
        if ($s.MissingTechnical.Count -gt 0) {
            Write-Output ""
            Write-Output "--- Missing technical.md ($($s.MissingTechnical.Count)) ---"
            foreach ($m in $s.MissingTechnical) { Write-Output "  $mapsDir\$m\technical.md" }
        }
        if ($s.MissingCritical.Count -gt 0) {
            Write-Output ""
            Write-Output "--- Missing critical.md ($($s.MissingCritical.Count)) ---"
            foreach ($m in $s.MissingCritical) { Write-Output "  $mapsDir\$m\critical.md" }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: missing (flat list of all missing .md file paths)
# ═══════════════════════════════════════════════════════════════════════════
elseif ($Mode -eq "missing") {
    if ($Format -eq "csv") {
        Write-Output "SEQUENCE|MD_TYPE|MAP_NAME|FILE_PATH"
    }
    foreach ($s in $allStatuses) {
        if ($s.Deferred) { continue }
        foreach ($m in $s.MissingBlurb) {
            $path = "$mapsDir\$m\blurb.md"
            if ($Format -eq "csv") { Write-Output "$($s.Name)|blurb|$m|$path" }
            else { Write-Output "$path" }
        }
        foreach ($m in $s.MissingSummary) {
            $path = "$mapsDir\$m\summary.md"
            if ($Format -eq "csv") { Write-Output "$($s.Name)|summary|$m|$path" }
            else { Write-Output "$path" }
        }
        foreach ($m in $s.MissingTechnical) {
            $path = "$mapsDir\$m\technical.md"
            if ($Format -eq "csv") { Write-Output "$($s.Name)|technical|$m|$path" }
            else { Write-Output "$path" }
        }
        foreach ($m in $s.MissingCritical) {
            $path = "$mapsDir\$m\critical.md"
            if ($Format -eq "csv") { Write-Output "$($s.Name)|critical|$m|$path" }
            else { Write-Output "$path" }
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: postlab (missing/anomalous post-lab maps)
# ═══════════════════════════════════════════════════════════════════════════
elseif ($Mode -eq "postlab") {
    Write-Output "=== POST-LAB MAP STATUS ==="
    Write-Output ""
    foreach ($s in $allStatuses) {
        if ($s.Deferred) { continue }
        $postLabPath = Join-Path $labDir "map_data_post_$($s.Name).json"
        $status = if ($s.HasPostLab) { "OK" } else { "MISSING" }
        $icon = if ($s.HasPostLab) { "  " } else { "!!" }
        Write-Output "$icon $($s.Name.PadRight(25)) $status  $postLabPath"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: phase (group by QFEP phase)
# ═══════════════════════════════════════════════════════════════════════════
elseif ($Mode -eq "phase") {
    $phases = @("F_order","oscillation","E_entropy","lambda_edge","integration","synthesis")
    foreach ($p in $phases) {
        $pSeqs = @($allStatuses | Where-Object { $_.Phase -eq $p })
        if ($pSeqs.Count -eq 0) { continue }
        Write-Output "=== $($p.ToUpper()) ($($pSeqs.Count) sequences) ==="
        foreach ($s in $pSeqs) {
            $bookIcon = if ($s.BookReady) { "[BOOK]" } else { "      " }
            $wikiIcon = if ($s.WikiReady) { "[WIKI]" } else { "      " }
            $missing = $s.TotalMissingMd
            $missingStr = if ($missing -gt 0) { "$missing .md missing" } else { "complete" }
            Write-Output "  $($s.Name.PadRight(25)) $bookIcon $wikiIcon  $missingStr"
        }
        Write-Output ""
    }

    # Unphased
    $unphased = @($allStatuses | Where-Object { -not $_.Phase -or $_.Phase -eq "" })
    if ($unphased.Count -gt 0) {
        Write-Output "=== UNASSIGNED ($($unphased.Count) sequences) ==="
        foreach ($s in $unphased) {
            Write-Output "  $($s.Name.PadRight(25)) $($s.TotalMissingMd) .md missing"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: recommend (strategic next-action recommendations)
# ═══════════════════════════════════════════════════════════════════════════
elseif ($Mode -eq "recommend") {
    Write-Output "=== STRATEGIC RECOMMENDATIONS ==="
    Write-Output ""

    # ── Strategy 1: Near-wins — sequences closest to book/wiki ready ──
    Write-Output "--- NEAR WINS (fewest .md files to complete a sequence) ---"
    Write-Output "These sequences are closest to book-ready or wiki-ready."
    Write-Output "Completing them gives the most visible progress for least effort."
    Write-Output ""

    $nearWins = $allStatuses | Where-Object { -not $_.Deferred -and -not $_.BookReady -and $_.TotalMissingMd -gt 0 } |
        Sort-Object TotalMissingMd |
        Select-Object -First 8

    foreach ($s in $nearWins) {
        $remainBlurb = $s.MissingBlurb.Count
        $remainSumm = $s.MissingSummary.Count
        $remainTech = $s.MissingTechnical.Count
        $remainCrit = $s.MissingCritical.Count
        $breakdown = @()
        if ($remainBlurb -gt 0) { $breakdown += "${remainBlurb}b" }
        if ($remainSumm -gt 0) { $breakdown += "${remainSumm}s" }
        if ($remainTech -gt 0) { $breakdown += "${remainTech}t" }
        if ($remainCrit -gt 0) { $breakdown += "${remainCrit}c" }
        $breakdownStr = $breakdown -join " "
        Write-Output "  $($s.Name.PadRight(25)) $($s.TotalMissingMd.ToString().PadLeft(3)) files  ($breakdownStr)  [$($s.Phase)]"
    }

    # ── Strategy 2: Blurb-complete sequences needing summary/tech/crit ──
    Write-Output ""
    Write-Output "--- BLURB-COMPLETE (all blurbs exist, just need summary/tech/crit) ---"
    Write-Output "Blurbs provide the atmospheric context. These sequences have it."
    Write-Output "Writing summary/technical/critical for them is well-informed."
    Write-Output ""

    $blurbDone = $allStatuses | Where-Object {
        -not $_.Deferred -and -not $_.BookReady -and
        $_.BlurbHave -eq $_.MapCount -and $_.MapCount -gt 0
    } | Sort-Object TotalMissingMd

    if ($blurbDone.Count -eq 0) {
        Write-Output "  (none)"
    } else {
        foreach ($s in $blurbDone) {
            Write-Output "  $($s.Name.PadRight(25)) $($s.TotalMissingMd.ToString().PadLeft(3)) remaining  (s:$($s.MissingSummary.Count) t:$($s.MissingTechnical.Count) c:$($s.MissingCritical.Count))  [$($s.Phase)]"
        }
    }

    # ── Strategy 3: Phase completion — which QFEP phase is closest to done ──
    Write-Output ""
    Write-Output "--- PHASE COMPLETION (which QFEP phase is closest to all-book-ready) ---"
    Write-Output ""

    $phases = @("F_order","oscillation","E_entropy","lambda_edge","integration","synthesis")
    foreach ($p in $phases) {
        $pSeqs = @($allStatuses | Where-Object { $_.Phase -eq $p -and -not $_.Deferred })
        if ($pSeqs.Count -eq 0) { continue }
        $pBook = @($pSeqs | Where-Object { $_.BookReady }).Count
        $pMissing = ($pSeqs | Measure-Object -Property TotalMissingMd -Sum).Sum
        $pPct = [math]::Round(($pBook / $pSeqs.Count) * 100)
        Write-Output "  $($p.PadRight(15)) $pBook/$($pSeqs.Count) book-ready ($pPct%)  $pMissing .md remaining"
    }

    # ── Strategy 4: Post-lab gaps blocking the Lab forest ──
    $missingPL = @($allStatuses | Where-Object { -not $_.HasPostLab -and -not $_.Deferred })
    if ($missingPL.Count -gt 0) {
        Write-Output ""
        Write-Output "--- POST-LAB GAPS (blocking Lab forest progression) ---"
        Write-Output "These sequences have no post-lab map. The Lab cannot evolve past them."
        Write-Output ""
        foreach ($s in $missingPL) {
            Write-Output "  $($s.Name.PadRight(25)) [$($s.Phase)]  branches_from: $(if ($s.Type -eq 'branch') { 'yes' } else { 'spine' })"
        }
    }

    # ── Strategy 5: Concrete next session suggestion ──
    Write-Output ""
    Write-Output "--- SUGGESTED NEXT SESSION ---"
    Write-Output ""

    # Find the single best sequence to work on
    # Priority: near-win with blurbs done, smallest gap, spine before branch
    $bestCandidate = $allStatuses | Where-Object {
        -not $_.Deferred -and -not $_.BookReady -and $_.TotalMissingMd -gt 0
    } | Sort-Object @{Expression={$_.BlurbHave -eq $_.MapCount}; Descending=$true},
                     @{Expression={$_.TotalMissingMd}; Ascending=$true},
                     @{Expression={$_.Type -eq "spine"}; Descending=$true} |
        Select-Object -First 1

    if ($bestCandidate) {
        $bc = $bestCandidate
        Write-Output "  SEQUENCE: $($bc.Name)"
        Write-Output "  PHASE:    $($bc.Phase)"
        Write-Output "  MAPS:     $($bc.MapCount)"
        Write-Output "  MISSING:  $($bc.TotalMissingMd) files ($($bc.MissingBlurb.Count)b $($bc.MissingSummary.Count)s $($bc.MissingTechnical.Count)t $($bc.MissingCritical.Count)c)"
        Write-Output ""
        Write-Output "  WORKFLOW:"
        if ($bc.MissingBlurb.Count -gt 0) {
            Write-Output "    1. Write $($bc.MissingBlurb.Count) blurb.md files first (atmospheric intro, ~1 paragraph)"
        }
        if ($bc.MissingSummary.Count -gt 0) {
            $step = if ($bc.MissingBlurb.Count -gt 0) { "2" } else { "1" }
            Write-Output "    $step. Write $($bc.MissingSummary.Count) summary.md files (spatial layout, key elements, learning sequence)"
        }
        if ($bc.MissingTechnical.Count -gt 0) {
            $step = if ($bc.MissingBlurb.Count -gt 0 -and $bc.MissingSummary.Count -gt 0) { "3" } elseif ($bc.MissingBlurb.Count -gt 0 -or $bc.MissingSummary.Count -gt 0) { "2" } else { "1" }
            Write-Output "    $step. Write $($bc.MissingTechnical.Count) technical.md files (code examples, implementation details)"
        }
        if ($bc.MissingCritical.Count -gt 0) {
            Write-Output "    Last. Write $($bc.MissingCritical.Count) critical.md files (queer theory, philosophy, critical reflection)"
        }
        Write-Output ""
        Write-Output "  CONTEXT SOURCES:"
        Write-Output "    - Map data: commons/maps/<MapName>/map_data.json"
        Write-Output "    - Algorithms: algorithms/$($bc.Name)/"
        Write-Output "    - Existing blurbs: commons/maps/<MapName>/blurb.md"
        Write-Output "    - QFEP entry: sequence_requirements.json -> $($bc.Type)_sequences.$($bc.Name).qfep"
        Write-Output "    - Use: .\project_dashboard_cli.ps1 -Mode context -Name <MapName>"
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: context (gather all sources for writing .md files for a map)
# ═══════════════════════════════════════════════════════════════════════════
elseif ($Mode -eq "context") {
    if (-not $Name) {
        Write-Error "Use -Name <map_name> with -Mode context"
        exit 1
    }

    $mapDir = Join-Path $mapsDir $Name
    if (-not (Test-Path $mapDir)) {
        Write-Error "Map directory not found: $mapDir"
        exit 1
    }

    Write-Output "=== CONTEXT FOR: $Name ==="
    Write-Output ""

    # Which sequence does this map belong to?
    $ownerSeq = $null
    foreach ($s in $allStatuses) {
        if ($s.Maps -contains $Name) {
            $ownerSeq = $s
            break
        }
    }

    if ($ownerSeq) {
        Write-Output "Sequence:   $($ownerSeq.Name)"
        Write-Output "Phase:      $($ownerSeq.Phase)"
        Write-Output "Type:       $($ownerSeq.Type)"
        Write-Output "Position:   map $(($ownerSeq.Maps).IndexOf($Name) + 1) of $($ownerSeq.MapCount)"
        $prevMap = $null; $nextMap = $null
        $idx = ($ownerSeq.Maps).IndexOf($Name)
        if ($idx -gt 0) { $prevMap = $ownerSeq.Maps[$idx - 1] }
        if ($idx -lt $ownerSeq.Maps.Count - 1) { $nextMap = $ownerSeq.Maps[$idx + 1] }
        if ($prevMap) { Write-Output "Previous:   $prevMap" }
        if ($nextMap) { Write-Output "Next:       $nextMap" }
    } else {
        Write-Output "Sequence:   (not found in any sequence)"
    }
    Write-Output ""

    # Existing files in this map directory
    Write-Output "--- EXISTING FILES ---"
    $existingFiles = Get-ChildItem $mapDir -File | ForEach-Object { $_.Name }
    foreach ($f in $existingFiles) {
        $size = (Get-Item (Join-Path $mapDir $f)).Length
        Write-Output "  $f ($size bytes)"
    }
    Write-Output ""

    # What's missing
    Write-Output "--- MISSING .MD FILES ---"
    $hasMissing = $false
    foreach ($mdType in @("blurb","summary","technical","critical")) {
        $mdPath = Join-Path $mapDir "$mdType.md"
        if (-not (Test-Path $mdPath)) {
            Write-Output "  NEEDS: $mdType.md"
            $hasMissing = $true
        }
    }
    if (-not $hasMissing) { Write-Output "  (all present)" }
    Write-Output ""

    # QFEP context from requirements
    if ($ownerSeq) {
        $seqName = $ownerSeq.Name
        $seqType = $ownerSeq.Type
        $seqSection = "${seqType}_sequences"
        $seqReq = $null
        if ($req.$seqSection -and $req.$seqSection.$seqName) {
            $seqReq = $req.$seqSection.$seqName
        }

        if ($seqReq) {
            Write-Output "--- QFEP CONTEXT ---"
            if ($seqReq.qfep) {
                Write-Output "  Phase:        $($seqReq.qfep.phase)"
                Write-Output "  Contribution: $($seqReq.qfep.contribution)"
                if ($seqReq.qfep.builds_on) { Write-Output "  Builds on:    $($seqReq.qfep.builds_on -join ', ')" }
            }
            Write-Output ""

            Write-Output "--- NATURE CONTEXT ---"
            if ($seqReq.nature) {
                Write-Output "  Element:      $($seqReq.nature.element)"
                Write-Output "  Category:     $($seqReq.nature.category)"
                if ($seqReq.nature.forest_note) { Write-Output "  Forest note:  $($seqReq.nature.forest_note)" }
            }
            Write-Output ""

            Write-Output "--- CAPABILITY CONTEXT ---"
            if ($seqReq.capability) {
                Write-Output "  Perception:   $($seqReq.capability.perception)"
                if ($seqReq.capability.capability_grant) { Write-Output "  Capability:   $($seqReq.capability.capability_grant)" }
                if ($seqReq.capability.relation) { Write-Output "  Relation:     $($seqReq.capability.relation)" }
            }
            Write-Output ""

            Write-Output "--- APPLICATION CONTEXT ---"
            if ($seqReq.application) {
                if ($seqReq.application.work_package) { Write-Output "  Work package: $($seqReq.application.work_package)" }
                if ($seqReq.application.queer_dimension) { Write-Output "  Queer dim:    $($seqReq.application.queer_dimension)" }
            }
        }
    }

    # Algorithm source files
    Write-Output ""
    Write-Output "--- ALGORITHM SOURCES ---"
    if ($ownerSeq) {
        $algoPath = Join-Path $algoDir $ownerSeq.Name
        if (Test-Path $algoPath) {
            $gdFiles = @(Get-ChildItem $algoPath -Recurse -Filter "*.gd" -File)
            $readmeFiles = @(Get-ChildItem $algoPath -Recurse -Filter "README.md" -File)
            Write-Output "  Directory: $algoPath"
            Write-Output "  .gd files: $($gdFiles.Count)"
            Write-Output "  READMEs:   $($readmeFiles.Count)"
            if ($readmeFiles.Count -gt 0) {
                Write-Output "  README locations:"
                foreach ($r in $readmeFiles) {
                    Write-Output "    $($r.FullName)"
                }
            }
        } else {
            Write-Output "  (no dedicated algorithm directory)"
        }
    }

    # Neighboring maps context
    if ($prevMap) {
        Write-Output ""
        Write-Output "--- PREVIOUS MAP: $prevMap ---"
        $prevBlurb = Join-Path $mapsDir "$prevMap\blurb.md"
        if (Test-Path $prevBlurb) {
            Write-Output "  Has blurb.md (read for tonal continuity)"
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# MODE: nearwin (sequences closest to completion)
# ═══════════════════════════════════════════════════════════════════════════
elseif ($Mode -eq "nearwin") {
    Write-Output "=== NEAR WINS - Closest to Book/Wiki Ready ==="
    Write-Output ""
    Write-Output "Sorted by total missing .md files (ascending). Complete these first."
    Write-Output ""

    $candidates = $allStatuses | Where-Object {
        -not $_.Deferred -and -not $_.BookReady -and $_.TotalMissingMd -gt 0
    } | Sort-Object TotalMissingMd

    $hdrSeq = "Sequence".PadRight(25)
    $hdrMiss = "Missing".PadLeft(7)
    $hdrB = "Blurb".PadLeft(5)
    $hdrS = "Summ".PadLeft(5)
    $hdrT = "Tech".PadLeft(5)
    $hdrC = "Crit".PadLeft(5)
    Write-Output "  $hdrSeq $hdrMiss  $hdrB $hdrS $hdrT $hdrC  Phase"
    $sep = "-" * 25
    $sep7 = "-" * 7
    $sep5 = "-" * 5
    $sep12 = "-" * 12
    Write-Output "  $sep $sep7  $sep5 $sep5 $sep5 $sep5  $sep12"

    foreach ($s in $candidates) {
        $bMiss = $s.MissingBlurb.Count
        $sMiss = $s.MissingSummary.Count
        $tMiss = $s.MissingTechnical.Count
        $cMiss = $s.MissingCritical.Count
        if ($bMiss -eq 0) { $bStr = "  OK " } else { $bStr = "$bMiss".PadLeft(5) }
        if ($sMiss -eq 0) { $sStr = "  OK " } else { $sStr = "$sMiss".PadLeft(5) }
        if ($tMiss -eq 0) { $tStr = "  OK " } else { $tStr = "$tMiss".PadLeft(5) }
        if ($cMiss -eq 0) { $cStr = "  OK " } else { $cStr = "$cMiss".PadLeft(5) }
        $nameStr = $s.Name.PadRight(25)
        $missStr = $s.TotalMissingMd.ToString().PadLeft(7)
        Write-Output "  $nameStr $missStr  $bStr $sStr $tStr $cStr  $($s.Phase)"
    }
}

else {
    Write-Error "Unknown mode: $Mode. Use: status, tasks, sequence, missing, postlab, phase, recommend, context, nearwin"
}
