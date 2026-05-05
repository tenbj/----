$item = Get-Item '.agents\skills\记忆管理\scripts\remove.ps1'
$p = $item.FullName
$c = [System.IO.File]::ReadAllText($p, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($p, $c, [System.Text.UTF8Encoding]::new($true))
$b = [System.IO.File]::ReadAllBytes($p)
if ($b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
    Write-Host "BOM OK: $p"
} else {
    Write-Host "BOM FAIL: $p"
}
