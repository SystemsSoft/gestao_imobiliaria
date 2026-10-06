import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/contrato_locacao.dart';
import '../../domain/entities/locacao_enums.dart';
import '../../domain/entities/modelo_contrato.dart';
import '../pages/contrato_form_page.dart';
import '../viewmodels/contratos_viewmodel.dart';

class ContratosTab extends StatefulWidget {
  const ContratosTab({super.key});

  @override
  State<ContratosTab> createState() => _ContratosTabState();
}

class _ContratosTabState extends State<ContratosTab> {
  final _vm = sl<ContratosViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrir([ContratoLocacao? c]) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ContratoFormPage(contrato: c)),
  );

  Future<void> _excluir(ContratoLocacao c) async {
    final ok = await confirmDelete(
      context,
      'Excluir o contrato ${c.numero}? As despesas e cobranças dele também '
      'serão excluídas.',
    );
    if (ok && !await _vm.remover(c.id) && mounted) {
      mostrarMensagem(context, _vm.erro!);
    }
  }

  Future<void> _imprimir(ContratoLocacao c) async {
    final modelos = _vm.modelos;
    final modelo = modelos.length == 1
        ? modelos.first
        : await showDialog<ModeloContrato>(
            context: context,
            builder: (ctx) => SimpleDialog(
              backgroundColor: AppColors.navy,
              title: const Text('Escolha o modelo'),
              children: [
                for (final m in modelos)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, m),
                    child: Text(m.nome),
                  ),
              ],
            ),
          );
    if (modelo == null) return;
    if (!await _vm.imprimir(c, modelo) && mounted) {
      mostrarMensagem(context, _vm.erro ?? 'Falha ao gerar o contrato.');
    }
  }

  Color _cor(StatusContrato s) => switch (s) {
    StatusContrato.ativo => Colors.greenAccent,
    StatusContrato.encerrado => Colors.grey,
    StatusContrato.rescindido => Colors.orangeAccent,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.note_add_outlined,
        label: 'Novo contrato',
        onPressed: _abrir,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.filtrados;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  onChanged: _vm.buscar,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por número, locatário ou imóvel...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              FiltroChips<StatusContrato>(
                opcoes: StatusContrato.values,
                selecionado: _vm.status,
                labelOf: (s) => s.label,
                onChanged: _vm.filtrarStatus,
              ),
              Expanded(
                child: !_vm.carregado
                    ? const SizedBox.shrink()
                    : lista.isEmpty
                    ? EmptyState(
                        icon: Icons.handshake_outlined,
                        message: _vm.semCadastro
                            ? 'Nenhum contrato de locação.\nCadastre imóveis e contatos em "Cadastros e CRM" e crie o contrato aqui.'
                            : 'Nenhum contrato encontrado com esse filtro.',
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

  Widget _card(ContratoLocacao c) {
    final imovel = _vm.imovel(c.imovelId);
    return CardPadrao(
      onTap: () => _abrir(c),
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
                      c.numero,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GoldChip(c.status.label, color: _cor(c.status)),
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
                  'Locatário: ${_vm.nomeContato(c.locatarioId)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Locador(es): ${c.beneficiarios.map((b) => '${_vm.nomeContato(b.contatoId)} (${decimalToText(b.percentual)}%)').join(', ')}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatMoney(c.valorAluguel)} • vence dia ${c.diaVencimento} • '
                  '${formatDate(c.dataInicio)} a ${formatDate(c.dataFim)}',
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
            onSelected: (v) => switch (v) {
              'edit' => _abrir(c),
              'print' => _imprimir(c),
              _ => _excluir(c),
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'print', child: Text('Imprimir contrato')),
              PopupMenuItem(value: 'del', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
