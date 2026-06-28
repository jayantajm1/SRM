namespace SRM.Api.Contracts.Crud;

public sealed record CrudRecordResponse(
    string TableName,
    IReadOnlyDictionary<string, object?> Data);

public sealed record CrudCollectionResponse(
    string TableName,
    IReadOnlyList<CrudRecordResponse> Items,
    int PageNumber,
    int PageSize,
    int TotalCount,
    int TotalPages);
