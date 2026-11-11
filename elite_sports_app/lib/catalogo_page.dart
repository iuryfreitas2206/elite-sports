import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'produto_page.dart';
import 'login_page.dart';
import 'minha_conta_page.dart';
import 'sessao_usuario.dart';
import 'carrinho_page.dart';

// ==========================================
// DADOS DOS PRODUTOS DO SITE
// ==========================================

class _ProdutoSite {
  final String nome;
  final String nomeBanco;
  final String imagem;
  final String tipo;
  final String? imagemAlternativa;

  const _ProdutoSite(
    this.nome,
    this.nomeBanco,
    this.imagem,
    this.tipo, {
    this.imagemAlternativa,
  });
}

class CatalogoPage extends StatefulWidget {
  final String categoria;

  const CatalogoPage({super.key, required this.categoria});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  static const String apiBase =
      'https://elite-sports-production.up.railway.app';

  static const Color fundo = Color(0xFF0D0D12);
  static const Color card = Color(0xFF17171C);
  static const Color roxo = Color(0xFF7B2CFF);
  static const Color roxoClaro = Color(0xFFA855F7);
  static const Color cinza = Color(0xFF9292A5);
  static const Color borda = Color(0xFF303038);

  final buscaController = TextEditingController();

  List<Map<String, dynamic>> produtosBanco = [];

  bool carregando = true;
  String? erro;
  String filtroAtivo = 'Todos';
  late String categoriaAtual;
  String busca = '';

  // ==========================================
  // PRODUTOS DAS TRÊS CATEGORIAS
  // ==========================================

  List<_ProdutoSite> get produtosSite {
    switch (categoriaAtual) {
      case 'Camisetas':
        return const [
          _ProdutoSite(
            'Camiseta Dry Fit',
            'Camiseta Dry Fit',
            'assets/img/camiseta-dryfit/DryFit-azul-1.png',
            'Dry Fit',
          ),
          _ProdutoSite(
            'Camiseta Treino',
            'Camiseta Treino',
            'assets/img/camiseta-treino/Camiseta treino-preta-1.png',
            'Treino',
          ),
          _ProdutoSite(
            'Regata Fitness',
            'Regata Fitness',
            'assets/img/regata/regata-Preta-1.png',
            'Regatas',
            imagemAlternativa: 'assets/img/regata/regata-Preta-1.png',
          ),
        ];

      case 'Shorts':
        return const [
          _ProdutoSite(
            'Short Esportivo',
            'Short Esportivo',
            'assets/img/short-esportivo/Short-Preto-1.png',
            'Esportivo',
          ),
          _ProdutoSite(
            'Chuteira Elite Speed',
            'Chuteira Elite Speed',
            'assets/img/acessorios/chuteira-preta-1.png',
            'Esportivo',
          ),
        ];

      case 'Acessórios':
        return const [
          _ProdutoSite(
            'Bola Elite Nations',
            'Bola Elite Nations',
            'assets/img/acessorios/Bola_futebol_1.png',
            'Bolas',
          ),
          _ProdutoSite(
            'Bola Elite Stars',
            'Bola Elite Stars',
            'assets/img/acessorios/Bola_futebol_2.png',
            'Bolas',
          ),
          _ProdutoSite(
            'Bola Elite Pro',
            'Bola Elite Pro',
            'assets/img/acessorios/Bola_futebol_3.png',
            'Bolas',
          ),
          _ProdutoSite(
            'Garrafa Esportiva Elite 750ml',
            'Garrafa Esportiva Elite 750ml',
            'assets/img/acessorios/Garrafa_preta_1.png',
            'Garrafas',
          ),
          _ProdutoSite(
            'Bolsa Esportiva Elite',
            'Bolsa Esportiva Elite',
            'assets/img/acessorios/Bolsa_preta_1.png',
            'Bolsas e Mochilas',
          ),
          _ProdutoSite(
            'Mochila Esportiva Elite',
            'Mochila Esportiva Elite',
            'assets/img/acessorios/Mochila_preta_1.png',
            'Bolsas e Mochilas',
          ),
          _ProdutoSite(
            'Meia Esportiva Elite',
            'Meia Esportiva Elite',
            'assets/img/acessorios/Meia_branca_1.png',
            'Meias',
          ),
        ];

      default:
        return const [];
    }
  }

  List<String> get filtros {
    switch (categoriaAtual) {
      case 'Camisetas':
        return const ['Todos', 'Dry Fit', 'Treino', 'Regatas'];
      case 'Shorts':
        return const ['Todos', 'Esportivo'];
      case 'Acessórios':
        return const [
          'Todos',
          'Bolas',
          'Garrafas',
          'Bolsas e Mochilas',
          'Meias',
        ];
      default:
        return const ['Todos'];
    }
  }

  String get descricao {
    switch (categoriaAtual) {
      case 'Camisetas':
        return 'Performance, conforto e estilo para acompanhar todos os seus treinos.';
      case 'Shorts':
        return 'Liberdade de movimento, conforto e performance para acompanhar seus treinos.';
      case 'Acessórios':
        return 'Complete seu treino com acessórios para sua rotina dentro e fora do esporte.';
      default:
        return '';
    }
  }

  // ==========================================
  // INICIALIZAÇÃO
  // ==========================================

  @override
  void initState() {
    super.initState();
    categoriaAtual = widget.categoria;
    carregarProdutos();
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  // ==========================================
  // CONSULTAR MYSQL ATRAVÉS DA API
  // ==========================================

  Future<void> carregarProdutos() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final resposta = await http
          .get(Uri.parse('$apiBase/api/produtos'))
          .timeout(const Duration(seconds: 20));

      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw Exception('Não foi possível consultar os produtos.');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! List) {
        throw const FormatException('Resposta de produtos inválida.');
      }

      final lista = <Map<String, dynamic>>[];

      for (final produto in dados) {
        if (produto is Map) {
          lista.add(Map<String, dynamic>.from(produto));
        }
      }

      if (!mounted) return;

      setState(() {
        produtosBanco = lista;
        carregando = false;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = 'O servidor demorou para responder.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erro = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==========================================
  // LOCALIZAR PRODUTO NO BANCO
  // ==========================================

  Map<String, dynamic>? encontrarProduto(_ProdutoSite produto) {
    for (final item in produtosBanco) {
      final nome = item['nome']?.toString().trim().toLowerCase();

      if (nome == produto.nomeBanco.toLowerCase()) {
        return item;
      }
    }

    return null;
  }

  // ==========================================
  // FORMATAR PREÇO
  // ==========================================

  String formatarPreco(dynamic valor) {
    final numero = double.tryParse(valor?.toString() ?? '');

    if (numero == null || !numero.isFinite) {
      return 'Preço indisponível';
    }

    final partes = numero.toStringAsFixed(2).split('.');
    final inteiro = partes[0];

    final caracteres = StringBuffer();

    for (int i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        caracteres.write('.');
      }
      caracteres.write(inteiro[i]);
    }

    return 'R\$ ${caracteres.toString()},${partes[1]}';
  }

  // ==========================================
  // SOMAR ESTOQUE DAS VARIAÇÕES
  // ==========================================

  int estoqueTotal(Map<String, dynamic> produto) {
    final variacoes = produto['variacoes'];

    if (variacoes is! List) return 0;

    int total = 0;

    for (final variacao in variacoes) {
      if (variacao is Map) {
        final quantidade =
            num.tryParse(variacao['estoque']?.toString() ?? '') ?? 0;

        total += quantidade.toInt();
      }
    }

    return total;
  }

  // ==========================================
  // FILTROS E BUSCA
  // ==========================================

  List<_ProdutoSite> get produtosFiltrados {
    return produtosSite.where((produto) {
      final correspondeFiltro =
          filtroAtivo == 'Todos' || produto.tipo == filtroAtivo;

      final correspondeBusca = produto.nome.toLowerCase().contains(
        busca.toLowerCase().trim(),
      );

      return correspondeFiltro && correspondeBusca;
    }).toList();
  }

  void mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // ==========================================
  // ABRIR DETALHES DO PRODUTO
  // ==========================================

  void abrirDetalhes(_ProdutoSite produto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProdutoPage(
          nomeProduto: produto.nome,
          imagemInicial: produto.imagem,
        ),
      ),
    );
  }

  // ==========================================
  // VOLTAR PARA A TELA INICIAL
  // ==========================================

  void _irInicio() {
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  // ==========================================
  // TROCAR DE CATEGORIA SEM ABRIR NOVA TELA
  // ==========================================

  void _trocarCategoria(String categoria) {
    if (categoria == 'Início') {
      _irInicio();
      return;
    }

    if (categoria == categoriaAtual) return;

    buscaController.clear();

    setState(() {
      categoriaAtual = categoria;
      filtroAtivo = 'Todos';
      busca = '';
    });
  }

  // ==========================================
  // ABRIR MINHA CONTA OU LOGIN
  // ==========================================

  Future<void> _abrirContaCabecalho() async {
    final usuario = await SessaoUsuario.ler();

    if (!mounted) return;

    if (usuario == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MinhaContaPage()),
      );
    }
  }

  // ==========================================
  // ABRIR CARRINHO
  // ==========================================

  void _abrirCarrinhoCabecalho() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CarrinhoPage()),
    );
  }

  // ==========================================
  // TELA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 68,
        titleSpacing: 18,

        // LOGO DA ELITE SPORTS
        title: InkWell(
          onTap: _irInicio,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/img/logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 9),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Elite ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'Sports',
                      style: TextStyle(
                        color: Color(0xFFA855F7),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),

        // ÍCONES DA CONTA E DO CARRINHO
        actions: [
          IconButton(
            tooltip: 'Minha conta',
            onPressed: _abrirContaCabecalho,
            icon: const Icon(Icons.person_outline, size: 23),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Carrinho',
            onPressed: _abrirCarrinhoCabecalho,
            icon: const Icon(Icons.shopping_cart_outlined, size: 23),
          ),
          const SizedBox(width: 12),
        ],

        // MENU DE CATEGORIAS
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF101013),
              border: Border(
                top: BorderSide(color: Color(0xFF24242A)),
                bottom: BorderSide(color: Color(0xFF24242A)),
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final categoria in const [
                      'Início',
                      'Camisetas',
                      'Shorts',
                      'Acessórios',
                    ])
                      InkWell(
                        onTap: () => _trocarCategoria(categoria),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: categoriaAtual == categoria
                                    ? roxo
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            categoria,
                            style: TextStyle(
                              color: categoriaAtual == categoria
                                  ? Colors.white
                                  : const Color(0xFFAAAAAF),
                              fontSize: 14,
                              fontWeight: categoriaAtual == categoria
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [construirBanner(), construirConteudo()]),
        ),
      ),
    );
  }

  // ==========================================
  // BANNER DA CATEGORIA
  // ==========================================

  Widget construirBanner() {
    final celular = MediaQuery.sizeOf(context).width < 700;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: celular ? 20 : 50,
        vertical: celular ? 45 : 65,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF191126), Color(0xFF0D0D12)],
        ),
        border: Border(bottom: BorderSide(color: borda)),
      ),
      child: Column(
        children: [
          const Text(
            'ELITE SPORTS',
            style: TextStyle(
              color: roxoClaro,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            categoriaAtual.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: celular ? 35 : 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              descricao,
              textAlign: TextAlign.center,
              style: const TextStyle(color: cinza, fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CATÁLOGO, PESQUISA E FILTROS
  // ==========================================

  Widget construirConteudo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 35),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: buscaController,
                onChanged: (valor) {
                  setState(() {
                    busca = valor;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar em ${categoriaAtual.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFF19191F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filtro in filtros) ...[
                      ChoiceChip(
                        label: Text(filtro),
                        selected: filtroAtivo == filtro,
                        onSelected: (_) {
                          setState(() {
                            filtroAtivo = filtro;
                          });
                        },
                        selectedColor: roxo,
                        backgroundColor: card,
                        labelStyle: TextStyle(
                          color: filtroAtivo == filtro ? Colors.white : cinza,
                        ),
                        side: const BorderSide(color: borda),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (carregando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(color: roxo),
                  ),
                )
              else if (erro != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      erro!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: carregarProdutos,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                )
              else
                construirGrade(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // GRADE RESPONSIVA DE PRODUTOS
  // ==========================================

  Widget construirGrade() {
    final produtos = produtosFiltrados;

    if (produtos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(45),
          child: Text(
            'Nenhum produto encontrado.',
            style: TextStyle(color: cinza),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final largura = constraints.maxWidth;

        final colunas = largura >= 950
            ? 3
            : largura >= 600
            ? 2
            : 1;

        const espacamento = 22.0;

        final larguraCard = (largura - espacamento * (colunas - 1)) / colunas;

        return Wrap(
          spacing: espacamento,
          runSpacing: espacamento,
          children: [
            for (final produto in produtos)
              SizedBox(width: larguraCard, child: construirCard(produto)),
          ],
        );
      },
    );
  }

  // ==========================================
  // CARD INDIVIDUAL DO PRODUTO
  // ==========================================

  Widget construirCard(_ProdutoSite produto) {
    final dados = encontrarProduto(produto);

    final estoque = dados == null ? 0 : estoqueTotal(dados);

    final disponivel = dados != null && estoque > 0;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 235,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF22222A), Color(0xFF17171C)],
              ),
            ),
            child: construirImagem(produto),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produto.tipo.toUpperCase(),
                  style: const TextStyle(
                    color: roxoClaro,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  produto.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  dados == null
                      ? 'Preço indisponível'
                      : formatarPreco(dados['preco']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  dados == null
                      ? 'Produto não encontrado no banco'
                      : disponivel
                      ? 'Em estoque'
                      : 'Produto esgotado',
                  style: TextStyle(
                    color: disponivel
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFFF7070),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: disponivel ? () => abrirDetalhes(produto) : null,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(disponivel ? 'Ver produto' : 'Indisponível'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF09090D),
                      side: const BorderSide(color: borda),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // IMAGENS DOS PRODUTOS
  // ==========================================

  Widget construirImagem(_ProdutoSite produto) {
    return Image.asset(
      produto.imagem,
      fit: BoxFit.contain,
      errorBuilder: (context, erro, stackTrace) {
        if (produto.imagemAlternativa != null) {
          return Image.asset(
            produto.imagemAlternativa!,
            fit: BoxFit.contain,
            errorBuilder: (context, erro, stackTrace) {
              return const Icon(
                Icons.image_not_supported_outlined,
                size: 50,
                color: cinza,
              );
            },
          );
        }

        return const Icon(
          Icons.image_not_supported_outlined,
          size: 50,
          color: cinza,
        );
      },
    );
  }
}
