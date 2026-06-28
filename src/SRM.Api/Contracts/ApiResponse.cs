namespace SRM.Api.Contracts;

public sealed record ApiResponse<T>
{
    public bool Success { get; init; }

    public string Message { get; init; } = string.Empty;

    public T? Data { get; init; }

    public IReadOnlyList<string> Errors { get; init; } = Array.Empty<string>();

    public static ApiResponse<T> Ok(T? data, string message = "Request completed successfully.")
    {
        return new ApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data,
            Errors = Array.Empty<string>()
        };
    }

    public static ApiResponse<T> Fail(string message, params string[] errors)
    {
        return new ApiResponse<T>
        {
            Success = false,
            Message = message,
            Data = default,
            Errors = errors
        };
    }
}

public sealed record PagedResponse<T>
{
    public required IReadOnlyList<T> Items { get; init; }

    public required int PageNumber { get; init; }

    public required int PageSize { get; init; }

    public required int TotalCount { get; init; }

    public int TotalPages => PageSize <= 0 ? 0 : (int)Math.Ceiling((double)TotalCount / PageSize);
}
