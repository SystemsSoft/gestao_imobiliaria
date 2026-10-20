import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/indice_mensal.dart';
import '../../domain/usecases/financeiro_usecases.dart';
import 'abrir_sicoob.dart';

/// Botão "Abrir banco" do Financeiro, com o lápis para trocar o link.
/// Sem link cadastrado, abre o Sicoob.
class BotaoAbrirBanco extends StatefulWidget {
  const BotaoAbrirBanco({super.key});

  @override
  State<BotaoAbrirBanco> createState() => _BotaoAbrirBancoState();
}

class _BotaoAbrirBancoState extends State<BotaoAbrirBanco> {
  late final Stream<ConfiguracaoFinanceira> _config =
      sl<ObservarConfiguracaoFinanceira>()();

  Future<void> _editar(String atual) async {
    final link = await showDialog<String>(
      context: context,
      builder: (_) => _LinkBancoDialog(atual: atual),
    );
    if (link == null) return;
    try {
      // Lê a configuração na hora de salvar, para não apagar multa e juros.
      final c = await sl<ObterConfiguracaoFinanceira>()();
      await sl<SalvarConfiguracaoFinanceira>()(
        ConfiguracaoFinanceira(
          multaPercentual: c.multaPercentual,
          jurosMesPercentual: c.jurosMesPercentual,
          indicePadrao: c.indicePadrao,
          linkBanco: link,
        ),
      );
      if (mounted) mostrarMensagem(context, 'Link do banco salvo.');
    } catch (e) {
      if (mounted) mostrarMensagem(context, 'Não foi possível salvar o link.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConfiguracaoFinanceira>(
      stream: _config,
      builder: (context, snapshot) {
        final salvo = snapshot.data?.linkBanco ?? '';
        final link = salvo.isEmpty ? linkSicoob : salvo;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BotaoAbrirSite(
              rotulo: 'Abrir banco',
              icone: Icons.language,
              onPressed: () => abrirSicoob(context, link: link),
            ),
            IconButton(
              tooltip: 'Editar link do banco',
              color: AppColors.gold,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _editar(link),
            ),
          ],
        );
      },
    );
  }
}

class _LinkBancoDialog extends StatefulWidget {
  const _LinkBancoDialog({required this.atual});

  final String atual;

  @override
  State<_LinkBancoDialog> createState() => _LinkBancoDialogState();
}

class _LinkBancoDialogState extends State<_LinkBancoDialog> {
  final _form = GlobalKey<FormState>();
  late final _link = TextEditingController(text: widget.atual);

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, aparar(_link.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Link do banco'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Endereço do internet banking aberto pelo botão "Abrir banco". '
                'Deixe vazio para voltar ao Sicoob.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Link do internet banking',
                hint: 'https://...',
                controller: _link,
                keyboardType: TextInputType.url,
                validator: (v) {
                  final t = aparar(v ?? '');
                  return t.isEmpty || t.startsWith('https://')
                      ? null
                      : 'Use um link que comece com https://';
                },
              ),
            ],
          ),
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
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
