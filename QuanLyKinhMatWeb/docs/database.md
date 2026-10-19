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

`WebUsers` có khóa chính identity `Id`, khóa ngoại `EmployeeId` duy nhất tới `NhanVien`, `UserName` duy nhất, `PasswordHash`, `DisplayName`, `Role` (`Admin`/`Staff`), `IsActive`, `SecurityStamp` và `CreatedAt`. Script SQL có ba tài khoản mã nhân viên `1`/`2`/`3` bằng `PasswordHash`, không chứa mật khẩu văn bản. Ứng dụng không tạo tài khoản demo.

## Tài khoản trong bộ nộp

SQL đã kèm đủ ba tài khoản: mã `1` là Admin; mã `2`, `3` là Staff. Người dùng nhập mã nhân viên và mật khẩu đã cung cấp cho bản chạy. Hash được tạo bằng ASP.NET PasswordHasher, không dùng cột Passw để xác thực web. Hai tài khoản demo đã xóa và không được seed lại.

Máy mới chỉ cần SQL Server, bộ SQL và runner đi kèm; không cần `QuanLyKinhMat` gốc. `scripts/Import-EmployeeLogins.ps1` là công cụ chuyển tùy chọn từ bản gốc khi cần, không phải bước dựng bộ nộp. Công cụ chỉ đọc nguồn, không reset tài khoản đã có; gặp hash PBKDF2 cũ sẽ dừng để chuyển bằng xác minh mật khẩu.

## Chạy khởi tạo

Tại thư mục project:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Initialize-Database.ps1 -Server 'HIEUCOI\SQLEXPRESS'
```

Runner dùng `System.Data.SqlClient` của Windows PowerShell và Windows Authentication. Tên database đích cố định là **QuanLyKinhMatWeb**, không có tham số chuyển sang database gốc.

Trình tự thực hiện:

1. Kết nối `master`, kiểm tra database đích chưa tồn tại.
2. Tạo database mới bằng đường dẫn mặc định do SQL Server quản lý.
3. Kết nối riêng tới database vừa tạo, kiểm tra chưa có bảng người dùng.
4. Đánh dấu connection bằng `SESSION_CONTEXT` rồi chạy các batch schema/seed trong một transaction.
5. Commit nếu toàn bộ batch thành công; rollback schema/seed nếu một batch lỗi.

Từng batch SQL kiểm tra cả `DB_NAME()` và dấu session của runner. Chạy file SQL trực tiếp trên database gốc hoặc bằng connection thông thường sẽ bị từ chối. Hãy dùng runner thay vì bỏ các guard để chạy thủ công.

Nếu database đã tồn tại, runner dừng **trước mọi thao tác tạo bảng/seed**. Script không có `DROP`, `TRUNCATE`, chế độ ghi đè hay chế độ dọn database. Khi schema lỗi, database mới vẫn tồn tại để chẩn đoán; không tự chạy lại trên database đó. Sau khi kiểm tra nguyên nhân, quản trị viên quyết định cách xử lý bản khởi tạo lỗi.

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

Kỳ vọng: database đúng tên, 22 bảng, hai số đếm mật khẩu/tài khoản cũ bằng 0, hai filtered index có điều kiện `TokenLuu IS NOT NULL`, ghi chú có kích thước 1000 byte (500 ký tự Unicode). `WebUsers` có ba tài khoản mã nhân viên ngay sau khởi tạo; khởi động lại không tạo thêm demo.

Không xuất `PasswordHash` hoặc dữ liệu cá nhân để chứng minh kết quả. Database WinForms gốc không nằm trong chuỗi kết nối của runner ở bất kỳ bước import nào.

## Vị trí SQL trong repository

File SQL hoàn chỉnh nằm ở ngoài cùng: [QuanLyKinhMat.sql](../../QuanLyKinhMat.sql). Runner trong `scripts/Initialize-Database.ps1` đọc file này theo đường dẫn tương đối; không phụ thuộc tên thư mục clone hoặc database gốc trên máy chấm bài.
