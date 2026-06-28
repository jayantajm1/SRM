using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using SRM.Api.Contracts;

namespace SRM.Tests;

public sealed class WhatsFlowDashboardTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient client;

    public WhatsFlowDashboardTests(WebApplicationFactory<Program> factory)
    {
        client = factory.CreateClient();
    }

    [Fact]
    public async Task DashboardSummaryReturnsSeededMetrics()
    {
        var summary = await client.GetFromJsonAsync<DashboardSummaryResponse>("/api/dashboard/summary");

        Assert.NotNull(summary);
        Assert.Equal(14, summary!.TodayFollowUps);
        Assert.True(summary.ActiveCustomers > 0);
        Assert.NotEmpty(summary.RecentCustomers);
    }

    [Fact]
    public async Task CustomersEndpointReturnsSeededCustomers()
    {
        var customers = await client.GetFromJsonAsync<List<RecentCustomerResponse>>("/api/customers");

        Assert.NotNull(customers);
        Assert.NotEmpty(customers!);
        Assert.Contains(customers, customer => customer.Name == "Asha Fitness");
    }
}