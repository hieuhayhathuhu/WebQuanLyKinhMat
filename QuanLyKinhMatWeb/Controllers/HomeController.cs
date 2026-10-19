using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Antiforgery;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KinhMat.Web.Controllers;

[Authorize]
public sealed class HomeController(IAntiforgery antiforgery) : Controller
{
    public IActionResult Index()
    {
        ViewBag.CspNonce = HttpContext.Items["CspNonce"];
        ViewBag.BootstrapJson = JsonSerializer.Serialize(new
        {
            userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!),
            employeeId = int.Parse(User.FindFirstValue("employeeId")!), displayName = User.Identity!.Name,
            role = User.FindFirstValue(ClaimTypes.Role), csrfToken = antiforgery.GetAndStoreTokens(HttpContext).RequestToken
        });
        return View();
    }
}
