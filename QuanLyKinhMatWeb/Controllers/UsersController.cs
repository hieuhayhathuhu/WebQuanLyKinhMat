using System.Security.Claims;
using KinhMat.Web.Data;
using KinhMat.Web.Models;
using KinhMat.Web.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace KinhMat.Web.Controllers;

[ApiController, Authorize(Roles = "Admin"), Route("api/users")]
public sealed class UsersController(AccountRepository accounts) : ControllerBase
{
    [HttpGet] public Task<List<UserSummary>> List() => accounts.ListAsync();
    [HttpPost] public async Task<IActionResult> Create(UserCreateInput input) => Ok(await accounts.CreateAsync(input));
    [HttpPut("{id:int}")] public async Task<IActionResult> Update(int id, UserEditInput input)
    {
        var result = await accounts.UpdateAsync(id, input);
        if (id == int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!))
        {
            var user = await accounts.FindAsync(id);
            if (user?.IsActive == true) await SessionIssuer.SignInAsync(HttpContext, user);
        }
        return Ok(result);
    }
}

[ApiController, Authorize, Route("api/account")]
public sealed class ProfileController(AccountRepository accounts, IPasswordHasher<WebUser> passwords) : ControllerBase
{
    [HttpPost("password")]
    public async Task<IActionResult> Password(PasswordChangeInput input)
    {
        var user = await accounts.FindAsync(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!));
        if (user is null || passwords.VerifyHashedPassword(user, user.PasswordHash, input.CurrentPassword) == PasswordVerificationResult.Failed)
            throw new BusinessException("Mật khẩu hiện tại chưa đúng.");
        if (input.CurrentPassword == input.NewPassword) throw new BusinessException("Mật khẩu mới cần khác mật khẩu hiện tại.");
        var updatedStamp = await accounts.ChangePasswordAsync(user, input.NewPassword);
        user = await accounts.FindAsync(user.Id);
        if (user is null || !user.IsActive)
            throw new BusinessException("Tài khoản không còn hoạt động. Vui lòng đăng nhập lại.", 401);
        if (user.SecurityStamp != updatedStamp)
            throw new BusinessException("Tài khoản đã thay đổi. Vui lòng đăng nhập lại.", 409);
        await SessionIssuer.SignInAsync(HttpContext, user);
        return Ok(new { message = "Đã đổi mật khẩu. Các phiên đăng nhập khác sẽ cần đăng nhập lại." });
    }
}
