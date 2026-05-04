<#
.SYNOPSIS
    Create a new sub-project folder under output/
.DESCRIPTION
    Creates a timestamped sub-project directory following naming convention:
    output\{Topic}_{YYYYMMDDHHMI}
    Also initializes a standard folder structure inside.
.PARAMETER Topic
    The topic/domain name in Chinese (required)
.PARAMETER OutputRoot
    The root output directory. Defaults to the workspace output folder.
.EXAMPLE
    .\new_project.ps1 -Topic "减肥第一性原理"
    # Creates: output\减肥第一性原理_202605031528\
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Topic,

    [Parameter(Mandatory=$false)]
    [string]$OutputRoot = ""
)

# Auto-detect workspace root (folder containing output\ and .history\)
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

# Generate timestamp: YYYYMMDDHHmm
$timestamp = Get-Date -Format "yyyyMMddHHmm"

# Build folder name and path
$folderName = "${Topic}_${timestamp}"
$projectPath = Join-Path $OutputRoot $folderName

# Check if already exists
if (Test-Path $projectPath) {
    Write-Error "Folder already exists: $projectPath"
    exit 1
}

# Create the sub-project folder
New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
Write-Host "[OK] Created project folder: $projectPath"

# Copy version management reference file if it exists
$versionMgmtSrc = Get-ChildItem -Path $OutputRoot -Filter "*版本管理*" -Recurse -File | Select-Object -First 1
if ($versionMgmtSrc) {
    $versionMgmtDst = Join-Path $projectPath "版本管理.md"
    Copy-Item -Path $versionMgmtSrc.FullName -Destination $versionMgmtDst
    Write-Host "[OK] Copied version management guide: 版本管理.md"
}

Write-Host ""
Write-Host "=========================================="
Write-Host "  New Sub-Project Created"
Write-Host "=========================================="
Write-Host "  Topic    : $Topic"
Write-Host "  Folder   : $folderName"
Write-Host "  Path     : $projectPath"
Write-Host "  Created  : $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Write-Host "=========================================="
Write-Host ""
Write-Host "Next: start creating files in $projectPath"
