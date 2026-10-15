import 'package:flutter/foundation.dart';

/// Último erro ao carregar dados do servidor (null = tudo certo) e as
/// coleções que podem ser recarregadas em "Tentar novamente".
class StatusConexao extends ChangeNotifier {
  String? erro;
  final _recarregadores = <Future<void> Function()>[];
  final _invalidadores = <void Function()>[];

  void registrar(
    Future<void> Function() recarregar, {
    void Function()? invalidar,
  }) {
    _recarregadores.add(recarregar);
    if (invalidar != null) _invalidadores.add(invalidar);
  }

  /// Descarta os dados em cache (ex.: ao entrar ou sair): cada tela busca
  /// de novo no servidor, já com as permissões de quem está logado.
  void invalidarTudo() {
    for (final i in _invalidadores) {
      i();
    }
    limpar();
  }

  void falhou(String mensagem) {
    erro = mensagem;
    notifyListeners();
  }

  void limpar() {
    if (erro == null) return;
    erro = null;
    notifyListeners();
  }

  Future<void> tentarNovamente() async {
    limpar();
    for (final r in _recarregadores) {
      await r();
    }
  }
}
