# Kết quả kiểm thử thực tế

Ngày thực hiện: 19/10/2026. Môi trường: Windows, .NET SDK 10.0.401, ASP.NET Core 10.0.12, Microsoft Edge, SQL Server `HIEUCOI\SQLEXPRESS`, database riêng `QuanLyKinhMatWeb`.

## Bổ sung đăng nhập theo mã nhân viên SQL cũ

Đã chuyển ba tài khoản mã `1`/`2`/`3` từ `NhanVien` gốc sang `WebUsers`; mã `1` là Admin, mã `2`/`3` là Staff. `scripts/verify-employee-logins.cjs` đạt **26/26** kiểm tra ở lượt mới: mật khẩu cũ đăng nhập được, đúng EmployeeId/quyền, Staff bị từ chối quản trị, DTO không trả hash, đăng xuất hết quyền, mật khẩu sai bị từ chối. Đầu ra: [employee-login-check.json](employee-login-check.json). Mật khẩu kiểm thử được truyền qua biến môi trường tạm, không lưu trong kết quả. Bốn kiểm tra bổ sung xác nhận UI chỉ có ba dòng, không có demo và hai tên demo không còn đăng nhập được.

Chạy import lần đầu thêm 3, chạy lại thêm 0. Đối chiếu schema/số dòng/SHA256 cả 22 bảng nguồn trước/sau import giữ nguyên; xem [employee-account-migration.json](employee-account-migration.json). Web hiện chỉ có 3 tài khoản mã nhân viên. Hai demo và hai nhân viên demo không có chứng từ đã được xóa; bootstrap bị gỡ khỏi mã. Bộ nghiệp vụ `verify-app.cjs` đã chạy lại bằng mã 1 đạt 55/55 (QA1792428679860.json), dữ liệu QA đã dọn. Các bộ còn lại trong tổng 186 và 40 bố cục giữ bằng chứng lượt trước; 26 kiểm tra tài khoản mới ghi riêng. Không giả định đã chạy lại mọi bộ cũ. Xem [submission-check.json](submission-check.json).

## SQL và bộ nộp độc lập

SQL khởi tạo chứa schema/dữ liệu và 3 PasswordHash. Lượt trước đã kiểm tra cú pháp 175 batch bằng PARSEONLY. Solution và file SQL được đặt ngoài thư mục project MVC.

## Xác nhận quy trình khởi chạy ngày 20/10/2026

Đã bỏ công cụ khởi chạy cũ. File SQL hiện chạy trực tiếp trong SSMS; ứng dụng khởi chạy bằng Visual Studio hoặc `dotnet run`.

- Chạy 179 batch trên một kết nối SQL tới database tạm: tạo đủ 22 bảng, 8 sản phẩm có đường dẫn ảnh và 3 tài khoản web; transaction commit và dấu session được xóa.
- Chạy lại toàn bộ SQL, kể cả tiếp tục sau lỗi như SSMS: bị từ chối với mã 51001; số dòng và checksum của cả 22 bảng giữ nguyên.
- Chèn lỗi thực thi thử trước commit: schema và seed rollback, transaction đóng. Hai database tạm đã được dọn; database web đang dùng giữ nguyên.
- Release build: 0 lỗi, 0 cảnh báo. Chạy đúng lệnh `dotnet run` với launch profile của project tại cổng 5080: health ready, đăng nhập quản lý thành công, API trả đủ 8 sản phẩm và cả 8 ảnh trả HTTP 200. Đã dừng phiên thử bằng Ctrl + C.

Bằng chứng: [startup-check.json](startup-check.json). Không cộng các kiểm tra này vào tổng 186 của các lượt trước. Đường chạy Visual Studio được cấu hình trong `Properties/launchSettings.json`; lượt xác nhận mới dùng .NET CLI.

## Phiên đăng nhập sau khi khởi động lại ngày 20/10/2026

Kiểm tra riêng đạt **20/20** bằng HTTP qua hai tiến trình ứng dụng thật, dùng cùng thư mục nội dung và cùng khóa Data Protection:

- Không chọn giữ đăng nhập: vẫn dùng được trong lần chạy hiện tại; sau khi dừng/chạy lại, API trả 401 và trang chính chuyển về đăng nhập.
- Có chọn giữ đăng nhập: tiếp tục dùng được sau khi chạy lại; nhân viên vẫn nhận 403 khi gọi API quản lý tài khoản.
- Đăng nhập lại, tải lại trang trong cùng lần chạy và đăng xuất với CSRF hợp lệ đều hoạt động đúng. Sau đăng xuất, API trả 401.

Release build đạt 0 lỗi, 0 cảnh báo. Các kiểm tra chỉ đăng nhập, đọc dữ liệu và đăng xuất; không ghi dữ liệu nghiệp vụ. Xem [login-restart-check.json](login-restart-check.json). Kết quả này được ghi riêng, không cộng vào tổng 186 của các lượt trước.

## Biên dịch và kết nối

- Release build thành công: 0 lỗi, 0 cảnh báo.
- Kết nối bằng Windows Authentication; endpoint `/health` trả `ready`.
- Bộ khởi tạo đã tạo database riêng từ SQL portable; không chạy các lệnh ghi lên `QuanLyKinhMat`.
- Có 22 bảng trong bản web, gồm 21 bảng nguồn và WebUsers.
- Chạy lại khởi tạo trên DB đã có: bị từ chối đúng trước khi ghi; tài khoản TaiKhoan cũ còn hoạt động/mật khẩu cũ: 0.
- Đăng xuất trả 200; gọi API sau đăng xuất trả 401 và mở trang ứng dụng chuyển tới đăng nhập.
- Ở lượt kiểm thử trước, bản publish đã chạy thành công tại cổng 5080; kiểm tra đăng nhập, thông báo validation tiếng Việt và đăng xuất đều đạt. Bản nộp hiện dùng Visual Studio hoặc `dotnet run`.
- Ở lượt kiểm thử trước, gói ZIP đã giải nén sang thư mục khác có khoảng trắng và chạy tại cổng 5081: health ready, trang đăng nhập trả 200 và có token CSRF. Không phụ thuộc thư mục build ban đầu. Các tiến trình kiểm thử đã được dừng sau khi hoàn tất.
- Đã đọc fingerprint trước/sau một vòng nhập hai dòng, hủy và dọn QA: schema, số dòng và SHA256 của cả 22 bảng hiện có trong `QuanLyKinhMat` giống nhau. Dùng `scripts/Verify-OriginalDatabase.ps1`; snapshot được tạo ở vòng kiểm thử bổ sung, không phải trước lần khởi tạo đầu tiên. Xem [original-database-check.json](original-database-check.json).

## Các bộ kiểm thử tự động

| Bộ kiểm thử | Số kiểm tra đạt | Kết quả |
|---|---:|---|
| `scripts/verify-app.cjs` | 55 / 55 | Đạt toàn bộ lượt cuối |
| `scripts/verify-forms.cjs` | 29 / 29 | Đạt toàn bộ lượt cuối |
| Kiểm tra riêng hàm hiển thị báo cáo | 2 / 2 | Hai mã cùng tên tách riêng; một mã đổi tên vẫn một nhóm |
| `scripts/verify-inventory-extended.cjs` | 28 / 28 | Form nhập nhiều dòng, số tiền lẻ, hủy và validation |
| `scripts/verify-auth-extended.cjs` | 45 / 45 | Đăng nhập, đổi mật khẩu hai phiên, quyền và đủ method/token CSRF |
| `scripts/verify-ui-extended.cjs` | 27 / 27 | Phân trang/lọc, bàn phím, CSV, chuỗi HTML/SQL và request lỗi |
| **Tổng** | **186 / 186** | Không cộng các lượt chạy lặp |

Đầu ra từng kiểm tra được tổng hợp trong [test-results.json](test-results.json), không kèm mật khẩu, cookie hoặc dữ liệu cá nhân từ database nguồn. [preview-check.json](preview-check.json) ghi đủ 40 tổ hợp của 10 màn hình tại 320/390/768/1440px, đều không tràn chiều rộng trang.

Đã kiểm tra trực tiếp trên ứng dụng chạy với SQL Server, không dùng localStorage hoặc repository giả:

- Đăng nhập Admin/Staff, danh tính riêng từng phiên, nhân viên không thể gọi API quản trị hoặc hủy chứng từ.
- Từ chối request thay đổi dữ liệu thiếu token CSRF; API tài khoản không trả mật khẩu/hash.
- Bảo vệ Admin hoạt động cuối cùng; đổi mật khẩu kiểm tra mật khẩu hiện tại; khóa tài khoản làm cookie cũ mất quyền.
- CRUD sản phẩm, khách hàng, nhà cung cấp, loại kính/thương hiệu qua API và form thật; kiểm tra giới hạn tên/điện thoại và bảo vệ dữ liệu đang được tham chiếu.
- Nhập làm tăng tồn và cập nhật giá; giảm giá được tính vào tổng tiền. Bán quá tồn và giá cũ bị từ chối, không ghi giao dịch dở dang.
- Gửi cùng token lặp lại, kể cả đồng thời, chỉ tạo một chứng từ và trừ tồn một lần; cùng token nhưng nội dung khác bị từ chối.
- Hai người tranh mua đơn vị cuối: chỉ một giao dịch thành công, giao dịch còn lại trả 409, tồn không âm.
- Giao dịch nhiều dòng có một sản phẩm thiếu tồn bị từ chối nguyên giao dịch.
- Hủy bán hoàn tồn đúng một lần; hủy nhập khôi phục tồn/giá. Không cho hủy phiếu nhập khi hàng đã bán hết.
- Giỏ hàng phát hiện giá thay đổi, cập nhật giá và yêu cầu người dùng xác nhận lại; không còn tình trạng xác nhận giá cũ nhưng lưu giá mới.
- Tạo, xem chi tiết và hủy hóa đơn trực tiếp qua form UI; tổng 2 × 110.000 × 90% = 198.000đ, tồn giảm 2 rồi được hoàn.
- Mở đủ 10 màn hình quản lý; liên kết bỏ qua điều hướng giữ đúng trang; không có JavaScript page error trong các luồng đã chạy.
- Sai mật khẩu, tên không tồn tại và tài khoản bị khóa có cùng thông báo, không tạo phiên; Staff tự gửi Role=Admin hoặc sửa người khác đều bị từ chối 403.
- Đổi mật khẩu hợp lệ thu hồi cookie ở context sao chép trước khi đổi; mật khẩu cũ không đăng nhập được, mật khẩu mới thành công. Ba đầu vào đổi mật khẩu không hợp lệ bị từ chối 400.
- Thiếu/sai CSRF trên cả POST/PUT/DELETE đều trả 400; so sánh dữ liệu trước/sau không đổi.
- Nhập hai dòng qua form: tổng 906.444,79đ; tồn 20→22 và 30→33, đúng nhân viên/NCC; hủy qua form khôi phục cả hai dòng và giá cũ. Hủy lần nữa không tác động tiếp.
- Tìm 12 sản phẩm Unicode bằng từ không dấu/Đ, phân trang 8+4, kết hợp loại/tồn/trạng thái và trạng thái rỗng; đổi tìm kiếm đưa về trang 1.
- Tên chứa HTML/onerror, dấu nháy và chuỗi SQL được lưu, tìm và hiển thị như văn bản; không chạy mã nhập vào.
- Enter mở/lưu form khách hàng; Escape trả focus nút mở; skip link chuyển focus đến nội dung và giữ đúng màn hình.
- Giả lập ngắt POST lưu bán: cảnh báo được focus, giỏ/khách/tổng không mất, số hóa đơn và tồn SQL không đổi; bỏ mô phỏng lỗi mở lại xác nhận được.
- CSV sản phẩm giữ BOM UTF-8, tiếng Việt, dấu nháy/phẩy và 123456.78; ngày trong tên tệp lấy theo local.

Các luồng nghiệp vụ ở trên dùng SQL Server thật. Riêng kiểm tra CSV hóa đơn dùng một phản hồi GET giả lập trong trình duyệt với ngày `2026-02-03` và tiền `123456.78` để kiểm soát đầu vào; không tạo hóa đơn SQL cho ca này. Ca lỗi mạng ngắt request tại trình duyệt, không tắt SQL Server của người dùng.

Các fixture đều có mã QA và token được ghi nhận. Sau kiểm thử, script chỉ dọn đúng các bản ghi thử đã hủy, theo ID/token; không xóa database, không đụng dữ liệu nguồn.

## Chạy lại kiểm thử

Các script QA cần Node.js, Microsoft Edge và Playwright 1.62.1. Chúng ưu tiên dependency trong `scripts/node_modules`; trên máy phát triển cũng nhận runtime sẵn có. Chạy ứng dụng bằng Visual Studio hoặc `dotnet run` không cần Node hoặc Playwright.

```powershell
npm install --prefix scripts
$env:KINHMAT_TEST_URL = 'http://127.0.0.1:5080'
$env:KINHMAT_TEST_USER = '1'
$env:KINHMAT_TEST_PASSWORD = '<mật khẩu quản lý hiện tại>'
node scripts/verify-app.cjs
```

Mở web bằng Visual Studio hoặc `dotnet run` trước khi chạy kiểm thử. Mỗi script in đường dẫn JSON kết quả; dọn ngay lượt vừa chạy bằng `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Cleanup-TestData.ps1 -ResultsFile <đường dẫn JSON>`. Chạy các bộ nối tiếp để tránh fixture làm thay đổi số bản ghi của nhau. Trước bộ `verify-auth-extended.cjs`, để cách các lần đăng nhập trước ít nhất một phút vì máy chủ giới hạn 12 lần đăng nhập/phút. Các script dùng mã quản lý từ KINHMAT_TEST_USER (mặc định 1), bắt buộc truyền KINHMAT_TEST_PASSWORD; không lưu mật khẩu thật trong mã QA.

Đối chiếu database gốc: chạy `Verify-OriginalDatabase.ps1 -Mode Baseline` trước lượt kiểm thử và `-Mode Compare` sau lượt đó. Dùng `-SnapshotFile` mới cho mỗi baseline; script không ghi đè bằng chứng cũ và chỉ đọc SQL. Công cụ này dành cho máy hiện có `QuanLyKinhMat`; không cần cho thao tác sử dụng web thường ngày.

## Lỗi phát hiện và đã xử lý

| Lỗi | Thay đổi | Kết quả kiểm tra lại |
|---|---|---|
| Trang rộng hơn màn hình điện thoại | Đặt `.table-wrap` làm vùng định vị tương đối để nhãn screen-reader không định vị theo BODY. Bảng vẫn cuộn trong khung. | 40/40 tổ hợp của 10 màn hình tại 320, 390, 768, 1440px đạt; bộ kiểm thử chính cũng qua 5 màn hình tại 390px. |
| Giỏ xác nhận giá cũ | Tải lại giá/tồn trước xác nhận; nếu giá đổi, cập nhật giỏ và yêu cầu xác nhận lại. Server tiếp tục từ chối giá sai. | API giá cũ trả 409; form xác nhận hiển thị 115.000đ sau khi giá thay đổi. |
| Báo cáo gộp theo tên | Xếp hạng theo mã sản phẩm; tên chỉ dùng để hiển thị. | Đã đối chiếu mã tổng hợp; không còn dùng tên làm khóa. |
| Điện thoại không có chữ số | Validation annotation và kiểm tra server theo giới hạn SQL. | `--------` trả 400. |
| Race đổi mật khẩu | UPDATE kiểm tra SecurityStamp/trạng thái và dùng stamp vừa tạo trước khi phát cookie. | Build và luồng đổi mật khẩu/khóa phiên đạt; nhánh race được rà soát mã độc lập. |

## Tình trạng database sau khi dọn QA

Số liệu đọc trực tiếp được lưu tại [database-final-check.json](database-final-check.json). Chứng từ nguồn chưa có `ThanhTienChot` được đối chiếu bằng công thức tiền dòng của repository.

| Chỉ số | Giá trị |
|---|---:|
| Sản phẩm | 8 |
| Khách hàng | 5 |
| Nhà cung cấp | 3 |
| Hóa đơn bán / phiếu nhập | 5 / 3 |
| Tài khoản web theo mã nhân viên | 3 |
| Sản phẩm tồn âm | 0 |
| Mật khẩu cũ còn trong NhanVien bản web | 0 |
| PasswordHash rỗng hoặc quá ngắn | 0 |
| Tổng hóa đơn bán lệch chi tiết | 0 |

Các giao dịch mẫu trong dump có ngày lịch sử, vì vậy doanh thu hôm nay có thể bằng 0; ứng dụng không tự sửa ngày chứng từ để tạo số liệu mới.

## Giới hạn của kết quả

Tổng cộng 186 kiểm tra tự động/hồi quy đạt trong các lượt thành công cuối, ngoài 40 tổ hợp bố cục. Kết quả chứng minh những luồng đã liệt kê trong môi trường local. Chưa chạy thử tải lớn, triển khai nhiều máy/HTTPS công khai hoặc mô phỏng mất điện giữa giao dịch; không suy rộng kết quả sang các môi trường đó.
