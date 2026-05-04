$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$npPath = Join-Path $scriptDir "new_project.ps1"
$content = [System.IO.File]::ReadAllText($npPath)

$s_mulu       = [System.Text.Encoding]::UTF8.GetString(@(0xE7,0x9B,0xAE,0xE5,0xBD,0x95))
$s_dot        = [System.Text.Encoding]::UTF8.GetString(@(0xC2,0xB7))
$s_sub_desc   = [System.Text.Encoding]::UTF8.GetString(@(0xE6,0x9C,0xAC,0xE5,0xAD,0x90,0xE9,0xA1,0xB9,0xE7,0x9B,0xAE,0xE5,0x86,0x85,0xE6,0x89,0x80,0xE6,0x9C,0x89,0xE5,0x86,0x85,0xE5,0xAE,0xB9,0xE6,0x96,0x87,0xE4,0xBB,0xB6,0xE7,0x9A,0x84,0xE7,0xB4,0xA2,0xE5,0xBC,0x95,0xE3,0x80,0x82))
$s_file       = [System.Text.Encoding]::UTF8.GetString(@(0xE6,0x96,0x87,0xE4,0xBB,0xB6))
$s_desc       = [System.Text.Encoding]::UTF8.GetString(@(0xE8,0xAF,0xB4,0xE6,0x98,0x8E))
$s_first      = [System.Text.Encoding]::UTF8.GetString(@(0xE9,0xA6,0x96,0xE6,0xAC,0xA1,0xE8,0x90,0xBD,0xE7,0x9B,0x98))
$s_last       = [System.Text.Encoding]::UTF8.GetString(@(0xE6,0x9C,0x80,0xE8,0xBF,0x91,0xE6,0x9B,0xB4,0xE6,0x96,0xB0))
$s_ph         = [System.Text.Encoding]::UTF8.GetString(@(0xE5,0xBE,0x85,0xE6,0x96,0xB0,0xE5,0xA2,0x9E,0xE6,0x96,0x87,0xE4,0xBB,0xB6,0xE5,0x90,0x8E,0xE5,0xA1,0xAB,0xE5,0x86,0x99))
$s_ver_record = [System.Text.Encoding]::UTF8.GetString(@(0xE7,0x89,0x88,0xE6,0x9C,0xAC,0xE8,0xAE,0xB0,0xE5,0xBD,0x95))

$catalogCodeTemplate = @'

$todayDate = Get-Date -Format "yyyy-MM-dd"
$catalogPath = Join-Path $projectPath "MULU_PH.md"
$catalogContent = @"
# MULU_PH DOT_PH $Topic

> SUB_DESC_PH

| # | FILE_PH | DESC_PH | FIRST_PH | LAST_PH |
|---|------|------|---------|---------|
| PH_PH | | | |

"@
[System.IO.File]::WriteAllText($catalogPath, $catalogContent, $utf8WithBom)
Write-Host "[OK] Created catalog: $catalogPath"

'@

$catalogCodeTemplate = $catalogCodeTemplate.Replace("MULU_PH.md", $s_mulu + ".md")
$catalogCodeTemplate = $catalogCodeTemplate.Replace("MULU_PH DOT_PH", $s_mulu + " " + $s_dot)
$catalogCodeTemplate = $catalogCodeTemplate.Replace("SUB_DESC_PH", $s_sub_desc)
$catalogCodeTemplate = $catalogCodeTemplate.Replace("FILE_PH", $s_file)
$catalogCodeTemplate = $catalogCodeTemplate.Replace("DESC_PH", $s_desc)
$catalogCodeTemplate = $catalogCodeTemplate.Replace("FIRST_PH", $s_first)
$catalogCodeTemplate = $catalogCodeTemplate.Replace("LAST_PH", $s_last)
$catalogCodeTemplate = $catalogCodeTemplate.Replace("PH_PH", $s_ph)

$insertMarker = 'Write-Host "[OK] Created version record: $versionRecordPath"'
$content = $content.Replace($insertMarker, ($insertMarker + $catalogCodeTemplate))

[System.IO.File]::WriteAllText($npPath, $content, [System.Text.UTF8Encoding]::new($true))
Write-Host "new_project.ps1 updated OK"
