
namespace EliteSports.Modelos;

public class ProdutoConsulta
{
    public int IdProduto { get; set; }
    public string Nome { get; set; } = string.Empty;
    public string? Descricao { get; set; }
    public decimal Preco { get; set; }
    public bool Ativo { get; set; }

    public string? Imagem { get; set; }
    public string Categoria { get; set; } = string.Empty;
}
