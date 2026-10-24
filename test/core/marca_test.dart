import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/core/api/api_client.dart';
import 'package:gestao_imobiliaria/core/config/empresa_info.dart';
import 'package:gestao_imobiliaria/core/marca/armazenamento_local.dart';
import 'package:gestao_imobiliaria/core/marca/descobrir_marca.dart';
import 'package:gestao_imobiliaria/core/marca/marca.dart';
import 'package:gestao_imobiliaria/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Servidor falso de `/api/v1/marca`: reconhece o domínio quando
/// [porDominio] e o código `joao` pelo cabeçalho.
MockClient _servidor({bool porDominio = false, List<http.Request>? pedidos}) =>
    MockClient((r) async {
      pedidos?.add(r);
      final codigo = r.headers['X-Imobiliaria'];
      if (codigo == null && !porDominio) {
        return http.Response('{"detail": "Imobiliária não identificada"}', 400);
      }
      if (codigo != null && codigo != 'joao') {
        return http.Response('{"detail": "Imobiliária não encontrada."}', 404);
      }
      return http.Response(
        jsonEncode({
          'imobiliaria': 'joao',
          'origem': codigo == null ? 'dominio' : 'cabecalho',
          'nome': 'João Imóveis',
          'corPrimaria': '#0f5132',
          'corDestaque': '#f5c432',
          'temLogo': true,
          'logo': '/logo?imob=joao',
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

void main() {
  tearDown(() => MarcaAtual.aplicar(null));

  test('marca do servidor: a cor padrão do sistema vira null', () {
    final m = Marca.fromJson({
      'imobiliaria': 'x',
      'nome': 'X',
      'origem': 'dominio',
      'corPrimaria': '#061A48',
      'corDestaque': '#ff6600',
      'temLogo': false,
      'logo': '/logo',
    });
    expect(m.corPrimaria, isNull);
    expect(m.corDestaque, const Color(0xFFFF6600));
    expect(m.logo, isNull);
    expect(m.peloDominio, isTrue);
  });

  test('pelo domínio, sem código', () async {
    final d = DescobrirMarca(
      'https://joao.com.br',
      cliente: _servidor(porDominio: true),
    );
    final m = await d.descobrir();
    expect(
      (m!.imobiliaria, m.nome, m.peloDominio),
      ('joao', 'João Imóveis', true),
    );
  });

  test('fora do domínio: pede o código, guarda e reconhece depois', () async {
    final local = ArmazenamentoLocal();
    final d = DescobrirMarca(
      'https://api.x',
      cliente: _servidor(),
      armazenamento: local,
    );
    expect(await d.descobrir(), isNull);
    await expectLater(
      d.porCodigo('maria'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.mensagem,
          'mensagem',
          contains('não encontrada'),
        ),
      ),
    );
    final m = await d.porCodigo('  JOAO ');
    expect(m.origem, 'cabecalho');
    expect((await d.descobrir())!.imobiliaria, 'joao');
    d.esquecer();
    expect(await d.descobrir(), isNull);
  });

  test('sem conexão avisa (o app oferece tentar de novo)', () async {
    final d = DescobrirMarca(
      'https://api.x',
      cliente: MockClient((_) => throw http.ClientException('offline')),
    );
    expect(d.descobrir(), throwsA(isA<ApiException>()));
  });

  test('aplicar a marca muda paleta e nome; sem ela, nenhuma marca', () async {
    final padrao = AppColors.gold;
    final d = DescobrirMarca(
      'https://joao.com.br',
      cliente: _servidor(porDominio: true),
    );
    MarcaAtual.aplicar(await d.descobrir());
    expect(EmpresaInfo.nome, 'João Imóveis');
    expect(
      AppColors.gold,
      padrao,
      reason: 'destaque padrão segue o do sistema',
    );
    expect(AppColors.navyDark, isNot(const Color.fromARGB(255, 38, 49, 79)));
    MarcaAtual.aplicar(null);
    expect(EmpresaInfo.nome, isEmpty);
    expect(AppColors.navyDark, const Color.fromARGB(255, 38, 49, 79));
  });

  test('toda chamada à API leva a imobiliária em uso', () async {
    final pedidos = <http.Request>[];
    final api = ApiClient(
      'https://api.x',
      cliente: MockClient((r) async {
        pedidos.add(r);
        return http.Response('{}', 200);
      }),
    );
    await api.get('crm/contatos');
    expect(pedidos.last.headers.containsKey('X-Imobiliaria'), isFalse);
    MarcaAtual.aplicar(
      await DescobrirMarca(
        'https://joao.com.br',
        cliente: _servidor(porDominio: true),
      ).descobrir(),
    );
    await api.get('crm/contatos');
    expect(pedidos.last.headers['X-Imobiliaria'], 'joao');
  });
}
