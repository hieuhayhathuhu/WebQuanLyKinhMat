# Cài đặt và sử dụng WebQuanLyKinhMat

Tài liệu hướng dẫn dựng ứng dụng trên máy Windows, kết nối SQL Server, chạy thử các chức năng và đưa mã nguồn lên GitHub. Xem [README](README.md) để biết phạm vi, cấu trúc và công nghệ của dự án.

**Tra cứu nhanh:** [Môi trường](#1-chuẩn-bị-môi-trường) · [SQL Server](#2-cấu-hình-và-khởi-tạo-sql-server) · [Chạy web](#3-chạy-ứng-dụng) · [Sử dụng](#4-đăng-nhập-và-sử-dụng) · [Xử lý lỗi](#5-kiểm-tra-và-xử-lý-lỗi-thường-gặp) · [GitHub](#6-đưa-source-lên-github-để-nộp)

## 1. Chuẩn bị môi trường

| Thành phần | Yêu cầu |
|---|---|
| .NET | **.NET 10 SDK** để restore, build và chạy mã nguồn `net10.0`. Chỉ có runtime thì chưa đủ cho bản source này. |
| SQL Server | Instance đang hoạt động; tài khoản Windows hiện tại kết nối được và có quyền tạo database khi khởi tạo lần đầu. |
| Công cụ mở source | Visual Studio hỗ trợ `.slnx` và .NET 10, có workload **ASP.NET and web development**; hoặc trình soạn thảo kèm Terminal. |
| Trình duyệt | Microsoft Edge, Google Chrome hoặc trình duyệt hiện đại tương đương. |
| Mạng | Cần cho lần đầu tải các gói NuGet nếu máy chưa có trong cache. |
| Git | Cần khi clone hoặc gửi source lên GitHub; không bắt buộc nếu dùng bản ZIP đã giải nén. |

SQL Server Management Studio (SSMS) là công cụ tùy chọn để kiểm tra kết nối và xem dữ liệu, không thay thế dịch vụ SQL Server. Kiểm tra SDK trong PowerShell:

```powershell
dotnet --list-sdks
```

Danh sách cần có một bản `10.0.x`. Nếu chưa có, cài .NET 10 SDK rồi mở lại Terminal hoặc Visual Studio.

Giải nén hoặc clone **toàn bộ repository**. Không chỉ lấy riêng thư mục project vì script khởi tạo còn cần file SQL ở ngoài cùng. Cấu trúc chính:

```text
WebQuanLyKinhMat/
├── WebQuanLyKinhMat.slnx
├── QuanLyKinhMat.sql
├── README.md
├── CAI_DAT_VA_SU_DUNG.md
├── .gitignore
└── WebQuanLyKinhMat/
    ├── WebQuanLyKinhMat.csproj
    ├── appsettings.json
    ├── CHAY-WEB.cmd
    ├── TAT-WEB.cmd
    ├── scripts/
    ├── Controllers/
    ├── Models/
    ├── Views/
    └── wwwroot/
```

**Các lệnh bên dưới chạy tại thư mục ngoài cùng, nơi có `WebQuanLyKinhMat.slnx`, trừ khi có ghi chú khác.**

Cách mở PowerShell tại đúng vị trí: mở thư mục ngoài cùng bằng File Explorer, nhập `powershell` vào thanh địa chỉ rồi nhấn Enter.

## 2. Cấu hình và khởi tạo SQL Server

| Thuộc tính | Giá trị mặc định |
|---|---|
| Server/instance | `HIEUCOI\SQLEXPRESS` |
| Database | **`QuanLyKinhMatWeb`** |
| Xác thực kết nối SQL | Windows Authentication |
| File schema và dữ liệu mẫu | `QuanLyKinhMat.sql` ở ngoài cùng |

Tên file SQL là `QuanLyKinhMat.sql`, nhưng database đích là **`QuanLyKinhMatWeb`**. Giữ nguyên tên database này vì ứng dụng và script có kiểm tra bảo vệ tên đích. Máy cài mới không cần database WinForms cũ.

Nếu instance trên máy khác với mặc định, tạo file **`WebQuanLyKinhMat/appsettings.Local.json`** bên trong project:

```json
{
  "ConnectionStrings": {
    "Store": "Server=.\\SQLEXPRESS;Database=QuanLyKinhMatWeb;Integrated Security=True;TrustServerCertificate=True;Connect Timeout=10"
  }
}
```

Thay `.\SQLEXPRESS` bằng tên server đã kết nối thành công trong SSMS, chẳng hạn `TEN_MAY\SQLEXPRESS` hoặc `.` nếu dùng instance mặc định. Trong JSON, dấu `\` của tên instance phải viết thành `\\`.

`appsettings.Local.json` ghi đè chuỗi kết nối trong `appsettings.json`; launcher cũng đọc file này. Git bỏ qua file cấu hình riêng để từng máy dùng instance phù hợp. Sau khi sửa cấu hình, dừng rồi chạy lại web.

### Khởi tạo database lần đầu

- **Dùng `CHAY-WEB.cmd`:** launcher đọc cấu hình, tự gọi script tạo database nếu `QuanLyKinhMatWeb` chưa tồn tại, sau đó build và chạy web.
- **Dùng Visual Studio hoặc `dotnet run`:** tự chạy lệnh khởi tạo bên dưới trước lần chạy đầu. Hai cách này không tự tạo database.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\WebQuanLyKinhMat\scripts\Initialize-Database.ps1 -Server '.\SQLEXPRESS'
```

Tham số `-Server` phải trùng với server đã cấu hình. Script `Initialize-Database.ps1` chạy riêng **không đọc `appsettings.Local.json`**; nếu bỏ tham số, script dùng `HIEUCOI\SQLEXPRESS`. Chạy lệnh khởi tạo không thay đổi cấu hình kết nối của ứng dụng.

Script kiểm tra database chưa tồn tại, rồi tạo schema và nạp dữ liệu trong giao dịch. Nếu database đã có, script dừng và không ghi đè. SQL có kiểm tra database và phiên khởi tạo, vì vậy hãy dùng runner đi kèm; không mở file SQL rồi nhấn F5 trong SSMS để thay thế bước này.

Nếu tạo database thành công nhưng nạp schema thất bại, script giữ lại database để kiểm tra và không tự xóa. Đọc lỗi trước khi xử lý; chạy lại ngay sẽ nhận thông báo database đã tồn tại. Chi tiết nằm trong [tài liệu database](WebQuanLyKinhMat/docs/database.md).

## 3. Chạy ứng dụng

### Cách A — Mở nhanh bằng file CMD

1. Mở thư mục **`WebQuanLyKinhMat` bên trong**.
2. Nhấp đúp **`CHAY-WEB.cmd`**.
3. Chờ kiểm tra database, tải thư viện và build ở lần đầu; trình duyệt sẽ mở khi web sẵn sàng.
4. Nếu trình duyệt chưa mở, truy cập **<http://127.0.0.1:5080>**.

Launcher chạy web ở chế độ nền. Đóng tab trình duyệt không dừng web; dùng **`TAT-WEB.cmd`** trong cùng thư mục để dừng phiên do launcher tạo.

Nếu cần cổng khác, gọi trực tiếp script từ thư mục ngoài cùng:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\WebQuanLyKinhMat\scripts\Start-Web.ps1 -Port 5081
```

Khi đó địa chỉ là `http://127.0.0.1:5081`. Có thể thêm `-NoBrowser` để không tự mở trình duyệt. Hai tham số này dành cho `Start-Web.ps1`; file `CHAY-WEB.cmd` không chuyển tiếp tham số. Dừng phiên launcher hiện tại trước khi chuyển cổng để tránh để lại nhiều tiến trình.

### Cách B — Mở bằng Visual Studio

1. Hoàn thành cấu hình và khởi tạo database ở mục 2.
2. Mở **`WebQuanLyKinhMat.slnx`** ở ngoài cùng.
3. Chọn project **`WebQuanLyKinhMat`** làm Startup Project và profile chạy cùng tên nếu được hỏi.
4. Chờ restore NuGet, nhấn **Ctrl + F5** để chạy hoặc **F5** để gỡ lỗi.
5. Khi chạy F5, dùng **Stop Debugging** để dừng. Nếu chạy Ctrl + F5 và có cửa sổ console, nhấn **Ctrl + C** tại cửa sổ đó.

Profile trong `Properties/launchSettings.json` dùng `http://127.0.0.1:5080`. Nếu cổng này đang được launcher sử dụng, dừng launcher trước khi chạy bằng Visual Studio.

### Cách C — Chạy từ PowerShell/Terminal

Sau khi đã có database:

```powershell
dotnet restore .\WebQuanLyKinhMat.slnx
dotnet build .\WebQuanLyKinhMat.slnx
dotnet run --project .\WebQuanLyKinhMat\WebQuanLyKinhMat.csproj --no-launch-profile -- --urls http://127.0.0.1:5080
```

Mở `http://127.0.0.1:5080`; giữ Terminal mở trong thời gian dùng web. Nhấn **Ctrl + C** để dừng. `TAT-WEB.cmd` chỉ quản lý tiến trình do launcher khởi động, không thay cho Ctrl + C hoặc nút dừng của Visual Studio.

### Sau khi sửa mã nguồn

Nếu chạy bằng launcher, dừng rồi mở lại để build source mới. Bản Git không kèm thư mục biên dịch `runtime`. Nếu tự thêm một bản publish tại `WebQuanLyKinhMat/runtime`, launcher sẽ ưu tiên `runtime/KinhMat.Web.dll` và bỏ qua build; cần publish lại hoặc chạy source bằng Visual Studio/`dotnet run` để thấy thay đổi.

Tên assembly `KinhMat.Web.dll` và namespace `KinhMat.Web` được giữ trong cấu hình nội bộ. Đây là đầu ra hợp lệ của project `WebQuanLyKinhMat`, không phải lỗi đường dẫn.

## 4. Đăng nhập và sử dụng

Ngay sau khi khởi tạo từ bộ SQL đi kèm:

| Mã nhân viên dùng để đăng nhập | Mật khẩu ban đầu | Quyền |
|---|---|---|
| `1` | `hieucoi12345` | Quản lý (`Admin`) |
| `2` | `hieucoi12345` | Nhân viên (`Staff`) |
| `3` | `hieucoi12345` | Nhân viên (`Staff`) |

Nhập mã vào ô **Mã nhân viên / tên đăng nhập**. Web xác thực với bảng `WebUsers` bằng mật khẩu đã băm; không dùng tài khoản SQL Server để đăng nhập giao diện. Bộ SQL không tạo lại tài khoản demo `admin` hoặc `nhanvien`.

Nếu đã đổi mật khẩu trong database hiện tại, dùng mật khẩu mới. Khởi động lại web không đặt lại mật khẩu và không nạp lại dữ liệu mẫu.

### Trình tự thao tác đề xuất

1. **Tổng quan:** xem doanh thu, hóa đơn mới và hàng sắp hết.
2. **Danh mục → Sản phẩm:** quản lý tạo/sửa loại kính, thương hiệu, thuộc tính và sản phẩm; nhân viên có thể tra cứu. Dùng tìm kiếm, bộ lọc và phân trang để tìm sản phẩm.
3. **Nhà cung cấp → Nhập hàng:** quản lý chọn nhà cung cấp, thêm sản phẩm, nhập số lượng, đơn giá và giảm giá; kiểm tra tổng tiền trước khi lưu. Phiếu nhập hoàn tất làm tăng tồn kho.
4. **Khách hàng → Bán hàng:** chọn khách hàng hoặc khách lẻ, thêm sản phẩm đang bán, nhập số lượng và giảm giá. Kiểm tra chứng từ rồi xác nhận lưu; hóa đơn hoàn tất làm giảm tồn kho.
5. **Lịch sử chứng từ:** mở chi tiết trong Bán hàng/Nhập hàng để xem các dòng, số tiền và nhân viên lập. Quản lý có thể hủy chứng từ; hóa đơn bán được hoàn tồn, phiếu nhập chỉ hủy được khi tồn còn đủ để trừ lại. Chứng từ đã hủy vẫn giữ trong lịch sử.
6. **Báo cáo:** chọn kỳ để xem số liệu và xuất CSV. Doanh thu tính các hóa đơn hoàn tất, loại chứng từ đã hủy.

Theo quy tắc đang cài đặt, lưu phiếu nhập cập nhật giá nhập của sản phẩm bằng đơn giá nhập và tính giá bán bằng 110% đơn giá đó, làm tròn hai chữ số thập phân. Giảm giá trên dòng ảnh hưởng thành tiền chứng từ. Sản phẩm đã có chứng từ không được sửa tồn kho trực tiếp; dùng nhập/bán hàng để thay đổi tồn có lịch sử.

Staff không có quyền sửa sản phẩm, danh mục, nhà cung cấp, quản lý tài khoản, nhập hàng hoặc hủy chứng từ. Menu và nút được hiển thị theo quyền; API cũng kiểm tra quyền thực hiện thao tác.

Chọn biểu tượng **Tài khoản của tôi** ở phần hồ sơ để đổi mật khẩu hoặc đăng xuất. Mật khẩu mới dài 8–128 ký tự và phải nhập xác nhận khớp. Đổi mật khẩu làm các phiên đăng nhập khác mất hiệu lực; tài khoản bị khóa không tiếp tục truy cập được. Quản lý dùng mục **Tài khoản** để thêm tài khoản, sửa quyền/trạng thái hoặc đặt mật khẩu mới; khi sửa, để trống ô mật khẩu nếu muốn giữ nguyên.

Nếu có người khác vừa thay đổi giá hoặc tồn kho, hệ thống có thể yêu cầu kiểm tra lại giỏ hàng trước khi lưu. Khi có lỗi, đọc thông báo trong form và làm mới dữ liệu trước khi thử lại.

## 5. Kiểm tra và xử lý lỗi thường gặp

| Hiện tượng | Cách kiểm tra/xử lý |
|---|---|
| Không nhận lệnh `dotnet`, thiếu SDK hoặc không hỗ trợ `net10.0` | Chạy `dotnet --list-sdks`; cài .NET 10 SDK rồi mở lại Terminal/Visual Studio. |
| Visual Studio không mở `.slnx` hoặc không nhận project | Kiểm tra hỗ trợ định dạng solution, SDK và workload ASP.NET and web development; có thể chạy bằng Terminal trong lúc bổ sung môi trường. |
| Restore NuGet thất bại | Kiểm tra Internet, proxy và nguồn NuGet; chạy lại `dotnet restore .\WebQuanLyKinhMat.slnx` để đọc lỗi cụ thể. |
| Không kết nối được SQL Server | Kiểm tra tên instance, dịch vụ SQL Server và chuỗi kết nối; thử Windows Authentication trong SSMS bằng cùng tài khoản Windows. |
| Không có quyền tạo database | Tài khoản Windows chạy script cần quyền tạo database trên instance đó hoặc nhờ quản trị viên khởi tạo bằng runner. |
| Runner báo database đã tồn tại | Nếu database hoàn chỉnh thì bỏ qua khởi tạo và chạy web; nếu lần khởi tạo trước thất bại thì kiểm tra nguyên nhân trước khi xử lý database đó. |
| Database có sẵn nhưng thiếu bảng/không đăng nhập được | Xác nhận đúng `QuanLyKinhMatWeb` và schema của bộ SQL; launcher không tự nâng cấp hay thay schema database cũ. |
| Cổng 5080 đang được dùng | Dừng phiên trước bằng đúng công cụ đã mở nó, hoặc dùng `Start-Web.ps1 -Port 5081`. |
| Trình duyệt không mở hoặc không vào được web | Kiểm tra cửa sổ CMD, thử địa chỉ đúng cổng và xem log bên dưới. Giữ thông báo lỗi để đối chiếu. |
| Đăng nhập bị từ chối | Dùng mã `1`, `2`, `3`, mật khẩu hiện tại và tài khoản đang hoạt động. Nếu thử quá nhiều lần, đợi một phút rồi thử lại. |
| API trả 401/403 | 401: đăng nhập lại; 403: chức năng nằm ngoài quyền tài khoản. |
| Sửa source nhưng giao diện chưa đổi | Dừng và build/chạy lại; kiểm tra bản `runtime` được ưu tiên nếu có, rồi tải lại trang bằng Ctrl + F5. |

Log khi dùng launcher:

```text
WebQuanLyKinhMat/App_Data/server.log
WebQuanLyKinhMat/App_Data/server-error.log
```

Chạy từ Terminal/Visual Studio thì xem output tại chính nơi khởi chạy. Truy cập `/health` tại cổng đang dùng: HTTP 200 với `status: "ready"` cho biết web đang chạy và kết nối được database; HTTP 503 với `database-unavailable` cho biết cần kiểm tra SQL.

## 6. Đưa source lên GitHub để nộp

Đẩy **thư mục ngoài cùng** để repository hiển thị solution, SQL, README và thư mục project. Không chỉ upload file ZIP hoặc riêng thư mục project.

### Khi repository cục bộ đã có Git

Mở Terminal tại thư mục ngoài cùng:

```powershell
git status
git branch --show-current
git remote -v
```

Thư mục đã chuẩn bị có nhánh `main`. Tạo repository **trống** trong tài khoản GitHub của bạn, không chọn tạo sẵn README hay `.gitignore`. Nếu chưa có `origin`, gắn URL repo:

```powershell
git remote add origin https://github.com/TEN_TAI_KHOAN/WebQuanLyKinhMat.git
```

Nếu `origin` đã có nhưng trỏ sai địa chỉ, dùng lệnh sau thay cho `remote add`:

```powershell
git remote set-url origin https://github.com/TEN_TAI_KHOAN/WebQuanLyKinhMat.git
```

Thay `TEN_TAI_KHOAN` bằng tài khoản thật. Nếu có thay đổi chưa commit:

```powershell
git add .
git commit -m "Hoan thien du an quan ly kinh mat"
```

Nếu Git chưa biết danh tính commit, cấu hình tên/email của chính bạn cho repository rồi thực hiện lại commit:

```powershell
git config user.name "TEN_CUA_BAN"
git config user.email "EMAIL_CUA_BAN"
```

Sau đó gửi nhánh lên GitHub:

```powershell
git push -u origin main
```

Đăng nhập bằng tài khoản của bạn qua trình duyệt/Git Credential Manager nếu được yêu cầu. Sau khi push, mở trang repository, kiểm tra đủ file và gửi link theo yêu cầu nộp bài.

### Nếu lấy bản ZIP và chưa có thư mục `.git`

Khởi tạo tại thư mục ngoài cùng, rồi làm tiếp bước gắn `origin` và push ở trên:

```powershell
git init -b main
git add .
git commit -m "Khoi tao du an quan ly kinh mat"
```

Không cần `git init` lại cho thư mục đã là repository. Các lần cập nhật sau dùng `git status`, `git add .`, `git commit` và `git push`.

### Thành phần đưa lên repository

Giữ source, `.slnx`, `.csproj`, SQL, tài liệu và tài nguyên giao diện. `.gitignore` loại `.vs`, `bin`, `obj`, `runtime`, `App_Data`, log, khóa cookie, kết quả/cache chạy thử, `node_modules` và `appsettings.Local.json`. Không cần các đầu ra này để người khác build source. Kiểm tra `git status` trước mỗi commit, đặc biệt khi thêm cấu hình cục bộ hoặc file mới.
