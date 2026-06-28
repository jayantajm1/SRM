using System.Collections.Concurrent;
using Dapper;
using SRM.Api.Infrastructure;

namespace SRM.Api.Infrastructure.Crud;

public sealed class TableMetadataProvider(DapperContext context) : ITableMetadataProvider
{
    private const string SchemaName = "whatsflow";
    private readonly ConcurrentDictionary<string, Lazy<Task<TableMetadata>>> cache = new(StringComparer.OrdinalIgnoreCase);

    public Task<TableMetadata> GetTableMetadataAsync(string tableName, CancellationToken cancellationToken = default)
    {
        var normalizedName = tableName.Trim();
        if (string.IsNullOrWhiteSpace(normalizedName))
        {
            throw new ArgumentException("Table name is required.", nameof(tableName));
        }

        var metadata = cache.GetOrAdd(normalizedName, key => new Lazy<Task<TableMetadata>>(() => LoadTableMetadataAsync(key, cancellationToken)));
        return metadata.Value;
    }

    private async Task<TableMetadata> LoadTableMetadataAsync(string tableName, CancellationToken cancellationToken)
    {
        await using var connection = context.CreateConnection();
        await connection.OpenAsync(cancellationToken);

        const string columnSql = """
            select
                column_name as ColumnName,
                data_type as DataType,
                udt_name as UdtName,
                is_nullable = 'YES' as IsNullable,
                column_default as ColumnDefault,
                is_identity = 'YES' as IsIdentity,
                is_generated <> 'NEVER' as IsGenerated,
                ordinal_position as OrdinalPosition
            from information_schema.columns
            where table_schema = @SchemaName and table_name = @TableName
            order by ordinal_position;
            """;

        const string primaryKeySql = """
            select kcu.column_name
            from information_schema.table_constraints tc
            join information_schema.key_column_usage kcu
                on tc.constraint_name = kcu.constraint_name
               and tc.table_schema = kcu.table_schema
               and tc.table_name = kcu.table_name
            where tc.table_schema = @SchemaName
              and tc.table_name = @TableName
              and tc.constraint_type = 'PRIMARY KEY'
            order by kcu.ordinal_position;
            """;

        var columnRows = (await connection.QueryAsync<TableColumnMetadata>(new CommandDefinition(
            columnSql,
            new { SchemaName, TableName = tableName },
            cancellationToken: cancellationToken))).ToArray();

        if (columnRows.Length == 0)
        {
            throw new InvalidOperationException($"Table '{SchemaName}.{tableName}' was not found.");
        }

        var primaryKeyColumns = (await connection.QueryAsync<string>(new CommandDefinition(
            primaryKeySql,
            new { SchemaName, TableName = tableName },
            cancellationToken: cancellationToken))).ToArray();

        return new TableMetadata(SchemaName, tableName, columnRows, primaryKeyColumns);
    }
}
