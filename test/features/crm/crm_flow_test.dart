import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/crm/domain/entities/enums.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/contato_repository.dart';
import 'package:marceloimob_gestao/features/crm/domain/repositories/imovel_repository.dart';
import 'package:marceloimob_gestao/features/crm/domain/usecases/sugerir_negocios.dart';
import 'package:marceloimob_gestao/features/crm/presentation/pages/cadastros_crm_page.dart';
import 'package:marceloimob_gestao/features/crm/presentation/pages/contato_form_page.dart';
import 'package:marceloimob_gestao/features/crm/presentation/pages/imovel_form_page.dart';

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1000, 9000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: buildAppTheme(), home: const SizedBox.shrink()),
  );
  // Empilha a página sobre uma rota base, como no app.
  tester
      .state<NavigatorState>(find.byType(Navigator))
      .push(MaterialPageRoute<void>(builder: (_) => page));
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  setUp(configurarDependencias);

  testWidgets('cadastra imóvel com característica personalizada e anexo', (
    tester,
  ) async {
    await _pump(tester, const ImovelFormPage());

    await tester.enterText(_field('Título do anúncio *'), 'Apto 2 qtos Icaraí');
    await tester.enterText(_field('Valor de venda'), '45000000');
    await tester.enterText(_field('Quartos'), '2');
    await tester.enterText(_field('Característica'), 'Pé-direito');
    await tester.enterText(_field('Valor (opcional)'), '4 m');
    await tester.tap(find.text('Adicionar característica'));
    await tester.enterText(
      _field('Link (URL)'),
      'https://exemplo.com/foto.jpg',
    );
    expect(find.text('Enviar do computador'), findsOneWidget);
    await tester.tap(find.text('Adicionar link'));
    await tester.pump();
    await tester.tap(find.text('SALVAR IMÓVEL'));
    await tester.pumpAndSettle();

    final i = (await sl<ImovelRepository>().listar()).single;
    expect(i.codigo, 'IM-0001');
    expect(i.valorVenda, 450000);
    expect(i.quartos, 2);
    expect(i.personalizadas.single.nome, 'Pé-direito');
    expect(i.anexos.single.tipo, AnexoTipo.foto);
  });

  testWidgets('não salva imóvel sem título', (tester) async {
    await _pump(tester, const ImovelFormPage());
    await tester.tap(find.text('SALVAR IMÓVEL'));
    await tester.pump();
    expect(find.text('Informe o título'), findsOneWidget);
    expect(await sl<ImovelRepository>().listar(), isEmpty);
  });

  testWidgets('contato com perfil é cruzado com o imóvel', (tester) async {
    await _pump(tester, const ContatoFormPage());
    await tester.enterText(_field('Nome completo *'), 'Ana Souza');
    await tester.enterText(_field('CPF'), '12345678901');
    await tester.tap(find.byType(Switch).last);
    await tester.pump();
    await tester.enterText(_field('Quartos (mín.)'), '2');
    await tester.tap(find.text('SALVAR CONTATO'));
    await tester.pumpAndSettle();

    final c = (await sl<ContatoRepository>().listar()).single;
    expect(c.documento, '123.456.789-01');
    expect(c.perfil!.quartosMin, 2);

    await _pump(tester, const ImovelFormPage());
    await tester.enterText(_field('Título do anúncio *'), 'Casa');
    await tester.enterText(_field('Quartos'), '3');
    await tester.tap(find.text('SALVAR IMÓVEL'));
    await tester.pumpAndSettle();

    final sugestoes = const SugerirNegocios().paraContato(
      c,
      await sl<ImovelRepository>().listar(),
    );
    expect(sugestoes.single.score, 100);
  });

  testWidgets('módulo exibe as quatro abas', (tester) async {
    await _pump(tester, const Scaffold(body: CadastrosCrmPage()));
    for (final t in [
      'Imóveis',
      'Contatos (CRM)',
      'Cruzamento de perfil',
      'Central de Relacionamento',
    ]) {
      expect(find.text(t), findsOneWidget);
    }
  });
}
