import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/pagamento_dialog.dart';
import '../../domain/entities/parcela.dart';
import '../../domain/entities/venda.dart';
import '../../domain/entities/venda_enums.dart';
import '../viewmodels/venda_detalhe_viewmodel.dart';
import '../widgets/escolher_modelo.dart';
import 'venda_form_page.dart';

class VendaDetalhePage extends StatefulWidget {
  const VendaDetalhePage({super.key, required this.vendaId});

  final String vendaId;

  @override
  State<VendaDetalhePage> createState() => _VendaDetalhePageState();
}

class _VendaDetalhePageState extends State<VendaDetalhePage> {
  late final _vm = sl<VendaDetalheViewModel>(param1: widget.vendaId);

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

  Future<void> _pagar(Parcela p) async {
    final r = await mostrarPagamentoDialog(
      context,
      valor: p.valor,
      vencimento: p.vencimento,
      hoje: _vm.hoje,
      simular: (d) => _vm.simular(p, d),
      rotuloValor: 'Valor da parcela',
    );
    if (r != null) {
      await _acao(() => _vm.pagar(p, r.data, r.valor), 'Pagamento registrado.');
    }
  }

  Future<void> _contrato() async {
    final m = await escolherModelo(context, _vm.modelos);
    if (m != null) await _acao(() => _vm.imprimirContrato(m));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final v = _vm.venda;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.navy,
            foregroundColor: AppColors.gold,
            title: Text(v == null ? 'Venda' : 'Venda ${v.numero}'),
            actions: [
              if (v != null)
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => VendaFormPage(venda: v),
                    ),
                  ),
                ),
            ],
          ),
          body: !_vm.carregado
              ? const SizedBox.shrink()
              : v == null
              ? const EmptyState(
                  icon: Icons.sell_outlined,
                  message: 'Venda não encontrada.',
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _resumo(v),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _botao(
                              Icons.description_outlined,
                              'Contrato',
                              _contrato,
                            ),
                            if (v.financiamentoProprio) ...[
                              _botao(
                                Icons.receipt_long_outlined,
                                'Carnê',
                                () => _acao(_vm.imprimirCarne),
                              ),
                              _botao(
                                Icons.edit_document,
                                'Notas promissórias',
                                () => _acao(_vm.imprimirPromissorias),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (v.financiamentoProprio) _parcelas(),
                        _comissao(v),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _botao(IconData icon, String label, VoidCallback onPressed) =>
      FilledButton.icon(
        onPressed: _vm.ocupado ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navyDark,
        ),
        icon: Icon(icon),
        label: Text(label),
      );

  Widget _resumo(Venda v) {
    final r = _vm.resumo;
    final i = _vm.imovel;
    return FormSection(
      title: i == null ? 'Imóvel removido' : '${i.codigo} • ${i.titulo}',
      icon: Icons.home_work_outlined,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            GoldChip(
              v.status.label,
              color: v.status == StatusVenda.quitada
                  ? Colors.greenAccent
                  : AppColors.gold,
            ),
            GoldChip(v.formaPagamento.label, color: AppColors.blueGlow),
            if (v.plano != null && v.financiamentoProprio)
              GoldChip(
                '${v.plano!.numeroParcelas}x • ${v.plano!.sistema.label}'
                ' • ${decimalToText(v.plano!.taxaJurosMes)}% a.m.',
              ),
          ],
        ),
        Text('Compradores: ${v.compradores.map(_vm.nome).join(', ')}'),
        Text(
          'Vendedores: ${v.vendedores.map((p) => '${_vm.nome(p.contatoId)} (${decimalToText(p.percentual)}%)').join(', ')}',
        ),
        Text(
          'Data da venda: ${formatDate(v.dataVenda)}',
          style: const TextStyle(color: Colors.white70),
        ),
        ResumoValores(
          itens: [
            (
              rotulo: 'Valor da venda',
              valor: formatMoney(v.valorVenda),
              cor: AppColors.gold,
            ),
            if (v.financiamentoProprio) ...[
              (
                rotulo: 'Recebido',
                valor: formatMoney(r.totalRecebido),
                cor: Colors.greenAccent,
              ),
              (
                rotulo: 'Saldo devedor',
                valor: formatMoney(r.saldoDevedor),
                cor: Colors.orangeAccent,
              ),
            ] else
              (
                rotulo: 'Entrada',
                valor: formatMoney(v.valorEntrada),
                cor: Colors.greenAccent,
              ),
          ],
        ),
        if (v.financiamentoProprio)
          Text(
            '${r.quantidadePagas} de ${r.quantidade} parcelas pagas'
            '${r.proxima == null ? '' : ' • próxima: ${r.proxima!.rotulo} em ${formatDate(r.proxima!.vencimento)}'}'
            ' • saldo devedor = valor para quitação hoje, sem juros futuros',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
      ],
    );
  }

  Widget _parcelas() {
    final hoje = _vm.hoje;
    return FormSection(
      title: 'Parcelas',
      icon: Icons.calendar_month_outlined,
      children: [
        for (final p in _vm.parcelas)
          Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  p.rotulo,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatDate(p.vencimento)} • ${formatMoney(p.valor)}',
                    ),
                    Text(
                      p.status == StatusParcela.paga
                          ? 'Pago ${formatMoney(p.valorPago)} em ${formatDate(p.dataPagamento)}'
                          : 'Amortização ${formatMoney(p.amortizacao)} + juros ${formatMoney(p.juros)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(p, hoje),
              if (p.status == StatusParcela.aberta)
                IconButton(
                  tooltip: 'Registrar pagamento',
                  icon: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.gold,
                  ),
                  onPressed: () => _pagar(p),
                )
              else if (p.status == StatusParcela.paga)
                IconButton(
                  tooltip: 'Estornar pagamento',
                  icon: const Icon(Icons.undo),
                  onPressed: () =>
                      _acao(() => _vm.estornar(p), 'Pagamento estornado.'),
                ),
            ],
          ),
      ],
    );
  }

  Widget _comissao(Venda v) => FormSection(
    title:
        'Comissão: ${decimalToText(v.comissaoPercentual)}% = ${formatMoney(v.valorComissao)}',
    icon: Icons.percent,
    children: [
      if (v.comissaoPercentual <= 0) const Text('Venda sem comissão.'),
      if (v.comissaoPercentual > 0)
        for (var i = 0; i < v.corretores.length; i++)
          Row(
            children: [
              Checkbox(
                value: v.corretores[i].pagaEm != null,
                activeColor: AppColors.gold,
                checkColor: AppColors.navyDark,
                onChanged: (x) =>
                    _acao(() => _vm.marcarComissao(i, x ?? false)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_vm.nome(v.corretores[i].contatoId)} '
                      '(${decimalToText(v.corretores[i].percentual)}%)',
                    ),
                    Text(
                      v.corretores[i].pagaEm == null
                          ? 'Pendente'
                          : 'Paga em ${formatDate(v.corretores[i].pagaEm)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: v.corretores[i].pagaEm == null
                            ? Colors.orangeAccent
                            : Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(v.valorComissao * v.corretores[i].percentual / 100),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(
                tooltip: 'Recibo de comissão',
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.goldLight,
                ),
                onPressed: () => _acao(() => _vm.imprimirReciboComissao(i)),
              ),
            ],
          ),
    ],
  );
}

Widget _statusChip(Parcela p, DateTime hoje) {
  final (rotulo, cor) = switch (p.status) {
    StatusParcela.paga => ('Paga', Colors.greenAccent),
    StatusParcela.cancelada => ('Cancelada', Colors.grey),
    StatusParcela.aberta when p.atrasada(hoje) => (
      'Atrasada',
      Colors.redAccent,
    ),
    StatusParcela.aberta => ('Em aberto', Colors.orangeAccent),
  };
  return GoldChip(rotulo, color: cor);
}

/// Usado também pela aba de recebimentos.
Widget statusParcelaChip(Parcela p, DateTime hoje) => _statusChip(p, hoje);
