import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../../core/widgets/visual_marca.dart';
import '../../domain/entities/auditoria.dart';
import '../pages/auditorias_page.dart';
import '../viewmodels/auditoria_viewmodels.dart';
import 'auditoria_visual.dart';

/// Auditorias em campo (agendadas, em andamento e concluídas).
class AuditoriasTab extends StatefulWidget {
  const AuditoriasTab({super.key});

  @override
  State<AuditoriasTab> createState() => _AuditoriasTabState();
}

class _AuditoriasTabState extends State<AuditoriasTab> {
  final _vm = sl<AuditoriasViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _abrir(Auditoria a) async {
    await abrirAuditoria(context, a, modelos: _vm.modelos);
    await _vm.recarregar();
  }

  Future<void> _nova() async {
    await abrirNovaAuditoria(context);
    await _vm.recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.add_task,
        label: 'Nova auditoria',
        onPressed: _nova,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final lista = _vm.lista;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _margem(context),
                  20,
                  _margem(context),
                  0,
                ),
                child: CampoBusca(
                  hint:
                      'Buscar por número, imóvel, proprietário ou corretor...',
                  onChanged: _vm.buscar,
                ),
              ),
              FiltroChips<StatusAuditoria>(
                padding: EdgeInsets.symmetric(horizontal: _margem(context)),
                opcoes: StatusAuditoria.values,
                selecionado: _vm.status,
                labelOf: (s) => '${s.label} (${_vm.contar(s)})',
                onChanged: _vm.filtrar,
              ),
              Expanded(
                child: !_vm.carregado
                    ? const Center(child: CircularProgressIndicator())
                    : lista.isEmpty
                    ? const EmptyState(
                        icon: Icons.fact_check_outlined,
                        message:
                            'Nenhuma auditoria. Agende a primeira visita '
                            'em "Nova auditoria".',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          _margem(context),
                          4,
                          _margem(context),
                          96,
                        ),
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

  Widget _card(Auditoria a) {
    final videos = a.midias.where((m) => m.video).length;
    final fotos = a.midias.length - videos;
    return CardPadrao(
      onTap: () => _abrir(a),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: a.status.cor.withValues(alpha: 0.15),
            child: Icon(Icons.fact_check_outlined, color: a.status.cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${a.numero} • ${_vm.nomeImovel(a.imovelId)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  [
                    a.tipo.label,
                    if (a.data != null) formatDate(a.data),
                    if (_vm.contatos[a.proprietarioId] case final c?)
                      'Proprietário: ${c.nome}',
                    if (_vm.usuarios[a.corretorId] case final u?) u.nome,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final e in [
                      EstadoItem.ok,
                      EstadoItem.atencao,
                      EstadoItem.problema,
                    ])
                      if (a.contar(e) > 0)
                        Text(
                          '${a.contar(e)} ${e.label.toLowerCase()}',
                          style: TextStyle(color: e.cor, fontSize: 12),
                        ),
                    if (fotos > 0)
                      Text(
                        '$fotos foto(s)',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    if (videos > 0)
                      Text(
                        '$videos vídeo(s)',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (a.nota != null) Estrelas(nota: a.nota, tamanho: 16),
          const SizedBox(width: 8),
          if (a.publicada)
            Tooltip(
              message: 'Publicada na Área do proprietário',
              child: Icon(Icons.public, color: AppColors.gold, size: 20),
            ),
          GoldChip(a.status.label, color: a.status.cor),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }
}

/// Margem lateral: menor no celular.
double _margem(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600 ? 16 : 24;
