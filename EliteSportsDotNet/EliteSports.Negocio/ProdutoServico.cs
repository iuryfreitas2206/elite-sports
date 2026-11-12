
using EliteSports.Modelos;
using EliteSports.Repositorio;

namespace EliteSports.Negocio;

public class ProdutoServico
{
    private readonly ProdutoRepositorio _repositorio;

    public ProdutoServico(ProdutoRepositorio repositorio)
    {
        _repositorio = repositorio;
    }

    public async Task<IEnumerable<ProdutoConsulta>> ConsultarAsync(
        int? idCategoria = null)
    {
        return await _repositorio.ConsultarAsync(idCategoria);
    }
}
