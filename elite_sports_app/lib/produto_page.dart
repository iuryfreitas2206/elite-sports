import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'carrinho_page.dart';

class ProdutoPage extends StatefulWidget {
  final String nomeProduto;
  final String? imagemInicial;

  const ProdutoPage({super.key, required this.nomeProduto, this.imagemInicial});

  @override
  State<ProdutoPage> createState() => _ProdutoPageState();
}

class _ProdutoPageState extends State<ProdutoPage> {
  static const String apiBase =
      'https://elite-sports-production.up.railway.app';

  static const String chaveCarrinho = 'carrinho_flutter_v1';

  static const Color fundo = Color(0xFF0D0D12);
  static const Color card = Color(0xFF17171C);
  static const Color borda = Color(0xFF303038);
  static const Color roxo = Color(0xFF7B2CFF);
  static const Color roxoClaro = Color(0xFFA855F7);
  static const Color cinza = Color(0xFF9292A5);

  Map<String, dynamic>? produtoBanco;
  List<Map<String, dynamic>> variacoes = [];

  String? corSelecionada;
  String? tamanhoSelecionado;

  int quantidade = 1;
  int fotoAtual = 0;

  bool carregando = true;
  bool salvando = false;
  String? erro;

  // ==========================================
  // GALERIAS ORIGINAIS DO SITE
  // ==========================================

  static const galerias = <String, Map<String, List<String>>>{
    'Camiseta Dry Fit': {
      'azul': [
        'assets/img/camiseta-dryfit/DryFit-azul-1.png',
        'assets/img/camiseta-dryfit/DryFit-azul-2.png',
        'assets/img/camiseta-dryfit/DryFit-azul-3.png',
      ],
      'branco': [
        'assets/img/camiseta-dryfit/DryFit-branca-1.png',
        'assets/img/camiseta-dryfit/DryFit-branca-2.png',
        'assets/img/camiseta-dryfit/DryFit-branca-3.png',
      ],
      'preto': [
        'assets/img/camiseta-dryfit/DryFit-preta-1.png',
        'assets/img/camiseta-dryfit/DryFit-preta-2.png',
        'assets/img/camiseta-dryfit/DryFit-preta-3.png',
      ],
    },
    'Short Esportivo': {
      'preto': [
        'assets/img/short-esportivo/Short-Preto-1.png',
        'assets/img/short-esportivo/Short-Preto-2.png',
        'assets/img/short-esportivo/Short-Preto-3.png',
      ],
      'azul': [
        'assets/img/short-esportivo/Short-Azul-1.png',
        'assets/img/short-esportivo/Short-Azul-2.png',
        'assets/img/short-esportivo/Short-Azul-3.png',
      ],
      'branco': [
        'assets/img/short-esportivo/Short-Branco-1.png',
        'assets/img/short-esportivo/Short-Branco-2.png',
        'assets/img/short-esportivo/Short-Branco-3.png',
      ],
    },
    'Camiseta Treino': {
      'preto': [
        'assets/img/camiseta-treino/Camiseta treino-preta-1.png',
        'assets/img/camiseta-treino/Camiseta treino-preta-2.png',
        'assets/img/camiseta-treino/Camiseta treino-preta-3.png',
      ],
      'azul': [
        'assets/img/camiseta-treino/Camiseta treino-azul-3.png',
        'assets/img/camiseta-treino/Camiseta treino-azul-2.png',
        'assets/img/camiseta-treino/Camiseta treino-azul-1.png',
      ],
      'branco': [
        'assets/img/camiseta-treino/Camiseta treino-branca-1.png',
        'assets/img/camiseta-treino/Camiseta treino-branca-2.png',
        'assets/img/camiseta-treino/Camiseta treino-branca-3.png',
      ],
    },
    'Regata Fitness': {
      'preto': [
        'assets/img/regata/Regata-Preta-1.png',
        'assets/img/regata/Regata-Preta-2.png',
        'assets/img/regata/Regata-Preta-3.png',
      ],
      'azul': [
        'assets/img/regata/Regata-Azul-1.png',
        'assets/img/regata/Regata-Azul-2.png',
        'assets/img/regata/Regata-Azul-3.png',
      ],
      'branco': [
        'assets/img/regata/Regata-Branca-1.png',
        'assets/img/regata/Regata-Branca-2.png',
        'assets/img/regata/Regata-Branca-3.png',
      ],
    },
    'Bola Elite Nations': {
      'principal': ['assets/img/acessorios/Bola_futebol_1.png'],
    },
    'Bola Elite Stars': {
      'principal': ['assets/img/acessorios/Bola_futebol_2.png'],
    },
    'Bola Elite Pro': {
      'principal': ['assets/img/acessorios/Bola_futebol_3.png'],
    },
    'Garrafa Esportiva Elite 750ml': {
      'preto': ['assets/img/acessorios/Garrafa_preta_1.png'],
      'azul': ['assets/img/acessorios/Garrafa_azul_1.png'],
      'branco': ['assets/img/acessorios/Garrafa_branca_1.png'],
    },
    'Bolsa Esportiva Elite': {
      'preto': [
        'assets/img/acessorios/Bolsa_preta_1.png',
        'assets/img/acessorios/Bolsa_preta_2.png',
        'assets/img/acessorios/Bolsa_preta_3.png',
      ],
      'azul': [
        'assets/img/acessorios/Bolsa_azul_1.png',
        'assets/img/acessorios/Bolsa_azul_2.png',
        'assets/img/acessorios/Bolsa_azul_3.png',
      ],
      'branco': [
        'assets/img/acessorios/Bolsa_branca_1.png',
        'assets/img/acessorios/Bolsa_branca_2.png',
        'assets/img/acessorios/Bolsa_branca_3.png',
      ],
    },
    'Mochila Esportiva Elite': {
      'preto': [
        'assets/img/acessorios/Mochila_preta_1.png',
        'assets/img/acessorios/Mochila_preta_2.png',
        'assets/img/acessorios/Mochila_preta_3.png',
      ],
      'azul': [
        'assets/img/acessorios/Mochila_azul_1.png',
        'assets/img/acessorios/Mochila_azul_2.png',
        'assets/img/acessorios/Mochila_azul_3.png',
      ],
      'branco': [
        'assets/img/acessorios/Mochila_branca_1.png',
        'assets/img/acessorios/Mochila_branca_2.png',
        'assets/img/acessorios/Mochila_branca_3.png',
      ],
    },
    'Meia Esportiva Elite': {
      'preto': [
        'assets/img/acessorios/Meia_preta_1.png',
        'assets/img/acessorios/Meia_preta_2.png',
        'assets/img/acessorios/Meia_preta_3.png',
      ],
      'branco': [
        'assets/img/acessorios/Meia_branca_1.png',
        'assets/img/acessorios/Meia_branca_2.png',
        'assets/img/acessorios/Meia_branca_3.png',
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    carregarProduto();
  }

  // ==========================================
  // FUNÇÕES AUXILIARES
  // ==========================================

  String normalizar(dynamic valor) {
    return valor?.toString().trim().toLowerCase() ?? '';
  }

  String nomeCor(String cor) {
    if (cor.isEmpty) return cor;
    return '${cor[0].toUpperCase()}${cor.substring(1)}';
  }

  Color corVisual(String cor) {
    switch (normalizar(cor)) {
      case 'preto':
        return Colors.black;
      case 'branco':
        return Colors.white;
      case 'azul':
        return const Color(0xFF2676E8);
      default:
        return const Color(0xFF888894);
    }
  }

  double? get preco {
    final valor = produtoBanco?['preco'];

    if (valor is num) return valor.toDouble();

    return double.tryParse(valor?.toString() ?? '');
  }

  String formatarPreco(double? valor) {
    if (valor == null || !valor.isFinite) {
      return 'Preço indisponível';
    }

    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final buffer = StringBuffer();

    for (int i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(inteiro[i]);
    }

    return 'R\$ ${buffer.toString()},${partes[1]}';
  }

  // ==========================================
  // CORES E TAMANHOS DISPONÍVEIS NA API
  // ==========================================

  List<String> get cores {
    final resultado = <String>[];

    for (final variacao in variacoes) {
      final cor = variacao['cor']?.toString().trim() ?? '';

      if (cor.isNotEmpty &&
          normalizar(cor) != 'única' &&
          !resultado.any((item) => normalizar(item) == normalizar(cor))) {
        resultado.add(cor);
      }
    }

    return resultado;
  }

  List<String> get tamanhos {
    final resultado = <String>[];

    for (final variacao in variacoes) {
      final tamanho = variacao['tamanho']?.toString().trim() ?? '';

      if (tamanho.isNotEmpty &&
          normalizar(tamanho) != 'único' &&
          !resultado.contains(tamanho)) {
        resultado.add(tamanho);
      }
    }

    const ordem = ['P', 'M', 'G', 'GG'];

    resultado.sort((a, b) {
      final ia = ordem.indexOf(a.toUpperCase());
      final ib = ordem.indexOf(b.toUpperCase());

      if (ia == -1 && ib == -1) return a.compareTo(b);
      if (ia == -1) return 1;
      if (ib == -1) return -1;
      return ia.compareTo(ib);
    });

    return resultado;
  }

  // ==========================================
  // CONSULTAR PRODUTO NA API
  // ==========================================

  Future<void> carregarProduto() async {
    if (mounted) {
      setState(() {
        carregando = true;
        erro = null;
      });
    }

    try {
      final resposta = await http
          .get(Uri.parse('$apiBase/api/produtos'))
          .timeout(const Duration(seconds: 20));

      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw Exception('Erro ao consultar o produto.');
      }

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is! List) {
        throw const FormatException('Lista de produtos inválida.');
      }

      Map<String, dynamic>? encontrado;

      for (final item in dados) {
        if (item is Map &&
            normalizar(item['nome']) == normalizar(widget.nomeProduto)) {
          encontrado = Map<String, dynamic>.from(item);
          break;
        }
      }

      if (encontrado == null) {
        throw Exception('Produto não encontrado no banco de dados.');
      }

      final lista = <Map<String, dynamic>>[];
      final originais = encontrado['variacoes'];

      if (originais is List) {
        for (final item in originais) {
          if (item is Map) {
            lista.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;

      setState(() {
        produtoBanco = encontrado;
        variacoes = lista;

        corSelecionada = null;
        tamanhoSelecionado = null;
        quantidade = 1;
        fotoAtual = 0;

        // As cores e tamanhos vêm do banco.
        // Usa a primeira cor disponível inicialmente.
        if (cores.isNotEmpty) {
          final preferencias = <String, String>{
            'Camiseta Dry Fit': 'azul',
            'Short Esportivo': 'preto',
            'Camiseta Treino': 'preto',
            'Regata Fitness': 'preto',
          };

          final preferida = preferencias[widget.nomeProduto];

          for (final cor in cores) {
            if (normalizar(cor) == normalizar(preferida)) {
              corSelecionada = cor;
              break;
            }
          }

          corSelecionada ??= cores.first;
        }

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
  // VARIAÇÃO SELECIONADA
  // ==========================================

  Map<String, dynamic>? get variacaoSelecionada {
    if (produtoBanco == null) return null;

    if (tamanhos.isNotEmpty && tamanhoSelecionado == null) {
      return null;
    }

    for (final variacao in variacoes) {
      final corBanco = variacao['cor']?.toString() ?? 'Única';

      final tamanhoBanco = variacao['tamanho'];

      final mesmaCor =
          cores.isEmpty || normalizar(corBanco) == normalizar(corSelecionada);

      final mesmoTamanho = tamanhos.isEmpty
          ? tamanhoBanco == null ||
                normalizar(tamanhoBanco).isEmpty ||
                normalizar(tamanhoBanco) == 'único'
          : normalizar(tamanhoBanco) == normalizar(tamanhoSelecionado);

      if (mesmaCor && mesmoTamanho) {
        return variacao;
      }
    }

    return null;
  }

  int get estoqueSelecionado {
    final valor = variacaoSelecionada?['estoque'];

    if (valor is num) return valor.toInt();

    return int.tryParse(valor?.toString() ?? '') ?? 0;
  }

  // ==========================================
  // IMAGENS DA COR SELECIONADA
  // ==========================================

  String? converterCaminho(dynamic valor) {
    var caminho = valor?.toString().trim() ?? '';

    if (caminho.isEmpty) return null;

    if (caminho.startsWith('http://') || caminho.startsWith('https://')) {
      return caminho;
    }

    while (caminho.startsWith('./')) {
      caminho = caminho.substring(2);
    }

    if (caminho.startsWith('/')) {
      caminho = caminho.substring(1);
    }

    if (caminho.startsWith('img/')) {
      return 'assets/$caminho';
    }

    if (caminho.startsWith('assets/img/')) {
      return caminho;
    }

    return null;
  }

  List<String> get imagens {
    final mapa = galerias[widget.nomeProduto];

    final cor = normalizar(corSelecionada);

    final lista = mapa?[cor] ?? mapa?['principal'];

    if (lista != null && lista.isNotEmpty) {
      return lista;
    }

    final imagemBanco = converterCaminho(variacaoSelecionada?['imagem']);

    if (imagemBanco != null) return [imagemBanco];

    final inicial = converterCaminho(widget.imagemInicial);

    if (inicial != null) return [inicial];

    return [];
  }

  Widget mostrarImagem(String caminho) {
    if (caminho.startsWith('http')) {
      return Image.network(
        caminho,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) {
          return const Icon(
            Icons.image_not_supported_outlined,
            color: cinza,
            size: 50,
          );
        },
      );
    }

    return Image.asset(
      caminho,
      fit: BoxFit.contain,
      errorBuilder: (_, error, stackTrace) {
        return const Icon(
          Icons.image_not_supported_outlined,
          color: cinza,
          size: 50,
        );
      },
    );
  }

  // ==========================================
  // SELECIONAR COR, TAMANHO E QUANTIDADE
  // ==========================================

  void selecionarCor(String cor) {
    setState(() {
      corSelecionada = cor;
      quantidade = 1;
      fotoAtual = 0;
    });
  }

  void selecionarTamanho(String tamanho) {
    setState(() {
      tamanhoSelecionado = tamanho;
      quantidade = 1;
    });
  }

  void alterarQuantidade(int diferenca) {
    final nova = quantidade + diferenca;

    if (nova < 1) return;

    if (nova > estoqueSelecionado) return;

    setState(() {
      quantidade = nova;
    });
  }

  void mensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // ==========================================
  // ADICIONAR PRODUTO AO CARRINHO LOCAL
  // ==========================================

  Future<void> adicionarCarrinho() async {
    if (salvando || produtoBanco == null) return;

    if (tamanhos.isNotEmpty && tamanhoSelecionado == null) {
      mensagem('Selecione um tamanho.');
      return;
    }

    final variacao = variacaoSelecionada;

    if (variacao == null) {
      mensagem('Esta combinação não está disponível.');
      return;
    }

    if (estoqueSelecionado < quantidade) {
      mensagem('Quantidade acima do estoque disponível.');
      return;
    }

    if (preco == null) {
      mensagem('Preço indisponível para este produto.');
      return;
    }

    setState(() => salvando = true);

    try {
      final preferencias = SharedPreferencesAsync();

      final texto = await preferencias.getString(chaveCarrinho);

      final carrinho = <Map<String, dynamic>>[];

      if (texto != null) {
        final dados = jsonDecode(texto);

        if (dados is List) {
          for (final item in dados) {
            if (item is Map) {
              carrinho.add(Map<String, dynamic>.from(item));
            }
          }
        }
      }

      final idVariacao = variacao['id_variacao'].toString();

      final indice = carrinho.indexWhere(
        (item) => item['id_variacao']?.toString() == idVariacao,
      );

      final quantidadeExistente = indice >= 0
          ? int.tryParse(carrinho[indice]['qtd']?.toString() ?? '') ?? 0
          : 0;

      if (quantidadeExistente + quantidade > estoqueSelecionado) {
        mensagem(
          'Estoque disponível: $estoqueSelecionado unidade(s). '
          'Você já tem $quantidadeExistente no carrinho.',
        );
        return;
      }

      if (indice >= 0) {
        carrinho[indice]['qtd'] = quantidadeExistente + quantidade;
      } else {
        carrinho.add({
          'id_produto': produtoBanco!['id_produto'],
          'id_variacao': variacao['id_variacao'],
          'nome': produtoBanco!['nome'],
          'preco': preco,
          'cor': cores.isEmpty ? 'Única' : corSelecionada,
          'tamanho': tamanhos.isEmpty ? 'Único' : tamanhoSelecionado,
          'imagem': imagens.isNotEmpty ? imagens.first : '',
          'qtd': quantidade,
        });
      }

      await preferencias.setString(chaveCarrinho, jsonEncode(carrinho));

      if (!mounted) return;

      final verCarrinho = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: const Color(0xFF18181F),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFF383041)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFF282039),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFFA855F7),
                        size: 48,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Produto adicionado!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Seu produto foi adicionado ao carrinho '
                      'com sucesso. O que deseja fazer agora?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFAAAAAF),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // BOTÃO VER CARRINHO
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext, true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7B2CFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: const Text(
                          'Ver carrinho',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BOTÃO CONTINUAR COMPRANDO
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext, false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF484850)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text(
                          'Continuar comprando',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (!mounted) return;

      if (verCarrinho == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CarrinhoPage()),
        );
      }
    } catch (e) {
      mensagem('Não foi possível adicionar o produto: $e');
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  // ==========================================
  // MONTAGEM DA TELA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.sizeOf(context).width;
    final celular = larguraTela < 750;

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Elite Sports — Produto',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: carregando
            ? const Center(child: CircularProgressIndicator(color: roxo))
            : erro != null
            ? construirErro()
            : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: celular ? 18 : 35,
                  vertical: 30,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: celular
                        ? Column(
                            children: [
                              construirGaleria(),
                              const SizedBox(height: 25),
                              construirInformacoes(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: construirGaleria()),
                              const SizedBox(width: 35),
                              Expanded(child: construirInformacoes()),
                            ],
                          ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget construirErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              erro!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              onPressed: carregarProduto,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // GALERIA COM FOTO PRINCIPAL E MINIATURAS
  // ==========================================

  Widget construirGaleria() {
    final fotos = imagens;

    final indice = fotos.isEmpty ? 0 : fotoAtual.clamp(0, fotos.length - 1);

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).width < 750 ? 360 : 490,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF242430), Color(0xFF17171E), Color(0xFF131319)],
            ),
            border: Border.all(color: borda),
            borderRadius: BorderRadius.circular(20),
          ),
          child: fotos.isEmpty
              ? const Icon(
                  Icons.image_not_supported_outlined,
                  color: cinza,
                  size: 60,
                )
              : mostrarImagem(fotos[indice]),
        ),

        if (fotos.length > 1) ...[
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < fotos.length; i++) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        fotoAtual = i;
                      });
                    },
                    child: Container(
                      width: 84,
                      height: 84,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: fotoAtual == i ? 2 : 1,
                          color: fotoAtual == i ? roxo : borda,
                        ),
                      ),
                      child: mostrarImagem(fotos[i]),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // INFORMAÇÕES DO PRODUTO
  // ==========================================

  Widget construirInformacoes() {
    final statusCor = tamanhos.isNotEmpty && tamanhoSelecionado == null
        ? cinza
        : estoqueSelecionado > 0
        ? const Color(0xFF4ADE80)
        : const Color(0xFFFF7070);

    String status;

    if (tamanhos.isNotEmpty && tamanhoSelecionado == null) {
      status = 'Selecione um tamanho para consultar o estoque.';
    } else if (variacaoSelecionada == null) {
      status = 'Variação indisponível.';
    } else if (estoqueSelecionado > 0) {
      status = 'Em estoque: $estoqueSelecionado unidade(s)';
    } else {
      status = 'Esta combinação está esgotada.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ELITE SPORTS',
            style: TextStyle(
              color: roxoClaro,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            widget.nomeProduto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            formatarPreco(preco),
            style: const TextStyle(
              color: roxoClaro,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Escolha as opções disponíveis para seu produto.',
            style: TextStyle(color: cinza, fontSize: 14),
          ),

          const SizedBox(height: 27),
          const Divider(color: borda),
          const SizedBox(height: 20),

          // SELECIONAR COR
          if (cores.isNotEmpty) ...[
            const Text(
              'Cor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final cor in cores)
                  InkWell(
                    onTap: () => selecionarCor(cor),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: normalizar(corSelecionada) == normalizar(cor)
                            ? const Color(0xFF291746)
                            : const Color(0xFF202027),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: normalizar(corSelecionada) == normalizar(cor)
                              ? roxo
                              : borda,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 19,
                            height: 19,
                            decoration: BoxDecoration(
                              color: corVisual(cor),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white54),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(nomeCor(cor)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 26),
          ],

          // SELECIONAR TAMANHO
          if (tamanhos.isNotEmpty) ...[
            const Text(
              'Tamanho',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final tamanho in tamanhos)
                  OutlinedButton(
                    onPressed: () => selecionarTamanho(tamanho),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: tamanhoSelecionado == tamanho
                          ? roxo
                          : const Color(0xFF202027),
                      side: BorderSide(
                        color: tamanhoSelecionado == tamanho ? roxo : borda,
                      ),
                      minimumSize: const Size(55, 46),
                    ),
                    child: Text(tamanho),
                  ),
              ],
            ),
            const SizedBox(height: 26),
          ],

          Text(
            status,
            style: TextStyle(
              color: statusCor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Quantidade',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton.outlined(
                onPressed: quantidade > 1 ? () => alterarQuantidade(-1) : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 55,
                child: Text(
                  '$quantidade',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton.outlined(
                onPressed: estoqueSelecionado > quantidade
                    ? () => alterarQuantidade(1)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: FilledButton.icon(
              onPressed:
                  salvando ||
                      preco == null ||
                      variacaoSelecionada == null ||
                      estoqueSelecionado < quantidade
                  ? null
                  : adicionarCarrinho,
              style: FilledButton.styleFrom(
                backgroundColor: roxo,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF35303E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_outlined),
              label: const Text(
                'Adicionar ao carrinho',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'O carrinho será finalizado na próxima etapa.',
            style: TextStyle(color: cinza, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
