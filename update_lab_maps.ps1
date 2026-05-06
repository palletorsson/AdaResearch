$paths = @("commons/maps/Lab", "commons/maps/AdvancedLaboratory*")
$files = Get-ChildItem -Path $paths -Recurse -Include "map_data*.json"

foreach ($file in $files) {
    Write-Host "Processing $($file.FullName)"
    $content = Get-Content $file.FullName -Raw
    
    # Check if settings exists
    if ($content -match '"settings"\s*:\s*\{') {
        # Check if enter_type already exists
        if ($content -match '"enter_type"\s*:\s*"[^"]*"') {
            # Update existing
            $content = $content -replace '"enter_type"\s*:\s*"[^"]*"', '"enter_type": "corridor"'
            Write-Host "  Updated existing enter_type"
        } else {
            # Insert new
            $content = $content -replace '"settings"\s*:\s*\{', '"settings": { "enter_type": "corridor",'
            Write-Host "  Inserted new enter_type"
        }
        Set-Content $file.FullName $content
    } else {
        Write-Host "  Skipped: No settings object found"
    }
}
