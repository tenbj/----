$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wsRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..\..")).Path
$historySkills = Join-Path $wsRoot ".history\.agents\skills"
$srcDir = Get-ChildItem $historySkills -Directory | Where-Object { $_.Name -like "*_20260504211144" } | Select-Object -First 1
if (-not $srcDir) { Write-Error "Backup not found"; exit 1 }
$src = Join-Path $srcDir.FullName "scripts\new_project.ps1"
$dst = Join-Path $scriptDir "new_project.ps1"
$c = [System.IO.File]::ReadAllText($src)
[System.IO.File]::WriteAllText($dst, $c, [System.Text.UTF8Encoding]::new($true))
Write-Host "Restored OK"
