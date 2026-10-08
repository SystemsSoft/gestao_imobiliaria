import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/evento.dart';
import '../viewmodels/central_viewmodel.dart';
import 'evento_dialog.dart';

IconData iconeTipoEvento(TipoEvento t) => switch (t) {
  TipoEvento.anotacao => Icons.sticky_note_2_outlined,
  TipoEvento.lembrete => Icons.alarm,
  TipoEvento.recado => Icons.chat_bubble_outline,
  TipoEvento.visita => Icons.directions_walk,
  TipoEvento.ligacao => Icons.phone_in_talk_outlined,
  TipoEvento.reuniao => Icons.groups_outlined,
};

Color _corSecao(TipoSecao t) => switch (t) {
  TipoSecao.atrasados => Colors.redAccent,
  TipoSecao.hoje => AppColors.gold,
  TipoSecao.proximos => AppColors.goldLight,
  TipoSecao.semData => Colors.white70,
  TipoSecao.concluidos => Colors.white38,
};

/// Agenda unificada: anotações, lembretes, recados, visitas, ligações e
/// reuniões, com notificações de itens atrasados e do dia.
class CentralTab extends StatefulWidget {
  const CentralTab({super.key});

  @override
  State<CentralTab> createState() => _CentralTabState();
}

class _CentralTabState extends State<CentralTab> {
  final _vm = sl<CentralViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.add_alert_outlined,
        label: 'Novo item',
        onPressed: () => showEventoDialog(context),
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (!_vm.carregado) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
            children: [
              _Notificacoes(
                atrasados: _vm.atrasados,
                hoje: _vm.paraHoje,
                sugestoes: _vm.sugestoes,
              ),
              const SizedBox(height: 12),
              FiltroChips<TipoEvento>(
                opcoes: TipoEvento.values,
                selecionado: _vm.filtroTipo,
                labelOf: (t) => t.label,
                onChanged: _vm.filtrar,
                padding: EdgeInsets.zero,
              ),
              if (_vm.vazio)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: EmptyState(
                    icon: Icons.event_note_outlined,
                    message:
                        'Sua agenda está vazia.\nRegistre anotações, lembretes, recados e visitas.',
                  ),
                ),
              for (final secao in _vm.secoes) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 6),
                  child: Text(
                    '${secao.titulo} (${secao.itens.length})',
                    style: TextStyle(
                      color: _corSecao(secao.tipo),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                for (final e in secao.itens)
                  _EventoTile(
                    vm: _vm,
                    evento: e,
                    destaque: _corSecao(secao.tipo),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Notificacoes extends StatelessWidget {
  const _Notificacoes({
    required this.atrasados,
    required this.hoje,
    required this.sugestoes,
  });

  final int atrasados;
  final int hoje;
  final int sugestoes;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, Color cor, int n, String label) => Expanded(
      child: Column(
        children: [
          Icon(icon, color: cor),
          const SizedBox(height: 4),
          Text(
            '$n',
            style: TextStyle(
              color: cor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.blue.withValues(alpha: 0.5), AppColors.navy],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          item(
            Icons.warning_amber_rounded,
            Colors.redAccent,
            atrasados,
            'Atrasados',
          ),
          item(Icons.today, AppColors.gold, hoje, 'Para hoje'),
          item(
            Icons.auto_awesome,
            Colors.greenAccent,
            sugestoes,
            'Sugestões de negócio',
          ),
        ],
      ),
    );
  }
}

class _EventoTile extends StatelessWidget {
  const _EventoTile({
    required this.vm,
    required this.evento,
    required this.destaque,
  });

  final CentralViewModel vm;
  final Evento evento;
  final Color destaque;

  @override
  Widget build(BuildContext context) {
    final detalhes = [
      if (evento.dataHora != null) formatDateTime(evento.dataHora),
      ?vm.nomeContato(evento.contatoId),
      ?vm.codigoImovel(evento.imovelId),
    ].join('  •  ');

    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: destaque.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        onTap: () => showEventoDialog(context, evento: evento),
        leading: Checkbox(
          value: evento.concluido,
          activeColor: AppColors.gold,
          checkColor: AppColors.navyDark,
          onChanged: (_) => vm.alternarConcluido(evento),
        ),
        title: Row(
          children: [
            Icon(iconeTipoEvento(evento.tipo), size: 16, color: destaque),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                evento.titulo,
                style: TextStyle(
                  decoration: evento.concluido
                      ? TextDecoration.lineThrough
                      : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (evento.prioridade == Prioridade.alta)
              const GoldChip('Alta', color: Colors.redAccent),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detalhes.isNotEmpty)
              Text(detalhes, style: const TextStyle(fontSize: 12)),
            if (evento.descricao.isNotEmpty)
              Text(
                evento.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            if (await confirmDelete(context, 'Excluir "${evento.titulo}"?')) {
              await vm.remover(evento.id);
            }
          },
        ),
      ),
    );
  }
}
