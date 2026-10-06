import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../viewmodels/comissoes_viewmodel.dart';

/// Comissões de corretagem a pagar e recibos de comissão.
class ComissoesTab extends StatefulWidget {
  const ComissoesTab({super.key});

  @override
  State<ComissoesTab> createState() => _ComissoesTabState();
}

class _ComissoesTabState extends State<ComissoesTab> {
  final _vm = sl<ComissoesViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _acao(Future<bool> Function() f) async {
    if (!await f() && mounted) mostrarMensagem(context, _vm.erro ?? 'Falha.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final linhas = _vm.linhas;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            ResumoValores(
              itens: [
                (
                  rotulo: 'Pendente',
                  valor: formatMoney(_vm.totalPendente),
                  cor: Colors.orangeAccent,
                ),
                (
                  rotulo: 'Pago',
                  valor: formatMoney(_vm.totalPago),
                  cor: Colors.greenAccent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final f in FiltroComissao.values)
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
            if (_vm.carregado && linhas.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: EmptyState(
                  icon: Icons.percent,
                  message: 'Nenhuma comissão neste filtro.',
                ),
              ),
            for (final l in linhas)
              CardPadrao(
                child: Row(
                  children: [
                    Checkbox(
                      value: l.paga,
                      activeColor: AppColors.gold,
                      checkColor: AppColors.navyDark,
                      onChanged: (x) => _acao(() => _vm.marcar(l, x ?? false)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.beneficiario,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${l.venda.numero} • ${decimalToText(l.participacao.percentual)}% de '
                            '${decimalToText(l.venda.comissaoPercentual)}% sobre ${formatMoney(l.venda.valorVenda)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            l.paga
                                ? 'Paga em ${formatDate(l.participacao.pagaEm)}'
                                : 'Pendente',
                            style: TextStyle(
                              fontSize: 12,
                              color: l.paga
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatMoney(l.valor),
                      style: const TextStyle(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Recibo de comissão (PDF)',
                      icon: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: AppColors.goldLight,
                      ),
                      onPressed: () => _acao(() => _vm.recibo(l)),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
