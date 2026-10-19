import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/pwa/instalacao_app.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/auditoria/presentation/pages/auditorias_page.dart';
import 'package:marceloimob_gestao/features/home/presentation/pages/home_page.dart';
import 'package:marceloimob_gestao/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:marceloimob_gestao/features/home/presentation/widgets/navegacao_inferior.dart';

/// Navegador simulado (Android ou não, instalado ou não).
class _InstalacaoFalsa implements InstalacaoApp {
  _InstalacaoFalsa({
    this.android = true,
    this.instalado = false,
    this.disponivel = false,
    this.enderecoOficial = true,
  });

  @override
  final bool android;
  @override
  final bool instalado;
  @override
  bool disponivel;
  @override
  final bool enderecoOficial;
  int pedidos = 0;

  @override
  bool get mostrarOpcao => android && !instalado;

  @override
  Future<ResultadoInstalacao> instalar() async {
    pedidos++;
    disponivel = false;
    return ResultadoInstalacao.instalado;
  }
}

void _celular(WidgetTester tester) {
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _abrirHome(WidgetTester tester, InstalacaoApp app) async {
  sl
    ..unregister<InstalacaoApp>()
    ..registerSingleton<InstalacaoApp>(app);
  await tester.pumpWidget(
    MaterialApp(theme: buildAppTheme(), home: const HomePage()),
  );
  await tester.pumpAndSettle();
}

Future<void> _abrirMenu(WidgetTester tester) async {
  await tester.tap(find.text('Mais'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text(ModuloMenu.values.last.label),
    200,
    scrollable: find.byType(Scrollable).last,
  );
}

void main() {
  setUp(configurarDependencias);

  testWidgets('celular: barra inferior troca de módulo e mostra o título', (
    tester,
  ) async {
    _celular(tester);
    await _abrirHome(tester, _InstalacaoFalsa(android: false));
    expect(find.byType(NavegacaoInferior), findsOneWidget);
    for (final r in ['Início', 'CRM', 'Locação', 'Auditorias', 'Mais']) {
      expect(find.text(r), findsWidgets);
    }
    await tester.tap(find.text('Auditorias').last);
    await tester.pumpAndSettle();
    expect(find.byType(AuditoriasPage), findsOneWidget);
    // O nome do módulo fica na barra do topo (sem a faixa de título).
    expect(find.text('Auditorias'), findsWidgets);
  });

  testWidgets('"Baixar app" não aparece fora do Android', (tester) async {
    _celular(tester);
    await _abrirHome(tester, _InstalacaoFalsa(android: false));
    await _abrirMenu(tester);
    expect(find.text('Baixar app'), findsNothing);
  });

  testWidgets('"Baixar app" não aparece no app já instalado', (tester) async {
    _celular(tester);
    await _abrirHome(tester, _InstalacaoFalsa(instalado: true));
    await _abrirMenu(tester);
    expect(find.text('Baixar app'), findsNothing);
  });

  testWidgets('Android: "Baixar app" é a última opção e instala', (
    tester,
  ) async {
    _celular(tester);
    final app = _InstalacaoFalsa(disponivel: true);
    await _abrirHome(tester, app);
    await _abrirMenu(tester);
    await tester.scrollUntilVisible(
      find.text('Baixar app'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    final ultimoModulo = tester.getTopLeft(
      find.text(ModuloMenu.values.last.label).last,
    );
    expect(
      tester.getTopLeft(find.text('Baixar app')).dy,
      greaterThan(ultimoModulo.dy),
    );

    await tester.tap(find.text('Baixar app'));
    await tester.pumpAndSettle();
    expect(app.pedidos, 1);
    expect(find.textContaining('App instalado!'), findsOneWidget);
  });

  testWidgets('Android sem convite do navegador: mostra como instalar', (
    tester,
  ) async {
    _celular(tester);
    await _abrirHome(tester, _InstalacaoFalsa(enderecoOficial: false));
    await _abrirMenu(tester);
    await tester.scrollUntilVisible(
      find.text('Baixar app'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Baixar app'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir endereço oficial'), findsOneWidget);
    expect(find.text(enderecoAppWeb), findsOneWidget);
  });

  testWidgets('computador: sem barra inferior', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _abrirHome(tester, _InstalacaoFalsa(android: false));
    expect(find.byType(NavegacaoInferior), findsNothing);
  });
}
