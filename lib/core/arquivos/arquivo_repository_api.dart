import 'dart:async';
import 'dart:typed_data';

import '../api/api_client.dart';
import 'arquivo_repository.dart';

/// Arquivos no servidor. Os links assinados são pedidos em lote (uma
/// requisição para todas as fotos da tela) e reaproveitados até expirar.
class ArquivoRepositoryApi implements ArquivoRepository {
  ArquivoRepositoryApi(this._api);

  final ApiClient _api;
  final _links = <String, Uri>{};
  final _pendentes = <String, Completer<Uri?>>{};
  Timer? _lote;

  @override
  Future<ArquivoEnviado> enviar({
    required Uint8List bytes,
    required String nome,
    required CategoriaArquivo categoria,
  }) async {
    categoria.validar(nome, bytes.length);
    final r =
        await _api.enviarArquivo(
              'arquivos',
              bytes: bytes,
              nomeArquivo: nome,
              campos: {'categoria': categoria.name},
            )
            as Map<String, dynamic>;
    final id = r['id'] as String;
    _links[id] = _api.endereco(r['link'] as String);
    return ArquivoEnviado(
      id: id,
      nome: r['nome'] as String,
      tamanho: r['tamanho'] as int,
    );
  }

  @override
  Future<Uri?> endereco(String url) {
    if (!ehArquivoEnviado(url)) return Future.value(Uri.tryParse(url));
    final id = url.substring(prefixoArquivo.length);
    if (_links[id] case final link? when _valido(link)) {
      return Future.value(link);
    }
    final pendente = _pendentes.putIfAbsent(id, Completer.new);
    _lote ??= Timer(Duration.zero, _buscarLote);
    return pendente.future;
  }

  /// Folga de 5 minutos para o link não vencer com a tela aberta.
  static bool _valido(Uri link) {
    final expira = int.tryParse(link.queryParameters['expira'] ?? '');
    if (expira == null) return false;
    final limite = DateTime.fromMillisecondsSinceEpoch(expira * 1000);
    return DateTime.now().add(const Duration(minutes: 5)).isBefore(limite);
  }

  Future<void> _buscarLote() async {
    _lote = null;
    final lote = Map.of(_pendentes);
    _pendentes.clear();
    try {
      final r =
          await _api.post('arquivos/links', {'ids': lote.keys.toList()})
              as Map<String, dynamic>;
      for (final MapEntry(key: id, value: c) in lote.entries) {
        final caminho = r[id] as String?;
        final link = caminho == null ? null : _api.endereco(caminho);
        if (link != null) _links[id] = link;
        c.complete(link);
      }
    } catch (e, s) {
      for (final c in lote.values) {
        c.completeError(e, s);
      }
    }
  }
}
