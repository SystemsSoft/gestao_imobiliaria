import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/fluxo_caixa.dart';
import '../viewmodels/fluxo_caixa_viewmodel.dart';

const _abrev = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

/// Fluxo de caixa do ano: entradas, saídas e saldo acumulado por mês.
class FluxoCaixaTab extends StatefulWidget {
  const FluxoCaixaTab({super.key});

  @override
  State<FluxoCaixaTab> createState() => _FluxoCaixaTabState();
}

class _FluxoCaixaTabState extends State<FluxoCaixaTab> {
  final _vm = sl<FluxoCaixaViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final f = _vm.fluxo;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CompetenciaSelector(
                  value: DateTime(_vm.ano),
                  anual: true,
                  onChanged: (d) => _vm.mudarAno(d.year),
                ),
                SegmentedButton<RegimeFluxo>(
                  segments: [
                    for (final r in RegimeFluxo.values)
                      ButtonSegment(value: r, label: Text(r.label)),
                  ],
                  selected: {_vm.regime},
                  onSelectionChanged: (s) => _vm.mudarRegime(s.first),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _vm.regime.descricao,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ResumoValores(
              itens: [
                (
                  rotulo: 'Entradas',
                  valor: formatMoney(f.totalEntradas),
                  cor: Colors.greenAccent,
                ),
                (
                  rotulo: 'Saídas',
                  valor: formatMoney(f.totalSaidas),
                  cor: Colors.redAccent,
                ),
                (
                  rotulo: 'Saldo final',
                  valor: formatMoney(f.saldoFinal),
                  cor: f.saldoFinal >= 0 ? AppColors.gold : Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Saldo de abertura: ${formatMoney(f.saldoInicial)} • saldo atual das contas: '
              '${formatMoney(_vm.saldoAtual)}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _Grafico(vm: _vm, fluxo: f),
            const SizedBox(height: 12),
            _tabela(f),
            if (_vm.mesSelecionado != null) ...[
              const SizedBox(height: 16),
              _movimentos(),
            ],
          ],
        );
      },
    );
  }

  Widget _tabela(FluxoAno f) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
        columns: const [
          DataColumn(label: Text('Mês')),
          DataColumn(label: Text('Entradas'), numeric: true),
          DataColumn(label: Text('Saídas'), numeric: true),
          DataColumn(label: Text('Saldo do mês'), numeric: true),
          DataColumn(label: Text('Saldo acumulado'), numeric: true),
        ],
        rows: [
          for (final m in f.meses)
            DataRow(
              selected: _vm.mesSelecionado == m.mes,
              onSelectChanged: (_) => _vm.selecionarMes(m.mes),
              cells: [
                DataCell(Text(nomeMes(m.mes))),
                DataCell(
                  Text(
                    formatMoney(m.entradas),
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                ),
                DataCell(
                  Text(
                    formatMoney(m.saidas),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                DataCell(Text(formatMoney(m.saldo))),
                DataCell(
                  Text(
                    formatMoney(m.saldoAcumulado),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: m.saldoAcumulado < 0
                          ? Colors.redAccent
                          : AppColors.goldLight,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _movimentos() {
    final mov = _vm.movimentos;
    return FormSection(
      title: 'Movimentos de ${nomeMes(_vm.mesSelecionado!)}/${_vm.ano}',
      icon: Icons.list_alt_outlined,
      children: [
        if (mov.isEmpty) const Text('Nenhum movimento neste mês.'),
        for (final m in mov)
          Row(
            children: [
              SizedBox(
                width: 78,
                child: Text(
                  formatDate(m.data),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Expanded(
                child: Text(
                  '${m.lancamento.descricao}${m.previsto ? ' (previsto)' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatMoney(
                  m.lancamento.tipo.sinal *
                      (m.previsto
                          ? m.lancamento.valor
                          : (m.lancamento.valorBaixa ?? m.lancamento.valor)),
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: m.lancamento.tipo == TipoLancamento.receber
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Gráfico de barras: entradas (verde) e saídas (vermelho) por mês.
class _Grafico extends StatelessWidget {
  const _Grafico({required this.vm, required this.fluxo});

  final FluxoCaixaViewModel vm;
  final FluxoAno fluxo;

  static const _altura = 150.0;

  @override
  Widget build(BuildContext context) {
    final maior = vm.maiorValor;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: _altura + 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final m in fluxo.meses)
                  Expanded(
                    child: InkWell(
                      onTap: () => vm.selecionarMes(m.mes),
                      child: Container(
                        decoration: BoxDecoration(
                          color: vm.mesSelecionado == m.mes
                              ? AppColors.gold.withValues(alpha: 0.12)
                              : null,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _barra(
                                  m.entradas / maior * _altura,
                                  Colors.greenAccent,
                                ),
                                const SizedBox(width: 2),
                                _barra(
                                  m.saidas / maior * _altura,
                                  Colors.redAccent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _abrev[m.mes - 1],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legenda(Colors.greenAccent, 'Entradas'),
              SizedBox(width: 16),
              _Legenda(Colors.redAccent, 'Saídas'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barra(double altura, Color cor) => Container(
    width: 10,
    height: altura < 2 && altura > 0 ? 2 : altura,
    decoration: BoxDecoration(
      color: cor.withValues(alpha: 0.85),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
    ),
  );
}

class _Legenda extends StatelessWidget {
  const _Legenda(this.cor, this.texto);

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, color: cor),
      const SizedBox(width: 4),
      Text(texto, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}
