import pathlib

script_content = """param()
$skillPath = Join-Path (Get-Location) ".agents\\skills\\记忆管理\\scripts"
Get-ChildItem -LiteralPath $skillPath -Filter "*.ps1" | ForEach-Object {
    $p = $_.FullName
    $c = [System.IO.File]::ReadAllText($p)
    [System.IO.File]::WriteAllText($p, $c, [System.Text.UTF8Encoding]::new($true))
    Write-Host ("BOM fixed: " + $_.Name)
}
"""

p = pathlib.Path(r"e:\my_project\知识研究\.temp\fix_bom3.ps1")
p.write_bytes(b"\xef\xbb\xbf" + script_content.encode("utf-8"))
print("Script written with BOM OK")
