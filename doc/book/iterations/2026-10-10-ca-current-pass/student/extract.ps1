$ErrorActionPreference = 'Stop'
$packetRoot = Join-Path $PSScriptRoot '../packet'
$order = Get-Content -Raw -LiteralPath (Join-Path $packetRoot 'order.json') | ConvertFrom-Json
$manifest = @()
foreach ($hall in $order) {
    $tutorial = Get-Content -Raw -LiteralPath (Join-Path $packetRoot "$hall/tutorial.md")
    foreach ($variant in @('original','variation')) {
        $dest = Join-Path $PSScriptRoot "$hall/$variant"
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        foreach ($block in [regex]::Matches($tutorial, '(?s)<!-- student-code:([^>]+) -->\s*```gdscript\r?\n(.*?)```')) {
            $name = $block.Groups[1].Value
            $code = $block.Groups[2].Value
            [System.IO.File]::WriteAllText((Join-Path $dest $name), $code, [System.Text.UTF8Encoding]::new($false))
            if ($variant -eq 'original') {
                $manifest += [pscustomobject]@{ hall=$hall; filename=$name; sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $dest $name)).Hash }
            }
        }
    }
}
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'extraction_manifest.json')
$manifest | Format-Table -AutoSize
