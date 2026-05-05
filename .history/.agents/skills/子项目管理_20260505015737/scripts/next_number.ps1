<#
.SYNOPSIS
    Get the next file number for a sub-project.
.DESCRIPTION
    Scans a sub-project directory for content files matching the pattern
    {NN}_{topic}_v{x.y.z}.ext and returns the next available number (NN).
    Skips fixed files: catalog.md, version-log.md.
.PARAMETER ProjectPath
    Path to the sub-project directory.
.EXAMPLE
    .\next_number.ps1 -ProjectPath "output\06_catalog_test_v1.0.0"
    # Returns: 01  (if no content files exist yet)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
)

if (-not (Test-Path $ProjectPath)) {
    Write-Error "Project path not found: $ProjectPath"
    exit 1
}

$fixedFiles = @("目录.md", "版本记录.md")

$existingNumbers = @(
    Get-ChildItem -Path $ProjectPath -File -ErrorAction SilentlyContinue |
        Where-Object { $fixedFiles -notcontains $_.Name } |
        ForEach-Object {
            if ($_.Name -match '^(\d{2})_') {
                [int]$matches[1]
            }
        }
) | Sort-Object -Descending

$nextNumber = if ($existingNumbers.Count -gt 0) {
    $existingNumbers[0] + 1
} else {
    1
}

"{0:D2}" -f $nextNumber
