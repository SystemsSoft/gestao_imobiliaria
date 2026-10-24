import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/midia_anexo.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/imovel.dart';
import '../pages/imovel_form_page.dart';
import '../viewmodels/imoveis_viewmodel.dart';

class ImoveisTab extends StatefulWidget {
  const ImoveisTab({super.key});

  @override
  State<ImoveisTab> createState() => _ImoveisTabState();
}

class _ImoveisTabState extends State<ImoveisTab> {
  final _vm = sl<ImoveisViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrir([Imovel? imovel]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ImovelFormPage(imovel: imovel)),
    );
  }

  Future<void> _excluir(Imovel i) async {
    if (await confirmDelete(context, 'Excluir o imóvel "${i.titulo}"?')) {
      await _vm.remover(i.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.add_home_outlined,
        label: 'Novo imóvel',
        onPressed: _abrir,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.filtrados;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: CampoBusca(
                  hint: 'Buscar por código, título, endereço...',
                  onChanged: _vm.buscar,
                ),
              ),
              FiltroChips<StatusImovel>(
                opcoes: StatusImovel.values,
                selecionado: _vm.status,
                labelOf: (s) => s.label,
                onChanged: _vm.filtrarStatus,
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              Expanded(
                child: !_vm.carregado
                    ? const SizedBox.shrink()
                    : lista.isEmpty
                    ? EmptyState(
                        icon: Icons.apartment,
                        message: _vm.semCadastro
                            ? 'Nenhum imóvel cadastrado.\nToque em "Novo imóvel" para começar.'
                            : 'Nenhum imóvel encontrado com esse filtro.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                        itemCount: lista.length,
                        itemBuilder: (_, i) => _ImovelCard(
                          imovel: lista[i],
                          onTap: () => _abrir(lista[i]),
                          onDelete: () => _excluir(lista[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImovelCard extends StatelessWidget {
  const _ImovelCard({
    required this.imovel,
    required this.onTap,
    required this.onDelete,
  });

  final Imovel imovel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color get _statusColor => switch (imovel.status) {
    StatusImovel.disponivel => Colors.greenAccent,
    StatusImovel.reservado => Colors.orangeAccent,
    StatusImovel.alugado || StatusImovel.vendido => AppColors.blueGlow,
    StatusImovel.inativo => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final foto = imovel.primeiraFoto;
    final valores = [
      if (imovel.finalidades.contains(Finalidade.venda) &&
          imovel.valorVenda != null)
        'Venda ${formatMoney(imovel.valorVenda)}',
      if (imovel.finalidades.contains(Finalidade.locacao) &&
          imovel.valorLocacao != null)
        'Aluguel ${formatMoney(imovel.valorLocacao)}',
      if (imovel.finalidades.contains(Finalidade.temporada) &&
          imovel.valorTemporada != null)
        'Diária ${formatMoney(imovel.valorTemporada)}',
    ];
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: foto == null
                      ? const _FotoPlaceholder()
                      : ImagemAnexo(
                          foto,
                          alternativa: const _FotoPlaceholder(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          imovel.codigo,
                          style: TextStyle(
                            color: AppColors.gold.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GoldChip(imovel.status.label, color: _statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      imovel.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (imovel.enderecoResumo.isNotEmpty)
                      Text(
                        imovel.enderecoResumo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        imovel.tipo.label,
                        if (imovel.quartos > 0) '${imovel.quartos} qto',
                        if (imovel.suites > 0) '${imovel.suites} suíte',
                        if (imovel.vagas > 0) '${imovel.vagas} vaga',
                        if (imovel.areaUtil != null)
                          '${decimalToText(imovel.areaUtil)} m²',
                      ].join(' • '),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (valores.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          valores.join('  |  '),
                          style: TextStyle(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.navy,
                onSelected: (v) => v == 'edit' ? onTap() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'del', child: Text('Excluir')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FotoPlaceholder extends StatelessWidget {
  const _FotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blue.withValues(alpha: 0.4),
      child: Icon(Icons.apartment, color: AppColors.gold, size: 36),
    );
  }
}
