import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../domain/entities/manutencao.dart';
import '../viewmodels/manutencoes_viewmodel.dart';
import '../widgets/manutencao_dialogs.dart';
import '../widgets/manutencao_widgets.dart';
import '../../../portal_inquilino/presentation/widgets/anexos_chamado.dart';

/// Dados da manutenção e o diário de serviços executados.
class ManutencaoDetalhePage extends StatelessWidget {
  const ManutencaoDetalhePage({
    super.key,
    required this.vm,
    required this.manutencaoId,
  });

  final ManutencoesViewModel vm;
  final String manutencaoId;

  void _registrar(BuildContext context, [RegistroDiario? r]) =>
      showDialog<void>(
        context: context,
        builder: (_) => RegistroDiarioDialog(
          vm: vm,
          manutencaoId: manutencaoId,
          registro: r,
        ),
      );

  Future<void> _imprimir(BuildContext context, Manutencao m) async {
    final ok = await vm.imprimirDiario(m.id);
    if (!ok && context.mounted) {
      mostrarMensagem(context, vm.erro ?? 'Não foi possível gerar o PDF.');
    }
  }

  Future<void> _excluir(BuildContext context, Manutencao m) async {
    if (!await confirmDelete(
      context,
      'Excluir a manutenção "${m.descricao}" e todo o seu diário?',
    )) {
      return;
    }
    await vm.remover(m.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final m = vm.porId(manutencaoId);
        if (m == null) return const Scaffold(body: SizedBox.shrink());
        return Scaffold(
          backgroundColor: AppColors.navyDark,
          appBar: AppBar(
            backgroundColor: AppColors.navyDark,
            title: Text('Manutenção • ${m.tipoLabel}'),
            actions: [
              IconButton(
                tooltip: 'Gerar PDF do diário',
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () => _imprimir(context, m),
              ),
              IconButton(
                tooltip: 'Editar pauta',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ManutencaoDialog(vm: vm, manutencao: m),
                ),
              ),
              IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _excluir(context, m),
              ),
            ],
          ),
          floatingActionButton: goldFab(
            icon: Icons.edit_note,
            label: 'Registrar no diário',
            onPressed: () => _registrar(context),
          ),
          body: FundoMarca(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    _cabecalho(m),
                    AnexosChamado(manutencaoId: m.id),
                    const SizedBox(height: 12),
                    ResumoValores(
                      itens: [
                        (
                          rotulo: 'Valor total dos serviços',
                          valor: formatMoney(m.totalServicos),
                          cor: Colors.white,
                        ),
                        (
                          rotulo: 'Taxas de manutenção',
                          valor: formatMoney(m.totalTaxas),
                          cor: AppColors.goldLight,
                        ),
                        (
                          rotulo: 'Total',
                          valor: formatMoney(m.total),
                          cor: AppColors.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 10),
                        Text('Diário', style: estiloTitulo(tamanho: 22)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (m.diario.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: EmptyState(
                          icon: Icons.edit_note,
                          message:
                              'Nenhum registro no diário.\n'
                              'Registre os serviços conforme forem executados.',
                        ),
                      ),
                    for (final r in m.diarioOrdenado) _registro(context, r),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cabecalho(Manutencao m) {
    final atrasada = m.atrasadaEm(vm.hoje);
    return CardPadrao(
      borda: corStatus(m.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                child: Icon(iconeTipo(m.tipo), color: AppColors.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.descricaoImovel(m.imovelId),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Manutenção • ${m.contexto.label} • aberta em '
                      '${formatDate(m.criadaEm)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(m.descricao, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (m.doInquilino)
                const GoldChip(
                  'Chamado do inquilino (portal)',
                  color: Colors.lightBlueAccent,
                ),
              GoldChip(m.tipoLabel),
              if (m.dataPrevista != null)
                GoldChip(
                  '${atrasada ? 'Atrasada • ' : 'Prevista '}'
                  '${formatDate(m.dataPrevista)}',
                  color: atrasada ? Colors.redAccent : Colors.white70,
                ),
              const SizedBox(width: 8),
              SegmentedButton<StatusManutencao>(
                segments: [
                  for (final s in StatusManutencao.values)
                    ButtonSegment(value: s, label: Text(s.label)),
                ],
                selected: {m.status},
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: corStatus(m.status),
                  selectedForegroundColor: AppColors.navyDark,
                  foregroundColor: Colors.white,
                ),
                onSelectionChanged: (s) => vm.alterarStatus(m.id, s.first),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _registro(BuildContext context, RegistroDiario r) {
    Widget valor(String rotulo, double v, {Color cor = Colors.white}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        Text(
          formatMoney(v),
          style: TextStyle(color: cor, fontWeight: FontWeight.w700),
        ),
      ],
    );
    return CardPadrao(
      onTap: () => _registrar(context, r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 18, color: AppColors.gold),
              const SizedBox(width: 6),
              Text(
                formatDate(r.data),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.engineering_outlined,
                size: 18,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.profissional,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              IconButton(
                tooltip: 'Excluir registro',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () async {
                  if (await confirmDelete(context, 'Excluir este registro?')) {
                    await vm.removerRegistro(manutencaoId, r.id);
                  }
                },
              ),
            ],
          ),
          Text(r.servico, style: const TextStyle(fontSize: 15)),
          if (r.material.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Material: ${r.material}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 28,
            runSpacing: 8,
            children: [
              valor('Material', r.valorMaterial),
              valor('Mão de obra', r.valorMaoDeObra),
              valor('Valor total dos serviços', r.valorServicos),
              valor(
                'Taxa de manutenção',
                r.valorTaxa,
                cor: AppColors.goldLight,
              ),
              valor('Total', r.valorTotal, cor: AppColors.gold),
            ],
          ),
        ],
      ),
    );
  }
}
