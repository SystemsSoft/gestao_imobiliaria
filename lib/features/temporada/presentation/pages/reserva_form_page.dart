import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/id.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/entities/reserva_enums.dart';
import '../viewmodels/reserva_form_viewmodel.dart';

/// Formulário de reserva ou bloqueio de datas. Em uma nova reserva,
/// [imovelId] e [checkIn] podem vir preenchidos pelo calendário.
class ReservaFormPage extends StatefulWidget {
  const ReservaFormPage({super.key, this.reserva, this.imovelId, this.checkIn});

  final Reserva? reserva;
  final String? imovelId;
  final DateTime? checkIn;

  @override
  State<ReservaFormPage> createState() => _ReservaFormPageState();
}

class _ReservaFormPageState extends State<ReservaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _vm = sl<ReservaFormViewModel>();
  Reserva? get _r => widget.reserva;

  late String? _imovelId = _r?.imovelId ?? widget.imovelId;
  late String? _hospedeId = _r?.hospedeId;
  late bool _bloqueio = _r?.bloqueio ?? false;
  late DateTime _checkIn =
      _r?.checkIn ?? soData(widget.checkIn ?? DateTime.now());
  late DateTime _checkOut =
      _r?.checkOut ?? _checkIn.add(const Duration(days: 2));
  late SituacaoReserva _situacao = _r?.situacao ?? SituacaoReserva.confirmada;
  late OrigemReserva _origem = _r?.origem ?? OrigemReserva.direto;

  late final _hospedes = TextEditingController(text: '${_r?.hospedes ?? 2}');
  late final _diaria = TextEditingController(
    text: moneyToText(_r?.valorDiaria),
  );
  late final _limpeza = TextEditingController(
    text: moneyToText(_r?.taxaLimpeza),
  );
  late final _desconto = TextEditingController(text: moneyToText(_r?.desconto));
  late final _pago = TextEditingController(text: moneyToText(_r?.valorPago));
  late final _motivo = TextEditingController(text: _r?.motivoBloqueio);
  late final _obs = TextEditingController(text: _r?.observacoes);

  @override
  void initState() {
    super.initState();
    if (_r == null && _imovelId != null) {
      // Preenche a diária quando os imóveis terminarem de carregar.
      _vm.addListener(_preencherDiariaInicial);
    }
    _verificar();
  }

  void _preencherDiariaInicial() {
    if (!_vm.carregado) return;
    _vm.removeListener(_preencherDiariaInicial);
    _aplicarDiariaDoImovel();
  }

  @override
  void dispose() {
    for (final c in [
      _hospedes,
      _diaria,
      _limpeza,
      _desconto,
      _pago,
      _motivo,
      _obs,
    ]) {
      c.dispose();
    }
    _vm.dispose();
    super.dispose();
  }

  void _aplicarDiariaDoImovel() {
    final valor = _vm.imovel(_imovelId)?.valorTemporada;
    if (valor != null && _diaria.text.isEmpty && mounted) {
      setState(() => _diaria.text = moneyToText(valor));
    }
  }

  void _verificar() => _vm.verificar(
    imovelId: _imovelId,
    checkIn: _checkIn,
    checkOut: _checkOut,
    ignorarId: _r?.id,
  );

  void _mudou(VoidCallback f) {
    setState(f);
    _verificar();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _vm.salvar(
      Reserva(
        id: _r?.id ?? gerarId(),
        numero: _r?.numero ?? '',
        imovelId: _imovelId ?? '',
        hospedeId: _bloqueio ? null : _hospedeId,
        bloqueio: _bloqueio,
        motivoBloqueio: _bloqueio ? _motivo.text.trim() : '',
        checkIn: _checkIn,
        checkOut: _checkOut,
        hospedes: _bloqueio ? 0 : parseInt(_hospedes.text) ?? 0,
        valorDiaria: _bloqueio ? 0 : parseMoney(_diaria.text) ?? 0,
        taxaLimpeza: _bloqueio ? 0 : parseMoney(_limpeza.text) ?? 0,
        desconto: _bloqueio ? 0 : parseMoney(_desconto.text) ?? 0,
        valorPago: _bloqueio ? 0 : parseMoney(_pago.text) ?? 0,
        situacao: _bloqueio ? SituacaoReserva.confirmada : _situacao,
        origem: _origem,
        observacoes: _obs.text.trim(),
      ),
    );
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível salvar.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text(_bloqueio ? 'Bloqueio salvo.' : 'Reserva salva.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.gold,
        title: Text(
          _r == null
              ? 'Nova reserva'
              : _r!.bloqueio
              ? 'Bloqueio de datas'
              : 'Reserva ${_r!.numero}',
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
                    _periodo(),
                    if (!_bloqueio) _hospede(),
                    if (!_bloqueio) _valores(),
                    FormSection(
                      title: 'Observações',
                      icon: Icons.notes,
                      children: [
                        if (_bloqueio)
                          AppTextField(
                            label: 'Motivo do bloqueio',
                            hint: 'Ex.: manutenção, uso do proprietário',
                            controller: _motivo,
                          ),
                        AppTextField(
                          label: 'Observações',
                          controller: _obs,
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
                        'SALVAR',
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

  Widget _periodo() {
    final noites = _checkOut.difference(_checkIn).inDays;
    final livre = _vm.conflitos.isEmpty;
    return FormSection(
      title: 'Imóvel e período',
      icon: Icons.event_available_outlined,
      children: [
        AppDropdown<String>(
          label: 'Imóvel de temporada *',
          value: _vm.imovel(_imovelId)?.id,
          items: _vm.imoveis.map((i) => i.id).toList(),
          labelOf: (id) {
            final i = _vm.imovel(id)!;
            return '${i.codigo} • ${i.titulo}';
          },
          onChanged: (v) {
            _mudou(() => _imovelId = v);
            if (_diaria.text.isEmpty) _aplicarDiariaDoImovel();
          },
          validator: (v) => v == null ? 'Selecione o imóvel' : null,
        ),
        AppSwitch(
          label: 'Bloqueio de datas (manutenção ou uso do proprietário)',
          value: _bloqueio,
          onChanged: (v) => setState(() => _bloqueio = v),
        ),
        FieldRow(
          children: [
            DateField(
              label: 'Check-in',
              value: _checkIn,
              onChanged: (d) => _mudou(() {
                _checkIn = soData(d ?? _checkIn);
                if (!_checkOut.isAfter(_checkIn)) {
                  _checkOut = _checkIn.add(const Duration(days: 1));
                }
              }),
            ),
            DateField(
              label: 'Check-out',
              value: _checkOut,
              onChanged: (d) =>
                  _mudou(() => _checkOut = soData(d ?? _checkOut)),
            ),
          ],
        ),
        if (_imovelId != null && noites > 0)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: (livre ? Colors.greenAccent : Colors.redAccent).withValues(
                alpha: 0.12,
              ),
              border: Border.all(
                color: (livre ? Colors.greenAccent : Colors.redAccent)
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  livre ? Icons.check_circle_outline : Icons.block,
                  color: livre ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    livre
                        ? '$noites noite(s) • período disponível'
                        : 'Período indisponível: conflita com '
                              '${_vm.conflitos.first.bloqueio ? 'um bloqueio' : 'a reserva ${_vm.conflitos.first.numero}'} '
                              '(${formatDate(_vm.conflitos.first.checkIn)} a ${formatDate(_vm.conflitos.first.checkOut)})',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _hospede() => FormSection(
    title: 'Hóspede',
    icon: Icons.person_outline,
    children: [
      AppDropdown<String>(
        label: 'Hóspede *',
        value: _vm.contatos.any((c) => c.id == _hospedeId) ? _hospedeId : null,
        items: _vm.contatos.map((c) => c.id).toList(),
        labelOf: _vm.nome,
        onChanged: (v) => setState(() => _hospedeId = v),
        validator: (v) => v == null ? 'Selecione o hóspede' : null,
      ),
      if (_vm.contatos.isEmpty)
        const Text(
          'Cadastre o hóspede em "Cadastros e CRM > Contatos".',
          style: TextStyle(color: Colors.orangeAccent),
        ),
      FieldRow(
        children: [
          AppTextField.integer(label: 'Nº de hóspedes', controller: _hospedes),
          AppDropdown<OrigemReserva>(
            label: 'Origem da reserva',
            value: _origem,
            items: OrigemReserva.values,
            labelOf: (e) => e.label,
            onChanged: (v) => setState(() => _origem = v ?? _origem),
          ),
          AppDropdown<SituacaoReserva>(
            label: 'Situação',
            value: _situacao,
            items: SituacaoReserva.values,
            labelOf: (e) => e.label,
            onChanged: (v) => setState(() => _situacao = v ?? _situacao),
          ),
        ],
      ),
    ],
  );

  Widget _valores() {
    final diaria = parseMoney(_diaria.text) ?? 0;
    final e = _vm.estadia(
      checkIn: _checkIn,
      checkOut: _checkOut,
      valorDiaria: diaria,
      taxaLimpeza: parseMoney(_limpeza.text) ?? 0,
      desconto: parseMoney(_desconto.text) ?? 0,
    );
    final pago = parseMoney(_pago.text) ?? 0;
    AppTextField dinheiro(String label, TextEditingController c) =>
        AppTextField(
          label: label,
          controller: c,
          prefixText: r'R$ ',
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          onChanged: (_) => setState(() {}),
        );
    return FormSection(
      title: 'Valores',
      icon: Icons.attach_money,
      children: [
        FieldRow(
          children: [
            dinheiro('Valor da diária *', _diaria),
            dinheiro('Taxa de limpeza', _limpeza),
            dinheiro('Desconto', _desconto),
          ],
        ),
        ResumoValores(
          itens: [
            (
              rotulo: '${e.noites} noite(s)',
              valor: formatMoney(e.subtotal),
              cor: AppColors.gold,
            ),
            (
              rotulo: 'Total',
              valor: formatMoney(e.total),
              cor: Colors.greenAccent,
            ),
            (
              rotulo: 'Saldo',
              valor: formatMoney(e.total - pago),
              cor: e.total - pago > 0
                  ? Colors.orangeAccent
                  : Colors.greenAccent,
            ),
          ],
        ),
        dinheiro('Valor já pago (sinal / total)', _pago),
      ],
    );
  }
}
