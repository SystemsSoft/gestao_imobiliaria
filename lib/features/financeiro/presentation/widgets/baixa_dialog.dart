import 'package:flutter/material.dart';

import '../../../../core/domain/encargos.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/services/atualizacao_monetaria.dart';
import '../../../../core/widgets/competencia_selector.dart';

typedef ResultadoBaixa = ({
  DateTime data,
  double valor,
  MeioPagamento meio,
  String? contaId,
});

/// Diálogo de baixa (pagamento ou recebimento) com juros, multa e
/// atualização monetária calculados pela data.
Future<ResultadoBaixa?> mostrarBaixaDialog(
  BuildContext context, {
  required Lancamento lancamento,
  required List<ContaBancaria> contas,
  required DateTime hoje,
  required ({Encargos encargos, VariacaoAcumulada variacao}) Function(
    DateTime data,
  )
  simular,
}) => showDialog(
  context: context,
  builder: (_) => _BaixaDialog(
    lancamento: lancamento,
    contas: contas,
    hoje: hoje,
    simular: simular,
  ),
);

class _BaixaDialog extends StatefulWidget {
  const _BaixaDialog({
    required this.lancamento,
    required this.contas,
    required this.hoje,
    required this.simular,
  });

  final Lancamento lancamento;
  final List<ContaBancaria> contas;
  final DateTime hoje;
  final ({Encargos encargos, VariacaoAcumulada variacao}) Function(DateTime)
  simular;

  @override
  State<_BaixaDialog> createState() => _BaixaDialogState();
}

class _BaixaDialogState extends State<_BaixaDialog> {
  late DateTime _data = soData(widget.hoje);
  final _valor = TextEditingController();
  bool _valorEditado = false;
  MeioPagamento _meio = MeioPagamento.pix;
  late String? _contaId = widget.contas.firstOrNull?.id;

  double get _devido =>
      widget.simular(_data).encargos.devido(widget.lancamento.valor);

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
      _data = soData(d);
      if (!_valorEditado) _valor.text = moneyToText(_devido);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lancamento;
    final r = widget.simular(_data);
    final e = r.encargos;
    Widget linha(String t, double v, {Color? cor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(t, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            formatMoney(v),
            style: TextStyle(color: cor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    final receber = l.tipo == TipoLancamento.receber;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(receber ? 'Receber conta' : 'Pagar conta'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.descricao,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Vencimento: ${formatDate(l.vencimento)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              DateField(
                label: receber ? 'Data do recebimento' : 'Data do pagamento',
                value: _data,
                onChanged: _mudarData,
              ),
              const SizedBox(height: 12),
              linha('Valor original', l.valor),
              if (e.correcao > 0)
                linha(
                  'Atualização ${l.indice.label} (${decimalToText(double.parse(r.variacao.percentual.toStringAsFixed(4)))}%)',
                  e.correcao,
                  cor: Colors.orangeAccent,
                ),
              if (e.multa > 0)
                linha(
                  'Multa (${decimalToText(l.multaPercentual)}%)',
                  e.multa,
                  cor: Colors.orangeAccent,
                ),
              if (e.juros > 0)
                linha(
                  'Juros (${e.diasAtraso} dia(s))',
                  e.juros,
                  cor: Colors.orangeAccent,
                ),
              if (r.variacao.mesesSemIndice.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Índice ${l.indice.label} não cadastrado para: '
                    '${r.variacao.mesesSemIndice.map((m) => '${nomeMes(m.month)}/${m.year}').join(', ')}. '
                    'Esses meses foram considerados 0%.',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              const Divider(),
              linha('Valor devido', _devido, cor: AppColors.gold),
              const SizedBox(height: 12),
              AppTextField(
                label: receber ? 'Valor recebido' : 'Valor pago',
                controller: _valor,
                prefixText: r'R$ ',
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                onChanged: (_) => _valorEditado = true,
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppDropdown<MeioPagamento>(
                    label: 'Forma',
                    value: _meio,
                    items: MeioPagamento.values,
                    labelOf: (e) => e.label,
                    onChanged: (v) => setState(() => _meio = v ?? _meio),
                  ),
                  AppDropdown<String?>(
                    label: 'Conta bancária',
                    value: widget.contas.any((c) => c.id == _contaId)
                        ? _contaId
                        : null,
                    items: [null, ...widget.contas.map((c) => c.id)],
                    labelOf: (id) => id == null
                        ? 'Caixa / não informada'
                        : widget.contas.firstWhere((c) => c.id == id).nome,
                    onChanged: (v) => setState(() => _contaId = v),
                  ),
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
          onPressed: () => Navigator.pop(context, (
            data: _data,
            valor: parseMoney(_valor.text) ?? _devido,
            meio: _meio,
            contaId: _contaId,
          )),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
