<#
.SYNOPSIS
    Initialize a new knowledge-research workspace skeleton.
.DESCRIPTION
    This script creates the reusable project skeleton for a new workspace:
    .agent/rules, selected core .agent/skills, .memory, .history, input, and output.

    By default it copies the current workspace's core rules and core skills:
    子项目管理, 版本控制备份, 记忆管理

    It does not copy current project output, history snapshots, or old memory content.
.PARAMETER TargetRoot
    The new workspace root to initialize.
.PARAMETER SourceRoot
    The source workspace root. If omitted, the script auto-detects it by walking upward
    from this script's folder.
.PARAMETER CoreSkillNames
    Skill folder names to copy into the new workspace.
.PARAMETER Force
    Allows writing into an existing target folder. Existing copied files may be overwritten,
    but the script never deletes existing target content.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File ".\初始化知识研究工作区_v1.0.0.ps1" -TargetRoot "E:\my_project\新知识研究"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetRoot,

    [Parameter(Mandatory = $false)]
    [string]$SourceRoot = "",

    [Parameter(Mandatory = $false)]
    [string[]]$CoreSkillNames = @("子项目管理", "版本控制备份", "记忆管理"),

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-AbsolutePath {
    param([string]$Path)
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

function Normalize-PathText {
    param([string]$Path)
    return ((Get-AbsolutePath $Path).TrimEnd('\', '/'))
}

function Find-SourceWorkspaceRoot {
    param([string]$StartPath)

    $searchDir = Normalize-PathText $StartPath
    while ($searchDir) {
        $rulesDir = Join-Path $searchDir ".agent\rules"
        $skillsDir = Join-Path $searchDir ".agent\skills"
        if ((Test-Path -LiteralPath $rulesDir) -and (Test-Path -LiteralPath $skillsDir)) {
            return $searchDir
        }

        $parent = Split-Path $searchDir -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $searchDir) {
            break
        }
        $searchDir = $parent
    }

    return $null
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Assert-SourceDirectory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Required source directory not found: $Path"
    }
}

function Copy-DirectoryContents {
    param(
        [string]$SourceDir,
        [string]$DestinationDir
    )

    Assert-SourceDirectory $SourceDir
    Ensure-Directory $DestinationDir

    if ((Get-ChildItem -LiteralPath $DestinationDir -Force -ErrorAction SilentlyContinue | Select-Object -First 1) -and -not $Force) {
        throw "Destination already contains files. Re-run with -Force to merge: $DestinationDir"
    }

    Get-ChildItem -LiteralPath $SourceDir -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $DestinationDir -Recurse -Force
    }
}

function Write-Utf8FileIfMissing {
    param(
        [string]$Path,
        [string]$Content
    )

    if ((Test-Path -LiteralPath $Path) -and -not $Force) {
        return
    }

    Ensure-Directory (Split-Path $Path -Parent)
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

function Replace-TextLiteralIgnoreCase {
    param(
        [string]$Text,
        [string]$OldValue,
        [string]$NewValue
    )

    if ([string]::IsNullOrWhiteSpace($OldValue)) {
        return $Text
    }

    $regex = [regex]::new([regex]::Escape($OldValue), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    return $regex.Replace($Text, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $NewValue })
}

function Update-AgentPathReferences {
    param(
        [string]$TargetAgentRoot,
        [string]$OldRoot,
        [string]$NewRoot
    )

    if (-not (Test-Path -LiteralPath $TargetAgentRoot)) {
        return
    }

    Get-ChildItem -LiteralPath $TargetAgentRoot -Recurse -File |
        Where-Object { $_.Extension -in @(".md", ".ps1") } |
        ForEach-Object {
            $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
            $updated = Replace-TextLiteralIgnoreCase -Text $content -OldValue $OldRoot -NewValue $NewRoot
            if ($updated -ne $content) {
                Set-Content -Path $_.FullName -Value $updated -Encoding UTF8
            }
        }
}

$scriptStart = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

if ([string]::IsNullOrWhiteSpace($SourceRoot)) {
    $SourceRoot = Find-SourceWorkspaceRoot -StartPath $scriptStart
    if (-not $SourceRoot) {
        throw "Source workspace root was not auto-detected. Pass -SourceRoot explicitly."
    }
} else {
    $SourceRoot = Normalize-PathText $SourceRoot
}

$TargetRoot = Normalize-PathText $TargetRoot
$SourceRoot = Normalize-PathText $SourceRoot

if ($TargetRoot.Equals($SourceRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "TargetRoot must be different from SourceRoot."
}

if ((Test-Path -LiteralPath $TargetRoot -PathType Leaf)) {
    throw "TargetRoot points to a file, not a directory: $TargetRoot"
}

if ((Test-Path -LiteralPath $TargetRoot) -and
    (Get-ChildItem -LiteralPath $TargetRoot -Force -ErrorAction SilentlyContinue | Select-Object -First 1) -and
    -not $Force) {
    throw "TargetRoot already contains files. Choose an empty folder or re-run with -Force: $TargetRoot"
}

Assert-SourceDirectory (Join-Path $SourceRoot ".agent\rules")
Assert-SourceDirectory (Join-Path $SourceRoot ".agent\skills")

$coreDirectories = @(
    ".agent",
    ".agent\rules",
    ".agent\skills",
    ".history",
    ".history\output",
    ".history\.agent\rules",
    ".history\.agent\skills",
    ".history\.memory\知识提炼",
    ".history\.memory\全局知识地图",
    ".memory",
    ".memory\对话记录",
    ".memory\知识提炼",
    ".memory\系统记录",
    "input",
    "output"
)

foreach ($dir in $coreDirectories) {
    Ensure-Directory (Join-Path $TargetRoot $dir)
}

Copy-DirectoryContents -SourceDir (Join-Path $SourceRoot ".agent\rules") -DestinationDir (Join-Path $TargetRoot ".agent\rules")

foreach ($skillName in $CoreSkillNames) {
    $sourceSkill = Join-Path (Join-Path $SourceRoot ".agent\skills") $skillName
    $targetSkill = Join-Path (Join-Path $TargetRoot ".agent\skills") $skillName
    Copy-DirectoryContents -SourceDir $sourceSkill -DestinationDir $targetSkill
}

Update-AgentPathReferences -TargetAgentRoot (Join-Path $TargetRoot ".agent") -OldRoot $SourceRoot -NewRoot $TargetRoot

$mapContent = @"
<!-- memory-version: 1.0.0 -->
# 全局知识地图

> 所有研究子项目的总索引，新建子项目时自动更新。

| 话题 | 子项目文件夹 | 创建时间 | 状态 | 核心结论（一句话） |
|------|------------|---------|------|----------------|
"@

$systemRecordContent = @"
# 系统记录 · rules-skills

> 记录 Rule、Skill、脚本、备份流程、Memory 机制等系统治理相关对话，按时间追加。

---

## $(Get-Date -Format "yyyy-MM-dd HH:mm")

**用户问**：初始化新的知识研究工作区骨架
**AI做了**：通过脚本创建目录、规则、核心脚本能力、空记忆区和历史区

---
"@

Write-Utf8FileIfMissing -Path (Join-Path $TargetRoot ".memory\全局知识地图.md") -Content $mapContent
Write-Utf8FileIfMissing -Path (Join-Path $TargetRoot ".memory\系统记录\rules-skills.md") -Content $systemRecordContent

Write-Host ""
Write-Host "=========================================="
Write-Host "  Workspace Skeleton Initialized"
Write-Host "=========================================="
Write-Host "  Source : $SourceRoot"
Write-Host "  Target : $TargetRoot"
Write-Host "  Rules  : .agent\rules"
Write-Host "  Skills : $($CoreSkillNames -join ', ')"
Write-Host "  Memory : .memory 当前态已初始化"
Write-Host "  History: .history 已初始化"
Write-Host "=========================================="
Write-Host ""
Write-Host "Next: run .agent\skills\子项目管理\scripts\new_project.ps1 in the new workspace."

