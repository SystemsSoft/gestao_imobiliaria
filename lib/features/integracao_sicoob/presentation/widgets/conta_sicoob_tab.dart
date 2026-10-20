import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../pages/integracao_sicoob_page.dart';
import '../viewmodels/integracao_sicoob_viewmodel.dart';

/// Saldo e extrato (API Conta Corrente), com importação para a Conciliação
/// bancária do Financeiro.
class ContaSicoobTab extends StatefulWidget {
  const ContaSicoobTab({super.key, required this.vm});

  final IntegracaoSicoobViewModel vm;

  @override
  State<ContaSicoobTab> createState() => _ContaSicoobTabState();
}

class _ContaSicoobTabState extends State<ContaSicoobTab> {
  late int _mes = DateTime.now().month;
  late int _ano = DateTime.now().year;

  IntegracaoSicoobViewModel get _vm => widget.vm;

  Future<void> _rodar(Future<bool> acao, [String? sucesso]) async {
    final ok = await acao;
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Erro.');
    } else if (sucesso != null) {
      mostrarMensagem(context, sucesso);
    }
  }

  Future<void> _importar() async {
    final ok = await _vm.importarExtrato(_mes, _ano);
    if (!mounted) return;
    mostrarMensagem(
      context,
      ok ? (_vm.ultimaMensagem ?? 'Importado.') : (_vm.erro ?? 'Erro.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final m = margemSicoob(context);
        final s = _vm.saldo;
        final e = _vm.extrato;
        return ListView(
          padding: EdgeInsets.fromLTRB(m, 16, m, 64),
          children: [
            if (!_vm.pronto) avisoConfigurar(),
            FormSection(
              title: 'Saldo',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                if (s == null)
                  const Text(
                    'Consulte o saldo da conta corrente no Sicoob.',
                    style: TextStyle(color: Colors.white60),
                  )
                else
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      _valor('Saldo', s.saldo, destaque: true),
                      _valor('Limite', s.saldoLimite),
                      _valor('Bloqueado', s.saldoBloqueado),
                    ],
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _vm.ocupado
                        ? null
                        : () => _rodar(_vm.buscarSaldo()),
                    icon: const Icon(Icons.sync),
                    label: const Text('Consultar saldo'),
                  ),
                ),
              ],
            ),
            FormSection(
              title: 'Extrato do mês',
              icon: Icons.receipt_outlined,
              children: [
                FieldRow(
                  children: [
                    AppDropdown<int>(
                      label: 'Mês',
                      value: _mes,
                      items: List.generate(12, (i) => i + 1),
                      labelOf: (v) => v.toString().padLeft(2, '0'),
                      onChanged: (v) => setState(() => _mes = v ?? _mes),
                    ),
                    AppDropdown<int>(
                      label: 'Ano',
                      value: _ano,
                      items: [
                        for (var a = DateTime.now().year; a >= 2023; a--) a,
                      ],
                      labelOf: (v) => '$v',
                      onChanged: (v) => setState(() => _ano = v ?? _ano),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _vm.ocupado
                          ? null
                          : () => _rodar(_vm.buscarExtrato(_mes, _ano)),
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar extrato'),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                      ),
                      onPressed: _vm.ocupado ? null : _importar,
                      icon: const Icon(Icons.move_down),
                      label: const Text('Levar para a conciliação'),
                    ),
                  ],
                ),
                if (e != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Saldo anterior ${formatMoney(e.saldoAnterior)} · '
                    'saldo atual ${formatMoney(e.saldoAtual)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  if (e.transacoes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Nenhuma movimentação no mês.'),
                    ),
                  for (final t in e.transacoes)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        t.credito ? Icons.call_received : Icons.call_made,
                        color: t.credito
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                      title: Text(t.descricao),
                      subtitle: Text(
                        [
                          formatDate(t.data),
                          if (t.documento.isNotEmpty) t.documento,
                          if (t.complemento.isNotEmpty) t.complemento,
                        ].join(' · '),
                      ),
                      trailing: Text(
                        '${t.credito ? '+' : '−'} ${formatMoney(t.valor)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: t.credito
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _valor(String rotulo, double v, {bool destaque = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(rotulo, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      Text(
        formatMoney(v),
        style: TextStyle(
          fontSize: destaque ? 22 : 16,
          fontWeight: FontWeight.w700,
          color: destaque ? AppColors.gold : Colors.white,
        ),
      ),
    ],
  );
}
