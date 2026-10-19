#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Data
$projectRoot = Split-Path -Parent $PSScriptRoot
$settings = Get-Content -LiteralPath (Join-Path $projectRoot 'appsettings.json') -Raw | ConvertFrom-Json
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $settings.ConnectionStrings.Store
if ($builder['Initial Catalog'] -ne 'QuanLyKinhMatWeb') { throw 'Wrong target database.' }
$connection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
try {
    $connection.Open()
    $command = $connection.CreateCommand()
    $command.CommandText = @'
SET XACT_ABORT ON;
IF DB_NAME()<>N'QuanLyKinhMatWeb' THROW 51000,N'Wrong database.',1;
BEGIN TRANSACTION;
IF NOT EXISTS(SELECT 1 FROM dbo.WebUsers u WITH(UPDLOCK,HOLDLOCK)
 JOIN dbo.NhanVien n ON n.MaNhanVien=u.EmployeeId
 WHERE u.UserName=N'1' AND u.EmployeeId=1 AND u.Role=N'Admin' AND u.IsActive=1 AND n.TrangThai=1)
 THROW 51001,N'Keep the active employee 1 administrator before removing demo accounts.',1;
DELETE dbo.WebUsers WHERE (UserName=N'admin' AND EmployeeId=4)
 OR (UserName=N'nhanvien' AND EmployeeId=5);
DECLARE @accounts int=@@ROWCOUNT;
DELETE n FROM dbo.NhanVien n
WHERE ((n.MaNhanVien=4 AND n.HoTen=N'Quản lý cửa hàng') OR (n.MaNhanVien=5 AND n.HoTen=N'Nhân viên bán hàng'))
 AND NOT EXISTS(SELECT 1 FROM dbo.WebUsers u WHERE u.EmployeeId=n.MaNhanVien)
 AND NOT EXISTS(SELECT 1 FROM dbo.TaiKhoan t WHERE t.MaNhanVien=n.MaNhanVien)
 AND NOT EXISTS(SELECT 1 FROM dbo.HoaDonBan h WHERE h.MaNhanVien=n.MaNhanVien)
 AND NOT EXISTS(SELECT 1 FROM dbo.PhieuNhap p WHERE p.MaNhanVien=n.MaNhanVien);
DECLARE @employees int=@@ROWCOUNT;
COMMIT;
SELECT @accounts AS AccountsRemoved,@employees AS UnreferencedDemoEmployeesRemoved;
'@
    $reader = $command.ExecuteReader()
    try { if ($reader.Read()) { Write-Host "Da xoa $($reader.GetInt32(0)) tai khoan demo va $($reader.GetInt32(1)) nhan vien demo khong co chung tu." } }
    finally { $reader.Dispose(); $command.Dispose() }
} finally { $connection.Dispose() }
