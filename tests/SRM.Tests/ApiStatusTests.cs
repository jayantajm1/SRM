using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using SRM.Api.Contracts;

namespace SRM.Tests;

public sealed class ApiStatusTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient client;

    public ApiStatusTests(WebApplicationFactory<Program> factory)
    {
        client = factory.CreateClient();
    }

    [Fact]
    public async Task StatusEndpointReturnsApplicationMetadata()
    {
        var response = await client.GetAsync("/api/status");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var payload = await response.Content.ReadFromJsonAsync<AppStatusResponse>();

        Assert.NotNull(payload);
        Assert.Equal("WhatsFlow CRM", payload!.Application);
        Assert.Contains("OpenAPI", payload.Capabilities);
    }
}