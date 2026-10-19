# WebQuanLyKinhMat

Bài tập lớn môn Lập trình web: ASP.NET Core MVC, C#, Razor, JavaScript và SQL Server. Mã nguồn được tổ chức để mở bằng Visual Studio và nộp trên GitHub.

## Cấu trúc repository

```text
WebQuanLyKinhMat/
├── WebQuanLyKinhMat/
├── .gitignore
├── CAI_DAT_VA_SU_DUNG.md
├── QuanLyKinhMat.sql
├── WebQuanLyKinhMat.slnx
└── README.md
```


## Chức năng

- Đăng nhập theo mã nhân viên; quyền quản lý và nhân viên.
- Quản lý sản phẩm, khách hàng, nhà cung cấp và danh mục.
- Nhập hàng, bán hàng, giảm giá, hủy chứng từ và cập nhật tồn kho.
- Tìm kiếm, lọc, phân trang, báo cáo và xuất CSV.
- Kiểm tra giá/tồn trên máy chủ, transaction và chống lưu trùng.

## Chạy dự án

1. Cài .NET 10 SDK và SQL Server.
2. Sửa tên `Server` trong `WebQuanLyKinhMat/appsettings.json` cho đúng instance của máy. Giữ `Database=QuanLyKinhMatWeb` và Windows Authentication.
3. Mở thư mục `WebQuanLyKinhMat`, nhấp đúp **CHAY-WEB.cmd** bên trong. Bản Git chứa source; lần đầu launcher build project rồi mở http://127.0.0.1:5080.
4. Dừng bằng **TAT-WEB.cmd** trong cùng thư mục project.

Khi database web chưa có, launcher tạo bằng `QuanLyKinhMat.sql`; tài khoản Windows cần quyền tạo database. Database đã có không bị ghi đè. Máy chấm bài không cần database WinForms gốc.

Mở source bằng **WebQuanLyKinhMat.slnx**, chọn project web rồi chạy trong Visual Studio. Chi tiết xem [hướng dẫn dự án](CAI_DAT_VA_SU_DUNG.md).

## Tài khoản bài thực hành

| Mã nhân viên | Vai trò | Mật khẩu khởi tạo trong bộ SQL |
|---|---|---|
| `1` | Quản lý | `hieucoi12345` |
| `2` | Nhân viên bán hàng | `hieucoi12345` |
| `3` | Nhân viên kho | `hieucoi12345` |

Hai tài khoản demo `admin`, `nhanvien` đã xóa và không tự tạo lại. SQL lưu PasswordHash của ba tài khoản, không lưu mật khẩu văn bản trong bảng web. Nếu tài khoản đã đổi mật khẩu trên database đang dùng, khởi động lại không reset mật khẩu đó.

## Tài liệu và giao diện

- [Báo cáo kỹ thuật](WebQuanLyKinhMat/docs/report.md).
- [Kiến trúc và thiết kế dữ liệu](WebQuanLyKinhMat/docs/architecture.md).
- [Kết quả kiểm thử](WebQuanLyKinhMat/docs/verification.md).
- [Hướng dẫn đưa lên GitHub](CAI_DAT_VA_SU_DUNG.md#đưa-thư-mục-này-lên-github).

![Giao diện sản phẩm](WebQuanLyKinhMat/docs/screenshots/products-desktop.png)

Thông tin trường, lớp, thành viên và khảo sát thực tế trong báo cáo cần được nhóm bổ sung trước khi nộp.
