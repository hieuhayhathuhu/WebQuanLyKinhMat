# Database riêng cho ứng dụng web

## Phạm vi và nguồn dữ liệu

`../../QuanLyKinhMat.sql` được chuyển từ dump `QLKM.sql` của project WinForms đã cung cấp. Bộ script không đọc hoặc sao chép trực tiếp database đang hoạt động.

- Nguồn dump có **21 bảng nghiệp vụ**. Thêm `dbo.WebUsers` cho ứng dụng web, tổng cộng **22 bảng**. Bảng hệ thống như `sysdiagrams` không thuộc schema nghiệp vụ này.
- Giữ tên bảng/cột, dữ liệu nghiệp vụ, identity, khóa chính/ngoại, default, check constraint và view gốc.
- Giữ unique filtered index `UX_HoaDonBan_Token`, `UX_PhieuNhap_Token` và các index mã chứng từ; không tạo bản trùng.
- Thêm `dbo.KhachHang.GhiChu nvarchar(500) NULL` để lưu ghi chú từ form web.
- Không chép cấu hình đường dẫn `.mdf/.ldf`, database option gắn với server gốc, SQL login, database user hoặc role membership từ dump.
- Loại tùy chọn index `OPTIMIZE_FOR_SEQUENTIAL_KEY=OFF` khỏi bản chuyển để giảm phụ thuộc phiên bản server; không đổi khóa hay tính duy nhất của index.

## Loại bỏ mật khẩu cũ

Trong chính các câu seed của bản SQL mới:

- `NhanVien.Passw` được thay bằng `NULL`.
- `TaiKhoan.MatKhau` được thay bằng chuỗi rỗng và `TrangThai=0`.
- Các giá trị mật khẩu cũ không được giữ rồi mới xóa sau khi import.
- Ứng dụng web chỉ xác thực bằng `WebUsers.PasswordHash`; không dùng hai nguồn mật khẩu cũ.

`WebUsers` có khóa chính identity `Id`, khóa ngoại `EmployeeId` duy nhất tới `NhanVien`, `UserName` duy nhất, `PasswordHash`, `DisplayName`, `Role` (`Admin`/`Staff`), `IsActive`, `SecurityStamp` và `CreatedAt`. Script SQL có ba tài khoản mã nhân viên `1`/`2`/`3` bằng `PasswordHash`, không chứa mật khẩu văn bản.

## Tài khoản trong bộ nộp

SQL đã kèm đủ ba tài khoản: mã `1` là Admin; mã `2`, `3` là Staff. Người dùng nhập mã nhân viên và mật khẩu đã cung cấp cho bản chạy. Hash được tạo bằng ASP.NET PasswordHasher, không dùng cột Passw để xác thực web. Thông tin đăng nhập mẫu nằm trong [README](../../README.md#1-tài-khoản-đăng-nhập).

Máy mới chỉ cần SQL Server, SSMS và bộ SQL đi kèm; không cần `QuanLyKinhMat` gốc. `scripts/Import-EmployeeLogins.ps1` là công cụ chuyển tùy chọn từ bản gốc khi cần, không phải bước dựng bộ nộp. Công cụ chỉ đọc nguồn, không reset tài khoản đã có; gặp hash PBKDF2 cũ sẽ dừng để chuyển bằng xác minh mật khẩu.

## Chạy khởi tạo

Trong SSMS, kết nối SQL Server, mở toàn bộ [QuanLyKinhMat.sql](../../QuanLyKinhMat.sql) và nhấn **F5**. Tài khoản kết nối cần quyền tạo database. Chỉ chạy lần đầu khi `QuanLyKinhMatWeb` chưa tồn tại.

Script tự tạo database bằng đường dẫn mặc định của SQL Server, chuyển sang database mới rồi chạy schema và dữ liệu mẫu trong transaction. Từng batch kiểm tra tên database, dấu `SESSION_CONTEXT` của lần khởi tạo và trạng thái transaction. Cuối script commit và xóa dấu session.

Nếu database đã có, script từ chối khởi tạo, không ghi đè dữ liệu. `XACT_ABORT ON` hoàn tác transaction khi gặp lỗi thực thi; database mới được giữ lại để kiểm tra lỗi. Không chạy riêng một đoạn seed/schema hoặc tự xóa database đang sử dụng.

Sau khi chuẩn bị database, sửa `ConnectionStrings.Store` trong `appsettings.json` cho đúng SQL Server, mở solution bằng Visual Studio hoặc dùng `dotnet run`.

## Kiểm tra sau khởi tạo

Các truy vấn sau chỉ đọc; chạy trên `QuanLyKinhMatWeb`:

```sql
SELECT DB_NAME() AS DatabaseName;
SELECT COUNT(*) AS BusinessTableCount FROM sys.tables WHERE is_ms_shipped=0;
SELECT COUNT(*) AS LegacyEmployeePasswords FROM dbo.NhanVien WHERE Passw IS NOT NULL;
SELECT COUNT(*) AS ActiveLegacyAccounts FROM dbo.TaiKhoan WHERE TrangThai<>0 OR MatKhau<>'';
SELECT name, has_filter, filter_definition
FROM sys.indexes
WHERE name IN ('UX_HoaDonBan_Token','UX_PhieuNhap_Token');
SELECT COL_LENGTH('dbo.KhachHang','GhiChu') AS NoteColumnBytes;
SELECT COUNT(*) AS WebAccountCount FROM dbo.WebUsers;
```

Kỳ vọng: database đúng tên, 22 bảng, hai số đếm mật khẩu/tài khoản cũ bằng 0, hai filtered index có điều kiện `TokenLuu IS NOT NULL`, ghi chú có kích thước 1000 byte (500 ký tự Unicode). `WebUsers` có ba tài khoản mã nhân viên ngay sau khởi tạo; khởi động lại không tự tạo thêm tài khoản.

Không xuất `PasswordHash` hoặc dữ liệu cá nhân để chứng minh kết quả. Script khởi tạo chỉ ghi vào database web mới; không thay đổi database WinForms gốc.

## Vị trí SQL trong repository

File SQL hoàn chỉnh nằm ở ngoài cùng: [QuanLyKinhMat.sql](../../QuanLyKinhMat.sql). Mở trực tiếp file này trong SSMS; không phụ thuộc tên thư mục clone hoặc database gốc trên máy chấm bài.
