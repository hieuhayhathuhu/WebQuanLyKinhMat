using System.ComponentModel.DataAnnotations;

namespace KinhMat.Web.Models;

public sealed class WebUser
{
    public int Id { get; set; }
    public int EmployeeId { get; set; }
    public string UserName { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public string Role { get; set; } = "Staff";
    public bool IsActive { get; set; }
    public Guid SecurityStamp { get; set; }
}

public sealed class LoginInput
{
    [Required(ErrorMessage = "Nhập tên đăng nhập."), StringLength(50)]
    public string UserName { get; set; } = "";
    [Required(ErrorMessage = "Nhập mật khẩu."), StringLength(128), DataType(DataType.Password)]
    public string Password { get; set; } = "";
    public bool RememberMe { get; set; }
    public string? ReturnUrl { get; set; }
}

public sealed class UserCreateInput
{
    [Required, StringLength(50, MinimumLength = 3), RegularExpression(@"^[a-zA-Z0-9._-]+$", ErrorMessage = "Tên đăng nhập chỉ gồm chữ, số, dấu chấm, gạch dưới hoặc gạch ngang.")]
    public string UserName { get; set; } = "";
    [Required, StringLength(100)] public string DisplayName { get; set; } = "";
    [Required, StringLength(128, MinimumLength = 8)] public string Password { get; set; } = "";
    [Required, RegularExpression("^(Admin|Staff)$")] public string Role { get; set; } = "Staff";
}

public sealed class UserEditInput
{
    [Required, StringLength(100)] public string DisplayName { get; set; } = "";
    [Required, RegularExpression("^(Admin|Staff)$")] public string Role { get; set; } = "Staff";
    public bool IsActive { get; set; } = true;
    [StringLength(128, MinimumLength = 8)] public string? Password { get; set; }
}

public sealed class PasswordChangeInput
{
    [Required, StringLength(128)] public string CurrentPassword { get; set; } = "";
    [Required, StringLength(128, MinimumLength = 8)] public string NewPassword { get; set; } = "";
    [Required, Compare(nameof(NewPassword), ErrorMessage = "Mật khẩu xác nhận chưa khớp.")]
    public string ConfirmPassword { get; set; } = "";
}

public sealed record UserSummary(int Id, int EmployeeId, string UserName, string DisplayName, string Role, bool IsActive);
