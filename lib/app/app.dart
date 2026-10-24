import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/di/injector.dart';
import '../core/errors/domain_exception.dart';
import '../core/marca/descobrir_marca.dart';
import '../core/marca/marca.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/pages/escolher_imobiliaria_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

/// Permite voltar ao login de qualquer tela (ex.: sessão expirada).
final navegadorGlobal = GlobalKey<NavigatorState>();

class GestaoImobiliariaApp extends StatelessWidget {
  const GestaoImobiliariaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Redesenha com a paleta e o nome da imobiliária quando ela é
    // identificada (ou trocada).
    return ValueListenableBuilder<Marca?>(
      valueListenable: MarcaAtual.mudancas,
      builder: (context, marca, _) => MaterialApp(
        title: marca?.nome ?? 'Gestão Imobiliária',
        navigatorKey: navegadorGlobal,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const InicioApp(),
      ),
    );
  }
}

enum _Fase { descobrindo, semConexao, escolher, abertura, login }

/// Entrada do app: descobre a imobiliária (pelo domínio ou pelo código
/// guardado), sem logotipo nem nome até lá; depois, a abertura com a marca
/// dela e o login. Sem imobiliária identificada, pede o código.
class InicioApp extends StatefulWidget {
  const InicioApp({super.key});

  @override
  State<InicioApp> createState() => _InicioAppState();
}

class _InicioAppState extends State<InicioApp> {
  _Fase _fase = _Fase.descobrindo;
  String _erro = '';

  @override
  void initState() {
    super.initState();
    if (MarcaAtual.atual != null || !sl.isRegistered<DescobrirMarca>()) {
      _fase = _Fase.login;
    } else {
      _descobrir();
    }
  }

  Future<void> _descobrir() async {
    setState(() => _fase = _Fase.descobrindo);
    try {
      final marca = await sl<DescobrirMarca>().descobrir();
      if (!mounted) return;
      if (marca == null) {
        setState(() => _fase = _Fase.escolher);
      } else {
        _usar(marca);
      }
    } on DomainException catch (e) {
      if (mounted) {
        setState(() {
          _fase = _Fase.semConexao;
          _erro = e.mensagem;
        });
      }
    }
  }

  void _usar(Marca marca) {
    MarcaAtual.aplicar(marca);
    setState(() => _fase = _Fase.abertura);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: switch (_fase) {
        _Fase.descobrindo => const _Descobrindo(key: ValueKey('descobrindo')),
        _Fase.semConexao => _SemConexao(
          key: const ValueKey('semConexao'),
          mensagem: _erro,
          onTentar: _descobrir,
        ),
        _Fase.escolher => EscolherImobiliariaPage(
          key: const ValueKey('escolher'),
          onEscolhida: _usar,
        ),
        _Fase.abertura => SplashPage(
          key: const ValueKey('abertura'),
          onFinished: () => setState(() => _fase = _Fase.login),
        ),
        _Fase.login => const LoginPage(key: ValueKey('login')),
      },
    );
  }
}

/// Neutra: nenhuma marca até a imobiliária ser identificada.
class _Descobrindo extends StatelessWidget {
  const _Descobrindo({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FundoMarca(
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.gold.withValues(alpha: 0.8),
        ),
      ),
    ),
  );
}

class _SemConexao extends StatelessWidget {
  const _SemConexao({
    super.key,
    required this.mensagem,
    required this.onTentar,
  });

  final String mensagem;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FundoMarca(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 44, color: AppColors.gold),
              const SizedBox(height: 12),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onTentar,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
