using SRM.Api.Contracts;
using SRM.Api.Contracts.Crud;

namespace SRM.Api.BAL.Interfaces;

public interface ICrudService
{
    Task<PagedResponse<CrudRecordResponse>> GetPagedAsync(string tableName, CrudListRequest request, CancellationToken cancellationToken = default);

    Task<CrudRecordResponse?> FindByKeysAsync(string tableName, CrudKeyRequest request, CancellationToken cancellationToken = default);

    Task<CrudRecordResponse> CreateAsync(string tableName, CrudValuesRequest request, CancellationToken cancellationToken = default);

    Task<CrudRecordResponse?> UpdateAsync(string tableName, CrudUpsertRequest request, CancellationToken cancellationToken = default);

    Task<bool> DeleteAsync(string tableName, CrudKeyRequest request, CancellationToken cancellationToken = default);
}
