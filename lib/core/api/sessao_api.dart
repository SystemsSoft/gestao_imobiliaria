import 'package:flutter/foundation.dart';

/// Login atual no servidor: o token vai em todas as requisições.
class SessaoApi extends ChangeNotifier {
  String? token;
  String? usuarioId;
  String? sessaoId;

  /// Chamado quando o servidor recusa o token (sessão encerrada ou expirada).
  void Function(String mensagem)? aoExpirar;

  bool get logado => token != null;

  void iniciar({
    required String token,
    required String usuarioId,
    required String sessaoId,
  }) {
    this.token = token;
    this.usuarioId = usuarioId;
    this.sessaoId = sessaoId;
    notifyListeners();
  }

  void encerrar() {
    token = usuarioId = sessaoId = null;
    notifyListeners();
  }

  void expirou(String mensagem) {
    if (!logado) return;
    encerrar();
    aoExpirar?.call(mensagem);
  }
}
