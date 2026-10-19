using KinhMat.Web.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace KinhMat.Web.Services;

public sealed class BusinessExceptionFilter : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        if (context.Exception is not BusinessException error) return;
        context.Result = new ObjectResult(new { message = error.Message }) { StatusCode = error.StatusCode };
        context.ExceptionHandled = true;
    }
}
