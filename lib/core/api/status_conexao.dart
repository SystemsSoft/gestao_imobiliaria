import 'package:flutter/foundation.dart';

/// Último erro ao carregar dados do servidor (null = tudo certo) e as
/// coleções que podem ser recarregadas em "Tentar novamente".
class StatusConexao extends ChangeNotifier {
  String? erro;
  final _recarregadores = <Future<void> Function()>[];

  void registrar(Future<void> Function() recarregar) =>
      _recarregadores.add(recarregar);

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
