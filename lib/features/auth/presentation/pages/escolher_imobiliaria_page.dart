import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/marca/descobrir_marca.dart';
import '../../../../core/marca/marca.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../splash/presentation/pages/splash_page.dart';

/// Fora do domínio de uma imobiliária, a pessoa informa o código dela (dado
/// pela imobiliária). Fica guardado neste aparelho para as próximas vezes.
class EscolherImobiliariaPage extends StatefulWidget {
  const EscolherImobiliariaPage({super.key, required this.onEscolhida});

  final ValueChanged<Marca> onEscolhida;

  @override
  State<EscolherImobiliariaPage> createState() =>
      _EscolherImobiliariaPageState();
}

class _EscolherImobiliariaPageState extends State<EscolherImobiliariaPage> {
  final _codigo = TextEditingController();
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final marca = await sl<DescobrirMarca>().porCodigo(_codigo.text);
      if (mounted) widget.onEscolhida(marca);
    } on DomainException catch (e) {
      if (mounted) setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FundoMarca(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.apartment, size: 44, color: AppColors.gold),
                      const SizedBox(height: 12),
                      Text(
                        'Gestão Imobiliária',
                        textAlign: TextAlign.center,
                        style: estiloTitulo(tamanho: 26),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Informe o código da sua imobiliária para continuar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _codigo,
                        autofocus: true,
                        autocorrect: false,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _carregando ? null : _continuar(),
                        decoration: InputDecoration(
                          labelText: 'Código da imobiliária',
                          hintText: 'ex.: joao',
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                          errorText: _erro,
                          errorMaxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _carregando ? null : _continuar,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: AppColors.navyDark,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: _carregando
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.navyDark,
                                ),
                              )
                            : const Text(
                                'CONTINUAR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
