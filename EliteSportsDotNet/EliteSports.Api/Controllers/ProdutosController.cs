
using EliteSports.Modelos;
using EliteSports.Negocio;
using Microsoft.AspNetCore.Mvc;

namespace EliteSports.Api.Controllers;

[ApiController]
[Route("api/produtos")]
public class ProdutosController : ControllerBase
{
    private readonly ProdutoServico _produtoServico;

    public ProdutosController(ProdutoServico produtoServico)
    {
        _produtoServico = produtoServico;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProdutoConsulta>>> Consultar(
        [FromQuery] int? idCategoria = null)
    {
        var produtos = await _produtoServico.ConsultarAsync(idCategoria);

        return Ok(produtos);
    }
}
