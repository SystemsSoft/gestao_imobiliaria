import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/domain_exception.dart';
import '../marca/marca.dart';
import 'sessao_api.dart';

/// Falha de comunicação com o servidor, com mensagem pronta para o usuário.
class ApiException extends DomainException {
  const ApiException(super.mensagem, {this.statusCode});

  final int? statusCode;
}

/// Cliente JSON da API (`/api/v1`). Erros viram [ApiException] com a
/// mensagem enviada pelo servidor (`detail`).
class ApiClient {
  ApiClient(String urlBase, {http.Client? cliente, this.sessao})
    : _base = Uri.parse(urlBase.endsWith('/') ? urlBase : '$urlBase/'),
      _http = cliente ?? http.Client();

  final Uri _base;
  final http.Client _http;

  /// Login atual; sem ele as requisições vão sem token.
  final SessaoApi? sessao;

  static const _timeout = Duration(seconds: 20);
  static const _timeoutEnvio = Duration(minutes: 15);

  Map<String, String> get _cabecalhos => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    ..._identificacao,
  };

  /// Token do login e imobiliária em uso (cada uma tem o seu banco).
  Map<String, String> get _identificacao => {
    if (sessao?.token case final t?) 'Authorization': 'Bearer $t',
    'X-Imobiliaria': ?MarcaAtual.imobiliaria,
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

  /// Envia um arquivo (multipart) com campos de formulário.
  Future<dynamic> enviarArquivo(
    String caminho, {
    required List<int> bytes,
    required String nomeArquivo,
    Map<String, String> campos = const {},
  }) => _enviar(() async {
    final req = http.MultipartRequest('POST', _uri(caminho))
      ..headers.addAll({'Accept': 'application/json', ..._identificacao})
      ..fields.addAll(campos)
      ..files.add(
        http.MultipartFile.fromBytes('arquivo', bytes, filename: nomeArquivo),
      );
    return http.Response.fromStream(await _http.send(req));
  }, timeout: _timeoutEnvio);

  /// Endereço completo de um caminho devolvido pelo servidor (`/api/v1/...`).
  Uri endereco(String caminho) =>
      _base.resolve(caminho.startsWith('/') ? caminho.substring(1) : caminho);

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

  Future<dynamic> _enviar(
    Future<http.Response> Function() requisicao, {
    Duration timeout = _timeout,
  }) async {
    final http.Response r;
    try {
      r = await requisicao().timeout(timeout);
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
    if (r.statusCode == 401) {
      sessao?.expirou(
        detalhe is String ? detalhe : 'Sua sessão expirou. Entre novamente.',
      );
    }
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
