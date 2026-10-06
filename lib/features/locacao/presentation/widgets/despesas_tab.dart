import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/despesa.dart';
import '../../domain/entities/locacao_enums.dart';
import '../viewmodels/despesas_viewmodel.dart';

/// Controle de despesas fixas e extraordinárias dos contratos.
class DespesasTab extends StatefulWidget {
  const DespesasTab({super.key});

  @override
  State<DespesasTab> createState() => _DespesasTabState();
}

class _DespesasTabState extends State<DespesasTab> {
  final _vm = sl<DespesasViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrir([Despesa? d]) {
    if (_vm.contratos.isEmpty) {
      mostrarMensagem(context, 'Cadastre um contrato de locação primeiro.');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _DespesaDialog(vm: _vm, despesa: d),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.add_card,
        label: 'Nova despesa',
        onPressed: _abrir,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.filtradas;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              const Text(
                'Despesas do locatário entram no boleto; as do proprietário são '
                'descontadas no repasse. Fixas repetem todo mês; extraordinárias '
                'incidem só na competência informada.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              AppDropdown<String?>(
                label: 'Contrato',
                value: _vm.contratoId,
                items: [null, ..._vm.contratos.map((c) => c.id)],
                labelOf: (id) => id == null
                    ? 'Todos os contratos'
                    : _vm.descricaoContrato(id),
                onChanged: _vm.filtrarContrato,
              ),
              FiltroChips<NaturezaDespesa>(
                opcoes: NaturezaDespesa.values,
                selecionado: _vm.natureza,
                labelOf: (n) => n.label,
                onChanged: _vm.filtrarNatureza,
                padding: const EdgeInsets.only(top: 8),
              ),
              if (_vm.carregado && lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: EmptyState(
                    icon: Icons.payments_outlined,
                    message: 'Nenhuma despesa lançada.',
                  ),
                ),
              for (final d in lista) _card(d),
            ],
          );
        },
      ),
    );
  }

  Widget _card(Despesa d) {
    final periodo = d.natureza == NaturezaDespesa.extraordinaria
        ? 'Competência ${competenciaLabel(d.competenciaInicio)}'
        : 'A partir de ${competenciaLabel(d.competenciaInicio)}'
              '${d.competenciaFim == null ? '' : ' até ${competenciaLabel(d.competenciaFim!)}'}';
    return CardPadrao(
      onTap: () => _abrir(d),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.descricao,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _vm.descricaoContrato(d.contratoId),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    GoldChip(d.natureza.label),
                    GoldChip(
                      '${d.responsavel.label} • ${d.responsavel.efeito}',
                      color: d.responsavel == ResponsavelDespesa.locatario
                          ? AppColors.blueGlow
                          : Colors.orangeAccent,
                    ),
                    if (d.dedutivelIR)
                      const GoldChip(
                        'Dedutível no IR',
                        color: Colors.greenAccent,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  periodo,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(d.valor),
            style: const TextStyle(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirmDelete(context, 'Excluir "${d.descricao}"?')) {
                await _vm.remover(d.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DespesaDialog extends StatefulWidget {
  const _DespesaDialog({required this.vm, this.despesa});

  final DespesasViewModel vm;
  final Despesa? despesa;

  @override
  State<_DespesaDialog> createState() => _DespesaDialogState();
}

class _DespesaDialogState extends State<_DespesaDialog> {
  Despesa? get _d => widget.despesa;
  late String? _contratoId = _d?.contratoId ?? widget.vm.contratoId;
  late final _descricao = TextEditingController(text: _d?.descricao);
  late final _valor = TextEditingController(text: moneyToText(_d?.valor));
  late NaturezaDespesa _natureza = _d?.natureza ?? NaturezaDespesa.fixa;
  late ResponsavelDespesa _responsavel =
      _d?.responsavel ?? ResponsavelDespesa.locatario;
  late DateTime _inicio =
      _d?.competenciaInicio ?? competenciaDe(DateTime.now());
  late DateTime? _fim = _d?.competenciaFim;
  late bool _dedutivel = _d?.dedutivelIR ?? false;

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  void _sugerir(String s) {
    setState(() {
      _descricao.text = s;
      if (s == 'IPTU' || s == 'Condomínio') _dedutivel = true;
      if (s == 'Fundo de reserva' || s == 'Obras estruturais') {
        _responsavel = ResponsavelDespesa.proprietario;
      }
    });
  }

  Future<void> _salvar() async {
    final ok = await widget.vm.salvar(
      Despesa(
        id: _d?.id ?? gerarId(),
        contratoId: _contratoId ?? '',
        descricao: _descricao.text.trim(),
        valor: parseMoney(_valor.text) ?? 0,
        natureza: _natureza,
        responsavel: _responsavel,
        competenciaInicio: _inicio,
        competenciaFim: _natureza == NaturezaDespesa.fixa ? _fim : null,
        dedutivelIR:
            _responsavel == ResponsavelDespesa.proprietario && _dedutivel,
      ),
    );
    if (!mounted) return;
    if (!ok) {
      return mostrarMensagem(
        context,
        widget.vm.erro ?? 'Não foi possível salvar.',
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(_d == null ? 'Nova despesa' : 'Editar despesa'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              AppDropdown<String>(
                label: 'Contrato *',
                value: vm.contratos.any((c) => c.id == _contratoId)
                    ? _contratoId
                    : null,
                items: vm.contratos.map((c) => c.id).toList(),
                labelOf: vm.descricaoContrato,
                onChanged: (v) => setState(() => _contratoId = v),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Descrição *', controller: _descricao),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in despesasSugeridas)
                    ActionChip(label: Text(s), onPressed: () => _sugerir(s)),
                ],
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppDropdown<NaturezaDespesa>(
                    label: 'Natureza',
                    value: _natureza,
                    items: NaturezaDespesa.values,
                    labelOf: (e) => e.label,
                    onChanged: (v) =>
                        setState(() => _natureza = v ?? _natureza),
                  ),
                  AppTextField.money(label: 'Valor *', controller: _valor),
                ],
              ),
              const SizedBox(height: 12),
              AppDropdown<ResponsavelDespesa>(
                label: 'Quem paga',
                value: _responsavel,
                items: ResponsavelDespesa.values,
                labelOf: (e) => '${e.label} (${e.efeito})',
                onChanged: (v) =>
                    setState(() => _responsavel = v ?? _responsavel),
              ),
              const SizedBox(height: 12),
              Text(
                _natureza == NaturezaDespesa.fixa
                    ? 'A partir de'
                    : 'Competência',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: CompetenciaSelector(
                  value: _inicio,
                  onChanged: (c) => setState(() => _inicio = c),
                ),
              ),
              if (_natureza == NaturezaDespesa.fixa) ...[
                AppSwitch(
                  label: 'Tem data de término',
                  value: _fim != null,
                  onChanged: (v) => setState(() => _fim = v ? _inicio : null),
                ),
                if (_fim != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CompetenciaSelector(
                      value: _fim!,
                      onChanged: (c) => setState(() => _fim = c),
                    ),
                  ),
              ],
              if (_responsavel == ResponsavelDespesa.proprietario)
                AppSwitch(
                  label:
                      'Dedutível da base do Imposto de Renda (IPTU, condomínio...)',
                  value: _dedutivel,
                  onChanged: (v) => setState(() => _dedutivel = v),
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
          onPressed: _salvar,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
