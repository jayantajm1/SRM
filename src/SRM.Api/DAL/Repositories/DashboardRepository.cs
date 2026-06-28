using SRM.Api.Contracts;
using SRM.Api.DAL.Interfaces;
using SRM.Api.Infrastructure;

namespace SRM.Api.DAL.Repositories;

public sealed class DashboardRepository(WhatsFlowDemoData demoData) : IDashboardRepository
{
    public DashboardSummaryResponse GetSummary()
    {
        return new DashboardSummaryResponse(
            TodayFollowUps: 14,
            UpcomingAppointments: 7,
            MonthlyRevenue: 284500m,
            PendingPayments: 92800m,
            ActiveCustomers: 148,
            NewLeads: 37,
            BroadcastStatus: "2 campaigns scheduled",
            LeadConversionRate: 18.4m,
            CustomerGrowthRate: 12.7m,
            RecentCustomers: demoData.Customers,
            RecentActivities: demoData.Activities);
    }
}