import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/entities/reserva_enums.dart';
import '../pages/reserva_form_page.dart';
import '../viewmodels/reservas_viewmodel.dart';
import 'cores_reserva.dart';

class ReservasTab extends StatefulWidget {
  const ReservasTab({super.key});

  @override
  State<ReservasTab> createState() => _ReservasTabState();
}

class _ReservasTabState extends State<ReservasTab> {
  final _vm = sl<ReservasViewModel>();

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrir([Reserva? r]) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ReservaFormPage(reserva: r)));

  Future<void> _acao(Future<bool> Function() f, [String? sucesso]) async {
    final ok = await f();
    if (!mounted) return;
    if (!ok) {
      mostrarMensagem(context, _vm.erro ?? 'Não foi possível concluir.');
    } else if (sucesso != null) {
      mostrarMensagem(context, sucesso);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: goldFab(
        icon: Icons.event_available_outlined,
        label: 'Nova reserva',
        onPressed: _abrir,
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
                    hintText: 'Buscar por número, hóspede ou imóvel...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final f in FiltroReserva.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f.label),
                          selected: _vm.filtro == f,
                          selectedColor: AppColors.gold,
                          labelStyle: TextStyle(
                            color: _vm.filtro == f
                                ? AppColors.navyDark
                                : Colors.white,
                          ),
                          onSelected: (_) => _vm.filtrar(f),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: !_vm.carregado
                    ? const SizedBox.shrink()
                    : lista.isEmpty
                    ? EmptyState(
                        icon: Icons.beach_access_outlined,
                        message: _vm.semCadastro
                            ? 'Nenhuma reserva.\nUse "Nova reserva" ou toque em um dia livre do calendário.'
                            : 'Nenhuma reserva neste filtro.',
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

  Widget _card(Reserva r) {
    final estado = _vm.estado(r);
    final cor = corDaReserva(r, _vm.hoje);
    return CardPadrao(
      borda: cor,
      onTap: () => _abrir(r),
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
                      r.bloqueio ? 'BLOQUEIO' : r.numero,
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GoldChip(
                      r.bloqueio ? 'Bloqueio' : estado.label,
                      color: cor,
                    ),
                    if (!r.bloqueio &&
                        r.saldo > 0 &&
                        r.situacao != SituacaoReserva.cancelada) ...[
                      const SizedBox(width: 6),
                      const GoldChip(
                        'Saldo a receber',
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _vm.hospede(r),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _vm.imovel(r),
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDate(r.checkIn)} → ${formatDate(r.checkOut)} • ${r.noites} noite(s)'
                  '${r.bloqueio ? '' : ' • ${formatMoney(r.total)} (pago ${formatMoney(r.valorPago)})'}',
                  style: TextStyle(
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
              'edit' => _abrir(r),
              'confirmar' => _acao(
                () => _vm.confirmar(r),
                'Reserva confirmada.',
              ),
              'quitar' => _acao(() => _vm.quitar(r), 'Reserva quitada.'),
              'cancelar' => _acao(() => _vm.cancelar(r), 'Reserva cancelada.'),
              _ => () async {
                if (await confirmDelete(context, 'Excluir esta reserva?')) {
                  await _acao(() => _vm.remover(r));
                }
              }(),
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              if (!r.bloqueio && r.situacao != SituacaoReserva.confirmada)
                PopupMenuItem(
                  value: 'confirmar',
                  child: Text(
                    r.situacao == SituacaoReserva.cancelada
                        ? 'Reativar'
                        : 'Confirmar reserva',
                  ),
                ),
              if (!r.bloqueio && r.saldo > 0 && r.ocupa)
                const PopupMenuItem(
                  value: 'quitar',
                  child: Text('Registrar pagamento do saldo'),
                ),
              if (r.ocupa)
                PopupMenuItem(
                  value: 'cancelar',
                  child: Text(r.bloqueio ? 'Desbloquear' : 'Cancelar reserva'),
                ),
              const PopupMenuItem(value: 'del', child: Text('Excluir')),
            ],
          ),
        ],
      ),
    );
  }
}
