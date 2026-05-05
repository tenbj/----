<#
.SYNOPSIS
    Framework health check. Read-only. Reports issues, does not fix them.
.DESCRIPTION
    Loads workspace-spec.json from .system/standards/ as Single Source of Truth.
    Checks: conversation records, .ps1 BOM, .memory cleanliness, knowledge map alignment,
    input/ path, sub-project catalog completeness, file numbering, required skeleton.
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

# ── Load SSOT spec ─────────────────────────────────────────────────────────────
$specPath = Join-Path $workspaceRoot ".system\standards\workspace-spec.json"
if (-not (Test-Path $specPath)) {
    Write-Host "WARN: workspace-spec.json not found at $specPath — falling back to built-in defaults"
    $spec = $null
} else {
    $spec = Get-Content $specPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

# ── Derive values from spec (with hard-coded fallbacks) ────────────────────────
$requiredSkills = if ($spec) {
    $spec.overwriteLayer.skills
} else {
    @("创建技能","子项目管理","安装技能","框架体检","版本控制备份","记忆管理","项目规范化","课题研究")
}

$requiredRules = if ($spec) {
    $spec.overwriteLayer.rules
} else {
    @("direction-rules.md","filename-rules.md","memory-rules.md","version-control-rules.md")
}

$bomFiles = if ($spec) {
    $spec.bomCheck.files | ForEach-Object { Join-Path $workspaceRoot $_ }
} else {
    @(
        (Join-Path $workspaceRoot ".agents\skills\版本控制备份\scripts\backup.ps1"),
        (Join-Path $workspaceRoot ".agents\skills\子项目管理\scripts\new_project.ps1"),
        (Join-Path $workspaceRoot ".agents\skills\子项目管理\scripts\next_number.ps1"),
        (Join-Path $workspaceRoot ".agents\skills\子项目管理\scripts\normalize_project.ps1"),
        (Join-Path $workspaceRoot ".agents\skills\框架体检\scripts\framework-check.ps1"),
        (Join-Path $workspaceRoot ".agents\skills\项目规范化\scripts\normalize.ps1"),
        (Join-Path $workspaceRoot ".agents\skills\记忆管理\scripts\remove.ps1")
    )
}

$systemRecordFiles = if ($spec) {
    $spec.naming.systemRecord.fixedNames
} else {
    @("规则变更记录.md","技能变更记录.md","脚本治理记录.md","教训库.md","索引.md")
}

$allowedMemoryDirs = if ($spec) {
    $spec.memoryCleanRules.allowedDirs
} else {
    @("对话记录","系统记录","知识提炼")
}

$subFolderSpecs = if ($spec) {
    $spec.naming.subfolder.specs | ForEach-Object {
        @{ Prefix = $_.prefix; Title = $_.title; Stem = $_.stem }
    }
} else {
    @(
        @{ Prefix = "01"; Title = "问题答疑"; Stem = "01_问题答疑" },
        @{ Prefix = "02"; Title = "课题研究"; Stem = "02_课题研究" },
        @{ Prefix = "03"; Title = "代码程序"; Stem = "03_代码程序" }
    )
}

$requiredDirs = if ($spec) { $spec.requiredLayer.directories } else { @() }

# ── Helper functions ───────────────────────────────────────────────────────────
$issues = 0
$warnings = 0
$passes = 0

function Get-ProjectRootContentFiles($projectDir) {
    return @(Get-ChildItem -LiteralPath $projectDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("目录.md", "版本记录.md") -and $_.Name -match '\.(md|html|txt|ps1)$' } |
        Sort-Object CreationTime, Name)
}

function Get-ProjectRootPayloadFiles($projectDir) {
    return @(Get-ChildItem -LiteralPath $projectDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("目录.md", "版本记录.md") } |
        Sort-Object Name)
}

function Get-SubFolderContentFiles($subDir) {
    if (-not (Test-Path -LiteralPath $subDir)) { return @() }
    return @(Get-ChildItem -LiteralPath $subDir -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne ".gitkeep" } |
        Sort-Object CreationTime, Name)
}

function Get-ProjectSubFolderMatches($projectDir, $spec) {
    $pattern = "^$([regex]::Escape($spec.Stem))_v\d+\.\d+\.\d+$"
    return @(Get-ChildItem -LiteralPath $projectDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $pattern } |
        Sort-Object Name)
}

function Get-ProjectSubFolderVersion($folderName, $spec) {
    $pattern = "^$([regex]::Escape($spec.Stem))_v(\d+\.\d+\.\d+)$"
    if ($folderName -match $pattern) { return $Matches[1] }
    return ""
}

function Get-ExpectedSubFolderVersion($subDir) {
    $files = Get-SubFolderContentFiles $subDir
    if ($files.Count -gt 0) { return "1.0.0" }
    return "0.0.0"
}

function Test-StructuredProject($projectDir) {
    $rootPayloadFiles = Get-ProjectRootPayloadFiles $projectDir
    $rootPayloadDirs = @(Get-ChildItem -LiteralPath $projectDir -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            $dirName = $_.Name
            -not ($subFolderSpecs | Where-Object {
                $dirName -match "^$([regex]::Escape($_.Stem))_v\d+\.\d+\.\d+$"
            })
        })
    $subFolderCount = 0
    foreach ($s in $subFolderSpecs) {
        $subFolderCount += (Get-ProjectSubFolderMatches $projectDir $s).Count
    }
    return ($subFolderCount -gt 0 -or ($rootPayloadFiles.Count -eq 0 -and $rootPayloadDirs.Count -eq 0))
}

# ══════════════════════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "========================================"
Write-Host "  Framework Health Check"
Write-Host "  Workspace: $workspaceRoot"
if ($spec) { Write-Host "  Spec: workspace-spec.json v$($spec.version)" }
Write-Host "========================================"
Write-Host ""

# ── Check 0: Required skeleton ──────────────────────────────────────────────
if ($requiredDirs.Count -gt 0) {
    Write-Host "--- 0. Required Skeleton Directories ---"
    $missingDirs = @()
    foreach ($d in $requiredDirs) {
        $p = Join-Path $workspaceRoot ($d -replace '/', '\')
        if (-not (Test-Path $p)) { $missingDirs += $d }
    }
    if ($missingDirs.Count -eq 0) {
        Write-Host "  [PASS] All $($requiredDirs.Count) required directories exist"
        $passes++
    } else {
        foreach ($m in $missingDirs) {
            Write-Host "  [FAIL] Missing: $m/"
            $issues++
        }
    }

    # Core subproject check
    if ($spec -and $spec.requiredLayer.coreSubproject) {
        Write-Host ""
        Write-Host "--- 0b. Core Subproject (00_系统治理) ---"
        $coreSpec = $spec.requiredLayer.coreSubproject
        $corePattern = "^00_$([regex]::Escape($coreSpec.name))_v\d+\.\d+\.\d+$"
        $coreDirs = @(Get-ChildItem (Join-Path $workspaceRoot "output") -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match $corePattern })
        if ($coreDirs.Count -eq 0) {
            Write-Host "  [FAIL] Core subproject not found: output/00_$($coreSpec.name)_v*/"
            $issues++
        } else {
            $coreDir = $coreDirs[0]
            Write-Host "  [PASS] Core subproject: $($coreDir.Name)"
            $passes++
            # Check subfolders
            foreach ($sf in $coreSpec.subfolders) {
                $stem = $sf -replace '_v\d+\.\d+\.\d+$', ''
                $sfMatch = @(Get-ChildItem $coreDir.FullName -Directory |
                    Where-Object { $_.Name -match "^$([regex]::Escape($stem))_v\d+\.\d+\.\d+$" })
                if ($sfMatch.Count -eq 0) {
                    Write-Host "  [WARN] Core subproject missing subfolder: $stem"
                    $warnings++
                }
            }
            # Check fixed files
            foreach ($ff in $coreSpec.fixedFiles) {
                if (-not (Test-Path (Join-Path $coreDir.FullName $ff))) {
                    Write-Host "  [WARN] Core subproject missing: $ff"
                    $warnings++
                }
            }
            # Check conversation record
            $convRecordName = "00_$($coreSpec.name)_v" + $coreDir.Name.Split('_v')[-1] + ".md"
            $convRecordPath = Join-Path $workspaceRoot ".memory\对话记录\$convRecordName"
            if (-not (Test-Path $convRecordPath)) {
                Write-Host "  [WARN] Core subproject conversation record missing: .memory/对话记录/$convRecordName"
                $warnings++
            }
        }
    }

    # .system/standards files
    if ($spec) {
        Write-Host ""
        Write-Host "--- 0c. .system/standards/ ---"
        $stdDir = Join-Path $workspaceRoot ".system\standards"
        $jsonOk = Test-Path (Join-Path $stdDir "workspace-spec.json")
        $mdOk   = Test-Path (Join-Path $stdDir "工作区骨架规格.md")
        if ($jsonOk -and $mdOk) {
            Write-Host "  [PASS] workspace-spec.json + 工作区骨架规格.md present"
            $passes++
        } else {
            if (-not $jsonOk) { Write-Host "  [FAIL] Missing: .system/standards/workspace-spec.json"; $issues++ }
            if (-not $mdOk)   { Write-Host "  [WARN] Missing: .system/standards/工作区骨架规格.md"; $warnings++ }
        }
    }
    Write-Host ""
}

# ── Check 1: Conversation records ────────────────────────────────────────────
Write-Host "--- 1. Conversation Records ---"
$outputDirs = Get-ChildItem (Join-Path $workspaceRoot "output") -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^\d{2}_.+_v\d+\.\d+\.\d+$' }
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
$convFiles = Get-ChildItem $convDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^\d{2}_.+\.md$' }
$outputNames = $outputDirs | ForEach-Object { "$($_.Name).md" }
$orphans = $convFiles | Where-Object { $_.Name -notin $outputNames }
foreach ($o in $orphans) {
    Write-Host "  [WARN] Orphan record: $($o.Name)"
    $warnings++
}

# ── Check 2: .ps1 BOM ─────────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- 2. .ps1 BOM ---"
foreach ($p in $bomFiles) {
    if (-not (Test-Path $p)) {
        Write-Host "  [FAIL] Not found: $($p.Substring($workspaceRoot.Length + 1))"
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

# ── Check 3: .memory cleanliness ─────────────────────────────────────────────
Write-Host ""
Write-Host "--- 3. .memory Current Zone ---"
$memRoot = Join-Path $workspaceRoot ".memory"

# No _v* history copies outside 对话记录
$vCopies = Get-ChildItem $memRoot -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match '_v\d+\.\d+\.\d+\.[^.]+$' -and
        $_.DirectoryName -notmatch '\\\.history' -and
        $_.DirectoryName -notmatch '\\对话记录'
    }
if ($vCopies.Count -eq 0) {
    Write-Host "  [PASS] No _v* history copies in current zone"
    $passes++
} else {
    foreach ($vc in $vCopies) {
        Write-Host "  [FAIL] History copy: $($vc.FullName.Substring($workspaceRoot.Length + 1))"
        $issues++
    }
}

# No extra dirs in .memory
$memDirs = @(Get-ChildItem $memRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
$unexpectedDirs = $memDirs | Where-Object { $allowedMemoryDirs -notcontains $_ }
foreach ($ud in $unexpectedDirs) {
    Write-Host "  [WARN] Unexpected dir in .memory/: $ud/"
    $warnings++
}

# System record files
$sysRecDir = Join-Path $memRoot "系统记录"
if (Test-Path $sysRecDir) {
    $missingRec = @()
    foreach ($rf in $systemRecordFiles) {
        if (-not (Test-Path (Join-Path $sysRecDir $rf))) { $missingRec += $rf }
    }
    $extraRec = @(Get-ChildItem $sysRecDir -File -ErrorAction SilentlyContinue |
        Where-Object { $systemRecordFiles -notcontains $_.Name -and $_.Name -ne "rules-skills.md" })
    if ($missingRec.Count -eq 0 -and $extraRec.Count -eq 0) {
        Write-Host "  [PASS] 系统记录/ has exactly $($systemRecordFiles.Count) required files"
        $passes++
    } else {
        foreach ($mr in $missingRec) { Write-Host "  [FAIL] Missing system record: $mr"; $issues++ }
        foreach ($er in $extraRec)   { Write-Host "  [WARN] Extra system record: $($er.Name)"; $warnings++ }
    }
    if (Test-Path (Join-Path $sysRecDir "rules-skills.md")) {
        Write-Host "  [WARN] Legacy rules-skills.md still present — needs migration"
        $warnings++
    }
}

# ── Check 4: Knowledge map ────────────────────────────────────────────────────
Write-Host ""
Write-Host "--- 4. Knowledge Map ---"
$mapPath = Join-Path $memRoot "全局知识地图.md"
if (-not (Test-Path $mapPath)) {
    Write-Host "  [FAIL] Map not found"
    $issues++
} else {
    $mapContent = Get-Content $mapPath -Raw -Encoding UTF8
    $mapProjects = ([regex]::Matches($mapContent, '\| (\d{2}_.+?_v[\d\.]+) \|') |
        ForEach-Object { $_.Groups[1].Value })
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

# ── Check 5: input/ ───────────────────────────────────────────────────────────
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

# ── Check 6: Structured sub-project internals ─────────────────────────────────
Write-Host ""
Write-Host "--- 6. Structured Sub-folders ---"
$missingCatalog = @()
$structuredProblems = @()
foreach ($dir in $outputDirs) {
    $catalogPath = Join-Path $dir.FullName "目录.md"
    if (-not (Test-Path $catalogPath)) {
        $missingCatalog += $dir.Name
    }
    if (Test-StructuredProject $dir.FullName) {
        foreach ($s in $subFolderSpecs) {
            $sfMatches = Get-ProjectSubFolderMatches $dir.FullName $s
            if ($sfMatches.Count -eq 0) {
                $structuredProblems += "$($dir.Name): missing $($s.Stem)_v*"
                continue
            }
            if ($sfMatches.Count -gt 1) {
                $structuredProblems += "$($dir.Name): duplicate $($s.Stem)_v*"
            }
            $actualVersion   = Get-ProjectSubFolderVersion $sfMatches[0].Name $s
            $expectedVersion = Get-ExpectedSubFolderVersion $sfMatches[0].FullName
            if ($actualVersion -ne $expectedVersion) {
                $structuredProblems += "$($dir.Name)\$($sfMatches[0].Name): expected v$expectedVersion"
            }
        }
    }
}
if ($missingCatalog.Count -eq 0) {
    Write-Host "  [PASS] All $($outputDirs.Count) subprojects have 目录.md"
    $passes++
} else {
    foreach ($m in $missingCatalog) { Write-Host "  [FAIL] Missing 目录.md: $m"; $issues++ }
}
if ($structuredProblems.Count -eq 0) {
    Write-Host "  [PASS] Structured sub-folder checks passed"
    $passes++
} else {
    foreach ($p in $structuredProblems) { Write-Host "  [FAIL] $p"; $issues++ }
}

# ── Check 7: File numbering and internal version suffix ───────────────────────
Write-Host ""
Write-Host "--- 7. Internal File Naming ---"
$unnumberedFiles   = @()
$versionedInnerFiles = @()
foreach ($dir in $outputDirs) {
    if (Test-StructuredProject $dir.FullName) {
        foreach ($s in $subFolderSpecs) {
            $sfMatches = Get-ProjectSubFolderMatches $dir.FullName $s
            if ($sfMatches.Count -eq 0) { continue }
            foreach ($f in (Get-SubFolderContentFiles $sfMatches[0].FullName)) {
                $relPath = "$($dir.Name)\$($sfMatches[0].Name)\$($f.Name)"
                if ($f.Name -match '_v\d+\.\d+\.\d+\.[^.]+$') {
                    $versionedInnerFiles += $relPath
                }
                if ($s.Prefix -ne "03" -and $f.Name -notmatch '^\d{2}_') {
                    $unnumberedFiles += $relPath
                }
            }
        }
    } else {
        foreach ($f in (Get-ProjectRootContentFiles $dir.FullName)) {
            if ($f.Name -notmatch '^\d{2}_') {
                $unnumberedFiles += "$($dir.Name)\$($f.Name)"
            }
        }
    }
}
if ($unnumberedFiles.Count -eq 0) {
    Write-Host "  [PASS] Numbered content files look OK"
    $passes++
} else {
    Write-Host "  [WARN] $($unnumberedFiles.Count) files without {NN}_ prefix:"
    foreach ($u in $unnumberedFiles) { Write-Host "     $u" }
    $warnings++
}
if ($versionedInnerFiles.Count -eq 0) {
    Write-Host "  [PASS] Inner files do not carry v* suffixes"
    $passes++
} else {
    Write-Host "  [WARN] $($versionedInnerFiles.Count) inner files still carry v* suffixes:"
    foreach ($v in $versionedInnerFiles) { Write-Host "     $v" }
    $warnings++
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Passed : $passes  |  Failed : $issues  |  Warnings: $warnings"
Write-Host "========================================"
if ($issues -gt 0) { exit 1 } else { exit 0 }