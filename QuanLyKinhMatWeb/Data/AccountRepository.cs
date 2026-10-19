using System.Data;
using KinhMat.Web.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.Data.SqlClient;

namespace KinhMat.Web.Data;

public sealed class AccountRepository(SqlDatabase database, IPasswordHasher<WebUser> passwords)
{
    private const string Fields = "u.Id,u.EmployeeId,u.UserName,u.DisplayName,u.PasswordHash,u.Role,u.IsActive,u.SecurityStamp";
    private static WebUser Read(SqlDataReader reader) => new()
    {
        Id = reader.GetInt32(0), EmployeeId = reader.GetInt32(1), UserName = reader.GetString(2),
        DisplayName = reader.GetString(3), PasswordHash = reader.GetString(4), Role = reader.GetString(5),
        IsActive = reader.GetBoolean(6), SecurityStamp = reader.GetGuid(7)
    };
    public async Task<WebUser?> FindAsync(string name)
    {
        await using var connection = await database.OpenAsync();
        await using var command = new SqlCommand($"SELECT {Fields} FROM dbo.WebUsers u JOIN dbo.NhanVien n ON n.MaNhanVien=u.EmployeeId WHERE u.UserName=@name AND n.TrangThai=1", connection);
        command.Parameters.Add("@name", SqlDbType.NVarChar, 50).Value = name.Trim();
        await using var reader = await command.ExecuteReaderAsync();
        return await reader.ReadAsync() ? Read(reader) : null;
    }
    public async Task<WebUser?> FindAsync(int id)
    {
        await using var connection = await database.OpenAsync();
        await using var command = new SqlCommand($"SELECT {Fields} FROM dbo.WebUsers u JOIN dbo.NhanVien n ON n.MaNhanVien=u.EmployeeId WHERE u.Id=@id AND n.TrangThai=1", connection);
        command.Parameters.AddWithValue("@id", id);
        await using var reader = await command.ExecuteReaderAsync();
        return await reader.ReadAsync() ? Read(reader) : null;
    }
    public async Task<List<UserSummary>> ListAsync()
    {
        await using var connection = await database.OpenAsync();
        await using var command = new SqlCommand("SELECT Id,EmployeeId,UserName,DisplayName,Role,IsActive FROM dbo.WebUsers ORDER BY Id", connection);
        await using var reader = await command.ExecuteReaderAsync();
        var result = new List<UserSummary>();
        while (await reader.ReadAsync()) result.Add(new(reader.GetInt32(0), reader.GetInt32(1), reader.GetString(2), reader.GetString(3), reader.GetString(4), reader.GetBoolean(5)));
        return result;
    }
    public async Task<UserSummary> CreateAsync(UserCreateInput input)
    {
        var name = input.UserName.Trim();
        var display = input.DisplayName.Trim();
        if (display.Length == 0) throw new BusinessException("Nhập họ tên nhân viên.");
        var user = new WebUser { UserName = name, DisplayName = display, Role = input.Role, IsActive = true };
        await using var connection = await database.OpenAsync();
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable);
        await using var command = new SqlCommand(@"IF EXISTS(SELECT 1 FROM dbo.WebUsers WITH(UPDLOCK,HOLDLOCK) WHERE UserName=@name) THROW 50001,N'Tên đăng nhập đã tồn tại.',1;
INSERT dbo.NhanVien(HoTen,ChucVu,TrangThai,Passw) VALUES(@display,@position,1,NULL);
DECLARE @employee int=CONVERT(int,SCOPE_IDENTITY());
INSERT dbo.WebUsers(EmployeeId,UserName,PasswordHash,DisplayName,Role,IsActive) VALUES(@employee,@name,@hash,@display,@role,1);
SELECT CONVERT(int,SCOPE_IDENTITY()),@employee;", connection, transaction);
        command.Parameters.AddWithValue("@name", name);
        command.Parameters.AddWithValue("@display", display);
        command.Parameters.AddWithValue("@position", input.Role == "Admin" ? "Quản lý" : "Nhân viên bán hàng");
        command.Parameters.AddWithValue("@role", input.Role);
        command.Parameters.AddWithValue("@hash", passwords.HashPassword(user, input.Password));
        try
        {
            await using (var reader = await command.ExecuteReaderAsync())
            {
                await reader.ReadAsync(); user.Id = reader.GetInt32(0); user.EmployeeId = reader.GetInt32(1);
            }
            await transaction.CommitAsync();
        }
        catch (SqlException ex) when (ex.Number is 50001 or 2601 or 2627) { throw new BusinessException("Tên đăng nhập đã tồn tại.", 409); }
        return new(user.Id, user.EmployeeId, name, display, input.Role, true);
    }
    public async Task<UserSummary> UpdateAsync(int id, UserEditInput input)
    {
        var display = input.DisplayName.Trim();
        if (display.Length == 0) throw new BusinessException("Nhập họ tên nhân viên.");
        await using var connection = await database.OpenAsync();
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable);
        await using var read = new SqlCommand($"SELECT {Fields} FROM dbo.WebUsers u WITH(UPDLOCK,HOLDLOCK) WHERE u.Id=@id", connection, transaction);
        read.Parameters.AddWithValue("@id", id);
        WebUser user;
        await using (var reader = await read.ExecuteReaderAsync()) { if (!await reader.ReadAsync()) throw new BusinessException("Không tìm thấy tài khoản.", 404); user = Read(reader); }
        if (user.Role == "Admin" && user.IsActive && (input.Role != "Admin" || !input.IsActive))
        {
            await using var count = new SqlCommand("SELECT COUNT(*) FROM dbo.WebUsers WITH(UPDLOCK,HOLDLOCK) WHERE Role=N'Admin' AND IsActive=1", connection, transaction);
            if (Convert.ToInt32(await count.ExecuteScalarAsync()) <= 1) throw new BusinessException("Cần giữ ít nhất một tài khoản quản lý đang hoạt động.", 409);
        }
        var hash = string.IsNullOrEmpty(input.Password) ? user.PasswordHash : passwords.HashPassword(user, input.Password);
        await using var update = new SqlCommand(@"UPDATE dbo.WebUsers SET DisplayName=@display,Role=@role,IsActive=@active,PasswordHash=@hash,SecurityStamp=NEWID() WHERE Id=@id;
UPDATE dbo.NhanVien SET HoTen=@display,ChucVu=@position,TrangThai=@active WHERE MaNhanVien=@employee;", connection, transaction);
        update.Parameters.AddWithValue("@display", display); update.Parameters.AddWithValue("@role", input.Role);
        update.Parameters.AddWithValue("@active", input.IsActive); update.Parameters.AddWithValue("@hash", hash);
        update.Parameters.AddWithValue("@position", input.Role == "Admin" ? "Quản lý" : "Nhân viên bán hàng");
        update.Parameters.AddWithValue("@employee", user.EmployeeId); update.Parameters.AddWithValue("@id", id);
        await update.ExecuteNonQueryAsync(); await transaction.CommitAsync();
        return new(id, user.EmployeeId, user.UserName, display, input.Role, input.IsActive);
    }
    public async Task<Guid> ChangePasswordAsync(WebUser user, string password)
    {
        await using var connection = await database.OpenAsync();
        await using var command = new SqlCommand("UPDATE dbo.WebUsers SET PasswordHash=@hash,SecurityStamp=NEWID() OUTPUT inserted.SecurityStamp WHERE Id=@id AND SecurityStamp=@stamp AND IsActive=1", connection);
        command.Parameters.AddWithValue("@hash", passwords.HashPassword(user, password)); command.Parameters.AddWithValue("@id", user.Id);
        command.Parameters.AddWithValue("@stamp", user.SecurityStamp);
        var stamp = await command.ExecuteScalarAsync();
        return stamp is Guid updatedStamp ? updatedStamp
            : throw new BusinessException("Tài khoản đã thay đổi. Vui lòng đăng nhập lại trước khi đổi mật khẩu.", 409);
    }
    // Explicit local migration only: the original database is read, never updated.
    // Re-running keeps existing web passwords/roles intact.
    public async Task<int> ImportEmployeeLoginsAsync()
    {
        await using var connection = await database.OpenAsync();
        var source = new List<(int Id, string Name, string Password, bool Active, string Role)>();
        await using (var read = new SqlCommand(@"
SELECT n.MaNhanVien,n.HoTen,n.Passw,n.TrangThai,
 CASE WHEN EXISTS(SELECT 1 FROM [QuanLyKinhMat].dbo.TaiKhoan t
   WHERE t.MaNhanVien=n.MaNhanVien AND t.Quyen=N'Admin' AND t.TrangThai=1)
   OR COALESCE(c.TenChucVu,n.ChucVu)=N'Quản lý' THEN N'Admin' ELSE N'Staff' END
FROM [QuanLyKinhMat].dbo.NhanVien n
LEFT JOIN [QuanLyKinhMat].dbo.ChucVu c ON c.MaChucVu=n.MaChucVu
WHERE n.Passw IS NOT NULL AND LEN(n.Passw)>0 ORDER BY n.MaNhanVien;", connection))
        await using (var reader = await read.ExecuteReaderAsync())
        {
            while (await reader.ReadAsync()) source.Add((reader.GetInt32(0), reader.GetString(1), reader.GetString(2), reader.GetBoolean(3), reader.GetString(4)));
        }
        if (source.Count == 0) throw new InvalidOperationException("Database gốc không có tài khoản nhân viên để chuyển.");
        await using var transaction = (SqlTransaction)await connection.BeginTransactionAsync(IsolationLevel.Serializable);
        var imported = 0;
        foreach (var employee in source)
        {
            var name = employee.Id.ToString(System.Globalization.CultureInfo.InvariantCulture);
            await using var existing = new SqlCommand("SELECT UserName FROM dbo.WebUsers WITH(UPDLOCK,HOLDLOCK) WHERE EmployeeId=@employee", connection, transaction);
            existing.Parameters.AddWithValue("@employee", employee.Id);
            var existingName = await existing.ExecuteScalarAsync();
            if (existingName is string currentName)
            {
                if (currentName != name) throw new InvalidOperationException($"Nhân viên {name} đã có tài khoản web khác; dừng để tránh đổi tài khoản đang dùng.");
                continue;
            }
            // This migration handles the plain-text credentials in the supplied SQL database.
            // Never turn a legacy hash into a literal password or reset an existing account.
            if (employee.Password.StartsWith("PBKDF2$", StringComparison.Ordinal))
                throw new InvalidOperationException($"Nhân viên {name} có mật khẩu PBKDF2 cũ; cần chuyển bằng xác minh mật khẩu, không được băm lại chuỗi hash.");
            var user = new WebUser { EmployeeId = employee.Id, UserName = name, DisplayName = employee.Name, Role = employee.Role, IsActive = employee.Active };
            await using var insert = new SqlCommand(@"
IF DB_NAME()<>N'QuanLyKinhMatWeb' THROW 51000,N'Sai database đích.',1;
IF NOT EXISTS(SELECT 1 FROM dbo.NhanVien WHERE MaNhanVien=@employee AND HoTen=@display)
 THROW 51001,N'Nhân viên trong bản web không khớp bản gốc; dừng để kiểm tra.',1;
IF EXISTS(SELECT 1 FROM dbo.WebUsers WITH(UPDLOCK,HOLDLOCK) WHERE UserName=@name)
 THROW 51002,N'Tên đăng nhập mã nhân viên đã được sử dụng.',1;
INSERT dbo.WebUsers(EmployeeId,UserName,PasswordHash,DisplayName,Role,IsActive)
 VALUES(@employee,@name,@hash,@display,@role,@active);", connection, transaction);
            insert.Parameters.AddWithValue("@employee", employee.Id);
            insert.Parameters.AddWithValue("@name", name);
            insert.Parameters.AddWithValue("@hash", passwords.HashPassword(user, employee.Password));
            insert.Parameters.AddWithValue("@display", employee.Name);
            insert.Parameters.AddWithValue("@role", employee.Role);
            insert.Parameters.AddWithValue("@active", employee.Active);
            await insert.ExecuteNonQueryAsync();
            imported++;
        }
        await transaction.CommitAsync();
        return imported;
    }
}
