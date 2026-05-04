$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$wsRoot = Split-Path $scriptRoot -Parent
$skillsDir = Join-Path $wsRoot ".agents\skills"

# Chinese strings via byte arrays
$s_km        = [System.Text.Encoding]::UTF8.GetString(@(0xE6,0xA1,0x86,0xE6,0x9E,0xB6,0xE4,0xBD,0x93,0xE6,0xA3,0x80))
$s_bb        = [System.Text.Encoding]::UTF8.GetString(@(0xE7,0x89,0x88,0xE6,0x9C,0xAC,0xE6,0x8E,0xA7,0xE5,0x88,0xB6,0xE5,0xA4,0x87,0xE4,0xBB,0xBD))
$s_xmgl      = [System.Text.Encoding]::UTF8.GetString(@(0xE5,0xAD,0x90,0xE9,0xA1,0xB9,0xE7,0x9B,0xAE,0xE7,0xAE,0xA1,0xE7,0x90,0x86))
$s_mulu      = [System.Text.Encoding]::UTF8.GetString(@(0xE7,0x9B,0xAE,0xE5,0xBD,0x95))
$s_ver_log   = [System.Text.Encoding]::UTF8.GetString(@(0xE7,0x89,0x88,0xE6,0x9C,0xAC,0xE8,0xAE,0xB0,0xE5,0xBD,0x95))

# Find framework-check skill
$allDirs = Get-ChildItem $skillsDir -Directory
$targetDir = $null
foreach ($d in $allDirs) {
    if ($d.Name.Contains($s_km) -and (-not $d.Name.Contains("_"))) {
        $targetDir = $d.FullName
        break
    }
}
if (-not $targetDir) { Write-Error "framework-check skill dir not found"; exit 1 }

$path = Join-Path $targetDir "scripts\framework-check.ps1"
$c = [System.IO.File]::ReadAllText($path)

# --- Update DESCRIPTION ---
$oldDesc = "Checks: conversation records, .ps1 BOM, .memory cleanliness, knowledge map alignment, input/ path."
$newDesc = "Checks: conversation records, .ps1 BOM, .memory cleanliness, knowledge map alignment, input/ path, sub-project catalog completeness, file numbering."
$c = $c.Replace($oldDesc, $newDesc)

# --- Update #2 BOM check ---
# Build old & new patterns
$old1 = ".agents\skills\" + $s_bb + "\scripts\backup.ps1"
$old2 = ".agents\skills\" + $s_xmgl + "\scripts\new_project.ps1"
$new3 = ".agents\skills\" + $s_xmgl + "\scripts\next_number.ps1"
$new4 = ".agents\skills\" + $s_xmgl + "\scripts\normalize_project.ps1"
$new5 = ".agents\skills\" + $s_km + "\scripts\framework-check.ps1"

# Use regex-like matching: find the ps1Files block and replace
$bomStart = $c.IndexOf('$ps1Files = @(')
$bomEnd = $c.IndexOf(')', $bomStart)
# Find the closing of the array: look for the line with just ')' after the last entry
$bomClose = $c.IndexOf("`r`n)", $bomEnd) + 1
if ($bomClose -le 0) { $bomClose = $c.IndexOf("`n)", $bomEnd) + 1 }
if ($bomClose -le 0) { $bomClose = $bomEnd + 1 }

$newBom = '$ps1Files = @(' + "`r`n    (Join-Path `$workspaceRoot `"$old1`"),`r`n    (Join-Path `$workspaceRoot `"$old2`"),`r`n    (Join-Path `$workspaceRoot `"$new3`"),`r`n    (Join-Path `$workspaceRoot `"$new4`"),`r`n    (Join-Path `$workspaceRoot `"$new5`")`r`n)"

$c = $c.Substring(0, $bomStart) + $newBom + $c.Substring($bomClose + 1)

# --- Build Check #6: catalog completeness ---
$chk6 = @'

# 6. Sub-project catalog completeness
Write-Host ""
Write-Host "--- 6. MULU_PH.md Completeness ---"
$missingCatalog = @()
foreach ($dir in $outputDirs) {
    $catalogPath = Join-Path $dir.FullName "MULU_PH.md"
    if (-not (Test-Path $catalogPath)) {
        $missingCatalog += $dir.Name
    }
}
if ($missingCatalog.Count -eq 0) {
    Write-Host "  [PASS] All $($outputDirs.Count) subprojects have MULU_PH.md"
    $passes++
} else {
    foreach ($m in $missingCatalog) {
        Write-Host "  [FAIL] Missing MULU_PH.md: $m"
        $issues++
    }
}
'@
$chk6 = $chk6.Replace('MULU_PH', $s_mulu)

# --- Build Check #7: file numbering ---
$chk7 = @'

# 7. File numbering ({NN}_ prefix)
Write-Host ""
Write-Host "--- 7. File Numbering ---"
$unnumberedFiles = @()
foreach ($dir in $outputDirs) {
    $files = Get-ChildItem $dir.FullName -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("MULU_PH.md", "VER_LOG_PH.md") -and $_.Name -match '\.(md|html|txt|ps1)$' }
    foreach ($f in $files) {
        if ($f.Name -notmatch '^\d{2}_') {
            $relPath = "$($dir.Name)\$($f.Name)"
            $unnumberedFiles += $relPath
        }
    }
}
if ($unnumberedFiles.Count -eq 0) {
    Write-Host "  [PASS] All content files have {NN}_ prefix"
    $passes++
} else {
    Write-Host "  [WARN] $($unnumberedFiles.Count) files without {NN}_ prefix:"
    foreach ($u in $unnumberedFiles) {
        Write-Host "     $u"
    }
    $warnings++
}
'@
$chk7 = $chk7.Replace('MULU_PH', $s_mulu)
$chk7 = $chk7.Replace('VER_LOG_PH', $s_ver_log)

# Insert before the final summary block
$marker = 'Write-Host "  Passed : $passes  |  Failed : $issues  |  Warnings: $warnings"'
$pos = $c.LastIndexOf($marker)
if ($pos -gt 0) {
    # Go back to the empty Write-Host before summary
    $insertPos = $c.LastIndexOf('Write-Host ""', $pos)
    if ($insertPos -gt 0) {
        $c = $c.Substring(0, $insertPos) + $chk6 + $chk7 + "`r`n" + $c.Substring($insertPos)
    }
}

[System.IO.File]::WriteAllText($path, $c, [System.Text.UTF8Encoding]::new($true))
Write-Host "framework-check.ps1 updated"
