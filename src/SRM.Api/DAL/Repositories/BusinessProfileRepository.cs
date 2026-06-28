using SRM.Api.Contracts;
using SRM.Api.DAL.Interfaces;
using SRM.Api.Infrastructure;

namespace SRM.Api.DAL.Repositories;

public sealed class BusinessProfileRepository(WhatsFlowDemoData demoData) : IBusinessProfileRepository
{
    public BusinessProfileResponse GetBusinessProfile()
    {
        return demoData.BusinessProfile;
    }
}