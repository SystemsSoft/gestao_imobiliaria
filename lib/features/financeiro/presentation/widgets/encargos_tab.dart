import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/financeiro_enums.dart';
import '../../domain/entities/indice_mensal.dart';
import '../viewmodels/encargos_viewmodel.dart';

/// Juros, multa e atualização monetária: padrões, índices e simulador.
class EncargosTab extends StatefulWidget {
  const EncargosTab({super.key});

  @override
  State<EncargosTab> createState() => _EncargosTabState();
}

class _EncargosTabState extends State<EncargosTab> {
  final _vm = sl<EncargosViewModel>();

  // Simulador
  final _valor = TextEditingController(text: '1.000,00');
  final _multa = TextEditingController(text: '2');
  final _juros = TextEditingController(text: '1');
  DateTime _vencimento = DateTime.now().subtract(const Duration(days: 45));
  DateTime _pagamento = DateTime.now();
  IndiceMonetario _indice = IndiceMonetario.nenhum;

  // Padrões
  final _multaPadrao = TextEditingController();
  final _jurosPadrao = TextEditingController();
  IndiceMonetario _indicePadrao = IndiceMonetario.nenhum;
  bool _padroesCarregados = false;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_carregarPadroes);
  }

  void _carregarPadroes() {
    if (_padroesCarregados || !_vm.carregado) return;
    _padroesCarregados = true;
    setState(() {
      _multaPadrao.text = decimalToText(_vm.config.multaPercentual);
      _jurosPadrao.text = decimalToText(_vm.config.jurosMesPercentual);
      _indicePadrao = _vm.config.indicePadrao;
    });
  }

  @override
  void dispose() {
    for (final c in [_valor, _multa, _juros, _multaPadrao, _jurosPadrao]) {
      c.dispose();
    }
    _vm.dispose();
    super.dispose();
  }

  Future<void> _novoIndice() async {
    final i = await showDialog<IndiceMensal>(
      context: context,
      builder: (_) => const _IndiceDialog(),
    );
    if (i == null) return;
    final ok = await _vm.salvarIndice(i);
    if (mounted && !ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível salvar.');
    }
  }

  Future<void> _salvarPadroes() async {
    final ok = await _vm.salvarConfig(
      ConfiguracaoFinanceira(
        multaPercentual: parseDecimal(_multaPadrao.text) ?? 0,
        jurosMesPercentual: parseDecimal(_jurosPadrao.text) ?? 0,
        indicePadrao: _indicePadrao,
        linkBanco: _vm.config.linkBanco,
      ),
    );
    if (!mounted) return;
    mostrarMensagem(
      context,
      ok ? 'Padrões salvos.' : _vm.erro ?? 'Não foi possível salvar.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _simulador(),
            _padroes(),
            _indices(),
            FormSection(
              title: 'Como o cálculo é feito',
              icon: Icons.info_outline,
              children: const [
                Text(
                  '• Atualização monetária: variação composta do índice entre o mês do vencimento '
                  'e o mês anterior ao do pagamento (índices são divulgados depois do fim do mês).\n'
                  '• Multa: percentual único sobre o valor atualizado.\n'
                  '• Juros de mora: percentual ao mês, proporcional aos dias de atraso (mês de 30 dias), '
                  'sobre o valor atualizado.\n'
                  '• Meses sem índice cadastrado contam como 0% e são avisados na baixa.\n'
                  '• Valores sugeridos ao criar contas a receber vêm dos padrões acima.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _simulador() {
    final valor = parseMoney(_valor.text) ?? 0;
    final r = _vm.simular(
      valor: valor,
      vencimento: _vencimento,
      pagamento: _pagamento,
      multa: parseDecimal(_multa.text) ?? 0,
      juros: parseDecimal(_juros.text) ?? 0,
      indice: _indice,
    );
    final e = r.encargos;
    Widget linha(String t, double v, {Color? cor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(t, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            formatMoney(v),
            style: TextStyle(color: cor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    return FormSection(
      title: 'Simulador de atraso',
      icon: Icons.calculate_outlined,
      children: [
        FieldRow(
          children: [
            AppTextField(
              label: 'Valor original',
              controller: _valor,
              prefixText: r'R$ ',
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              onChanged: (_) => setState(() {}),
            ),
            DateField(
              label: 'Vencimento',
              value: _vencimento,
              onChanged: (d) => setState(() => _vencimento = d ?? _vencimento),
            ),
            DateField(
              label: 'Pagamento',
              value: _pagamento,
              onChanged: (d) => setState(() => _pagamento = d ?? _pagamento),
            ),
          ],
        ),
        FieldRow(
          children: [
            AppTextField.decimal(
              label: 'Multa',
              controller: _multa,
              suffixText: '%',
              onChanged: (_) => setState(() {}),
            ),
            AppTextField.decimal(
              label: 'Juros de mora',
              controller: _juros,
              suffixText: '% a.m.',
              onChanged: (_) => setState(() {}),
            ),
            AppDropdown<IndiceMonetario>(
              label: 'Atualização monetária',
              value: _indice,
              items: IndiceMonetario.values,
              labelOf: (x) => x.label,
              onChanged: (v) => setState(() => _indice = v ?? _indice),
            ),
          ],
        ),
        linha('Valor original', valor),
        linha(
          'Atualização monetária (${decimalToText(double.parse(r.variacao.percentual.toStringAsFixed(4)))}%)',
          e.correcao,
          cor: Colors.orangeAccent,
        ),
        linha('Multa', e.multa, cor: Colors.orangeAccent),
        linha(
          'Juros (${e.diasAtraso} dia(s) de atraso)',
          e.juros,
          cor: Colors.orangeAccent,
        ),
        const Divider(),
        linha('Valor devido', r.devido, cor: AppColors.gold),
        if (r.variacao.mesesSemIndice.isNotEmpty)
          Text(
            'Sem índice cadastrado para: '
            '${r.variacao.mesesSemIndice.map((m) => '${nomeMes(m.month)}/${m.year}').join(', ')} (considerado 0%).',
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
          ),
      ],
    );
  }

  Widget _padroes() => FormSection(
    title: 'Padrões para contas a receber',
    icon: Icons.tune,
    children: [
      FieldRow(
        children: [
          AppTextField.decimal(
            label: 'Multa',
            controller: _multaPadrao,
            suffixText: '%',
          ),
          AppTextField.decimal(
            label: 'Juros de mora',
            controller: _jurosPadrao,
            suffixText: '% a.m.',
          ),
          AppDropdown<IndiceMonetario>(
            label: 'Atualização monetária',
            value: _indicePadrao,
            items: IndiceMonetario.values,
            labelOf: (x) => x.label,
            onChanged: (v) =>
                setState(() => _indicePadrao = v ?? _indicePadrao),
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.icon(
          onPressed: _salvarPadroes,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navyDark,
          ),
          icon: const Icon(Icons.check),
          label: const Text('Salvar padrões'),
        ),
      ),
    ],
  );

  Widget _indices() {
    final lista = _vm.indicesFiltrados;
    return FormSection(
      title: 'Índices mensais (IGP-M, IPCA, INPC)',
      icon: Icons.show_chart,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cadastre a variação mensal divulgada para atualizar valores em atraso.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _novoIndice,
              icon: const Icon(Icons.add),
              label: const Text('Novo índice'),
            ),
          ],
        ),
        FiltroChips<IndiceMonetario>(
          opcoes: IndiceMonetario.values
              .where((i) => i != IndiceMonetario.nenhum)
              .toList(),
          selecionado: _vm.filtroIndice,
          labelOf: (i) => i.label,
          onChanged: _vm.filtrar,
          padding: EdgeInsets.zero,
        ),
        if (lista.isEmpty)
          const Text(
            'Nenhum índice cadastrado.',
            style: TextStyle(color: Colors.white60),
          ),
        for (final i in lista)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.show_chart, color: AppColors.gold),
            title: Text('${i.indice.label} • ${nomeMes(i.mes)}/${i.ano}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${decimalToText(i.percentual)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: i.percentual < 0
                        ? Colors.redAccent
                        : Colors.greenAccent,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _vm.removerIndice(i.id),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IndiceDialog extends StatefulWidget {
  const _IndiceDialog();

  @override
  State<_IndiceDialog> createState() => _IndiceDialogState();
}

class _IndiceDialogState extends State<_IndiceDialog> {
  IndiceMonetario _indice = IndiceMonetario.igpm;
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month - 1);
  final _valor = TextEditingController();

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Novo índice mensal'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            AppDropdown<IndiceMonetario>(
              label: 'Índice',
              value: _indice,
              items: IndiceMonetario.values
                  .where((i) => i != IndiceMonetario.nenhum)
                  .toList(),
              labelOf: (i) => i.label,
              onChanged: (v) => setState(() => _indice = v ?? _indice),
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
            AppTextField(
              label: 'Variação do mês (%)',
              hint: 'Ex.: 0,45 ou -0,12',
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ],
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
            IndiceMensal(
              indice: _indice,
              ano: _mes.year,
              mes: _mes.month,
              percentual: parseDecimal(_valor.text) ?? 0,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
