import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Guarda dados básicos da sessão local.
/// Não armazena senha nem CPF.
class SessaoUsuario {
  static const _chave = 'usuarioLogado';

  static final SharedPreferencesAsync _preferencias = SharedPreferencesAsync();

  // Ler o usuário que está logado
  static Future<Map<String, dynamic>?> ler() async {
    final texto = await _preferencias.getString(_chave);

    if (texto == null) return null;

    try {
      final dados = jsonDecode(texto);

      if (dados is! Map<String, dynamic>) return null;

      final id = dados['id_usuario']?.toString().trim();

      if (id == null || id.isEmpty) return null;

      return dados;
    } catch (_) {
      return null;
    }
  }

  // Salvar dados do usuário após login
  static Future<void> salvar(Map<String, dynamic> usuario) async {
    final id = usuario['id_usuario']?.toString().trim();

    if (id == null || id.isEmpty) {
      throw const FormatException('A API não retornou o ID do usuário.');
    }

    final dados = <String, dynamic>{
      'id_usuario': usuario['id_usuario'],
      'nome': usuario['nome']?.toString() ?? '',
      'email': usuario['email']?.toString() ?? '',
      'telefone': usuario['telefone']?.toString() ?? '',
    };

    await _preferencias.setString(_chave, jsonEncode(dados));
  }

  // Encerrar sessão
  static Future<void> sair() {
    return _preferencias.remove(_chave);
  }
}
