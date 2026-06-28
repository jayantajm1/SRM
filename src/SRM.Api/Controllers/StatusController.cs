using System.Reflection;
using Microsoft.AspNetCore.Mvc;
using SRM.Api.Contracts;

namespace SRM.Api.Controllers;

[ApiController]
[Route("api/status")]
public sealed class StatusController : ControllerBase
{
    [HttpGet]
    public ActionResult<AppStatusResponse> Get()
    {
        var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "unknown";

        return Ok(new AppStatusResponse(
            Application: "WhatsFlow CRM",
            Environment: HttpContext.RequestServices.GetRequiredService<IHostEnvironment>().EnvironmentName,
            Version: version,
            TimestampUtc: DateTimeOffset.UtcNow,
            Capabilities: ["Angular dashboard", "ASP.NET Core API", "xUnit test project", "OpenAPI"]
        ));
    }
}