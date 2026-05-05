param()
$skillPath = Join-Path (Get-Location) ".agents\skills\记忆管理\scripts"
Get-ChildItem -LiteralPath $skillPath -Filter "*.ps1" | ForEach-Object {
    $p = $_.FullName
    $c = [System.IO.File]::ReadAllText($p)
    [System.IO.File]::WriteAllText($p, $c, [System.Text.UTF8Encoding]::new($true))
    Write-Host ("BOM fixed: " + $_.Name)
}
