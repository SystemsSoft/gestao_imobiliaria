import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/manutencao.dart';
import '../viewmodels/manutencoes_viewmodel.dart';
import 'manutencao_widgets.dart';

Widget _acoes(BuildContext context, VoidCallback onSalvar) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancelar'),
    ),
    const SizedBox(width: 8),
    FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navyDark,
      ),
      onPressed: onSalvar,
      child: const Text('Salvar'),
    ),
  ],
);

/// Inclusão/edição de um item da pauta de manutenção.
class ManutencaoDialog extends StatefulWidget {
  const ManutencaoDialog({super.key, required this.vm, this.manutencao});

  final ManutencoesViewModel vm;
  final Manutencao? manutencao;

  @override
  State<ManutencaoDialog> createState() => _ManutencaoDialogState();
}

class _ManutencaoDialogState extends State<ManutencaoDialog> {
  Manutencao? get _m => widget.manutencao;
  late String? _imovelId = _m?.imovelId ?? widget.vm.imovelId;
  late TipoManutencao _tipo = _m?.tipo ?? TipoManutencao.eletrica;
  late final _outro = TextEditingController(text: _m?.tipoOutro);
  late final _descricao = TextEditingController(text: _m?.descricao);
  late StatusManutencao _status = _m?.status ?? StatusManutencao.pendente;
  late DateTime? _prevista = _m?.dataPrevista;

  @override
  void dispose() {
    _outro.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final ok = await widget.vm.salvar(
      Manutencao(
        id: _m?.id ?? gerarId(),
        contexto: widget.vm.contexto,
        imovelId: _imovelId ?? '',
        tipo: _tipo,
        tipoOutro: _tipo == TipoManutencao.outros ? _outro.text.trim() : '',
        descricao: _descricao.text.trim(),
        status: _status,
        dataPrevista: _prevista,
        criadaEm: _m?.criadaEm ?? DateTime.now(),
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
    final imoveis = vm.imoveis;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(_m == null ? 'Nova manutenção' : 'Editar manutenção'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              AppDropdown<String>(
                label: 'Qual imóvel *',
                value: imoveis.any((i) => i.id == _imovelId) ? _imovelId : null,
                items: imoveis.map((i) => i.id).toList(),
                labelOf: vm.descricaoImovel,
                onChanged: (v) => setState(() => _imovelId = v),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tipo de manutenção',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in TipoManutencao.values)
                    ChoiceChip(
                      avatar: Icon(
                        iconeTipo(t),
                        size: 18,
                        color: _tipo == t ? AppColors.navyDark : AppColors.gold,
                      ),
                      label: Text(t.label),
                      selected: _tipo == t,
                      showCheckmark: false,
                      selectedColor: AppColors.gold,
                      labelStyle: TextStyle(
                        color: _tipo == t ? AppColors.navyDark : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setState(() => _tipo = t),
                    ),
                ],
              ),
              if (_tipo == TipoManutencao.outros) ...[
                const SizedBox(height: 12),
                AppTextField(label: 'Qual? *', controller: _outro),
              ],
              const SizedBox(height: 12),
              AppTextField(
                label: 'O que precisa ser feito *',
                controller: _descricao,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  DateField(
                    label: 'Data prevista',
                    value: _prevista,
                    onChanged: (d) => setState(() => _prevista = d),
                  ),
                  AppDropdown<StatusManutencao>(
                    label: 'Situação',
                    value: _status,
                    items: StatusManutencao.values,
                    labelOf: (s) => s.label,
                    onChanged: (s) => setState(() => _status = s ?? _status),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [_acoes(context, _salvar)],
    );
  }
}

/// Lançamento no diário da manutenção, com os totais calculados na hora.
class RegistroDiarioDialog extends StatefulWidget {
  const RegistroDiarioDialog({
    super.key,
    required this.vm,
    required this.manutencaoId,
    this.registro,
  });

  final ManutencoesViewModel vm;
  final String manutencaoId;
  final RegistroDiario? registro;

  @override
  State<RegistroDiarioDialog> createState() => _RegistroDiarioDialogState();
}

class _RegistroDiarioDialogState extends State<RegistroDiarioDialog> {
  RegistroDiario? get _r => widget.registro;
  late DateTime? _data = _r?.data ?? DateTime.now();
  late final _profissional = TextEditingController(text: _r?.profissional);
  late final _servico = TextEditingController(text: _r?.servico);
  late final _material = TextEditingController(text: _r?.material);
  late final _valorMaterial = TextEditingController(
    text: moneyToText(_r?.valorMaterial),
  );
  late final _maoDeObra = TextEditingController(
    text: moneyToText(_r?.valorMaoDeObra),
  );
  // Sugere a mesma taxa do último registro desta manutenção.
  late final _taxa = TextEditingController(
    text: moneyToText(_r?.valorTaxa ?? _ultimaTaxa),
  );

  double? get _ultimaTaxa {
    final diario = widget.vm.porId(widget.manutencaoId)?.diarioOrdenado;
    return diario == null || diario.isEmpty ? null : diario.first.valorTaxa;
  }

  @override
  void initState() {
    super.initState();
    for (final c in [_valorMaterial, _maoDeObra, _taxa]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _profissional,
      _servico,
      _material,
      _valorMaterial,
      _maoDeObra,
      _taxa,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  RegistroDiario get _registro => RegistroDiario(
    id: _r?.id ?? gerarId(),
    data: _data ?? DateTime.now(),
    profissional: _profissional.text.trim(),
    servico: _servico.text.trim(),
    material: _material.text.trim(),
    valorMaterial: parseMoney(_valorMaterial.text) ?? 0,
    valorMaoDeObra: parseMoney(_maoDeObra.text) ?? 0,
    valorTaxa: parseMoney(_taxa.text) ?? 0,
  );

  Future<void> _salvar() async {
    final ok = await widget.vm.registrar(widget.manutencaoId, _registro);
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
    final r = _registro;
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text(_r == null ? 'Registrar no diário' : 'Editar registro'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 4),
              FieldRow(
                flex: const [2, 3],
                children: [
                  DateField(
                    label: 'Data *',
                    value: _data,
                    onChanged: (d) => setState(() => _data = d),
                  ),
                  AppTextField(
                    label: 'Profissional *',
                    controller: _profissional,
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Serviço a ser executado *',
                controller: _servico,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              FieldRow(
                flex: const [3, 2],
                children: [
                  AppTextField(
                    label: 'Material',
                    hint: 'Ex.: 2 latas de tinta, fios 2,5mm...',
                    controller: _material,
                  ),
                  AppTextField.money(
                    label: 'Valor do material',
                    controller: _valorMaterial,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FieldRow(
                children: [
                  AppTextField.money(
                    label: 'Mão de obra',
                    controller: _maoDeObra,
                  ),
                  AppTextField.money(
                    label: 'Taxa de manutenção',
                    controller: _taxa,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ResumoValores(
                itens: [
                  (
                    rotulo: 'Valor total dos serviços',
                    valor: formatMoney(r.valorServicos),
                    cor: Colors.white,
                  ),
                  (
                    rotulo: 'Taxa de manutenção',
                    valor: formatMoney(r.valorTaxa),
                    cor: AppColors.goldLight,
                  ),
                  (
                    rotulo: 'Total',
                    valor: formatMoney(r.valorTotal),
                    cor: AppColors.gold,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [_acoes(context, _salvar)],
    );
  }
}
