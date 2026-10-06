import 'dart:async';

import 'package:flutter/foundation.dart';

import '../errors/domain_exception.dart';

/// Base dos ViewModels: guarda as assinaturas de streams e as cancela no
/// dispose, notificando a View a cada novo dado.
abstract class ViewModel extends ChangeNotifier {
  final _subs = <StreamSubscription<dynamic>>[];
  bool _disposed = false;

  bool get disposed => _disposed;

  /// Verdadeiro enquanto uma ação disparada por [executar] está em andamento.
  bool ocupado = false;

  /// Mensagem da última falha de regra de negócio.
  String? erro;

  /// Executa [acao] tratando [DomainException]; retorna true em caso de sucesso.
  Future<bool> executar(Future<void> Function() acao) async {
    ocupado = true;
    erro = null;
    notificar();
    try {
      await acao();
      return true;
    } on DomainException catch (e) {
      erro = e.mensagem;
      return false;
    } finally {
      ocupado = false;
      notificar();
    }
  }

  void observar<T>(Stream<T> stream, void Function(T dados) onData) {
    _subs.add(
      stream.listen((dados) {
        onData(dados);
        notificar();
      }),
    );
  }

  void notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
