import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import 'armazenamento_local.dart';
import 'marca.dart';

/// Descobre qual imobiliária usa o app: primeiro pelo domínio em que ele
/// abriu (o servidor reconhece o endereço) e, fora dele, pelo código que a
/// pessoa digitou e ficou guardado neste aparelho.
class DescobrirMarca {
  DescobrirMarca(
    String apiUrl, {
    http.Client? cliente,
    ArmazenamentoLocal? armazenamento,
  }) : _base = Uri.parse(apiUrl.endsWith('/') ? apiUrl : '$apiUrl/'),
       _http = cliente ?? http.Client(),
       _armazenamento = armazenamento ?? ArmazenamentoLocal();

  static const _chave = 'gestao.imobiliaria';
  static const _timeout = Duration(seconds: 15);

  final Uri _base;
  final http.Client _http;
  final ArmazenamentoLocal _armazenamento;

  /// A imobiliária do domínio ou a do código guardado; null se nenhuma
  /// (o app pede o código). Sem conexão, lança [ApiException].
  Future<Marca?> descobrir() async {
    final pelaUrl = await _buscar(null);
    if (pelaUrl != null && pelaUrl.peloDominio) return pelaUrl;
    final guardado = _armazenamento.ler(_chave);
    if (guardado == null) return null;
    final marca = await _buscar(guardado);
    if (marca == null) _armazenamento.remover(_chave);
    return marca;
  }

  /// Confere o código digitado e o guarda neste aparelho.
  Future<Marca> porCodigo(String codigo) async {
    final limpo = codigo.trim().toLowerCase();
    if (limpo.isEmpty) {
      throw const ApiException('Informe o código da imobiliária.');
    }
    final marca = await _buscar(limpo);
    if (marca == null) {
      throw const ApiException(
        'Imobiliária não encontrada. Confira o código com a sua imobiliária.',
      );
    }
    _armazenamento.gravar(_chave, marca.imobiliaria);
    return marca;
  }

  /// Esquece o código guardado (trocar de imobiliária).
  void esquecer() => _armazenamento.remover(_chave);

  Future<Marca?> _buscar(String? codigo) async {
    final http.Response r;
    try {
      r = await _http
          .get(
            _base.resolve('api/v1/marca'),
            headers: {'Accept': 'application/json', 'X-Imobiliaria': ?codigo},
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou a responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }
    if (r.statusCode == 400 || r.statusCode == 404) return null;
    if (r.statusCode != 200) {
      throw ApiException(
        'Erro no servidor (${r.statusCode}). Tente novamente.',
        statusCode: r.statusCode,
      );
    }
    return Marca.fromJson(
      jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
