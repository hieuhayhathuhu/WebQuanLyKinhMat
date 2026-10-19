# Cài đặt và sử dụng

## 1. Chuẩn bị và kết nối SQL Server

Cần **Windows, .NET 10 SDK và SQL Server đang chạy**. Nếu dùng Visual Studio, cần hỗ trợ `.slnx`, .NET 10 và workload **ASP.NET and web development**. Lần build đầu cần mạng để tải thư viện NuGet nếu máy chưa có cache.

Giải nén/clone toàn bộ repository. Mở **`WebQuanLyKinhMat/appsettings.json`**, sửa phần `Server` trong `ConnectionStrings.Store` theo instance của máy:

- Mặc định: `HIEUCOI\SQLEXPRESS`; máy khác có thể là `.\SQLEXPRESS`, `TEN_MAY\SQLEXPRESS` hoặc `.` với instance mặc định.
- Trong chuỗi JSON, mỗi dấu `\` phải viết thành `\\`, ví dụ `Server=.\\SQLEXPRESS`.
- Giữ **`Database=QuanLyKinhMatWeb`** và Windows Authentication (`Integrated Security=True`).

## 2. Chạy lần đầu

1. Mở thư mục **`WebQuanLyKinhMat` bên trong** rồi nhấp đúp **`CHAY-WEB.cmd`**.
2. Đợi script kiểm tra database, build source và mở trình duyệt.
3. Truy cập **[http://127.0.0.1:5080](http://127.0.0.1:5080)** nếu trình duyệt chưa tự mở.
4. Đăng nhập bằng tài khoản ở mục 4; dùng **`TAT-WEB.cmd`** trong cùng thư mục để dừng web.

Khi database chưa có, script tự tạo từ **`QuanLyKinhMat.sql` ở ngoài cùng**; tài khoản Windows cần quyền tạo database. Database đã có không bị ghi đè. Hãy dùng script đi kèm để khởi tạo vì bộ SQL có kiểm tra phiên chạy; không chạy trực tiếp file SQL bằng F5 trong SSMS.

Đóng tab trình duyệt không dừng tiến trình web. Không cần cài Node.js để sử dụng ứng dụng.

## 3. Mở bằng Visual Studio

Sau khi chạy thành công lần đầu ở mục 2:

1. Dùng `TAT-WEB.cmd` dừng phiên chạy nhanh để giải phóng cổng 5080.
2. Mở **`WebQuanLyKinhMat.slnx` ở ngoài cùng**.
3. Chọn project/profile **`WebQuanLyKinhMat`**, nhấn **F5** hoặc **Ctrl + F5**.
4. Dừng bằng **Stop Debugging** khi chạy F5; với cửa sổ console của Ctrl + F5, dùng **Ctrl + C**.

Visual Studio không tự tạo database. Khi sửa source, dừng rồi chạy lại để biên dịch thay đổi.

## 4. Đăng nhập và thao tác

| Tên đăng nhập | Mật khẩu khởi tạo | Quyền |
|---|---|---|
| `1` | `hieucoi12345` | Quản lý |
| `2`, `3` | `hieucoi12345` | Nhân viên |

Đây là tài khoản web, khác với tài khoản kết nối SQL Server. Nếu đã đổi mật khẩu thì dùng mật khẩu mới; khởi động lại không reset mật khẩu.

**Luồng sử dụng:** tra cứu sản phẩm → quản lý nhập hàng nếu cần → chọn khách hàng/khách lẻ → thêm sản phẩm vào giỏ bán → kiểm tra số lượng, giảm giá và tổng tiền → xác nhận lưu. Xem lại chứng từ trong Bán hàng/Nhập hàng; quản lý có thể hủy theo quy tắc tồn kho. Báo cáo cho chọn 7 hoặc 30 ngày gần nhất.

Nhân viên được bán hàng và quản lý khách hàng; quản lý có thêm quyền sửa sản phẩm/danh mục, nhà cung cấp, nhập hàng, hủy chứng từ và quản lý tài khoản. Đổi mật khẩu hoặc đăng xuất tại **Tài khoản của tôi**.

## 5. Lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| Thiếu SDK hoặc build không hỗ trợ `net10.0` | Chạy `dotnet --list-sdks`, kiểm tra có .NET 10 SDK; lỗi tải thư viện thì kiểm tra mạng/NuGet. |
| Không kết nối SQL hoặc không tạo được database | Kiểm tra tên instance, dịch vụ SQL Server và quyền tài khoản Windows; có thể thử kết nối trong SSMS. |
| Cổng 5080 đang được dùng | Dừng phiên cũ bằng đúng CMD/Visual Studio đã khởi chạy nó, rồi chạy lại. |
| Có database nhưng thiếu bảng hoặc đăng nhập lỗi | Xác nhận đúng `QuanLyKinhMatWeb`, đúng schema và mật khẩu hiện tại; script không tự sửa/ghi đè database cũ. |
| Doanh thu gần nhất bằng 0 | Dữ liệu mẫu có ngày giao dịch cũ; thử lập hóa đơn mới hợp lệ để xem số liệu hiện tại. |

Log của phiên chạy nhanh nằm tại `WebQuanLyKinhMat/App_Data/server.log` và `server-error.log`. Chi tiết kỹ thuật và kiểm thử xem trong [README](README.md).

## 6. Đưa lên GitHub

Thư mục hiện tại đã có Git và nhánh `main`. Tạo repository trống trên GitHub; mở PowerShell tại **thư mục ngoài cùng chứa `.slnx`** rồi chạy:

```powershell
git remote add origin https://github.com/TEN_TAI_KHOAN/WebQuanLyKinhMat.git
git push -u origin main
```

Thay `TEN_TAI_KHOAN` bằng tài khoản của bạn. Nếu đã có `origin`, kiểm tra `git remote -v` và dùng `git remote set-url origin <URL_repo_cua_ban>` khi cần đổi. Với thay đổi mới, chạy `git add .`, `git commit -m "Cap nhat du an"` rồi `git push`.

Kiểm tra trên GitHub có đủ thư mục project, `.slnx`, SQL và hai file Markdown rồi gửi link nộp bài. `.gitignore` đã loại `bin`, `obj`, `runtime`, `.vs`, log và cấu hình riêng.
