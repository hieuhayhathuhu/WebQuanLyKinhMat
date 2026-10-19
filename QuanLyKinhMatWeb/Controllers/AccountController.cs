using KinhMat.Web.Data;
using KinhMat.Web.Models;
using KinhMat.Web.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace KinhMat.Web.Controllers;

public sealed class AccountController(AccountRepository accounts, IPasswordHasher<WebUser> passwords) : Controller
{
    [AllowAnonymous, HttpGet("/account/login")]
    public IActionResult Login(string? returnUrl)
    {
        if (User.Identity?.IsAuthenticated == true) return Redirect("/");
        return View(new LoginInput { ReturnUrl = returnUrl });
    }
    [AllowAnonymous, HttpPost("/account/login"), EnableRateLimiting("login")]
    public async Task<IActionResult> Login(LoginInput input)
    {
        if (!ModelState.IsValid) return View(input);
        var user = await accounts.FindAsync(input.UserName);
        if (user is null || !user.IsActive || passwords.VerifyHashedPassword(user, user.PasswordHash, input.Password) == PasswordVerificationResult.Failed)
        {
            ModelState.AddModelError("", "Tên đăng nhập hoặc mật khẩu không đúng, hoặc tài khoản đã ngừng hoạt động.");
            return View(input);
        }
        await SessionIssuer.SignInAsync(HttpContext, user, input.RememberMe);
        return LocalRedirect(Url.IsLocalUrl(input.ReturnUrl) ? input.ReturnUrl! : "/");
    }
    [Authorize, HttpPost("/account/logout")]
    public async Task<IActionResult> Logout()
    {
        HttpContext.Session.Clear(); await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return Ok(new { message = "Đã đăng xuất." });
    }
    [AllowAnonymous, HttpGet("/account/denied")]
    public IActionResult Denied() => StatusCode(403, "Bạn không có quyền thực hiện chức năng này.");
}
