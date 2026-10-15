import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marceloimob_gestao/core/api/api_client.dart';

/// Servidor falso que imita a API: guarda o JSON recebido em PUT /{id},
/// devolve nas listagens e gera os campos do servidor (datas, códigos).
class ServidorFalso {
  /// Coleção ('crm/imoveis') → id → registro.
  final colecoes = <String, Map<String, Map<String, dynamic>>>{};
  final requisicoes = <String>[];

  /// Recusa a gravação com esta mensagem (422) quando devolve não nulo.
  String? Function(String colecao, Map<String, dynamic> corpo)? recusar;

  static const _numeradores = {
    'crm/imoveis': ('codigo', 'IM'),
    'locacao/contratos': ('numero', 'LOC'),
  };
  final _sequencias = <String, int>{};

  ApiClient cliente() =>
      ApiClient('http://servidor', cliente: MockClient(responder));

  Map<String, Map<String, dynamic>> colecao(String nome) =>
      colecoes.putIfAbsent(nome, () => {});

  http.Response _json(Object? corpo, [int status = 200]) => http.Response(
    jsonEncode(corpo),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<http.Response> responder(http.Request r) async {
    requisicoes.add('${r.method} ${r.url.path}');
    final partes = r.url.pathSegments.skip(2).toList(); // sem api/v1

    // Repasses: /locacao/repasses/{cobrancaId}/{contatoId}
    if (partes.length >= 2 && partes[1] == 'repasses') {
      final repasses = colecao('locacao/repasses');
      if (partes.length == 2) return _json(repasses.values.toList());
      final chave = '${partes[2]}|${partes[3]}';
      if (r.method == 'DELETE') {
        repasses.remove(chave);
        return http.Response('', 204);
      }
      final corpo = jsonDecode(r.body) as Map<String, dynamic>;
      return _json(
        repasses[chave] = {
          'cobrancaId': partes[2],
          'contatoId': partes[3],
          'data': corpo['data'],
        },
      );
    }

    final temId = partes.last.length == 36 && partes.last.contains('-');
    final nome = (temId ? partes.sublist(0, partes.length - 1) : partes).join(
      '/',
    );
    final itens = colecao(nome);
    final id = temId ? partes.last : null;
    switch (r.method) {
      case 'GET':
        return _json({
          'itens': itens.values.toList(),
          'total': itens.length,
          'limite': 500,
          'deslocamento': 0,
        });
      case 'PUT':
        final corpo = jsonDecode(r.body) as Map<String, dynamic>;
        final erro = recusar?.call(nome, corpo);
        if (erro != null) return _json({'detail': erro}, 422);
        final novo = !itens.containsKey(id);
        final numerador = _numeradores[nome];
        itens[id!] = {
          ...corpo,
          'id': id,
          'criadoEm': '2026-10-15T10:00:00',
          'atualizadoEm': '2026-10-15T10:00:00',
          if (numerador != null)
            numerador.$1: novo
                ? '${numerador.$2}-${(_sequencias[nome] = (_sequencias[nome] ?? 0) + 1).toString().padLeft(4, '0')}'
                : itens[id]![numerador.$1],
        };
        return _json(itens[id], novo ? 201 : 200);
      case 'DELETE':
        itens.remove(id);
        if (nome == 'locacao/contratos') {
          // Como o servidor: o contrato leva despesas e cobranças junto.
          for (final c in ['locacao/despesas', 'locacao/cobrancas']) {
            colecao(c).removeWhere((_, v) => v['contratoId'] == id);
          }
        }
        return http.Response('', 204);
    }
    return http.Response('', 405);
  }
}
