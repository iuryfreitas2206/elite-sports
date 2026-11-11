import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'sessao_usuario.dart';
import 'meus_pedidos_page.dart';

class MinhaContaPage extends StatefulWidget {
  const MinhaContaPage({super.key});

  @override
  State<MinhaContaPage> createState() => _MinhaContaPageState();
}

class _MinhaContaPageState extends State<MinhaContaPage> {
  static const _apiBase = 'https://elite-sports-production.up.railway.app';

  static const _fundo = Color(0xFF0D0D12);
  static const _topo = Color(0xFF0B0B0F);
  static const _lateral = Color(0xFF111114);
  static const _card = Color(0xFF15151B);
  static const _borda = Color(0xFF292930);
  static const _roxo = Color(0xFF7B2CFF);
  static const _roxoClaro = Color(0xFFA855F7);
  static const _textoSecundario = Color(0xFF9B9BAA);

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();

  Map<String, dynamic>? _usuario;
  String _nomeTopo = 'Usuário';

  bool _carregando = true;
  bool _salvando = false;
  bool _editando = false;

  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDadosUsuario();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  void _mensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // ==========================================
  // CARREGAR DADOS DA API
  // ==========================================

  Future<void> _carregarDadosUsuario() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }

    try {
      final sessao = await SessaoUsuario.ler();

      if (!mounted) return;

      if (sessao == null) {
        Navigator.pop(context, true);
        return;
      }

      final id = Uri.encodeComponent(sessao['id_usuario'].toString());

      final resposta = await http
          .get(Uri.parse('$_apiBase/api/usuarios/$id'))
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (resposta.statusCode == 401 || resposta.statusCode == 403) {
        await SessaoUsuario.sair();

        if (!mounted) return;

        _mensagem('Sessão expirada. Entre novamente.');
        Navigator.pop(context, true);
        return;
      }

      Map<String, dynamic> dados = {};

      try {
        final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));

        if (corpo is Map<String, dynamic>) {
          dados = corpo;
        }
      } catch (_) {
        // Resposta sem JSON válido.
      }

      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        throw Exception(
          dados['mensagem']?.toString() ??
              'Não foi possível carregar os dados.',
        );
      }

      if (dados.isEmpty) {
        throw Exception('O servidor retornou dados inválidos.');
      }

      final atualizado = <String, dynamic>{...sessao, ...dados};

      await SessaoUsuario.salvar(atualizado);

      if (!mounted) return;

      setState(() {
        _usuario = atualizado;

        _nomeTopo = atualizado['nome']?.toString() ?? 'Usuário';

        _nomeController.text = atualizado['nome']?.toString() ?? '';

        _emailController.text = atualizado['email']?.toString() ?? '';

        _cpfController.text = atualizado['cpf']?.toString() ?? '';

        _telefoneController.text = atualizado['telefone']?.toString() ?? '';

        _carregando = false;
        _erro = null;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _carregando = false;

        _erro = erro is TimeoutException
            ? 'A conexão demorou demais. Tente novamente.'
            : erro.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ==========================================
  // SALVAR ALTERAÇÕES
  // ==========================================

  Future<void> _salvarDados() async {
    if (_salvando || _usuario == null) return;

    final nome = _nomeController.text.trim();
    final telefone = _telefoneController.text.trim();

    if (nome.isEmpty) {
      _mensagem('Informe seu nome.');
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final id = Uri.encodeComponent(_usuario!['id_usuario'].toString());

      final resposta = await http
          .put(
            Uri.parse('$_apiBase/api/usuarios/$id'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'nome': nome, 'telefone': telefone}),
          )
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      Map<String, dynamic> dados = {};

      try {
        final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));

        if (corpo is Map<String, dynamic>) {
          dados = corpo;
        }
      } catch (_) {
        // Resposta sem JSON válido.
      }

      if (resposta.statusCode < 200 || resposta.statusCode >= 300) {
        _mensagem(
          dados['mensagem']?.toString() ??
              'Não foi possível atualizar os dados.',
        );
        return;
      }

      final atualizado = <String, dynamic>{
        ..._usuario!,
        'nome': nome,
        'telefone': telefone,
      };

      await SessaoUsuario.salvar(atualizado);

      if (!mounted) return;

      setState(() {
        _usuario = atualizado;
        _nomeTopo = nome;
        _editando = false;
      });

      _mensagem('Dados atualizados com sucesso!');

      await _carregarDadosUsuario();
    } on TimeoutException {
      _mensagem(
        'A conexão demorou demais. Verifique os dados e tente novamente.',
      );
    } catch (_) {
      _mensagem('Não foi possível conectar com o servidor.');
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  // ==========================================
  // EDITAR OU CANCELAR EDIÇÃO
  // ==========================================

  void _alternarEdicao() {
    if (_editando && _usuario != null) {
      _nomeController.text = _usuario!['nome']?.toString() ?? '';

      _telefoneController.text = _usuario!['telefone']?.toString() ?? '';
    }

    setState(() {
      _editando = !_editando;
    });
  }

  // ==========================================
  // SAIR DA CONTA
  // ==========================================

  Future<void> _sairConta() async {
    await SessaoUsuario.sair();

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  // ==========================================
  // CONSTRUÇÃO DA TELA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final compacto = MediaQuery.sizeOf(context).width <= 700;

    return Scaffold(
      backgroundColor: _fundo,
      body: SafeArea(
        child: Column(
          children: [
            _cabecalhoTopo(compacto),
            Expanded(
              child: SingleChildScrollView(
                child: compacto
                    ? Column(
                        children: [
                          _menu(horizontal: true),
                          _conteudo(compacto: true),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width <= 1000
                                ? 240
                                : 290,
                            child: _menu(horizontal: false),
                          ),
                          Expanded(child: _conteudo(compacto: false)),
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
  // CABEÇALHO SUPERIOR
  // ==========================================

  Widget _cabecalhoTopo(bool compacto) {
    return Container(
      height: compacto ? 70 : 80,
      color: _topo,
      padding: EdgeInsets.symmetric(horizontal: compacto ? 18 : 40),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: _roxoClaro, size: 26),
          const SizedBox(width: 12),
          if (!compacto)
            Expanded(
              child: Text(
                _nomeTopo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            const Spacer(),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: Text(compacto ? '' : 'Voltar'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home_outlined),
            label: Text(compacto ? '' : 'Início'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MENU DA CONTA
  // ==========================================

  Widget _menu({required bool horizontal}) {
    final itens = <Widget>[
      _itemMenu(Icons.person_outline, 'Minha conta', ativo: true),
      _itemMenu(
        Icons.shopping_bag_outlined,
        'Meus pedidos',
        onTap: () async {
          final saiu = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const MeusPedidosPage()),
          );

          if (!mounted) return;

          if (saiu == true) {
            Navigator.pop(context, true);
          }
        },
      ),
      _itemMenu(Icons.logout, 'Sair da conta', onTap: _sairConta),
    ];

    if (horizontal) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: _lateral,
          border: Border(bottom: BorderSide(color: _borda)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: itens),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 500),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      decoration: const BoxDecoration(
        color: _lateral,
        border: Border(right: BorderSide(color: _borda)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          itens[0],
          const SizedBox(height: 8),
          itens[1],
          const SizedBox(height: 185),
          itens[2],
        ],
      ),
    );
  }

  Widget _itemMenu(
    IconData icone,
    String titulo, {
    bool ativo = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: ativo ? const Color(0xFF26153F) : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: ativo ? _roxoClaro : Colors.white, size: 21),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  color: ativo ? _roxoClaro : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // CONTEÚDO PRINCIPAL
  // ==========================================

  Widget _conteudo({required bool compacto}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 18 : 40,
        vertical: compacto ? 35 : 55,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compacto)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_titulo(), const SizedBox(height: 20), _botaoEditar()],
            )
          else
            Row(
              children: [
                Expanded(child: _titulo()),
                const SizedBox(width: 16),
                _botaoEditar(),
              ],
            ),
          const SizedBox(height: 35),
          if (_carregando)
            const Center(child: CircularProgressIndicator(color: _roxo))
          else if (_erro != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: _carregarDadosUsuario,
                  child: const Text('Tentar novamente'),
                ),
              ],
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                color: _card,
                border: Border.all(color: _borda),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _linhaDado(
                    Icons.person_outline,
                    'Nome',
                    _nomeController,
                    editavel: true,
                    compacto: compacto,
                  ),
                  const Divider(height: 1, color: _borda),
                  _linhaDado(
                    Icons.email_outlined,
                    'E-mail',
                    _emailController,
                    compacto: compacto,
                  ),
                  const Divider(height: 1, color: _borda),
                  _linhaDado(
                    Icons.badge_outlined,
                    'CPF',
                    _cpfController,
                    compacto: compacto,
                  ),
                  const Divider(height: 1, color: _borda),
                  _linhaDado(
                    Icons.phone_outlined,
                    'Telefone',
                    _telefoneController,
                    editavel: true,
                    compacto: compacto,
                    hint: 'Adicionar telefone',
                    teclado: TextInputType.phone,
                  ),
                ],
              ),
            ),
            if (_editando) ...[
              const SizedBox(height: 25),
              SizedBox(
                width: compacto ? double.infinity : null,
                child: FilledButton(
                  onPressed: _salvando ? null : _salvarDados,
                  style: FilledButton.styleFrom(
                    backgroundColor: _roxo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 17,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _salvando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Salvar alterações'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TÍTULO DA PÁGINA
  // ==========================================

  Widget _titulo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minha conta',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        Text(
          'Veja e edite suas informações pessoais.',
          style: TextStyle(color: _textoSecundario, fontSize: 15),
        ),
      ],
    );
  }

  // ==========================================
  // BOTÃO EDITAR DADOS
  // ==========================================

  Widget _botaoEditar() {
    return OutlinedButton.icon(
      onPressed: (_carregando || _erro != null || _salvando)
          ? null
          : _alternarEdicao,
      icon: Icon(_editando ? Icons.close : Icons.edit_outlined, size: 18),
      label: Text(_editando ? 'Cancelar edição' : 'Editar dados'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _roxoClaro,
        side: const BorderSide(color: _roxoClaro),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  // ==========================================
  // CAMPOS DE INFORMAÇÕES
  // ==========================================

  Widget _linhaDado(
    IconData icone,
    String titulo,
    TextEditingController controller, {
    bool editavel = false,
    required bool compacto,
    String? hint,
    TextInputType? teclado,
  }) {
    final habilitado = editavel && _editando;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 18 : 28,
        vertical: compacto ? 20 : 22,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compacto ? 50 : 62,
            height: compacto ? 50 : 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF24153D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, size: compacto ? 23 : 27, color: _roxoClaro),
          ),
          SizedBox(width: compacto ? 15 : 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Color(0xFF8F8F9D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: controller,
                  readOnly: !habilitado,
                  keyboardType: teclado,
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compacto ? 15 : 17,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Color(0xFF777784)),
                    isDense: true,
                    contentPadding: habilitado
                        ? const EdgeInsets.all(10)
                        : EdgeInsets.zero,
                    filled: habilitado,
                    fillColor: const Color(0xFF101015),
                    border: habilitado
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF3A3A45),
                            ),
                          )
                        : InputBorder.none,
                    enabledBorder: habilitado
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF3A3A45),
                            ),
                          )
                        : InputBorder.none,
                    focusedBorder: habilitado
                        ? OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _roxoClaro),
                          )
                        : InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
