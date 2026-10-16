import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marceloimob_gestao/core/cep/busca_cep.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/errors/domain_exception.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/crm/presentation/pages/contato_form_page.dart';

/// ViaCEP simulada: conhece só o CEP de Icaraí.
final _viaCep = MockClient((r) async {
  final cep = r.url.pathSegments[1];
  if (cep == '24230050') {
    return http.Response(
      jsonEncode({
        'cep': '24230-050',
        'logradouro': 'Rua Moreira César',
        'complemento': '',
        'bairro': 'Icaraí',
        'localidade': 'Niterói',
        'uf': 'RJ',
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
  if (cep == '00000000') throw http.ClientException('sem internet');
  return http.Response(jsonEncode({'erro': 'true'}), 200);
});

void main() {
  test('consulta: encontrado, inexistente e sem conexão', () async {
    final busca = BuscaCep(cliente: _viaCep);
    final e = (await busca('24230-050'))!;
    expect(
      (e.logradouro, e.bairro, e.cidade, e.uf),
      ('Rua Moreira César', 'Icaraí', 'Niterói', 'RJ'),
    );
    expect(await busca('99999-999'), isNull);
    await expectLater(busca('00000-000'), throwsA(isA<DomainException>()));
    await expectLater(busca('123'), throwsA(isA<DomainException>()));
  });

  testWidgets('cadastro de contato preenche o endereço pelo CEP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await configurarDependencias();
    sl
      ..unregister<BuscaCep>()
      ..registerSingleton(BuscaCep(cliente: _viaCep));

    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const ContatoFormPage()),
    );
    await tester.pumpAndSettle();
    final cep = find.widgetWithText(TextFormField, 'CEP');
    await tester.ensureVisible(cep);
    await tester.enterText(cep, '24230050');
    await tester.pumpAndSettle();

    expect(find.text('Rua Moreira César'), findsOneWidget);
    expect(find.text('Icaraí'), findsOneWidget);
    expect(find.text('Niterói'), findsOneWidget);
    expect(find.text('RJ'), findsWidgets);

    await tester.enterText(cep, '99999999');
    await tester.pumpAndSettle();
    expect(find.text('CEP não encontrado.'), findsOneWidget);
  });
}
