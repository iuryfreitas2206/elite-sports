import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class RecuperarSenhaPage extends StatefulWidget {
  final String emailInicial;

  const RecuperarSenhaPage({super.key, this.emailInicial = ''});

  @override
  State<RecuperarSenhaPage> createState() => _RecuperarSenhaPageState();
}

class _RecuperarSenhaPageState extends State<RecuperarSenhaPage> {
  static const String apiBase =
      'https://elite-sports-production.up.railway.app';

  static const Color roxo = Color(0xFF822CFF);
  static const Color painel = Color(0xFF111116);
  static const Color fundo = Color(0xFF08080C);

  final emailController = TextEditingController();
  final codigoController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarController = TextEditingController();

  bool etapaCodigo = false;
  bool carregando = false;
  bool mostrarSenha = false;

  String emailSolicitado = '';
  String mensagem = '';
  bool mensagemSucesso = false;

  @override
  void initState() {
    super.initState();
    emailController.text = widget.emailInicial;
  }

  @override
  void dispose() {
    emailController.dispose();
    codigoController.dispose();
    senhaController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  String respostaMensagem(http.Response resposta) {
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));

      if (dados is Map && dados['mensagem'] is String) {
        return dados['mensagem'];
      }
    } catch (_) {}

    return 'Não foi possível concluir a solicitação.';
  }

  void aviso(String texto, {bool sucesso = false}) {
    if (!mounted) return;

    setState(() {
      mensagem = texto;
      mensagemSucesso = sucesso;
    });
  }

  // =========================================
  // ENVIAR CÓDIGO POR E-MAIL
  // =========================================

  Future<void> solicitarCodigo() async {
    if (carregando) return;

    final email = emailController.text.trim().toLowerCase();

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      aviso('Digite um e-mail válido.');
      return;
    }

    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final resposta = await http
          .post(
            Uri.parse('$apiBase/api/recuperacao/solicitar'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        setState(() {
          etapaCodigo = true;
          emailSolicitado = email;
          mensagem =
              'Se o e-mail estiver cadastrado, você receberá '
              'um código válido por 10 minutos.';
          mensagemSucesso = true;
        });
      } else {
        aviso(respostaMensagem(resposta));
      }
    } on TimeoutException {
      aviso(
        'A solicitação demorou demais. '
        'Confira seu e-mail antes de tentar novamente.',
      );
    } catch (_) {
      aviso('Não foi possível conectar com o servidor.');
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  // =========================================
  // VERIFICAR CÓDIGO E REDEFINIR SENHA
  // =========================================

  Future<void> atualizarSenha() async {
    if (carregando) return;

    final codigo = codigoController.text.trim();
    final senha = senhaController.text;
    final confirmar = confirmarController.text;

    if (!RegExp(r'^\d{6}$').hasMatch(codigo)) {
      aviso('Digite o código de 6 números.');
      return;
    }

    if (senha.length < 8 || utf8.encode(senha).length > 72) {
      aviso(
        'A senha precisa ter pelo menos 8 caracteres '
        'e no máximo 72 bytes.',
      );
      return;
    }

    if (senha != confirmar) {
      aviso('As senhas não conferem.');
      return;
    }

    setState(() {
      carregando = true;
      mensagem = '';
    });

    try {
      final resposta = await http
          .post(
            Uri.parse('$apiBase/api/recuperacao/confirmar'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'email': emailSolicitado,
              'codigo': codigo,
              'novaSenha': senha,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (!mounted) return;

      if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
        Navigator.pop(context, 'sucesso');
      } else {
        aviso(respostaMensagem(resposta));
      }
    } on TimeoutException {
      aviso(
        'A conexão demorou demais. '
        'Tente entrar com a nova senha antes de repetir.',
      );
    } catch (_) {
      aviso('Não foi possível conectar com o servidor.');
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  // =========================================
  // CAMPO COM O ESTILO DO SITE
  // =========================================

  Widget campo({
    required String titulo,
    required TextEditingController controller,
    required String dica,
    bool senha = false,
    bool codigo = false,
    TextInputType? teclado,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          obscureText: senha && !mostrarSenha,
          keyboardType: teclado,
          maxLength: codigo ? 6 : null,
          inputFormatters: codigo
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            hintText: dica,
            hintStyle: const TextStyle(color: Color(0xFF777781)),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 19,
              vertical: 20,
            ),
            filled: true,
            fillColor: painel,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF33333D)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: roxo, width: 1.5),
            ),
            suffixIcon: senha
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        mostrarSenha = !mostrarSenha;
                      });
                    },
                    icon: Icon(
                      mostrarSenha
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white70,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  // =========================================
  // BOTÕES DO SITE
  // =========================================

  Widget botao({
    required String texto,
    required VoidCallback? aoClicar,
    Color cor = fundo,
    Color textoCor = Colors.white,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: ElevatedButton(
        onPressed: aoClicar,
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: textoCor,
          disabledBackgroundColor: cor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // =========================================
  // LAYOUT IGUAL AO SITE
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 44,
                ),
                decoration: BoxDecoration(
                  color: painel,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF303039)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LOGO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sports, color: roxo, size: 36),
                        const SizedBox(width: 14),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                            ),
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 38),

                    // ABAS ENTRAR / CADASTRAR
                    Row(
                      children: [
                        Expanded(
                          child: botao(
                            texto: 'Entrar',
                            cor: roxo,
                            aoClicar: () {
                              Navigator.pop(context, 'login');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: botao(
                            texto: 'Cadastrar',
                            cor: const Color(0xFF25252D),
                            textoCor: Colors.white70,
                            aoClicar: () {
                              Navigator.pop(context, 'cadastro');
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 38),

                    const Text(
                      'Redefinir Senha',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (!etapaCodigo) ...[
                      campo(
                        titulo: 'E-mail cadastrado',
                        controller: emailController,
                        dica: 'Digite seu e-mail',
                        teclado: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 23),

                      botao(
                        texto: carregando ? 'Enviando...' : 'Confirmar',
                        aoClicar: carregando ? null : solicitarCodigo,
                      ),
                    ] else ...[
                      const Text(
                        'Digite o código recebido por e-mail.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 18),

                      campo(
                        titulo: 'Código de verificação',
                        controller: codigoController,
                        dica: 'Digite os 6 números',
                        codigo: true,
                        teclado: TextInputType.number,
                      ),

                      const SizedBox(height: 17),

                      campo(
                        titulo: 'Nova senha',
                        controller: senhaController,
                        dica: 'Nova senha',
                        senha: true,
                      ),

                      const SizedBox(height: 17),

                      campo(
                        titulo: 'Confirmar senha',
                        controller: confirmarController,
                        dica: 'Repita a senha',
                        senha: true,
                      ),

                      const SizedBox(height: 23),

                      botao(
                        texto: carregando
                            ? 'Atualizando...'
                            : 'Redefinir Senha',
                        aoClicar: carregando ? null : atualizarSenha,
                      ),
                    ],

                    // MENSAGENS
                    if (mensagem.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        mensagem,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mensagemSucesso
                              ? Colors.greenAccent
                              : const Color(0xFFFF555F),
                          fontSize: 15,
                        ),
                      ),
                    ],

                    if (etapaCodigo) ...[
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: carregando
                            ? null
                            : () {
                                setState(() {
                                  etapaCodigo = false;
                                  emailSolicitado = '';
                                  mensagem = '';
                                  codigoController.clear();
                                  senhaController.clear();
                                  confirmarController.clear();
                                });
                              },
                        child: const Text(
                          'Voltar e solicitar outro código',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    botao(
                      texto: 'Voltar para login',
                      aoClicar: () {
                        Navigator.pop(context, 'login');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
