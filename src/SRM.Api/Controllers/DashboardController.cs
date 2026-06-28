using Microsoft.AspNetCore.Mvc;
using SRM.Api.Contracts;
using SRM.Api.BAL.Interfaces;

namespace SRM.Api.Controllers;

[ApiController]
[Route("api/dashboard")]
public sealed class DashboardController(IWhatsFlowDashboardService dashboardService) : ControllerBase
{
    [HttpGet("summary")]
    public ActionResult<DashboardSummaryResponse> GetSummary()
    {
        return Ok(dashboardService.GetSummary());
    }
}