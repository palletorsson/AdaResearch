$mapsDir = 'C:\Users\palle\Documents\GitHub\AdaResearch_46\commons\maps'
$seqDir = Join-Path $mapsDir 'sequences'

# Get all map folders that have each .md file type
$allBlurbs = @((Get-ChildItem -Path $mapsDir -Recurse -Filter 'blurb.md' -File).DirectoryName | ForEach-Object { Split-Path $_ -Leaf })
$allSummaries = @((Get-ChildItem -Path $mapsDir -Recurse -Filter 'summary.md' -File).DirectoryName | ForEach-Object { Split-Path $_ -Leaf })
$allTechnicals = @((Get-ChildItem -Path $mapsDir -Recurse -Filter 'technical.md' -File).DirectoryName | ForEach-Object { Split-Path $_ -Leaf })
$allCriticals = @((Get-ChildItem -Path $mapsDir -Recurse -Filter 'critical.md' -File).DirectoryName | ForEach-Object { Split-Path $_ -Leaf })

Write-Output "SEQUENCE|TOTAL_MAPS|BLURB|SUMMARY|TECHNICAL|CRITICAL|MISSING_BLURB|MISSING_SUMMARY|MISSING_TECHNICAL|MISSING_CRITICAL"

$seqNames = @('primitives','transformation','color','forces','array_tutorial','wavefunctions','randomness','noise','cellularautomata','fractals','lsystems','proceduralgeneration','softbodies','swarmintelligence','machinelearning','foundationscrisis','qfeplaboratory','postfoundationscrisis','graphtheory','meshes','datastructures','computationalgeometry','physicssimulation','proceduralaudio','patterngeneration','recursiveemergence','artmathematics','searchpathfinding','resourcemanagement','spatial_partitioning','constraint_solvers','isosurfaces','higher_dimensions','grammar_systems','particles','joints','bricolage','biological_growth','structure')

foreach ($seq in $seqNames) {
    $seqFile = Join-Path $seqDir ($seq + '.json')
    if (Test-Path $seqFile) {
        $content = Get-Content $seqFile -Raw | ConvertFrom-Json

        # Navigate to sequences.{name}.maps - the maps are a simple string array
        $seqData = $content.sequences.PSObject.Properties | Select-Object -First 1
        if ($seqData -and $seqData.Value.maps) {
            $maps = @($seqData.Value.maps)
        } else {
            # Try direct maps property
            if ($content.maps) {
                $maps = @($content.maps)
            } else {
                $maps = @()
            }
        }

        $mapCount = $maps.Count

        $missingB = @()
        $missingS = @()
        $missingT = @()
        $missingC = @()

        foreach ($m in $maps) {
            if ($allBlurbs -notcontains $m) { $missingB += $m }
            if ($allSummaries -notcontains $m) { $missingS += $m }
            if ($allTechnicals -notcontains $m) { $missingT += $m }
            if ($allCriticals -notcontains $m) { $missingC += $m }
        }

        $b = $mapCount - $missingB.Count
        $s = $mapCount - $missingS.Count
        $t = $mapCount - $missingT.Count
        $c = $mapCount - $missingC.Count

        $mbStr = ($missingB -join ',')
        $msStr = ($missingS -join ',')
        $mtStr = ($missingT -join ',')
        $mcStr = ($missingC -join ',')

        Write-Output "$seq|$mapCount|$b|$s|$t|$c|$mbStr|$msStr|$mtStr|$mcStr"
    } else {
        Write-Output "$seq|NOT_FOUND"
    }
}
