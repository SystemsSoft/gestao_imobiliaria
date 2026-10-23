import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_imobiliaria/core/di/injector.dart';
import 'package:gestao_imobiliaria/core/theme/app_theme.dart';
import 'package:gestao_imobiliaria/features/auth/presentation/pages/login_page.dart';
import 'package:gestao_imobiliaria/features/crm/presentation/pages/cadastros_crm_page.dart';
import 'package:gestao_imobiliaria/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:gestao_imobiliaria/features/home/presentation/pages/home_page.dart';
import 'package:gestao_imobiliaria/features/home/presentation/viewmodels/home_viewmodel.dart';

/// Tela alta o bastante para o botão ENTRAR ficar visível mesmo depois que
/// a logo (carregada de forma assíncrona) aumenta a altura da página.
void _telaGrande(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(configurarDependencias);

  testWidgets('login valida campos vazios', (tester) async {
    _telaGrande(tester);
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const LoginPage()),
    );
    await tester.tap(find.text('ENTRAR'));
    await tester.pump();
    expect(find.text('Informe seu usuário'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);
  });

  testWidgets('login válido abre a tela principal', (tester) async {
    _telaGrande(tester);
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const LoginPage()),
    );
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, '123');
    await tester.tap(find.text('ENTRAR'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('tela larga abre no dashboard com o menu fixo', (tester) async {
    _telaGrande(tester);
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const HomePage()),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);
    for (final m in ModuloMenu.values) {
      if (HomeViewModel.foraDoMenu.contains(m)) continue;
      expect(find.text(m.label), findsWidgets);
    }
    expect(find.text('Financeiro'), findsWidgets);
    expect(find.text('Integração Sicoob'), findsNothing);
    expect(find.text('Abrir Sicoob'), findsNothing);
    await tester.tap(find.text('Ver imóveis'));
    await tester.pumpAndSettle();
    expect(find.byType(CadastrosCrmPage), findsOneWidget);
  });

  testWidgets('tela estreita lista os módulos no drawer', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const HomePage()),
    );
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    for (final m in ModuloMenu.values) {
      if (HomeViewModel.foraDoMenu.contains(m)) continue;
      expect(find.text(m.label), findsWidgets);
    }
    expect(find.text('Financeiro'), findsWidgets);
    expect(find.text('Integração Sicoob'), findsNothing);
    expect(find.text('Abrir Sicoob'), findsNothing);
  });
}
