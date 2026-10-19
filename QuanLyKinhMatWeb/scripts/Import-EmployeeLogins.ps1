#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$entry = Join-Path $projectRoot 'runtime\KinhMat.Web.dll'
if (-not (Test-Path -LiteralPath $entry)) { throw 'Can publish runtime truoc khi chuyen tai khoan.' }
$dotnet = Get-Command dotnet -ErrorAction Stop
& $dotnet.Source $entry --contentRoot $projectRoot --import-employee-logins
if ($LASTEXITCODE -ne 0) { throw 'Chuyen tai khoan that bai. Khong doi database goc.' }
