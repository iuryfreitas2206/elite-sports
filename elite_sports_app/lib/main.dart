import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_page.dart';
import 'minha_conta_page.dart';
import 'sessao_usuario.dart';
import 'catalogo_page.dart';
import 'produto_page.dart';
import 'carrinho_page.dart';

void main() {
  runApp(const EliteSportsApp());
}

class EliteSportsApp extends StatelessWidget {
  const EliteSportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elite Sports',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111115),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B2CFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color preto = Color(0xFF09090B);
  static const Color cinzaTexto = Color(0xFF8F8F9D);
  static const Color roxo = Color(0xFF7B2CFF);
  static const Color roxoClaro = Color(0xFFA855F7);

  static const String apiBase =
      'https://elite-sports-production.up.railway.app';

  final PageController _bannerController = PageController();
  final TextEditingController _buscaController = TextEditingController();
  Map<String, dynamic>? _usuarioLogado;

  Timer? _bannerTimer;
  int _itensNoCarrinho = 0;
  int _bannerAtual = 0;

  Map<String, String> _precos = {
    'Camiseta Dry Fit': 'R\$ 99,90',
    'Short Esportivo': 'R\$ 79,90',
    'Camiseta Treino': 'R\$ 89,90',
    'Regata Fitness': 'R\$ 69,90',
  };

  final List<_BannerData> _banners = const [
    _BannerData(
      imagem: 'assets/img/banner1.png',
      tag: 'PERFORMANCE • CONFORTO • ESTILO',
      titulo1: 'VISTA SUA',
      titulo2: 'PAIXÃO',
      descricao: 'Roupas esportivas pensadas para quem vive o esporte dentro e fora do jogo.',
      botao: 'Ver produtos',
    ),
    _BannerData(
      imagem: 'assets/img/banner2.png',
      titulo1: 'CHUTEIRAS ELITE',
      titulo2: 'SPEED',
      descricao: 'Performance, conforto e estilo para o seu jogo.',
    ),
    _BannerData(
      imagem: 'assets/img/banner3.png',
      tag: 'ELITE SPORTS',
      titulo1: 'SUPERE SEUS',
      titulo2: 'LIMITES',
      descricao: 'Performance, conforto e estilo para acompanhar o seu ritmo.',
      botao: 'Ver produtos',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _carregarPrecos();
    _atualizarContadorCarrinho();
    _carregarSessao();

    _bannerTimer = Timer.periodic(
      const Duration(seconds: 100),
      (_) => _proximoBanner(),
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarPrecos() async {
    try {
      final resposta = await http.get(Uri.parse('$apiBase/api/produtos'));
      if (resposta.statusCode < 200 || resposta.statusCode >= 300) return;

      final dados = jsonDecode(resposta.body);
      if (dados is! List) return;

      final novos = Map<String, String>.from(_precos);

      for (final item in dados) {
        if (item is! Map) continue;
        final nome = item['nome']?.toString().trim();
        final preco = double.tryParse(item['preco'].toString());
        if (nome == null || preco == null || !novos.containsKey(nome)) continue;

        novos[nome] = 'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';
      }

      if (!mounted) return;
      setState(() => _precos = novos);
    } catch (_) {}
  }

  // ==========================================
  // CARREGAR SESSÃO DO USUÁRIO
  // ==========================================

  Future<void> _carregarSessao() async {
    final usuario = await SessaoUsuario.ler();

    if (!mounted) return;

    setState(() {
      _usuarioLogado = usuario;
    });
  }

  // ==========================================
  // ABRIR LOGIN
  // ==========================================

  Future<void> _abrirLogin() async {
    final entrou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );

    if (!mounted) return;

    if (entrou == true) {
      await _carregarSessao();
    }
  }

  // ==========================================
  // ABRIR MINHA CONTA
  // ==========================================

  Future<void> _abrirConta() async {
    // Se ainda não fez login, abre a tela de login.
    if (_usuarioLogado == null) {
      await _abrirLogin();

      if (!mounted || _usuarioLogado == null) {
        return;
      }
    }

    // Abre a página Minha Conta.
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const MinhaContaPage()),
    );

    // Atualiza os dados ao voltar.
    if (mounted) {
      await _carregarSessao();
    }
  }

  // ==========================================
  // NOME EXIBIDO NO CABEÇALHO
  // ==========================================

  String get _rotuloConta {
    if (_usuarioLogado == null) {
      return 'Login';
    }

    final nome = _usuarioLogado!['nome']?.toString().trim() ?? '';

    return nome.isEmpty ? 'Minha conta' : nome.split(' ').first;
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: const Color(0xFF17171C)),
    );
  }

  void _proximoBanner() {
    if (!_bannerController.hasClients) return;
    final proximo = (_bannerAtual + 1) % _banners.length;
    _bannerController.animateToPage(
      proximo,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _bannerAnterior() {
    if (!_bannerController.hasClients) return;
    final anterior = (_bannerAtual - 1 + _banners.length) % _banners.length;
    _bannerController.animateToPage(
      anterior,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final desktop = largura > 1000;
    final celular = largura <= 700;
    final celularPequeno = largura <= 480;

    return Scaffold(
      backgroundColor: const Color(0xFF111115),
      body: SafeArea(
        child: Column(
          children: [
            _header(desktop: desktop, celular: celular),
            _menu(celular: celular),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _banner(
                      desktop: desktop,
                      celular: celular,
                      celularPequeno: celularPequeno,
                    ),
                    _beneficios(desktop: desktop, celular: celular),
                    _categorias(desktop: desktop, celular: celular),
                    _destaques(
                      desktop: desktop,
                      celular: celular,
                      celularPequeno: celularPequeno,
                    ),
                    _cta(celular: celular),
                    _rodape(desktop: desktop, celular: celular),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header({required bool desktop, required bool celular}) {
    if (celular) {
      return Container(
        color: preto,
        padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
        child: Row(
          children: [
            _logo(tamanhoLogo: 34, tamanhoTexto: 20),
            const Spacer(),
            _botaoIconeMobile(icon: Icons.person_outline, onTap: _abrirConta),
            const SizedBox(width: 12),
            _carrinhoMobile(),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      color: preto,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? MediaQuery.sizeOf(context).width * .05 : 25,
        vertical: 14,
      ),
      child: Row(
        children: [
          _logo(),
          const SizedBox(width: 35),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: _campoBusca(),
              ),
            ),
          ),
          const SizedBox(width: 35),
          _acaoHeader(Icons.home_outlined, 'Início', () {}),
          const SizedBox(width: 25),
          _acaoHeader(Icons.person_outline, _rotuloConta, _abrirConta),
          const SizedBox(width: 25),
          _carrinhoDesktop(),
        ],
      ),
    );
  }

  Widget _logo({double tamanhoLogo = 40, double tamanhoTexto = 23}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/img/logo.png',
          width: tamanhoLogo,
          height: tamanhoLogo,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Elite ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: tamanhoTexto,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: 'Sports',
                style: TextStyle(
                  color: roxo,
                  fontSize: tamanhoTexto,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _campoBusca() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _buscaController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Busque por camisetas, shorts, acessórios...',
          hintStyle: const TextStyle(color: Color(0xFF777785), fontSize: 14),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFB5B5BF),
            size: 19,
          ),
          filled: true,
          fillColor: const Color(0xFF19191F),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF25252C)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: roxo),
          ),
        ),
      ),
    );
  }

  Widget _acaoHeader(IconData icon, String texto, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFEEEEEE), size: 20),
            const SizedBox(width: 7),
            Text(
              texto,
              style: const TextStyle(
                color: Color(0xFFEEEEEE),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CONTADOR DO CARRINHO
  // ==========================================

  Future<void> _atualizarContadorCarrinho() async {
    final total = await CarrinhoPage.contarItens();

    if (!mounted) return;

    setState(() {
      _itensNoCarrinho = total;
    });
  }

  // ==========================================
  // ABRIR O CARRINHO
  // ==========================================

  Future<void> _abrirCarrinho() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CarrinhoPage()),
    );

    if (!mounted) return;

    await _atualizarContadorCarrinho();
  }

  Widget _carrinhoDesktop() {
    return InkWell(
      onTap: _abrirCarrinho,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 23,
              ),
            ),
            Positioned(top: -3, right: -4, child: _contadorCarrinho()),
          ],
        ),
      ),
    );
  }

  Widget _botaoIconeMobile({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF18181D),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 21, color: Colors.white),
        ),
      ),
    );
  }

  Widget _carrinhoMobile() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _botaoIconeMobile(
          icon: Icons.shopping_cart_outlined,
          onTap: _abrirCarrinho,
        ),
        Positioned(top: -3, right: -4, child: _contadorCarrinho()),
      ],
    );
  }

  Widget _contadorCarrinho() {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [roxo, roxoClaro]),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: preto, width: 2),
      ),
      child: Text(
        _itensNoCarrinho > 9 ? '9+' : '$_itensNoCarrinho',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _menu({required bool celular}) {
    const itens = ['Início', 'Camisetas', 'Shorts', 'Acessórios'];

    return Container(
      height: 54,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF101013),
        border: Border(
          top: BorderSide(color: Color(0xFF17171D)),
          bottom: BorderSide(color: Color(0xFF24242A)),
        ),
      ),
      child: celular
          ? ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: itens.length,
              separatorBuilder: (_, __) => const SizedBox(width: 25),
              itemBuilder: (_, index) =>
                  _menuItem(texto: itens[index], ativo: index == 0),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < itens.length; i++) ...[
                  _menuItem(texto: itens[i], ativo: i == 0),
                  if (i < itens.length - 1) const SizedBox(width: 55),
                ],
              ],
            ),
    );
  }

  // ==========================================
  // ABRIR CATÁLOGO DE PRODUTOS
  // ==========================================

  Future<void> _abrirCatalogo(String categoria) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CatalogoPage(categoria: categoria),
      ),
    );

    if (!mounted) return;

    await _atualizarContadorCarrinho();
  }

  Widget _menuItem({required String texto, required bool ativo}) {
    return InkWell(
      onTap: () {
        if (!ativo) {
          _abrirCatalogo(texto);
        }
      },
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: ativo
              ? const Border(bottom: BorderSide(color: roxo, width: 3))
              : null,
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: ativo ? Colors.white : const Color(0xFFAAAAB5),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _banner({
    required bool desktop,
    required bool celular,
    required bool celularPequeno,
  }) {
    final alturaTela = MediaQuery.sizeOf(context).height;
    final larguraTela = MediaQuery.sizeOf(context).width;

    double altura;

    if (celular) {
      altura = (larguraTela * 0.60 + 325).clamp(510.0, 700.0);
    } else {
      altura = (alturaTela - 218).clamp(560.0, 900.0);
    }

    return SizedBox(
      height: altura,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _banners.length,
              onPageChanged: (index) {
                setState(() => _bannerAtual = index);
              },
              itemBuilder: (_, index) => _bannerSlide(
                banner: _banners[index],
                desktop: desktop,
                celular: celular,
                celularPequeno: celularPequeno,
              ),
            ),
          ),
          Positioned(
            left: celular ? 8 : 25,
            top: celular ? larguraTela * 0.22 : 0,
            bottom: celular ? null : 0,
            child: Center(
              child: _botaoSetaBanner(
                icon: Icons.chevron_left,
                onTap: _bannerAnterior,
                tamanho: celularPequeno
                    ? 34
                    : celular
                    ? 36
                    : 46,
              ),
            ),
          ),
          Positioned(
            right: celular ? 8 : 25,
            top: celular ? larguraTela * 0.22 : 0,
            bottom: celular ? null : 0,
            child: Center(
              child: _botaoSetaBanner(
                icon: Icons.chevron_right,
                onTap: _proximoBanner,
                tamanho: celularPequeno
                    ? 34
                    : celular
                    ? 36
                    : 46,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                final ativo = _bannerAtual == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: ativo ? 27 : 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: ativo ? roxo : Colors.white.withValues(alpha: .4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerSlide({
    required _BannerData banner,
    required bool desktop,
    required bool celular,
    required bool celularPequeno,
  }) {
    final largura = MediaQuery.sizeOf(context).width;

    final paddingEsquerdo = celularPequeno
        ? 22.0
        : celular
        ? 28.0
        : (largura * .06).clamp(45.0, 115.0);

    final paddingDireito = celular
        ? 22.0
        : celular
        ? largura * .32
        : largura * .50;

    final titulo = celularPequeno
        ? (largura * .09).clamp(30.0, 40.0)
        : celular
        ? (largura * .08).clamp(34.0, 48.0)
        : (largura * .047).clamp(46.0, 82.0);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              banner.imagem,
              fit: celular ? BoxFit.cover : BoxFit.fitHeight,
              alignment: celular
                  ? const Alignment(0.45, 0.0)
                  : Alignment.centerRight,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: celular
                      ? const [0.0, .42, 1.0]
                      : const [0.0, .34, .70, 1.0],
                  colors: celular
                      ? const [
                          Color.fromRGBO(0, 0, 0, .94),
                          Color.fromRGBO(0, 0, 0, .78),
                          Color.fromRGBO(0, 0, 0, .30),
                        ]
                      : const [
                          Color.fromRGBO(0, 0, 0, .94),
                          Color.fromRGBO(0, 0, 0, .72),
                          Color.fromRGBO(0, 0, 0, .20),
                          Color.fromRGBO(0, 0, 0, .15),
                        ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: paddingEsquerdo,
              right: paddingDireito,
              bottom: 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (banner.tag != null) ...[
                  Text(
                    banner.tag!,
                    style: TextStyle(
                      color: const Color(0xFFB8B8C2),
                      fontSize: celularPequeno ? 10 : 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: celularPequeno ? 2 : 3,
                    ),
                  ),
                  SizedBox(height: celularPequeno ? 12 : 18),
                ],
                Text(
                  banner.titulo1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titulo,
                    height: celular ? .98 : .95,
                    letterSpacing: celular ? -2 : -3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  banner.titulo2,
                  style: TextStyle(
                    color: roxo,
                    fontSize: titulo,
                    height: celular ? .98 : .95,
                    letterSpacing: celular ? -2 : -3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: celularPequeno ? 17 : 24),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: celular ? 390 : 520),
                  child: Text(
                    banner.descricao,
                    style: TextStyle(
                      color: const Color(0xFFC4C4CE),
                      fontSize: celularPequeno
                          ? 13
                          : celular
                          ? 14
                          : (largura * .0105).clamp(14.0, 18.0),
                      height: celular ? 1.5 : 1.6,
                    ),
                  ),
                ),
                if (banner.botao != null) ...[
                  SizedBox(height: celularPequeno ? 20 : 30),
                  FilledButton(
                    onPressed: () => _abrirCatalogo('Camisetas'),
                    style: FilledButton.styleFrom(
                      backgroundColor: roxo,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: celularPequeno ? 18 : 25,
                        vertical: celularPequeno ? 13 : 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner.botao!,
                          style: TextStyle(
                            fontSize: celularPequeno ? 13 : 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 15),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoSetaBanner({
    required IconData icon,
    required VoidCallback onTap,
    required double tamanho,
  }) {
    return Material(
      color: const Color.fromRGBO(28, 28, 34, .85),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: tamanho,
          height: tamanho,
          child: Icon(icon, color: Colors.white, size: tamanho * .57),
        ),
      ),
    );
  }

  Widget _beneficios({required bool desktop, required bool celular}) {
    const beneficios = [
      (
        Icons.local_shipping_outlined,
        'Entrega para todo o Brasil',
        'Receba seus produtos com segurança.',
      ),
      (Icons.shield_outlined, 'Compra segura', 'Seus dados protegidos.'),
      (
        Icons.credit_card_outlined,
        'Pagamento facilitado',
        'Mais comodidade para comprar.',
      ),
      (
        Icons.support_agent_outlined,
        'Atendimento',
        'Conte com a Elite Sports.',
      ),
    ];

    final colunas = celular ? 2 : (desktop ? 4 : 2);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF101014),
        border: Border(
          top: BorderSide(color: Color(0xFF292930)),
          bottom: BorderSide(color: Color(0xFF292930)),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: desktop
            ? MediaQuery.sizeOf(context).width * .05
            : celular
            ? 20
            : 25,
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final larguraItem = constraints.maxWidth / colunas;

          return Wrap(
            children: [
              for (int i = 0; i < beneficios.length; i++)
                SizedBox(
                  width: larguraItem,
                  child: _beneficioItem(
                    icon: beneficios[i].$1,
                    titulo: beneficios[i].$2,
                    descricao: beneficios[i].$3,
                    mostrarBordaDireita: colunas > 1 && (i + 1) % colunas != 0,
                    mostrarBordaBaixo: colunas == 1 || (colunas == 2 && i < 2),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _beneficioItem({
    required IconData icon,
    required String titulo,
    required String descricao,
    required bool mostrarBordaDireita,
    required bool mostrarBordaBaixo,
  }) {
    final compacto = MediaQuery.sizeOf(context).width <= 700;

    return Container(
      height: compacto ? 150 : null,
      constraints: const BoxConstraints(minHeight: 92),
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 25,
        vertical: compacto ? 12 : 20,
      ),
      decoration: BoxDecoration(
        border: Border(
          right: mostrarBordaDireita
              ? const BorderSide(color: Color(0xFF292930))
              : BorderSide.none,
          bottom: mostrarBordaBaixo
              ? const BorderSide(color: Color(0xFF292930))
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compacto ? 34 : 45,
            height: compacto ? 34 : 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: roxo.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: roxo, size: compacto ? 22 : 26),
          ),
          SizedBox(width: compacto ? 8 : 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compacto ? 11 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  descricao,
                  style: TextStyle(
                    color: cinzaTexto,
                    fontSize: compacto ? 10 : 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categorias({required bool desktop, required bool celular}) {
    const categorias = [
      ('Camisetas', 'assets/img/camiseta-dryfit/DryFit-preta-1.png'),
      ('Shorts', 'assets/img/short-esportivo/Short-Preto-1.png'),
      ('Acessórios', 'assets/img/acessorios/Bola_futebol_3.png'),
    ];

    final colunas = celular
        ? 1
        : desktop
        ? 3
        : 2;

    return Container(
      width: double.infinity,
      color: const Color(0xFF111115),
      padding: EdgeInsets.symmetric(
        horizontal: celular ? 18 : MediaQuery.sizeOf(context).width * .05,
        vertical: celular ? 55 : 80,
      ),
      child: Column(
        children: [
          _tituloSecao(
            tag: 'CATEGORIAS',
            titulo: 'Encontre seu estilo',
            descricao:
                'Escolha a categoria e encontre o produto ideal para você.',
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: LayoutBuilder(
              builder: (_, constraints) {
                const gap = 22.0;
                final larguraCard =
                    (constraints.maxWidth - gap * (colunas - 1)) / colunas;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final categoria in categorias)
                      SizedBox(
                        width: larguraCard,
                        height: celular ? 260 : 280,
                        child: _categoriaCard(
                          titulo: categoria.$1,
                          imagem: categoria.$2,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSecao({
    required String tag,
    required String titulo,
    required String descricao,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 42),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 27, height: 2, color: roxo),
              const SizedBox(width: 8),
              Text(
                tag,
                style: const TextStyle(
                  color: roxoClaro,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: (MediaQuery.sizeOf(context).width * .03).clamp(
                28.0,
                38.0,
              ),
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            descricao,
            textAlign: TextAlign.center,
            style: const TextStyle(color: cinzaTexto, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _categoriaCard({required String titulo, required String imagem}) {
    return Material(
      color: const Color(0xFF18181D),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirCatalogo(titulo),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF202027), Color(0xFF141419)],
                ),
              ),
              padding: const EdgeInsets.all(25),
              child: Image.asset(imagem, fit: BoxFit.contain),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.25, 1.0],
                  colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, .85)],
                ),
              ),
            ),
            Positioned(
              left: 25,
              right: 25,
              bottom: 25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver produtos',
                        style: TextStyle(
                          color: roxoClaro,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, color: roxoClaro, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destaques({
    required bool desktop,
    required bool celular,
    required bool celularPequeno,
  }) {
    final produtos = [
      _ProdutoDestaqueData(
        imagem: 'assets/img/camiseta-dryfit/DryFit-azul-1.png',
        categoria: 'CAMISETAS',
        nome: 'Camiseta Dry Fit',
        preco: _precos['Camiseta Dry Fit'] ?? 'R\$ 99,90',
        badge: true,
      ),
      _ProdutoDestaqueData(
        imagem: 'assets/img/short-esportivo/Short-Preto-1.png',
        categoria: 'SHORTS',
        nome: 'Short Esportivo',
        preco: _precos['Short Esportivo'] ?? 'R\$ 79,90',
      ),
      _ProdutoDestaqueData(
        imagem: 'assets/img/camiseta-treino/Camiseta treino-preta-1.png',
        categoria: 'CAMISETAS',
        nome: 'Camiseta Treino',
        preco: _precos['Camiseta Treino'] ?? 'R\$ 89,90',
      ),
      _ProdutoDestaqueData(
        imagem: 'assets/img/regata/regata-Preta-1.png',
        imagemFallback: 'assets/img/regata/regata-Preta-1.png',
        categoria: 'TREINO',
        nome: 'Regata Fitness',
        preco: _precos['Regata Fitness'] ?? 'R\$ 69,90',
      ),
    ];

    final colunas = celular
        ? 1
        : desktop
        ? 3
        : 2;

    return Container(
      width: double.infinity,
      color: const Color(0xFF111115),
      padding: EdgeInsets.fromLTRB(
        celular ? 18 : MediaQuery.sizeOf(context).width * .05,
        celular ? 55 : 75,
        celular ? 18 : MediaQuery.sizeOf(context).width * .05,
        celular ? 65 : 90,
      ),
      child: Column(
        children: [
          _tituloSecao(
            tag: 'DESTAQUES',
            titulo: 'Produtos em destaque',
            descricao: 'Alguns dos produtos mais procurados da Elite Sports.',
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: LayoutBuilder(
              builder: (_, constraints) {
                const gap = 24.0;
                final larguraCard =
                    (constraints.maxWidth - gap * (colunas - 1)) / colunas;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final produto in produtos)
                      SizedBox(
                        width: larguraCard,
                        child: _produtoDestaque(
                          produto,
                          alturaImagem: celularPequeno
                              ? 280
                              : celular
                              ? 330
                              : 300,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ABRIR DETALHES DO PRODUTO
  // ==========================================

  Future<void> _abrirDetalhesProduto(String nome) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProdutoPage(nomeProduto: nome)),
    );

    if (!mounted) return;

    await _atualizarContadorCarrinho();
  }

  Widget _produtoDestaque(
    _ProdutoDestaqueData produto, {
    required double alturaImagem,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirDetalhesProduto(produto.nome),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF191920), Color(0xFF15151B)],
            ),
            border: Border.all(color: const Color(0xFF303038)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: alturaImagem,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF22222A), Color(0xFF18181F)],
                          ),
                        ),
                        child: _AssetComFallback(
                          imagem: produto.imagem,
                          fallback: produto.imagemFallback,
                        ),
                      ),
                    ),

                    if (produto.badge)
                      Positioned(
                        top: 15,
                        left: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [roxo, roxoClaro],
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            'DESTAQUE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: 175),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.categoria,
                      style: const TextStyle(
                        color: roxoClaro,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      produto.nome,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      produto.preco,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => _abrirDetalhesProduto(produto.nome),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF09090D),
                          side: const BorderSide(color: Color(0xFF303039)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ver produto',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cta({required bool celular}) {
    final conteudo = Column(
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
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: const [
              TextSpan(text: 'Mais que esporte,\n'),
              TextSpan(
                text: 'é estilo de vida.',
                style: TextStyle(color: roxoClaro),
              ),
            ],
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: (MediaQuery.sizeOf(context).width * .03).clamp(
              27.0,
              40.0,
            ),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Performance, conforto e estilo em cada detalhe.',
          style: TextStyle(color: Color(0xFF9999A5)),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: celular ? 25 : MediaQuery.sizeOf(context).width * .07,
        vertical: celular ? 45 : 55,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF160B28), Color(0xFF0D0D11)],
          stops: [0, .55],
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF2F1A55)),
          bottom: BorderSide(color: Color(0xFF2F1A55)),
        ),
      ),
      child: celular
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [conteudo, const SizedBox(height: 28), _botaoCta()],
            )
          : Row(
              children: [
                Expanded(child: conteudo),
                const SizedBox(width: 30),
                _botaoCta(),
              ],
            ),
    );
  }

  Widget _botaoCta() {
    return FilledButton(
      onPressed: () => _abrirCatalogo('Camisetas'),
      style: FilledButton.styleFrom(
        backgroundColor: roxo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Conhecer produtos',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );
  }

  Widget _rodape({required bool desktop, required bool celular}) {
    final colunas = [
      _footerMarca(),
      _footerColuna(
        titulo: 'Navegação',
        itens: const ['Início', 'Camisetas', 'Shorts', 'Acessórios'],
      ),
      _footerColuna(
        titulo: 'Minha conta',
        itens: const ['Entrar', 'Minha conta', 'Meus pedidos', 'Carrinho'],
      ),
      _footerRedes(),
    ];

    final numeroColunas = desktop ? 4 : 2;

    return Container(
      width: double.infinity,
      color: const Color(0xFF08080A),
      padding: EdgeInsets.fromLTRB(
        celular ? 25 : MediaQuery.sizeOf(context).width * .06,
        celular ? 45 : 55,
        celular ? 25 : MediaQuery.sizeOf(context).width * .06,
        25,
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: LayoutBuilder(
              builder: (_, constraints) {
                final gap = celular ? 12.0 : 50.0;
                final largura =
                    (constraints.maxWidth - gap * (numeroColunas - 1)) /
                    numeroColunas;

                return Wrap(
                  spacing: gap,
                  runSpacing: 35,
                  children: [
                    for (final coluna in colunas)
                      SizedBox(width: largura, child: coluna),
                  ],
                );
              },
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Container(
              margin: const EdgeInsets.only(top: 45),
              padding: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF242429))),
              ),
              child: celular
                  ? const Row(
                      children: [
                        Expanded(
                          child: Text(
                            '© 2026 Elite Sports.',
                            style: TextStyle(
                              color: Color(0xFF686875),
                              fontSize: 10,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Todos os direitos reservados.',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: Color(0xFF686875),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '© 2026 Elite Sports.',
                          style: TextStyle(
                            color: Color(0xFF686875),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Todos os direitos reservados.',
                          style: TextStyle(
                            color: Color(0xFF686875),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerMarca() {
    final celular = MediaQuery.sizeOf(context).width <= 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _logo(tamanhoLogo: celular ? 25 : 40, tamanhoTexto: celular ? 16 : 23),
        const SizedBox(height: 10),
        const Text(
          'Mais que esporte, é estilo de vida.',
          style: TextStyle(color: Color(0xFF888894), fontSize: 13, height: 1.6),
        ),
      ],
    );
  }

  Widget _footerColuna({required String titulo, required List<String> itens}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in itens)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _aviso(item),
              child: Text(
                item,
                style: const TextStyle(color: Color(0xFF9999A5), fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  Widget _footerRedes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Siga a Elite Sports',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _socialButton(icon: Icons.camera_alt_outlined, texto: 'Instagram'),
            _socialButton(icon: Icons.chat_bubble_outline, texto: 'WhatsApp'),
            _socialButton(icon: Icons.music_note, texto: 'TikTok'),
          ],
        ),
      ],
    );
  }

  Widget _socialButton({required IconData icon, required String texto}) {
    return Tooltip(
      message: texto,
      child: InkWell(
        onTap: () => _aviso(texto),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF303038)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _AssetComFallback extends StatefulWidget {
  final String imagem;
  final String? fallback;

  const _AssetComFallback({required this.imagem, this.fallback});

  @override
  State<_AssetComFallback> createState() => _AssetComFallbackState();
}

class _AssetComFallbackState extends State<_AssetComFallback> {
  bool usandoFallback = false;

  @override
  Widget build(BuildContext context) {
    final caminho = usandoFallback && widget.fallback != null
        ? widget.fallback!
        : widget.imagem;

    return Image.asset(
      caminho,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        if (!usandoFallback && widget.fallback != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => usandoFallback = true);
          });
          return const SizedBox.shrink();
        }

        return const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFF777785),
            size: 42,
          ),
        );
      },
    );
  }
}

class _BannerData {
  final String imagem;
  final String? tag;
  final String titulo1;
  final String titulo2;
  final String descricao;
  final String? botao;

  const _BannerData({
    required this.imagem,
    this.tag,
    required this.titulo1,
    required this.titulo2,
    required this.descricao,
    this.botao,
  });
}

class _ProdutoDestaqueData {
  final String imagem;
  final String? imagemFallback;
  final String categoria;
  final String nome;
  final String preco;
  final bool badge;

  const _ProdutoDestaqueData({
    required this.imagem,
    this.imagemFallback,
    required this.categoria,
    required this.nome,
    required this.preco,
    this.badge = false,
  });
}
