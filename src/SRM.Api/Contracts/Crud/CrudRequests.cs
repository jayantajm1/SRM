using System.ComponentModel.DataAnnotations;
using System.Text.Json;

namespace SRM.Api.Contracts.Crud;

public sealed class CrudListRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Page number must be greater than zero.")]
    public int PageNumber { get; init; } = 1;

    [Range(1, 200, ErrorMessage = "Page size must be between 1 and 200.")]
    public int PageSize { get; init; } = 20;
}

public sealed class CrudValuesRequest : IValidatableObject
{
    [Required(ErrorMessage = "Values are required.")]
    public Dictionary<string, JsonElement> Values { get; init; } = new(StringComparer.OrdinalIgnoreCase);

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (Values.Count == 0)
        {
            yield return new ValidationResult("At least one field must be provided.", [nameof(Values)]);
        }
    }
}

public sealed class CrudKeyRequest : IValidatableObject
{
    [Required(ErrorMessage = "Keys are required.")]
    public Dictionary<string, JsonElement> Keys { get; init; } = new(StringComparer.OrdinalIgnoreCase);

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (Keys.Count == 0)
        {
            yield return new ValidationResult("At least one key must be provided.", [nameof(Keys)]);
        }
    }
}

public sealed class CrudUpsertRequest : IValidatableObject
{
    [Required(ErrorMessage = "Keys are required.")]
    public Dictionary<string, JsonElement> Keys { get; init; } = new(StringComparer.OrdinalIgnoreCase);

    [Required(ErrorMessage = "Values are required.")]
    public Dictionary<string, JsonElement> Values { get; init; } = new(StringComparer.OrdinalIgnoreCase);

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (Keys.Count == 0)
        {
            yield return new ValidationResult("At least one key must be provided.", [nameof(Keys)]);
        }

        if (Values.Count == 0)
        {
            yield return new ValidationResult("At least one field must be provided.", [nameof(Values)]);
        }
    }
}
