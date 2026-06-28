using SRM.Api.Contracts;

namespace SRM.Api.Infrastructure;

public sealed class WhatsFlowDemoData
{
    public BusinessProfileResponse BusinessProfile { get; } = new(
        "Asha Wellness Studio",
        "Meera Shah",
        "Fitness & Wellness",
        "Mumbai",
        "+91 98765 43210",
        "Asia/Kolkata",
        "Growth",
        6,
        DateTimeOffset.UtcNow.AddDays(-18));

    public IReadOnlyList<RecentCustomerResponse> Customers { get; } =
    [
        new(1, "Asha Fitness", "Gym", "Mumbai", "+91 98765 43210", "Hot Lead", DateTimeOffset.UtcNow.AddHours(-2), ["Hot Lead", "Follow-up"]),
        new(2, "GreenLeaf Salon", "Salon", "Pune", "+91 98980 12345", "Active", DateTimeOffset.UtcNow.AddHours(-6), ["VIP", "Paid"]),
        new(3, "Bright Minds Tuition", "Tuition", "Nagpur", "+91 91234 56789", "Needs Follow-up", DateTimeOffset.UtcNow.AddDays(-1), ["New", "Follow-up"]),
        new(4, "Medico Care", "Clinic", "Nashik", "+91 99887 77665", "Active", DateTimeOffset.UtcNow.AddHours(-8), ["Returning"]),
        new(5, "Urban Furnish", "Furniture", "Thane", "+91 97654 32109", "Pending Payment", DateTimeOffset.UtcNow.AddDays(-2), ["Pending", "Invoice"])
    ];

    public IReadOnlyList<RecentActivityResponse> Activities { get; } =
    [
        new("WhatsApp follow-up sent to Asha Fitness", DateTimeOffset.UtcNow.AddMinutes(-18)),
        new("New lead created from Instagram click-to-chat", DateTimeOffset.UtcNow.AddMinutes(-42)),
        new("Payment reminder scheduled for Urban Furnish", DateTimeOffset.UtcNow.AddHours(-1)),
        new("Appointment confirmed for GreenLeaf Salon", DateTimeOffset.UtcNow.AddHours(-2))
    ];
}