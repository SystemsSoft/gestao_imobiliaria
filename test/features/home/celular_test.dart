import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marceloimob_gestao/core/di/injector.dart';
import 'package:marceloimob_gestao/core/pwa/instalacao_app.dart';
import 'package:marceloimob_gestao/core/theme/app_theme.dart';
import 'package:marceloimob_gestao/features/auditoria/presentation/pages/auditorias_page.dart';
import 'package:marceloimob_gestao/features/home/presentation/pages/home_page.dart';
import 'package:marceloimob_gestao/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:marceloimob_gestao/features/home/presentation/widgets/navegacao_inferior.dart';

/// Navegador simulado (sistema, navegador, instalado ou não).
class _InstalacaoFalsa implements InstalacaoApp {
  _InstalacaoFalsa({
    bool android = true,
    Sistema? sistema,
    this.navegador = Navegador.chrome,
    this.instalado = false,
    this.disponivel = false,
    this.enderecoOficial = true,
    this.resultadoSemConvite = ResultadoInstalacao.indisponivel,
  }) : sistema = sistema ?? (android ? Sistema.android : Sistema.ios);

  @override
  final Sistema sistema;
  @override
  final Navegador navegador;
  @override
  final bool instalado;
  @override
  bool disponivel;
  @override
  final bool enderecoOficial;
  int pedidos = 0;
  int aberturasNoChrome = 0;

  /// O que o navegador responde quando não ofereceu a instalação.
  final ResultadoInstalacao resultadoSemConvite;

  @override
  Future<ResultadoInstalacao> instalar({
    Duration espera = Duration.zero,
  }) async {
    pedidos++;
    if (!disponivel) return resultadoSemConvite;
    disponivel = false;
    return ResultadoInstalacao.instalado;
  }

  @override
  void abrirNoChrome() => aberturasNoChrome++;
}

void _computador(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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

  Future<void> tocarBaixarApp(WidgetTester tester) async {
    await _abrirMenu(tester);
    await tester.scrollUntilVisible(
      find.text('Baixar app'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Baixar app'));
    await tester.pumpAndSettle();
  }

  testWidgets('Android: instala direto, sem passo a passo', (tester) async {
    _celular(tester);
    final app = _InstalacaoFalsa(disponivel: true, enderecoOficial: false);
    await _abrirHome(tester, app);
    await tocarBaixarApp(tester);
    expect(app.pedidos, 1);
    expect(find.textContaining('App instalado!'), findsOneWidget);
    expect(find.textContaining('Abrir endereço oficial'), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Android com o app já instalado: avisa, sem instruções', (
    tester,
  ) async {
    _celular(tester);
    final app = _InstalacaoFalsa(
      resultadoSemConvite: ResultadoInstalacao.jaInstalado,
    );
    await _abrirHome(tester, app);
    await tocarBaixarApp(tester);
    expect(find.textContaining('já está instalado'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Android fora do Chrome: reabre a página no Chrome', (
    tester,
  ) async {
    _celular(tester);
    final app = _InstalacaoFalsa(navegador: Navegador.firefox);
    await _abrirHome(tester, app);
    await tocarBaixarApp(tester);
    expect(app.aberturasNoChrome, 1);
    expect(find.textContaining('Abrindo no Google Chrome'), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('computador: sem barra inferior', (tester) async {
    _computador(tester);
    await _abrirHome(tester, _InstalacaoFalsa(android: false));
    expect(find.byType(NavegacaoInferior), findsNothing);
    expect(find.byTooltip('Baixar para desktop'), findsNothing); // iPhone/iPad
  });

  testWidgets('Mac com Chrome: botão "Baixar para desktop" instala', (
    tester,
  ) async {
    _computador(tester);
    final app = _InstalacaoFalsa(sistema: Sistema.mac, disponivel: true);
    await _abrirHome(tester, app);
    // Ícone no topo e última opção do menu.
    expect(find.byTooltip('Baixar para desktop'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Baixar para desktop'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Baixar app'), findsNothing);
    await tester.tap(find.byTooltip('Baixar para desktop'));
    await tester.pumpAndSettle();
    expect(app.pedidos, 1);
    expect(find.textContaining('janela própria'), findsOneWidget);
  });

  testWidgets('Mac com Safari: ensina "Adicionar ao Dock"', (tester) async {
    _computador(tester);
    await _abrirHome(
      tester,
      _InstalacaoFalsa(sistema: Sistema.mac, navegador: Navegador.safari),
    );
    await tester.tap(find.byTooltip('Baixar para desktop'));
    await tester.pumpAndSettle();
    expect(find.text('MB Gestão para macOS'), findsOneWidget);
    expect(find.textContaining('Adicionar ao Dock'), findsOneWidget);
  });

  testWidgets('Windows com Firefox: indica Chrome ou Edge', (tester) async {
    _computador(tester);
    await _abrirHome(
      tester,
      _InstalacaoFalsa(sistema: Sistema.windows, navegador: Navegador.firefox),
    );
    await tester.tap(find.byTooltip('Baixar para desktop'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Google Chrome ou no Microsoft Edge'),
      findsOneWidget,
    );
  });

  testWidgets('app já instalado no computador: sem o botão', (tester) async {
    _computador(tester);
    await _abrirHome(
      tester,
      _InstalacaoFalsa(sistema: Sistema.windows, instalado: true),
    );
    expect(find.byTooltip('Baixar para desktop'), findsNothing);
  });

  test('detecta sistema e navegador pelo user agent', () {
    const mac =
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)';
    expect(detectar('$mac Chrome/141.0.0.0 Safari/537.36'), (
      Sistema.mac,
      Navegador.chrome,
    ));
    expect(detectar('$mac Version/26.0 Safari/605.1.15'), (
      Sistema.mac,
      Navegador.safari,
    ));
    expect(detectar('$mac Version/26.0 Safari/605.1.15', pontosToque: 5), (
      Sistema.ios,
      Navegador.safari,
    )); // iPad
    expect(
      detectar(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36 Edg/141.0.0.0',
      ),
      (Sistema.windows, Navegador.edge),
    );
    expect(
      detectar(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:144.0) Gecko/20100101 Firefox/144.0',
      ),
      (Sistema.windows, Navegador.firefox),
    );
    expect(
      detectar(
        'Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36',
      ),
      (Sistema.android, Navegador.chrome),
    );
    expect(
      detectar(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1',
      ).$1,
      Sistema.ios,
    );
  });
}
