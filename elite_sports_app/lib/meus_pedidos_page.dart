import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'sessao_usuario.dart';

class MeusPedidosPage extends StatefulWidget {
  const MeusPedidosPage({super.key});

  @override
  State<MeusPedidosPage> createState() => _MeusPedidosPageState();
}

class _MeusPedidosPageState extends State<MeusPedidosPage> {
  static const String apiBase =
      'https://elite-sports-production.up.railway.app';

  static const Color fundo = Color(0xFF0D0D12);
  static const Color topo = Color(0xFF0B0B0F);
  static const Color lateral = Color(0xFF111114);
  static const Color card = Color(0xFF111116);
  static const Color borda = Color(0xFF292932);
  static const Color roxo = Color(0xFF7C2CFF);
  static const Color roxoClaro = Color(0xFFA855F7);
  static const Color cinza = Color(0xFF9292A5);

  String nomeUsuario = 'Usuário';

  bool carregando = true;
  String? erro;

  List<Map<String, dynamic>> pedidos = [];

  @override
  void initState() {
    super.initState();
    carregarPedidos();
  }

  // ==========================================
  // BUSCAR PEDIDOS NA API
  // ==========================================

  Future<void> carregarPedidos() async {
    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final usuario = await SessaoUsuario.ler();

      if (!mounted) return;

      if (usuario == null) {
        Navigator.pop(context);
        return;
      }

      setState(() {
        nomeUsuario = usuario['nome']?.toString() ?? 'Usuário';
      });

      final id = Uri.encodeComponent(usuario['id_usuario'].toString());

      final resposta = await http
          .get(Uri.parse('$apiBase/api/pedidos/usuario/$id'))
          .timeout(const Duration(seconds: 20));

      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (!mounted) return;

      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        final mensagem = dados is Map ? dados['mensagem']?.toString() : null;

        throw Exception(mensagem ?? 'Não foi possível carregar seus pedidos.');
      }

      if (dados is! List) {
        throw const FormatException(
          'O servidor retornou uma lista de pedidos inválida.',
        );
      }

      final lista = <Map<String, dynamic>>[];

      for (final pedido in dados) {
        if (pedido is Map) {
          lista.add(Map<String, dynamic>.from(pedido));
        }
      }

      setState(() {
        pedidos = lista;
        carregando = false;
      });
    } on TimeoutException {
      if (!mounted) return;

      setState(() {
        erro = 'A conexão demorou demais. Tente novamente.';
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        erro = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('FormatException: ', '');
        carregando = false;
      });
    }
  }

  // ==========================================
  // FORMATAR VALORES EM REAL
  // ==========================================

  String formatarPreco(dynamic valor) {
    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(valor?.toString() ?? '');

    if (numero == null || !numero.isFinite) {
      return 'R\$ —';
    }

    final partes = numero.abs().toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final buffer = StringBuffer();

    for (int i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(inteiro[i]);
    }

    final sinal = numero < 0 ? '-' : '';

    return 'R\$ $sinal${buffer.toString()},${partes[1]}';
  }

  // ==========================================
  // FORMATAR DATA DO PEDIDO
  // ==========================================

  String formatarData(dynamic valor) {
    final data = DateTime.tryParse(valor?.toString() ?? '');

    if (data == null) return 'Data indisponível';

    final local = data.toLocal();

    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final ano = local.year.toString();

    return '$dia/$mes/$ano';
  }

  // ==========================================
  // COR DO STATUS
  // ==========================================

  Color corStatus(String status) {
    final texto = status.toLowerCase();

    if (texto.contains('entregue')) {
      return const Color(0xFF4ADE80);
    }

    if (texto.contains('trânsito') || texto.contains('transito')) {
      return const Color(0xFF60A5FA);
    }

    return roxoClaro;
  }

  // ==========================================
  // ENCERRAR SESSÃO
  // ==========================================

  Future<void> sairConta() async {
    await SessaoUsuario.sair();

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  // ==========================================
  // VOLTAR PARA A TELA INICIAL
  // ==========================================

  void irInicio() {
    Navigator.of(context).popUntil((rota) => rota.isFirst);
  }

  // ==========================================
  // TELA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final celular = largura <= 700;

    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Column(
          children: [
            construirTopo(celular),
            Expanded(
              child: SingleChildScrollView(
                child: celular
                    ? Column(
                        children: [
                          construirMenu(horizontal: true),
                          construirConteudo(celular: true),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: largura <= 1000 ? 240 : 290,
                            child: construirMenu(horizontal: false),
                          ),
                          Expanded(child: construirConteudo(celular: false)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TOPO
  // ==========================================

  Widget construirTopo(bool celular) {
    return Container(
      height: celular ? 70 : 80,
      color: topo,
      padding: EdgeInsets.symmetric(horizontal: celular ? 18 : 40),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: roxoClaro, size: 25),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nomeUsuario,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Voltar',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
          ),
          if (!celular) const Text('Voltar'),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Início',
            onPressed: irInicio,
            icon: const Icon(Icons.home_outlined),
          ),
          if (!celular) const Text('Início'),
        ],
      ),
    );
  }

  // ==========================================
  // MENU LATERAL
  // ==========================================

  Widget construirMenu({required bool horizontal}) {
    final botoes = <Widget>[
      itemMenu(
        Icons.person_outline,
        'Minha conta',
        onTap: () => Navigator.pop(context),
      ),
      itemMenu(Icons.shopping_bag_outlined, 'Meus pedidos', ativo: true),
      itemMenu(Icons.logout, 'Sair da conta', onTap: sairConta),
    ];

    if (horizontal) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: lateral,
          border: Border(bottom: BorderSide(color: borda)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: botoes),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 500),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      decoration: const BoxDecoration(
        color: lateral,
        border: Border(right: BorderSide(color: borda)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          botoes[0],
          const SizedBox(height: 8),
          botoes[1],
          const SizedBox(height: 185),
          botoes[2],
        ],
      ),
    );
  }

  Widget itemMenu(
    IconData icone,
    String titulo, {
    bool ativo = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: ativo ? const Color(0xFF26153F) : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: ativo ? roxoClaro : Colors.white, size: 21),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  color: ativo ? roxoClaro : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CONTEÚDO DOS PEDIDOS
  // ==========================================

  Widget construirConteudo({required bool celular}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: celular ? 18 : 40,
        vertical: celular ? 35 : 55,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meus pedidos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Acompanhe seus pedidos realizados.',
                style: TextStyle(color: cinza, fontSize: 15),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: carregando ? null : carregarPedidos,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar pedidos'),
              ),
              const SizedBox(height: 25),

              if (carregando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(color: roxo),
                  ),
                )
              else if (erro != null)
                construirErro()
              else if (pedidos.isEmpty)
                construirVazio()
              else
                Column(
                  children: [
                    for (final pedido in pedidos) ...[
                      construirCardPedido(pedido, celular),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MENSAGEM DE ERRO
  // ==========================================

  Widget construirErro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
          const SizedBox(height: 15),
          Text(
            erro!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: carregarPedidos,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // QUANDO NÃO EXISTEM PEDIDOS
  // ==========================================

  Widget construirVazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 65),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: roxoClaro, size: 60),
          const SizedBox(height: 20),
          const Text(
            'Você ainda não possui pedidos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Quando você finalizar uma compra, ela aparecerá aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cinza, fontSize: 15),
          ),
          const SizedBox(height: 25),
          FilledButton(
            onPressed: irInicio,
            style: FilledButton.styleFrom(
              backgroundColor: roxo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            ),
            child: const Text('Ver produtos'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // CARD DO PEDIDO
  // ==========================================

  Widget construirCardPedido(Map<String, dynamic> pedido, bool celular) {
    final itens = <Map<String, dynamic>>[];

    final listaOriginal = pedido['itens'];

    if (listaOriginal is List) {
      for (final item in listaOriginal) {
        if (item is Map) {
          itens.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final status = pedido['status']?.toString() ?? '';
    final cor = corStatus(status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(celular ? 18 : 24),
      decoration: BoxDecoration(
        color: card,
        border: Border.all(color: borda),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 20,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${pedido['id_pedido'] ?? '—'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Realizado em ${formatarData(pedido['data_pedido'])}',
                    style: const TextStyle(color: cinza, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  status.isEmpty ? 'Status não informado' : status,
                  style: TextStyle(
                    color: cor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          for (final item in itens) ...[
            const Divider(height: 1, color: borda),
            construirItemPedido(item, celular),
          ],

          const Divider(height: 1, color: borda),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Flexible(
                child: Text(
                  'Total do pedido',
                  style: TextStyle(color: cinza, fontSize: 14),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                formatarPreco(pedido['valor_total']),
                style: TextStyle(
                  color: roxoClaro,
                  fontSize: celular ? 19 : 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PRODUTO DENTRO DO PEDIDO
  // ==========================================

  Widget construirItemPedido(Map<String, dynamic> item, bool celular) {
    final tamanho = item['tamanho']?.toString() ?? 'Único';
    final cor = item['cor']?.toString() ?? 'Única';
    final quantidade = item['quantidade']?.toString() ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: celular ? 80 : 105,
            height: celular ? 80 : 105,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF242430),
                  Color(0xFF17171E),
                  Color(0xFF131319),
                ],
              ),
              border: Border.all(color: const Color(0xFF30303B)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: imagemProduto(item['imagem']),
          ),
          SizedBox(width: celular ? 15 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nome_produto']?.toString() ?? 'Produto sem nome',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  formatarPreco(item['preco_unitario']),
                  style: const TextStyle(
                    color: roxoClaro,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 13,
                  runSpacing: 5,
                  children: [
                    Text(
                      'Cor: $cor',
                      style: const TextStyle(color: cinza, fontSize: 13),
                    ),
                    Text(
                      'Tamanho: $tamanho',
                      style: const TextStyle(color: cinza, fontSize: 13),
                    ),
                    Text(
                      'Quantidade: $quantidade',
                      style: const TextStyle(color: cinza, fontSize: 13),
                    ),
                  ],
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

  Widget imagemProduto(dynamic valor) {
    var caminho = valor?.toString().trim() ?? '';

    if (caminho.isEmpty) {
      return iconeSemImagem();
    }

    if (caminho.startsWith('https://') || caminho.startsWith('http://')) {
      return Image.network(
        caminho,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return iconeSemImagem();
        },
      );
    }

    // Converte caminhos do site para os assets Flutter.
    while (caminho.startsWith('./')) {
      caminho = caminho.substring(2);
    }

    if (caminho.startsWith('/')) {
      caminho = caminho.substring(1);
    }

    if (caminho.startsWith('img/')) {
      caminho = 'assets/$caminho';
    }

    if (!caminho.startsWith('assets/img/')) {
      return iconeSemImagem();
    }

    return Image.asset(
      caminho,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return iconeSemImagem();
      },
    );
  }

  Widget iconeSemImagem() {
    return const Icon(Icons.shopping_bag_outlined, color: roxoClaro, size: 35);
  }
}
