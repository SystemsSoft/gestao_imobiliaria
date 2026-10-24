import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/pagamento_dialog.dart';
import '../../domain/entities/parcela.dart';
import '../../domain/entities/venda_enums.dart';
import '../pages/venda_detalhe_page.dart';
import '../viewmodels/recebimentos_viewmodel.dart';

/// Parcelas do financiamento próprio a receber, por mês.
class RecebimentosTab extends StatefulWidget {
  const RecebimentosTab({super.key});

  @override
  State<RecebimentosTab> createState() => _RecebimentosTabState();
}

class _RecebimentosTabState extends State<RecebimentosTab> {
  final _vm = sl<RecebimentosViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _acao(Future<bool> Function() f, String sucesso) async {
    final ok = await f();
    if (mounted) mostrarMensagem(context, ok ? sucesso : _vm.erro ?? 'Falha.');
  }

  Future<void> _pagar(Parcela p) async {
    final r = await mostrarPagamentoDialog(
      context,
      valor: p.valor,
      vencimento: p.vencimento,
      hoje: _vm.hoje,
      simular: (d) => _vm.simular(p, d),
      rotuloValor: 'Valor da parcela',
    );
    if (r != null) {
      await _acao(() => _vm.pagar(p, r.data, r.valor), 'Pagamento registrado.');
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
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CompetenciaSelector(value: _vm.mes, onChanged: _vm.mudarMes),
                if (_vm.totalAtrasado > 0)
                  Text(
                    'Total em atraso: ${formatMoney(_vm.totalAtrasado)}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ResumoValores(
              itens: [
                (
                  rotulo: 'Previsto',
                  valor: formatMoney(_vm.previsto),
                  cor: AppColors.gold,
                ),
                (
                  rotulo: 'Recebido',
                  valor: formatMoney(_vm.recebido),
                  cor: Colors.greenAccent,
                ),
                (
                  rotulo: 'Em aberto',
                  valor: formatMoney(_vm.emAberto),
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
                  for (final f in FiltroParcela.values)
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
                  icon: Icons.calendar_month_outlined,
                  message: 'Nenhuma parcela com vencimento neste mês.',
                ),
              ),
            for (final p in lista) _card(p),
          ],
        );
      },
    );
  }

  Widget _card(Parcela p) {
    final v = _vm.venda(p.vendaId);
    return CardPadrao(
      onTap: p.status == StatusParcela.aberta ? () => _pagar(p) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${v?.numero ?? '—'} • ${p.rotulo}',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    statusParcelaChip(p, _vm.hoje),
                  ],
                ),
                Text(
                  _vm.compradores(p),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  p.status == StatusParcela.paga
                      ? 'Pago ${formatMoney(p.valorPago)} em ${formatDate(p.dataPagamento)}'
                      : 'Vence em ${formatDate(p.vencimento)} • ${formatMoney(p.valor)}',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.navy,
            onSelected: (op) => switch (op) {
              'pagar' => _pagar(p),
              'estornar' => _acao(
                () => _vm.estornar(p),
                'Pagamento estornado.',
              ),
              _ => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => VendaDetalhePage(vendaId: p.vendaId),
                ),
              ),
            },
            itemBuilder: (_) => [
              if (p.status == StatusParcela.aberta)
                const PopupMenuItem(
                  value: 'pagar',
                  child: Text('Registrar pagamento'),
                ),
              if (p.status == StatusParcela.paga)
                const PopupMenuItem(
                  value: 'estornar',
                  child: Text('Estornar pagamento'),
                ),
              const PopupMenuItem(value: 'venda', child: Text('Abrir venda')),
            ],
          ),
        ],
      ),
    );
  }
}
