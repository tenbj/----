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
    $requiredSkills = @("创建技能","子项目管理","安装技能","框架体检","版本控制备份","记忆管理","项目规范化")
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
                if ($Fix) { New-Item -ItemType Directory -Path (Join-Path $skillsDir $s) -Force | Out-Null; Write-Host "  [FIXED] Created: skills/$s/" }
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
    } else { Write-Host "  [PASS] .memory/$($S_map).md"; $passes++ }

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
