import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/venda.dart';
import '../../domain/entities/venda_enums.dart';
import '../pages/venda_detalhe_page.dart';
import '../pages/venda_form_page.dart';
import '../viewmodels/vendas_viewmodel.dart';
import 'escolher_modelo.dart';

class VendasTab extends StatefulWidget {
  const VendasTab({super.key});

  @override
  State<VendasTab> createState() => _VendasTabState();
}

class _VendasTabState extends State<VendasTab> {
  final _vm = sl<VendasViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _ir(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _contrato(Venda v) async {
    final m = await escolherModelo(context, _vm.modelos);
    if (m != null && !await _vm.imprimir(v, m) && mounted) {
      mostrarMensagem(context, _vm.erro ?? 'Falha ao gerar o contrato.');
    }
  }

  Future<void> _excluir(Venda v) async {
    if (await confirmDelete(
      context,
      'Excluir a venda ${v.numero} e suas parcelas?',
    )) {
      await _vm.remover(v.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.add_business_outlined,
        label: 'Nova venda',
        onPressed: () => _ir(const VendaFormPage()),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.filtradas;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: _vm.buscar,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por número, comprador ou imóvel...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              FiltroChips<StatusVenda>(
                opcoes: StatusVenda.values,
                selecionado: _vm.status,
                labelOf: (s) => s.label,
                onChanged: _vm.filtrarStatus,
              ),
              Expanded(
                child: !_vm.carregado
                    ? const SizedBox.shrink()
                    : lista.isEmpty
                    ? EmptyState(
                        icon: Icons.sell_outlined,
                        message: _vm.semCadastro
                            ? 'Nenhuma venda registrada.\nCadastre o imóvel e os contatos em "Cadastros e CRM" e registre a venda aqui.'
                            : 'Nenhuma venda encontrada com esse filtro.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                        itemCount: lista.length,
                        itemBuilder: (_, i) => _card(lista[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card(Venda v) {
    final imovel = _vm.imovel(v.imovelId);
    final r = _vm.resumo(v);
    final cor = switch (v.status) {
      StatusVenda.ativa => AppColors.gold,
      StatusVenda.quitada => Colors.greenAccent,
      StatusVenda.distratada => Colors.grey,
    };
    return CardPadrao(
      onTap: () => _ir(VendaDetalhePage(vendaId: v.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      v.numero,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GoldChip(v.status.label, color: cor),
                    const SizedBox(width: 6),
                    GoldChip(v.formaPagamento.label, color: AppColors.blueGlow),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  imovel == null
                      ? 'Imóvel removido'
                      : '${imovel.codigo} • ${imovel.titulo}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Comprador(es): ${_vm.nomes(v.compradores)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatMoney(v.valorVenda)} • ${formatDate(v.dataVenda)}'
                  '${v.financiamentoProprio ? ' • ${r.quantidadePagas}/${r.quantidade} pagas • saldo ${formatMoney(r.saldoDevedor)}' : ''}',
                  style: const TextStyle(
                    color: AppColors.goldLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.navy,
            onSelected: (op) => switch (op) {
              'ver' => _ir(VendaDetalhePage(vendaId: v.id)),
              'edit' => _ir(VendaFormPage(venda: v)),
              'contrato' => _contrato(v),
              _ => _excluir(v),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'ver', child: Text('Parcelas e documentos')),
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(
                value: 'contrato',
                child: Text('Imprimir contrato'),
              ),
              PopupMenuItem(value: 'del', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
