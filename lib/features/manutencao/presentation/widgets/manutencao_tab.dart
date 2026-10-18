import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/manutencao.dart';
import '../pages/manutencao_detalhe_page.dart';
import '../viewmodels/manutencoes_viewmodel.dart';
import 'manutencao_dialogs.dart';
import 'manutencao_widgets.dart';

/// Pauta de manutenção dos imóveis do módulo, com o diário de cada item.
class ManutencaoTab extends StatefulWidget {
  const ManutencaoTab({super.key, required this.contexto});

  final ContextoManutencao contexto;

  @override
  State<ManutencaoTab> createState() => _ManutencaoTabState();
}

class _ManutencaoTabState extends State<ManutencaoTab> {
  late final _vm = sl<ManutencoesViewModel>(param1: widget.contexto);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _nova() {
    if (_vm.semImoveis) {
      mostrarMensagem(
        context,
        'Cadastre um imóvel em Cadastros e CRM primeiro.',
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => ManutencaoDialog(vm: _vm),
    );
  }

  void _detalhar(Manutencao m) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ManutencaoDetalhePage(vm: _vm, manutencaoId: m.id),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.handyman_outlined,
        label: 'Nova manutenção',
        onPressed: _nova,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.filtradas;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              const Text(
                'Monte a pauta de manutenção dos imóveis e registre no diário '
                'cada serviço executado: profissional, material, mão de obra e '
                'taxa de manutenção.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ResumoValores(
                itens: [
                  (
                    rotulo: 'Pendentes',
                    valor: '${_vm.quantidade(StatusManutencao.pendente)}',
                    cor: corStatus(StatusManutencao.pendente),
                  ),
                  (
                    rotulo: 'Em andamento',
                    valor: '${_vm.quantidade(StatusManutencao.emAndamento)}',
                    cor: corStatus(StatusManutencao.emAndamento),
                  ),
                  (
                    rotulo: 'Concluídas',
                    valor: '${_vm.quantidade(StatusManutencao.concluida)}',
                    cor: corStatus(StatusManutencao.concluida),
                  ),
                  (
                    rotulo: 'Total gasto',
                    valor: formatMoney(_vm.totalGasto),
                    cor: AppColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppDropdown<String?>(
                label: 'Imóvel',
                value: _vm.imovelId,
                items: [null, ..._vm.imoveis.map((i) => i.id)],
                labelOf: (id) =>
                    id == null ? 'Todos os imóveis' : _vm.descricaoImovel(id),
                onChanged: _vm.filtrarImovel,
              ),
              FiltroChips<StatusManutencao>(
                opcoes: StatusManutencao.values,
                selecionado: _vm.status,
                labelOf: (s) => s.label,
                onChanged: _vm.filtrarStatus,
                padding: const EdgeInsets.only(top: 8),
              ),
              FiltroChips<TipoManutencao>(
                opcoes: TipoManutencao.values,
                selecionado: _vm.tipo,
                labelOf: (t) => t.label,
                onChanged: _vm.filtrarTipo,
                padding: EdgeInsets.zero,
              ),
              if (_vm.carregado && lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: EmptyState(
                    icon: Icons.handyman_outlined,
                    message:
                        'Nenhuma manutenção na pauta.\n'
                        'Toque em "Nova manutenção" para incluir.',
                  ),
                ),
              for (final m in lista) _card(m),
            ],
          );
        },
      ),
    );
  }

  Widget _card(Manutencao m) {
    final atrasada = m.atrasadaEm(_vm.hoje);
    return CardPadrao(
      onTap: () => _detalhar(m),
      borda: corStatus(m.status),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.gold.withValues(alpha: 0.15),
            child: Icon(iconeTipo(m.tipo), color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _vm.descricaoImovel(m.imovelId),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (m.doInquilino)
                      const GoldChip(
                        'Chamado do inquilino',
                        color: Colors.lightBlueAccent,
                      ),
                    GoldChip(m.tipoLabel),
                    GoldChip(m.status.label, color: corStatus(m.status)),
                    if (m.dataPrevista != null)
                      GoldChip(
                        '${atrasada ? 'Atrasada • ' : 'Prevista '}'
                        '${formatDate(m.dataPrevista)}',
                        color: atrasada ? Colors.redAccent : Colors.white70,
                      ),
                    GoldChip(
                      '${m.diario.length} registro(s) no diário',
                      color: Colors.white70,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMoney(m.total),
            style: const TextStyle(
              color: AppColors.goldLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
