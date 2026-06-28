using Dapper;
using System.Collections.Concurrent;
using System.Data.Common; // Required for DbConnection and await using
using System.Linq;

namespace SRM.Api.Infrastructure.Crud;

public sealed class TableMetadataProvider(DapperContext context) : ITableMetadataProvider
{
    private const string SchemaName = "whatsflow";

    // Using Lazy<Task<...>> is a good pattern to prevent "cache stampedes"
    private readonly ConcurrentDictionary<string, Lazy<Task<TableMetadata>>> cache = new(StringComparer.OrdinalIgnoreCase);

    public Task<TableMetadata> GetTableMetadataAsync(string tableName, CancellationToken cancellationToken = default)
    {
        var normalizedName = tableName.Trim();
        if (string.IsNullOrWhiteSpace(normalizedName))
        {
            throw new ArgumentException("Table name is required.", nameof(tableName));
        }

        // The factory only runs once per table name
        var metadata = cache.GetOrAdd(normalizedName, key =>
            new Lazy<Task<TableMetadata>>(() => LoadTableMetadataAsync(key, cancellationToken)));

        return metadata.Value;
    }

    private async Task<TableMetadata> LoadTableMetadataAsync(string tableName, CancellationToken cancellationToken)
    {
        // FIX: Cast IDbConnection to DbConnection to support 'await using' (IAsyncDisposable)
        var connection = context.CreateConnection() as DbConnection
            ?? throw new InvalidOperationException("The database driver does not support asynchronous disposal.");

        await using (connection)
        {
            await connection.OpenAsync(cancellationToken);

            // SQL for column details
            // Postgres 'is_nullable' and 'is_identity' are strings ('YES'/'NO'), 
            // so we compare them to get a boolean for C#
            const string columnSql = """
                SELECT
                    column_name as ColumnName,
                    data_type as DataType,
                    udt_name as UdtName,
                    (is_nullable = 'YES') as IsNullable,
                    column_default as ColumnDefault,
                    (is_identity = 'YES') as IsIdentity,
                    (is_generated <> 'NEVER') as IsGenerated,
                    ordinal_position as OrdinalPosition
                FROM information_schema.columns
                WHERE table_schema = @SchemaName AND table_name = @TableName
                ORDER BY ordinal_position;
                """;

            // SQL for Primary Key columns
            const string primaryKeySql = """
                SELECT kcu.column_name
                FROM information_schema.table_constraints tc
                JOIN information_schema.key_column_usage kcu
                    ON tc.constraint_name = kcu.constraint_name
                   AND tc.table_schema = kcu.table_schema
                   AND tc.table_name = kcu.table_name
                WHERE tc.table_schema = @SchemaName
                  AND tc.table_name = @TableName
                  AND tc.constraint_type = 'PRIMARY KEY'
                ORDER BY kcu.ordinal_position;
                """;

            var columnRows = (await connection.QueryAsync<TableColumnMetadata>(new CommandDefinition(
                columnSql,
                new { SchemaName, TableName = tableName },
                cancellationToken: cancellationToken))).ToArray();

            if (columnRows.Length == 0)
            {
                // If table is not found, we remove it from cache so it can be retried later
                cache.TryRemove(tableName, out _);
                throw new InvalidOperationException($"Table '{SchemaName}.{tableName}' was not found in the database.");
            }

            var primaryKeyColumns = (await connection.QueryAsync<string>(new CommandDefinition(
                primaryKeySql,
                new { SchemaName, TableName = tableName },
                cancellationToken: cancellationToken))).ToArray();

            return new TableMetadata(SchemaName, tableName, columnRows, primaryKeyColumns);
        }
    }
}