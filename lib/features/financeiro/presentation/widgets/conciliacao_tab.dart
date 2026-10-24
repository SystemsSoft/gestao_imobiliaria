import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/lancamento.dart';
import '../../domain/entities/linha_extrato.dart';
import '../viewmodels/conciliacao_viewmodel.dart';
import 'conta_bancaria_dialog.dart';
import 'linha_extrato_dialog.dart';

/// Conciliação bancária: confronta o extrato com as contas baixadas.
class ConciliacaoTab extends StatefulWidget {
  const ConciliacaoTab({super.key});

  @override
  State<ConciliacaoTab> createState() => _ConciliacaoTabState();
}

class _ConciliacaoTabState extends State<ConciliacaoTab> {
  final _vm = sl<ConciliacaoViewModel>();

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

  Future<void> _conciliarAuto() async {
    final ok = await _vm.conciliarAutomaticamente();
    if (!mounted) return;
    mostrarMensagem(
      context,
      ok ? _vm.resultadoAuto ?? '' : _vm.erro ?? 'Não foi possível conciliar.',
    );
  }

  Future<void> _novaConta([bool editar = false]) async {
    final c = await mostrarContaBancariaDialog(
      context,
      conta: editar ? _vm.conta : null,
    );
    if (c != null) await _acao(() => _vm.salvarConta(c), 'Conta salva.');
  }

  Future<void> _novaLinha() async {
    final l = await mostrarLinhaExtratoDialog(context, contaId: _vm.conta!.id);
    if (l != null) await _acao(() => _vm.salvarLinha(l));
  }

  /// Escolhe manualmente a baixa que corresponde à linha.
  Future<void> _conciliarManual(LinhaExtrato linha) async {
    final candidatos = _vm.candidatos
        .where((l) => (l.baixaComSinal - linha.valor).abs() <= 0.005)
        .toList();
    final escolhido = await showDialog<Lancamento>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.navy,
        title: Text('Conciliar ${formatMoney(linha.valor)}'),
        children: [
          if (candidatos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhuma conta baixada nesta conta bancária com o mesmo valor.\n'
                'Dê baixa na conta em "Contas" informando esta conta bancária.',
              ),
            ),
          for (final l in candidatos)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l),
              child: Text(
                '${formatDate(l.dataBaixa)} • ${l.descricao} • ${formatMoney(l.valorBaixa)}',
              ),
            ),
        ],
      ),
    );
    if (escolhido != null) {
      await _acao(() => _vm.conciliar(linha, escolhido), 'Linha conciliada.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        if (!_vm.carregado) return const SizedBox.shrink();
        final conta = _vm.conta;
        if (conta == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EmptyState(
                  icon: Icons.account_balance_outlined,
                  message:
                      'Cadastre uma conta bancária para conciliar o extrato.',
                ),
                FilledButton.icon(
                  onPressed: _novaConta,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova conta bancária'),
                ),
              ],
            ),
          );
        }
        final saldos = _vm.saldos!;
        final sugestoes = _vm.sugestoes;
        final linhas = _vm.linhas;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: AppDropdown<String>(
                    label: 'Conta bancária',
                    value: conta.id,
                    items: _vm.contas.map((c) => c.id).toList(),
                    labelOf: (id) =>
                        _vm.contas.firstWhere((c) => c.id == id).descricao,
                    onChanged: _vm.selecionarConta,
                  ),
                ),
                IconButton(
                  tooltip: 'Editar conta',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _novaConta(true),
                ),
                IconButton(
                  tooltip: 'Nova conta bancária',
                  icon: Icon(Icons.add_circle_outline, color: AppColors.gold),
                  onPressed: _novaConta,
                ),
                IconButton(
                  tooltip: 'Excluir conta',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirmDelete(
                      context,
                      'Excluir a conta "${conta.nome}"?',
                    )) {
                      await _acao(() => _vm.removerConta(conta.id));
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            ResumoValores(
              itens: [
                (
                  rotulo: 'Saldo contábil',
                  valor: formatMoney(saldos.contabil),
                  cor: AppColors.gold,
                ),
                (
                  rotulo: 'Saldo do extrato',
                  valor: formatMoney(saldos.extrato),
                  cor: AppColors.blueGlow,
                ),
                (
                  rotulo: 'Diferença',
                  valor: formatMoney(saldos.diferenca),
                  cor: saldos.diferenca == 0
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Contábil: saldo inicial + baixas desta conta. Extrato: saldo inicial + linhas lançadas. '
              'A diferença some quando todas as linhas estão conciliadas.',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _novaLinha,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Lançar linha do extrato'),
                ),
                OutlinedButton.icon(
                  onPressed: sugestoes.isEmpty ? null : _conciliarAuto,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(
                    'Conciliar automaticamente (${sugestoes.length})',
                  ),
                ),
                const Tooltip(
                  message:
                      'A importação de OFX/CSV será ligada na integração com o banco.',
                  child: OutlinedButton(
                    onPressed: null,
                    child: Text('Importar extrato (em breve)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Extrato • ${_vm.pendentes} pendente(s)',
              style: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (linhas.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                message: 'Nenhuma linha de extrato lançada para esta conta.',
              ),
            for (final l in linhas) _linha(l, sugestoes[l.id]),
          ],
        );
      },
    );
  }

  Widget _linha(LinhaExtrato l, Lancamento? sugestao) {
    final conciliado = _vm.lancamento(l.lancamentoId);
    final cor = l.conciliada ? Colors.greenAccent : AppColors.gold;
    return CardPadrao(
      borda: cor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      formatDate(l.data),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    GoldChip(
                      l.conciliada ? 'Conciliada' : 'Pendente',
                      color: cor,
                    ),
                  ],
                ),
                Text(
                  l.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (conciliado != null)
                  Text(
                    '↔ ${conciliado.descricao}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                    ),
                  )
                else if (sugestao != null)
                  Text(
                    'Sugestão: ${sugestao.descricao} (${formatDate(sugestao.dataBaixa)})',
                    style: TextStyle(color: AppColors.goldLight, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            formatMoney(l.valor),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: l.valor >= 0 ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.navy,
            onSelected: (v) => switch (v) {
              'sugestao' => _acao(
                () => _vm.conciliar(l, sugestao!),
                'Linha conciliada.',
              ),
              'manual' => _conciliarManual(l),
              'desfazer' => _acao(() => _vm.desfazer(l)),
              _ => _acao(() => _vm.removerLinha(l.id)),
            },
            itemBuilder: (_) => [
              if (!l.conciliada && sugestao != null)
                const PopupMenuItem(
                  value: 'sugestao',
                  child: Text('Aceitar sugestão'),
                ),
              if (!l.conciliada)
                const PopupMenuItem(
                  value: 'manual',
                  child: Text('Conciliar com uma baixa...'),
                ),
              if (l.conciliada)
                const PopupMenuItem(
                  value: 'desfazer',
                  child: Text('Desfazer conciliação'),
                ),
              if (!l.conciliada)
                const PopupMenuItem(value: 'del', child: Text('Excluir linha')),
            ],
          ),
        ],
      ),
    );
  }
}
