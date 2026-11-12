import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'sessao_usuario.dart';
import 'login_page.dart';
import 'meus_pedidos_page.dart';

class CarrinhoPage extends StatefulWidget {
  const CarrinhoPage({super.key});

  static const String chaveCarrinho = 'carrinho_flutter_v1';

  // Usada para atualizar o contador da tela inicial.
  static Future<int> contarItens() async {
    try {
      final prefs = SharedPreferencesAsync();
      final texto = await prefs.getString(chaveCarrinho);

      if (texto == null) return 0;

      final dados = jsonDecode(texto);
      if (dados is! List) return 0;

      int total = 0;

      for (final item in dados) {
        if (item is Map) {
          final quantidade = int.tryParse(item['qtd']?.toString() ?? '') ?? 0;

          if (quantidade > 0) {
            total += quantidade;
          }
        }
      }

      return total;
    } catch (_) {
      return 0;
    }
  }

  @override
  State<CarrinhoPage> createState() => _CarrinhoPageState();
}

class _CarrinhoPageState extends State<CarrinhoPage> {
  static const String apiBase =
      'https://elite-sports-production.up.railway.app';

  static const Color fundo = Color(0xFF0D0D12);
  static const Color card = Color(0xFF17171C);
  static const Color borda = Color(0xFF303038);
  static const Color roxo = Color(0xFF7B2CFF);
  static const Color roxoClaro = Color(0xFFA855F7);
  static const Color cinza = Color(0xFF9292A5);

  final prefs = SharedPreferencesAsync();

  List<Map<String, dynamic>> itens = [];

  // Dados atualizados de estoque e preço.
  Map<String, Map<String, dynamic>> variacoesAtuais = {};

  bool carregando = true;
  bool gravando = false;
  bool _pedidoJaRegistrado = false;
  bool _envioSemConfirmacao = false;
  bool dadosValidados = false;

  String? erroLeitura;
  String? avisoConexao;

  @override
  void initState() {
    super.initState();
    carregarCarrinho();
  }

  // ==========================================
  // LEITURA DO CARRINHO E CONSULTA À API
  // ==========================================

  Future<void> carregarCarrinho() async {
    setState(() {
      carregando = true;
      erroLeitura = null;
      avisoConexao = null;
      dadosValidados = false;
    });

    final lista = <Map<String, dynamic>>[];

    try {
      final texto = await prefs.getString(CarrinhoPage.chaveCarrinho);

      if (texto != null) {
        final dados = jsonDecode(texto);

        if (dados is! List) {
          throw const FormatException('Formato inválido.');
        }

        for (final item in dados) {
          if (item is Map) {
            lista.add(Map<String, dynamic>.from(item));
          }
        }
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        carregando = false;
        erroLeitura = 'Não foi possível ler os produtos salvos no carrinho.';
      });
      return;
    }

    final atualizadas = <String, Map<String, dynamic>>{};
    String? aviso;
    bool validado = false;

    if (lista.isNotEmpty) {
      try {
        final resposta = await http
            .get(Uri.parse('$apiBase/api/produtos'))
            .timeout(const Duration(seconds: 20));

        if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
          throw Exception('A API não retornou os produtos.');
        }

        final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

        if (dados is! List) {
          throw const FormatException('Resposta de produtos inválida.');
        }

        for (final produto in dados) {
          if (produto is! Map) continue;

          final variacoes = produto['variacoes'];

          if (variacoes is! List) continue;

          for (final variacao in variacoes) {
            if (variacao is! Map) continue;

            final id = variacao['id_variacao']?.toString();

            if (id == null) continue;

            atualizadas[id] = {
              'id_produto': produto['id_produto'],
              'nome': produto['nome'],
              'preco': produto['preco'],
              'estoque': variacao['estoque'],
            };
          }
        }

        validado = true;
      } on TimeoutException {
        aviso =
            'A consulta de estoque demorou demais. '
            'Tente atualizar o carrinho.';
      } catch (_) {
        aviso =
            'Não foi possível atualizar preços e estoque. '
            'Os valores exibidos podem estar desatualizados.';
      }
    }

    if (!mounted) return;

    setState(() {
      itens = lista;
      variacoesAtuais = atualizadas;
      dadosValidados = validado;
      avisoConexao = aviso;
      carregando = false;
    });
  }

  // ==========================================
  // FUNÇÕES DE PREÇO, QUANTIDADE E ESTOQUE
  // ==========================================

  int quantidade(Map<String, dynamic> item) {
    final valor = int.tryParse(item['qtd']?.toString() ?? '') ?? 1;

    return valor < 1 ? 1 : valor;
  }

  double? converterPreco(dynamic valor) {
    if (valor is num) return valor.toDouble();

    return double.tryParse(valor?.toString() ?? '');
  }

  Map<String, dynamic>? variacaoAtual(Map<String, dynamic> item) {
    final id = item['id_variacao']?.toString();
    return variacoesAtuais[id];
  }

  double? precoAtual(Map<String, dynamic> item) {
    final variacao = variacaoAtual(item);

    if (variacao != null) {
      return converterPreco(variacao['preco']);
    }

    return converterPreco(item['preco']);
  }

  int estoqueAtual(Map<String, dynamic> item) {
    final variacao = variacaoAtual(item);
    if (variacao == null) return 0;

    return int.tryParse(variacao['estoque']?.toString() ?? '') ?? 0;
  }

  bool itemValido(Map<String, dynamic> item) {
    if (!dadosValidados) return false;

    if (variacaoAtual(item) == null) return false;

    if (precoAtual(item) == null) return false;

    return estoqueAtual(item) >= quantidade(item);
  }

  int get quantidadeTotal {
    int total = 0;

    for (final item in itens) {
      total += quantidade(item);
    }

    return total;
  }

  double get subtotal {
    double total = 0;

    for (final item in itens) {
      total += (precoAtual(item) ?? 0) * quantidade(item);
    }

    return total;
  }

  bool get tudoDisponivel {
    return itens.isNotEmpty && itens.every((item) => itemValido(item));
  }

  String formatarPreco(double? valor) {
    if (valor == null || !valor.isFinite) {
      return 'R\$ —';
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
  // SALVAR MODIFICAÇÕES
  // ==========================================

  Future<void> salvarItens(List<Map<String, dynamic>> novaLista) async {
    if (gravando) return;

    setState(() => gravando = true);

    try {
      await prefs.setString(CarrinhoPage.chaveCarrinho, jsonEncode(novaLista));

      if (!mounted) return;

      setState(() {
        itens = novaLista;
      });
    } catch (_) {
      mostrarMensagem('Não foi possível salvar a alteração no carrinho.');
    } finally {
      if (mounted) {
        setState(() => gravando = false);
      }
    }
  }

  // ==========================================
  // AUMENTAR OU DIMINUIR QUANTIDADE
  // ==========================================

  Future<void> alterarQuantidade(int indice, int diferenca) async {
    if (gravando) return;

    final item = itens[indice];
    final atual = quantidade(item);
    final nova = atual + diferenca;

    if (nova < 1) return;

    if (diferenca > 0 && (!dadosValidados || nova > estoqueAtual(item))) {
      mostrarMensagem(
        'Não há estoque confirmado para aumentar '
        'a quantidade deste produto.',
      );
      return;
    }

    final novaLista = itens
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    novaLista[indice]['qtd'] = nova;

    await salvarItens(novaLista);
  }

  // ==========================================
  // REMOVER PRODUTO
  // ==========================================

  Future<void> removerProduto(int indice) async {
    if (gravando) return;

    final novaLista = itens
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    novaLista.removeAt(indice);

    await salvarItens(novaLista);
  }

  // ==========================================
  // LIMPAR CARRINHO COM CONFIRMAÇÃO
  // ==========================================

  Future<void> limparCarrinho() async {
    if (gravando || itens.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: card,
          title: const Text('Limpar carrinho?'),
          content: const Text('Todos os produtos serão removidos do carrinho.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Limpar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true) return;

    await salvarItens([]);
  }

  void mostrarMensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // ==========================================
  // MENSAGEM CENTRALIZADA
  // ==========================================

  Future<void> _mostrarAvisoCentral(String titulo, String texto) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181F),
          title: Text(titulo),
          content: Text(texto),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // FINALIZAR COMPRA - REGISTRAR PEDIDO NA API
  // ==========================================

  Future<void> finalizarCompra() async {
    if (gravando ||
        carregando ||
        !tudoDisponivel ||
        _pedidoJaRegistrado ||
        _envioSemConfirmacao) {
      return;
    }

    // 1. VERIFICAR SE O USUÁRIO ESTÁ LOGADO
    final usuario = await SessaoUsuario.ler();

    if (!mounted) return;

    final idUsuario = int.tryParse(usuario?['id_usuario']?.toString() ?? '');

    if (idUsuario == null || idUsuario <= 0) {
      final entrar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF18181F),
            title: const Text('Entre na sua conta'),
            content: const Text(
              'Você precisa estar logado para registrar um pedido.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Fazer login'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      if (entrar == true) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }

      return;
    }

    // 2. PEDIR CONFIRMAÇÃO ANTES DE ENVIAR AO BANCO
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Color(0xFFA855F7)),
              SizedBox(width: 12),
              Expanded(child: Text('Confirmar pedido')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confira os dados antes de registrar:'),
              const SizedBox(height: 18),
              Text('Quantidade de produtos: $quantidadeTotal'),
              const SizedBox(height: 9),
              Text(
                'Subtotal: ${formatarPreco(subtotal)}',
                style: const TextStyle(
                  color: Color(0xFFA855F7),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Ao confirmar, o pedido será gravado no MySQL '
                'e o estoque será reduzido. '
                'Esta etapa não processa pagamento nem calcula frete.',
                style: TextStyle(color: Color(0xFFAAAAAF), fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7B2CFF),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Finalizar compra'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmar != true || gravando) {
      return;
    }

    // 3. BLOQUEAR NOVOS CLIQUES ENQUANTO ENVIA
    setState(() {
      gravando = true;
    });

    try {
      // 4. PREPARAR OS ITENS PARA O FORMATO DA API
      final itensPedido = itens.map((item) {
        return {
          'nome': item['nome'],
          'cor': item['cor'] ?? 'Única',
          'tamanho': item['tamanho'] ?? 'Único',
          'qtd': quantidade(item),
        };
      }).toList();

      final corpo = {'id_usuario': idUsuario, 'itens': itensPedido};

      // 5. REGISTRAR PEDIDO NO MYSQL
      final resposta = await http
          .post(
            Uri.parse('$apiBase/api/pedidos'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(corpo),
          )
          .timeout(const Duration(seconds: 25));

      // 6. LER A RESPOSTA DO SERVIDOR
      dynamic dados;

      try {
        dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      } catch (_) {
        dados = null;
      }

      if (!mounted) return;

      if (resposta.statusCode != 201) {
        final mensagemServidor = dados is Map
            ? dados['mensagem']?.toString()
            : null;

        await _mostrarAvisoCentral(
          'Não foi possível registrar o pedido',
          mensagemServidor ?? 'O servidor não confirmou o registro do pedido.',
        );

        return;
      }

      // 7. PEDIDO CONFIRMADO PELO SERVIDOR
      final numeroPedido = dados is Map ? dados['id_pedido']?.toString() : null;

      // 8. LIMPAR CARRINHO LOCAL APÓS A CONFIRMAÇÃO
      bool carrinhoLimpo = true;

      try {
        await prefs.remove(CarrinhoPage.chaveCarrinho);
      } catch (_) {
        carrinhoLimpo = false;
      }

      if (!mounted) return;

      setState(() {
        _pedidoJaRegistrado = true;

        if (carrinhoLimpo) {
          itens = [];
          variacoesAtuais = {};
        }
      });

      // 9. EXIBIR CONFIRMAÇÃO CENTRALIZADA
      final abrirPedidos = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF18181F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF4ADE80),
                  size: 30,
                ),
                SizedBox(width: 12),
                Expanded(child: Text('Pedido registrado!')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numeroPedido == null
                      ? 'O servidor confirmou o registro do pedido.'
                      : 'Pedido nº $numeroPedido registrado com sucesso!',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Você pode acompanhar o registro '
                  'na página Meus Pedidos.',
                ),
                if (!carrinhoLimpo) ...[
                  const SizedBox(height: 15),
                  const Text(
                    'Atenção: o pedido foi criado, mas não foi '
                    'possível limpar o carrinho local. '
                    'Não registre os mesmos produtos novamente.',
                    style: TextStyle(color: Color(0xFFFFB86B)),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Fechar'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7B2CFF),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Ver meus pedidos'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // 10. ABRIR A PÁGINA DE PEDIDOS
      if (abrirPedidos == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MeusPedidosPage()),
        );
      }
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        _envioSemConfirmacao = true;
      });

      await _mostrarAvisoCentral(
        'Não foi possível confirmar a resposta',
        'A conexão demorou demais. O pedido pode ter sido '
            'registrado no servidor. Confira Meus Pedidos '
            'antes de tentar novamente para evitar duplicidade.',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _envioSemConfirmacao = true;
      });

      await _mostrarAvisoCentral(
        'Falha na comunicação',
        'Não foi possível confirmar se o pedido foi '
            'registrado. Verifique Meus Pedidos antes de '
            'realizar qualquer novo envio.',
      );
    } finally {
      if (mounted) {
        setState(() {
          gravando = false;
        });
      }
    }
  }

  void continuarComprando() {
    Navigator.pop(context);
  }

  // ==========================================
  // IMAGEM DO PRODUTO
  // ==========================================

  Widget imagemProduto(Map<String, dynamic> item) {
    final caminho = item['imagem']?.toString() ?? '';

    if (caminho.startsWith('https://') || caminho.startsWith('http://')) {
      return Image.network(
        caminho,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) {
          return imagemIndisponivel();
        },
      );
    }

    if (caminho.startsWith('assets/img/')) {
      return Image.asset(
        caminho,
        fit: BoxFit.contain,
        errorBuilder: (_, error, stackTrace) {
          return imagemIndisponivel();
        },
      );
    }

    return imagemIndisponivel();
  }

  Widget imagemIndisponivel() {
    return const Icon(Icons.shopping_bag_outlined, size: 45, color: roxoClaro);
  }

  // ==========================================
  // TELA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final celular = MediaQuery.sizeOf(context).width < 850;

    return Scaffold(
      backgroundColor: fundo,
      appBar: AppBar(
        title: const Text('Elite Sports — Carrinho'),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Atualizar preços e estoque',
            onPressed: carregando || gravando ? null : carregarCarrinho,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator(color: roxo))
          : erroLeitura != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Text(
                  erroLeitura!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: celular ? 18 : 35,
                vertical: 30,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      construirCabecalho(),
                      const SizedBox(height: 30),

                      if (avisoConexao != null) ...[
                        construirAviso(avisoConexao!),
                        const SizedBox(height: 25),
                      ],

                      if (itens.isEmpty)
                        construirCarrinhoVazio()
                      else if (celular)
                        Column(
                          children: [
                            construirLista(),
                            const SizedBox(height: 25),
                            construirResumo(),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: construirLista()),
                            const SizedBox(width: 28),
                            Expanded(flex: 4, child: construirResumo()),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ==========================================
  // CABEÇALHO
  // ==========================================

  Widget construirCabecalho() {
    return Column(
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
        const SizedBox(height: 10),
        const Text(
          'Meu Carrinho',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'Confira os produtos que você selecionou.',
          style: TextStyle(color: cinza, fontSize: 15),
        ),
      ],
    );
  }

  Widget construirAviso(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2216),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFBBF24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(texto, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARRINHO VAZIO
  // ==========================================

  Widget construirCarrinhoVazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 65, horizontal: 20),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 65, color: roxoClaro),
          const SizedBox(height: 20),
          const Text(
            'Seu carrinho está vazio',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Adicione produtos para começar sua compra.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cinza),
          ),
          const SizedBox(height: 25),
          FilledButton.icon(
            onPressed: continuarComprando,
            style: FilledButton.styleFrom(
              backgroundColor: roxo,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Continuar comprando'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // LISTAGEM DOS PRODUTOS
  // ==========================================

  Widget construirLista() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < itens.length; i++) ...[
          construirItem(itens[i], i),
          const SizedBox(height: 16),
        ],

        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: gravando ? null : limparCarrinho,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Limpar carrinho'),
          ),
        ),
      ],
    );
  }

  Widget construirItem(Map<String, dynamic> item, int indice) {
    final quantidadeAtual = quantidade(item);
    final estoque = estoqueAtual(item);
    final valido = itemValido(item);
    final preco = precoAtual(item);

    final nome = item['nome']?.toString() ?? 'Produto';
    final cor = item['cor']?.toString() ?? 'Única';
    final tamanho = item['tamanho']?.toString() ?? 'Único';

    String situacao;

    if (!dadosValidados) {
      situacao = 'Estoque não verificado';
    } else if (variacaoAtual(item) == null) {
      situacao = 'Variação indisponível';
    } else if (estoque < quantidadeAtual) {
      situacao = 'Estoque atual: $estoque';
    } else {
      situacao = 'Em estoque';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 105,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25252C), Color(0xFF15151B)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: imagemProduto(item),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cor: $cor  •  Tamanho: $tamanho',
                  style: const TextStyle(color: cinza, fontSize: 13),
                ),
                const SizedBox(height: 9),
                Text(
                  situacao,
                  style: TextStyle(
                    color: valido
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFFFF8888),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  formatarPreco(preco),
                  style: const TextStyle(
                    color: roxoClaro,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 13),

                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton.outlined(
                      tooltip: 'Diminuir quantidade',
                      onPressed: gravando || quantidadeAtual <= 1
                          ? null
                          : () => alterarQuantidade(indice, -1),
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '$quantidadeAtual',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: 'Aumentar quantidade',
                      onPressed:
                          gravando ||
                              !dadosValidados ||
                              quantidadeAtual >= estoque
                          ? null
                          : () => alterarQuantidade(indice, 1),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: 'Remover produto',
                      onPressed: gravando ? null : () => removerProduto(indice),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Text(
                  'Subtotal: ${formatarPreco(preco == null ? null : preco * quantidadeAtual)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
  // RESUMO DO PEDIDO
  // ==========================================

  Widget construirResumo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do pedido',
            style: TextStyle(
              fontSize: 21,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 25),

          linhaResumo('Produtos ($quantidadeTotal)', formatarPreco(subtotal)),
          const SizedBox(height: 15),
          linhaResumo('Frete', 'A definir'),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: borda),
          ),

          linhaResumo('Subtotal', formatarPreco(subtotal), destaque: true),
          const SizedBox(height: 24),

          if (!tudoDisponivel)
            const Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Text(
                'Confira a disponibilidade dos produtos '
                'antes de finalizar a compra.',
                style: TextStyle(color: Color(0xFFFFB86B), fontSize: 13),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed:
                  gravando ||
                      !tudoDisponivel ||
                      _pedidoJaRegistrado ||
                      _envioSemConfirmacao
                  ? null
                  : finalizarCompra,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Finalizar compra'),
              style: FilledButton.styleFrom(
                backgroundColor: roxo,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF39313F),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: continuarComprando,
              child: const Text('Continuar comprando'),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'O pedido será registrado sem processamento '
            'de pagamento. O frete ainda não é calculado.',
            style: TextStyle(color: cinza, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget linhaResumo(String titulo, String valor, {bool destaque = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            titulo,
            style: TextStyle(
              color: destaque ? Colors.white : cinza,
              fontWeight: destaque ? FontWeight.w800 : FontWeight.w500,
              fontSize: destaque ? 17 : 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          valor,
          style: TextStyle(
            color: destaque ? roxoClaro : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: destaque ? 22 : 15,
          ),
        ),
      ],
    );
  }
}
