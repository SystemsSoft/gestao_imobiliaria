import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marceloimob_gestao/core/api/api_client.dart';
import 'package:marceloimob_gestao/core/api/sessao_api.dart';

/// Servidor falso que imita a API: guarda o JSON recebido em PUT /{id},
/// devolve nas listagens e gera os campos do servidor (datas, códigos).
class ServidorFalso {
  /// Coleção ('crm/imoveis') → id → registro.
  final colecoes = <String, Map<String, Map<String, dynamic>>>{};
  final requisicoes = <String>[];

  /// Cabeçalho Authorization da última requisição.
  String? ultimoToken;

  /// Força uma resposta de erro (ex.: 401, 403) para caminhos que começam
  /// com a chave.
  final erros = <String, (int, String)>{};

  /// Recusa a gravação com esta mensagem (422) quando devolve não nulo.
  String? Function(String colecao, Map<String, dynamic> corpo)? recusar;

  static const _numeradores = {
    'crm/imoveis': ('codigo', 'IM'),
    'locacao/contratos': ('numero', 'LOC'),
    'vendas': ('numero', 'VEN'),
    'temporada/reservas': ('numero', 'RES'),
  };
  final _sequencias = <String, int>{};

  ApiClient cliente({SessaoApi? sessao}) => ApiClient(
    'http://servidor',
    cliente: MockClient(responder),
    sessao: sessao,
  );

  Map<String, Map<String, dynamic>> colecao(String nome) =>
      colecoes.putIfAbsent(nome, () => {});

  http.Response _json(Object? corpo, [int status = 200]) => http.Response(
    jsonEncode(corpo),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  /// Arquivos enviados (multipart): id → nome, categoria e tamanho.
  final arquivos = <String, Map<String, dynamic>>{};

  http.Response _arquivos(http.Request r, List<String> partes) {
    String link(String id) =>
        '/api/v1/arquivos/$id/conteudo?expira=4102444800&assinatura=x';
    if (partes.length == 2 && partes[1] == 'links') {
      final ids = ((jsonDecode(r.body) as Map)['ids'] as List).cast<String>();
      return _json({
        for (final id in ids)
          if (arquivos.containsKey(id)) id: link(id),
      });
    }
    final corpo = latin1.decode(r.bodyBytes);
    final nome = RegExp(r'filename="([^"]+)"').firstMatch(corpo)!.group(1)!;
    final categoria = RegExp(
      r'name="categoria"\r\n\r\n(\w+)',
    ).firstMatch(corpo)!.group(1)!;
    final id =
        '00000000-0000-4000-8000-${(arquivos.length + 1).toString().padLeft(12, '0')}';
    arquivos[id] = {'nome': nome, 'categoria': categoria};
    return _json({
      'id': id,
      'nome': nome,
      'tamanho': corpo.length,
      'link': link(id),
    }, 201);
  }

  Future<http.Response> responder(http.Request r) async {
    requisicoes.add('${r.method} ${r.url.path}');
    ultimoToken = r.headers['Authorization'];
    final partes = r.url.pathSegments.skip(2).toList(); // sem api/v1
    final caminho = partes.join('/');
    for (final e in erros.entries) {
      if (caminho.startsWith(e.key)) {
        return _json({'detail': e.value.$2}, e.value.$1);
      }
    }
    if (partes.isNotEmpty && partes[0] == 'auth') return _auth(r, partes[1]);
    if (partes.isNotEmpty && partes[0] == 'arquivos') {
      return _arquivos(r, partes);
    }
    if (partes.isNotEmpty && partes[0] == 'equipe') {
      final especial = _equipe(r, partes);
      if (especial != null) return especial;
    }

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

    if (partes.join('/') == 'contratos/modelos' && r.method == 'GET') {
      return _json(colecao('contratos/modelos').values.toList());
    }

    if (partes.join('/') == 'fiscal/declarante') {
      final d = colecao('fiscal');
      if (r.method == 'PUT') {
        d['declarante'] = jsonDecode(r.body) as Map<String, dynamic>;
      }
      return _json(d['declarante'] ?? {'nome': 'Marcelo Bonifácio'});
    }

    if (partes.isNotEmpty && partes[0] == 'financeiro') {
      final especial = _financeiro(r, partes);
      if (especial != null) return especial;
    }

    // Parcelas de uma venda: DELETE /vendas/{id}/parcelas
    if (partes.length == 3 &&
        partes[0] == 'vendas' &&
        partes[2] == 'parcelas') {
      colecao(
        'vendas/parcelas',
      ).removeWhere((_, v) => v['vendaId'] == partes[1]);
      return http.Response('', 204);
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
      case 'PUT' when id == null:
        // Gravação em lote (lista com id em cada item).
        final lote = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
        return _json([
          for (final item in lote)
            itens[item['id'] as String] = {
              ...item,
              'criadoEm': '2026-10-15T10:00:00',
              'atualizadoEm': '2026-10-15T10:00:00',
            },
        ]);
      case 'PUT':
        final corpo = jsonDecode(r.body) as Map<String, dynamic>;
        final erro = recusar?.call(nome, corpo);
        if (erro != null) return _json({'detail': erro}, 422);
        final novo = !itens.containsKey(id);
        final numerador = _numeradores[nome];
        if (nome == 'equipe/comissoes/regras') corpo['usuarioId'] = id;
        corpo.remove('senha'); // como o servidor: a senha nunca volta
        if (nome == 'financeiro/boletos' && corpo['nossoNumero'] == '') {
          final conta = 'nosso-${corpo['contaId']}';
          _sequencias[conta] = (_sequencias[conta] ?? 0) + 1;
          corpo['nossoNumero'] = _sequencias[conta]!.toString().padLeft(
            10,
            '0',
          );
        }
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
        if (nome == 'vendas') {
          colecao('vendas/parcelas').removeWhere((_, v) => v['vendaId'] == id);
        }
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

  /// Rotas do financeiro que não seguem o padrão coleção/{id}.
  http.Response? _financeiro(http.Request r, List<String> partes) {
    final recurso = partes.length > 1 ? partes[1] : '';
    if (recurso == 'contas-bancarias' && r.method == 'GET') {
      return _json(colecao('financeiro/contas-bancarias').values.toList());
    }
    if (recurso == 'indices') {
      final indices = colecao('financeiro/indices');
      if (r.method == 'GET') return _json(indices.values.toList());
      if (r.method == 'DELETE') {
        indices.remove('${partes[2]}-${partes[3]}-${partes[4]}');
        return http.Response('', 204);
      }
      final corpo = jsonDecode(r.body) as Map<String, dynamic>;
      return _json(
        indices['${corpo['indice']}-${corpo['ano']}-${corpo['mes']}'] = corpo,
      );
    }
    if (recurso == 'configuracao') {
      final cfg = colecao('financeiro/configuracao');
      if (r.method == 'PUT') {
        cfg['config'] = jsonDecode(r.body) as Map<String, dynamic>;
      }
      return _json(
        cfg['config'] ??
            {
              'multaPercentual': 2,
              'jurosMesPercentual': 1,
              'indicePadrao': 'nenhum',
            },
      );
    }
    return null;
  }

  /// Login: aceita a senha "senha-certa" para qualquer usuário.
  http.Response _auth(http.Request r, String acao) {
    switch (acao) {
      case 'entrar':
        final corpo = jsonDecode(r.body) as Map<String, dynamic>;
        if (corpo['senha'] != 'senha-certa') {
          return _json({'detail': 'Usuário ou senha incorretos.'}, 422);
        }
        return _json({
          'token': 'token-de-teste',
          'sessaoId': 'sessao-1',
          'usuario': {
            'id': 'u-admin',
            'nome': 'Admin',
            'login': corpo['usuario'],
          },
        });
      case 'sair':
      case 'alterar-senha':
        return http.Response('', 204);
    }
    return http.Response('', 404);
  }

  /// Rotas da equipe que devolvem lista simples ou substituem tudo.
  http.Response? _equipe(http.Request r, List<String> partes) {
    final nome = partes.join('/');
    const listas = {
      'equipe/usuarios',
      'equipe/sessoes',
      'equipe/atividades',
      'equipe/fila',
      'equipe/atendimentos',
      'equipe/comissoes/regras',
      'equipe/comissoes',
      'equipe/mensagens',
    };
    if (r.method == 'GET' && listas.contains(nome)) {
      return _json(colecao(nome).values.toList());
    }
    if (nome == 'equipe/fila' && r.method == 'PUT') {
      final fila = (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
      colecao(nome)
        ..clear()
        ..addAll({for (final i in fila) i['usuarioId'] as String: i});
      return _json(fila);
    }
    if (nome == 'equipe/configuracao') {
      final cfg = colecao(nome);
      if (r.method == 'PUT') {
        cfg['config'] = jsonDecode(r.body) as Map<String, dynamic>;
      }
      return _json(
        cfg['config'] ?? {'limiteSessoes': 5, 'inatividadeMinutos': 30},
      );
    }
    return null;
  }
}
