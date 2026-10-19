# Cài đặt và sử dụng

**Yêu cầu:** Windows, .NET 10 SDK và SQL Server. Nếu dùng Visual Studio, cài workload **ASP.NET and web development** và phiên bản hỗ trợ .NET 10, `.slnx`.

## 1. Khởi chạy dự án

1. Tải và giải nén toàn bộ dự án, giữ nguyên cấu trúc thư mục.
2. Mở `WebQuanLyKinhMat/appsettings.json`, sửa **`Server`** trong `ConnectionStrings.Store` theo tên máy chủ hiển thị ở SSMS. Giữ tên database `QuanLyKinhMatWeb` và dùng **Windows Authentication**. Ví dụ với SQL Express trên máy hiện tại:

   ```json
   "Store": "Server=HIEUCOI\\SQLEXPRESS;Database=QuanLyKinhMatWeb;Integrated Security=True;TrustServerCertificate=True;Connect Timeout=10"
   ```

3. Mở thư mục `WebQuanLyKinhMat` bên trong, nhấp đúp **`CHAY-WEB.cmd`**. Chương trình tự tạo database và dữ liệu mẫu từ `QuanLyKinhMat.sql` nếu chưa có, sau đó biên dịch và mở website. Lần đầu cần mạng để tải thư viện và tài khoản Windows có quyền tạo database.
4. Truy cập **[http://127.0.0.1:5080](http://127.0.0.1:5080)**. Dừng chương trình bằng **`TAT-WEB.cmd`**.

**Chạy bằng Visual Studio:** Sau lần khởi chạy đầu, dùng `TAT-WEB.cmd` để dừng web, mở **`WebQuanLyKinhMat.slnx`** ở thư mục ngoài cùng rồi nhấn **F5** hoặc **Ctrl + F5**.

## 2. Đăng nhập

| Tài khoản | Mật khẩu khởi tạo | Quyền |
|---|---|---|
| `1` | `hieucoi12345` | Quản lý |
| `2`, `3` | `hieucoi12345` | Nhân viên |

Tài khoản trên dùng để đăng nhập website. Nếu đã đổi mật khẩu, sử dụng mật khẩu mới. Chức năng và kết quả kiểm thử xem tại [README](README.md).
