<#
.SYNOPSIS
    Framework health check. Read-only. Reports issues, does not fix them.
.DESCRIPTION
    Checks: conversation records, .ps1 BOM, .memory cleanliness, knowledge map alignment, input/ path.
#>

param([switch]$Quiet)

$ErrorActionPreference = "Continue"
$workspaceRoot = $PSScriptRoot
while ($workspaceRoot -and -not (Test-Path (Join-Path $workspaceRoot ".history"))) {
    $parent = Split-Path $workspaceRoot -Parent
    if ($parent -eq $workspaceRoot) { $workspaceRoot = $null; break }
    $workspaceRoot = $parent
}

if (-not $workspaceRoot) {
    Write-Host "ERROR: Workspace root not found"
    exit 1
}

$issues = 0
$warnings = 0
$passes = 0

Write-Host ""
Write-Host "========================================"
Write-Host "  Framework Health Check"
Write-Host "  Workspace: $workspaceRoot"
Write-Host "========================================"
Write-Host ""

# 1. Conversation records
Write-Host "--- 1. Conversation Records ---"
$outputDirs = Get-ChildItem (Join-Path $workspaceRoot "output") -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d{2}_.+_v\d+\.\d+\.\d+$' }
$convDir = Join-Path $workspaceRoot ".memory\对话记录"
$missingConvs = @()
foreach ($dir in $outputDirs) {
    $expected = Join-Path $convDir "$($dir.Name).md"
    if (-not (Test-Path $expected)) { $missingConvs += $dir.Name }
}
if ($missingConvs.Count -eq 0) {
    Write-Host "  [PASS] $($outputDirs.Count)/$($outputDirs.Count) subprojects have conversation records"
    $passes++
} else {
    foreach ($m in $missingConvs) {
        Write-Host "  [FAIL] Missing: $m"
        $issues++
    }
}
$convFiles = Get-ChildItem $convDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d{2}_.+\.md$' }
$outputNames = $outputDirs | ForEach-Object { "$($_.Name).md" }
$orphans = $convFiles | Where-Object { $_.Name -notin $outputNames }
foreach ($o in $orphans) {
    Write-Host "  [WARN] Orphan record: $($o.Name)"
    $warnings++
}

# 2. .ps1 BOM
Write-Host ""
Write-Host "--- 2. .ps1 BOM ---"
$ps1Files = @(
    (Join-Path $workspaceRoot ".agents\skills\版本控制备份\scripts\backup.ps1"),
    (Join-Path $workspaceRoot ".agents\skills\子项目管理\scripts\new_project.ps1")
)
foreach ($p in $ps1Files) {
    if (-not (Test-Path $p)) {
        Write-Host "  [FAIL] Not found: $p"
        $issues++
        continue
    }
    $b = [System.IO.File]::ReadAllBytes($p)
    $rel = $p.Substring($workspaceRoot.Length + 1)
    if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) {
        Write-Host "  [PASS] BOM OK: $rel"
        $passes++
    } else {
        Write-Host "  [FAIL] No BOM: $rel"
        $issues++
    }
}

# 3. .memory cleanliness
Write-Host ""
Write-Host "--- 3. .memory Current Zone ---"
$memRoot = Join-Path $workspaceRoot ".memory"
$vCopies = Get-ChildItem $memRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '_v\d+\.\d+\.\d+\.[^.]+$' -and $_.DirectoryName -notmatch '\\\.history' -and $_.DirectoryName -notmatch '\\对话记录' }
if ($vCopies.Count -eq 0) {
    Write-Host "  [PASS] No _v* history copies in current zone"
    $passes++
} else {
    foreach ($vc in $vCopies) {
        Write-Host "  [FAIL] History copy: $($vc.FullName.Substring($workspaceRoot.Length + 1))"
        $issues++
    }
}

# 4. Knowledge map
Write-Host ""
Write-Host "--- 4. Knowledge Map ---"
$mapPath = Join-Path $memRoot "全局知识地图.md"
if (-not (Test-Path $mapPath)) {
    Write-Host "  [FAIL] Map not found"
    $issues++
} else {
    $mapContent = Get-Content $mapPath -Raw -Encoding UTF8
    $mapProjects = ([regex]::Matches($mapContent, '\| (\d{2}_.+?_v[\d\.]+) \|') | ForEach-Object { $_.Groups[1].Value })
    $outputNames = $outputDirs | ForEach-Object { $_.Name }
    $inMapNotOut = $mapProjects | Where-Object { $_ -notin $outputNames }
    $inOutNotMap = $outputNames | Where-Object { $_ -notin $mapProjects }
    if ($inMapNotOut.Count -eq 0 -and $inOutNotMap.Count -eq 0) {
        Write-Host "  [PASS] Map ($($mapProjects.Count)) matches output/ ($($outputDirs.Count))"
        $passes++
    } else {
        foreach ($m in $inMapNotOut) { Write-Host "  [FAIL] In map, not output/: $m"; $issues++ }
        foreach ($o in $inOutNotMap) { Write-Host "  [FAIL] In output/, not map: $o"; $issues++ }
    }
}

# 5. input/ check
Write-Host ""
Write-Host "--- 5. input/ Path ---"
$inputPath = Join-Path $workspaceRoot "input"
if (Test-Path $inputPath) {
    $inputFiles = Get-ChildItem $inputPath -File -ErrorAction SilentlyContinue
    $bad = $inputFiles | Where-Object { $_.Name -match '系统|变更|治理|规则|skill|备份|记忆' }
    if ($bad.Count -gt 0) {
        foreach ($b in $bad) { Write-Host "  [WARN] Possible governance doc in input/: $($b.Name)"; $warnings++ }
    } else {
        Write-Host "  [PASS] input/ clean"
        $passes++
    }
} else {
    Write-Host "  [PASS] No input/"
    $passes++
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Passed : $passes  |  Failed : $issues  |  Warnings: $warnings"
Write-Host "========================================"
if ($issues -gt 0) { exit 1 } else { exit 0 }