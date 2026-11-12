using EliteSports.Negocio;
using EliteSports.Repositorio;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Conexao local com o SQL Server
var connectionString = builder.Configuration
    .GetConnectionString("EliteSports")
    ?? throw new InvalidOperationException(
        "A conexao EliteSports nao foi configurada."
    );

// Registra o repositorio e a camada de negocio
builder.Services.AddScoped(
    _ => new ProdutoRepositorio(connectionString)
);

builder.Services.AddScoped<ProdutoServico>();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
