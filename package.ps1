# 思源笔记插件打包脚本
# 用法: 在项目根目录运行 .\package.ps1

$ErrorActionPreference = "Stop"

# 获取版本号
$pluginJson = Get-Content -Path "plugin.json" -Raw | ConvertFrom-Json
$version = $pluginJson.version
$pluginName = $pluginJson.name

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  思源插件打包脚本" -ForegroundColor Cyan
Write-Host "  插件名称: $pluginName" -ForegroundColor Cyan
Write-Host "  版本: $version" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 定义输出文件名
$outputZip = "package.zip"

# 删除旧的打包文件
if (Test-Path $outputZip) {
    Remove-Item $outputZip -Force
    Write-Host "[清理] 删除旧的 $outputZip" -ForegroundColor Yellow
}

# 需要打包的文件和目录
$filesToInclude = @(
    "plugin.json",
    "index.js",
    "index.css",
    "style.css",
    "icon.png",
    "preview.png",
    "README.md",
    "README_zh_CN.md",
    "font"
)

# 检查必要文件是否存在
Write-Host "`n[检查] 验证必要文件..." -ForegroundColor Cyan
$missingFiles = @()
foreach ($file in $filesToInclude) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
        Write-Host "  [缺失] $file" -ForegroundColor Red
    } else {
        $item = Get-Item $file
        if ($item.PSIsContainer) {
            $count = (Get-ChildItem $file -Recurse -File).Count
            Write-Host "  [OK] $file/ ($count 个文件)" -ForegroundColor Green
        } else {
            $size = [math]::Round($item.Length / 1KB, 2)
            Write-Host "  [OK] $file ($size KB)" -ForegroundColor Green
        }
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "`n[错误] 缺少必要文件，无法打包！" -ForegroundColor Red
    exit 1
}

# 检查图片大小
Write-Host "`n[检查] 验证图片大小..." -ForegroundColor Cyan
$iconSize = (Get-Item "icon.png").Length / 1KB
$previewSize = (Get-Item "preview.png").Length / 1KB

if ($iconSize -gt 20) {
    Write-Host "  [警告] icon.png ($([math]::Round($iconSize, 2)) KB) 超过 20KB 限制！" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] icon.png ($([math]::Round($iconSize, 2)) KB)" -ForegroundColor Green
}

if ($previewSize -gt 200) {
    Write-Host "  [警告] preview.png ($([math]::Round($previewSize, 2)) KB) 超过 200KB 限制！" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] preview.png ($([math]::Round($previewSize, 2)) KB)" -ForegroundColor Green
}

# 创建临时目录
$tempDir = "temp_package"
if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir | Out-Null

# 复制文件到临时目录
Write-Host "`n[打包] 复制文件..." -ForegroundColor Cyan
foreach ($file in $filesToInclude) {
    if (Test-Path $file) {
        $item = Get-Item $file
        if ($item.PSIsContainer) {
            Copy-Item $file -Destination "$tempDir\$file" -Recurse
            Write-Host "  复制目录: $file/" -ForegroundColor Gray
        } else {
            Copy-Item $file -Destination "$tempDir\$file"
            Write-Host "  复制文件: $file" -ForegroundColor Gray
        }
    }
}

# 创建 ZIP 文件
Write-Host "`n[打包] 创建 $outputZip..." -ForegroundColor Cyan
Compress-Archive -Path "$tempDir\*" -DestinationPath $outputZip -Force

# 清理临时目录
Remove-Item $tempDir -Recurse -Force

# 显示结果
$zipSize = [math]::Round((Get-Item $outputZip).Length / 1KB, 2)
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  打包完成！" -ForegroundColor Green
Write-Host "  输出文件: $outputZip" -ForegroundColor Green
Write-Host "  文件大小: $zipSize KB" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n[下一步] 发布流程:" -ForegroundColor Cyan
Write-Host "  1. 在 GitHub 创建 Release，Tag 为 v$version" -ForegroundColor White
Write-Host "  2. 上传 $outputZip 作为 Release 附件" -ForegroundColor White
Write-Host "  3. 首次上架需要 PR 到 siyuan-note/bazaar 仓库" -ForegroundColor White
Write-Host "     - Fork https://github.com/siyuan-note/bazaar" -ForegroundColor Gray
Write-Host "     - 在 plugins.json 中添加你的仓库路径" -ForegroundColor Gray
Write-Host "     - 提交 PR 等待审核" -ForegroundColor Gray
