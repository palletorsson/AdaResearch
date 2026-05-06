# analyze_gdscript.ps1 - Find GDScript warnings (shadowed variables, unused vars, etc.)
# Usage: .\analyze_gdscript.ps1

$projectRoot = "C:\Users\palle\Documents\GitHub\AdaResearch_46"

# Node3D properties that can be shadowed
$node3dProps = @("position", "rotation", "scale", "transform", "visible", "name")
$node2dProps = @("position", "rotation", "scale", "transform", "visible", "name", "z_index")
$controlProps = @("position", "size", "visible", "name")

Write-Host "🔍 Analyzing GDScript files for warnings..." -ForegroundColor Cyan
Write-Host ""

$results = @{
    shadowed = @()
    unused = @()
}

Get-ChildItem -Path $projectRoot -Recurse -Filter "*.gd" | 
    Where-Object { $_.FullName -notmatch "\.godot|android\\build" } |
    ForEach-Object {
        $file = $_
        $relativePath = $file.FullName.Replace($projectRoot + "\", "")
        $lines = Get-Content $file.FullName
        
        $lineNum = 0
        foreach ($line in $lines) {
            $lineNum++
            
            # Check for shadowed variables (var position, var rotation, var scale)
            foreach ($prop in $node3dProps) {
                if ($line -match "^\s*var\s+$prop\s*[=:]") {
                    $results.shadowed += [PSCustomObject]@{
                        File = $relativePath
                        Line = $lineNum
                        Property = $prop
                        Code = $line.Trim()
                    }
                }
            }
            
            # Check for variables declared but potentially unused (basic check)
            # This is a simplified check - looks for var declarations
            if ($line -match "^\s*var\s+(\w+)\s*=" -and $line -notmatch "^\s*var\s+_") {
                $varName = $matches[1]
                # Check if it's used elsewhere in the file (very basic)
                $restOfFile = ($lines | Select-Object -Skip $lineNum) -join "`n"
                $usagePattern = "\b$varName\b"
                if ($restOfFile -notmatch $usagePattern) {
                    # Might be unused - flag for review
                    # Skip common false positives
                    if ($varName -notin @("i", "j", "k", "x", "y", "z", "result", "ret", "err")) {
                        $results.unused += [PSCustomObject]@{
                            File = $relativePath
                            Line = $lineNum
                            Variable = $varName
                            Code = $line.Trim()
                        }
                    }
                }
            }
        }
    }

# Report shadowed variables
Write-Host "⚠️  SHADOWED VARIABLES (local var shadows Node3D property)" -ForegroundColor Yellow
Write-Host "   These cause SHADOWED_VARIABLE_BASE_CLASS warnings in editor" -ForegroundColor Gray
Write-Host ""

if ($results.shadowed.Count -eq 0) {
    Write-Host "   ✅ None found!" -ForegroundColor Green
} else {
    $grouped = $results.shadowed | Group-Object Property | Sort-Object Count -Descending
    foreach ($group in $grouped) {
        Write-Host "   $($group.Name): $($group.Count) instances" -ForegroundColor Yellow
        $group.Group | Select-Object -First 5 | ForEach-Object {
            Write-Host "      $($_.File):$($_.Line)" -ForegroundColor Gray
        }
        if ($group.Count -gt 5) {
            Write-Host "      ... and $($group.Count - 5) more" -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   Shadowed variables: $($results.shadowed.Count)" -ForegroundColor $(if ($results.shadowed.Count -gt 0) { "Yellow" } else { "Green" })

# Save full report
$reportPath = "$projectRoot\doc\GDSCRIPT_ANALYSIS.md"
$report = @"
# GDScript Analysis Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Shadowed Variables ($($results.shadowed.Count) total)

These local variables shadow Node3D/Node2D base class properties.

| File | Line | Property | Code |
|------|------|----------|------|
"@

foreach ($item in $results.shadowed | Sort-Object File, Line) {
    $code = $item.Code -replace '\|', '\|'
    $report += "| $($item.File) | $($item.Line) | ``$($item.Property)`` | ``$code`` |`n"
}

$report | Out-File $reportPath -Encoding utf8
Write-Host ""
Write-Host "📄 Full report saved to: doc\GDSCRIPT_ANALYSIS.md" -ForegroundColor Cyan
