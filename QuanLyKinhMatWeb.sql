-- Sanitized clone of the supplied QLKM.sql; UTF-8 without BOM.
-- Run through scripts/Initialize-Database.ps1. Every batch rejects another database
-- or a connection that was not marked by the guarded provisioning script.
-- Preserves 21 original tables, views, keys, constraints, data and filtered token indexes.
-- Removes server logins/users, physical file paths and server-specific database options.
-- NhanVien.Passw is NULL; legacy TaiKhoan rows are disabled with empty passwords.
-- Application login uses WebUsers with PasswordHasher; no web password is seeded here.

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[SanPham]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[SanPham](
	[MaSanPham] [int] IDENTITY(1,1) NOT NULL,
	[TenSanPham] [nvarchar](150) NOT NULL,
	[MaLoai] [int] NOT NULL,
	[MaThuongHieu] [int] NULL,
	[MauSac] [nvarchar](50) NULL,
	[ChatLieu] [nvarchar](100) NULL,
	[GiaNhap] [decimal](18, 2) NOT NULL,
	[GiaBan] [decimal](18, 2) NOT NULL,
	[SoLuongTon] [int] NOT NULL,
	[MoTa] [nvarchar](500) NULL,
	[TrangThai] [bit] NOT NULL,
	[HinhAnh] [nvarchar](260) NULL,
	[LoaiGong] [nvarchar](100) NULL,
	[HinhDang] [nvarchar](100) NULL,
	[Diop] [nvarchar](100) NULL,
	[CongDung] [nvarchar](500) NULL,
	[DacDiem] [nvarchar](500) NULL,
	[NuocSanXuat] [nvarchar](100) NULL,
	[BaoHanh] [nvarchar](100) NULL,
	[GhiChu] [nvarchar](500) NULL,
	[MaChatLieu] [int] NULL,
	[MaMauSac] [int] NULL,
	[MaLoaiGong] [int] NULL,
	[MaHinhDang] [int] NULL,
	[MaDiop] [int] NULL,
	[MaCongDung] [int] NULL,
	[MaDacDiem] [int] NULL,
	[MaNuocSanXuat] [int] NULL,
	[MaBaoHanh] [int] NULL,
	[GiaNhapGoc] [decimal](18, 2) NULL,
	[GiaBanGoc] [decimal](18, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[MaSanPham] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  View [dbo].[v_SanPhamDen]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
EXEC(N'CREATE VIEW [dbo].[v_SanPhamDen]
AS
SELECT MaSanPham, TenSanPham, GiaBan
FROM dbo.SanPham
WHERE MauSac = N''Đen'';');
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[KhachHang]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[KhachHang](
	[MaKhachHang] [int] IDENTITY(1,1) NOT NULL,
	[HoTen] [nvarchar](100) NOT NULL,
	[SoDienThoai] [varchar](15) NULL,
	[DiaChi] [nvarchar](255) NULL,
	[Email] [varchar](100) NULL,
	[NgaySinh] [date] NULL,
	[GioiTinh] [nvarchar](10) NULL,
PRIMARY KEY CLUSTERED 
(
	[MaKhachHang] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  View [dbo].[v_KhachNu]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
EXEC(N'create view [dbo].[v_KhachNu]
as 
select MaKhachHang, HoTen, SoDienThoai
from dbo.KhachHang
where GioiTinh = N''Nữ'';');
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  View [dbo].[v_loinhuan]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
EXEC(N'create view [dbo].[v_loinhuan]
as
select MaSanPham, TenSanPham, (GiaBan - GiaNhap) as LoiNhuan
from dbo.SanPham');
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  View [dbo].[v_TuoiKhach]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
EXEC(N'create view [dbo].[v_TuoiKhach]
as
select MaKhachHang, HoTen, DATEDIFF(year,NgaySinh,GETDATE()) as Tuoi
from dbo.KhachHang');
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[BaoHanh]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[BaoHanh](
	[MaBaoHanh] [int] IDENTITY(1,1) NOT NULL,
	[TenBaoHanh] [nvarchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaBaoHanh] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[ChatLieu]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[ChatLieu](
	[MaChatLieu] [int] IDENTITY(1,1) NOT NULL,
	[TenChatLieu] [nvarchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaChatLieu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[ChiTietHoaDonBan]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[ChiTietHoaDonBan](
	[MaHoaDon] [int] NOT NULL,
	[MaSanPham] [int] NOT NULL,
	[SoLuong] [int] NOT NULL,
	[DonGiaBan] [decimal](18, 2) NOT NULL,
	[ThanhTien]  AS ([SoLuong]*[DonGiaBan]),
	[GiamGia] [decimal](5, 2) NOT NULL,
	[ThanhTienChot] [decimal](18, 2) NULL,
 CONSTRAINT [PK_ChiTietHoaDonBan] PRIMARY KEY CLUSTERED 
(
	[MaHoaDon] ASC,
	[MaSanPham] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[ChiTietPhieuNhap]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[ChiTietPhieuNhap](
	[MaPhieuNhap] [int] NOT NULL,
	[MaSanPham] [int] NOT NULL,
	[SoLuong] [int] NOT NULL,
	[DonGiaNhap] [decimal](18, 2) NOT NULL,
	[ThanhTien]  AS ([SoLuong]*[DonGiaNhap]),
	[GiamGia] [decimal](5, 2) NOT NULL,
	[ThanhTienChot] [decimal](18, 2) NULL,
	[GiaNhapTruoc] [decimal](18, 2) NULL,
	[GiaBanTruoc] [decimal](18, 2) NULL,
 CONSTRAINT [PK_ChiTietPhieuNhap] PRIMARY KEY CLUSTERED 
(
	[MaPhieuNhap] ASC,
	[MaSanPham] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[ChucVu]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[ChucVu](
	[MaChucVu] [int] IDENTITY(1,1) NOT NULL,
	[TenChucVu] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaChucVu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[CongDung]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[CongDung](
	[MaCongDung] [int] IDENTITY(1,1) NOT NULL,
	[TenCongDung] [nvarchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaCongDung] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[DacDiem]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[DacDiem](
	[MaDacDiem] [int] IDENTITY(1,1) NOT NULL,
	[TenDacDiem] [nvarchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaDacDiem] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[Diop]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[Diop](
	[MaDiop] [int] IDENTITY(1,1) NOT NULL,
	[TenDiop] [nvarchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaDiop] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[HinhDang]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[HinhDang](
	[MaHinhDang] [int] IDENTITY(1,1) NOT NULL,
	[TenHinhDang] [nvarchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaHinhDang] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[HoaDonBan]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[HoaDonBan](
	[MaHoaDon] [int] IDENTITY(1,1) NOT NULL,
	[MaKhachHang] [int] NULL,
	[MaNhanVien] [int] NOT NULL,
	[NgayBan] [datetime] NOT NULL,
	[TongTien] [decimal](18, 2) NOT NULL,
	[GhiChu] [nvarchar](255) NULL,
	[SoHoaDon] [nvarchar](40) NULL,
	[TokenLuu] [uniqueidentifier] NULL,
	[DaHuy] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaHoaDon] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[LoaiGong]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[LoaiGong](
	[MaLoaiGong] [int] IDENTITY(1,1) NOT NULL,
	[TenLoaiGong] [nvarchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaLoaiGong] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[LoaiSanPham]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[LoaiSanPham](
	[MaLoai] [int] IDENTITY(1,1) NOT NULL,
	[TenLoai] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaLoai] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[MauSac]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[MauSac](
	[MaMauSac] [int] IDENTITY(1,1) NOT NULL,
	[TenMauSac] [nvarchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaMauSac] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[NhaCungCap]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[NhaCungCap](
	[MaNhaCungCap] [int] IDENTITY(1,1) NOT NULL,
	[TenNhaCungCap] [nvarchar](150) NOT NULL,
	[SoDienThoai] [varchar](15) NULL,
	[DiaChi] [nvarchar](255) NULL,
	[Email] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[MaNhaCungCap] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[NhanVien]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[NhanVien](
	[MaNhanVien] [int] IDENTITY(1,1) NOT NULL,
	[HoTen] [nvarchar](100) NOT NULL,
	[NgaySinh] [date] NULL,
	[GioiTinh] [nvarchar](10) NULL,
	[SoDienThoai] [varchar](15) NULL,
	[DiaChi] [nvarchar](255) NULL,
	[ChucVu] [nvarchar](50) NULL,
	[TrangThai] [bit] NOT NULL,
	[Passw] [nvarchar](255) NULL,
	[MaChucVu] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[MaNhanVien] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[NuocSanXuat]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[NuocSanXuat](
	[MaNuocSanXuat] [int] IDENTITY(1,1) NOT NULL,
	[TenNuocSanXuat] [nvarchar](500) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaNuocSanXuat] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[PhieuNhap]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[PhieuNhap](
	[MaPhieuNhap] [int] IDENTITY(1,1) NOT NULL,
	[MaNhaCungCap] [int] NOT NULL,
	[MaNhanVien] [int] NOT NULL,
	[NgayNhap] [datetime] NOT NULL,
	[TongTien] [decimal](18, 2) NOT NULL,
	[GhiChu] [nvarchar](255) NULL,
	[SoHoaDon] [nvarchar](40) NULL,
	[TokenLuu] [uniqueidentifier] NULL,
	[DaHuy] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaPhieuNhap] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[TaiKhoan]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[TaiKhoan](
	[MaTaiKhoan] [int] IDENTITY(1,1) NOT NULL,
	[TenDangNhap] [varchar](50) NOT NULL,
	[MatKhau] [varchar](255) NOT NULL,
	[MaNhanVien] [int] NOT NULL,
	[Quyen] [nvarchar](30) NOT NULL,
	[TrangThai] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaTaiKhoan] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Table [dbo].[ThuongHieu]    Script Date: 16/10/2026 23:27:14 ******/
SET ANSI_NULLS ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET QUOTED_IDENTIFIER ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[ThuongHieu](
	[MaThuongHieu] [int] IDENTITY(1,1) NOT NULL,
	[TenThuongHieu] [nvarchar](100) NOT NULL,
	[QuocGia] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[MaThuongHieu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[ChatLieu] ON 

INSERT [dbo].[ChatLieu] ([MaChatLieu], [TenChatLieu]) VALUES (1, N'Kim loại')
INSERT [dbo].[ChatLieu] ([MaChatLieu], [TenChatLieu]) VALUES (2, N'Nhựa')
INSERT [dbo].[ChatLieu] ([MaChatLieu], [TenChatLieu]) VALUES (3, N'Polycarbonate')
SET IDENTITY_INSERT [dbo].[ChatLieu] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
INSERT [dbo].[ChiTietHoaDonBan] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGiaBan], [GiamGia], [ThanhTienChot]) VALUES (1, 1, 2, CAST(550000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL)
INSERT [dbo].[ChiTietHoaDonBan] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGiaBan], [GiamGia], [ThanhTienChot]) VALUES (1, 6, 2, CAST(440000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL)
INSERT [dbo].[ChiTietHoaDonBan] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGiaBan], [GiamGia], [ThanhTienChot]) VALUES (2, 2, 1, CAST(1650000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL)
INSERT [dbo].[ChiTietHoaDonBan] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGiaBan], [GiamGia], [ThanhTienChot]) VALUES (3, 1, 1, CAST(550000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL)
INSERT [dbo].[ChiTietHoaDonBan] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGiaBan], [GiamGia], [ThanhTienChot]) VALUES (3, 3, 1, CAST(2200000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL)
INSERT [dbo].[ChiTietHoaDonBan] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGiaBan], [GiamGia], [ThanhTienChot]) VALUES (4, 5, 1, CAST(1980000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL)
INSERT [dbo].[ChiTietHoaDonBan] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGiaBan], [GiamGia], [ThanhTienChot]) VALUES (4, 6, 1, CAST(440000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL)
INSERT [dbo].[ChiTietHoaDonBan] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGiaBan], [GiamGia], [ThanhTienChot]) VALUES (5, 1, 1, CAST(550000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL)
INSERT [dbo].[ChiTietHoaDonBan] ([MaHoaDon], [MaSanPham], [SoLuong], [DonGiaBan], [GiamGia], [ThanhTienChot]) VALUES (5, 8, 2, CAST(770000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL)
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
INSERT [dbo].[ChiTietPhieuNhap] ([MaPhieuNhap], [MaSanPham], [SoLuong], [DonGiaNhap], [GiamGia], [ThanhTienChot], [GiaNhapTruoc], [GiaBanTruoc]) VALUES (1, 1, 10, CAST(500000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL, NULL, NULL)
INSERT [dbo].[ChiTietPhieuNhap] ([MaPhieuNhap], [MaSanPham], [SoLuong], [DonGiaNhap], [GiamGia], [ThanhTienChot], [GiaNhapTruoc], [GiaBanTruoc]) VALUES (1, 2, 3, CAST(1500000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL, NULL, NULL)
INSERT [dbo].[ChiTietPhieuNhap] ([MaPhieuNhap], [MaSanPham], [SoLuong], [DonGiaNhap], [GiamGia], [ThanhTienChot], [GiaNhapTruoc], [GiaBanTruoc]) VALUES (2, 3, 3, CAST(2000000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL, NULL, NULL)
INSERT [dbo].[ChiTietPhieuNhap] ([MaPhieuNhap], [MaSanPham], [SoLuong], [DonGiaNhap], [GiamGia], [ThanhTienChot], [GiaNhapTruoc], [GiaBanTruoc]) VALUES (2, 5, 2, CAST(1800000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL, NULL, NULL)
INSERT [dbo].[ChiTietPhieuNhap] ([MaPhieuNhap], [MaSanPham], [SoLuong], [DonGiaNhap], [GiamGia], [ThanhTienChot], [GiaNhapTruoc], [GiaBanTruoc]) VALUES (3, 4, 5, CAST(1200000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL, NULL, NULL)
INSERT [dbo].[ChiTietPhieuNhap] ([MaPhieuNhap], [MaSanPham], [SoLuong], [DonGiaNhap], [GiamGia], [ThanhTienChot], [GiaNhapTruoc], [GiaBanTruoc]) VALUES (3, 6, 10, CAST(400000.00 AS Decimal(18, 2)), CAST(0.00 AS Decimal(5, 2)), NULL, NULL, NULL)
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[ChucVu] ON 

INSERT [dbo].[ChucVu] ([MaChucVu], [TenChucVu]) VALUES (1, N'Nhân viên bán hàng')
INSERT [dbo].[ChucVu] ([MaChucVu], [TenChucVu]) VALUES (2, N'Nhân viên kho')
INSERT [dbo].[ChucVu] ([MaChucVu], [TenChucVu]) VALUES (3, N'Quản lý')
SET IDENTITY_INSERT [dbo].[ChucVu] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[HoaDonBan] ON 

INSERT [dbo].[HoaDonBan] ([MaHoaDon], [MaKhachHang], [MaNhanVien], [NgayBan], [TongTien], [GhiChu], [SoHoaDon], [TokenLuu], [DaHuy]) VALUES (1, 1, 2, CAST(N'2026-04-01T00:00:00.000' AS DateTime), CAST(1980000.00 AS Decimal(18, 2)), NULL, NULL, NULL, 0)
INSERT [dbo].[HoaDonBan] ([MaHoaDon], [MaKhachHang], [MaNhanVien], [NgayBan], [TongTien], [GhiChu], [SoHoaDon], [TokenLuu], [DaHuy]) VALUES (2, 2, 2, CAST(N'2026-04-05T00:00:00.000' AS DateTime), CAST(1650000.00 AS Decimal(18, 2)), NULL, NULL, NULL, 0)
INSERT [dbo].[HoaDonBan] ([MaHoaDon], [MaKhachHang], [MaNhanVien], [NgayBan], [TongTien], [GhiChu], [SoHoaDon], [TokenLuu], [DaHuy]) VALUES (3, 3, 1, CAST(N'2026-05-10T00:00:00.000' AS DateTime), CAST(2750000.00 AS Decimal(18, 2)), NULL, NULL, NULL, 0)
INSERT [dbo].[HoaDonBan] ([MaHoaDon], [MaKhachHang], [MaNhanVien], [NgayBan], [TongTien], [GhiChu], [SoHoaDon], [TokenLuu], [DaHuy]) VALUES (4, 4, 2, CAST(N'2026-05-15T00:00:00.000' AS DateTime), CAST(2420000.00 AS Decimal(18, 2)), NULL, NULL, NULL, 0)
INSERT [dbo].[HoaDonBan] ([MaHoaDon], [MaKhachHang], [MaNhanVien], [NgayBan], [TongTien], [GhiChu], [SoHoaDon], [TokenLuu], [DaHuy]) VALUES (5, 5, 1, CAST(N'2026-06-01T00:00:00.000' AS DateTime), CAST(2090000.00 AS Decimal(18, 2)), NULL, NULL, NULL, 0)
SET IDENTITY_INSERT [dbo].[HoaDonBan] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[KhachHang] ON 

INSERT [dbo].[KhachHang] ([MaKhachHang], [HoTen], [SoDienThoai], [DiaChi], [Email], [NgaySinh], [GioiTinh]) VALUES (1, N'Phạm Minh Đức', N'0971111111', N'Hà Nội', N'duc@gmail.com', CAST(N'2002-06-10' AS Date), N'Nam')
INSERT [dbo].[KhachHang] ([MaKhachHang], [HoTen], [SoDienThoai], [DiaChi], [Email], [NgaySinh], [GioiTinh]) VALUES (2, N'Nguyễn Thu Hà', N'0972222222', N'Bắc Ninh', N'ha@gmail.com', CAST(N'2001-11-25' AS Date), N'Nữ')
INSERT [dbo].[KhachHang] ([MaKhachHang], [HoTen], [SoDienThoai], [DiaChi], [Email], [NgaySinh], [GioiTinh]) VALUES (3, N'Đỗ Văn Nam', N'0973333333', N'Hải Dương', N'nam@gmail.com', CAST(N'1999-07-18' AS Date), N'Nam')
INSERT [dbo].[KhachHang] ([MaKhachHang], [HoTen], [SoDienThoai], [DiaChi], [Email], [NgaySinh], [GioiTinh]) VALUES (4, N'Hoàng Ngọc Mai', N'0974444444', N'Hà Nội', N'mai@gmail.com', CAST(N'2003-02-12' AS Date), N'Nữ')
INSERT [dbo].[KhachHang] ([MaKhachHang], [HoTen], [SoDienThoai], [DiaChi], [Email], [NgaySinh], [GioiTinh]) VALUES (5, N'Vũ Anh Tuấn', N'0975555555', N'Bắc Giang', N'atuan@gmail.com', CAST(N'2000-10-30' AS Date), N'Nam')
SET IDENTITY_INSERT [dbo].[KhachHang] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[LoaiSanPham] ON 

INSERT [dbo].[LoaiSanPham] ([MaLoai], [TenLoai]) VALUES (1, N'Gọng kính')
INSERT [dbo].[LoaiSanPham] ([MaLoai], [TenLoai]) VALUES (2, N'Kính râm')
INSERT [dbo].[LoaiSanPham] ([MaLoai], [TenLoai]) VALUES (3, N'Kính cận')
INSERT [dbo].[LoaiSanPham] ([MaLoai], [TenLoai]) VALUES (4, N'Kính thời trang')
INSERT [dbo].[LoaiSanPham] ([MaLoai], [TenLoai]) VALUES (5, N'Tròng kính')
SET IDENTITY_INSERT [dbo].[LoaiSanPham] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[MauSac] ON 

INSERT [dbo].[MauSac] ([MaMauSac], [TenMauSac]) VALUES (1, N'Bạc')
INSERT [dbo].[MauSac] ([MaMauSac], [TenMauSac]) VALUES (2, N'Đen')
INSERT [dbo].[MauSac] ([MaMauSac], [TenMauSac]) VALUES (3, N'Nâu')
INSERT [dbo].[MauSac] ([MaMauSac], [TenMauSac]) VALUES (4, N'Trong suốt')
INSERT [dbo].[MauSac] ([MaMauSac], [TenMauSac]) VALUES (5, N'Vàng')
SET IDENTITY_INSERT [dbo].[MauSac] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[NhaCungCap] ON 

INSERT [dbo].[NhaCungCap] ([MaNhaCungCap], [TenNhaCungCap], [SoDienThoai], [DiaChi], [Email]) VALUES (1, N'Công ty Kính Việt', N'0241111111', N'Hà Nội', N'kinhviet@gmail.com')
INSERT [dbo].[NhaCungCap] ([MaNhaCungCap], [TenNhaCungCap], [SoDienThoai], [DiaChi], [Email]) VALUES (2, N'Optical Fashion', N'0242222222', N'Hồ Chí Minh', N'optical@gmail.com')
INSERT [dbo].[NhaCungCap] ([MaNhaCungCap], [TenNhaCungCap], [SoDienThoai], [DiaChi], [Email]) VALUES (3, N'EyeWear Việt Nam', N'0243333333', N'Đà Nẵng', N'eyewear@gmail.com')
SET IDENTITY_INSERT [dbo].[NhaCungCap] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[NhanVien] ON 

INSERT [dbo].[NhanVien] ([MaNhanVien], [HoTen], [NgaySinh], [GioiTinh], [SoDienThoai], [DiaChi], [ChucVu], [TrangThai], [Passw], [MaChucVu]) VALUES (1, N'Nguyễn Văn An', CAST(N'2000-05-12' AS Date), N'Nam', N'0912345678', N'Hà Nội', N'Quản lý', 1, NULL, 3)
INSERT [dbo].[NhanVien] ([MaNhanVien], [HoTen], [NgaySinh], [GioiTinh], [SoDienThoai], [DiaChi], [ChucVu], [TrangThai], [Passw], [MaChucVu]) VALUES (2, N'Trần Thị Lan', CAST(N'2002-08-20' AS Date), N'Nữ', N'0987654321', N'Bắc Ninh', N'Nhân viên bán hàng', 1, NULL, 1)
INSERT [dbo].[NhanVien] ([MaNhanVien], [HoTen], [NgaySinh], [GioiTinh], [SoDienThoai], [DiaChi], [ChucVu], [TrangThai], [Passw], [MaChucVu]) VALUES (3, N'Lê Minh Tuấn', CAST(N'2001-03-15' AS Date), N'Nam', N'0905123456', N'Hà Nội', N'Nhân viên kho', 1, NULL, 2)
SET IDENTITY_INSERT [dbo].[NhanVien] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[PhieuNhap] ON 

INSERT [dbo].[PhieuNhap] ([MaPhieuNhap], [MaNhaCungCap], [MaNhanVien], [NgayNhap], [TongTien], [GhiChu], [SoHoaDon], [TokenLuu], [DaHuy]) VALUES (1, 1, 3, CAST(N'2026-01-05T00:00:00.000' AS DateTime), CAST(9500000.00 AS Decimal(18, 2)), NULL, NULL, NULL, 0)
INSERT [dbo].[PhieuNhap] ([MaPhieuNhap], [MaNhaCungCap], [MaNhanVien], [NgayNhap], [TongTien], [GhiChu], [SoHoaDon], [TokenLuu], [DaHuy]) VALUES (2, 2, 3, CAST(N'2026-02-10T00:00:00.000' AS DateTime), CAST(9600000.00 AS Decimal(18, 2)), NULL, NULL, NULL, 0)
INSERT [dbo].[PhieuNhap] ([MaPhieuNhap], [MaNhaCungCap], [MaNhanVien], [NgayNhap], [TongTien], [GhiChu], [SoHoaDon], [TokenLuu], [DaHuy]) VALUES (3, 3, 3, CAST(N'2026-03-15T00:00:00.000' AS DateTime), CAST(10000000.00 AS Decimal(18, 2)), NULL, NULL, NULL, 0)
SET IDENTITY_INSERT [dbo].[PhieuNhap] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[SanPham] ON 

INSERT [dbo].[SanPham] ([MaSanPham], [TenSanPham], [MaLoai], [MaThuongHieu], [MauSac], [ChatLieu], [GiaNhap], [GiaBan], [SoLuongTon], [MoTa], [TrangThai], [HinhAnh], [LoaiGong], [HinhDang], [Diop], [CongDung], [DacDiem], [NuocSanXuat], [BaoHanh], [GhiChu], [MaChatLieu], [MaMauSac], [MaLoaiGong], [MaHinhDang], [MaDiop], [MaCongDung], [MaDacDiem], [MaNuocSanXuat], [MaBaoHanh], [GiaNhapGoc], [GiaBanGoc]) VALUES (1, N'Gọng kính RB Classic', 1, 1, N'Đen', N'Kim loại', CAST(500000.00 AS Decimal(18, 2)), CAST(550000.00 AS Decimal(18, 2)), 20, N'Gọng kính kiểu dáng cổ điển', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(500000.00 AS Decimal(18, 2)), CAST(550000.00 AS Decimal(18, 2)))
INSERT [dbo].[SanPham] ([MaSanPham], [TenSanPham], [MaLoai], [MaThuongHieu], [MauSac], [ChatLieu], [GiaNhap], [GiaBan], [SoLuongTon], [MoTa], [TrangThai], [HinhAnh], [LoaiGong], [HinhDang], [Diop], [CongDung], [DacDiem], [NuocSanXuat], [BaoHanh], [GhiChu], [MaChatLieu], [MaMauSac], [MaLoaiGong], [MaHinhDang], [MaDiop], [MaCongDung], [MaDacDiem], [MaNuocSanXuat], [MaBaoHanh], [GiaNhapGoc], [GiaBanGoc]) VALUES (2, N'Kính râm Ray-Ban Aviator', 2, 1, N'Đen', N'Kim loại', CAST(1500000.00 AS Decimal(18, 2)), CAST(1650000.00 AS Decimal(18, 2)), 15, N'Kính râm Aviator', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(1500000.00 AS Decimal(18, 2)), CAST(1650000.00 AS Decimal(18, 2)))
INSERT [dbo].[SanPham] ([MaSanPham], [TenSanPham], [MaLoai], [MaThuongHieu], [MauSac], [ChatLieu], [GiaNhap], [GiaBan], [SoLuongTon], [MoTa], [TrangThai], [HinhAnh], [LoaiGong], [HinhDang], [Diop], [CongDung], [DacDiem], [NuocSanXuat], [BaoHanh], [GhiChu], [MaChatLieu], [MaMauSac], [MaLoaiGong], [MaHinhDang], [MaDiop], [MaCongDung], [MaDacDiem], [MaNuocSanXuat], [MaBaoHanh], [GiaNhapGoc], [GiaBanGoc]) VALUES (3, N'Gọng Gucci GG01', 1, 2, N'Vàng', N'Kim loại', CAST(2000000.00 AS Decimal(18, 2)), CAST(2200000.00 AS Decimal(18, 2)), 10, N'Gọng kính thời trang Gucci', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(2000000.00 AS Decimal(18, 2)), CAST(2200000.00 AS Decimal(18, 2)))
INSERT [dbo].[SanPham] ([MaSanPham], [TenSanPham], [MaLoai], [MaThuongHieu], [MauSac], [ChatLieu], [GiaNhap], [GiaBan], [SoLuongTon], [MoTa], [TrangThai], [HinhAnh], [LoaiGong], [HinhDang], [Diop], [CongDung], [DacDiem], [NuocSanXuat], [BaoHanh], [GhiChu], [MaChatLieu], [MaMauSac], [MaLoaiGong], [MaHinhDang], [MaDiop], [MaCongDung], [MaDacDiem], [MaNuocSanXuat], [MaBaoHanh], [GiaNhapGoc], [GiaBanGoc]) VALUES (4, N'Oakley Sport', 2, 3, N'Đen', N'Nhựa', CAST(1200000.00 AS Decimal(18, 2)), CAST(1320000.00 AS Decimal(18, 2)), 18, N'Kính thể thao', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(1200000.00 AS Decimal(18, 2)), CAST(1320000.00 AS Decimal(18, 2)))
INSERT [dbo].[SanPham] ([MaSanPham], [TenSanPham], [MaLoai], [MaThuongHieu], [MauSac], [ChatLieu], [GiaNhap], [GiaBan], [SoLuongTon], [MoTa], [TrangThai], [HinhAnh], [LoaiGong], [HinhDang], [Diop], [CongDung], [DacDiem], [NuocSanXuat], [BaoHanh], [GhiChu], [MaChatLieu], [MaMauSac], [MaLoaiGong], [MaHinhDang], [MaDiop], [MaCongDung], [MaDacDiem], [MaNuocSanXuat], [MaBaoHanh], [GiaNhapGoc], [GiaBanGoc]) VALUES (5, N'Gentle Monster GM01', 4, 4, N'Nâu', N'Nhựa', CAST(1800000.00 AS Decimal(18, 2)), CAST(1980000.00 AS Decimal(18, 2)), 12, N'Kính thời trang', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(1800000.00 AS Decimal(18, 2)), CAST(1980000.00 AS Decimal(18, 2)))
INSERT [dbo].[SanPham] ([MaSanPham], [TenSanPham], [MaLoai], [MaThuongHieu], [MauSac], [ChatLieu], [GiaNhap], [GiaBan], [SoLuongTon], [MoTa], [TrangThai], [HinhAnh], [LoaiGong], [HinhDang], [Diop], [CongDung], [DacDiem], [NuocSanXuat], [BaoHanh], [GhiChu], [MaChatLieu], [MaMauSac], [MaLoaiGong], [MaHinhDang], [MaDiop], [MaCongDung], [MaDacDiem], [MaNuocSanXuat], [MaBaoHanh], [GiaNhapGoc], [GiaBanGoc]) VALUES (6, N'Tròng kính Essilor 1.56', 5, 5, N'Trong suốt', N'Polycarbonate', CAST(400000.00 AS Decimal(18, 2)), CAST(440000.00 AS Decimal(18, 2)), 30, N'Tròng kính chống UV', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(400000.00 AS Decimal(18, 2)), CAST(440000.00 AS Decimal(18, 2)))
INSERT [dbo].[SanPham] ([MaSanPham], [TenSanPham], [MaLoai], [MaThuongHieu], [MauSac], [ChatLieu], [GiaNhap], [GiaBan], [SoLuongTon], [MoTa], [TrangThai], [HinhAnh], [LoaiGong], [HinhDang], [Diop], [CongDung], [DacDiem], [NuocSanXuat], [BaoHanh], [GhiChu], [MaChatLieu], [MaMauSac], [MaLoaiGong], [MaHinhDang], [MaDiop], [MaCongDung], [MaDacDiem], [MaNuocSanXuat], [MaBaoHanh], [GiaNhapGoc], [GiaBanGoc]) VALUES (7, N'Gọng kính Basic 01', 1, NULL, N'Đen', N'Nhựa', CAST(250000.00 AS Decimal(18, 2)), CAST(275000.00 AS Decimal(18, 2)), 25, N'Gọng kính phổ thông', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(250000.00 AS Decimal(18, 2)), CAST(275000.00 AS Decimal(18, 2)))
INSERT [dbo].[SanPham] ([MaSanPham], [TenSanPham], [MaLoai], [MaThuongHieu], [MauSac], [ChatLieu], [GiaNhap], [GiaBan], [SoLuongTon], [MoTa], [TrangThai], [HinhAnh], [LoaiGong], [HinhDang], [Diop], [CongDung], [DacDiem], [NuocSanXuat], [BaoHanh], [GhiChu], [MaChatLieu], [MaMauSac], [MaLoaiGong], [MaHinhDang], [MaDiop], [MaCongDung], [MaDacDiem], [MaNuocSanXuat], [MaBaoHanh], [GiaNhapGoc], [GiaBanGoc]) VALUES (8, N'Kính cận Classic', 3, NULL, N'Bạc', N'Kim loại', CAST(700000.00 AS Decimal(18, 2)), CAST(770000.00 AS Decimal(18, 2)), 15, N'Kính cận kiểu dáng đơn giản', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CAST(700000.00 AS Decimal(18, 2)), CAST(770000.00 AS Decimal(18, 2)))
SET IDENTITY_INSERT [dbo].[SanPham] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[TaiKhoan] ON 

INSERT [dbo].[TaiKhoan] ([MaTaiKhoan], [TenDangNhap], [MatKhau], [MaNhanVien], [Quyen], [TrangThai]) VALUES (1, N'admin', '', 1, N'Admin', 0)
INSERT [dbo].[TaiKhoan] ([MaTaiKhoan], [TenDangNhap], [MatKhau], [MaNhanVien], [Quyen], [TrangThai]) VALUES (2, N'lan', '', 2, N'NhanVien', 0)
INSERT [dbo].[TaiKhoan] ([MaTaiKhoan], [TenDangNhap], [MatKhau], [MaNhanVien], [Quyen], [TrangThai]) VALUES (3, N'tuan', '', 3, N'NhanVien', 0)
SET IDENTITY_INSERT [dbo].[TaiKhoan] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET IDENTITY_INSERT [dbo].[ThuongHieu] ON 

INSERT [dbo].[ThuongHieu] ([MaThuongHieu], [TenThuongHieu], [QuocGia]) VALUES (1, N'Ray-Ban', N'Ý')
INSERT [dbo].[ThuongHieu] ([MaThuongHieu], [TenThuongHieu], [QuocGia]) VALUES (2, N'Gucci', N'Ý')
INSERT [dbo].[ThuongHieu] ([MaThuongHieu], [TenThuongHieu], [QuocGia]) VALUES (3, N'Oakley', N'Mỹ')
INSERT [dbo].[ThuongHieu] ([MaThuongHieu], [TenThuongHieu], [QuocGia]) VALUES (4, N'Gentle Monster', N'Hàn Quốc')
INSERT [dbo].[ThuongHieu] ([MaThuongHieu], [TenThuongHieu], [QuocGia]) VALUES (5, N'Essilor', N'Pháp')
SET IDENTITY_INSERT [dbo].[ThuongHieu] OFF
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET ANSI_PADDING ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Index [UQ__ChucVu__A7E2123E8BCAD63F]    Script Date: 16/10/2026 23:27:14 ******/
ALTER TABLE [dbo].[ChucVu] ADD UNIQUE NONCLUSTERED 
(
	[TenChucVu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET ANSI_PADDING ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Index [UX_HoaDonBan_So]    Script Date: 16/10/2026 23:27:14 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_HoaDonBan_So] ON [dbo].[HoaDonBan]
(
	[SoHoaDon] ASC
)
WHERE ([SoHoaDon] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Index [UX_HoaDonBan_Token]    Script Date: 16/10/2026 23:27:14 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_HoaDonBan_Token] ON [dbo].[HoaDonBan]
(
	[TokenLuu] ASC
)
WHERE ([TokenLuu] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET ANSI_PADDING ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Index [UX_PhieuNhap_So]    Script Date: 16/10/2026 23:27:14 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_PhieuNhap_So] ON [dbo].[PhieuNhap]
(
	[SoHoaDon] ASC
)
WHERE ([SoHoaDon] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Index [UX_PhieuNhap_Token]    Script Date: 16/10/2026 23:27:14 ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_PhieuNhap_Token] ON [dbo].[PhieuNhap]
(
	[TokenLuu] ASC
)
WHERE ([TokenLuu] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
SET ANSI_PADDING ON
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
/****** Object:  Index [UQ__TaiKhoan__55F68FC00C147F2A]    Script Date: 16/10/2026 23:27:14 ******/
ALTER TABLE [dbo].[TaiKhoan] ADD UNIQUE NONCLUSTERED 
(
	[TenDangNhap] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan] ADD  DEFAULT ((0)) FOR [GiamGia]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap] ADD  DEFAULT ((0)) FOR [GiamGia]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[HoaDonBan] ADD  DEFAULT (getdate()) FOR [NgayBan]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[HoaDonBan] ADD  DEFAULT ((0)) FOR [TongTien]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[HoaDonBan] ADD  DEFAULT ((0)) FOR [DaHuy]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[NhanVien] ADD  DEFAULT ((1)) FOR [TrangThai]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[PhieuNhap] ADD  DEFAULT (getdate()) FOR [NgayNhap]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[PhieuNhap] ADD  DEFAULT ((0)) FOR [TongTien]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[PhieuNhap] ADD  DEFAULT ((0)) FOR [DaHuy]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] ADD  DEFAULT ((0)) FOR [GiaNhap]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] ADD  DEFAULT ((0)) FOR [GiaBan]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] ADD  DEFAULT ((0)) FOR [SoLuongTon]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] ADD  DEFAULT ((1)) FOR [TrangThai]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[TaiKhoan] ADD  DEFAULT ((1)) FOR [TrangThai]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan]  WITH CHECK ADD  CONSTRAINT [FK_CTHD_HoaDon] FOREIGN KEY([MaHoaDon])
REFERENCES [dbo].[HoaDonBan] ([MaHoaDon])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan] CHECK CONSTRAINT [FK_CTHD_HoaDon]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan]  WITH CHECK ADD  CONSTRAINT [FK_CTHD_SanPham] FOREIGN KEY([MaSanPham])
REFERENCES [dbo].[SanPham] ([MaSanPham])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan] CHECK CONSTRAINT [FK_CTHD_SanPham]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap]  WITH CHECK ADD  CONSTRAINT [FK_CTPN_PhieuNhap] FOREIGN KEY([MaPhieuNhap])
REFERENCES [dbo].[PhieuNhap] ([MaPhieuNhap])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap] CHECK CONSTRAINT [FK_CTPN_PhieuNhap]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap]  WITH CHECK ADD  CONSTRAINT [FK_CTPN_SanPham] FOREIGN KEY([MaSanPham])
REFERENCES [dbo].[SanPham] ([MaSanPham])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap] CHECK CONSTRAINT [FK_CTPN_SanPham]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[HoaDonBan]  WITH CHECK ADD  CONSTRAINT [FK_HoaDon_KhachHang] FOREIGN KEY([MaKhachHang])
REFERENCES [dbo].[KhachHang] ([MaKhachHang])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[HoaDonBan] CHECK CONSTRAINT [FK_HoaDon_KhachHang]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[HoaDonBan]  WITH CHECK ADD  CONSTRAINT [FK_HoaDon_NhanVien] FOREIGN KEY([MaNhanVien])
REFERENCES [dbo].[NhanVien] ([MaNhanVien])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[HoaDonBan] CHECK CONSTRAINT [FK_HoaDon_NhanVien]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[NhanVien]  WITH CHECK ADD  CONSTRAINT [FK_NhanVien_ChucVu] FOREIGN KEY([MaChucVu])
REFERENCES [dbo].[ChucVu] ([MaChucVu])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[NhanVien] CHECK CONSTRAINT [FK_NhanVien_ChucVu]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[PhieuNhap]  WITH CHECK ADD  CONSTRAINT [FK_PhieuNhap_NCC] FOREIGN KEY([MaNhaCungCap])
REFERENCES [dbo].[NhaCungCap] ([MaNhaCungCap])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[PhieuNhap] CHECK CONSTRAINT [FK_PhieuNhap_NCC]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[PhieuNhap]  WITH CHECK ADD  CONSTRAINT [FK_PhieuNhap_NhanVien] FOREIGN KEY([MaNhanVien])
REFERENCES [dbo].[NhanVien] ([MaNhanVien])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[PhieuNhap] CHECK CONSTRAINT [FK_PhieuNhap_NhanVien]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_BaoHanh] FOREIGN KEY([MaBaoHanh])
REFERENCES [dbo].[BaoHanh] ([MaBaoHanh])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_BaoHanh]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_ChatLieu] FOREIGN KEY([MaChatLieu])
REFERENCES [dbo].[ChatLieu] ([MaChatLieu])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_ChatLieu]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_CongDung] FOREIGN KEY([MaCongDung])
REFERENCES [dbo].[CongDung] ([MaCongDung])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_CongDung]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_DacDiem] FOREIGN KEY([MaDacDiem])
REFERENCES [dbo].[DacDiem] ([MaDacDiem])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_DacDiem]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_Diop] FOREIGN KEY([MaDiop])
REFERENCES [dbo].[Diop] ([MaDiop])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_Diop]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_HinhDang] FOREIGN KEY([MaHinhDang])
REFERENCES [dbo].[HinhDang] ([MaHinhDang])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_HinhDang]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_Loai] FOREIGN KEY([MaLoai])
REFERENCES [dbo].[LoaiSanPham] ([MaLoai])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_Loai]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_LoaiGong] FOREIGN KEY([MaLoaiGong])
REFERENCES [dbo].[LoaiGong] ([MaLoaiGong])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_LoaiGong]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_MauSac] FOREIGN KEY([MaMauSac])
REFERENCES [dbo].[MauSac] ([MaMauSac])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_MauSac]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_NuocSanXuat] FOREIGN KEY([MaNuocSanXuat])
REFERENCES [dbo].[NuocSanXuat] ([MaNuocSanXuat])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_NuocSanXuat]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [FK_SanPham_ThuongHieu] FOREIGN KEY([MaThuongHieu])
REFERENCES [dbo].[ThuongHieu] ([MaThuongHieu])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [FK_SanPham_ThuongHieu]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[TaiKhoan]  WITH CHECK ADD  CONSTRAINT [FK_TaiKhoan_NhanVien] FOREIGN KEY([MaNhanVien])
REFERENCES [dbo].[NhanVien] ([MaNhanVien])
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[TaiKhoan] CHECK CONSTRAINT [FK_TaiKhoan_NhanVien]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan]  WITH CHECK ADD CHECK  (([GiamGia]>=(0) AND [GiamGia]<=(100)))
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan]  WITH CHECK ADD  CONSTRAINT [CK_CTHD_DonGia] CHECK  (([DonGiaBan]>=(0)))
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan] CHECK CONSTRAINT [CK_CTHD_DonGia]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan]  WITH CHECK ADD  CONSTRAINT [CK_CTHD_SoLuong] CHECK  (([SoLuong]>(0)))
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietHoaDonBan] CHECK CONSTRAINT [CK_CTHD_SoLuong]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap]  WITH CHECK ADD CHECK  (([GiamGia]>=(0) AND [GiamGia]<=(100)))
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap]  WITH CHECK ADD  CONSTRAINT [CK_CTPN_DonGia] CHECK  (([DonGiaNhap]>=(0)))
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap] CHECK CONSTRAINT [CK_CTPN_DonGia]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap]  WITH CHECK ADD  CONSTRAINT [CK_CTPN_SoLuong] CHECK  (([SoLuong]>(0)))
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[ChiTietPhieuNhap] CHECK CONSTRAINT [CK_CTPN_SoLuong]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [CK_SanPham_GiaBan] CHECK  (([GiaBan]>=(0)))
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [CK_SanPham_GiaBan]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [CK_SanPham_GiaNhap] CHECK  (([GiaNhap]>=(0)))
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [CK_SanPham_GiaNhap]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham]  WITH CHECK ADD  CONSTRAINT [CK_SanPham_SoLuongTon] CHECK  (([SoLuongTon]>=(0)))
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[SanPham] CHECK CONSTRAINT [CK_SanPham_SoLuongTon]
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
ALTER TABLE [dbo].[KhachHang] ADD [GhiChu] nvarchar(500) NULL;
GO

IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
CREATE TABLE [dbo].[WebUsers] (
    [Id] int IDENTITY(1,1) NOT NULL CONSTRAINT [PK_WebUsers] PRIMARY KEY,
    [EmployeeId] int NOT NULL CONSTRAINT [UQ_WebUsers_EmployeeId] UNIQUE,
    [UserName] nvarchar(50) NOT NULL CONSTRAINT [UQ_WebUsers_UserName] UNIQUE,
    [PasswordHash] nvarchar(512) NOT NULL,
    [DisplayName] nvarchar(100) NOT NULL,
    [Role] nvarchar(20) NOT NULL,
    [IsActive] bit NOT NULL CONSTRAINT [DF_WebUsers_IsActive] DEFAULT (1),
    [SecurityStamp] uniqueidentifier NOT NULL CONSTRAINT [DF_WebUsers_SecurityStamp] DEFAULT (NEWID()),
    [CreatedAt] datetime2 NOT NULL CONSTRAINT [DF_WebUsers_CreatedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [FK_WebUsers_NhanVien] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[NhanVien]([MaNhanVien]),
    CONSTRAINT [CK_WebUsers_Role] CHECK ([Role] IN (N'Admin', N'Staff'))
);
GO

-- BEGIN WEB EMPLOYEE ACCOUNT SEED
IF DB_NAME() <> N'QuanLyKinhMatWeb'
    OR ISNULL(CONVERT(nvarchar(64), SESSION_CONTEXT(N'KinhMat.Provisioning')), N'') <> N'NewDatabaseOnly'
    THROW 51002, 'Run scripts/Initialize-Database.ps1 against a new QuanLyKinhMatWeb database.', 1;
IF EXISTS(SELECT 1 FROM dbo.WebUsers) THROW 51003, 'WebUsers must be empty for initial account seed.', 1;
INSERT dbo.WebUsers(EmployeeId,UserName,PasswordHash,DisplayName,Role,IsActive) VALUES(1,N'1',N'AQAAAAIAAYagAAAAEIg0tCr50rK0LFykE1guIyLvUI7BcdSDLk5YYScDdrhKm4T74oDxbaigqfQG8rA58w==',N'Nguyễn Văn An',N'Admin',1);
INSERT dbo.WebUsers(EmployeeId,UserName,PasswordHash,DisplayName,Role,IsActive) VALUES(2,N'2',N'AQAAAAIAAYagAAAAEBDy1YgZuBx+6FeBZLiwyZ8Yom9NwyIak+t/wXH1iav5w1oo8vKpMxmeLxl+nfB15Q==',N'Trần Thị Lan',N'Staff',1);
INSERT dbo.WebUsers(EmployeeId,UserName,PasswordHash,DisplayName,Role,IsActive) VALUES(3,N'3',N'AQAAAAIAAYagAAAAEEQdzA5Ij7vjL0r0oEdkWIjZeo/ZTdwGuzwWERbubUH47wBW+t4VVVQtWRFHsnwuhw==',N'Lê Minh Tuấn',N'Staff',1);
GO
-- END WEB EMPLOYEE ACCOUNT SEED
