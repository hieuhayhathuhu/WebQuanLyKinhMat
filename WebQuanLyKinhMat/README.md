# Quản lý cửa hàng kính mắt - ASP.NET MVC

Ứng dụng web cho bài tập lớn môn Lập trình web, dùng ASP.NET Core MVC, Razor, JavaScript và SQL Server. Giao diện được phát triển từ bản web đã cung cấp; phần máy chủ xử lý đăng nhập, phân quyền, kiểm tra dữ liệu và giao dịch nhập/bán. Project WinForms được dùng để tham khảo nghiệp vụ.

Database của ứng dụng là **QuanLyKinhMatWeb**. Database WinForms **QuanLyKinhMat** được giữ riêng; bộ khởi tạo không ghi vào database đó.

## Chạy nhanh trên máy hiện tại

Nhấp đúp **`CHAY-WEB.cmd`**. Launcher kiểm tra SQL Server, tạo database riêng nếu chưa có, chạy ứng dụng trong nền và mở trình duyệt tại **http://127.0.0.1:5080**. Dùng **`TAT-WEB.cmd`** để dừng đúng tiến trình đã khởi động. Nhật ký nằm trong `App_Data/server.log` và `server-error.log`.

Trên máy hiện tại đã có database riêng và đã chuyển tài khoản cũ theo mã nhân viên: **`1` (quản lý), `2` và `3` (nhân viên)**. Dùng mật khẩu cũ trong SQL. Bên web lưu mật khẩu bằng hash; database gốc không thay đổi. Bản GitHub chứa mã nguồn; launcher build project bằng .NET 10 SDK rồi chạy. Không đưa runtime hoặc thư viện biên dịch lên Git. Hướng dẫn Git và cấu trúc repo nằm trong [README ngoài cùng](../README.md).

Đã hoàn tất **186 kiểm tra tự động/hồi quy và 40 tổ hợp bố cục**: API/nghiệp vụ, form bán/nhập, phân quyền/đổi mật khẩu, tìm kiếm/phân trang, CSV và lỗi mạng. Xem [kết quả kiểm thử thực tế](docs/verification.md), [đầu ra từng kiểm tra](docs/test-results.json) và [ảnh giao diện](docs/screenshots/products-desktop.png). Dữ liệu QA đã được dọn sau kiểm thử.

## 1. Chuẩn bị

- Windows, .NET 10 SDK và SQL Server đang chạy. Project khai báo `net10.0` trong `WebQuanLyKinhMat.csproj`.
- Tài khoản Windows chạy bước khởi tạo có quyền tạo database trên SQL Server.
- Mặc định SQL Server là `HIEUCOI\SQLEXPRESS`, dùng Windows Authentication. Không cần đặt mật khẩu SQL vào JavaScript.
- Có thể mở `WebQuanLyKinhMat.csproj` bằng Visual Studio có công cụ phát triển ASP.NET; hoặc dùng các lệnh `dotnet` bên dưới.

## 2. Tạo database riêng

Mở PowerShell tại thư mục chứa `WebQuanLyKinhMat.csproj`:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Initialize-Database.ps1
```

Nếu tên máy/instance khác:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\Initialize-Database.ps1 -Server '.\SQLEXPRESS'
```

Script tạo database mới từ `../QuanLyKinhMat.sql`: giữ 21 bảng nghiệp vụ, các view, ràng buộc và dữ liệu của dump gốc; thêm `WebUsers` thành 22 bảng và thêm `KhachHang.GhiChu`. Mật khẩu cũ trong `NhanVien` bị loại bỏ; các tài khoản `TaiKhoan` cũ bị vô hiệu hóa. Tài khoản web dùng bảng `WebUsers` riêng.

**Nếu `QuanLyKinhMatWeb` đã tồn tại, script dừng trước khi ghi dữ liệu.** Script không có chế độ ghi đè, xóa hoặc reset. Khi khởi tạo schema lỗi, giao dịch được rollback và database mới được giữ lại để kiểm tra; lần chạy sau cũng dừng vì database đã tồn tại. Xem [hướng dẫn database](docs/database.md).

## 3. Cấu hình và chạy

Trong `appsettings.json`, sửa tên server nếu cần và giữ tên database `QuanLyKinhMatWeb`:

```json
{
  "ConnectionStrings": {
    "Store": "Server=HIEUCOI\\SQLEXPRESS;Database=QuanLyKinhMatWeb;Integrated Security=True;TrustServerCertificate=True;Connect Timeout=10"
  }
}
```

`TrustServerCertificate=True` phục vụ SQL Server cục bộ trong bài thực hành. Khi dùng môi trường khác, cấu hình chứng chỉ và kết nối phù hợp với môi trường đó.

```powershell
dotnet restore
dotnet build
dotnet run --urls "http://127.0.0.1:5080"
```

Mở [http://127.0.0.1:5080](http://127.0.0.1:5080). Chỉ chạy trên máy cục bộ; không cấu hình địa chỉ lắng nghe công khai. Khi mở trong Visual Studio, chọn project web làm Startup Project và chạy bằng cấu hình local.

## 4. Tài khoản đăng nhập

Đăng nhập bằng **mã nhân viên** từ `QuanLyKinhMat.dbo.NhanVien.MaNhanVien` và mật khẩu cũ của cột `Passw`. Trên máy hiện tại đã chuyển thành công mã `1`, `2`, `3` sang `QuanLyKinhMatWeb.dbo.WebUsers` và kiểm tra đăng nhập/quyền/đăng xuất đủ ba tài khoản.

Bộ SQL khởi tạo đã có đủ ba tài khoản bằng `PasswordHash`; máy chấm bài không cần database WinForms `QuanLyKinhMat`. Hai tài khoản demo `admin`, `nhanvien` cùng nhân viên demo không có chứng từ đã được xóa, và ứng dụng không còn chức năng tự tạo lại chúng.

Nếu cần chuyển lại từ một database gốc riêng, công cụ `scripts/Import-EmployeeLogins.ps1` vẫn có thể dùng tùy chọn; chạy lại không reset tài khoản đã có. Đây không phải bước bắt buộc của bộ nộp. Sau khi chuyển, mật khẩu được quản lý trên web độc lập với WinForms.

## 5. Sử dụng và phân quyền

| Chức năng | Admin | Staff |
|---|---|---|
| Đăng nhập, đăng xuất, đổi mật khẩu của mình | Có | Có |
| Xem tổng quan, tìm kiếm và báo cáo | Có | Có |
| Tra cứu sản phẩm, khách hàng, nhà cung cấp và danh mục | Có | Có |
| Thêm/sửa/xóa khách hàng theo ràng buộc dữ liệu | Có | Có |
| Thêm/sửa/xóa sản phẩm, nhà cung cấp và danh mục | Có | Không |
| Lập hóa đơn bán hàng | Có | Có |
| Lập/xem/hủy phiếu nhập | Có | Không |
| Hủy hóa đơn bán hàng | Có | Không |
| Quản lý tài khoản, vai trò và trạng thái tài khoản | Có | Không |

Quyền sửa dữ liệu nghiệp vụ được kiểm tra tại endpoint máy chủ; việc ẩn nút trên giao diện chỉ hỗ trợ thao tác. Staff xem báo cáo và lịch sử bán hàng; dữ liệu phiếu nhập dành cho Admin. Ma trận chi tiết theo API nằm trong [kiến trúc và phân quyền](docs/architecture.md).

Luồng demo nên thực hiện: đăng nhập quản trị → kiểm tra danh mục/sản phẩm/khách hàng/nhà cung cấp → nhập hàng → bán hàng → xem chứng từ và báo cáo → thử quyền nhân viên bằng cửa sổ trình duyệt riêng → đổi mật khẩu và đăng xuất.

## 6. Tài liệu bài tập lớn

- [Kiến trúc, use-case, ERD và luồng xử lý](docs/architecture.md).
- [Sitemap và wireframe các màn hình](docs/wireframes.md).
- [Danh mục test case và cách ghi kết quả](docs/test-cases.md).
- [Báo cáo kỹ thuật theo hướng dẫn của thầy](docs/report.md) (bổ sung thông tin trường/lớp/thành viên trước khi nộp).
- [Khởi tạo, an toàn dữ liệu và kiểm tra database](docs/database.md).

Các tài liệu phân biệt chức năng đã có trong mã nguồn với kết quả cần chạy kiểm thử. Bảng test case không được coi là bằng chứng đã pass khi chưa ghi đầu ra thực tế.

## 7. Xử lý lỗi thường gặp

| Hiện tượng | Kiểm tra |
|---|---|
| Không kết nối được SQL Server | Instance đã chạy, tên server đúng và tài khoản Windows có quyền truy cập. Chuỗi kết nối của web khác với cấu hình WinForms. |
| Database đã tồn tại | Bỏ qua bước khởi tạo nếu đó là database web đã tạo thành công. Không đổi tên sang database gốc để chạy script. |
| Không có bảng `WebUsers` | Database chưa được khởi tạo bằng bộ script này hoặc connection string đang trỏ sai. |
| Không đăng nhập được bằng tài khoản WinForms | Nhập mã nhân viên dạng số (ví dụ `1`), không nhập tên người. SQL đóng gói đã có ba tài khoản; kiểm tra nhân viên còn hoạt động và database đúng bản web. |
| SDK không nhận `net10.0` | Kiểm tra `dotnet --list-sdks` và dùng SDK tương ứng với target của project. |
| Cổng 5080 đang được dùng | Đổi cổng trong lệnh `dotnet run --urls`, vẫn giữ host `127.0.0.1`. |
