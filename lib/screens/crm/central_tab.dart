import 'package:flutter/material.dart';

import '../../data/crm_store.dart';
import '../../models/enums.dart';
import '../../models/evento.dart';
import '../../services/matching.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/form_widgets.dart';
import 'evento_dialog.dart';

/// Agenda unificada: anotações, lembretes, recados, visitas, ligações e
/// reuniões, com notificações de itens atrasados e do dia.
class CentralTab extends StatefulWidget {
  const CentralTab({super.key});

  @override
  State<CentralTab> createState() => _CentralTabState();
}

class _CentralTabState extends State<CentralTab> {
  final _store = CrmStore.instance;
  TipoEvento? _tipo;

  static IconData iconeTipo(TipoEvento t) => switch (t) {
    TipoEvento.anotacao => Icons.sticky_note_2_outlined,
    TipoEvento.lembrete => Icons.alarm,
    TipoEvento.recado => Icons.chat_bubble_outline,
    TipoEvento.visita => Icons.directions_walk,
    TipoEvento.ligacao => Icons.phone_in_talk_outlined,
    TipoEvento.reuniao => Icons.groups_outlined,
  };

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
        listenable: _store,
        builder: (context, _) {
          final agora = DateTime.now();
          final inicioHoje = DateTime(agora.year, agora.month, agora.day);
          final fimHoje = inicioHoje.add(const Duration(days: 1));

          final todos = _store.eventos
              .where((e) => _tipo == null || e.tipo == _tipo)
              .toList();
          int porData(Evento a, Evento b) =>
              (a.dataHora ?? a.criadoEm).compareTo(b.dataHora ?? b.criadoEm);

          final abertos = todos.where((e) => !e.concluido).toList();
          final atrasados =
              abertos
                  .where(
                    (e) =>
                        e.dataHora != null && e.dataHora!.isBefore(inicioHoje),
                  )
                  .toList()
                ..sort(porData);
          final hoje =
              abertos
                  .where(
                    (e) =>
                        e.dataHora != null &&
                        !e.dataHora!.isBefore(inicioHoje) &&
                        e.dataHora!.isBefore(fimHoje),
                  )
                  .toList()
                ..sort(porData);
          final proximos =
              abertos
                  .where(
                    (e) => e.dataHora != null && !e.dataHora!.isBefore(fimHoje),
                  )
                  .toList()
                ..sort(porData);
          final semData = abertos.where((e) => e.dataHora == null).toList()
            ..sort(porData);
          final concluidos = todos.where((e) => e.concluido).toList()
            ..sort((a, b) => porData(b, a));

          final sugestoes = _store.contatos
              .map((c) => sugestoesParaContato(c, _store.imoveis).length)
              .fold<int>(0, (a, b) => a + b);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              _Notificacoes(
                atrasados: atrasados.length,
                hoje: hoje.length,
                sugestoes: sugestoes,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final t in [null, ...TipoEvento.values])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t?.label ?? 'Todos'),
                          selected: _tipo == t,
                          selectedColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color: _tipo == t
                                ? AppColors.navyDark
                                : Colors.white,
                          ),
                          onSelected: (_) => setState(() => _tipo = t),
                        ),
                      ),
                  ],
                ),
              ),
              if (todos.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: EmptyState(
                    icon: Icons.event_note_outlined,
                    message:
                        'Sua agenda está vazia.\nRegistre anotações, lembretes, recados e visitas.',
                  ),
                ),
              ..._secao('Atrasados', atrasados, Colors.redAccent),
              ..._secao('Hoje', hoje, AppColors.gold),
              ..._secao('Próximos', proximos, AppColors.goldLight),
              ..._secao('Anotações e itens sem data', semData, Colors.white70),
              ..._secao('Concluídos', concluidos, Colors.white38),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _secao(String titulo, List<Evento> itens, Color cor) {
    if (itens.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(
          '$titulo (${itens.length})',
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      for (final e in itens) _EventoTile(evento: e, destaque: cor),
    ];
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
  const _EventoTile({required this.evento, required this.destaque});

  final Evento evento;
  final Color destaque;

  @override
  Widget build(BuildContext context) {
    final store = CrmStore.instance;
    final contato = store.contatoPorId(evento.contatoId);
    final imovel = store.imovelPorId(evento.imovelId);
    final detalhes = [
      if (evento.dataHora != null) formatDateTime(evento.dataHora),
      if (contato != null) contato.nome,
      if (imovel != null) imovel.codigo,
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
          onChanged: (_) => store.alternarConcluido(evento),
        ),
        title: Row(
          children: [
            Icon(
              _CentralTabState.iconeTipo(evento.tipo),
              size: 16,
              color: destaque,
            ),
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
              store.removerEvento(evento.id);
            }
          },
        ),
      ),
    );
  }
}
