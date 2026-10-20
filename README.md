# WebQuanLyKinhMat

**Bài tập lớn môn Lập trình web — Website quản lý cửa hàng kính mắt.**

Ứng dụng dùng ASP.NET Core MVC (.NET 10), C#, Razor, JavaScript và SQL Server; truy cập dữ liệu bằng ADO.NET/`Microsoft.Data.SqlClient`. Hệ thống dành cho quản lý và nhân viên, hỗ trợ bán hàng, nhập hàng, quản lý tồn kho và báo cáo doanh thu.

## 1. Tài khoản đăng nhập

| Tên đăng nhập | Mật khẩu khởi tạo | Quyền |
|---|---|---|
| `1` | `hieucoi12345` | Quản lý (`Admin`) |
| `2` | `hieucoi12345` | Nhân viên (`Staff`) |
| `3` | `hieucoi12345` | Nhân viên (`Staff`) |

Tên đăng nhập ban đầu trùng mã nhân viên. Tài khoản `2` và `3` cùng quyền `Staff`. Đây là tài khoản **web**; kết nối SQL Server dùng Windows Authentication. Mật khẩu lưu dạng băm trong `WebUsers`; nếu đã đổi thì dùng mật khẩu mới.

## 2. Khởi chạy dự án

1. Chuẩn bị **.NET 10 SDK**, **SQL Server** và **SSMS**.
2. Trong SSMS, mở **`QuanLyKinhMat.sql`** ở thư mục ngoài cùng và nhấn **F5** để tạo database/dữ liệu mẫu. Bỏ qua bước này nếu đã có database **`QuanLyKinhMatWeb`**.
3. Sửa `Server` trong `WebQuanLyKinhMat/appsettings.json` theo máy chủ SQL của bạn; giữ tên database và Windows Authentication.
4. Mở **`WebQuanLyKinhMat.slnx`** bằng Visual Studio, nhấn **F5** hoặc **Ctrl + F5**. Hoặc mở terminal tại thư mục ngoài cùng, chạy:

```powershell
cd WebQuanLyKinhMat
dotnet run
```

Truy cập [http://127.0.0.1:5080](http://127.0.0.1:5080). Xem [hướng dẫn cài đặt](CAI_DAT_VA_SU_DUNG.md) để biết cấu hình kết nối và tài khoản.

## 3. Chức năng đã thực hiện

| Chức năng | Quản lý | Nhân viên |
|---|---|---|
| Tổng quan, báo cáo doanh thu 7/30 ngày, sản phẩm bán chạy, xuất CSV | Có | Có |
| Sản phẩm và danh mục: loại, thương hiệu, chất liệu, màu sắc, hình dáng | Thêm, sửa, xóa, tra cứu | Tra cứu |
| Khách hàng | Thêm, sửa, xóa, tra cứu | Thêm, sửa, xóa, tra cứu |
| Nhà cung cấp | Quản lý | Không có màn hình quản lý |
| Hóa đơn bán | Lập, xem, hủy | Lập, xem |
| Phiếu nhập | Lập, xem, hủy | Không |
| Tài khoản nhân viên | Tạo, sửa quyền/trạng thái, đặt mật khẩu | Không |
| Đổi mật khẩu cá nhân, đăng xuất | Có | Có |

Quyền được kiểm tra trên máy chủ. Nhân viên vẫn có thể đọc danh sách nhà cung cấp qua API. Tìm kiếm hỗ trợ tiếng Việt không dấu, kết hợp bộ lọc và phân trang.

**Quy tắc nghiệp vụ:** nhập tăng tồn, bán giảm tồn; máy chủ kiểm tra lại giá/tồn trước khi lưu và dùng transaction để tránh ghi dở dang. Gửi lại cùng mã xác nhận với cùng nội dung chỉ tạo một chứng từ. Hủy chứng từ giữ lịch sử và hoàn tác tồn đúng một lần; hủy nhập bị từ chối khi không đủ tồn để trừ lại.

Phiếu nhập cập nhật giá nhập theo đơn giá và giá bán bằng **110% đơn giá nhập**. Sản phẩm đã có chứng từ không được sửa tồn trực tiếp. Doanh thu tính hóa đơn bán hoàn tất sau giảm giá; dữ liệu mẫu có ngày giao dịch cũ nên thống kê kỳ gần nhất có thể bằng 0.

## 4. Bảng kiểm thử tiêu biểu

Các ca dưới đây tóm tắt kết quả đã ghi nhận ngày **19/10/2026**, bằng Microsoft Edge và SQL Server local. Các sản phẩm/khách hàng QA là dữ liệu tạo riêng cho kiểm thử và đã được dọn sau khi chạy.

| ID | Chức năng kiểm thử | Dữ liệu đầu vào / thao tác | Kết quả kỳ vọng | Kết quả thực tế | Trạng thái |
|---|---|---|---|---|:---:|
| TC01 | Đăng nhập quản lý | Tài khoản `1`, mật khẩu khởi tạo | Vào ứng dụng, có quyền quản lý | Đúng mã nhân viên và vai trò `Admin`; truy cập được quản lý tài khoản | PASS |
| TC02 | Đăng nhập sai | Mã nhân viên hợp lệ, mật khẩu sai | Từ chối, không tạo phiên đăng nhập | Hiện thông báo lỗi; API cần đăng nhập vẫn trả 401 | PASS |
| TC03 | Phân quyền nhân viên | Staff gọi API tạo/sửa tài khoản quản lý | Bị từ chối; không thay đổi tài khoản | Trả 403; danh sách tài khoản giữ nguyên | PASS |
| TC04 | Thêm và sửa sản phẩm | Nhập sản phẩm QA hợp lệ, sửa tên/giá rồi đọc lại | Lưu vào SQL, hiển thị đúng dữ liệu mới | Form thêm/sửa thành công; dữ liệu đọc lại khớp | PASS |
| TC05 | Kiểm tra dữ liệu không hợp lệ | Tên sản phẩm rỗng, giá âm hoặc tồn âm | Báo lỗi, không thêm sản phẩm | API trả 400; số bản ghi không tăng | PASS |
| TC06 | Tìm kiếm, lọc và phân trang | Bộ 12 sản phẩm QA có dấu/Đ; tìm không dấu, đổi bộ lọc và trang | Tìm đúng, phân trang và bộ lọc nhất quán | Hai trang 8 + 4 sản phẩm; lọc đúng, tìm mới về trang 1 | PASS |
| TC07 | Bán hàng và giảm giá | Bán 2 chiếc × 110.000đ, giảm 10%, tồn ban đầu 20 | Tổng 198.000đ; tồn còn 18 | Lưu đúng tổng 198.000đ; tồn từ 20 xuống 18 | PASS |
| TC08 | Nhập nhiều sản phẩm | Nhập hai dòng QA, số lượng 2 và 3, có giá lẻ/giảm giá | Đúng tổng, nhà cung cấp, người lập và tồn từng dòng | Tổng 906.444,79đ; tồn 20→22 và 30→33; thông tin khớp | PASS |
| TC09 | Bán vượt tồn | Số lượng bán lớn hơn tồn hiện tại | Từ chối toàn giao dịch; không đổi tồn | Trả 409; không tạo hóa đơn dở dang | PASS |
| TC10 | Hủy chứng từ | Hủy hóa đơn bán; thử hủy lại cùng chứng từ | Hoàn tồn một lần, giữ lịch sử đã hủy | Tồn khôi phục; lần hủy lặp không cộng thêm tồn | PASS |
| TC11 | Chống lưu trùng | Gửi đồng thời hai yêu cầu cùng mã xác nhận và nội dung | Chỉ lưu một hóa đơn, trừ tồn một lần | Hai phản hồi cùng mã hóa đơn; tồn chỉ giảm một lần | PASS |
| TC12 | Báo cáo theo mã sản phẩm | Hai mã cùng tên; một mã đổi tên qua thời gian | Khác mã tách nhóm, cùng mã giữ một nhóm | Hàm báo cáo trả đúng 2 nhóm và 1 nhóm tương ứng | PASS |
| TC13 | Xuất CSV tiếng Việt | Tên chứa dấu, dấu phẩy/nháy và số tiền `123456.78` | Giữ đúng nội dung và số tiền | CSV có BOM UTF-8; giữ Unicode, ký tự và số lẻ | PASS |
| TC14 | Giao diện trên nhiều kích thước | 10 màn hình tại 320, 390, 768 và 1440px | Không tràn chiều rộng trang; bảng cuộn trong khung | 40/40 tổ hợp bố cục đạt | PASS |

**Kết quả kiểm thử:** 186/186 kiểm tra chức năng/hồi quy và 40/40 bố cục, tổng hợp từ các lượt chạy của từng bộ. Lượt xác nhận cuối của bộ nghiệp vụ đạt 55/55; bộ kiểm tra ba tài khoản nhân viên đạt 26/26 và được lưu riêng. Solution biên dịch thành công với 0 lỗi, 0 cảnh báo.

Bằng chứng: [test-results.json](WebQuanLyKinhMat/docs/test-results.json), [employee-login-check.json](WebQuanLyKinhMat/docs/employee-login-check.json), [submission-check.json](WebQuanLyKinhMat/docs/submission-check.json), [github-ready.json](WebQuanLyKinhMat/docs/github-ready.json). Xem [toàn bộ ca kiểm thử](WebQuanLyKinhMat/docs/test-cases.md) và [thuyết minh kết quả](WebQuanLyKinhMat/docs/verification.md) khi cần đối chiếu.

## 5. Cấu trúc và tài liệu

```text
WebQuanLyKinhMat/
├── WebQuanLyKinhMat/         # Project MVC: Controllers, Models, Views, wwwroot...
├── .gitignore
├── CAI_DAT_VA_SU_DUNG.md
├── QuanLyKinhMat.sql
├── WebQuanLyKinhMat.slnx
└── README.md
```

File SQL chạy trực tiếp trong SSMS để khởi tạo database **`QuanLyKinhMatWeb`**. Bộ dữ liệu có 22 bảng; máy cài mới không cần database WinForms gốc. Giỏ chưa lưu chỉ giữ trong trang đang mở, tải lại trang sẽ mất giỏ. Ứng dụng đã kiểm tra trong môi trường local; phạm vi kiểm thử được ghi trong tài liệu kết quả.

- [Cài đặt và sử dụng](CAI_DAT_VA_SU_DUNG.md).
- [Báo cáo kỹ thuật](WebQuanLyKinhMat/docs/report.md).
- [Kiến trúc ứng dụng](WebQuanLyKinhMat/docs/architecture.md) · [Thiết kế database](WebQuanLyKinhMat/docs/database.md).
- [Thiết kế giao diện](WebQuanLyKinhMat/docs/wireframes.md).
