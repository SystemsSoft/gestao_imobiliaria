import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/errors/domain_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/usecases/entrar.dart';

/// Troca a senha de quem está logado.
Future<void> mostrarAlterarSenhaDialog(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _AlterarSenhaDialog());

class _AlterarSenhaDialog extends StatefulWidget {
  const _AlterarSenhaDialog();

  @override
  State<_AlterarSenhaDialog> createState() => _AlterarSenhaDialogState();
}

class _AlterarSenhaDialogState extends State<_AlterarSenhaDialog> {
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [_atual, _nova, _confirmacao]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await sl<AlterarSenha>()(
        atual: _atual.text,
        nova: _nova.text,
        confirmacao: _confirmacao.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      mostrarMensagem(context, 'Senha alterada.');
    } on DomainException catch (e) {
      setState(() => _erro = e.mensagem);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _campo(String rotulo, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      obscureText: true,
      decoration: InputDecoration(labelText: rotulo),
      onSubmitted: (_) => _salvar(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Alterar senha'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            _campo('Senha atual', _atual),
            _campo('Nova senha (mín. 8 caracteres)', _nova),
            _campo('Repita a nova senha', _confirmacao),
            if (_erro != null)
              Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navyDark,
          ),
          onPressed: _salvando ? null : _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
