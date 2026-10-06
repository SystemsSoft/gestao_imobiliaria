import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/locacao_enums.dart';
import '../viewmodels/contrato_form_viewmodel.dart';

class ContratoFormPage extends StatefulWidget {
  const ContratoFormPage({super.key, this.contrato});

  final ContratoLocacao? contrato;

  @override
  State<ContratoFormPage> createState() => _ContratoFormPageState();
}

class _BeneficiarioEdit {
  _BeneficiarioEdit(this.contatoId, double? percentual)
    : percentual = TextEditingController(text: decimalToText(percentual));

  String? contatoId;
  final TextEditingController percentual;
}

class _ContratoFormPageState extends State<ContratoFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _vm = sl<ContratoFormViewModel>();
  ContratoLocacao? get _c => widget.contrato;

  late String? _imovelId = _c?.imovelId;
  late String? _locatarioId = _c?.locatarioId;
  late String? _fiadorId = _c?.fiadorId;
  late GarantiaLocacao _garantia = _c?.garantia ?? GarantiaLocacao.fiador;
  late FinalidadeLocacao _finalidade =
      _c?.finalidade ?? FinalidadeLocacao.residencial;
  late IndiceReajuste _indice = _c?.indiceReajuste ?? IndiceReajuste.igpm;
  late StatusContrato _status = _c?.status ?? StatusContrato.ativo;
  late DateTime _inicio = _c?.dataInicio ?? DateTime.now();

  late final _valorGarantia = TextEditingController(
    text: moneyToText(_c?.valorGarantia),
  );
  late final _prazo = TextEditingController(text: '${_c?.prazoMeses ?? 30}');
  late final _dia = TextEditingController(text: '${_c?.diaVencimento ?? 10}');
  late final _aluguel = TextEditingController(
    text: moneyToText(_c?.valorAluguel),
  );
  late final _taxaAdm = TextEditingController(
    text: decimalToText(_c?.taxaAdministracao ?? 10),
  );
  late final _taxaInterm = TextEditingController(
    text: decimalToText(_c?.taxaIntermediacao ?? 0),
  );
  late final _multa = TextEditingController(
    text: decimalToText(_c?.multaAtraso ?? 10),
  );
  late final _juros = TextEditingController(
    text: decimalToText(_c?.jurosMes ?? 1),
  );
  late final _desconto = TextEditingController(
    text: moneyToText(_c?.descontoPontualidade),
  );
  late final _clausulas = TextEditingController(text: _c?.clausulasAdicionais);
  late final _observacoes = TextEditingController(text: _c?.observacoes);
  late final List<_BeneficiarioEdit> _beneficiarios = [
    for (final b in _c?.beneficiarios ?? const <Beneficiario>[])
      _BeneficiarioEdit(b.contatoId, b.percentual),
  ];

  @override
  void dispose() {
    for (final c in [
      _valorGarantia,
      _prazo,
      _dia,
      _aluguel,
      _taxaAdm,
      _taxaInterm,
      _multa,
      _juros,
      _desconto,
      _clausulas,
      _observacoes,
      ..._beneficiarios.map((b) => b.percentual),
    ]) {
      c.dispose();
    }
    _vm.dispose();
    super.dispose();
  }

  void _escolherImovel(String? id) {
    setState(() {
      _imovelId = id;
      if (id == null) return;
      final s = _vm.sugestoesDoImovel(id);
      if (_aluguel.text.isEmpty && s.aluguel != null) {
        _aluguel.text = moneyToText(s.aluguel);
      }
      if (_beneficiarios.isEmpty) {
        _beneficiarios.addAll(
          s.beneficiarios.map(
            (b) => _BeneficiarioEdit(b.contatoId, b.percentual),
          ),
        );
      }
    });
  }

  double get _somaPercentuais => _beneficiarios.fold(
    0,
    (s, b) => s + (parseDecimal(b.percentual.text) ?? 0),
  );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _vm.salvar(
      ContratoLocacao(
        id: _c?.id ?? gerarId(),
        numero: _c?.numero ?? '',
        imovelId: _imovelId ?? '',
        locatarioId: _locatarioId ?? '',
        fiadorId: _garantia == GarantiaLocacao.fiador ? _fiadorId : null,
        beneficiarios: [
          for (final b in _beneficiarios)
            if (b.contatoId != null)
              Beneficiario(
                contatoId: b.contatoId!,
                percentual: parseDecimal(b.percentual.text) ?? 0,
              ),
        ],
        finalidade: _finalidade,
        garantia: _garantia,
        valorGarantia: parseMoney(_valorGarantia.text),
        dataInicio: _inicio,
        prazoMeses: parseInt(_prazo.text) ?? 0,
        diaVencimento: parseInt(_dia.text) ?? 0,
        valorAluguel: parseMoney(_aluguel.text) ?? 0,
        taxaAdministracao: parseDecimal(_taxaAdm.text) ?? 0,
        taxaIntermediacao: parseDecimal(_taxaInterm.text) ?? 0,
        indiceReajuste: _indice,
        multaAtraso: parseDecimal(_multa.text) ?? 0,
        jurosMes: parseDecimal(_juros.text) ?? 0,
        descontoPontualidade: parseMoney(_desconto.text) ?? 0,
        status: _status,
        clausulasAdicionais: _clausulas.text.trim(),
        observacoes: _observacoes.text.trim(),
      ),
    );
    if (!mounted) return;
    if (!ok) {
      return mostrarMensagem(context, _vm.erro ?? 'Não foi possível salvar.');
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(const SnackBar(content: Text('Contrato salvo.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text(
          _c == null ? 'Novo contrato de locação' : 'Contrato ${_c!.numero}',
        ),
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
                    _beneficiariosSecao(),
                    _prazoSecao(),
                    _valoresSecao(),
                    FormSection(
                      title: 'Cláusulas e observações',
                      icon: Icons.notes,
                      children: [
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
                        'SALVAR CONTRATO',
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

  String _nome(String? id) =>
      _vm.contatos.where((c) => c.id == id).firstOrNull?.nome ?? '';

  Widget _partes() {
    final contatos = _vm.contatos;
    return FormSection(
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
        AppDropdown<String>(
          label: 'Locatário *',
          value: contatos.any((c) => c.id == _locatarioId)
              ? _locatarioId
              : null,
          items: contatos.map((c) => c.id).toList(),
          labelOf: _nome,
          onChanged: (v) => setState(() => _locatarioId = v),
          validator: (v) => v == null ? 'Selecione o locatário' : null,
        ),
        FieldRow(
          children: [
            AppDropdown<GarantiaLocacao>(
              label: 'Garantia',
              value: _garantia,
              items: GarantiaLocacao.values,
              labelOf: (e) => e.label,
              onChanged: (v) => setState(() => _garantia = v ?? _garantia),
            ),
            if (_garantia == GarantiaLocacao.fiador)
              AppDropdown<String?>(
                label: 'Fiador',
                value: contatos.any((c) => c.id == _fiadorId)
                    ? _fiadorId
                    : null,
                items: [null, ...contatos.map((c) => c.id)],
                labelOf: (id) => id == null ? 'Nenhum' : _nome(id),
                onChanged: (v) => setState(() => _fiadorId = v),
              )
            else if (_garantia != GarantiaLocacao.semGarantia)
              AppTextField.money(
                label: 'Valor da garantia',
                controller: _valorGarantia,
              ),
          ],
        ),
        if (contatos.isEmpty)
          const Text(
            'Cadastre locatários, proprietários e fiadores em "Cadastros e CRM > Contatos".',
            style: TextStyle(color: Colors.orangeAccent),
          ),
      ],
    );
  }

  Widget _beneficiariosSecao() {
    final soma = _somaPercentuais;
    final ok = (soma - 100).abs() <= 0.01;
    return FormSection(
      title: 'Locadores / beneficiários do repasse',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        for (var i = 0; i < _beneficiarios.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: AppDropdown<String>(
                  label: 'Beneficiário',
                  value:
                      _vm.contatos.any(
                        (c) => c.id == _beneficiarios[i].contatoId,
                      )
                      ? _beneficiarios[i].contatoId
                      : null,
                  items: _vm.contatos.map((c) => c.id).toList(),
                  labelOf: _nome,
                  onChanged: (v) =>
                      setState(() => _beneficiarios[i].contatoId = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField.decimal(
                  label: 'Cota',
                  controller: _beneficiarios[i].percentual,
                  suffixText: '%',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() {
                  _beneficiarios.removeAt(i).percentual.dispose();
                }),
              ),
            ],
          ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(
                () => _beneficiarios.add(
                  _BeneficiarioEdit(null, _beneficiarios.isEmpty ? 100 : null),
                ),
              ),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Adicionar beneficiário'),
            ),
            const Spacer(),
            Text(
              'Total: ${decimalToText(soma)}%',
              style: TextStyle(
                color: ok ? Colors.greenAccent : Colors.orangeAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _prazoSecao() => FormSection(
    title: 'Prazo e condições',
    icon: Icons.event_outlined,
    children: [
      FieldRow(
        children: [
          DateField(
            label: 'Início da locação',
            value: _inicio,
            onChanged: (d) => setState(() => _inicio = d ?? _inicio),
          ),
          AppTextField.integer(label: 'Prazo (meses)', controller: _prazo),
          AppTextField.integer(label: 'Dia do vencimento', controller: _dia),
        ],
      ),
      FieldRow(
        children: [
          AppDropdown<FinalidadeLocacao>(
            label: 'Finalidade',
            value: _finalidade,
            items: FinalidadeLocacao.values,
            labelOf: (e) => e.label,
            onChanged: (v) => setState(() => _finalidade = v ?? _finalidade),
          ),
          AppDropdown<IndiceReajuste>(
            label: 'Índice de reajuste',
            value: _indice,
            items: IndiceReajuste.values,
            labelOf: (e) => e.label,
            onChanged: (v) => setState(() => _indice = v ?? _indice),
          ),
          AppDropdown<StatusContrato>(
            label: 'Situação',
            value: _status,
            items: StatusContrato.values,
            labelOf: (e) => e.label,
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
        ],
      ),
    ],
  );

  Widget _valoresSecao() => FormSection(
    title: 'Valores, taxas e encargos',
    icon: Icons.attach_money,
    children: [
      FieldRow(
        children: [
          AppTextField.money(label: 'Aluguel mensal *', controller: _aluguel),
          AppTextField.money(
            label: 'Desconto de pontualidade',
            controller: _desconto,
          ),
        ],
      ),
      FieldRow(
        children: [
          AppTextField.decimal(
            label: 'Taxa de administração',
            controller: _taxaAdm,
            suffixText: '%',
          ),
          AppTextField.decimal(
            label: 'Intermediação (1º aluguel)',
            controller: _taxaInterm,
            suffixText: '%',
          ),
        ],
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
