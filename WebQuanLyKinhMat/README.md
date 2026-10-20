# WebQuanLyKinhMat — mã nguồn ứng dụng

Project ASP.NET Core MVC, target `net10.0`, kết nối SQL Server qua `Microsoft.Data.SqlClient`.

- [Giới thiệu, tài khoản mẫu và bảng kiểm thử](../README.md).
- [Cài đặt, cấu hình SQL Server và chạy ứng dụng](../CAI_DAT_VA_SU_DUNG.md).
- [Kiến trúc và phân quyền](docs/architecture.md).
- [Thiết kế và khởi tạo database](docs/database.md).
- [Báo cáo kỹ thuật](docs/report.md).
- [Ca kiểm thử](docs/test-cases.md) và [kết quả kiểm thử](docs/verification.md).

Mở [WebQuanLyKinhMat.slnx](../WebQuanLyKinhMat.slnx) tại thư mục ngoài cùng. File khởi tạo database nằm tại [QuanLyKinhMat.sql](../QuanLyKinhMat.sql).

Lần đầu, chạy file SQL trong SSMS và cấu hình kết nối theo hướng dẫn cài đặt. Nếu đã có database `QuanLyKinhMatWeb`, bỏ qua bước khởi tạo. Sau đó mở solution bằng Visual Studio và nhấn **F5**, hoặc dùng `dotnet run` tại thư mục chứa `.csproj`.
