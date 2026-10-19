#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Data
$projectRoot = Split-Path -Parent $PSScriptRoot
$settings = Get-Content -LiteralPath (Join-Path $projectRoot 'appsettings.json') -Raw | ConvertFrom-Json
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $settings.ConnectionStrings.Store
if ($builder['Initial Catalog'] -ne 'QuanLyKinhMatWeb') { throw 'Wrong database.' }
$connection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
$rows = New-Object 'System.Collections.Generic.List[object]'
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = 'SELECT EmployeeId,UserName,PasswordHash,DisplayName,Role,IsActive FROM dbo.WebUsers ORDER BY EmployeeId;'
    $reader = $command.ExecuteReader()
    try {
        while ($reader.Read()) {
            $rows.Add([PSCustomObject]@{ EmployeeId=$reader.GetInt32(0); UserName=$reader.GetString(1); PasswordHash=$reader.GetString(2); DisplayName=$reader.GetString(3); Role=$reader.GetString(4); IsActive=$reader.GetBoolean(5) })
        }
    } finally { $reader.Dispose(); $command.Dispose() }
} finally { $connection.Dispose() }
if ($rows.Count -ne 3) { throw 'Chi dong goi 3 tai khoan ma nhan vien da xac nhan.' }
function Sql-Text([string]$Value) {
    return "N'" + $Value.Replace("'", "''").Replace("`r", "'+NCHAR(13)+N'").Replace("`n", "'+NCHAR(10)+N'") + "'"
}
$seed = New-Object System.Text.StringBuilder
[void]$seed.AppendLine('-- BEGIN WEB EMPLOYEE ACCOUNT SEED')
[void]$seed.AppendLine(@'
IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
IF EXISTS(SELECT 1 FROM dbo.WebUsers) THROW 51003, 'WebUsers must be empty for initial account seed.', 1;
'@)
for ($index=0; $index -lt 3; $index++) {
    $row=$rows[$index]
    if ($row.EmployeeId -ne $index+1 -or $row.UserName -ne [string]$row.EmployeeId -or $row.PasswordHash.Length -lt 30) { throw 'Tai khoan khong khop ma nhan vien.' }
    $active=if($row.IsActive){1}else{0}
    [void]$seed.AppendLine("INSERT dbo.WebUsers(EmployeeId,UserName,PasswordHash,DisplayName,Role,IsActive) VALUES($($row.EmployeeId),$(Sql-Text $row.UserName),$(Sql-Text $row.PasswordHash),$(Sql-Text $row.DisplayName),$(Sql-Text $row.Role),$active);")
}
[void]$seed.AppendLine('GO')
[void]$seed.AppendLine('-- END WEB EMPLOYEE ACCOUNT SEED')
$file=Join-Path (Split-Path -Parent $projectRoot) 'QuanLyKinhMat.sql'
$sql=[System.IO.File]::ReadAllText($file,[System.Text.Encoding]::UTF8)
$sql=[regex]::Replace($sql,'(?s)\r?\n?-- BEGIN WEB EMPLOYEE ACCOUNT SEED.*?-- END WEB EMPLOYEE ACCOUNT SEED\s*','')
$sql=$sql.TrimEnd()+"`r`n`r`n"+$seed.ToString()
[System.IO.File]::WriteAllText($file,$sql,(New-Object System.Text.UTF8Encoding($false)))
Write-Host 'Da dong goi 3 tai khoan ma nhan vien duoi dang PasswordHash vao SQL khoi tao. Khong xuat mat khau van ban.'
