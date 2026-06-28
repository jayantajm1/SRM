using Microsoft.AspNetCore.Mvc;
using SRM.Api.Contracts;
using SRM.Api.BAL.Interfaces;

namespace SRM.Api.Controllers;

[ApiController]
[Route("api/customers")]
public sealed class CustomersController(IWhatsFlowDashboardService dashboardService) : ControllerBase
{
    [HttpGet]
    public ActionResult<IReadOnlyList<RecentCustomerResponse>> Get()
    {
        return Ok(dashboardService.GetCustomers());
    }
}