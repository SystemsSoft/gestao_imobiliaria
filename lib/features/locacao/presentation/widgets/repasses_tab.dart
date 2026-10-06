import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/linha_repasse.dart';
import '../viewmodels/repasses_viewmodel.dart';

/// Repasse aos beneficiários (proprietários) dos aluguéis recebidos.
class RepassesTab extends StatefulWidget {
  const RepassesTab({super.key});

  @override
  State<RepassesTab> createState() => _RepassesTabState();
}

class _RepassesTabState extends State<RepassesTab> {
  final _vm = sl<RepassesViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _acao(Future<bool> Function() f) async {
    if (!await f() && mounted) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível concluir.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final grupos = _vm.grupos;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CompetenciaSelector(
                  value: _vm.competencia,
                  onChanged: _vm.mudarCompetencia,
                ),
                Text(
                  'A repassar: ${formatMoney(_vm.totalAPagar)}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Calculado a partir das cobranças pagas na competência: aluguel e '
              'encargos, menos taxa de administração, intermediação (1º mês), '
              'despesas do proprietário e IR retido por locatário PJ.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_vm.carregado && grupos.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: EmptyState(
                  icon: Icons.account_balance_outlined,
                  message: 'Nenhuma cobrança paga nesta competência.',
                ),
              ),
            for (final g in grupos) _grupo(g),
          ],
        );
      },
    );
  }

  Widget _grupo(GrupoRepasse g) {
    final b = g.beneficiario;
    final banco = [
      if (b.banco.isNotEmpty) 'Banco ${b.banco}',
      if (b.agencia.isNotEmpty) 'Ag. ${b.agencia}',
      if (b.conta.isNotEmpty) 'C/C ${b.conta}',
      if (b.pix.isNotEmpty) 'PIX ${b.pix}',
    ].join(' • ');
    return CardPadrao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      banco.isEmpty
                          ? 'Dados bancários não informados no cadastro'
                          : banco,
                      style: TextStyle(
                        color: banco.isEmpty
                            ? Colors.orangeAccent
                            : Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(g.totalLiquido),
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Divider(),
          for (final l in g.linhas) _linha(l),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _acao(() => _vm.imprimir(g)),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Demonstrativo (PDF)'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldLight,
                ),
              ),
              TextButton.icon(
                onPressed: () => _acao(() => _vm.marcarTodos(g)),
                icon: const Icon(Icons.done_all),
                label: const Text('Marcar todos como repassados'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linha(LinhaRepasse l) {
    final feito = _vm.realizadoEm(l);
    String m(double v) => formatMoney(v);
    final partes = [
      'Aluguel ${m(l.aluguel)}',
      if (l.encargos != 0)
        '${l.encargos > 0 ? '+' : '−'} encargos ${m(l.encargos.abs())}',
      '− adm. ${m(l.taxaAdministracao)}',
      if (l.taxaIntermediacao > 0) '− intermediação ${m(l.taxaIntermediacao)}',
      if (l.despesasProprietario > 0) '− despesas ${m(l.despesasProprietario)}',
      if (l.irrf > 0) '− IRRF ${m(l.irrf)}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Checkbox(
            value: feito != null,
            activeColor: AppColors.gold,
            checkColor: AppColors.navyDark,
            onChanged: (v) => _acao(() => _vm.marcar(l, v ?? false)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.contrato.numero} • ${_vm.imovelDoContrato(l.contrato)} '
                  '(${decimalToText(l.beneficiario.percentual)}%)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  partes.join(' '),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (feito != null)
                  Text(
                    'Repassado em ${formatDate(feito)}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            m(l.liquido),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
