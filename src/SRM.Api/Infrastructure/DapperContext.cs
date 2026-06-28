using System.Data;
using Npgsql;

namespace SRM.Api.Infrastructure;

public sealed class DapperContext(IConfiguration configuration)
{
    private readonly string connectionString =
        configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("Connection string 'DefaultConnection' was not found.");

    public IDbConnection CreateConnection()
    {
        return new NpgsqlConnection(connectionString);
    }
}