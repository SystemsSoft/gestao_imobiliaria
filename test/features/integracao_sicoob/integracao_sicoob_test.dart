import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gestao_imobiliaria/core/api/api_client.dart';
import 'package:gestao_imobiliaria/core/di/injector.dart';
import 'package:gestao_imobiliaria/core/theme/app_theme.dart';
import 'package:gestao_imobiliaria/features/integracao_sicoob/data/repositories/sicoob_repositories.dart';
import 'package:gestao_imobiliaria/features/integracao_sicoob/domain/entities/sicoob.dart';
import 'package:gestao_imobiliaria/features/integracao_sicoob/domain/repositories/sicoob_repository.dart';
import 'package:gestao_imobiliaria/features/integracao_sicoob/presentation/pages/integracao_sicoob_page.dart';
import 'package:gestao_imobiliaria/features/integracao_sicoob/presentation/viewmodels/integracao_sicoob_viewmodel.dart';

void main() {
  setUp(configurarDependencias);

  test('API: token só é enviado ao salvar; boleto e PDF', () async {
    final pedidos = <http.Request>[];
    final repo = SicoobApiRepository(
      ApiClient(
        'https://api.inovacloud.app',
        cliente: MockClient((r) async {
          pedidos.add(r);
          final p = r.url.path;
          Object corpo = switch (p) {
            '/api/v1/integracoes/sicoob/configuracao' => {
              'ambiente': 'sandbox',
              'clientId': 'cid',
              'numeroCliente': '25546454',
              'codigoModalidade': 1,
              'tokenConfigurado': true,
            },
            '/api/v1/integracoes/sicoob/boletos' => {
              'boleto': {
                'id': 'b1',
                'nossoNumero': '123456',
                'valor': 150.0,
                'vencimento': '2026-11-10',
                'pagadorNome': 'Ana',
                'situacao': 'Em Aberto',
                'criadoEm': '2026-10-19T10:00:00',
              },
              'pdf': base64Encode(utf8.encode('%PDF')),
            },
            _ => {},
          };
          return http.Response(
            jsonEncode(corpo),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    final c = await repo.salvarConfiguracao(
      const ConfiguracaoSicoob(clientId: 'cid', numeroCliente: '25546454'),
      token: 'tok',
    );
    expect(c.tokenConfigurado, true);
    expect(jsonDecode(pedidos.single.body)['token'], 'tok');

    final r = await repo.registrarBoleto(
      NovoBoletoSicoob(
        valor: 150,
        vencimento: DateTime(2026, 11, 10),
        pagador: const PagadorSicoob(documento: '52998224725', nome: 'Ana'),
        multaPercentual: 2,
      ),
    );
    expect(r.boleto.nossoNumero, '123456');
    expect(utf8.decode(r.pdf), '%PDF');
    final corpo = jsonDecode(pedidos.last.body) as Map<String, dynamic>;
    expect(corpo['vencimento'], '2026-11-10');
    expect(corpo['pagador']['documento'], '52998224725');
    expect(corpo['multaPercentual'], 2);
  });

  testWidgets('tela: configura, testa conexão e registra boleto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = sl<SicoobRepository>() as SicoobMemoryRepository;
    repo.abertas = [
      CobrancaAbertaSicoob(
        id: 'c1',
        descricao: 'LOC-0001 · 11/2099',
        locatario: 'Ana Inquilina',
        valor: 1500,
        vencimento: DateTime(2099, 11, 10),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: IntegracaoSicoobPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'client_id'),
      'cid-sandbox',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Token de acesso (Bearer)'),
      'tok',
    );
    await tester.tap(find.text('Salvar e testar conexão'));
    await tester.pumpAndSettle();
    expect(repo.config.clientId, 'cid-sandbox');
    expect(repo.config.tokenConfigurado, true);
    expect(find.text('Conectado e autorizado.'), findsNWidgets(3));

    // Boletos: preenche pela cobrança do aluguel e registra.
    await tester.tap(find.text('Boletos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo boleto de teste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dados livres'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Ana Inquilina').last);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Ana Inquilina'), findsOneWidget);
    await tester.tap(find.text('Registrar no Sicoob'));
    await tester.pumpAndSettle();
    final b = repo.boletosPorId.values.single;
    expect(
      (b.valor, b.cobrancaId, b.pagadorNome),
      (1500, 'c1', 'Ana Inquilina'),
    );
    expect(find.textContaining('Nosso número 100000'), findsOneWidget);

    // A chamada aparece no registro.
    await tester.tap(find.text('Chamadas'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar boleto'), findsOneWidget);
  });

  testWidgets('Pix: gera a cobrança e mostra o copia e cola', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = sl<SicoobRepository>() as SicoobMemoryRepository;
    await repo.salvarConfiguracao(
      const ConfiguracaoSicoob(clientId: 'cid', chavePix: 'imob@pix.com'),
      token: 'tok',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: IntegracaoSicoobPage(abaInicial: 2)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nova cobrança Pix'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Valor'),
      '15000',
    );
    await tester.tap(find.text('Gerar Pix'));
    await tester.pumpAndSettle();
    expect(find.textContaining('00020126580014br.gov.bcb.pix'), findsOneWidget);
    expect(repo.pixPorId.values.single.valor, 150);
  });

  test(
    'retorno: prévia não altera; aplicar dá baixa e manda o arquivo',
    () async {
      final repo = sl<SicoobRepository>() as SicoobMemoryRepository;
      final vm = sl<IntegracaoSicoobViewModel>();
      await repo.registrarBoleto(
        NovoBoletoSicoob(
          valor: 1500,
          vencimento: DateTime(2099, 11, 10),
          pagador: const PagadorSicoob(documento: '52998224725', nome: 'Ana'),
          cobrancaId: 'c1',
        ),
      );
      final arquivo = Uint8List.fromList(utf8.encode('756...'));
      final previa = await vm.processarRetorno(arquivo, aplicar: false);
      expect((previa!.baixas, previa.itens.single.situacao), (1, 'baixar'));
      expect(repo.boletosPorId.values.single.situacao, isNot('Liquidado'));

      final feito = await vm.processarRetorno(arquivo, aplicar: true);
      expect(feito!.aplicado, true);
      expect(repo.boletosPorId.values.single.situacao, 'Liquidado');
      expect(vm.boletos.single.situacao, 'Liquidado');
      vm.dispose();
    },
  );

  test('API: retorno vai em base64 com aplicar', () async {
    late http.Request pedido;
    final repo = SicoobApiRepository(
      ApiClient(
        'https://api.inovacloud.app',
        cliente: MockClient((r) async {
          pedido = r;
          return http.Response(
            jsonEncode({
              'arquivoLinhas': 6,
              'aplicado': false,
              'baixas': 1,
              'itens': [
                {
                  'linha': 3,
                  'nossoNumero': '123456',
                  'seuNumero': '',
                  'movimento': '06',
                  'valorPago': 1530.0,
                  'dataCredito': '2099-11-12',
                  'situacao': 'baixar',
                  'mensagem': 'Será marcada como paga.',
                  'locatario': 'Ana',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    final r = await repo.processarRetorno(
      Uint8List.fromList([1, 2, 3]),
      aplicar: false,
    );
    expect(pedido.url.path, '/api/v1/integracoes/sicoob/retorno');
    final corpo = jsonDecode(pedido.body) as Map<String, dynamic>;
    expect((corpo['conteudo'], corpo['aplicar']), ('AQID', false));
    expect((r.baixas, r.itens.single.valorPago), (1, 1530.0));
    expect(r.itens.single.dataCredito, DateTime(2099, 11, 12));
  });

  testWidgets('aba Boletos mostra o retorno e o botão Abrir Sicoob', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: IntegracaoSicoobPage(abaInicial: 1)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retorno de cobrança'), findsOneWidget);
    expect(find.text('Enviar arquivo de retorno'), findsOneWidget);
    // No cartão do retorno; no topo (1200px) fica só o ícone.
    expect(find.text('Abrir Sicoob'), findsOneWidget);
    expect(find.byTooltip('Abrir Sicoob'), findsOneWidget);
  });
}
