# Kế hoạch kiểm thử và ghi nhận kết quả

## Môi trường và cách ghi nhận

- Ứng dụng chạy trên localhost, kết nối riêng `QuanLyKinhMatWeb`.
- Dùng Admin và Staff ở hai cửa sổ/profile trình duyệt riêng để tránh dùng chung cookie.
- Dữ liệu tự động có tiền tố `QA` kèm timestamp; ghi lại ID/token để dọn đúng bản ghi sau kiểm thử. Không ghi vào database gốc `QuanLyKinhMat`.
- Với bài kiểm tra API, lấy token CSRF hợp lệ từ phiên đăng nhập cho request thay đổi dữ liệu, trừ test cố ý bỏ/sửa token.
- Chưa chạy thì ghi **Chưa chạy**. Khi chạy, bổ sung ngày, trình duyệt, dữ liệu thật, HTTP status, đầu ra thực tế và pass/fail. Lỗi phải có mô tả cách sửa và lần kiểm tra lại.

Danh sách dưới đây ghi kết quả chạy ngày 19/10/2026 bằng Microsoft Edge và SQL Server local. Tổng cộng 186 kiểm tra tự động/hồi quy đạt; xem [verification.md](verification.md) và [đầu ra từng kiểm tra](test-results.json). Kiểm tra lỗi mạng dùng request bị ngắt trong trình duyệt; kiểm tra CSV hóa đơn dùng một phản hồi GET giả lập, được ghi rõ trong bằng chứng.

## Danh mục test case

| ID | Mục tiêu / đầu vào và thao tác | Kết quả dự kiến | Đầu ra thực tế | Kết quả |
|---|---|---|---|---|
| DB01 | Khởi tạo khi chưa có `QuanLyKinhMatWeb`, server và quyền Windows hợp lệ. | Tạo DB riêng; 21 bảng gốc + WebUsers, view/ràng buộc/index đầy đủ; dữ liệu nghiệp vụ được import. | Database riêng đã tạo, 22 bảng; app kết nối thành công. | Đạt |
| DB02 | Chạy khởi tạo lần nữa khi DB web đã tồn tại. | Dừng với thông báo DB tồn tại; không ghi đè dữ liệu và không tạo lại bảng. | Lượt trước: công cụ khởi tạo từ chối database đã có. Quy trình SQL trực tiếp được xác nhận riêng ngày 20/10/2026 trong startup-check.json. | Đạt |
| DB03 | Kiểm tra `NhanVien.Passw`, `TaiKhoan.MatKhau/TrangThai` sau import. | Passw đều NULL; mật khẩu tài khoản cũ rỗng, tài khoản cũ không hoạt động. | Passw còn giá trị: 0; tài khoản cũ đang hoạt động/còn mật khẩu: 0. | Đạt |
| DB04 | Khởi động lại sau khi xóa tài khoản demo. | Giữ 3 tài khoản mã nhân viên; không tạo lại demo hoặc reset mật khẩu. | Đã bỏ bootstrap; chỉ còn tài khoản 1/2/3, đăng nhập và quyền đúng ở bộ kiểm tra tài khoản mới. | Đạt |
| DB05 | Chụp số dòng/SHA256 và cấu trúc DB gốc; chạy nhập/hủy và dọn QA ở web; đối chiếu lại. | `QuanLyKinhMat` không đổi trong vòng kiểm thử; ứng dụng chỉ ghi vào bản web riêng. | Cấu trúc, số dòng và SHA256 của toàn bộ 22 bảng trong DB gốc giống baseline trước/sau vòng nhập/hủy và cleanup. | Đạt |
| AU01 | Đăng nhập đúng tài khoản Admin và Staff. | Đến trang ứng dụng; danh tính, vai trò và người lập chứng từ đúng từng phiên. | Admin và Staff ở context khác nhau; EmployeeId chứng từ khớp từng phiên. | Đạt |
| AU02 | Sai mật khẩu, tên không tồn tại, tài khoản bị khóa. | Từ chối đăng nhập với thông báo chung; không lộ lý do chi tiết/hash. | Cả ba bị từ chối với cùng thông báo; API 401. Khóa tài khoản cũng thu hồi phiên đang mở. | Đạt |
| AU03 | Chưa đăng nhập, mở trang ứng dụng và gọi API. | Trang yêu cầu đăng nhập; API từ chối truy cập, không trả dữ liệu nghiệp vụ. | Trang gốc chuyển 302 tới đăng nhập; API trả 401. | Đạt |
| AU04 | Đăng xuất rồi gọi lại endpoint cần đăng nhập. | Phiên/cookie không còn quyền truy cập. | API sau logout trả 401; trang gốc yêu cầu đăng nhập. Phiên độc lập còn hiệu lực. | Đạt |
| AU05 | Staff gọi trực tiếp API tạo/sửa user, tự gửi Role=Admin. | Bị từ chối phía server; không tạo/sửa tài khoản, không tăng quyền. | Tạo Admin, tự nâng quyền và sửa người khác đều 403; danh sách tài khoản giữ nguyên. | Đạt |
| AU06 | Đổi mật khẩu: mật khẩu hiện tại sai; xác nhận khác; mật khẩu ngắn. | Từ chối và thông báo phù hợp; mật khẩu hiện tại không thay đổi. | Ba đầu vào đều 400; phiên hiện tại vẫn truy cập được. | Đạt |
| AU07 | Đổi mật khẩu hợp lệ rồi thử đăng nhập bằng mật khẩu cũ/mới. | Cũ bị từ chối, mới thành công; kiểm tra hiệu lực cookie ở phiên khác theo SecurityStamp. | Mật khẩu cũ bị từ chối, mới thành công; cookie sao chép trước khi đổi trả 401; phiên đổi mật khẩu vẫn 200. | Đạt |
| AU08 | Admin khóa/hạ quyền Admin hoạt động cuối cùng. | Máy chủ từ chối để giữ ít nhất một quản trị viên hoạt động. | Hạ Admin cuối cùng trả HTTP 409. | Đạt |
| SC01 | POST/PUT/DELETE có cookie nhưng thiếu hoặc sai CSRF token. | Máy chủ từ chối; DB không đổi. | Sáu tổ hợp method/token đều 400; dữ liệu khách hàng trước/sau giống nhau. | Đạt |
| SC02 | Tên/chuỗi tìm kiếm có dấu nháy và chuỗi giống SQL; tên chứa HTML/script. | SQL xem là dữ liệu; giao diện hiển thị nội dung an toàn, không chạy script nhập vào. | Tên có HTML/onerror, dấu nháy và SELECT được lưu/hiển thị nguyên văn; không tạo thẻ ảnh hoặc chạy script. | Đạt |
| PR01 | Admin thêm sản phẩm TEST-, sửa tên/giá/danh mục, tải lại trang. | Dữ liệu lưu SQL và hiển thị đúng sau khi tải lại. | Form tạo/sửa, API đọc lại tên/giá/danh mục và dữ liệu SQL khớp. | Đạt |
| PR02 | Tên rỗng/quá 150 ký tự; giá âm; tồn âm; ID danh mục không tồn tại. | Validation từ chối; không thêm/sửa nửa chừng. | Tám đầu vào lỗi, gồm khoảng trắng, tồn lẻ và tiền quá hai chữ số thập phân, đều bị từ chối; số sản phẩm không tăng. | Đạt |
| PR03 | Xóa sản phẩm chưa có chứng từ; xóa sản phẩm đã có chứng từ. | Bản chưa tham chiếu được xóa theo quyền; bản có chứng từ được bảo vệ/đề nghị ngừng bán theo quy tắc, không mất lịch sử. | Form xóa sản phẩm chưa dùng thành công; API xóa bản đã dùng trả 409. | Đạt |
| PR04 | Tìm tên có dấu/không dấu, lọc loại/trạng thái rồi chuyển trang. | Kết quả, số trang và bộ lọc nhất quán; đổi bộ lọc không kẹt ở trang rỗng không hợp lệ. | 12 sản phẩm QA có dấu/Đ tìm bằng chữ không dấu; hai trang 8+4, lọc loại/tồn/trạng thái đúng; tìm mới về trang 1, trạng thái rỗng đúng. | Đạt |
| CU01 | Thêm/sửa khách, email hợp lệ, ghi chú Unicode; sau đó tải lại. | Dữ liệu tồn tại trong SQL; tên ≤100, điện thoại ≤15, email ≤100, ghi chú ≤500 ký tự. | Form thêm/sửa khách có ghi chú Unicode; đọc lại API khớp. | Đạt |
| CU02 | Điện thoại `--------`, email sai, tên chỉ khoảng trắng. | Từ chối ở form/API, không lưu dữ liệu không hợp lệ. | Cả ba API trả 400; điện thoại lỗi có thông báo tiếng Việt. | Đạt |
| CA01 | Admin thêm/sửa/xóa danh mục chưa dùng và nhà cung cấp; dùng bản ghi đã tham chiếu để thử xóa. | CRUD hoạt động theo quyền; khóa ngoại/nghiệp vụ bảo vệ dữ liệu đã dùng. | Form loại kính/thương hiệu/NCC thêm sửa xóa đạt; danh mục đã dùng được bảo vệ 409. | Đạt |
| IN01 | Qua form nhập hai sản phẩm QA với số lượng 2 và 3, giá lẻ và giảm giá. | Lưu phiếu và dòng, đúng người lập/NCC, tăng tồn từng dòng; tổng tiền làm tròn đúng. | Form lưu hai dòng: tổng 906.444,79đ; tồn 20→22 và 30→33, EmployeeId/NCC khớp. | Đạt |
| IN02 | Số lượng 0, âm, 10.001; danh sách rỗng/trùng sản phẩm; NCC không tồn tại. | Từ chối toàn giao dịch, tồn và số phiếu không đổi. | Tám đầu vào lỗi, gồm dòng null và giảm giá >100%, bị từ chối; số phiếu và tồn giữ nguyên. | Đạt |
| SA01 | Bán 2 đơn vị khi còn đủ tồn; kiểm tra đơn giá/giảm giá/tổng tiền. | Tồn giảm 2; tổng tiền SQL, API và giao diện khớp theo quy tắc làm tròn. | Form bán 2 chiếc ×110.000đ, giảm 10%: tổng198.000đ; tồn20 xuống18. | Đạt |
| SA02 | Bán nhiều hơn tồn hoặc sản phẩm ngừng bán. | API từ chối; không tạo hóa đơn/dòng và không đổi tồn. | Bán quá tồn hoặc sản phẩm ngừng bán đều trả 409. | Đạt |
| SA03 | Thêm vào giỏ, đổi giá sản phẩm ở phiên quản trị khác, quay lại xác nhận. | Không âm thầm chốt tổng khác tiền đã xác nhận; báo giá đổi và cho người dùng kiểm tra lại. | Giá110.000 đổi115.000: giỏ cập nhật, buộc xác nhận lại; API giá cũ trả409. | Đạt |
| SA04 | Hai người bán đồng thời đơn vị tồn cuối cùng. | Chỉ giao dịch hợp lệ được lưu; tồn không âm, transaction lỗi không để lại chứng từ dở dang. | Hai request khác token mua đơn vị cuối: một200,một409;tồn0. | Đạt |
| SA05 | Gửi cùng token lưu chứng từ hai lần. | Chỉ một chứng từ; tồn chỉ thay đổi một lần. | Gửi trùng token đồng thời: cùng ID, tồn chỉ trừ một lần. | Đạt |
| IV01 | Admin hủy chứng từ có nhiều dòng; thử hủy lại; thử hủy nhập khi hàng đã bán không đủ tồn. | Lần đầu đảo tồn đúng, lần lặp không đảo tiếp; trường hợp thiếu tồn bị từ chối nguyên giao dịch. | Hủy phiếu nhập hai dòng qua form khôi phục tồn 20/30 và giá cũ; hủy lại không đổi tồn. Ca thiếu tồn đã trả 409 ở bộ chính. | Đạt |
| RE01 | Hai sản phẩm khác mã cùng tên; cùng sản phẩm có tên thay đổi qua thời gian. | Thống kê sản phẩm theo ID, không gộp nhầm hoặc chia lịch sử chỉ vì tên. | Hàm báo cáo thực: 2 ID cùng tên ra2nhóm; đổi tên cùngID ra1nhóm. | Đạt |
| UI01 | Mở các trang ở desktop, 768px và 390px; dùng menu/form/modal/bảng dài. | Nội dung và thao tác truy cập được; bảng có cuộn trong khung khi cần; không kết luận lỗi từ chiều rộng bảng đơn thuần. | 40/40 tổ hợp 10 màn hình tại320/390/768/1440px; không tràn root,0pageerror. | Đạt |
| UI02 | Dùng bàn phím: skip link, mở form bằng Enter, đóng Escape và lưu form. | Focus hợp lý, đóng modal trả focus, skip link không chuyển nhầm trang nghiệp vụ. | Skip giữ route/focus main; Enter mở form và lưu khách; Escape trả focus nút mở. | Đạt |
| UI03 | Làm request lưu hóa đơn bị ngắt trong trình duyệt. | Thông báo lỗi rõ, không báo lưu thành công giả, không làm mất giỏ trước khi biết kết quả. | POST bị abort: cảnh báo được focus, nút lưu hoạt động lại; giỏ/khách/tổng giữ nguyên, SQL không thêm hóa đơn/đổi tồn. | Đạt |
| I1801 | Tên tiếng Việt, số tiền decimal, ngày tháng trên màn hình/CSV. | Unicode đúng; định dạng hiển thị phù hợp; JSON số vẫn đúng kiểu để API xử lý. | CSV có BOM UTF-8, giữ dấu/nháy/phẩy và 123456.78. GET hóa đơn giả lập xác minh ngày 2026-02-03; tên tệp dùng ngày local. | Đạt |

## Biểu mẫu ghi lỗi và kiểm tra lại

```text
Test case:
Ngày / người chạy / môi trường:
Dữ liệu đầu vào thực tế, ID bản ghi:
Các bước tái hiện:
Đầu ra dự kiến:
Đầu ra thực tế (HTTP status / ảnh / dữ liệu đối chiếu):
Pass / Fail:
Nguyên nhân:
Tệp và thay đổi sửa lỗi:
Kết quả chạy lại:
```

Sau mỗi bộ kiểm thử, dùng `scripts/Cleanup-TestData.ps1 -ResultsFile <JSON kết quả>` để dọn bản ghi QA đã theo dõi. Chứng từ phải hủy trước khi dọn; script chỉ xóa theo ID/token/prefix trong `QuanLyKinhMatWeb`. Script khởi tạo không tự xóa database để reset test.
