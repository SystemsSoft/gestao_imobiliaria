import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/domain_exception.dart';

/// Endereço devolvido pela consulta de CEP.
class EnderecoCep {
  const EnderecoCep({
    required this.cep,
    this.logradouro = '',
    this.complemento = '',
    this.bairro = '',
    this.cidade = '',
    this.uf = '',
  });

  final String cep;
  final String logradouro;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
}

/// Consulta de CEP na ViaCEP (https://viacep.com.br), gratuita e sem chave.
class BuscaCep {
  BuscaCep({http.Client? cliente}) : _http = cliente ?? http.Client();

  final http.Client _http;
  final _cache = <String, EnderecoCep?>{};

  static String digitos(String cep) => cep.replaceAll(RegExp(r'\D'), '');

  /// Devolve null quando o CEP não existe; lança [DomainException] quando
  /// não foi possível consultar (sem internet, serviço fora do ar).
  Future<EnderecoCep?> call(String cep) async {
    final d = digitos(cep);
    if (d.length != 8) {
      throw const DomainException('O CEP precisa ter 8 dígitos.');
    }
    if (_cache.containsKey(d)) return _cache[d];
    final http.Response r;
    try {
      r = await _http
          .get(Uri.parse('https://viacep.com.br/ws/$d/json/'))
          .timeout(const Duration(seconds: 8));
    } on Exception {
      throw const DomainException(
        'Não foi possível consultar o CEP agora. Preencha o endereço à mão.',
      );
    }
    if (r.statusCode == 400) return _cache[d] = null; // CEP mal formado
    if (r.statusCode != 200) {
      throw const DomainException(
        'Não foi possível consultar o CEP agora. Preencha o endereço à mão.',
      );
    }
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (j['erro'] != null) return _cache[d] = null;
    String t(String k) => (j[k] as String? ?? '').trim();
    return _cache[d] = EnderecoCep(
      cep: t('cep'),
      logradouro: t('logradouro'),
      complemento: t('complemento'),
      bairro: t('bairro'),
      cidade: t('localidade'),
      uf: t('uf'),
    );
  }
}
