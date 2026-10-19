#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter()][ValidateNotNullOrEmpty()][string]$Server = 'HIEUCOI\SQLEXPRESS'
)

$ErrorActionPreference = 'Stop'
$databaseName = 'QuanLyKinhMatWeb'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sqlPath = Join-Path (Split-Path -Parent $projectRoot) 'QuanLyKinhMat.sql'
if (-not (Test-Path -LiteralPath $sqlPath -PathType Leaf)) {
    throw "Khong tim thay script: $sqlPath"
}

# System.Data.SqlClient is available in Windows PowerShell 5.1; no SQL login or password needed.
Add-Type -AssemblyName System.Data
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source'] = $Server
$builder['Initial Catalog'] = 'master'
$builder['Integrated Security'] = $true
$builder['Encrypt'] = $true
$builder['TrustServerCertificate'] = $true
$builder['Connect Timeout'] = 10
$masterConnection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
$storeConnection = $null
$transaction = $null
$databaseCreated = $false
try {
    $masterConnection.Open()
    $check = $masterConnection.CreateCommand()
    $check.CommandText = 'SELECT DB_ID(@name);'
    [void]$check.Parameters.Add('@name', [System.Data.SqlDbType]::NVarChar, 128)
    $check.Parameters['@name'].Value = $databaseName
    $existing = $check.ExecuteScalar()
    $check.Dispose()
    if ($existing -ne [DBNull]::Value -and $null -ne $existing) {
        throw "Database $databaseName da ton tai tren $Server. Dung lai; khong ghi de hay thay doi database."
    }

    # A concurrent initializer fails CREATE DATABASE and stops before touching its contents.
    $create = $masterConnection.CreateCommand()
    $create.CommandTimeout = 120
    $create.CommandText = 'CREATE DATABASE [QuanLyKinhMatWeb];'
    [void]$create.ExecuteNonQuery()
    $create.Dispose()
    $databaseCreated = $true

    $builder['Initial Catalog'] = $databaseName
    $storeConnection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
    $storeConnection.Open()
    $mark = $storeConnection.CreateCommand()
    $mark.CommandText = "IF DB_NAME() <> N'QuanLyKinhMatWeb' THROW 51001, 'Wrong target database.', 1; IF EXISTS(SELECT 1 FROM sys.tables WHERE is_ms_shipped=0) THROW 51003, 'Target is not empty.', 1; EXEC sys.sp_set_session_context @key=N'KinhMat.Provisioning', @value=N'NewDatabaseOnly';"
    [void]$mark.ExecuteNonQuery()
    $mark.Dispose()

    $sqlText = [System.IO.File]::ReadAllText($sqlPath, [System.Text.Encoding]::UTF8)
    $batches = [regex]::Split($sqlText, '(?im)^\s*GO\s*(?:--[^\r\n]*)?$')
    $transaction = $storeConnection.BeginTransaction()
    $batchNumber = 0
    foreach ($batch in $batches) {
        if ([string]::IsNullOrWhiteSpace($batch)) { continue }
        $batchNumber++
        $command = $storeConnection.CreateCommand()
        try {
            $command.Transaction = $transaction
            $command.CommandTimeout = 120
            $command.CommandText = $batch
            [void]$command.ExecuteNonQuery()
        }
        catch {
            # Do not echo a batch: seed rows can contain personal data.
            throw "Khoi tao that bai o batch $batchNumber. $($_.Exception.Message)"
        }
        finally { $command.Dispose() }
    }
    $transaction.Commit()
    $transaction.Dispose()
    $transaction = $null
    Write-Host "Da tao $databaseName tren ${Server}: 21 bang goc + WebUsers; du lieu nghiep vu duoc giu, mat khau cu da loai bo."
    Write-Host 'SQL da co 3 tai khoan ma nhan vien 1, 2, 3 bang PasswordHash; khong tao tai khoan demo.'
}
catch {
    if ($null -ne $transaction) {
        try { $transaction.Rollback() } catch { Write-Warning 'Khong the rollback giao dich khoi tao.' }
    }
    if ($databaseCreated) {
        Write-Warning "$databaseName da duoc tao nhung khoi tao schema/seed chua hoan tat. Script khong tu xoa database. Giu lai de kiem tra; lan chay tiep theo se dung vi database da ton tai."
    }
    throw
}
finally {
    if ($null -ne $transaction) { $transaction.Dispose() }
    if ($null -ne $storeConnection) { $storeConnection.Dispose() }
    $masterConnection.Dispose()
}
