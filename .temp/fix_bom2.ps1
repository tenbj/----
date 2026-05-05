 = Get-ChildItem -LiteralPath '.agents\skills记忆管理\scripts' -Filter '*.ps1'
foreach ( in ) {
     = .FullName
     = [System.IO.File]::ReadAllText()
    [System.IO.File]::WriteAllText(, , [System.Text.UTF8Encoding]::new(True))
    Write-Host ('BOM fixed: ' + )
}
