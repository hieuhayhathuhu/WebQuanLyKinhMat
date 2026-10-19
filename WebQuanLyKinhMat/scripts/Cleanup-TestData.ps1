#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ResultsFile, [string]$Server='HIEUCOI\SQLEXPRESS')
$ErrorActionPreference = 'Stop'
$result = Get-Content -LiteralPath $ResultsFile -Raw | ConvertFrom-Json
if ($result.tag -notmatch '^QA[0-9]+$') { throw 'Chi don du lieu do verify-app.cjs tao.' }
Add-Type -AssemblyName System.Data
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$builder['Data Source']=$Server; $builder['Initial Catalog']='QuanLyKinhMatWeb'
$builder['Integrated Security']=$true; $builder['TrustServerCertificate']=$true
$connection = New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
$connection.Open()
$transaction=$connection.BeginTransaction([System.Data.IsolationLevel]::Serializable)
function Run-Checked([string]$Sql,[hashtable]$Values) {
    $command=$connection.CreateCommand(); $command.Transaction=$transaction
    $command.CommandText="IF DB_NAME()<>N'QuanLyKinhMatWeb' THROW 51000,'Wrong database.',1; " + $Sql
    foreach($entry in $Values.GetEnumerator()) { [void]$command.Parameters.AddWithValue($entry.Key,$entry.Value) }
    try { [void]$command.ExecuteNonQuery() } finally { $command.Dispose() }
}
try {
    foreach($kind in @('sales','purchases')) {
        $header=if($kind -eq 'sales'){'HoaDonBan'}else{'PhieuNhap'}
        $detail=if($kind -eq 'sales'){'ChiTietHoaDonBan'}else{'ChiTietPhieuNhap'}
        $key=if($kind -eq 'sales'){'MaHoaDon'}else{'MaPhieuNhap'}
        foreach($invoice in $result.fixtures.$kind) {
            $id=[int]$invoice.id; $token=[Guid]$invoice.token
            Run-Checked "IF EXISTS(SELECT 1 FROM dbo.$header WHERE $key=@id AND TokenLuu=@token AND DaHuy=0) THROW 51001,'Cancel test invoice before cleanup.',1; DELETE d FROM dbo.$detail d JOIN dbo.$header h ON h.$key=d.$key WHERE h.$key=@id AND h.TokenLuu=@token AND h.DaHuy=1; DELETE dbo.$header WHERE $key=@id AND TokenLuu=@token AND DaHuy=1;" @{'@id'=$id;'@token'=$token}
        }
    }
    foreach($row in $result.fixtures.products) { Run-Checked 'DELETE dbo.SanPham WHERE MaSanPham=@id AND TenSanPham LIKE @prefix;' @{'@id'=[int]$row.id;'@prefix'=($result.tag+'%')} }
    foreach($row in $result.fixtures.customers) { Run-Checked 'DELETE dbo.KhachHang WHERE MaKhachHang=@id AND HoTen LIKE @prefix;' @{'@id'=[int]$row.id;'@prefix'=($result.tag+'%')} }
    foreach($row in $result.fixtures.suppliers) { Run-Checked 'DELETE dbo.NhaCungCap WHERE MaNhaCungCap=@id AND TenNhaCungCap LIKE @prefix;' @{'@id'=[int]$row.id;'@prefix'=($result.tag+'%')} }
    $catalogs=@{categories=@('LoaiSanPham','MaLoai','TenLoai');brands=@('ThuongHieu','MaThuongHieu','TenThuongHieu');materials=@('ChatLieu','MaChatLieu','TenChatLieu');colors=@('MauSac','MaMauSac','TenMauSac');shapes=@('HinhDang','MaHinhDang','TenHinhDang')}
    foreach($row in $result.fixtures.catalogs) {
        if (-not $catalogs.ContainsKey($row.type)) { throw 'Invalid test catalog.' }
        $definition=$catalogs[$row.type]
        Run-Checked "DELETE dbo.$($definition[0]) WHERE $($definition[1])=@id AND $($definition[2]) LIKE @prefix;" @{'@id'=[int]$row.id;'@prefix'=($result.tag+'%')}
    }
    foreach($row in $result.fixtures.users) {
        Run-Checked 'DELETE dbo.WebUsers WHERE Id=@id AND EmployeeId=@employee AND UserName=@username; DELETE dbo.NhanVien WHERE MaNhanVien=@employee AND HoTen LIKE @prefix AND NOT EXISTS(SELECT 1 FROM dbo.WebUsers WHERE EmployeeId=@employee);' @{'@id'=[int]$row.id;'@employee'=[int]$row.employeeId;'@username'=$result.tag.ToLowerInvariant();'@prefix'=($result.tag+'%')}
    }
    $transaction.Commit()
    Write-Host "Da don du lieu kiem thu $($result.tag) trong QuanLyKinhMatWeb."
} catch { $transaction.Rollback(); throw }
finally { $transaction.Dispose(); $connection.Dispose() }
