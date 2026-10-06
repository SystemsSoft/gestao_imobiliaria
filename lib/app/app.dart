import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class MarceloImobApp extends StatelessWidget {
  const MarceloImobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marcelo Bonifácio - Gestão',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _Inicio(),
    );
  }
}

/// Mostra a splash (vídeo) e, ao terminar, faz a transição para o login.
class _Inicio extends StatefulWidget {
  const _Inicio();

  @override
  State<_Inicio> createState() => _InicioState();
}

class _InicioState extends State<_Inicio> {
  bool _splashConcluida = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: _splashConcluida
          ? const LoginPage(key: ValueKey('login'))
          : SplashPage(
              key: const ValueKey('splash'),
              onFinished: () => setState(() => _splashConcluida = true),
            ),
    );
  }
}
