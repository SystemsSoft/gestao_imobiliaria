import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/ir_mensal.dart';
import '../../domain/services/tabela_ir.dart';
import '../viewmodels/imposto_renda_viewmodel.dart';

/// Cálculo do Imposto de Renda sobre aluguéis por beneficiário.
class ImpostoRendaTab extends StatefulWidget {
  const ImpostoRendaTab({super.key});

  @override
  State<ImpostoRendaTab> createState() => _ImpostoRendaTabState();
}

class _ImpostoRendaTabState extends State<ImpostoRendaTab> {
  final _vm = sl<ImpostoRendaViewModel>();

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
        final b = _vm.beneficiario;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CompetenciaSelector(
                  value: DateTime(_vm.ano),
                  anual: true,
                  onChanged: (d) => _vm.mudarAno(d.year),
                ),
                SizedBox(
                  width: 320,
                  child: AppDropdown<String>(
                    label: 'Beneficiário',
                    value: b?.id,
                    items: _vm.beneficiarios.map((c) => c.id).toList(),
                    labelOf: (id) =>
                        _vm.beneficiarios.firstWhere((c) => c.id == id).nome,
                    onChanged: _vm.selecionar,
                  ),
                ),
                FilledButton.icon(
                  onPressed: b == null
                      ? null
                      : () async {
                          if (!await _vm.imprimir() && context.mounted) {
                            mostrarMensagem(
                              context,
                              _vm.erro ?? 'Falha ao gerar o informe.',
                            );
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Informe de rendimentos'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (b == null)
              const EmptyState(
                icon: Icons.calculate_outlined,
                message: 'Nenhum beneficiário de contrato de locação ainda.',
              )
            else ...[
              if (_vm.beneficiarioPJ)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Beneficiário pessoa jurídica: os aluguéis são tributados na '
                    'apuração da empresa. Os valores abaixo são apenas informativos.',
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              ResumoValores(
                itens: [
                  (
                    rotulo: 'Rendimento bruto',
                    valor: formatMoney(_vm.total((m) => m.rendimentoBruto)),
                    cor: AppColors.gold,
                  ),
                  (
                    rotulo: 'Carnê-leão (estimado)',
                    valor: formatMoney(_vm.total((m) => m.impostoCarneLeao)),
                    cor: Colors.orangeAccent,
                  ),
                  (
                    rotulo: 'IRRF retido',
                    valor: formatMoney(_vm.total((m) => m.irrfRetido)),
                    cor: AppColors.blueGlow,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _tabela(_vm.meses),
            ],
            const SizedBox(height: 16),
            _explicacao(),
          ],
        );
      },
    );
  }

  Widget _tabela(List<IrMensal> meses) {
    DataCell v(double x) => DataCell(Text(formatMoney(x)));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
        columns: const [
          DataColumn(label: Text('Mês')),
          DataColumn(label: Text('Rend. bruto'), numeric: true),
          DataColumn(label: Text('Deduções'), numeric: true),
          DataColumn(label: Text('Base carnê-leão'), numeric: true),
          DataColumn(label: Text('Carnê-leão'), numeric: true),
          DataColumn(label: Text('Base IRRF'), numeric: true),
          DataColumn(label: Text('IRRF retido'), numeric: true),
        ],
        rows: [
          for (final m in meses)
            DataRow(
              cells: [
                DataCell(Text(nomeMes(m.mes))),
                v(m.rendimentoBruto),
                v(m.deducoes),
                v(m.baseCarneLeao),
                v(m.impostoCarneLeao),
                v(m.baseIrrf),
                v(m.irrfRetido),
              ],
            ),
          DataRow(
            color: WidgetStatePropertyAll(
              AppColors.gold.withValues(alpha: 0.1),
            ),
            cells: [
              const DataCell(
                Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              v(_vm.total((m) => m.rendimentoBruto)),
              v(_vm.total((m) => m.deducoes)),
              v(_vm.total((m) => m.baseCarneLeao)),
              v(_vm.total((m) => m.impostoCarneLeao)),
              v(_vm.total((m) => m.baseIrrf)),
              v(_vm.total((m) => m.irrfRetido)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _explicacao() {
    String faixa(FaixaIR f) => f.limite == double.infinity
        ? 'acima: ${decimalToText(f.aliquota * 100)}% (dedução ${formatMoney(f.deducao)})'
        : 'até ${formatMoney(f.limite)}: '
              '${f.aliquota == 0 ? 'isento' : '${decimalToText(f.aliquota * 100)}% (dedução ${formatMoney(f.deducao)})'}';
    return FormSection(
      title: 'Como o cálculo é feito',
      icon: Icons.info_outline,
      children: [
        const Text(
          '• Regime de caixa: o aluguel entra no mês em que foi recebido.\n'
          '• Deduções: taxa de administração e despesas pagas pelo locador '
          'marcadas como dedutíveis (IPTU, condomínio etc.).\n'
          '• Locatário pessoa jurídica: o IR é retido na fonte (IRRF) e '
          'descontado no repasse.\n'
          '• Locatário pessoa física: o beneficiário recolhe pelo carnê-leão '
          'sobre a soma dos aluguéis do mês.\n'
          '• A partir de 2026 aplica-se a redução da Lei nº 15.270/2025 '
          '(isenção até R\$ 5.000,00 e redução parcial até R\$ 7.350,00).',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        Text(
          'Tabela progressiva mensal: ${faixasIrMensal.map(faixa).join('; ')}.',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const Text(
          'Valores estimados. Confirme com o contador antes de recolher.',
          style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
        ),
      ],
    );
  }
}
