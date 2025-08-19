# PowerShell script to rename algorithm directories to lowercase
# This script renames PascalCase directories to lowercase with underscores

Write-Host "Starting algorithm directory renaming process..." -ForegroundColor Green

# Define the mappings: old name -> new name
$renameMappings = @{
    "AdvancedLaboratory" = "advanced_laboratory"
    "SwarmIntelligence" = "swarm_intelligence"
    "ProceduralGeneration" = "procedural_generation"
    "GraphTheory" = "graph_theory"
    "CriticalAlgorithms" = "critical_algorithms"
    "MachineLearning" = "machine_learning"
    "RecursiveEmergence" = "recursive_emergence"
}

# Change to the algorithms directory
Set-Location "algorithms"

# Process each mapping
foreach ($oldName in $renameMappings.Keys) {
    $newName = $renameMappings[$oldName]
    
    if (Test-Path $oldName) {
        Write-Host "Renaming '$oldName' to '$newName'..." -ForegroundColor Yellow
        
        try {
            # Use Move-Item to rename the directory
            Move-Item -Path $oldName -Destination $newName -ErrorAction Stop
            Write-Host "✓ Successfully renamed '$oldName' to '$newName'" -ForegroundColor Green
        }
        catch {
            Write-Host "✗ Error renaming '$oldName': $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Directory '$oldName' not found, skipping..." -ForegroundColor Gray
    }
}

Write-Host "`nRenaming process completed!" -ForegroundColor Green
Write-Host "Current algorithm directory structure:" -ForegroundColor Cyan

# Show the new directory structure
Get-ChildItem -Directory | Sort-Object Name | ForEach-Object {
    Write-Host "  $_" -ForegroundColor White
}

Write-Host "`nAll PascalCase directories have been renamed to lowercase with underscores." -ForegroundColor Green
