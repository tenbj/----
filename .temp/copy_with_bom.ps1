param(
    [string]$Src,
    [string]$Dst
)
$enc_bom   = [System.Text.UTF8Encoding]::new($true)
$enc_nobom = [System.Text.UTF8Encoding]::new($false)
$text = [System.IO.File]::ReadAllText($Src, $enc_nobom)
[System.IO.File]::WriteAllText($Dst, $text, $enc_bom)
$b = [System.IO.File]::ReadAllBytes($Dst)
Write-Host ("BOM bytes: " + $b[0] + " " + $b[1] + " " + $b[2])
Write-Host "Done: $Dst"
