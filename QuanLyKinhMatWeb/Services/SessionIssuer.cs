using System.Security.Claims;
using KinhMat.Web.Models;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;

namespace KinhMat.Web.Services;

public static class SessionIssuer
{
    public static async Task SignInAsync(HttpContext context, WebUser user, bool remember = false)
    {
        var identity = new ClaimsIdentity(new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()), new Claim(ClaimTypes.Name, user.DisplayName),
            new Claim(ClaimTypes.Role, user.Role), new Claim("employeeId", user.EmployeeId.ToString()),
            new Claim("userName", user.UserName), new Claim("stamp", user.SecurityStamp.ToString())
        }, CookieAuthenticationDefaults.AuthenticationScheme);
        context.Session.SetInt32("EmployeeId", user.EmployeeId);
        context.Session.SetString("DisplayName", user.DisplayName);
        await context.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, new ClaimsPrincipal(identity), new AuthenticationProperties
        { IsPersistent = remember, ExpiresUtc = DateTimeOffset.UtcNow.Add(remember ? TimeSpan.FromDays(14) : TimeSpan.FromHours(8)) });
    }
}
