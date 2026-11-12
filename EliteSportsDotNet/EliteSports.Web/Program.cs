using EliteSports.Negocio;
using EliteSports.Repositorio;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllersWithViews();

// Conexao com SQL Server
var connectionString = builder.Configuration
    .GetConnectionString("EliteSports")
    ?? throw new InvalidOperationException(
        "Conexao EliteSports nao configurada."
    );

// Registra repositorio e servico
builder.Services.AddScoped(
    _ => new ProdutoRepositorio(connectionString)
);

builder.Services.AddScoped<ProdutoServico>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.Run();
