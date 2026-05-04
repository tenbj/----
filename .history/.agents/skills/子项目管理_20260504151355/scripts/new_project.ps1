<#
.SYNOPSIS
    Create a new sub-project folder under output/
.DESCRIPTION
    Creates a versioned sub-project directory following naming convention:
    output\{Number}_{Topic}_v1.0.0
    Also initializes 版本记录.md inside.
.PARAMETER Topic
    The topic/domain name in Chinese (required)
.PARAMETER OutputRoot
    The root output directory. Defaults to the workspace output folder.
.EXAMPLE
    .\new_project.ps1 -Topic "减肥第一性原理"
    # Creates: output\01_减肥第一性原理_v1.0.0\
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Topic,

    [Parameter(Mandatory=$false)]
    [string]$OutputRoot = ""
)

if ($OutputRoot -eq "") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $searchDir = $scriptDir
    $workspaceRoot = $null
    while ($searchDir) {
        if ((Test-Path (Join-Path $searchDir "output")) -and (Test-Path (Join-Path $searchDir ".history"))) {
            $workspaceRoot = $searchDir
            break
        }
        $parent = Split-Path $searchDir -Parent
        if ($parent -eq $searchDir) { break }
        $searchDir = $parent
    }
    if (-not $workspaceRoot) {
        Write-Error "Workspace root not found. Please specify -OutputRoot explicitly."
        exit 1
    }
    $OutputRoot = Join-Path $workspaceRoot "output"
}

$existingProjectNumbers = @(
    Get-ChildItem -Path $OutputRoot -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            if ($_.Name -match '^(\d+)_') {
                [int]$matches[1]
            }
        }
) | Sort-Object -Descending

$nextProjectNumber = if ($existingProjectNumbers.Count -gt 0) {
    $existingProjectNumbers[0] + 1
} else {
    1
}

$projectNumber = "{0:D2}" -f $nextProjectNumber

$folderName = "${projectNumber}_${Topic}_v1.0.0"
$projectPath = Join-Path $OutputRoot $folderName

if (Test-Path $projectPath) {
    Write-Error "Folder already exists: $projectPath"
    exit 1
}

New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
Write-Host "[OK] Created project folder: $projectPath"

$displayTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$versionRecordPath = Join-Path $projectPath "版本记录.md"
$versionRecordContent = @"
# 版本记录 · $Topic

> 记录子项目的版本变更历史。

---

## v1.0.0 ($displayTimestamp)

**变更类型**：MAJOR
**创建时间**：$displayTimestamp
**变更描述**：首次创建。

**子文件变更明细**：

| 文件 | 版本变更 | 变更描述 |
|------|---------|---------|
| （待填写） | | |

---

"@
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($versionRecordPath, $versionRecordContent, $utf8WithBom)
Write-Host "[OK] Created version record: $versionRecordPath"

Write-Host ""
Write-Host "=========================================="
Write-Host "  New Sub-Project Created"
Write-Host "=========================================="
Write-Host "  Topic    : $Topic"
Write-Host "  Folder   : $folderName"
Write-Host "  Path     : $projectPath"
Write-Host "  Created  : $displayTimestamp"
Write-Host "=========================================="
Write-Host ""
Write-Host "Next: start creating files in $projectPath"