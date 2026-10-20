import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/lancamento.dart';
import '../viewmodels/lancamento_form_viewmodel.dart';

/// Cadastro e edição de conta a pagar ou a receber, em modal.
Future<void> mostrarLancamentoFormDialog(
  BuildContext context, {
  Lancamento? lancamento,
  TipoLancamento tipo = TipoLancamento.receber,
}) => showDialog<void>(
  context: context,
  builder: (_) => LancamentoFormDialog(lancamento: lancamento, tipo: tipo),
);

class LancamentoFormDialog extends StatefulWidget {
  const LancamentoFormDialog({
    super.key,
    this.lancamento,
    this.tipo = TipoLancamento.receber,
  });

  final Lancamento? lancamento;

  /// Tipo usado em uma nova conta.
  final TipoLancamento tipo;

  @override
  State<LancamentoFormDialog> createState() => _LancamentoFormDialogState();
}

class _LancamentoFormDialogState extends State<LancamentoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vm = sl<LancamentoFormViewModel>();
  Lancamento? get _l => widget.lancamento;
  bool get _novo => _l == null;

  late TipoLancamento _tipo = _l?.tipo ?? widget.tipo;
  late final _descricao = TextEditingController(text: _l?.descricao);
  late final _documento = TextEditingController(text: _l?.documento);
  late final _observacoes = TextEditingController(text: _l?.observacoes);
  late final _valor = TextEditingController(text: moneyToText(_l?.valor));
  late final _multa = TextEditingController(
    text: decimalToText(_l?.multaPercentual),
  );
  late final _juros = TextEditingController(
    text: decimalToText(_l?.jurosMesPercentual),
  );
  final _repetir = TextEditingController(text: '1');
  late DateTime _vencimento = _l?.vencimento ?? DateTime.now();
  late String? _categoria = (_l?.categoria.isEmpty ?? true)
      ? null
      : _l!.categoria;
  late String? _contatoId = _l?.contatoId;
  late IndiceMonetario _indice = _l?.indice ?? IndiceMonetario.nenhum;
  bool _padroesAplicados = false;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_aplicarPadroes);
  }

  /// Em uma nova conta a receber, sugere multa, juros e índice padrão.
  void _aplicarPadroes() {
    if (!_vm.carregado || _padroesAplicados) return;
    _padroesAplicados = true;
    if (_novo && _tipo == TipoLancamento.receber) {
      setState(() {
        _multa.text = decimalToText(_vm.config.multaPercentual);
        _juros.text = decimalToText(_vm.config.jurosMesPercentual);
        _indice = _vm.config.indicePadrao;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _descricao,
      _documento,
      _observacoes,
      _valor,
      _multa,
      _juros,
      _repetir,
    ]) {
      c.dispose();
    }
    _vm.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _vm.salvar(
      Lancamento(
        id: _l?.id ?? gerarId(),
        tipo: _tipo,
        descricao: _descricao.text.trim(),
        categoria: _categoria ?? '',
        contatoId: _contatoId,
        documento: _documento.text.trim(),
        observacoes: _observacoes.text.trim(),
        valor: parseMoney(_valor.text) ?? 0,
        vencimento: _vencimento,
        multaPercentual: parseDecimal(_multa.text) ?? 0,
        jurosMesPercentual: parseDecimal(_juros.text) ?? 0,
        indice: _indice,
        status: _l?.status ?? StatusLancamento.aberto,
        parcelaNumero: _l?.parcelaNumero ?? 1,
        parcelaTotal: _l?.parcelaTotal ?? 1,
        grupoId: _l?.grupoId,
        dataBaixa: _l?.dataBaixa,
        valorBaixa: _l?.valorBaixa,
        multa: _l?.multa ?? 0,
        juros: _l?.juros ?? 0,
        correcao: _l?.correcao ?? 0,
        desconto: _l?.desconto ?? 0,
        meio: _l?.meio,
        contaBaixaId: _l?.contaBaixaId,
      ),
      repetir: _novo ? parseInt(_repetir.text) ?? 1 : 1,
    );
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível salvar.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Conta salva.')));
  }

  @override
  Widget build(BuildContext context) {
    final receber = _tipo == TipoLancamento.receber;
    final tamanho = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: AppColors.navy,
      insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: tamanho.height - 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _novo
                          ? 'Nova conta ${_tipo.label.toLowerCase()}'
                          : 'Editar conta',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.gold),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) {
                  if (!_vm.carregado) {
                    return const SizedBox(
                      height: 160,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final baixado = _l?.baixado ?? false;
                  return Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      children: [
                        if (baixado)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Conta já baixada: alterações de valor e vencimento não recalculam a baixa.',
                              style: TextStyle(color: Colors.orangeAccent),
                            ),
                          ),
                        FormSection(
                          title: 'Dados da conta',
                          icon: Icons.receipt_long_outlined,
                          children: [
                            if (_novo)
                              SegmentedButton<TipoLancamento>(
                                segments: [
                                  for (final t in TipoLancamento.values)
                                    ButtonSegment(
                                      value: t,
                                      label: Text(t.label),
                                    ),
                                ],
                                selected: {_tipo},
                                onSelectionChanged: (s) => setState(() {
                                  _tipo = s.first;
                                  _categoria = null;
                                }),
                              ),
                            AppTextField(
                              label: 'Descrição *',
                              controller: _descricao,
                              textCapitalization: TextCapitalization.sentences,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Informe a descrição'
                                  : null,
                            ),
                            FieldRow(
                              children: [
                                AppDropdown<String>(
                                  label: 'Categoria',
                                  value: _categoria,
                                  items: receber
                                      ? categoriasReceber
                                      : categoriasPagar,
                                  onChanged: (v) =>
                                      setState(() => _categoria = v),
                                ),
                                AppDropdown<String?>(
                                  label: receber ? 'Cliente' : 'Fornecedor',
                                  value:
                                      _vm.contatos.any(
                                        (c) => c.id == _contatoId,
                                      )
                                      ? _contatoId
                                      : null,
                                  items: [
                                    null,
                                    ..._vm.contatos.map((c) => c.id),
                                  ],
                                  labelOf: (id) => id == null
                                      ? 'Não informado'
                                      : _vm.nome(id),
                                  onChanged: (v) =>
                                      setState(() => _contatoId = v),
                                ),
                              ],
                            ),
                            FieldRow(
                              children: [
                                AppTextField.money(
                                  label: 'Valor *',
                                  controller: _valor,
                                ),
                                DateField(
                                  label: 'Vencimento',
                                  value: _vencimento,
                                  onChanged: (d) => setState(
                                    () => _vencimento = d ?? _vencimento,
                                  ),
                                ),
                                AppTextField(
                                  label: 'Nº do documento',
                                  controller: _documento,
                                ),
                              ],
                            ),
                            if (_novo)
                              AppTextField.integer(
                                label:
                                    'Repetir por quantos meses (1 = não repetir)',
                                controller: _repetir,
                              ),
                          ],
                        ),
                        FormSection(
                          title: 'Juros, multa e atualização monetária',
                          icon: Icons.percent,
                          children: [
                            const Text(
                              'Aplicados automaticamente se a conta for baixada depois do vencimento.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            FieldRow(
                              children: [
                                AppTextField.decimal(
                                  label: 'Multa',
                                  controller: _multa,
                                  suffixText: '%',
                                ),
                                AppTextField.decimal(
                                  label: 'Juros de mora',
                                  controller: _juros,
                                  suffixText: '% a.m.',
                                ),
                                AppDropdown<IndiceMonetario>(
                                  label: 'Atualização monetária',
                                  value: _indice,
                                  items: IndiceMonetario.values,
                                  labelOf: (e) => e.label,
                                  onChanged: (v) =>
                                      setState(() => _indice = v ?? _indice),
                                ),
                              ],
                            ),
                          ],
                        ),
                        FormSection(
                          title: 'Observações',
                          icon: Icons.notes,
                          children: [
                            AppTextField(
                              label: 'Observações',
                              controller: _observacoes,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCELAR'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _vm.ocupado || !_vm.carregado ? null : _salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'SALVAR',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
