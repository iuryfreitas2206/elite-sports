using EliteSports.Negocio;
using Microsoft.AspNetCore.Mvc;

namespace EliteSports.Web.Controllers;

public class ProdutosController : Controller
{
    private readonly ProdutoServico _servico;

    public ProdutosController(ProdutoServico servico)
    {
        _servico = servico;
    }

    public async Task<IActionResult> Index()
    {
        var produtos = await _servico.ConsultarAsync();

        return View(produtos);
    }
}