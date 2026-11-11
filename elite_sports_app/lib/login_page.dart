import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'sessao_usuario.dart';

import 'recuperar_senha_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String apiBase =
      'https://elite-sports-production.up.railway.app';

  final loginEmailController = TextEditingController();
  final loginSenhaController = TextEditingController();

  final cadastroNomeController = TextEditingController();
  final cadastroEmailController = TextEditingController();
  final cadastroCpfController = TextEditingController();
  final cadastroSenhaController = TextEditingController();
  final cadastroConfirmarSenhaController = TextEditingController();

  bool modoLogin = true;
  bool carregando = false;

  bool mostrarSenhaLogin = false;
  bool mostrarSenhaCadastro = false;
  bool mostrarConfirmarSenha = false;

  String mensagem = '';
  bool mensagemSucesso = false;

  Map<String, dynamic> lerResposta(http.Response resposta) {
    try {
      final dados = jsonDecode(resposta.body);

      if (dados is Map<String, dynamic>) {
        return dados;
      }

      return {};
    } catch (_) {
      return {};
    }
  }

  void mostrarMensagem(String texto, {bool sucesso = false}) {
    setState(() {
      mensagem = texto;
      mensagemSucesso = sucesso;
    });
  }

  Future<void> fazerLogin() async {
    final email = loginEmailController.text.trim().toLowerCase();

    final senha = loginSenhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      mostrarMensagem('Digite e-mail e senha.');
      return;
    }

    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final resposta = await http.post(
        Uri.parse('$apiBase/api/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'senha': senha}),
      );

      final dados = lerResposta(resposta);

      if (!mounted) return;

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        final usuario = dados['usuario'];

        if (usuario is! Map || usuario['id_usuario'] == null) {
          mostrarMensagem('O servidor não retornou um usuário válido.');
          return;
        }

        // Salva o usuário no dispositivo
        await SessaoUsuario.salvar(Map<String, dynamic>.from(usuario));

        if (!mounted) return;

        final nome = usuario['nome']?.toString() ?? 'Usuário';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bem-vindo, $nome!'),
            backgroundColor: Colors.green,
          ),
        );

        // Volta para a tela inicial informando que fez login
        Navigator.of(context).popUntil((rota) => rota.isFirst);
      } else {
        mostrarMensagem(
          dados['mensagem']?.toString() ?? 'E-mail ou senha incorretos.',
        );
      }
    } catch (erro) {
      debugPrint('Erro no login: $erro');

      if (!mounted) return;

      mostrarMensagem('Não foi possível conectar com o servidor.');
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  Future<void> cadastrarUsuario() async {
    final nome = cadastroNomeController.text.trim();

    final email = cadastroEmailController.text.trim().toLowerCase();

    final cpf = cadastroCpfController.text.replaceAll(RegExp(r'\D'), '');

    final senha = cadastroSenhaController.text;

    final confirmarSenha = cadastroConfirmarSenhaController.text;

    if (nome.isEmpty ||
        email.isEmpty ||
        cpf.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      mostrarMensagem('Preencha todos os campos.');
      return;
    }

    if (nome.length < 3) {
      mostrarMensagem('O nome precisa ter pelo menos 3 caracteres.');
      return;
    }

    if (!validarEmail(email)) {
      mostrarMensagem('Digite um e-mail válido.');
      return;
    }

    if (!validarCpf(cpf)) {
      mostrarMensagem('CPF inválido.');
      return;
    }

    if (senha.length < 6) {
      mostrarMensagem('A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    if (senha != confirmarSenha) {
      mostrarMensagem('As senhas não conferem.');
      return;
    }

    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final resposta = await http.post(
        Uri.parse('$apiBase/api/usuarios'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'nome': nome,
          'email': email,
          'cpf': cpf,
          'telefone': '',
          'senha': senha,
        }),
      );

      final dados = lerResposta(resposta);

      if (!mounted) return;

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        loginEmailController.text = email;
        loginSenhaController.clear();

        cadastroSenhaController.clear();
        cadastroConfirmarSenhaController.clear();

        setState(() {
          modoLogin = true;
          mensagem =
              'Cadastro realizado com sucesso! Agora entre na sua conta.';
          mensagemSucesso = true;
        });
      } else {
        mostrarMensagem(
          dados['mensagem']?.toString() ??
              'Não foi possível realizar o cadastro.',
        );
      }
    } catch (erro) {
      debugPrint('Erro no cadastro: $erro');

      if (!mounted) return;

      mostrarMensagem('Não foi possível conectar com o servidor.');
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  bool validarEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    return regex.hasMatch(email);
  }

  bool validarCpf(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'\D'), '');

    if (cpf.length != 11) {
      return false;
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(cpf)) {
      return false;
    }

    int soma = 0;

    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }

    int resto = (soma * 10) % 11;

    if (resto == 10) {
      resto = 0;
    }

    if (resto != int.parse(cpf[9])) {
      return false;
    }

    soma = 0;

    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }

    resto = (soma * 10) % 11;

    if (resto == 10) {
      resto = 0;
    }

    return resto == int.parse(cpf[10]);
  }

  InputDecoration campoDecoration({
    required String hint,
    required IconData icone,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle: const TextStyle(color: Color(0xFF8F8F9D), fontSize: 15),

      prefixIcon: Icon(icone, color: const Color(0xFF9292A5)),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: const Color(0xFF111116),

      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF30303A)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF30303A)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF7C2CFF), width: 1.5),
      ),
    );
  }

  Widget campo({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icone,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: campoDecoration(
            hint: hint,
            icone: icone,
            suffixIcon: suffixIcon,
          ),
        ),

        const SizedBox(height: 18),
      ],
    );
  }

  @override
  void dispose() {
    loginEmailController.dispose();
    loginSenhaController.dispose();

    cadastroNomeController.dispose();
    cadastroEmailController.dispose();
    cadastroCpfController.dispose();
    cadastroSenhaController.dispose();
    cadastroConfirmarSenhaController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const roxo = Color(0xFF7C2CFF);

    final largura = MediaQuery.sizeOf(context).width;
    final celular = largura < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),

      appBar: celular
          ? AppBar(
              backgroundColor: const Color(0xFF0B0B0F),
              title: Text(modoLogin ? 'Entrar' : 'Cadastrar'),
            )
          : null,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: celular ? 16 : 24,
              vertical: 30,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: celular ? 22 : 44,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111116),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF292932)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/logo.png',
                                  width: 42,
                                  height: 42,
                                ),
                                const SizedBox(width: 12),
                                const Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Elite ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      TextSpan(
                                        text: 'Sports',
                                        style: TextStyle(color: roxo),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 35),

                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24242B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  setState(() {
                                    modoLogin = true;
                                    mensagem = '';
                                  });
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: modoLogin
                                      ? roxo
                                      : Colors.transparent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Entrar'),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: FilledButton(
                                onPressed: () {
                                  setState(() {
                                    modoLogin = false;
                                    mensagem = '';
                                  });
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: !modoLogin
                                      ? roxo
                                      : Colors.transparent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cadastrar'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 35),

                      if (modoLogin) construirLogin() else construirCadastro(),

                      if (mensagem.isNotEmpty) ...[
                        const SizedBox(height: 15),
                        Center(
                          child: Text(
                            mensagem,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: mensagemSucesso
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget construirLogin() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Bem-vindo de volta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Center(
          child: Text(
            'Entre na sua conta Elite Sports',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFFAAAAB5)),
          ),
        ),

        const SizedBox(height: 30),

        campo(
          label: 'E-mail',
          controller: loginEmailController,
          hint: 'Digite seu e-mail',
          icone: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        campo(
          label: 'Senha',
          controller: loginSenhaController,
          hint: 'Digite sua senha',
          icone: Icons.lock_outline,
          obscureText: !mostrarSenhaLogin,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                mostrarSenhaLogin = !mostrarSenhaLogin;
              });
            },
            icon: Icon(
              mostrarSenhaLogin
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: carregando ? null : fazerLogin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C2CFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: carregando
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Entrar',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () async {
              final resultado = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => RecuperarSenhaPage(
                    emailInicial: loginEmailController.text.trim(),
                  ),
                ),
              );

              if (!mounted) return;

              if (resultado == 'sucesso') {
                loginSenhaController.clear();

                setState(() {
                  modoLogin = true;
                  mensagem =
                      'Senha redefinida com sucesso! Entre com sua nova senha.';
                  mensagemSucesso = true;
                });
              } else if (resultado == 'cadastro') {
                setState(() {
                  modoLogin = false;
                  mensagem = '';
                });
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFA855F7),
              side: const BorderSide(color: Color(0xFF7C2CFF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Esqueci minha senha',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),

        const SizedBox(height: 14),

        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Ainda não possui conta?'),
              TextButton(
                onPressed: () {
                  setState(() {
                    modoLogin = false;
                    mensagem = '';
                  });
                },
                child: const Text(
                  'Cadastrar',
                  style: TextStyle(
                    color: Color(0xFFA855F7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget construirCadastro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Criar conta',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Center(
          child: Text(
            'Faça seu cadastro e compre seus produtos',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFAAAAB5), fontSize: 15),
          ),
        ),

        const SizedBox(height: 30),

        campo(
          label: 'Nome',
          controller: cadastroNomeController,
          hint: 'Digite seu nome',
          icone: Icons.person_outline,
        ),

        campo(
          label: 'E-mail',
          controller: cadastroEmailController,
          hint: 'Digite seu e-mail',
          icone: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),

        campo(
          label: 'CPF',
          controller: cadastroCpfController,
          hint: 'Digite seu CPF',
          icone: Icons.badge_outlined,
          keyboardType: TextInputType.number,
        ),

        campo(
          label: 'Senha',
          controller: cadastroSenhaController,
          hint: 'Crie uma senha',
          icone: Icons.lock_outline,
          obscureText: !mostrarSenhaCadastro,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                mostrarSenhaCadastro = !mostrarSenhaCadastro;
              });
            },
            icon: Icon(
              mostrarSenhaCadastro
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),

        campo(
          label: 'Confirmar senha',
          controller: cadastroConfirmarSenhaController,
          hint: 'Repita a senha',
          icone: Icons.lock_outline,
          obscureText: !mostrarConfirmarSenha,
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                mostrarConfirmarSenha = !mostrarConfirmarSenha;
              });
            },
            icon: Icon(
              mostrarConfirmarSenha
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: carregando ? null : cadastrarUsuario,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C2CFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: carregando
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Cadastrar',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                modoLogin = true;
                mensagem = '';
              });
            },
            child: const Text(
              'Já tenho uma conta',
              style: TextStyle(
                color: Color(0xFFA855F7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
