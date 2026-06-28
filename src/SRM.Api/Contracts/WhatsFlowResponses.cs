namespace SRM.Api.Contracts;

public sealed record DashboardSummaryResponse(
    int TodayFollowUps,
    int UpcomingAppointments,
    decimal MonthlyRevenue,
    decimal PendingPayments,
    int ActiveCustomers,
    int NewLeads,
    string BroadcastStatus,
    decimal LeadConversionRate,
    decimal CustomerGrowthRate,
    IReadOnlyList<RecentCustomerResponse> RecentCustomers,
    IReadOnlyList<RecentActivityResponse> RecentActivities);

public sealed record RecentCustomerResponse(
    int Id,
    string Name,
    string Industry,
    string City,
    string PhoneNumber,
    string Status,
    DateTimeOffset LastContactedAtUtc,
    string[] Labels);

public sealed record RecentActivityResponse(
    string Message,
    DateTimeOffset OccurredAtUtc);