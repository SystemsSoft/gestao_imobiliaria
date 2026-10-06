import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/ir_fiscal.dart';
import '../viewmodels/ir_fiscal_viewmodel.dart';

/// Cálculo do Imposto de Renda sobre aluguéis de todos os beneficiários.
class IrFiscalTab extends StatefulWidget {
  const IrFiscalTab({super.key});

  @override
  State<IrFiscalTab> createState() => _IrFiscalTabState();
}

class _IrFiscalTabState extends State<IrFiscalTab> {
  final _vm = sl<IrFiscalViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _informe(IrBeneficiario b) async {
    if (!await _vm.imprimirInforme(b) && mounted) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível gerar o informe.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (!_vm.carregado) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            CompetenciaSelector(
              value: DateTime(_vm.ano),
              anual: true,
              onChanged: (d) => _vm.mudarAno(d.year),
            ),
            const SizedBox(height: 12),
            ResumoValores(
              itens: [
                (
                  rotulo: 'Aluguéis recebidos',
                  valor: formatMoney(_vm.totalBruto),
                  cor: AppColors.gold,
                ),
                (
                  rotulo: 'Carnê-leão (estimado)',
                  valor: formatMoney(_vm.totalCarneLeao),
                  cor: Colors.orangeAccent,
                ),
                (
                  rotulo: 'IRRF retido',
                  valor: formatMoney(_vm.totalIrrf),
                  cor: AppColors.blueGlow,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_vm.beneficiarios.isEmpty)
              const EmptyState(
                icon: Icons.calculate_outlined,
                message: 'Nenhum beneficiário de contrato de locação ainda.',
              ),
            for (final b in _vm.beneficiarios) _beneficiario(b),
            if (_vm.darfs.isNotEmpty) _darfs(),
            _explicacao(),
          ],
        );
      },
    );
  }

  Widget _beneficiario(IrBeneficiario b) {
    final aberto = _vm.aberto == b.beneficiario.id;
    return CardPadrao(
      onTap: () => _vm.alternar(b.beneficiario.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            b.beneficiario.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GoldChip(
                          b.pessoaJuridica
                              ? 'Pessoa jurídica'
                              : 'Pessoa física',
                          color: b.pessoaJuridica
                              ? AppColors.blueGlow
                              : AppColors.gold,
                        ),
                      ],
                    ),
                    Text(
                      b.semMovimento
                          ? 'Sem aluguel recebido em ${_vm.ano}'
                          : 'Bruto ${formatMoney(b.bruto)} • deduções ${formatMoney(b.deducoes)} • '
                                'carnê-leão ${formatMoney(b.carneLeao)} • IRRF ${formatMoney(b.irrf)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Informe de rendimentos (PDF)',
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.goldLight,
                ),
                onPressed: b.semMovimento ? null : () => _informe(b),
              ),
              Icon(
                aberto ? Icons.expand_less : Icons.expand_more,
                color: AppColors.gold,
              ),
            ],
          ),
          if (aberto) ...[
            if (b.pessoaJuridica)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Pessoa jurídica: o aluguel é tributado na apuração da empresa; valores informativos.',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 34,
                dataRowMinHeight: 32,
                dataRowMaxHeight: 36,
                headingTextStyle: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                dataTextStyle: const TextStyle(fontSize: 12),
                columns: const [
                  DataColumn(label: Text('Mês')),
                  DataColumn(label: Text('Rend. bruto'), numeric: true),
                  DataColumn(label: Text('Deduções'), numeric: true),
                  DataColumn(label: Text('Base carnê-leão'), numeric: true),
                  DataColumn(label: Text('Carnê-leão'), numeric: true),
                  DataColumn(label: Text('Base IRRF'), numeric: true),
                  DataColumn(label: Text('IRRF'), numeric: true),
                ],
                rows: [
                  for (final m in b.meses)
                    DataRow(
                      cells: [
                        DataCell(Text(nomeMes(m.mes))),
                        DataCell(Text(formatMoney(m.rendimentoBruto))),
                        DataCell(Text(formatMoney(m.deducoes))),
                        DataCell(Text(formatMoney(m.baseCarneLeao))),
                        DataCell(Text(formatMoney(m.impostoCarneLeao))),
                        DataCell(Text(formatMoney(m.baseIrrf))),
                        DataCell(Text(formatMoney(m.irrfRetido))),
                      ],
                    ),
                  DataRow(
                    color: WidgetStatePropertyAll(
                      AppColors.gold.withValues(alpha: 0.1),
                    ),
                    cells: [
                      const DataCell(
                        Text(
                          'TOTAL',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      DataCell(Text(formatMoney(b.bruto))),
                      DataCell(Text(formatMoney(b.deducoes))),
                      DataCell(Text(formatMoney(b.baseCarneLeao))),
                      DataCell(Text(formatMoney(b.carneLeao))),
                      DataCell(Text(formatMoney(b.baseIrrf))),
                      DataCell(Text(formatMoney(b.irrf))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _darfs() {
    return FormSection(
      title: 'DARF do carnê-leão a recolher (${_vm.darfs.length})',
      icon: Icons.request_page_outlined,
      children: [
        for (final d in _vm.darfs)
          Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  formatDate(d.vencimento),
                  style: const TextStyle(color: AppColors.goldLight),
                ),
              ),
              Expanded(
                child: Text(
                  '${d.beneficiario.nome} • ${nomeMes(d.mes)}/${d.ano} • código ${DarfCarneLeao.codigoReceita}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatMoney(d.valor),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        const Text(
          'Vencimento no último dia útil do mês seguinte ao recebimento, sem considerar feriados.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _explicacao() {
    return FormSection(
      title: 'Como o cálculo é feito',
      icon: Icons.info_outline,
      children: const [
        Text(
          '• Regime de caixa: o aluguel entra no mês em que foi recebido.\n'
          '• Deduções: taxa de administração e despesas pagas pelo locador marcadas como dedutíveis.\n'
          '• Locatário pessoa jurídica: o IR é retido na fonte (IRRF) e descontado no repasse.\n'
          '• Locatário pessoa física: o beneficiário recolhe pelo carnê-leão sobre a soma dos aluguéis do mês.\n'
          '• Valores estimados com a tabela progressiva mensal vigente; confirme com o contador.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
      ],
    );
  }
}
