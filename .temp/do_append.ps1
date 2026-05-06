$targetPath = (Get-ChildItem -Path ".memory\对话记录\" -Filter "05_*.md" | Select-Object -First 1).FullName
$scriptContent = [System.IO.File]::ReadAllText(".temp\append_memory.ps1", [System.Text.Encoding]::UTF8)

$startIndex = $scriptContent.IndexOf("## 2026")
$endIndex = $scriptContent.IndexOf("---", $startIndex) + 3

$payload = "`r`n" + $scriptContent.Substring($startIndex, $endIndex - $startIndex) + "`r`n"

[System.IO.File]::AppendAllText($targetPath, $payload, [System.Text.Encoding]::UTF8)
Write-Host "Append successful to $targetPath"
