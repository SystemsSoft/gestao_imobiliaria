import 'dart:async';

import '../api/api_client.dart';
import '../api/status_conexao.dart';
import 'memory_collection.dart';

/// Cache local de uma coleção do servidor. Carrega tudo na primeira leitura
/// e mantém as telas atualizadas (watch) a cada gravação feita pelo app.
///
/// Com [intervalo], enquanto alguma tela observa, recarrega periodicamente
/// para mostrar o que outros usuários fizeram (ex.: chat, fila).
class RemoteCollection<T> {
  RemoteCollection({
    required String Function(T) idOf,
    required Future<List<T>> Function() carregar,
    required StatusConexao status,
    this.intervalo,
  }) : _carregar = carregar,
       _status = status,
       cache = MemoryCollection<T>(idOf) {
    status.registrar(recarregar, invalidar: invalidar);
  }

  final Future<List<T>> Function() _carregar;
  final StatusConexao _status;
  final MemoryCollection<T> cache;
  final Duration? intervalo;
  Future<void>? _carga;
  int _ouvintes = 0;
  Timer? _timer;

  /// Garante que os dados já vieram do servidor (uma vez por sessão).
  Future<void> garantir() => _carga ??= _buscar();

  Future<void> recarregar() => _carga = _buscar();

  /// Esquece os dados; a próxima leitura busca de novo.
  void invalidar() {
    _carga = null;
    cache.substituir(const []);
  }

  Future<void> _buscar() async {
    try {
      cache.substituir(await _carregar());
    } on ApiException catch (e) {
      _carga = null; // permite tentar de novo
      switch (e.statusCode) {
        // Sem permissão para o módulo: a tela fica vazia, sem alarme.
        case 403:
          cache.substituir(const []);
        // Sessão encerrada: o app volta ao login.
        case 401:
          break;
        default:
          _status.falhou(e.mensagem);
      }
    }
  }

  /// Emite só depois da primeira carga, para não piscar "lista vazia".
  Stream<List<T>> watch() async* {
    _ouvintes++;
    final i = intervalo;
    if (i != null) _timer ??= Timer.periodic(i, (_) => recarregar());
    try {
      await garantir();
      yield* cache.watch();
    } finally {
      if (--_ouvintes == 0) {
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  Future<List<T>> all() async {
    await garantir();
    return cache.all;
  }

  Future<T?> byId(String id) async {
    await garantir();
    return cache.byId(id);
  }
}
