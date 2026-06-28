namespace SRM.Api.Contracts;

public sealed record AppStatusResponse(
    string Application,
    string Environment,
    string Version,
    DateTimeOffset TimestampUtc,
    string[] Capabilities);