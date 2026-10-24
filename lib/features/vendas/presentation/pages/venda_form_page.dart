import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/venda.dart';
import '../../domain/entities/venda_enums.dart';
import '../../domain/services/calculadora_financiamento.dart';
import '../viewmodels/venda_form_viewmodel.dart';
import '../widgets/participacoes_editor.dart';

class VendaFormPage extends StatefulWidget {
  const VendaFormPage({super.key, this.venda});

  final Venda? venda;

  @override
  State<VendaFormPage> createState() => _VendaFormPageState();
}

class _VendaFormPageState extends State<VendaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _vm = sl<VendaFormViewModel>();
  Venda? get _v => widget.venda;

  late String? _imovelId = _v?.imovelId;
  late final List<String?> _compradores = [...?_v?.compradores];
  late final List<ParticipacaoEdit> _vendedores = [
    for (final p in _v?.vendedores ?? const <Participacao>[])
      ParticipacaoEdit.de(p),
  ];
  late final List<ParticipacaoEdit> _corretores = [
    for (final p in _v?.corretores ?? const [Participacao(percentual: 100)])
      ParticipacaoEdit.de(p),
  ];
  late DateTime _dataVenda = _v?.dataVenda ?? DateTime.now();
  late DateTime? _vencEntrada = _v?.vencimentoEntrada;
  late FormaPagamento _forma = _v?.formaPagamento ?? FormaPagamento.aVista;
  late SistemaAmortizacao _sistema =
      _v?.plano?.sistema ?? SistemaAmortizacao.price;
  late DateTime _primeiroVenc =
      _v?.plano?.primeiroVencimento ??
      DateTime(_dataVenda.year, _dataVenda.month + 1, _dataVenda.day);
  late CredorParcelas _credor = _v?.credor ?? CredorParcelas.vendedor;
  late StatusVenda _status = _v?.status ?? StatusVenda.ativa;

  late final _valor = TextEditingController(text: moneyToText(_v?.valorVenda));
  late final _entrada = TextEditingController(
    text: moneyToText(_v?.valorEntrada),
  );
  late final _parcelas = TextEditingController(
    text: '${_v?.plano?.numeroParcelas ?? 60}',
  );
  late final _taxa = TextEditingController(
    text: decimalToText(_v?.plano?.taxaJurosMes ?? 1),
  );
  late final _multa = TextEditingController(
    text: decimalToText(_v?.multaAtraso ?? 2),
  );
  late final _juros = TextEditingController(
    text: decimalToText(_v?.jurosMes ?? 1),
  );
  late final _comissao = TextEditingController(
    text: decimalToText(_v?.comissaoPercentual ?? 6),
  );
  late final _clausulas = TextEditingController(text: _v?.clausulasAdicionais);
  late final _observacoes = TextEditingController(text: _v?.observacoes);

  @override
  void dispose() {
    for (final c in [
      _valor,
      _entrada,
      _parcelas,
      _taxa,
      _multa,
      _juros,
      _comissao,
      _clausulas,
      _observacoes,
      ..._vendedores.map((e) => e.percentual),
      ..._corretores.map((e) => e.percentual),
    ]) {
      c.dispose();
    }
    _vm.dispose();
    super.dispose();
  }

  void _atualizar() => setState(() {});

  void _escolherImovel(String? id) {
    setState(() {
      _imovelId = id;
      if (id == null) return;
      final s = _vm.sugestoesDoImovel(id);
      if (_valor.text.isEmpty && s.valor != null) {
        _valor.text = moneyToText(s.valor);
      }
      if (_vendedores.isEmpty && s.vendedorId != null) {
        _vendedores.add(
          ParticipacaoEdit(contatoId: s.vendedorId, percentual: 100),
        );
      }
    });
  }

  double get _valorVenda => parseMoney(_valor.text) ?? 0;
  double get _valorEntrada => parseMoney(_entrada.text) ?? 0;

  PlanoFinanciamento get _plano => PlanoFinanciamento(
    numeroParcelas: parseInt(_parcelas.text) ?? 0,
    taxaJurosMes: parseDecimal(_taxa.text) ?? 0,
    sistema: _sistema,
    primeiroVencimento: _primeiroVenc,
  );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _vm.salvar(
      Venda(
        id: _v?.id ?? gerarId(),
        numero: _v?.numero ?? '',
        imovelId: _imovelId ?? '',
        compradores: _compradores.whereType<String>().toSet().toList(),
        vendedores: _vendedores.map((e) => e.toParticipacao()).toList(),
        dataVenda: _dataVenda,
        valorVenda: _valorVenda,
        valorEntrada: _valorEntrada,
        vencimentoEntrada: _vencEntrada,
        formaPagamento: _forma,
        plano: _forma == FormaPagamento.financiamentoProprio ? _plano : null,
        credor: _credor,
        multaAtraso: parseDecimal(_multa.text) ?? 0,
        jurosMes: parseDecimal(_juros.text) ?? 0,
        comissaoPercentual: parseDecimal(_comissao.text) ?? 0,
        corretores: _corretores.map((e) => e.toParticipacao()).toList(),
        status: _status,
        clausulasAdicionais: _clausulas.text.trim(),
        observacoes: _observacoes.text.trim(),
      ),
    );
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível salvar.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Venda salva.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text(_v == null ? 'Nova venda' : 'Venda ${_v!.numero}'),
        actions: [
          TextButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: const Text('SALVAR'),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (!_vm.carregado) {
            return const Center(child: CircularProgressIndicator());
          }
          return Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _partes(),
                    _valores(),
                    if (_forma == FormaPagamento.financiamentoProprio)
                      _financiamento(),
                    _comissaoSecao(),
                    FormSection(
                      title: 'Cláusulas e observações',
                      icon: Icons.notes,
                      children: [
                        AppDropdown<StatusVenda>(
                          label: 'Situação',
                          value: _status,
                          items: StatusVenda.values,
                          labelOf: (e) => e.label,
                          onChanged: (v) =>
                              setState(() => _status = v ?? _status),
                        ),
                        AppTextField(
                          label:
                              'Cláusulas adicionais (entram no contrato impresso)',
                          controller: _clausulas,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        AppTextField(
                          label: 'Observações internas',
                          controller: _observacoes,
                          maxLines: 2,
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: _vm.ocupado ? null : _salvar,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'SALVAR VENDA',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _partes() => FormSection(
    title: 'Imóvel e partes',
    icon: Icons.people_outline,
    children: [
      AppDropdown<String>(
        label: 'Imóvel *',
        value: _vm.imovel(_imovelId)?.id,
        items: _vm.imoveis.map((i) => i.id).toList(),
        labelOf: (id) {
          final i = _vm.imovel(id)!;
          return '${i.codigo} • ${i.titulo}';
        },
        onChanged: _escolherImovel,
        validator: (v) => v == null ? 'Selecione o imóvel' : null,
      ),
      const Text('Compradores', style: TextStyle(color: Colors.white70)),
      for (var i = 0; i < _compradores.length; i++)
        Row(
          children: [
            Expanded(
              child: AppDropdown<String>(
                label: 'Comprador ${i + 1}',
                value: _vm.contatos.any((c) => c.id == _compradores[i])
                    ? _compradores[i]
                    : null,
                items: _vm.contatos.map((c) => c.id).toList(),
                labelOf: _vm.nome,
                onChanged: (v) => setState(() => _compradores[i] = v),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(() => _compradores.removeAt(i)),
            ),
          ],
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _compradores.add(null)),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Adicionar comprador'),
        ),
      ),
      const Divider(),
      const Text(
        'Vendedores (proprietários)',
        style: TextStyle(color: Colors.white70),
      ),
      ParticipacoesEditor(
        itens: _vendedores,
        contatos: _vm.contatos,
        rotulo: 'Vendedor',
        onChanged: _atualizar,
      ),
      if (_vm.contatos.isEmpty)
        const Text(
          'Cadastre compradores e vendedores em "Cadastros e CRM > Contatos".',
          style: TextStyle(color: Colors.orangeAccent),
        ),
    ],
  );

  Widget _valores() {
    final financiado = _valorVenda - _valorEntrada;
    return FormSection(
      title: 'Valores e forma de pagamento',
      icon: Icons.attach_money,
      children: [
        FieldRow(
          children: [
            AppTextField.money(label: 'Valor da venda *', controller: _valor),
            DateField(
              label: 'Data da venda',
              value: _dataVenda,
              onChanged: (d) => setState(() => _dataVenda = d ?? _dataVenda),
            ),
          ],
        ),
        AppDropdown<FormaPagamento>(
          label: 'Forma de pagamento',
          value: _forma,
          items: FormaPagamento.values,
          labelOf: (e) => e.label,
          onChanged: (v) => setState(() => _forma = v ?? _forma),
        ),
        if (_forma != FormaPagamento.aVista || _valorEntrada > 0)
          FieldRow(
            children: [
              AppTextField(
                label: 'Entrada / sinal',
                controller: _entrada,
                prefixText: r'R$ ',
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                onChanged: (_) => _atualizar(),
              ),
              DateField(
                label: 'Vencimento da entrada',
                value: _vencEntrada ?? _dataVenda,
                onChanged: (d) => setState(() => _vencEntrada = d),
              ),
            ],
          ),
        if (_forma != FormaPagamento.aVista)
          Text(
            'Saldo a financiar: ${formatMoney(financiado < 0 ? 0 : financiado)}',
            style: TextStyle(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        FieldRow(
          children: [
            AppTextField.decimal(
              label: 'Multa por atraso',
              controller: _multa,
              suffixText: '%',
            ),
            AppTextField.decimal(
              label: 'Juros de mora',
              controller: _juros,
              suffixText: '% a.m.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _financiamento() {
    final tabela = _vm.simular(_valorVenda - _valorEntrada, _plano);
    final totalJuros = tabela.fold<double>(0, (s, p) => s + p.juros);
    final total = tabela.fold<double>(0, (s, p) => s + p.valor);
    return FormSection(
      title: 'Financiamento próprio (parcelado pela imobiliária)',
      icon: Icons.account_balance_outlined,
      children: [
        FieldRow(
          children: [
            AppTextField.integer(
              label: 'Nº de parcelas',
              controller: _parcelas,
              onChanged: (_) => _atualizar(),
            ),
            AppTextField.decimal(
              label: 'Juros do financiamento',
              controller: _taxa,
              suffixText: '% a.m.',
              onChanged: (_) => _atualizar(),
            ),
            DateField(
              label: '1º vencimento',
              value: _primeiroVenc,
              onChanged: (d) =>
                  setState(() => _primeiroVenc = d ?? _primeiroVenc),
            ),
          ],
        ),
        FieldRow(
          children: [
            AppDropdown<SistemaAmortizacao>(
              label: 'Sistema de amortização',
              value: _sistema,
              items: SistemaAmortizacao.values,
              labelOf: (e) => '${e.label} (${e.descricao})',
              onChanged: (v) => setState(() => _sistema = v ?? _sistema),
            ),
            AppDropdown<CredorParcelas>(
              label: 'Parcelas recebidas por',
              value: _credor,
              items: CredorParcelas.values,
              labelOf: (e) => e.label,
              onChanged: (v) => setState(() => _credor = v ?? _credor),
            ),
          ],
        ),
        if (tabela.isNotEmpty) ...[
          ResumoValores(
            itens: [
              (
                rotulo: _sistema == SistemaAmortizacao.sac
                    ? '1ª parcela'
                    : 'Parcela',
                valor: formatMoney(tabela.first.valor),
                cor: AppColors.gold,
              ),
              (
                rotulo: 'Total de juros',
                valor: formatMoney(totalJuros),
                cor: Colors.orangeAccent,
              ),
              (
                rotulo: 'Total a prazo',
                valor: formatMoney(total),
                cor: Colors.greenAccent,
              ),
            ],
          ),
          _TabelaSimulacao(tabela: tabela),
        ],
      ],
    );
  }

  Widget _comissaoSecao() => FormSection(
    title: 'Comissão de corretagem',
    icon: Icons.percent,
    children: [
      AppTextField.decimal(
        label: 'Comissão sobre o valor da venda',
        controller: _comissao,
        suffixText: '%',
        onChanged: (_) => _atualizar(),
      ),
      Text(
        'Valor da comissão: ${formatMoney(_valorVenda * (parseDecimal(_comissao.text) ?? 0) / 100)}',
        style: TextStyle(
          color: AppColors.goldLight,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Text(
        'Divisão da comissão',
        style: TextStyle(color: Colors.white70),
      ),
      ParticipacoesEditor(
        itens: _corretores,
        contatos: _vm.contatos,
        rotulo: 'Beneficiário',
        permitirImobiliaria: true,
        onChanged: _atualizar,
      ),
    ],
  );
}

class _TabelaSimulacao extends StatelessWidget {
  const _TabelaSimulacao({required this.tabela});

  final List<ParcelaPlano> tabela;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Ver tabela de ${tabela.length} parcelas',
          style: TextStyle(color: AppColors.gold),
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
              columns: const [
                DataColumn(label: Text('Nº')),
                DataColumn(label: Text('Vencimento')),
                DataColumn(label: Text('Parcela'), numeric: true),
                DataColumn(label: Text('Juros'), numeric: true),
                DataColumn(label: Text('Amortização'), numeric: true),
                DataColumn(label: Text('Saldo'), numeric: true),
              ],
              rows: [
                for (final p in tabela)
                  DataRow(
                    cells: [
                      DataCell(Text('${p.numero}')),
                      DataCell(Text(formatDate(p.vencimento))),
                      DataCell(Text(formatMoney(p.valor))),
                      DataCell(Text(formatMoney(p.juros))),
                      DataCell(Text(formatMoney(p.amortizacao))),
                      DataCell(Text(formatMoney(p.saldoDevedor))),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
