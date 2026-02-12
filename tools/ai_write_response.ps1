# ai_write_response.ps1
# Writes an AI response to the Godot AI panel.
# Usage: powershell -File tools\ai_write_response.ps1 -Text "Done, bass is darker now" -Changes "bass_filter: 2400->1400"

param(
    [Parameter(Mandatory=$true)][string]$Text,
    [string]$Changes = ""
)

$responseFile = "$env:APPDATA\Godot\app_userdata\Ada Research Zero One\ai_response.json"

$changesArray = @()
if ($Changes) {
    foreach ($c in ($Changes -split ';')) {
        $parts = $c.Trim() -split ':', 2
        $changesArray += @{
            file = if ($parts.Length -gt 1) { $parts[0].Trim() } else { "" }
            description = if ($parts.Length -gt 1) { $parts[1].Trim() } else { $parts[0].Trim() }
        }
    }
}

$response = @{
    role = "assistant"
    text = $Text
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    changes = $changesArray
} | ConvertTo-Json -Depth 3

$response | Out-File -FilePath $responseFile -Encoding utf8 -NoNewline
Write-Host "Response written to $responseFile" -ForegroundColor Green
