# Hướng dẫn dự án bài tập lớn

## Mở bằng Visual Studio

Mở `QuanLyKinhMatWeb.slnx` ở ngoài cùng. Source nằm trong `QuanLyKinhMatWeb/QuanLyKinhMatWeb.csproj`, target `net10.0`. Chọn project web làm Startup Project.

Nếu chỉ muốn chạy, mở thư mục `QuanLyKinhMatWeb` rồi dùng `CHAY-WEB.cmd` bên trong. File chạy sẽ tạo database mới khi chưa có, build source và mở trình duyệt. Bản Git không chứa thư viện biên dịch/runtime có sẵn.

## Database

SQL nằm ở ngoài cùng: `QuanLyKinhMat.sql`, gồm schema, dữ liệu và ba tài khoản hash. Đổi Server trong `QuanLyKinhMatWeb/appsettings.json` cho đúng máy; launcher và server cùng đọc cấu hình này. Có thể tạo `appsettings.Local.json` trong project để ghi cấu hình riêng; file đó đã được Git bỏ qua.

Bộ SQL có guard và dùng runner để khởi tạo an toàn. Không cần chạy trực tiếp bằng F5 trong SSMS. Nếu muốn khởi tạo riêng:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\QuanLyKinhMatWeb\scripts\Initialize-Database.ps1 -Server '.\SQLEXPRESS'
```

Đổi tên server cho đúng instance. Nếu DB web đã tồn tại, script dừng và không ghi đè. Database gốc WinForms không bị sửa.

## Chạy từ Terminal

Tại thư mục chứa solution:

```powershell
dotnet restore QuanLyKinhMatWeb.slnx
dotnet build QuanLyKinhMatWeb.slnx
dotnet run --project QuanLyKinhMatWeb/QuanLyKinhMatWeb.csproj --urls http://127.0.0.1:5080
```

Dùng Ctrl+C để dừng phiên chạy từ Terminal. Dùng `QuanLyKinhMatWeb/TAT-WEB.cmd` cho phiên chạy bằng launcher.

## Đưa thư mục này lên GitHub

Thư mục này là repository Git cục bộ. Không gắn với repo của nhóm mẫu và chưa tự gửi mã nguồn lên tài khoản GitHub nào.

1. Tạo một repository trống trong tài khoản GitHub của bạn, ví dụ `QuanLyKinhMatWeb`. Không chọn tạo README/gitignore mới nếu đã có các file tại máy.
2. Mở Terminal tại thư mục này.
3. Kiểm tra `git status` và commit nếu chưa có commit.
4. Gắn đúng link repo của bạn rồi push:

```powershell
git remote add origin https://github.com/TEN_TAI_KHOAN/QuanLyKinhMatWeb.git
git push -u origin main
```

Thay `TEN_TAI_KHOAN` bằng tài khoản thật; đăng nhập GitHub bằng cơ chế trình duyệt/Git Credential Manager khi được hỏi. Nếu Git yêu cầu danh tính commit, cấu hình tên/email của chính bạn cho repo rồi commit:

```powershell
git config user.name "TEN_CUA_BAN"
git config user.email "EMAIL_CUA_BAN"
git add .
git commit -m "Hoan thien bai tap lon quan ly kinh mat"
```

Sau khi push thành công, gửi đường dẫn repository cho thầy. Upload riêng một file ZIP không cho hiển thị trực tiếp cây source như repo mẫu.

## File được Git bỏ qua

`.vs`, `bin`, `obj`, `runtime`, `App_Data`, log, khóa cookie, file cấu hình riêng, cache và node_modules không được đưa lên Git. Source, `.slnx`, SQL, tài liệu và ảnh minh họa được giữ trong repo.
