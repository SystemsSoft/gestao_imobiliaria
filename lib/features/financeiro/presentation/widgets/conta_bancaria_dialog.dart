import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/conta_bancaria.dart';

/// Cadastro de conta bancária. Retorna a conta preenchida ou null.
Future<ContaBancaria?> mostrarContaBancariaDialog(
  BuildContext context, {
  ContaBancaria? conta,
}) => showDialog(
  context: context,
  builder: (_) => _ContaDialog(conta: conta),
);

class _ContaDialog extends StatefulWidget {
  const _ContaDialog({this.conta});

  final ContaBancaria? conta;

  @override
  State<_ContaDialog> createState() => _ContaDialogState();
}

class _ContaDialogState extends State<_ContaDialog> {
  ContaBancaria? get _c => widget.conta;
  late final _nome = TextEditingController(text: _c?.nome);
  late final _banco = TextEditingController(text: _c?.banco);
  late final _agencia = TextEditingController(text: _c?.agencia);
  late final _conta = TextEditingController(text: _c?.conta);
  late final _saldo = TextEditingController(
    text: moneyToText(_c?.saldoInicial),
  );
  late final _convenio = TextEditingController(text: _c?.convenio);
  late final _carteira = TextEditingController(text: _c?.carteira);

  @override
  void dispose() {
    for (final c in [
      _nome,
      _banco,
      _agencia,
      _conta,
      _saldo,
      _convenio,
      _carteira,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(_c == null ? 'Nova conta bancária' : 'Editar conta bancária'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              AppTextField(
                label: 'Nome da conta *',
                hint: 'Ex.: Itaú Empresa',
                controller: _nome,
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Banco', controller: _banco),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppTextField(label: 'Agência', controller: _agencia),
                  AppTextField(label: 'Conta', controller: _conta),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField.money(label: 'Saldo inicial', controller: _saldo),
              const SizedBox(height: 12),
              const Text(
                'Cobrança bancária (boletos)',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              FieldRow(
                children: [
                  AppTextField(label: 'Convênio', controller: _convenio),
                  AppTextField(label: 'Carteira', controller: _carteira),
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
            ContaBancaria(
              id: _c?.id ?? gerarId(),
              nome: _nome.text.trim(),
              banco: _banco.text.trim(),
              agencia: _agencia.text.trim(),
              conta: _conta.text.trim(),
              saldoInicial: parseMoney(_saldo.text) ?? 0,
              convenio: _convenio.text.trim(),
              carteira: _carteira.text.trim(),
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
