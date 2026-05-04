$path = Join-Path $PSScriptRoot "new_project.ps1"
$c = [System.IO.File]::ReadAllText($path)

$c = $c.Replace("Also initializes 版本记录.md inside.", "Also initializes 版本记录.md and 目录.md inside.")

$oldBlock = @'
Write-Host "[OK] Created version record: $versionRecordPath"

Write-Host ""
Write-Host "=========================================="
'@

$newBlock = @'
Write-Host "[OK] Created version record: $versionRecordPath"

$todayDate = Get-Date -Format "yyyy-MM-dd"
$catalogPath = Join-Path $projectPath "目录.md"
$catalogContent = @"
# 目录 · $Topic

> 本子项目内所有内容文件的索引。

| # | 文件 | 说明 | 首次落盘 | 最近更新 |
|---|------|------|---------|---------|
| （待新增文件后填写） | | | |

"@
[System.IO.File]::WriteAllText($catalogPath, $catalogContent, $utf8WithBom)
Write-Host "[OK] Created catalog: $catalogPath"

Write-Host ""
Write-Host "=========================================="
'@

$c = $c.Replace($oldBlock, $newBlock)

[System.IO.File]::WriteAllText($path, $c, [System.Text.UTF8Encoding]::new($true))
Write-Host "[OK] new_project.ps1 updated"
