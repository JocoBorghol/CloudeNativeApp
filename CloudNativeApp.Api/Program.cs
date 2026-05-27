using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddOpenApi();

//builder.Services.AddCors(options =>
//{
//    options.AddPolicy("StrictSecurityPolicy", policyBuilder =>
//    {
//        policyBuilder.WithOrigins("https://min-sakra-frontend-app.azurewebsites.net")
//                     .WithMethods("GET", "POST")
//                     .AllowAnyHeader();
//    });
//});

builder.Services.AddCors(options =>
{
    options.AddPolicy("StrictSecurityPolicy", policyBuilder =>
    {
        policyBuilder.WithOrigins("null")
                     .WithMethods("GET", "POST")
                     .AllowAnyHeader();
    });
});

var keyVaultUrl = builder.Configuration["KeyVaultUrl"];

if (!string.IsNullOrEmpty(keyVaultUrl))
{
    builder.Configuration.AddAzureKeyVault(
        new Uri(keyVaultUrl),
        new DefaultAzureCredential());
}

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

//viktigt att CORS den ligger efter app.UseHttpsRedirection(); och innan app.UseAuthorization();
//app.UseCors("StrictSecurityPolicy");

if (app.Environment.IsDevelopment())
{
    app.UseCors("StrictSecurityPolicy");
}

app.UseAuthorization();

app.MapControllers();

app.Run();