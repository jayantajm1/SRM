using Microsoft.AspNetCore.Mvc;
using SRM.Api.Contracts;
using SRM.Api.BAL.Interfaces;

namespace SRM.Api.Controllers;

[ApiController]
[Route("api/business/profile")]
public sealed class BusinessProfileController(IWhatsFlowDashboardService dashboardService) : ControllerBase
{
    [HttpGet]
    public ActionResult<BusinessProfileResponse> Get()
    {
        return Ok(dashboardService.GetBusinessProfile());
    }
}