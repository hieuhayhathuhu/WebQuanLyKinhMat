using Microsoft.Data.SqlClient;

namespace KinhMat.Web.Data;

public sealed class SqlDatabase
{
    private readonly string connectionString;

    public SqlDatabase(IConfiguration configuration)
    {
        var configured = configuration.GetConnectionString("Store");
        if (string.IsNullOrWhiteSpace(configured))
            throw new InvalidOperationException("Chưa cấu hình ConnectionStrings:Store.");
        var builder = new SqlConnectionStringBuilder(configured);
        if (!string.Equals(builder.InitialCatalog, "QuanLyKinhMatWeb", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Ứng dụng web chỉ sử dụng database bản sao QuanLyKinhMatWeb.");
        builder.ApplicationName = "KinhMat.Web";
        connectionString = builder.ConnectionString;
    }

    public async Task<SqlConnection> OpenAsync()
    {
        var connection = new SqlConnection(connectionString);
        try
        {
            await connection.OpenAsync();
            return connection;
        }
        catch
        {
            await connection.DisposeAsync();
            throw;
        }
    }
}
