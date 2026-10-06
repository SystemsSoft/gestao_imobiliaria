import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
