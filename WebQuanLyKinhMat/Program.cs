using System.Security.Claims;
using System.Security.Cryptography;
using KinhMat.Web.Data;
using KinhMat.Web.Models;
using KinhMat.Web.Services;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: true);
builder.Services.AddControllersWithViews(options => { options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()); options.Filters.Add<BusinessExceptionFilter>(); })
    .ConfigureApiBehaviorOptions(options => options.InvalidModelStateResponseFactory = context => new BadRequestObjectResult(new
    {
        message = "Thông tin chưa hợp lệ. Kiểm tra các ô đã nhập.",
        errors = context.ModelState.Where(x => x.Value?.Errors.Count > 0).ToDictionary(x => x.Key, x => x.Value!.Errors.Select(e => e.ErrorMessage).ToArray())
    }));
builder.Services.AddAntiforgery(options => { options.HeaderName = "X-CSRF-TOKEN"; options.Cookie.Name = "KinhMat.Antiforgery"; options.Cookie.SameSite = SameSiteMode.Strict; });
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options => { options.Cookie.Name = "KinhMat.Session"; options.Cookie.HttpOnly = true; options.Cookie.IsEssential = true; options.IdleTimeout = TimeSpan.FromHours(8); });
var keys = new DirectoryInfo(Path.Combine(builder.Environment.ContentRootPath, "App_Data", "keys"));
keys.Create();
var protection = builder.Services.AddDataProtection().PersistKeysToFileSystem(keys).SetApplicationName("KinhMat.Web");
if (OperatingSystem.IsWindows()) protection.ProtectKeysWithDpapi();
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(options =>
{
    options.Cookie.Name = "KinhMat.Auth"; options.Cookie.HttpOnly = true; options.Cookie.SameSite = SameSiteMode.Lax;
    options.LoginPath = "/account/login"; options.AccessDeniedPath = "/account/denied";
    options.ExpireTimeSpan = TimeSpan.FromHours(8); options.SlidingExpiration = true;
    options.Events.OnRedirectToLogin = context => { if (context.Request.Path.StartsWithSegments("/api")) context.Response.StatusCode = 401; else context.Response.Redirect(context.RedirectUri); return Task.CompletedTask; };
    options.Events.OnRedirectToAccessDenied = context => { if (context.Request.Path.StartsWithSegments("/api")) context.Response.StatusCode = 403; else context.Response.Redirect(context.RedirectUri); return Task.CompletedTask; };
    options.Events.OnValidatePrincipal = async context =>
    {
        var id = context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
        var user = int.TryParse(id, out var userId) ? await context.HttpContext.RequestServices.GetRequiredService<AccountRepository>().FindAsync(userId) : null;
        if (user is null || !user.IsActive || user.SecurityStamp.ToString() != context.Principal?.FindFirstValue("stamp"))
        { context.RejectPrincipal(); await context.HttpContext.SignOutAsync(); }
    };
});
builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("login", limiter => { limiter.PermitLimit = 12; limiter.Window = TimeSpan.FromMinutes(1); limiter.QueueLimit = 0; });
    options.OnRejected = async (context, token) => { context.HttpContext.Response.StatusCode = 429; await context.HttpContext.Response.WriteAsync("Bạn đã thử đăng nhập nhiều lần. Vui lòng đợi một phút.", token); };
});
builder.Services.AddScoped<SqlDatabase>();
builder.Services.AddScoped<StoreRepository>();
builder.Services.AddScoped<AccountRepository>();
builder.Services.AddScoped<IPasswordHasher<WebUser>, PasswordHasher<WebUser>>();
var app = builder.Build();
if (args.Contains("--import-employee-logins", StringComparer.Ordinal))
{
    using var scope = app.Services.CreateScope();
    var imported = await scope.ServiceProvider.GetRequiredService<AccountRepository>().ImportEmployeeLoginsAsync();
    Console.WriteLine($"Đã chuyển {imported} tài khoản mã nhân viên sang WebUsers. Database gốc giữ nguyên; tài khoản web đã có không bị đặt lại mật khẩu.");
    return;
}
app.UseExceptionHandler(handler => handler.Run(async context =>
{
    var error = context.Features.Get<IExceptionHandlerFeature>()?.Error;
    var status = error is BusinessException business ? business.StatusCode : 500;
    var message = error is BusinessException expected ? expected.Message : "Không thực hiện được yêu cầu. Kiểm tra kết nối database hoặc thử lại sau.";
    if (status >= 500) app.Logger.LogError(error, "Request failed: {Path}", context.Request.Path);
    context.Response.StatusCode = status;
    if (context.Request.Path.StartsWithSegments("/api")) await context.Response.WriteAsJsonAsync(new { message });
    else { context.Response.ContentType = "text/plain; charset=utf-8"; await context.Response.WriteAsync(message); }
}));
app.Use(async (context, next) =>
{
    var nonce = Convert.ToBase64String(RandomNumberGenerator.GetBytes(18)); context.Items["CspNonce"] = nonce;
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["Referrer-Policy"] = "same-origin";
    context.Response.Headers["Content-Security-Policy"] = $"default-src 'self'; script-src 'self' 'nonce-{nonce}'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self'; frame-ancestors 'none'; object-src 'none'; base-uri 'self'; form-action 'self'";
    if (!context.Request.Path.StartsWithSegments("/css") && !context.Request.Path.StartsWithSegments("/js"))
    { context.Response.Headers.CacheControl = "no-cache, no-store"; context.Response.Headers.Pragma = "no-cache"; }
    await next();
});
app.UseStaticFiles();
app.UseRouting();
app.UseRateLimiter();
app.UseSession();
app.UseAuthentication();
app.UseAuthorization();
app.MapGet("/health", async (SqlDatabase database) =>
{
    try { await using var connection = await database.OpenAsync(); return Results.Ok(new { app = "KinhMat.Web", status = "ready" }); }
    catch { return Results.Json(new { status = "database-unavailable" }, statusCode: 503); }
}).AllowAnonymous();
app.MapControllers();
app.MapControllerRoute("default", "{controller=Home}/{action=Index}/{id?}");
app.Run();

public partial class Program { }
