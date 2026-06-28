using SRM.Api.Contracts;

namespace SRM.Api.DAL.Interfaces;

public interface ICustomerRepository
{
    IReadOnlyList<RecentCustomerResponse> GetCustomers();
}