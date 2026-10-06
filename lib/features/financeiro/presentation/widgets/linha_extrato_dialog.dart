import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/linha_extrato.dart';

/// Lançamento manual de uma linha do extrato. Retorna a linha ou null.
Future<LinhaExtrato?> mostrarLinhaExtratoDialog(
  BuildContext context, {
  required String contaId,
}) => showDialog(
  context: context,
  builder: (_) => _LinhaDialog(contaId: contaId),
);

class _LinhaDialog extends StatefulWidget {
  const _LinhaDialog({required this.contaId});

  final String contaId;

  @override
  State<_LinhaDialog> createState() => _LinhaDialogState();
}

class _LinhaDialogState extends State<_LinhaDialog> {
  DateTime _data = DateTime.now();
  bool _credito = true;
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  final _documento = TextEditingController();

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    _documento.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Lançar linha do extrato'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.add),
                    label: Text('Crédito'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.remove),
                    label: Text('Débito'),
                  ),
                ],
                selected: {_credito},
                onSelectionChanged: (s) => setState(() => _credito = s.first),
              ),
              const SizedBox(height: 12),
              DateField(
                label: 'Data',
                value: _data,
                onChanged: (d) => setState(() => _data = d ?? _data),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Descrição *', controller: _descricao),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppTextField.money(label: 'Valor *', controller: _valor),
                  AppTextField(label: 'Documento', controller: _documento),
                ],
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
            LinhaExtrato(
              id: gerarId(),
              contaId: widget.contaId,
              data: _data,
              descricao: _descricao.text.trim(),
              valor: (_credito ? 1 : -1) * (parseMoney(_valor.text) ?? 0),
              documento: _documento.text.trim(),
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
