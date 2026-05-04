<#
.SYNOPSIS
    File/Folder Version Control Backup Script
.DESCRIPTION
    Supports two modes:
    - FILE mode  (output/ content): backup to .history + rename with new version
    - FOLDER mode (skills/): snapshot entire folder to .history with timestamp
    - CONFIG mode (rules/): backup single file to .history with timestamp
.PARAMETER TargetPath
    Absolute path of the file or folder to backup (required)
.PARAMETER ChangeType
    Version bump type for FILE mode: MAJOR | MINOR | PATCH (default: PATCH)
    Ignored in FOLDER and CONFIG modes.
.PARAMETER Mode
    Backup mode: FILE | FOLDER | CONFIG (default: auto-detect)
.EXAMPLE
    # Backup a content file (output/)
    .\backup.ps1 -TargetPath "e:\ws\output\topic\doc_v1.0.0.md" -ChangeType PATCH

    # Backup an entire skill folder
    .\backup.ps1 -TargetPath "e:\ws\.agent\skills\MySkill" -Mode FOLDER

    # Backup a rule config file
    .\backup.ps1 -TargetPath "e:\ws\.agent\rules\my-rule.md" -Mode CONFIG
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,

    [Parameter(Mandatory=$false)]
    [ValidateSet("MAJOR", "MINOR", "PATCH")]
    [string]$ChangeType = "PATCH",

    [Parameter(Mandatory=$false)]
    [ValidateSet("FILE", "FOLDER", "CONFIG", "AUTO")]
    [string]$Mode = "AUTO"
)

# -----------------------------------------------
# Auto-detect mode
# -----------------------------------------------
if ($Mode -eq "AUTO") {
    $item = Get-Item $TargetPath -ErrorAction SilentlyContinue
    if (-not $item) {
        Write-Error "Target not found: $TargetPath"
        exit 1
    }
    if ($item.PSIsContainer) {
        $Mode = "FOLDER"
    } elseif ($TargetPath -match '\\.agent\\rules\\') {
        $Mode = "CONFIG"
    } else {
        $Mode = "FILE"
    }
    Write-Host "[INFO] Auto-detected mode: $Mode"
}

# -----------------------------------------------
# Find workspace root (contains .history/)
# -----------------------------------------------
function Find-WorkspaceRoot {
    param([string]$StartPath)
    $searchDir = $StartPath
    while ($searchDir) {
        if (Test-Path (Join-Path $searchDir ".history")) {
            return $searchDir
        }
        $parent = Split-Path $searchDir -Parent
        if ($parent -eq $searchDir) { break }
        $searchDir = $parent
    }
    return $null
}

$startSearch = if ((Get-Item $TargetPath).PSIsContainer) { $TargetPath } else { Split-Path $TargetPath -Parent }
$workspaceRoot = Find-WorkspaceRoot $startSearch

if (-not $workspaceRoot) {
    Write-Error "Workspace root not found (no .history folder). Create .history in project root first."
    exit 1
}

$timestamp = Get-Date -Format "yyyyMMddHHmm"
$historyRoot = Join-Path $workspaceRoot ".history"

# -----------------------------------------------
# MODE: FOLDER - snapshot entire skill folder
# -----------------------------------------------
if ($Mode -eq "FOLDER") {
    $folderItem = Get-Item $TargetPath
    $folderName = $folderItem.Name
    $relativePath = $TargetPath.Substring($workspaceRoot.Length).TrimStart('\', '/')
    $relativeParent = Split-Path $relativePath -Parent
    $snapshotName = "${folderName}_${timestamp}"
    $snapshotDir = Join-Path (Join-Path $historyRoot $relativeParent) $snapshotName

    New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
    Copy-Item -Path "$TargetPath\*" -Destination $snapshotDir -Recurse -Force

    Write-Host "[OK] Skill folder snapshot created: $snapshotDir"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "  Folder Snapshot Complete"
    Write-Host "=========================================="
    Write-Host "  Source   : $TargetPath"
    Write-Host "  Snapshot : $snapshotDir"
    Write-Host "=========================================="
    exit 0
}

# -----------------------------------------------
# MODE: CONFIG - backup config file with timestamp
# -----------------------------------------------
if ($Mode -eq "CONFIG") {
    $fileItem = Get-Item $TargetPath
    $fileName = $fileItem.Name
    $baseName = $fileItem.BaseName
    $ext = $fileItem.Extension
    $relativePath = $TargetPath.Substring($workspaceRoot.Length).TrimStart('\', '/')
    $relativeParent = Split-Path $relativePath -Parent
    $backupFileName = "${baseName}_${timestamp}${ext}"
    $backupDir = Join-Path $historyRoot $relativeParent
    $backupPath = Join-Path $backupDir $backupFileName

    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    Copy-Item -Path $TargetPath -Destination $backupPath -Force

    Write-Host "[OK] Config file backed up: $backupPath"
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "  Config Backup Complete"
    Write-Host "=========================================="
    Write-Host "  Source : $TargetPath"
    Write-Host "  Backup : $backupPath"
    Write-Host "=========================================="
    exit 0
}

# -----------------------------------------------
# MODE: FILE - backup + rename with new version
# -----------------------------------------------
function Parse-Version {
    param([string]$v)
    if ($v -match '^(\d+)\.(\d+)\.(\d+)$') {
        return @{ Major=[int]$Matches[1]; Minor=[int]$Matches[2]; Patch=[int]$Matches[3] }
    }
    return $null
}

function Get-VersionFromName {
    param([string]$BaseName)
    if ($BaseName -match '_v(\d+\.\d+\.\d+)$') { return $Matches[1] }
    if ($BaseName -match '_v(\d+\.\d+)$') { return "$($Matches[1]).0" }
    return $null
}

function Get-PureName {
    param([string]$BaseName)
    if ($BaseName -match '^(.+)_v\d+\.\d+(\.\d+)?$') { return $Matches[1] }
    return $BaseName
}

function Bump-Version {
    param([string]$CurrentVersion, [string]$Type)
    $v = Parse-Version $CurrentVersion
    if (-not $v) { Write-Error "Cannot parse version: $CurrentVersion"; exit 1 }
    switch ($Type) {
        "MAJOR" { return "$($v.Major + 1).0.0" }
        "MINOR" { return "$($v.Major).$($v.Minor + 1).0" }
        "PATCH" { return "$($v.Major).$($v.Minor).$($v.Patch + 1)" }
    }
}

if (-not (Test-Path $TargetPath)) {
    Write-Error "Source file not found: $TargetPath"
    exit 1
}

$fileItem     = Get-Item $TargetPath
$fileDir      = $fileItem.DirectoryName
$fileExt      = $fileItem.Extension
$fileBaseName = $fileItem.BaseName

$relativePath  = $TargetPath.Substring($workspaceRoot.Length).TrimStart('\', '/')
$currentVersion = Get-VersionFromName $fileBaseName
$pureName = Get-PureName $fileBaseName

if (-not $currentVersion) {
    $currentVersion = "1.0.0"
    Write-Host "[WARN] No version in filename. Treating current as v$currentVersion"
}

$newVersion = Bump-Version -CurrentVersion $currentVersion -Type $ChangeType

$historyRelDir  = Split-Path $relativePath -Parent
$historyFileDir = Join-Path $historyRoot $historyRelDir
$historyFileName = "$pureName$fileExt"
$historyFilePath = Join-Path $historyFileDir $historyFileName
$newVersionFileName = "${pureName}_v${newVersion}${fileExt}"
$newVersionFilePath = Join-Path $fileDir $newVersionFileName

if (-not (Test-Path $historyFileDir)) {
    New-Item -ItemType Directory -Path $historyFileDir -Force | Out-Null
    Write-Host "[INFO] Created backup dir: $historyFileDir"
}

Copy-Item -Path $TargetPath -Destination $historyFilePath -Force
Write-Host "[OK] Backed up to: $historyFilePath"

Rename-Item -Path $TargetPath -NewName $newVersionFileName
Write-Host "[OK] Renamed to:   $newVersionFilePath"

Write-Host ""
Write-Host "=========================================="
Write-Host "  File Version Backup Complete"
Write-Host "=========================================="
Write-Host "  Source   : $TargetPath"
Write-Host "  Backup   : $historyFilePath"
Write-Host "  New File : $newVersionFilePath"
Write-Host "  Version  : v$currentVersion --> v$newVersion ($ChangeType)"
Write-Host "=========================================="
Write-Host ""
Write-Host "Next: edit the new file: $newVersionFileName"
