namespace KinhMat.Web.Data;

public sealed class BusinessException(string message, int statusCode = 400) : Exception(message)
{
    public int StatusCode { get; } = statusCode;
}
