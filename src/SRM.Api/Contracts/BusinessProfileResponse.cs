namespace SRM.Api.Contracts;

public sealed record BusinessProfileResponse(
    string BusinessName,
    string OwnerName,
    string Industry,
    string City,
    string PrimaryPhoneNumber,
    string Timezone,
    string PlanName,
    int TeamSize,
    DateTimeOffset OnboardedAtUtc);