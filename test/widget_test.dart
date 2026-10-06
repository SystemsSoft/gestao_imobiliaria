import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marceloimob_gestao/screens/home_screen.dart';
import 'package:marceloimob_gestao/screens/login_screen.dart';
import 'package:marceloimob_gestao/theme/app_theme.dart';

void main() {
  testWidgets('Login valida campos vazios', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const LoginScreen()),
    );

    await tester.tap(find.text('ENTRAR'));
    await tester.pump();

    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);
  });

  testWidgets('Drawer lista as opções do menu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const HomeScreen()),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    for (final label in [
      'Cadastros e CRM',
      'Administração de Locação',
      'Administração de Vendas',
      'Financeiro',
      'Fiscal',
      'Contratos e Relatórios',
      'Equipe e Segurança',
      'Personalização',
    ]) {
      expect(find.text(label), findsWidgets);
    }
  });
}
