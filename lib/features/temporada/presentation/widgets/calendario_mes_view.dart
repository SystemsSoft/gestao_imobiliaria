import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/dia_calendario.dart';
import '../../domain/entities/reserva.dart';
import 'cores_reserva.dart';

const _semana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

/// Grade mensal de um imóvel. Cada dia é dividido em duas metades: a noite
/// anterior (esquerda) e a noite que começa no dia (direita), de modo que
/// check-in e check-out no mesmo dia ficam visíveis.
class CalendarioMesView extends StatelessWidget {
  const CalendarioMesView({
    super.key,
    required this.ano,
    required this.mes,
    required this.dias,
    required this.hoje,
    required this.nomeHospede,
    required this.onReserva,
    required this.onDiaLivre,
  });

  final int ano;
  final int mes;
  final List<DiaCalendario> dias;
  final DateTime hoje;
  final String Function(Reserva) nomeHospede;
  final ValueChanged<Reserva> onReserva;
  final ValueChanged<DateTime> onDiaLivre;

  @override
  Widget build(BuildContext context) {
    final deslocamento = DateTime(ano, mes).weekday % 7; // domingo = 0
    final celulas = <DiaCalendario?>[
      ...List<DiaCalendario?>.filled(deslocamento, null),
      ...dias,
    ];
    while (celulas.length % 7 != 0) {
      celulas.add(null);
    }
    return Column(
      children: [
        Row(
          children: [
            for (final d in _semana)
              Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < celulas.length; i += 7)
          Row(
            children: [
              for (final c in celulas.sublist(i, i + 7))
                Expanded(
                  child: c == null ? const SizedBox(height: 64) : _celula(c),
                ),
            ],
          ),
      ],
    );
  }

  Widget _celula(DiaCalendario d) {
    final esq = d.noiteAnterior;
    final dir = d.noite;
    final ehHoje = d.data == hoje;
    Color? cor(Reserva? r) =>
        r == null ? null : corDaReserva(r, hoje).withValues(alpha: 0.75);
    final reserva = dir ?? esq;
    // Rótulo no dia de entrada (ou no primeiro dia do mês se já em curso).
    final rotulo =
        dir != null && (d.checkIn || d.data.day == 1) && !dir.bloqueio
        ? nomeHospede(dir).split(' ').first
        : dir != null && d.checkIn && dir.bloqueio
        ? nomeHospede(dir)
        : null;
    return Padding(
      padding: const EdgeInsets.all(1),
      child: InkWell(
        onTap: () =>
            reserva == null ? onDiaLivre(d.data) : onReserva(dir ?? esq!),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: ehHoje
                  ? AppColors.gold
                  : Colors.white.withValues(alpha: 0.1),
              width: ehHoje ? 2 : 1,
            ),
            color: Colors.white.withValues(alpha: 0.03),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(child: Container(color: cor(esq))),
                    Expanded(child: Container(color: cor(dir))),
                  ],
                ),
                Positioned(
                  left: 4,
                  top: 2,
                  child: Text(
                    '${d.data.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: reserva == null
                          ? Colors.white70
                          : AppColors.navyDark,
                    ),
                  ),
                ),
                if (d.viradaDeHospede)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Icon(
                      Icons.swap_horiz,
                      size: 12,
                      color: AppColors.navyDark,
                    ),
                  ),
                if (rotulo != null)
                  Positioned(
                    left: 3,
                    right: 2,
                    bottom: 2,
                    child: Text(
                      rotulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
