import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/marca/logo_marca.dart';
import '../../../../core/theme/app_theme.dart';

/// Abertura com o logotipo (ou o nome) da imobiliária identificada; chama
/// [onFinished] em seguida.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final _animacao = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  Timer? _fim;

  @override
  void initState() {
    super.initState();
    _fim = Timer(const Duration(milliseconds: 1600), widget.onFinished);
  }

  @override
  void dispose() {
    _fim?.cancel();
    _animacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FundoMarca(
        child: Center(
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _animacao, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: _animacao, curve: Curves.easeOutCubic),
              ),
              child: const Padding(
                padding: EdgeInsets.all(32),
                child: LogoMarca(altura: 180),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fundo das telas de entrada, nas cores da imobiliária (ou nas padrão).
class FundoMarca extends StatelessWidget {
  const FundoMarca({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.blue, AppColors.navyDark, AppColors.navyDark],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}
