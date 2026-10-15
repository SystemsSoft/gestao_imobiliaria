import 'dart:async';

import '../api/api_client.dart';
import '../api/status_conexao.dart';
import 'memory_collection.dart';

/// Cache local de uma coleção do servidor. Carrega tudo na primeira leitura
/// e mantém as telas atualizadas (watch) a cada gravação feita pelo app.
class RemoteCollection<T> {
  RemoteCollection({
    required String Function(T) idOf,
    required Future<List<T>> Function() carregar,
    required StatusConexao status,
  }) : _carregar = carregar,
       _status = status,
       cache = MemoryCollection<T>(idOf) {
    status.registrar(recarregar);
  }

  final Future<List<T>> Function() _carregar;
  final StatusConexao _status;
  final MemoryCollection<T> cache;
  Future<void>? _carga;

  /// Garante que os dados já vieram do servidor (uma vez por sessão).
  Future<void> garantir() => _carga ??= _buscar();

  Future<void> recarregar() => _carga = _buscar();

  Future<void> _buscar() async {
    try {
      cache.substituir(await _carregar());
    } on ApiException catch (e) {
      _carga = null; // permite tentar de novo
      _status.falhou(e.mensagem);
    }
  }

  /// Emite só depois da primeira carga, para não piscar "lista vazia".
  Stream<List<T>> watch() async* {
    await garantir();
    yield* cache.watch();
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
