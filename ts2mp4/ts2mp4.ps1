[CmdletBinding()]
param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$paths
)

chcp 65001 > $null
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new()

# 关键：静默 PowerShell 非致命错误
$ErrorActionPreference = "SilentlyContinue"

if (-not $paths) {
    Write-Host "请拖入 TS 文件或文件夹"
    Pause
    Exit
}

$tsFiles = @()

foreach ($p in $paths) {

    if (-not (Test-Path $p)) { continue }

    $item = Get-Item $p

    if ($item.PSIsContainer) {

        # 文件夹 → 递归扫描
        $tsFiles += Get-ChildItem -Path $p -Recurse -Filter *.ts

    } else {

        # 单个文件
        if ($item.Extension -ieq ".ts") {
            $tsFiles += $item
        }
    }
}

if (-not $tsFiles) {
    Write-Host "未找到 TS 文件"
    Pause
    Exit
}

$cpuThreads = [Environment]::ProcessorCount
$maxJobs = [Math]::Max(1, [Math]::Floor($cpuThreads / 4))

Write-Host "逻辑核心数: $cpuThreads"
Write-Host "并行任务数: $maxJobs"
Write-Host "文件总数: $($tsFiles.Count)"
Write-Host ""

$success = 0
$failed = 0
$completed = 0
$total = $tsFiles.Count

$startTime = Get-Date
$jobs = @()

foreach ($file in $tsFiles) {

    while ($jobs.Count -ge $maxJobs) {

        $done = Wait-Job -Job $jobs -Any -Timeout 1

        if ($done) {
            foreach ($j in $done) {

                $result = Receive-Job $j
                if ($result -eq 0) { $success++ } else { $failed++ }

                Remove-Job $j
                $jobs = $jobs | Where-Object { $_.Id -ne $j.Id }

                $completed++

                Write-Progress `
                    -Activity "TS → MP4 转换中" `
                    -Status "已完成 $completed / $total" `
                    -PercentComplete (($completed / $total) * 100)
            }
        }
    }

    $jobs += Start-Job -ArgumentList $file.FullName -ScriptBlock {

        param($inputFile)

        $outputFile = [System.IO.Path]::ChangeExtension($inputFile, ".mp4")

        & ffmpeg -i "$inputFile" `
                 -c copy `
                 -bsf:a aac_adtstoasc `
                 "$outputFile" `
                 -y -loglevel error

        if ($LASTEXITCODE -eq 0) {
            Remove-Item "$inputFile" -Force
        }

        return $LASTEXITCODE
    }
}

while ($jobs.Count -gt 0) {

    $done = Wait-Job -Job $jobs -Any

    foreach ($j in $done) {

        $result = Receive-Job $j
        if ($result -eq 0) { $success++ } else { $failed++ }

        Remove-Job $j
        $jobs = $jobs | Where-Object { $_.Id -ne $j.Id }

        $completed++

        Write-Progress `
            -Activity "TS → MP4 转换中" `
            -Status "已完成 $completed / $total" `
            -PercentComplete (($completed / $total) * 100)
    }
}

$elapsed = ((Get-Date) - $startTime).TotalSeconds
$speed = [Math]::Round($completed / $elapsed, 2)

Write-Host ""
Write-Host "=============================="
Write-Host "处理完成"
Write-Host "成功: $success"
Write-Host "失败: $failed"
Write-Host "耗时: $([Math]::Round($elapsed,1)) 秒"
Write-Host "速率: $speed 文件 / 秒"
Write-Host "=============================="

Pause
