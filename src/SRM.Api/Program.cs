using System.Reflection;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Mvc;
using SRM.Api.Contracts;
using SRM.Api.BAL;
using SRM.Api.BAL.Interfaces;
using SRM.Api.DAL.Interfaces;
using SRM.Api.DAL.Repositories;
using SRM.Api.Infrastructure;
using SRM.Api.Infrastructure.Middleware;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "SRM API", Version = "v1" });
});
builder.Services.AddControllers();
builder.Services.AddHttpsRedirection(options =>
{
    options.HttpsPort = 7164;
});
builder.Services.AddSingleton<DapperContext>();
builder.Services.AddSingleton<WhatsFlowDemoData>();
builder.Services.AddSingleton<IBusinessProfileRepository, BusinessProfileRepository>();
builder.Services.AddSingleton<ICustomerRepository, CustomerRepository>();
builder.Services.AddSingleton<IDashboardRepository, DashboardRepository>();
builder.Services.AddSingleton<IWhatsFlowDashboardService, WhatsFlowDashboardService>();

var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];

if (allowedOrigins.Length == 0)
{
    throw new InvalidOperationException("Configuration section 'Cors:AllowedOrigins' must contain at least one origin.");
}

builder.Services.AddCors(options =>
{
    options.AddPolicy("WebApp", policy =>
    {
        policy.WithOrigins(allowedOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "SRM API v1");
        c.RoutePrefix = "swagger";
    });
    app.UseCors("WebApp");
}

app.UseMiddleware<ApiExceptionMiddleware>();
app.UseHttpsRedirection();

app.MapControllers();

app.Run();

public partial class Program
{
}
