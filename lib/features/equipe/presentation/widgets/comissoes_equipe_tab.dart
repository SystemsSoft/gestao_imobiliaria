import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/comissao_equipe.dart';
import '../../domain/entities/equipe_enums.dart';
import '../viewmodels/comissoes_equipe_viewmodel.dart';
import 'avatar_usuario.dart';

/// Gestão de comissões de corretagem da equipe.
class ComissoesEquipeTab extends StatefulWidget {
  const ComissoesEquipeTab({super.key});

  @override
  State<ComissoesEquipeTab> createState() => _ComissoesEquipeTabState();
}

class _ComissoesEquipeTabState extends State<ComissoesEquipeTab> {
  final _vm = sl<ComissoesEquipeViewModel>();

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

  Future<void> _novo() async {
    if (_vm.corretores.isEmpty) {
      mostrarMensagem(
        context,
        'Cadastre usuários na aba "Usuários e sessões" primeiro.',
      );
      return;
    }
    final l = await showDialog<LancamentoComissao>(
      context: context,
      builder: (_) => _LancamentoDialog(vm: _vm),
    );
    if (l != null) {
      await _acao(() => _vm.salvarLancamento(l), 'Comissão lançada.');
    }
  }

  Future<void> _regras(String usuarioId) async {
    final r = await showDialog<RegraComissao>(
      context: context,
      builder: (_) =>
          _RegraDialog(regra: _vm.regra(usuarioId), nome: _vm.nome(usuarioId)),
    );
    if (r != null) await _acao(() => _vm.salvarRegra(r), 'Regras salvas.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.add_card,
        label: 'Nova comissão',
        onPressed: _novo,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.lancamentos;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              CompetenciaSelector(value: _vm.mes, onChanged: _vm.mudarMes),
              if (!_vm.veTodos)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Você vê apenas as suas comissões (sem a permissão "Ver comissões de todos").',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              ResumoValores(
                itens: [
                  (
                    rotulo: 'A aprovar',
                    valor: formatMoney(_vm.totalAprovar),
                    cor: Colors.orangeAccent,
                  ),
                  (
                    rotulo: 'A pagar',
                    valor: formatMoney(_vm.totalPagar),
                    cor: AppColors.gold,
                  ),
                  (
                    rotulo: 'Pago',
                    valor: formatMoney(_vm.totalPago),
                    cor: Colors.greenAccent,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ranking(),
              const SizedBox(height: 8),
              if (_vm.veTodos)
                SizedBox(
                  width: 300,
                  child: AppDropdown<String?>(
                    label: 'Corretor',
                    value: _vm.corretorId,
                    items: [null, ..._vm.corretores.map((u) => u.id)],
                    labelOf: (id) => id == null ? 'Todos' : _vm.nome(id),
                    onChanged: _vm.filtrarCorretor,
                  ),
                ),
              FiltroChips<StatusComissao>(
                opcoes: StatusComissao.values,
                selecionado: _vm.status,
                labelOf: (s) => s.label,
                onChanged: _vm.filtrarStatus,
                padding: EdgeInsets.zero,
              ),
              if (_vm.carregado && lista.isEmpty)
                const EmptyState(
                  icon: Icons.percent,
                  message:
                      'Nenhuma comissão neste mês.\nUse "Nova comissão" para lançar.',
                ),
              for (final l in lista) _card(l),
            ],
          );
        },
      ),
    );
  }

  Widget _ranking() {
    final r = _vm.ranking;
    if (r.isEmpty) return const SizedBox.shrink();
    return FormSection(
      title: 'Desempenho do mês',
      icon: Icons.emoji_events_outlined,
      children: [
        for (var i = 0; i < r.length; i++)
          Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '${i + 1}º',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AvatarUsuario(nome: _vm.nome(r[i].usuarioId), raio: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_vm.nome(r[i].usuarioId)} • ${formatMoney(r[i].total)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (r[i].meta > 0) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: r[i].progressoMeta.clamp(0, 1),
                          minHeight: 6,
                          color: r[i].progressoMeta >= 1
                              ? Colors.greenAccent
                              : AppColors.gold,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      Text(
                        '${(r[i].progressoMeta * 100).round()}% da meta de ${formatMoney(r[i].meta)}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_vm.veTodos)
                IconButton(
                  tooltip: 'Regras de comissão',
                  icon: const Icon(Icons.tune),
                  onPressed: () => _regras(r[i].usuarioId),
                ),
            ],
          ),
        if (_vm.veTodos)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              const Text(
                'Regras de:',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              for (final u in _vm.corretores)
                ActionChip(
                  label: Text(u.nome, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _regras(u.id),
                ),
            ],
          ),
      ],
    );
  }

  Widget _card(LancamentoComissao l) {
    final (cor) = switch (l.status) {
      StatusComissao.pendente => Colors.orangeAccent,
      StatusComissao.aprovada => AppColors.gold,
      StatusComissao.paga => Colors.greenAccent,
      StatusComissao.cancelada => Colors.grey,
    };
    return CardPadrao(
      borda: cor,
      child: Row(
        children: [
          AvatarUsuario(nome: _vm.nome(l.usuarioId), raio: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _vm.nome(l.usuarioId),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GoldChip(l.status.label, color: cor),
                  ],
                ),
                Text(
                  '${l.tipo.label}${l.referencia.isEmpty ? '' : ' • ${l.referencia}'}'
                  '${l.tipo.porPercentual ? ' • ${formatMoney(l.baseValor)} × ${decimalToText(l.percentual)}%' : ''}'
                  '${l.dataPagamento == null ? '' : ' • paga em ${formatDate(l.dataPagamento)}'}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (l.observacao.isNotEmpty)
                  Text(
                    l.observacao,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
          Text(
            formatMoney(l.valor),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: l.valor < 0 ? Colors.redAccent : AppColors.goldLight,
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.navy,
            onSelected: (v) => switch (v) {
              'aprovar' => _acao(() => _vm.aprovar(l), 'Comissão aprovada.'),
              'pagar' => _acao(() => _vm.pagar(l), 'Comissão paga.'),
              'estornar' => _acao(
                () => _vm.estornar(l),
                'Pagamento estornado.',
              ),
              'cancelar' => _acao(() => _vm.cancelar(l), 'Comissão cancelada.'),
              'reabrir' => _acao(() => _vm.reabrir(l), 'Comissão reaberta.'),
              _ => () async {
                if (await confirmDelete(context, 'Excluir esta comissão?')) {
                  await _acao(() => _vm.remover(l));
                }
              }(),
            },
            itemBuilder: (_) => [
              if (l.status == StatusComissao.pendente)
                const PopupMenuItem(value: 'aprovar', child: Text('Aprovar')),
              if (l.status == StatusComissao.aprovada)
                const PopupMenuItem(
                  value: 'pagar',
                  child: Text('Marcar como paga'),
                ),
              if (l.status == StatusComissao.paga)
                const PopupMenuItem(
                  value: 'estornar',
                  child: Text('Estornar pagamento'),
                ),
              if (l.status == StatusComissao.pendente ||
                  l.status == StatusComissao.aprovada)
                const PopupMenuItem(value: 'cancelar', child: Text('Cancelar')),
              if (l.status == StatusComissao.cancelada)
                const PopupMenuItem(value: 'reabrir', child: Text('Reabrir')),
              if (l.status != StatusComissao.paga)
                const PopupMenuItem(value: 'del', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}

class _LancamentoDialog extends StatefulWidget {
  const _LancamentoDialog({required this.vm});

  final ComissoesEquipeViewModel vm;

  @override
  State<_LancamentoDialog> createState() => _LancamentoDialogState();
}

class _LancamentoDialogState extends State<_LancamentoDialog> {
  late String? _corretor = widget.vm.corretores.length == 1
      ? widget.vm.corretores.first.id
      : null;
  TipoComissao _tipo = TipoComissao.venda;
  late DateTime _mes = widget.vm.mes;
  final _referencia = TextEditingController();
  final _base = TextEditingController();
  final _percentual = TextEditingController();
  final _valor = TextEditingController();
  final _obs = TextEditingController();
  bool _desconto = false;

  @override
  void initState() {
    super.initState();
    _sugerirPercentual();
  }

  @override
  void dispose() {
    for (final c in [_referencia, _base, _percentual, _valor, _obs]) {
      c.dispose();
    }
    super.dispose();
  }

  void _sugerirPercentual() {
    if (_corretor == null || !_tipo.porPercentual) return;
    _percentual.text = decimalToText(
      widget.vm.regra(_corretor!).percentualDe(_tipo),
    );
  }

  double get _calculado =>
      (parseMoney(_base.text) ?? 0) *
      (parseDecimal(_percentual.text) ?? 0) /
      100;

  LancamentoComissao _montar() => LancamentoComissao(
    id: gerarId(),
    usuarioId: _corretor ?? '',
    tipo: _tipo,
    competencia: _mes,
    valor: _tipo.porPercentual
        ? 0
        : (_desconto ? -1 : 1) * (parseMoney(_valor.text) ?? 0),
    referencia: _referencia.text.trim(),
    baseValor: _tipo.porPercentual ? parseMoney(_base.text) ?? 0 : 0,
    percentual: _tipo.porPercentual ? parseDecimal(_percentual.text) ?? 0 : 0,
    observacao: _obs.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Nova comissão'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              AppDropdown<String>(
                label: 'Corretor *',
                value: _corretor,
                items: vm.corretores.map((u) => u.id).toList(),
                labelOf: vm.nome,
                onChanged: (v) => setState(() {
                  _corretor = v;
                  _sugerirPercentual();
                }),
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppDropdown<TipoComissao>(
                    label: 'Tipo',
                    value: _tipo,
                    items: TipoComissao.values,
                    labelOf: (t) => t.label,
                    onChanged: (v) => setState(() {
                      _tipo = v ?? _tipo;
                      _sugerirPercentual();
                    }),
                  ),
                  AppTextField(
                    label: 'Referência',
                    hint: 'Ex.: VEN-0001',
                    controller: _referencia,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: CompetenciaSelector(
                  value: _mes,
                  onChanged: (m) => setState(() => _mes = m),
                ),
              ),
              const SizedBox(height: 12),
              if (_tipo.porPercentual) ...[
                FieldRow(
                  children: [
                    AppTextField(
                      label: 'Comissão da imobiliária (base)',
                      controller: _base,
                      prefixText: r'R$ ',
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      onChanged: (_) => setState(() {}),
                    ),
                    AppTextField.decimal(
                      label: 'Percentual do corretor',
                      controller: _percentual,
                      suffixText: '%',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Comissão do corretor: ${formatMoney(_calculado)}',
                  style: TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ] else ...[
                AppTextField.money(label: 'Valor', controller: _valor),
                if (_tipo == TipoComissao.ajuste)
                  AppSwitch(
                    label: 'Desconto (valor negativo)',
                    value: _desconto,
                    onChanged: (v) => setState(() => _desconto = v),
                  ),
              ],
              const SizedBox(height: 12),
              AppTextField(label: 'Observações', controller: _obs, maxLines: 2),
            ],
          ),
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
          onPressed: () => Navigator.pop(context, _montar()),
          child: const Text('Lançar'),
        ),
      ],
    );
  }
}

class _RegraDialog extends StatefulWidget {
  const _RegraDialog({required this.regra, required this.nome});

  final RegraComissao regra;
  final String nome;

  @override
  State<_RegraDialog> createState() => _RegraDialogState();
}

class _RegraDialogState extends State<_RegraDialog> {
  late final _venda = TextEditingController(
    text: decimalToText(widget.regra.percentualVenda),
  );
  late final _locacao = TextEditingController(
    text: decimalToText(widget.regra.percentualLocacao),
  );
  late final _captacao = TextEditingController(
    text: decimalToText(widget.regra.percentualCaptacao),
  );
  late final _meta = TextEditingController(
    text: moneyToText(widget.regra.metaMensal),
  );

  @override
  void dispose() {
    for (final c in [_venda, _locacao, _captacao, _meta]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text('Regras de ${widget.nome}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Percentual da comissão da imobiliária que cabe ao corretor, por tipo de negócio.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppTextField.decimal(
                    label: 'Venda',
                    controller: _venda,
                    suffixText: '%',
                  ),
                  AppTextField.decimal(
                    label: 'Locação',
                    controller: _locacao,
                    suffixText: '%',
                  ),
                  AppTextField.decimal(
                    label: 'Captação',
                    controller: _captacao,
                    suffixText: '%',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField.money(
                label: 'Meta mensal de comissões',
                controller: _meta,
              ),
            ],
          ),
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
          onPressed: () => Navigator.pop(
            context,
            RegraComissao(
              usuarioId: widget.regra.usuarioId,
              percentualVenda: parseDecimal(_venda.text) ?? 0,
              percentualLocacao: parseDecimal(_locacao.text) ?? 0,
              percentualCaptacao: parseDecimal(_captacao.text) ?? 0,
              metaMensal: parseMoney(_meta.text) ?? 0,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
