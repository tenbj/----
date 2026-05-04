$tc = Split-Path $MyInvocation.MyCommand.Path -Parent
$ws = Split-Path $tc -Parent
$targetDir = $null
$allDirs = Get-ChildItem (Join-Path $ws ".history\.agents\skills") -Directory
foreach ($d in $allDirs) {
    if ($d.Name -like "*_20260504215340") {
        $targetDir = $d.FullName
        break
    }
}
if (-not $targetDir) { Write-Error "Snapshot not found"; exit 1 }
$src = Join-Path $targetDir "scripts\framework-check.ps1"
$skills = Join-Path $ws ".agents\skills"
$fw = [System.Text.Encoding]::UTF8.GetString(@(0xE6,0xA1,0x86,0xE6,0x9E,0xB6,0xE4,0xBD,0x93,0xE6,0xA3,0x80))
$allSkillDirs = Get-ChildItem $skills -Directory
$dst = $null
foreach ($d2 in $allSkillDirs) {
    if ($d2.Name.Contains($fw) -and (-not $d2.Name.Contains("_"))) {
        $dst = Join-Path $d2.FullName "scripts\framework-check.ps1"
        break
    }
}
if (-not $dst) { Write-Error "destination not found"; exit 1 }
$c = [System.IO.File]::ReadAllText($src)
[System.IO.File]::WriteAllText($dst, $c, [System.Text.UTF8Encoding]::new($true))
Write-Host "Restored"
