# Cài đặt và sử dụng

**Yêu cầu:** Windows, .NET 10 SDK, SQL Server và SSMS. Nếu dùng Visual Studio, cần phiên bản hỗ trợ .NET 10, `.slnx` và workload **ASP.NET and web development**.

## 1. Khởi chạy dự án

1. **Cơ sở dữ liệu:** Trong SSMS, kết nối SQL Server, mở `QuanLyKinhMat.sql` ở thư mục ngoài cùng và nhấn **F5** để tạo database `QuanLyKinhMatWeb` cùng dữ liệu mẫu. Chỉ thực hiện khi database chưa có; tài khoản kết nối cần quyền tạo database.
2. **Kết nối:** Mở `WebQuanLyKinhMat/appsettings.json`, sửa `Server` trong `ConnectionStrings.Store` theo tên máy chủ ở SSMS; giữ tên database và dùng **Windows Authentication**. Ví dụ:

   ```json
   "Store": "Server=HIEUCOI\\SQLEXPRESS;Database=QuanLyKinhMatWeb;Integrated Security=True;TrustServerCertificate=True;Connect Timeout=10"
   ```

3. **Chạy ứng dụng:** Mở `WebQuanLyKinhMat.slnx` ở thư mục ngoài cùng bằng Visual Studio, chọn project **WebQuanLyKinhMat** rồi nhấn **F5** hoặc **Ctrl + F5**.

   Hoặc mở terminal tại thư mục ngoài cùng và chạy:

   ```powershell
   cd WebQuanLyKinhMat
   dotnet run
   ```

4. Mở **[http://127.0.0.1:5080](http://127.0.0.1:5080)**. Dừng bằng **Shift + F5** khi debug, hoặc **Ctrl + C** tại cửa sổ console/terminal.

## 2. Đăng nhập

| Tài khoản | Mật khẩu khởi tạo | Quyền |
|---|---|---|
| `1` | `hieucoi12345` | Quản lý |
| `2`, `3` | `hieucoi12345` | Nhân viên |

Nếu đã đổi mật khẩu, sử dụng mật khẩu mới. Các chức năng và kết quả kiểm thử xem tại [README](README.md).
