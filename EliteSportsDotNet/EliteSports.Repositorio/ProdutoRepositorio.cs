
using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using EliteSports.Modelos;

namespace EliteSports.Repositorio;

public class ProdutoRepositorio
{
    private readonly string _connectionString;

    static ProdutoRepositorio()
    {
        DefaultTypeMap.MatchNamesWithUnderscores = true;
    }

    public ProdutoRepositorio(string connectionString)
    {
        _connectionString = connectionString;
    }

    public async Task<IEnumerable<ProdutoConsulta>> ConsultarAsync(
        int? idCategoria = null)
    {
        using var conexao = new SqlConnection(_connectionString);

        return await conexao.QueryAsync<ProdutoConsulta>(
            "dbo.usp_consultar_produtos",
            new { id_categoria = idCategoria },
            commandType: CommandType.StoredProcedure
        );
    }
}
