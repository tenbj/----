$tc = Split-Path $MyInvocation.MyCommand.Path -Parent
$ws = Split-Path $tc -Parent
$fw = [System.Text.Encoding]::UTF8.GetString(@(0xE6,0xA1,0x86,0xE6,0x9E,0xB6,0xE4,0xBD,0x93,0xE6,0xA3,0x80))
$skills = Join-Path $ws ".agents\skills"
$allSkillDirs = Get-ChildItem $skills -Directory
foreach ($d in $allSkillDirs) {
    if ($d.Name.Contains($fw) -and (-not $d.Name.Contains("_"))) {
        $f = Join-Path $d.FullName "scripts\framework-check.ps1"
        break
    }
}
$c = [System.IO.File]::ReadAllText($f)
$c = $c.Replace("framework-check.ps1`")`r`n))", "framework-check.ps1`")`r`n)")
[System.IO.File]::WriteAllText($f, $c, [System.Text.UTF8Encoding]::new($true))
Write-Host "Fixed double paren"
