import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../domain/entities/auditoria.dart';
import '../pages/auditorias_page.dart';
import '../viewmodels/auditoria_viewmodels.dart';
import 'auditoria_visual.dart';

/// Auditoria automática: o que está fora do esperado em cada contrato
/// (financeiro, contrato, documentos, imóvel e cadastro).
class PendenciasTab extends StatefulWidget {
  const PendenciasTab({super.key});

  @override
  State<PendenciasTab> createState() => _PendenciasTabState();
}

class _PendenciasTabState extends State<PendenciasTab> {
  final _vm = sl<PendenciasViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final lista = _vm.lista;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: CampoBusca(
                      hint: 'Buscar por proprietário, imóvel ou contrato...',
                      onChanged: _vm.buscar,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Recalcular',
                    icon: const Icon(Icons.refresh),
                    onPressed: _vm.ocupado ? null : _vm.recarregar,
                  ),
                ],
              ),
            ),
            FiltroChips<Gravidade>(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              opcoes: Gravidade.values,
              selecionado: _vm.gravidade,
              labelOf: (g) => '${g.label} (${_vm.contar(g)})',
              onChanged: _vm.filtrarGravidade,
            ),
            FiltroChips<AreaPendencia>(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              opcoes: AreaPendencia.values,
              selecionado: _vm.area,
              labelOf: (a) => a.label,
              onChanged: _vm.filtrarArea,
            ),
            if (_vm.erro != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _vm.erro!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Expanded(
              child: !_vm.carregado
                  ? const Center(child: CircularProgressIndicator())
                  : lista.isEmpty
                  ? const EmptyState(
                      icon: Icons.verified_outlined,
                      message: 'Nenhuma pendência. Carteira em dia!',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 48),
                      itemCount: lista.length,
                      itemBuilder: (_, i) => _card(lista[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _card(Pendencia p) {
    final proprietario = _vm.contatos[p.proprietarioId]?.nome;
    final contrato = _vm.contratos[p.contratoId]?.numero;
    return CardPadrao(
      borda: p.gravidade.cor,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: p.gravidade.cor.withValues(alpha: 0.15),
            child: Icon(p.area.icone, color: p.gravidade.cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.titulo,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (p.detalhe.isNotEmpty)
                  Text(
                    p.detalhe,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                Text(
                  [
                    ?proprietario,
                    if (p.imovelId != null) _vm.nomeImovel(p.imovelId),
                    ?contrato,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          GoldChip(p.area.label, color: p.gravidade.cor),
          if (p.area == AreaPendencia.imovel && p.imovelId != null)
            IconButton(
              tooltip: 'Agendar auditoria',
              color: AppColors.gold,
              icon: const Icon(Icons.add_task),
              onPressed: () async {
                await abrirNovaAuditoria(
                  context,
                  imovelId: p.imovelId!,
                  contratoId: p.contratoId,
                );
                await _vm.recarregar();
              },
            ),
        ],
      ),
    );
  }
}
