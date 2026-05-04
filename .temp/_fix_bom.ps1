$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$wsRoot = Split-Path $scriptRoot -Parent
$skillsDir = Join-Path $wsRoot ".agents\skills"
$s_gh = [System.Text.Encoding]::UTF8.GetString(@(0xE9,0xA1,0xB9,0xE7,0x9B,0xAE,0xE8,0xA7,0x84,0xE8,0x8C,0x83,0xE5,0x8C,0x96))
$allDirs = Get-ChildItem $skillsDir -Directory
foreach ($d in $allDirs) {
    if ($d.Name.Contains($s_gh) -and (-not $d.Name.Contains("_"))) {
        $path = Join-Path $d.FullName "scripts\normalize.ps1"
        $c = [System.IO.File]::ReadAllText($path)
        $c = $c.Replace("_20\d{12}\.md", "_20\d{10,14}\.md")
        [System.IO.File]::WriteAllText($path, $c, [System.Text.UTF8Encoding]::new($true))
        Write-Host "Fixed"
        break
    }
}
