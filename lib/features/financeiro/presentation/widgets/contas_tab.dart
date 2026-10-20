import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/lancamento.dart';
import '../viewmodels/contas_viewmodel.dart';
import 'baixa_dialog.dart';
import 'lancamento_form_dialog.dart';

/// Contas a pagar e a receber.
class ContasTab extends StatefulWidget {
  const ContasTab({super.key});

  @override
  State<ContasTab> createState() => _ContasTabState();
}

class _ContasTabState extends State<ContasTab> {
  final _vm = sl<ContasViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrir([Lancamento? l]) =>
      mostrarLancamentoFormDialog(context, lancamento: l, tipo: _vm.tipo);

  Future<void> _acao(Future<bool> Function() f, [String? sucesso]) async {
    final ok = await f();
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível concluir.');
    } else if (sucesso != null) {
      mostrarMensagem(context, sucesso);
    }
  }

  Future<void> _baixar(Lancamento l) async {
    final r = await mostrarBaixaDialog(
      context,
      lancamento: l,
      contas: _vm.contas,
      hoje: _vm.hoje,
      simular: (d) => _vm.simular(l, d),
    );
    if (r != null) {
      await _acao(
        () => _vm.baixar(l, r.data, r.valor, r.meio, r.contaId),
        'Baixa registrada.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => goldFab(
          icon: Icons.add_card,
          label: _vm.tipo == TipoLancamento.receber
              ? 'Nova conta a receber'
              : 'Nova conta a pagar',
          onPressed: _abrir,
        ),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.filtradas;
          final receber = _vm.tipo == TipoLancamento.receber;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              SegmentedButton<TipoLancamento>(
                segments: const [
                  ButtonSegment(
                    value: TipoLancamento.receber,
                    icon: Icon(Icons.south_west),
                    label: Text('A receber'),
                  ),
                  ButtonSegment(
                    value: TipoLancamento.pagar,
                    icon: Icon(Icons.north_east),
                    label: Text('A pagar'),
                  ),
                ],
                selected: {_vm.tipo},
                onSelectionChanged: (s) => _vm.mudarTipo(s.first),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!_vm.todosMeses)
                    CompetenciaSelector(
                      value: _vm.mes,
                      onChanged: _vm.mudarMes,
                    ),
                  FilterChip(
                    label: const Text('Todos os meses'),
                    selected: _vm.todosMeses,
                    selectedColor: AppColors.gold,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: _vm.todosMeses ? AppColors.navyDark : Colors.white,
                    ),
                    onSelected: _vm.alternarTodosMeses,
                  ),
                  if (_vm.totalVencido > 0)
                    Text(
                      'Vencido (todos os meses): ${formatMoney(_vm.totalVencido)}',
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
                    rotulo: 'Total',
                    valor: formatMoney(_vm.total),
                    cor: AppColors.gold,
                  ),
                  (
                    rotulo: receber ? 'Recebido' : 'Pago',
                    valor: formatMoney(_vm.baixado),
                    cor: Colors.greenAccent,
                  ),
                  (
                    rotulo: 'Em aberto',
                    valor: formatMoney(_vm.emAberto),
                    cor: Colors.orangeAccent,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: _vm.buscar,
                decoration: const InputDecoration(
                  hintText: 'Buscar por descrição, categoria ou nome...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final f in FiltroConta.values)
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 8,
                          top: 6,
                          bottom: 6,
                        ),
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
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: _vm.semCadastro
                        ? 'Nenhuma conta lançada.\nUse o botão abaixo para criar contas a pagar e a receber.'
                        : 'Nenhuma conta neste período e filtro.',
                  ),
                ),
              for (final l in lista) _card(l),
            ],
          );
        },
      ),
    );
  }

  Widget _card(Lancamento l) {
    final vencido = l.vencido(_vm.hoje);
    final (rotulo, cor) = switch (l.status) {
      StatusLancamento.baixado => (l.tipo.baixadoLabel, Colors.greenAccent),
      StatusLancamento.cancelado => ('Cancelado', Colors.grey),
      StatusLancamento.aberto when vencido => ('Vencido', Colors.redAccent),
      StatusLancamento.aberto => ('Em aberto', Colors.orangeAccent),
    };
    final contato = _vm.nomeContato(l.contatoId);
    return CardPadrao(
      borda: cor,
      onTap: () => _abrir(l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l.descricao}${l.rotuloParcela.isEmpty ? '' : ' (${l.rotuloParcela})'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GoldChip(rotulo, color: cor),
                  ],
                ),
                Text(
                  [
                    if (l.categoria.isNotEmpty) l.categoria,
                    ?contato,
                    if (l.documento.isNotEmpty) 'Doc. ${l.documento}',
                  ].join(' • '),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  l.baixado
                      ? '${l.tipo.baixadoLabel} ${formatMoney(l.valorBaixa)} em ${formatDate(l.dataBaixa)}'
                            '${l.multa + l.juros + l.correcao > 0 ? ' (inclui ${formatMoney(l.multa + l.juros + l.correcao)} de encargos)' : ''}'
                      : 'Vence em ${formatDate(l.vencimento)} • ${formatMoney(l.valor)}',
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
              'baixar' => _baixar(l),
              'edit' => _abrir(l),
              'estornar' => _acao(() => _vm.estornar(l), 'Baixa estornada.'),
              'cancelar' => _acao(() => _vm.cancelar(l), 'Conta cancelada.'),
              _ => () async {
                if (await confirmDelete(context, 'Excluir "${l.descricao}"?')) {
                  await _acao(() => _vm.remover(l));
                }
              }(),
            },
            itemBuilder: (_) => [
              if (l.emAberto)
                PopupMenuItem(
                  value: 'baixar',
                  child: Text(
                    l.tipo == TipoLancamento.receber ? 'Receber' : 'Pagar',
                  ),
                ),
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              if (l.baixado)
                const PopupMenuItem(
                  value: 'estornar',
                  child: Text('Estornar baixa'),
                ),
              if (l.emAberto)
                const PopupMenuItem(
                  value: 'cancelar',
                  child: Text('Cancelar conta'),
                ),
              const PopupMenuItem(value: 'del', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
