import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/declarante_dimob.dart';

/// Edita os dados do declarante. Retorna o novo declarante ou null.
Future<DeclaranteDimob?> mostrarDeclaranteDialog(
  BuildContext context,
  DeclaranteDimob atual,
) => showDialog(
  context: context,
  builder: (_) => _DeclaranteDialog(atual: atual),
);

class _DeclaranteDialog extends StatefulWidget {
  const _DeclaranteDialog({required this.atual});

  final DeclaranteDimob atual;

  @override
  State<_DeclaranteDialog> createState() => _DeclaranteDialogState();
}

class _DeclaranteDialogState extends State<_DeclaranteDialog> {
  late final _documento = TextEditingController(text: widget.atual.documento);
  late final _nome = TextEditingController(text: widget.atual.nome);
  late final _respNome = TextEditingController(
    text: widget.atual.responsavelNome,
  );
  late final _respCpf = TextEditingController(
    text: widget.atual.responsavelCpf,
  );
  late final _recibo = TextEditingController(text: widget.atual.numeroRecibo);
  late bool _retificadora = widget.atual.retificadora;

  @override
  void dispose() {
    for (final c in [_documento, _nome, _respNome, _respCpf, _recibo]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Declarante da DIMOB'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              AppTextField(label: 'Nome / razão social *', controller: _nome),
              const SizedBox(height: 12),
              AppTextField(
                label: 'CNPJ ou CPF',
                controller: _documento,
                keyboardType: TextInputType.number,
                inputFormatters: [cpfCnpjFormatter],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Responsável perante o CNPJ',
                controller: _respNome,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'CPF do responsável',
                controller: _respCpf,
                keyboardType: TextInputType.number,
                inputFormatters: [cpfCnpjFormatter],
              ),
              AppSwitch(
                label: 'Declaração retificadora',
                value: _retificadora,
                onChanged: (v) => setState(() => _retificadora = v),
              ),
              if (_retificadora)
                AppTextField(
                  label: 'Nº do recibo da declaração original',
                  controller: _recibo,
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
          onPressed: () => Navigator.pop(
            context,
            DeclaranteDimob(
              documento: _documento.text,
              nome: _nome.text.trim(),
              responsavelNome: _respNome.text.trim(),
              responsavelCpf: _respCpf.text,
              retificadora: _retificadora,
              numeroRecibo: _retificadora ? _recibo.text.trim() : '',
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
