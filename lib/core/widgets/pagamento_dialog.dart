import 'package:flutter/material.dart';

import '../domain/encargos.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'form_widgets.dart';

/// Diálogo de registro de pagamento com simulação de multa, juros e
/// desconto conforme a data. Retorna a data e o valor recebido.
Future<({DateTime data, double valor})?> mostrarPagamentoDialog(
  BuildContext context, {
  required double valor,
  required DateTime vencimento,
  required DateTime hoje,
  required Encargos? Function(DateTime data) simular,
  String rotuloValor = 'Valor da cobrança',
}) => showDialog(
  context: context,
  builder: (_) => _PagamentoDialog(
    valor: valor,
    vencimento: vencimento,
    hoje: hoje,
    simular: simular,
    rotuloValor: rotuloValor,
  ),
);

class _PagamentoDialog extends StatefulWidget {
  const _PagamentoDialog({
    required this.valor,
    required this.vencimento,
    required this.hoje,
    required this.simular,
    required this.rotuloValor,
  });

  final double valor;
  final DateTime vencimento;
  final DateTime hoje;
  final Encargos? Function(DateTime) simular;
  final String rotuloValor;

  @override
  State<_PagamentoDialog> createState() => _PagamentoDialogState();
}

class _PagamentoDialogState extends State<_PagamentoDialog> {
  late DateTime _data = widget.hoje;
  final _valor = TextEditingController();
  bool _valorEditado = false;

  double get _devido =>
      widget.simular(_data)?.devido(widget.valor) ?? widget.valor;

  @override
  void initState() {
    super.initState();
    _valor.text = moneyToText(_devido);
  }

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  void _mudarData(DateTime? d) {
    if (d == null) return;
    setState(() {
      _data = d;
      if (!_valorEditado) _valor.text = moneyToText(_devido);
    });
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.simular(_data);
    Widget linha(String r, double v, {Color? cor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(r, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            formatMoney(v),
            style: TextStyle(color: cor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Registrar pagamento'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Vencimento: ${formatDate(widget.vencimento)}'),
            const SizedBox(height: 12),
            DateField(
              label: 'Data do pagamento',
              value: _data,
              onChanged: _mudarData,
            ),
            const SizedBox(height: 12),
            linha(widget.rotuloValor, widget.valor),
            if (e != null && e.multa > 0)
              linha('Multa', e.multa, cor: Colors.orangeAccent),
            if (e != null && e.juros > 0)
              linha(
                'Juros (${e.diasAtraso} dia(s))',
                e.juros,
                cor: Colors.orangeAccent,
              ),
            if (e != null && e.desconto > 0)
              linha(
                'Desconto de pontualidade',
                -e.desconto,
                cor: Colors.greenAccent,
              ),
            const Divider(),
            linha('Valor devido', _devido, cor: AppColors.gold),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Valor recebido',
              controller: _valor,
              prefixText: r'R$ ',
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              onChanged: (_) => _valorEditado = true,
            ),
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
          onPressed: () => Navigator.pop(context, (
            data: _data,
            valor: parseMoney(_valor.text) ?? _devido,
          )),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
