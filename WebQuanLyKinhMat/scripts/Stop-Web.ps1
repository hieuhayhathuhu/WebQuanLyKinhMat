#Requires -Version 5.1
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$pidPath=Join-Path $projectRoot 'App_Data\server.pid'
if (-not (Test-Path -LiteralPath $pidPath)) { Write-Host 'Khong co tien trinh web do launcher nay khoi dong.'; return }
$serverProcessId=[int](Get-Content -LiteralPath $pidPath -Raw).Trim()
$process=Get-CimInstance Win32_Process -Filter "ProcessId=$serverProcessId" -ErrorAction SilentlyContinue
if ($null -eq $process) { Write-Host 'Ung dung da dung.'; return }
$runtimeDll=Join-Path $projectRoot 'runtime\KinhMat.Web.dll'
$buildDll=Join-Path $projectRoot 'bin\Release\net10.0\KinhMat.Web.dll'
if (-not ($process.CommandLine.Contains($runtimeDll) -or $process.CommandLine.Contains($buildDll))) { throw 'PID da thay doi; khong dung tien trinh khac.' }
Stop-Process -Id $serverProcessId
Write-Host 'Da dung ung dung KinhMat.Web.'
