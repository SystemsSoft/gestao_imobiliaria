import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/domain_exception.dart';

/// Falha de comunicação com o servidor, com mensagem pronta para o usuário.
class ApiException extends DomainException {
  const ApiException(super.mensagem, {this.statusCode});

  final int? statusCode;
}

/// Cliente JSON da API (`/api/v1`). Erros viram [ApiException] com a
/// mensagem enviada pelo servidor (`detail`).
class ApiClient {
  ApiClient(String urlBase, {http.Client? cliente})
    : _base = Uri.parse(urlBase.endsWith('/') ? urlBase : '$urlBase/'),
      _http = cliente ?? http.Client();

  final Uri _base;
  final http.Client _http;

  static const _timeout = Duration(seconds: 20);
  static const _cabecalhos = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  Uri _uri(String caminho, [Map<String, Object?>? query]) {
    final q = {
      for (final e in (query ?? const {}).entries)
        if (e.value != null) e.key: '${e.value}',
    };
    final uri = _base.resolve('api/v1/$caminho');
    return q.isEmpty ? uri : uri.replace(queryParameters: q);
  }

  Future<dynamic> get(String caminho, {Map<String, Object?>? query}) =>
      _enviar(() => _http.get(_uri(caminho, query), headers: _cabecalhos));

  Future<dynamic> post(String caminho, Object? corpo) => _enviar(
    () => _http.post(
      _uri(caminho),
      headers: _cabecalhos,
      body: jsonEncode(corpo),
    ),
  );

  Future<dynamic> put(String caminho, Object? corpo) => _enviar(
    () =>
        _http.put(_uri(caminho), headers: _cabecalhos, body: jsonEncode(corpo)),
  );

  Future<void> delete(String caminho) =>
      _enviar(() => _http.delete(_uri(caminho), headers: _cabecalhos));

  /// Busca todas as páginas de uma listagem paginada.
  Future<List<Map<String, dynamic>>> listarTudo(
    String caminho, {
    Map<String, Object?>? query,
  }) async {
    const limite = 500;
    final itens = <Map<String, dynamic>>[];
    var total = 0;
    do {
      final pagina =
          await get(
                caminho,
                query: {
                  ...?query,
                  'limite': limite,
                  'deslocamento': itens.length,
                },
              )
              as Map<String, dynamic>;
      final lote = (pagina['itens'] as List).cast<Map<String, dynamic>>();
      total = pagina['total'] as int;
      itens.addAll(lote);
      if (lote.isEmpty) break;
    } while (itens.length < total);
    return itens;
  }

  Future<dynamic> _enviar(Future<http.Response> Function() requisicao) async {
    final http.Response r;
    try {
      r = await requisicao().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou a responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }
    final texto = utf8.decode(r.bodyBytes);
    final corpo = texto.isEmpty ? null : _decodificar(texto);
    if (r.statusCode >= 200 && r.statusCode < 300) return corpo;
    final detalhe = corpo is Map ? corpo['detail'] : null;
    throw ApiException(
      detalhe is String
          ? detalhe
          : 'Erro no servidor (${r.statusCode}). Tente novamente.',
      statusCode: r.statusCode,
    );
  }

  static dynamic _decodificar(String texto) {
    try {
      return jsonDecode(texto);
    } on FormatException {
      return null;
    }
  }
}
