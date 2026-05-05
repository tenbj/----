param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,
    [Parameter(Mandatory=$true)]
    [string]$Base64Content
)
$enc = [System.Text.UTF8Encoding]::new($true)
$bytes = [System.Convert]::FromBase64String($Base64Content)
$text = [System.Text.UTF8Encoding]::new($false).GetString($bytes)
[System.IO.File]::WriteAllText($TargetPath, $text, $enc)
Write-Host "Written OK: $TargetPath"
