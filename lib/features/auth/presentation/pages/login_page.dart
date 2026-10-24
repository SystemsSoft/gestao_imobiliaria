import 'package:flutter/material.dart';

import '../../../../app/app.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/marca/descobrir_marca.dart';
import '../../../../core/marca/logo_marca.dart';
import '../../../../core/marca/marca.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.aviso});

  /// Mensagem mostrada ao abrir (ex.: sessão expirada).
  final String? aviso;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _vm = sl<LoginViewModel>();

  @override
  void initState() {
    super.initState();
    final aviso = widget.aviso;
    if (aviso != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(aviso)));
        }
      });
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    _vm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _vm.entrar(
      aparar(_usuarioController.text),
      aparar(_passwordController.text),
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_vm.erro ?? 'Falha no login')));
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
  }

  /// Esquece o código guardado e volta à escolha da imobiliária.
  void _trocarImobiliaria() {
    sl<DescobrirMarca>().esquecer();
    MarcaAtual.aplicar(null);
    navegadorGlobal.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const InicioApp()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.blue, AppColors.navyDark, AppColors.navyDark],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LogoMarca(altura: 150),
                        const SizedBox(height: 24),
                        ListenableBuilder(
                          listenable: _vm,
                          builder: (context, _) => _buildCard(context),
                        ),
                        if (MarcaAtual.atual case final m?
                            when !m.peloDominio &&
                                sl.isRegistered<DescobrirMarca>())
                          TextButton.icon(
                            onPressed: _trocarImobiliaria,
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: Text(
                              'Não é ${m.nome}? Trocar de imobiliária',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acesse sua conta',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usuarioController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'Usuário',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: _vm.validarUsuario,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _vm.senhaOculta,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _vm.senhaOculta ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: _vm.alternarSenha,
                ),
              ),
              validator: _vm.validarSenha,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.navy,
                    title: const Text('Esqueceu a senha?'),
                    content: const Text(
                      'Peça a um administrador para definir uma nova senha em '
                      'Equipe e Segurança > Usuários.\n\n'
                      'Se você é o administrador, peça ao suporte da '
                      'plataforma para redefinir a sua senha.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entendi'),
                      ),
                    ],
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 215, 188, 98),
                ),
                child: const Text('Esqueci minha senha'),
              ),
            ),
            const SizedBox(height: 8),
            _GoldButton(
              label: 'ENTRAR',
              loading: _vm.carregando,
              onPressed: _vm.carregando ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.onPressed,
    required this.loading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppColors.navyDark,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.navyDark,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}
