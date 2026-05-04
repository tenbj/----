<#
.SYNOPSIS
    一键将 初始化工作区.py + templates/ 编译为单文件 EXE。
.DESCRIPTION
    运行此脚本后，dist/ 下会生成 初始化工作区.exe。
    将该 EXE 放到任意目录，双击即可初始化知识研究工作区骨架。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File ".\build.ps1"
#>

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host ""
Write-Host "=========================================="
Write-Host "  Build: 初始化工作区.exe"
Write-Host "=========================================="

# 检查 Python
$pyVersion = python --version 2>&1
Write-Host "  Python : $pyVersion"

# 检查 pyinstaller
$piCheck = pip show pyinstaller 2>&1
if ($piCheck -match "WARNING: Package\(s\) not found") {
    Write-Host "  Installing pyinstaller ..."
    pip install pyinstaller
}

Write-Host "  Building EXE ..."
Write-Host ""

# 注意：PyInstaller 不支持中文路径，必须使用绝对路径
# 编译入口文件必须用 ASCII 文件名（init_workspace.py）
# 输出 EXE 可以用中文名（--name 参数）

$srcDir      = $PSScriptRoot
$templatesAbs = "$srcDir\templates"
$distAbs     = (Split-Path $srcDir -Parent) + "\dist"
$buildTmpAbs = (Split-Path $srcDir -Parent) + "\build_tmp"
$scriptAbs   = "$srcDir\init_workspace.py"

# 同步入口文件（确保与中文版保持一致）
Copy-Item "$srcDir\初始化工作区.py" "$scriptAbs" -Force

pyinstaller `
    --onefile `
    --noconsole `
    --add-data "$templatesAbs;templates" `
    --name "初始化工作区" `
    --distpath $distAbs `
    --workpath $buildTmpAbs `
    --specpath $buildTmpAbs `
    $scriptAbs

Write-Host ""

$exePath = Resolve-Path "..\dist\初始化工作区.exe" -ErrorAction SilentlyContinue
if ($exePath) {
    $sizeMB = [math]::Round((Get-Item $exePath).Length / 1MB, 1)
    Write-Host "=========================================="
    Write-Host "  ✅ Build Successful"
    Write-Host "  EXE  : $exePath"
    Write-Host "  Size : $sizeMB MB"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "使用方法："
    Write-Host "  将 初始化工作区.exe 复制到任意新建的空目录，双击运行即可。"
} else {
    Write-Host "❌ Build failed. Please check the output above."
    exit 1
}
