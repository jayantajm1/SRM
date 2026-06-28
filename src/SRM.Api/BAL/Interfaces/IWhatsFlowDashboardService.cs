using SRM.Api.Contracts;

namespace SRM.Api.BAL.Interfaces;

public interface IWhatsFlowDashboardService
{
    BusinessProfileResponse GetBusinessProfile();

    DashboardSummaryResponse GetSummary();

    IReadOnlyList<RecentCustomerResponse> GetCustomers();
}