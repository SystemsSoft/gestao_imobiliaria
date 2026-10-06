import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/cobranca.dart';
import '../../domain/entities/locacao_enums.dart';
import '../viewmodels/cobrancas_viewmodel.dart';

/// Cobranças mensais: geração, pagamento, boletos e recibos.
class CobrancasTab extends StatefulWidget {
  const CobrancasTab({super.key});

  @override
  State<CobrancasTab> createState() => _CobrancasTabState();
}

class _CobrancasTabState extends State<CobrancasTab> {
  final _vm = sl<CobrancasViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _acao(Future<bool> Function() f, [String? sucesso]) async {
    final ok = await f();
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível concluir.');
    } else if (sucesso != null) {
      mostrarMensagem(context, sucesso);
    }
  }

  Future<void> _gerar() async {
    await _vm.gerar();
    if (mounted) {
      mostrarMensagem(context, _vm.erro ?? _vm.resultadoGeracao ?? '');
    }
  }

  Future<void> _pagar(Cobranca c) async {
    final r = await showDialog<({DateTime data, double valor})>(
      context: context,
      builder: (_) => _PagamentoDialog(vm: _vm, cobranca: c),
    );
    if (r != null) {
      await _acao(() => _vm.pagar(c, r.data, r.valor), 'Pagamento registrado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final lista = _vm.filtradas;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CompetenciaSelector(
                  value: _vm.competencia,
                  onChanged: _vm.mudarCompetencia,
                ),
                FilledButton.icon(
                  onPressed: _vm.ocupado ? null : _gerar,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                  ),
                  icon: const Icon(Icons.auto_mode),
                  label: const Text('Gerar cobranças do mês'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ResumoValores(
              itens: [
                (
                  rotulo: 'Previsto',
                  valor: formatMoney(_vm.totalPrevisto),
                  cor: AppColors.gold,
                ),
                (
                  rotulo: 'Recebido',
                  valor: formatMoney(_vm.totalRecebido),
                  cor: Colors.greenAccent,
                ),
                (
                  rotulo: 'Em aberto',
                  valor: formatMoney(_vm.totalEmAberto),
                  cor: Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final f in FiltroCobranca.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.label),
                        selected: _vm.filtro == f,
                        selectedColor: AppColors.gold,
                        labelStyle: TextStyle(
                          color: _vm.filtro == f
                              ? AppColors.navyDark
                              : Colors.white,
                        ),
                        onSelected: (_) => _vm.filtrar(f),
                      ),
                    ),
                ],
              ),
            ),
            if (_vm.carregado && lista.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message:
                      'Nenhuma cobrança nesta competência.\n'
                      'Use "Gerar cobranças do mês" para criar as cobranças dos contratos vigentes.',
                ),
              ),
            for (final c in lista) _card(c),
          ],
        );
      },
    );
  }

  Widget _card(Cobranca c) {
    final atrasada = c.atrasada(_vm.hoje);
    final (rotulo, cor) = switch (c.status) {
      StatusCobranca.paga => ('Paga', Colors.greenAccent),
      StatusCobranca.cancelada => ('Cancelada', Colors.grey),
      StatusCobranca.aberta when atrasada => ('Atrasada', Colors.redAccent),
      StatusCobranca.aberta => ('Em aberto', Colors.orangeAccent),
    };
    final contrato = _vm.contrato(c.contratoId);
    return CardPadrao(
      borda: cor,
      onTap: c.status == StatusCobranca.aberta ? () => _pagar(c) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      contrato?.numero ?? '—',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GoldChip(rotulo, color: cor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _vm.locatario(c),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  c.itens
                      .map((i) => '${i.descricao} ${formatMoney(i.valor)}')
                      .join(' + '),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  c.status == StatusCobranca.paga
                      ? 'Pago ${formatMoney(c.valorPago)} em ${formatDate(c.dataPagamento)}'
                            '${c.multa + c.juros > 0 ? ' (multa ${formatMoney(c.multa)} + juros ${formatMoney(c.juros)})' : ''}'
                            '${c.desconto > 0 ? ' (desconto ${formatMoney(c.desconto)})' : ''}'
                      : 'Vence em ${formatDate(c.vencimento)} • ${formatMoney(c.total)}',
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.navy,
            onSelected: (v) => switch (v) {
              'pagar' => _pagar(c),
              'boleto' => _acao(() => _vm.boleto(c)),
              'recibo' => _acao(() => _vm.recibo(c)),
              'estornar' => _acao(
                () => _vm.estornar(c),
                'Pagamento estornado.',
              ),
              'cancelar' => _acao(() => _vm.cancelar(c), 'Cobrança cancelada.'),
              _ => () async {
                if (await confirmDelete(context, 'Excluir esta cobrança?')) {
                  await _acao(() => _vm.remover(c));
                }
              }(),
            },
            itemBuilder: (_) => [
              if (c.status == StatusCobranca.aberta)
                const PopupMenuItem(
                  value: 'pagar',
                  child: Text('Registrar pagamento'),
                ),
              if (c.status != StatusCobranca.cancelada)
                const PopupMenuItem(
                  value: 'boleto',
                  child: Text('Emitir boleto (PDF)'),
                ),
              if (c.status == StatusCobranca.paga) ...const [
                PopupMenuItem(
                  value: 'recibo',
                  child: Text('Emitir recibo (PDF)'),
                ),
                PopupMenuItem(
                  value: 'estornar',
                  child: Text('Estornar pagamento'),
                ),
              ],
              if (c.status == StatusCobranca.aberta)
                const PopupMenuItem(
                  value: 'cancelar',
                  child: Text('Cancelar cobrança'),
                ),
              const PopupMenuItem(value: 'del', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PagamentoDialog extends StatefulWidget {
  const _PagamentoDialog({required this.vm, required this.cobranca});

  final CobrancasViewModel vm;
  final Cobranca cobranca;

  @override
  State<_PagamentoDialog> createState() => _PagamentoDialogState();
}

class _PagamentoDialogState extends State<_PagamentoDialog> {
  late DateTime _data = widget.vm.hoje;
  final _valor = TextEditingController();
  bool _valorEditado = false;

  double get _devido {
    final e = widget.vm.simularEncargos(widget.cobranca, _data);
    return e?.devido(widget.cobranca.total) ?? widget.cobranca.total;
  }

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
    final c = widget.cobranca;
    final e = widget.vm.simularEncargos(c, _data);
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
            Text('Vencimento: ${formatDate(c.vencimento)}'),
            const SizedBox(height: 12),
            DateField(
              label: 'Data do pagamento',
              value: _data,
              onChanged: _mudarData,
            ),
            const SizedBox(height: 12),
            linha('Valor da cobrança', c.total),
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
