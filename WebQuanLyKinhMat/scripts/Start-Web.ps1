#Requires -Version 5.1
[CmdletBinding()]
param([int]$Port = 5080, [switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$url = "http://127.0.0.1:$Port"
$dotnetCommand = Get-Command dotnet -ErrorAction SilentlyContinue
if ($null -eq $dotnetCommand) { throw 'Can cai .NET 10 SDK hoac ASP.NET Core Runtime 10 de chay ung dung.' }
try {
    $ready = Invoke-RestMethod -Uri "$url/health" -TimeoutSec 2
    if ($ready.app -eq 'KinhMat.Web' -and $ready.status -eq 'ready') {
        Write-Host "Ung dung dang chay tai $url"
        if (-not $NoBrowser) { Start-Process $url }
        return
    }
} catch { }

$config = Get-Content -LiteralPath (Join-Path $projectRoot 'appsettings.json') -Raw | ConvertFrom-Json
$connectionString = $config.ConnectionStrings.Store
$localPath = Join-Path $projectRoot 'appsettings.Local.json'
if (Test-Path -LiteralPath $localPath) {
    $localConfig = Get-Content -LiteralPath $localPath -Raw | ConvertFrom-Json
    if ($localConfig.ConnectionStrings.Store) { $connectionString = $localConfig.ConnectionStrings.Store }
}
Add-Type -AssemblyName System.Data
$sqlBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $connectionString
if ($sqlBuilder['Initial Catalog'] -ne 'QuanLyKinhMatWeb') { throw 'Chi duoc su dung database QuanLyKinhMatWeb.' }
$server = $sqlBuilder['Data Source']
$sqlBuilder['Initial Catalog'] = 'master'
$connection = New-Object System.Data.SqlClient.SqlConnection($sqlBuilder.ConnectionString)
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT DB_ID(N'QuanLyKinhMatWeb');"
    $databaseId = $command.ExecuteScalar()
    $command.Dispose()
} finally { $connection.Dispose() }
if ($databaseId -eq [DBNull]::Value -or $null -eq $databaseId) {
    & (Join-Path $PSScriptRoot 'Initialize-Database.ps1') -Server $server
}

$dll = Join-Path $projectRoot 'runtime\KinhMat.Web.dll'
if (-not (Test-Path -LiteralPath $dll)) {
    Push-Location $projectRoot
    try {
        & $dotnetCommand.Source build WebQuanLyKinhMat.csproj -c Release -p:UseSharedCompilation=false -nr:false
        if ($LASTEXITCODE -ne 0) { throw 'Bien dich that bai. Kiem tra .NET SDK va ket noi NuGet.' }
    } finally { Pop-Location }
    $dll = Join-Path $projectRoot 'bin\Release\net10.0\KinhMat.Web.dll'
}
$dataDirectory = Join-Path $projectRoot 'App_Data'
[void](New-Item -ItemType Directory -Path $dataDirectory -Force)
$process = Start-Process -FilePath $dotnetCommand.Source -ArgumentList @(('"' + $dll + '"'), '--urls', $url, '--contentRoot', ('"' + $projectRoot + '"')) -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $dataDirectory 'server.log') -RedirectStandardError (Join-Path $dataDirectory 'server-error.log')
$process.Id | Set-Content -LiteralPath (Join-Path $dataDirectory 'server.pid')
$started = $false
for ($attempt = 0; $attempt -lt 40; $attempt++) {
    Start-Sleep -Milliseconds 500
    if ($process.HasExited) { break }
    try {
        $ready = Invoke-RestMethod -Uri "$url/health" -TimeoutSec 1
        if ($ready.app -eq 'KinhMat.Web' -and $ready.status -eq 'ready') { $started = $true; break }
    } catch { }
}
if (-not $started) { throw "Chua khoi dong duoc ung dung. Xem App_Data\server.log va server-error.log trong $projectRoot" }
Write-Host "Da khoi dong: $url"
Write-Host 'Dang nhap bang ma nhan vien va mat khau cu trong SQL (sau khi chuyen tai khoan). Xem README.md va CAI_DAT_VA_SU_DUNG.md o thu muc Git ngoai cung.'
if (-not $NoBrowser) { Start-Process $url }
