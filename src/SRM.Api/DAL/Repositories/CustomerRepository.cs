using SRM.Api.Contracts;
using SRM.Api.DAL.Interfaces;
using SRM.Api.Infrastructure;

namespace SRM.Api.DAL.Repositories;

public sealed class CustomerRepository(WhatsFlowDemoData demoData) : ICustomerRepository
{
    public IReadOnlyList<RecentCustomerResponse> GetCustomers()
    {
        return demoData.Customers;
    }
}