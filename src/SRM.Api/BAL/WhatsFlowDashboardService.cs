using SRM.Api.Contracts;
using SRM.Api.BAL.Interfaces;
using SRM.Api.DAL.Interfaces;

namespace SRM.Api.BAL;

public sealed class WhatsFlowDashboardService(
    IBusinessProfileRepository businessProfileRepository,
    IDashboardRepository dashboardRepository,
    ICustomerRepository customerRepository) : IWhatsFlowDashboardService
{
    public BusinessProfileResponse GetBusinessProfile()
    {
        return businessProfileRepository.GetBusinessProfile();
    }

    public DashboardSummaryResponse GetSummary()
    {
        return dashboardRepository.GetSummary();
    }

    public IReadOnlyList<RecentCustomerResponse> GetCustomers()
    {
        return customerRepository.GetCustomers();
    }
}