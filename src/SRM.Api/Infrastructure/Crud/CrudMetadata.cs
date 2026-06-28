namespace SRM.Api.Infrastructure.Crud;

public sealed record TableColumnMetadata(
    string ColumnName,
    string DataType,
    string UdtName,
    bool IsNullable,
    string? ColumnDefault,
    bool IsIdentity,
    bool IsGenerated,
    int OrdinalPosition)
{
    public bool IsWritable => !IsIdentity && !IsGenerated;
}

public sealed record TableMetadata(
    string SchemaName,
    string TableName,
    IReadOnlyList<TableColumnMetadata> Columns,
    IReadOnlyList<string> PrimaryKeyColumns)
{
    public TableColumnMetadata? FindColumn(string columnName)
    {
        return Columns.FirstOrDefault(column => column.ColumnName.Equals(columnName, StringComparison.OrdinalIgnoreCase));
    }

    public IReadOnlyList<TableColumnMetadata> WritableColumns => Columns.Where(column => column.IsWritable).ToArray();

    public IReadOnlyList<TableColumnMetadata> InsertableColumns => Columns.Where(column => column.IsWritable).ToArray();

    public IReadOnlyList<TableColumnMetadata> UpdatableColumns => Columns.Where(column => column.IsWritable && !PrimaryKeyColumns.Contains(column.ColumnName, StringComparer.OrdinalIgnoreCase)).ToArray();

    public IReadOnlyList<TableColumnMetadata> RequiredInsertColumns => Columns.Where(column => column.IsWritable && !column.IsNullable && column.ColumnDefault is null && !PrimaryKeyColumns.Contains(column.ColumnName, StringComparer.OrdinalIgnoreCase)).ToArray();
}

public interface ITableMetadataProvider
{
    Task<TableMetadata> GetTableMetadataAsync(string tableName, CancellationToken cancellationToken = default);
}
