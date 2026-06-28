using SRM.Api.Contracts;

namespace SRM.Api.DAL.Interfaces;

public interface IBusinessProfileRepository
{
    BusinessProfileResponse GetBusinessProfile();
}