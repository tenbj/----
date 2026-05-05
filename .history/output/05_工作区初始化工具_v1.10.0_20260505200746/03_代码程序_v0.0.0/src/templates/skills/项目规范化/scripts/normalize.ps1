<#
.SYNOPSIS
    Project structure normalization: check or fix.
.DESCRIPTION
    Checks 6 standards (root dirs, .agents, output, .memory, .history, .temp/input).
    --Check : report PASS/FAIL/WARN only.
    --Fix   : report then fix (create missing, move extras to .temp).
#>

param(
    [switch]$Check,
    [switch]$Fix
)

$ErrorActionPreference = "Continue"
$wn = Split-Path -Parent $MyInvocation.MyCommand.Path
while ($wn -and -not (Test-Path (Join-Path $wn ".history"))) {
    $p = Split-Path $wn -Parent
    if ($p -eq $wn) { $wn = $null; break }
    $wn = $p
}
if (-not $wn) { Write-Host "ERROR: Workspace root not found"; exit 1 }

$issues = 0; $warnings = 0; $passes = 0
$fixLog = @()
$snapshottedProjects = @{}

function cnp($n, $b) { return [System.Text.Encoding]::UTF8.GetString($b) }

$S_mulu      = cnp 0 (@(0xE7,0x9B,0xAE,0xE5,0xBD,0x95))
$S_ver_log   = cnp 0 (@(0xE7,0x89,0x88,0xE6,0x9C,0xAC,0xE8,0xAE,0xB0,0xE5,0xBD,0x95))
$S_conv      = cnp 0 (@(0xE5,0xAF,0xB9,0xE8,0xAF,0x9D,0xE8,0xAE,0xB0,0xE5,0xBD,0x95))
$S_sys_rec   = cnp 0 (@(0xE7,0xB3,0xBB,0xE7,0xBB,0x9F,0xE8,0xAE,0xB0,0xE5,0xBD,0x95))
$S_knowledge = cnp 0 (@(0xE7,0x9F,0xA5,0xE8,0xAF,0x86,0xE6,0x8F,0x90,0xE7,0x82,0xBC))
$S_map        = cnp 0 (@(0xE5,0x85,0xA8,0xE5,0xB1,0x80,0xE7,0x9F,0xA5,0xE8,0xAF,0x86,0xE5,0x9C,0xB0,0xE5,0x9B,0xBE))
$S_rule_chg   = cnp 0 (@(0xE8,0xA7,0x84,0xE5,0x88,0x99,0xE5,0x8F,0x98,0xE6,0x9B,0xB4,0xE8,0xAE,0xB0,0xE5,0xBD,0x95))
$S_skill_chg  = cnp 0 (@(0xE6,0x8A,0x80,0xE8,0x83,0xBD,0xE5,0x8F,0x98,0xE6,0x9B,0xB4,0xE8,0xAE,0xB0,0xE5,0xBD,0x95))
$S_script_gov = cnp 0 (@(0xE8,0x84,0x9A,0xE6,0x9C,0xAC,0xE6,0xB2,0xBB,0xE7,0x90,0x86,0xE8,0xAE,0xB0,0xE5,0xBD,0x95))
$S_lessons    = cnp 0 (@(0xE6,0x95,0x99,0xE8,0xAE,0xAD,0xE5,0xBA,0x93))
$S_index      = cnp 0 (@(0xE7,0xB4,0xA2,0xE5,0xBC,0x95))
$S_anomaly    = cnp 0 (@(0xE8,0xA7,0x84,0xE8,0x8C,0x83,0xE5,0x8C,0x96,0xE5,0xBC,0x82,0xE5,0xB8,0xB8))

$projectSubFolderSpecs = @(
    @{ Prefix = "01"; Title = "问题答疑"; Stem = "01_问题答疑" },
    @{ Prefix = "02"; Title = "课题研究"; Stem = "02_课题研究" },
    @{ Prefix = "03"; Title = "代码程序"; Stem = "03_代码程序" }
)

function move-extra($src, $dstRel) {
    $ts = Get-Date -Format "yyyyMMddHHmmss"
    $base = Join-Path $wn ".temp\$($S_anomaly)_$ts"
    $target = Join-Path $base $dstRel
    $pDir = Split-Path $target -Parent
    if (-not (Test-Path $pDir)) { New-Item -ItemType Directory -Path $pDir -Force | Out-Null }
    if (Test-Path $src) {
        Move-Item $src $target -Force
        $script:fixLog += "Moved: $src -> $target"
        Write-Host "  [FIXED] Moved to $($target.Substring($wn.Length+1))"
    }
}

function Read-Utf8Text($path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.UTF8Encoding]::new($false))
}

function Write-Utf8BomText($path, $content) {
    [System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($true))
}

function Has-Mojibake($text) {
    if ($null -eq $text) { return $false }
    return ($text -match '[鐗璁椤杩椋宸浣绠妫鏌鍏鐭绯荤粺]')
}

function Get-ProjectTopic($folderName) {
    if ($folderName -match '^\d{2}_(.+)_v\d+\.\d+\.\d+$') { return $Matches[1] }
    return $folderName
}

function Get-MemoryVersion($text) {
    if ($text -match '<!--\s*memory-version:\s*(\d+)\.(\d+)\.(\d+)\s*-->') {
        return @{
            Text = "$($Matches[1]).$($Matches[2]).$($Matches[3])"
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Patch = [int]$Matches[3]
        }
    }
    return @{
        Text = "1.0.0"
        Major = 1
        Minor = 0
        Patch = 0
    }
}

function Ensure-ProjectSnapshot($projectDir) {
    $name = Split-Path $projectDir -Leaf
    if ($script:snapshottedProjects.ContainsKey($name)) { return }
    $ts = Get-Date -Format "yyyyMMddHHmmss"
    $histOut = Join-Path $wn ".history\output"
    if (-not (Test-Path $histOut)) { New-Item -ItemType Directory -Path $histOut -Force | Out-Null }
    $snapshot = Join-Path $histOut "${name}_$ts"
    Copy-Item -LiteralPath $projectDir -Destination $snapshot -Recurse -Force
    $script:snapshottedProjects[$name] = $snapshot
    $script:fixLog += "Snapshot: $projectDir -> $snapshot"
    Write-Host "  [FIXED] Snapshot before project normalization: $($snapshot.Substring($wn.Length+1))"
}

function Get-ProjectRootContentFiles($projectDir) {
    $fixed = @("$S_mulu.md", "$S_ver_log.md")
    return @(Get-ChildItem -LiteralPath $projectDir -File -ErrorAction SilentlyContinue |
        Where-Object { $fixed -notcontains $_.Name -and $_.Name -match '\.(md|html|txt|ps1)$' } |
        Sort-Object CreationTime, Name)
}

function Get-ProjectRootPayloadFiles($projectDir) {
    $fixed = @("$S_mulu.md", "$S_ver_log.md")
    return @(Get-ChildItem -LiteralPath $projectDir -File -ErrorAction SilentlyContinue |
        Where-Object { $fixed -notcontains $_.Name } |
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

function Get-ExpectedSubFolderName($spec, $version) {
    return "$($spec.Stem)_v$version"
}

function Test-StructuredProject($projectDir) {
    $rootPayloadFiles = Get-ProjectRootPayloadFiles $projectDir
    $rootPayloadDirs = @(Get-ChildItem -LiteralPath $projectDir -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            $dirName = $_.Name
            -not ($projectSubFolderSpecs | Where-Object {
                $dirName -match "^$([regex]::Escape($_.Stem))_v\d+\.\d+\.\d+$"
            })
        })
    $subFolderCount = 0
    foreach ($spec in $projectSubFolderSpecs) {
        $subFolderCount += (Get-ProjectSubFolderMatches $projectDir $spec).Count
    }
    return ($subFolderCount -gt 0 -or ($rootPayloadFiles.Count -eq 0 -and $rootPayloadDirs.Count -eq 0))
}

function Ensure-StructuredSubFolders($projectDir) {
    foreach ($spec in $projectSubFolderSpecs) {
        $matches = Get-ProjectSubFolderMatches $projectDir $spec
        if ($matches.Count -eq 0) {
            $newName = Get-ExpectedSubFolderName $spec "0.0.0"
            $newPath = Join-Path $projectDir $newName
            New-Item -ItemType Directory -Path $newPath -Force | Out-Null
            Write-Host "  [FIXED] Created sub-folder: $((Split-Path $projectDir -Leaf))/$newName"
            continue
        }

        $primary = $matches[0]
        $expectedVersion = Get-ExpectedSubFolderVersion $primary.FullName
        $expectedName = Get-ExpectedSubFolderName $spec $expectedVersion
        if ($primary.Name -ne $expectedName) {
            $target = Join-Path $projectDir $expectedName
            if (-not (Test-Path -LiteralPath $target)) {
                Rename-Item -LiteralPath $primary.FullName -NewName $expectedName -Force
                Write-Host "  [FIXED] Renamed sub-folder: $($primary.Name) -> $expectedName"
            } else {
                Write-Host "  [WARN] Cannot rename $($primary.Name); target exists: $expectedName"
                $script:warnings++
            }
        }
    }
}

function Build-LegacyCatalogContent($projectDir) {
    $topic = Get-ProjectTopic (Split-Path $projectDir -Leaf)
    $rows = @()
    $files = Get-ProjectRootContentFiles $projectDir
    foreach ($f in $files) {
        $num = ""
        if ($f.Name -match '^(\d{2})_') { $num = $Matches[1] }
        $created = Get-Date $f.CreationTime -Format "yyyy-MM-dd"
        $modified = Get-Date $f.LastWriteTime -Format "yyyy-MM-dd"
        $rows += "| $num | [$($f.Name)](./$($f.Name)) | | $created | $modified |"
    }
    $content = "# $S_mulu · $topic`r`n`r`n> 本子项目内所有内容文件的索引。`r`n`r`n"
    $content += "| # | 文件 | 说明 | 首次落盘 | 最近更新 |`r`n|---|------|------|---------|---------|`r`n"
    if ($rows.Count -gt 0) { $content += ($rows -join "`r`n") + "`r`n" }
    else { $content += "| 待新增文件后填写 | | | | |`r`n" }
    return $content
}

function Build-StructuredCatalogContent($projectDir) {
    $topic = Get-ProjectTopic (Split-Path $projectDir -Leaf)
    $content = "# $S_mulu · $topic`r`n`r`n> 本子项目内所有内容文件的索引，按三个子文件夹分节列出。`r`n`r`n---`r`n"

    foreach ($spec in $projectSubFolderSpecs) {
        $matches = Get-ProjectSubFolderMatches $projectDir $spec
        $subDir = if ($matches.Count -gt 0) { $matches[0] } else { $null }
        $content += "`r`n## $($spec.Stem)`r`n`r`n"
        $content += "| # | 文件 | 说明 | 首次落盘 | 最近更新 |`r`n|---|------|------|---------|---------|`r`n"

        if ($null -eq $subDir) {
            $content += "| 待新增文件后填写 | | | | |`r`n`r`n---`r`n"
            continue
        }

        $rows = @()
        foreach ($f in (Get-SubFolderContentFiles $subDir.FullName)) {
            $num = ""
            if ($f.Name -match '^(\d{2})_') { $num = $Matches[1] }
            $created = Get-Date $f.CreationTime -Format "yyyy-MM-dd"
            $modified = Get-Date $f.LastWriteTime -Format "yyyy-MM-dd"
            $rel = "./$($subDir.Name)/$($f.Name)"
            $rows += "| $num | [$($f.Name)]($rel) | | $created | $modified |"
        }

        if ($rows.Count -gt 0) { $content += ($rows -join "`r`n") + "`r`n" }
        else { $content += "| 待新增文件后填写 | | | | |`r`n" }
        $content += "`r`n---`r`n"
    }

    return $content
}

function Build-CatalogContent($projectDir) {
    if (Test-StructuredProject $projectDir) {
        return (Build-StructuredCatalogContent $projectDir)
    }
    return (Build-LegacyCatalogContent $projectDir)
}

function Ensure-VersionRecord($projectDir) {
    $topic = Get-ProjectTopic (Split-Path $projectDir -Leaf)
    $path = Join-Path $projectDir "$S_ver_log.md"
    if (Test-Path $path) { return }
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $content = "# $S_ver_log · $topic`r`n`r`n> 记录子项目的版本变更历史。`r`n`r`n---`r`n`r`n"
    $content += "## 规范化补建 ($now)`r`n`r`n**变更类型**：PATCH`r`n**变更描述**：老项目迁移时补建版本记录。`r`n`r`n---`r`n"
    Write-Utf8BomText $path $content
    Write-Host "  [FIXED] Created: $((Join-Path (Split-Path $projectDir -Leaf) "$S_ver_log.md"))"
}

function Normalize-ProjectInternals($projectDir) {
    Ensure-ProjectSnapshot $projectDir

    if (Test-StructuredProject $projectDir) {
        Ensure-StructuredSubFolders $projectDir
        $catalogPath = Join-Path $projectDir "$S_mulu.md"
        Write-Utf8BomText $catalogPath (Build-CatalogContent $projectDir)
        Write-Host "  [FIXED] Updated structured catalog: $((Join-Path (Split-Path $projectDir -Leaf) "$S_mulu.md"))"
        Ensure-VersionRecord $projectDir
        return
    }

    $files = Get-ProjectRootContentFiles $projectDir
    $existingNums = @($files | ForEach-Object {
        if ($_.Name -match '^(\d{2})_') { [int]$Matches[1] }
    })
    $next = if ($existingNums.Count -gt 0) { ($existingNums | Sort-Object -Descending | Select-Object -First 1) + 1 } else { 1 }

    foreach ($f in $files) {
        if ($f.Name -notmatch '^\d{2}_') {
            do {
                $newName = ("{0:D2}_" -f $next) + $f.Name
                $newPath = Join-Path $projectDir $newName
                $next++
            } while (Test-Path $newPath)
            Move-Item -LiteralPath $f.FullName -Destination $newPath -Force
            Write-Host "  [FIXED] Renamed: $($f.Name) -> $newName"
        }
    }

    $catalogPath = Join-Path $projectDir "$S_mulu.md"
    Write-Utf8BomText $catalogPath (Build-CatalogContent $projectDir)
    Write-Host "  [FIXED] Updated: $((Join-Path (Split-Path $projectDir -Leaf) "$S_mulu.md"))"
    Ensure-VersionRecord $projectDir
}

function Repair-GlobalKnowledgeMap($mapPath, $outputDirs) {
    $oldText = if (Test-Path $mapPath) { Read-Utf8Text $mapPath } else { "" }
    $oldVersion = Get-MemoryVersion $oldText
    if (Test-Path $mapPath) {
        $histDir = Join-Path $wn ".history\.memory\$S_map"
        if (-not (Test-Path $histDir)) { New-Item -ItemType Directory -Path $histDir -Force | Out-Null }
        Copy-Item -LiteralPath $mapPath -Destination (Join-Path $histDir "$($S_map)_v$($oldVersion.Text).md") -Force
    }

    $rowInfo = @{}
    foreach ($line in ($oldText -split "`r?`n")) {
        if ($line -match '^\|') {
            $cells = @($line.Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
            if ($cells.Count -ge 5 -and $cells[1] -match '^\d{2}_.+_v\d+\.\d+\.\d+$' -and -not (Has-Mojibake $line)) {
                $rowInfo[$cells[1]] = @{ Date = $cells[2]; Status = $cells[3]; Core = $cells[4] }
            }
        }
    }

    $newVersion = "$($oldVersion.Major).$($oldVersion.Minor + 1).0"
    $content = "<!-- memory-version: $newVersion -->`r`n# $S_map`r`n`r`n"
    $content += "> 所有研究子项目的总索引，新建子项目时自动更新。`r`n`r`n"
    $content += "| 话题 | 子项目文件夹 | 创建时间 | 状态 | 核心结论（一句话） |`r`n"
    $content += "|------|------------|---------|------|----------------|`r`n"
    foreach ($d in ($outputDirs | Sort-Object Name)) {
        $topic = Get-ProjectTopic $d.Name
        if ($rowInfo.ContainsKey($d.Name)) {
            $created = $rowInfo[$d.Name].Date
            $status = $rowInfo[$d.Name].Status
            $core = $rowInfo[$d.Name].Core
        } else {
            $created = Get-Date $d.CreationTime -Format "yyyy-MM-dd"
            $status = "进行中"
            $core = "-"
        }
        $content += "| $topic | $($d.Name) | $created | $status | $core |`r`n"
    }
    Write-Utf8BomText $mapPath $content
    Write-Host "  [FIXED] Rebuilt: .memory/$($S_map).md"
}

Write-Host ""
Write-Host "========================================"
Write-Host "  Project Normalization"
Write-Host "  Workspace: $wn"
Write-Host "  Mode: $(if($Fix){'Fix'}else{'Check'})"
Write-Host "========================================"
Write-Host ""

# ========== Check 1: Root directories ==========
Write-Host "--- 1. Root Directories ---"
$rootDirs = @(".agents", ".history", ".memory", "output", "input", ".temp")
$missingRoot = @()
foreach ($d in $rootDirs) {
    $p = Join-Path $wn $d
    if (-not (Test-Path $p)) { $missingRoot += $d }
}
if ($missingRoot.Count -eq 0) {
    Write-Host "  [PASS] All 6 root directories exist"
    $passes++
} else {
    foreach ($m in $missingRoot) {
        Write-Host "  [FAIL] Missing: $m/"
        $issues++
    }
    if ($Fix) {
        foreach ($m in $missingRoot) {
            $p = Join-Path $wn $m
            New-Item -ItemType Directory -Path $p -Force | Out-Null
            Write-Host "  [FIXED] Created: $m/"
        }
    }
}

# ========== Check 2: .agents/ ==========
Write-Host ""
Write-Host "--- 2. .agents/ Structure ---"
$agents = Join-Path $wn ".agents"
if (Test-Path $agents) {
    $requiredSkills = @("创建技能","子项目管理","安装技能","框架体检","版本控制备份","记忆管理","项目规范化","课题研究")
    $skillsDir = Join-Path $agents "skills"
    $rulesDir = Join-Path $agents "rules"
    $requiredRules = @("direction-rules.md","filename-rules.md","memory-rules.md","version-control-rules.md")

    if (-not (Test-Path $rulesDir)) {
        Write-Host "  [FAIL] Missing: .agents/rules/"
        $issues++
        if ($Fix) { New-Item -ItemType Directory -Path $rulesDir -Force | Out-Null; Write-Host "  [FIXED] Created: .agents/rules/" }
    } else {
        foreach ($r in $requiredRules) {
            $rp = Join-Path $rulesDir $r
            if (-not (Test-Path $rp)) {
                Write-Host "  [FAIL] Missing rule: rules/$r"
                $issues++
            } else { Write-Host "  [PASS] rules/$r"; $passes++ }
        }
    }

    if (-not (Test-Path $skillsDir)) {
        Write-Host "  [FAIL] Missing: .agents/skills/"
        $issues++
        if ($Fix) { New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null; Write-Host "  [FIXED] Created: .agents/skills/" }
    } else {
        $existingSkills = Get-ChildItem $skillsDir -Directory | ForEach-Object { $_.Name }
        foreach ($s in $requiredSkills) {
            if ($existingSkills -notcontains $s) {
                Write-Host "  [FAIL] Missing skill: skills/$s/"
                $issues++
                if ($Fix) {
                    Write-Host "  [NEEDS TEMPLATE] Cannot synthesize skills/$s/. Run the latest init EXE first, then run normalization again."
                }
            } else { Write-Host "  [PASS] skills/$s/"; $passes++ }
        }
        # Check extra skills
        foreach ($es in $existingSkills) {
            if ($requiredSkills -notcontains $es) {
                Write-Host "  [WARN] Extra skill: skills/$es/"
                $warnings++
                if ($Fix) { move-extra (Join-Path $skillsDir $es) ".agents/skills/$es" }
            }
        }
        # SKILL.md in each
        foreach ($s in $requiredSkills) {
            $sp = Join-Path $skillsDir "$s\SKILL.md"
            if ((Test-Path (Join-Path $skillsDir $s)) -and -not (Test-Path $sp)) {
                Write-Host "  [WARN] No SKILL.md in: skills/$s/"
                $warnings++
            }
        }
    }
} else {
    Write-Host "  [FAIL] .agents/ missing (covered by check #1)"
    $issues++
}

# ========== Check 3: output/ ==========
Write-Host ""
Write-Host "--- 3. output/ Structure ---"
$out = Join-Path $wn "output"
if (Test-Path $out) {
    $outItems = Get-ChildItem $out -ErrorAction SilentlyContinue
    $outFiles = @($outItems | Where-Object { -not $_.PSIsContainer })
    $outDirs = @($outItems | Where-Object { $_.PSIsContainer })

    if ($outFiles.Count -gt 0) {
        foreach ($f in $outFiles) {
            Write-Host "  [FAIL] Loose file in output/: $($f.Name)"
            $issues++
            if ($Fix) { move-extra $f.FullName "output/$($f.Name)" }
        }
    }

    foreach ($d in $outDirs) {
        if ($d.Name -notmatch '^\d{2}_.+_v\d+\.\d+\.\d+$') {
            Write-Host "  [FAIL] Bad naming: $($d.Name)"
            $issues++
            if ($Fix) { move-extra $d.FullName "output/$($d.Name)" }
        } else { Write-Host "  [PASS] $($d.Name)"; $passes++ }
    }

    Write-Host ""
    Write-Host "--- 3b. output/ Project Internals ---"
    foreach ($d in $outDirs | Where-Object { $_.Name -match '^\d{2}_.+_v\d+\.\d+\.\d+$' }) {
        $catalogPath = Join-Path $d.FullName "$S_mulu.md"
        $versionPath = Join-Path $d.FullName "$S_ver_log.md"
        $rootContentFiles = Get-ProjectRootContentFiles $d.FullName
        $isStructured = Test-StructuredProject $d.FullName
        $needsProjectFix = $false

        if (-not (Test-Path $catalogPath)) {
            Write-Host "  [FAIL] Missing $S_mulu.md: $($d.Name)"
            $issues++
            $needsProjectFix = $true
        }
        if (-not (Test-Path $versionPath)) {
            Write-Host "  [FAIL] Missing $S_ver_log.md: $($d.Name)"
            $issues++
            $needsProjectFix = $true
        }

        if ($isStructured) {
            $catalogText = if (Test-Path $catalogPath) { Read-Utf8Text $catalogPath } else { "" }
            foreach ($spec in $projectSubFolderSpecs) {
                $matches = Get-ProjectSubFolderMatches $d.FullName $spec
                if ($matches.Count -eq 0) {
                    Write-Host "  [FAIL] Missing sub-folder $($spec.Stem)_v*: $($d.Name)"
                    $issues++
                    $needsProjectFix = $true
                    continue
                }
                if ($matches.Count -gt 1) {
                    Write-Host "  [WARN] Duplicate sub-folder $($spec.Stem)_v*: $($d.Name)"
                    $warnings++
                }

                $primary = $matches[0]
                $actualVersion = Get-ProjectSubFolderVersion $primary.Name $spec
                $expectedVersion = Get-ExpectedSubFolderVersion $primary.FullName
                if ($actualVersion -ne $expectedVersion) {
                    Write-Host "  [WARN] Sub-folder version should be v${expectedVersion}: $($d.Name)/$($primary.Name)"
                    $warnings++
                    $needsProjectFix = $true
                }

                if ($catalogText -notmatch "##\s+$([regex]::Escape($spec.Stem))") {
                    Write-Host "  [WARN] $S_mulu.md missing section: $($spec.Stem) in $($d.Name)"
                    $warnings++
                    $needsProjectFix = $true
                }

                $versionedInnerFiles = @(Get-SubFolderContentFiles $primary.FullName |
                    Where-Object { $_.Name -match '_v\d+\.\d+\.\d+\.[^.]+$' })
                if ($versionedInnerFiles.Count -gt 0) {
                    Write-Host "  [WARN] Inner files should not carry version suffix in $($d.Name)/$($primary.Name): $($versionedInnerFiles.Count)"
                    $warnings++
                }

                if ($spec.Prefix -ne "03") {
                    $unnumbered = @(Get-SubFolderContentFiles $primary.FullName |
                        Where-Object { $_.Name -notmatch '^\d{2}_' })
                    if ($unnumbered.Count -gt 0) {
                        Write-Host "  [WARN] Unnumbered files in $($d.Name)/$($primary.Name): $($unnumbered.Count)"
                        $warnings++
                    }
                }
            }

            if ($rootContentFiles.Count -gt 0) {
                Write-Host "  [WARN] Legacy root content remains outside sub-folders in $($d.Name): $($rootContentFiles.Count)"
                $warnings++
            }
        } else {
            $unnumbered = @($rootContentFiles | Where-Object { $_.Name -notmatch '^\d{2}_' })
            if ($unnumbered.Count -gt 0) {
                Write-Host "  [WARN] Unnumbered legacy content files in $($d.Name): $($unnumbered.Count)"
                $warnings++
                $needsProjectFix = $true
            }
        }

        if (-not $needsProjectFix) {
            Write-Host "  [PASS] $($d.Name) internals"
            $passes++
        } elseif ($Fix) {
            Normalize-ProjectInternals $d.FullName
        }
    }
} else {
    Write-Host "  [FAIL] output/ missing (covered by check #1)"
    $issues++
}

# ========== Check 4: .memory/ ==========
Write-Host ""
Write-Host "--- 4. .memory/ Structure ---"
$mem = Join-Path $wn ".memory"
if (Test-Path $mem) {
    $memConv = Join-Path $mem $S_conv
    $memSys  = Join-Path $mem $S_sys_rec
    $memKnow = Join-Path $mem $S_knowledge
    $memMap  = Join-Path $mem "$($S_map).md"

    # Subdirs
    @($memConv, $memSys, $memKnow) | ForEach-Object {
        if (-not (Test-Path $_)) {
            Write-Host "  [FAIL] Missing: .memory/$(Split-Path $_ -Leaf)/"
            $issues++
            if ($Fix) { New-Item -ItemType Directory -Path $_ -Force | Out-Null; Write-Host "  [FIXED] Created: .memory/$(Split-Path $_ -Leaf)/" }
        } else { Write-Host "  [PASS] .memory/$(Split-Path $_ -Leaf)/"; $passes++ }
    }

    if (-not (Test-Path $memMap)) {
        Write-Host "  [FAIL] Missing: .memory/$($S_map).md"
        $issues++
        if ($Fix -and (Test-Path (Join-Path $wn "output"))) {
            $outputDirsForMap = @(Get-ChildItem (Join-Path $wn "output") -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d{2}_.+_v\d+\.\d+\.\d+$' })
            Repair-GlobalKnowledgeMap $memMap $outputDirsForMap
        }
    } else { Write-Host "  [PASS] .memory/$($S_map).md"; $passes++ }

    if (Test-Path $memMap) {
        $mapText = Read-Utf8Text $memMap
        $outputDirsForMap = @(Get-ChildItem (Join-Path $wn "output") -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^\d{2}_.+_v\d+\.\d+\.\d+$' })
        $mapProjects = @([regex]::Matches($mapText, '\| ([0-9]{2}_.+?_v[0-9]+\.[0-9]+\.[0-9]+) \|') | ForEach-Object { $_.Groups[1].Value })
        $outputNames = @($outputDirsForMap | ForEach-Object { $_.Name })
        $mapIsBad = Has-Mojibake $mapText
        $missingInMap = @($outputNames | Where-Object { $_ -notin $mapProjects })
        $extraInMap = @($mapProjects | Where-Object { $_ -notin $outputNames })

        if ($mapIsBad) {
            Write-Host "  [FAIL] $($S_map).md appears to contain mojibake"
            $issues++
        }
        foreach ($m in $missingInMap) {
            Write-Host "  [WARN] output/ not in $($S_map): $m"
            $warnings++
        }
        foreach ($m in $extraInMap) {
            Write-Host "  [WARN] $($S_map) not in output/: $m"
            $warnings++
        }
        if (($mapIsBad -or $missingInMap.Count -gt 0 -or $extraInMap.Count -gt 0) -and $Fix) {
            Repair-GlobalKnowledgeMap $memMap $outputDirsForMap
        } elseif (-not $mapIsBad -and $missingInMap.Count -eq 0 -and $extraInMap.Count -eq 0) {
            Write-Host "  [PASS] $($S_map).md matches output/"
            $passes++
        }
    }

    # System records fixed files
    if (Test-Path $memSys) {
        $sysFiles = @("$($S_rule_chg).md", "$($S_skill_chg).md", "$($S_script_gov).md", "$($S_lessons).md", "$($S_index).md")
        foreach ($sf in $sysFiles) {
            if (-not (Test-Path (Join-Path $memSys $sf))) {
                Write-Host "  [WARN] Missing system record: $sf"
                $warnings++
            }
        }
        $extraSys = Get-ChildItem $memSys -File | Where-Object { $sysFiles -notcontains $_.Name }
        foreach ($es in $extraSys) {
            Write-Host "  [WARN] Extra system record: $($es.Name)"
            $warnings++
            if ($Fix) { move-extra $es.FullName ".memory/$($S_sys_rec)/$($es.Name)" }
        }
    }

    # Knowledge: no _v* copies
    if (Test-Path $memKnow) {
        $vCopies = Get-ChildItem $memKnow -Recurse -File | Where-Object { $_.Name -match '_v\d+\.\d+\.\d+\.[^.]+$' }
        foreach ($vc in $vCopies) {
            Write-Host "  [FAIL] _v* copy in knowledge: $($vc.Name)"
            $issues++
            if ($Fix) { move-extra $vc.FullName ".memory/$($S_knowledge)/$($vc.Name)" }
        }
    }

    # Knowledge: no subdirs
    if (Test-Path $memKnow) {
        $extraKnow = Get-ChildItem $memKnow -Directory
        foreach ($ek in $extraKnow) {
            Write-Host "  [WARN] Extra dir in knowledge: $($ek.Name)/"
            $warnings++
            if ($Fix) { move-extra $ek.FullName ".memory/$($S_knowledge)/$($ek.Name)" }
        }
    }

    # Extra dirs in .memory/
    $memDirs = Get-ChildItem $mem -Directory | ForEach-Object { $_.Name }
    $allowedDirs = @($S_conv, $S_sys_rec, $S_knowledge)
    foreach ($md in $memDirs) {
        if ($allowedDirs -notcontains $md) {
            Write-Host "  [WARN] Extra dir in .memory/: $md/"
            $warnings++
            if ($Fix) { move-extra (Join-Path $mem $md) ".memory/$md" }
        }
    }
} else {
    Write-Host "  [FAIL] .memory/ missing (covered by check #1)"
    $issues++
}

# ========== Check 5: .history/ ==========
Write-Host ""
Write-Host "--- 5. .history/ Structure ---"
$hist = Join-Path $wn ".history"
if (Test-Path $hist) {
    $histDirs = Get-ChildItem $hist -Directory | ForEach-Object { $_.Name }
    $allowedHist = @(".agents", ".memory", "output")
    foreach ($h in $histDirs) {
        if ($allowedHist -notcontains $h) {
            Write-Host "  [WARN] Extra dir in .history/: $h/"
            $warnings++
            if ($Fix) { move-extra (Join-Path $hist $h) ".history/$h" }
        } else { Write-Host "  [PASS] .history/$h/"; $passes++ }
    }
    foreach ($ah in $allowedHist) {
        if ($histDirs -notcontains $ah) {
            Write-Host "  [WARN] Missing: .history/$ah/"
            $warnings++
            if ($Fix) { New-Item -ItemType Directory -Path (Join-Path $hist $ah) -Force | Out-Null; Write-Host "  [FIXED] Created: .history/$ah/" }
        }
    }

    # .history/.agents/ structure
    $histAgents = Join-Path $hist ".agents"
    if (Test-Path $histAgents) {
        $haDirs = Get-ChildItem $histAgents -Directory | ForEach-Object { $_.Name }
        $allowedHA = @("rules", "skills")
        foreach ($h in $haDirs) {
            if ($allowedHA -notcontains $h) {
                Write-Host "  [WARN] Extra in .history/.agents/: $h/"
                $warnings++
                if ($Fix) { move-extra (Join-Path $histAgents $h) ".history/.agents/$h" }
            }
        }

        # Check skills/ for timestamp-less folders
        $histSkills = Join-Path $histAgents "skills"
        if (Test-Path $histSkills) {
            $hsDirs = Get-ChildItem $histSkills -Directory
            foreach ($hs in $hsDirs) {
                if ($hs.Name -notmatch '_\d{14}$') {
                    Write-Host "  [WARN] No timestamp in .history skill: $($hs.Name)"
                    $warnings++
                    if ($Fix) {
                        $ts = Get-Date -Format "yyyyMMddHHmmss"
                        $newName = $hs.Name + "_$ts"
                        $newPath = Join-Path $histSkills $newName
                        Rename-Item $hs.FullName $newName -Force
                        Write-Host "  [FIXED] Renamed: $($hs.Name) -> $newName"
                    }
                }
            }
        }

        # Check rules/ naming
        $histRules = Join-Path $histAgents "rules"
        if (Test-Path $histRules) {
            $hrFiles = Get-ChildItem $histRules -File
            foreach ($hr in $hrFiles) {
                if ($hr.Name -match '_20\d{10,14}\.md$') { continue }  # ok: with timestamp
                if ($hr.Name -in @("direction-rules.md","filename-rules.md","memory-rules.md","version-control-rules.md")) {
                    Write-Host "  [PASS] rules/$($hr.Name)"; $passes++
                } else {
                    Write-Host "  [WARN] Odd rule file: $($hr.Name)"
                    $warnings++
                }
            }
        }
    }

    # .history/output/ naming
    $histOut = Join-Path $hist "output"
    if (Test-Path $histOut) {
        $hoDirs = Get-ChildItem $histOut -Directory
        foreach ($ho in $hoDirs) {
            if ($ho.Name -notmatch '_\d{14}$') {
                Write-Host "  [WARN] No timestamp in output history: $($ho.Name)"
                $warnings++
            }
        }
    }
} else {
    Write-Host "  [FAIL] .history/ missing (covered by check #1)"
    $issues++
}

# ========== Check 6: .temp/ and input/ ==========
Write-Host ""
Write-Host "--- 6. .temp/ and input/ ---"
$temp = Join-Path $wn ".temp"
$inp  = Join-Path $wn "input"
if (Test-Path $temp) { Write-Host "  [PASS] .temp/ exists"; $passes++ }
else { Write-Host "  [FAIL] Missing .temp/"; $issues++; if ($Fix) { New-Item -ItemType Directory -Path $temp -Force | Out-Null; Write-Host "  [FIXED] Created .temp/" } }
if (Test-Path $inp) { Write-Host "  [PASS] input/ exists"; $passes++ }
else { Write-Host "  [FAIL] Missing input/"; $issues++; if ($Fix) { New-Item -ItemType Directory -Path $inp -Force | Out-Null; Write-Host "  [FIXED] Created input/" } }

Write-Host ""
Write-Host "========================================"
Write-Host "  Passed : $passes  |  Failed : $issues  |  Warnings: $warnings"
Write-Host "========================================"

if ($Fix -and $fixLog.Count -gt 0) {
    Write-Host ""
    Write-Host "--- Fix Summary ---"
    foreach ($fl in $fixLog) { Write-Host "  $fl" }
}

if ($issues -gt 0) { exit 1 } else { exit 0 }
