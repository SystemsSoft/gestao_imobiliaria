import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/competencia_selector.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/dimob.dart';
import '../viewmodels/dimob_viewmodel.dart';
import 'declarante_dialog.dart';

const _mesesAbrev = [
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

/// Geração da DIMOB (Declaração de Informações sobre Atividades Imobiliárias).
class DimobTab extends StatefulWidget {
  const DimobTab({super.key});

  @override
  State<DimobTab> createState() => _DimobTabState();
}

class _DimobTabState extends State<DimobTab> {
  final _vm = sl<DimobViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _editarDeclarante() async {
    final d = await mostrarDeclaranteDialog(
      context,
      _vm.declaracao!.declarante,
    );
    if (d == null) return;
    final ok = await _vm.salvarDeclarante(d);
    if (mounted && !ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível salvar.');
    }
  }

  Future<void> _gerar() async {
    final d = _vm.declaracao!;
    if (!d.pronta) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.navy,
          title: const Text('Há erros de preenchimento'),
          content: Text(
            '${d.erros} erro(s) precisam ser corrigidos antes de transmitir a DIMOB. '
            'Gerar a conferência mesmo assim?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Corrigir antes'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gerar mesmo assim'),
            ),
          ],
        ),
      );
      if (seguir != true) return;
    }
    final ok = await _vm.gerarConferencia();
    if (mounted && !ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível gerar.');
    }
  }

  Future<void> _copiarCsv() async {
    await Clipboard.setData(ClipboardData(text: _vm.csv));
    if (mounted) mostrarMensagem(context, 'Dados da DIMOB copiados (CSV).');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final d = _vm.declaracao;
        if (!_vm.carregado || d == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CompetenciaSelector(
                  value: DateTime(_vm.ano),
                  anual: true,
                  onChanged: (x) => _vm.mudarAno(x.year),
                ),
                Text(
                  'Ano-calendário ${_vm.ano} • entrega até ${formatDate(_vm.prazo)}',
                  style: TextStyle(
                    color: _vm.atrasada ? Colors.redAccent : Colors.white70,
                    fontWeight: _vm.atrasada
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _status(d),
            const SizedBox(height: 12),
            _declarante(d),
            if (d.pendencias.isNotEmpty) _pendencias(d),
            if (d.semMovimento)
              const EmptyState(
                icon: Icons.assignment_turned_in_outlined,
                message:
                    'Sem contratos de locação ou venda neste ano.\nA DIMOB seria entregue sem movimento.',
              ),
            if (d.locacoes.isNotEmpty) _secaoLocacoes(d),
            if (d.vendas.isNotEmpty) _secaoVendas(d),
            const SizedBox(height: 8),
            const Text(
              'Esta tela reúne e confere os dados. A transmissão é feita pelo programa DIMOB da Receita Federal '
              '(o arquivo oficial será gerado na integração).',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _status(DeclaracaoDimob d) {
    final cor = d.pronta ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.blue.withValues(alpha: 0.5), AppColors.navy],
        ),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                d.pronta ? Icons.check_circle_outline : Icons.error_outline,
                color: cor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  d.pronta
                      ? 'Pronta para gerar${d.avisos > 0 ? ' (${d.avisos} aviso(s) para conferir)' : ''}'
                      : '${d.erros} erro(s) de preenchimento a corrigir',
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ResumoValores(
            itens: [
              (
                rotulo: '${d.locacoes.length} locação(ões)',
                valor: formatMoney(d.totalAluguel),
                cor: AppColors.gold,
              ),
              (
                rotulo: 'Comissão',
                valor: formatMoney(d.totalComissao),
                cor: AppColors.goldLight,
              ),
              (
                rotulo: 'IRRF retido',
                valor: formatMoney(d.totalIrrf),
                cor: AppColors.blueGlow,
              ),
              (
                rotulo: '${d.vendas.length} venda(s)',
                valor: formatMoney(d.totalVendas),
                cor: Colors.greenAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _vm.ocupado ? null : _gerar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navyDark,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Gerar DIMOB (conferência em PDF)'),
              ),
              OutlinedButton.icon(
                onPressed: _copiarCsv,
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copiar dados (CSV)'),
              ),
            ],
          ),
          if (_vm.geradaEm != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Conferência gerada em ${formatDateTime(_vm.geradaEm)}.',
                style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _declarante(DeclaracaoDimob d) {
    final dec = d.declarante;
    return FormSection(
      title: 'Declarante',
      icon: Icons.business_outlined,
      children: [
        Text(
          dec.nome,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        Text(
          'CNPJ/CPF: ${dec.documento.isEmpty ? 'não informado' : dec.documento}'
          ' • Responsável: ${dec.responsavelNome.isEmpty ? '—' : dec.responsavelNome}'
          '${dec.responsavelCpf.isEmpty ? '' : ' (${dec.responsavelCpf})'}',
          style: const TextStyle(color: Colors.white70),
        ),
        Text(
          dec.retificadora
              ? 'Retificadora • recibo ${dec.numeroRecibo}'
              : 'Declaração original',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _editarDeclarante,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar declarante'),
          ),
        ),
      ],
    );
  }

  Widget _pendencias(DeclaracaoDimob d) {
    return FormSection(
      title: 'Pendências (${d.erros} erro(s), ${d.avisos} aviso(s))',
      icon: Icons.fact_check_outlined,
      children: [
        for (final p in d.pendencias)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                p.gravidade == GravidadePendencia.erro
                    ? Icons.error_outline
                    : Icons.warning_amber_rounded,
                size: 18,
                color: p.gravidade == GravidadePendencia.erro
                    ? Colors.redAccent
                    : Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white),
                    children: [
                      TextSpan(
                        text: '${p.referencia}: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                      TextSpan(text: p.mensagem),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _secaoLocacoes(DeclaracaoDimob d) {
    return FormSection(
      title: 'Locações (${d.locacoes.length})',
      icon: Icons.key_outlined,
      children: [
        for (final l in d.locacoes)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '${l.numero} • ${l.imovel.descricao}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Locatário: ${l.locatario.nome.isEmpty ? '—' : l.locatario.nome} • '
                'aluguel ${formatMoney(l.totalAluguel)} • comissão ${formatMoney(l.totalComissao)}'
                '${l.totalIrrf > 0 ? ' • IRRF ${formatMoney(l.totalIrrf)}' : ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              children: [
                _dados('Contrato de', formatDate(l.dataContrato)),
                _dados(
                  'Imóvel ${l.imovel.tipo.toLowerCase()}',
                  l.imovel.endereco,
                ),
                _dados('Locador(es)', _partes(l.locadores)),
                _dados('Locatário', _partes([l.locatario])),
                const SizedBox(height: 8),
                _tabelaMeses({
                  'Aluguel': l.aluguel,
                  'Encargos': l.encargos,
                  'Comissão': l.comissao,
                  'IRRF': l.irrf,
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _secaoVendas(DeclaracaoDimob d) {
    return FormSection(
      title: 'Compra e venda (${d.vendas.length})',
      icon: Icons.sell_outlined,
      children: [
        for (final v in d.vendas)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                '${v.numero} • ${v.imovel.descricao}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Operação ${formatMoney(v.valorOperacao)} • recebido no ano ${formatMoney(v.totalRecebido)}'
                '${v.presumido ? ' (presumido)' : ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              children: [
                _dados('Contrato de', formatDate(v.dataContrato)),
                _dados(
                  'Imóvel ${v.imovel.tipo.toLowerCase()}',
                  v.imovel.endereco,
                ),
                _dados('Vendedor(es)', _partes(v.vendedores)),
                _dados('Comprador(es)', _partes(v.compradores)),
                const SizedBox(height: 8),
                _tabelaMeses({'Recebido': v.recebido}),
              ],
            ),
          ),
      ],
    );
  }

  String _partes(List<ParteDimob> p) => p
      .map(
        (x) =>
            '${x.nome.isEmpty ? '—' : x.nome} (${x.documento.isEmpty ? 'sem CPF/CNPJ' : x.documento}'
            '${x.percentual == null ? '' : ' • ${decimalToText(x.percentual)}%'})',
      )
      .join('; ');

  Widget _dados(String rotulo, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$rotulo: ${valor.isEmpty ? '—' : valor}',
        style: const TextStyle(color: Colors.white70, fontSize: 13),
      ),
    ),
  );

  Widget _tabelaMeses(Map<String, List<double>> linhas) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 32,
        dataRowMinHeight: 30,
        dataRowMaxHeight: 34,
        headingTextStyle: const TextStyle(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        dataTextStyle: const TextStyle(fontSize: 12),
        columns: [
          const DataColumn(label: Text('')),
          for (final m in _mesesAbrev)
            DataColumn(label: Text(m), numeric: true),
          const DataColumn(label: Text('Total'), numeric: true),
        ],
        rows: [
          for (final e in linhas.entries)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    e.key,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                for (final v in e.value)
                  DataCell(Text(v == 0 ? '—' : formatMoney(v))),
                DataCell(
                  Text(
                    formatMoney(e.value.fold<double>(0, (s, v) => s + v)),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldLight,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
