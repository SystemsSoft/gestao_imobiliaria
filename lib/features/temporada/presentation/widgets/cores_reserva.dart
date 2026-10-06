import 'package:flutter/material.dart';

import '../../domain/entities/reserva.dart';
import '../../domain/entities/reserva_enums.dart';

/// Cor usada para cada estado da reserva no calendário.
Color corDaReserva(Reserva r, DateTime hoje) {
  if (r.bloqueio) return Colors.blueGrey;
  return switch (r.estadoEm(hoje)) {
    EstadoReserva.preReserva => Colors.orangeAccent,
    EstadoReserva.confirmada => const Color(0xFFF5C432),
    EstadoReserva.hospedada => Colors.greenAccent,
    EstadoReserva.concluida => const Color(0xFF5C7CB5),
    EstadoReserva.cancelada => Colors.grey,
  };
}

/// Legenda das cores do calendário.
class LegendaCalendario extends StatelessWidget {
  const LegendaCalendario({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        item(Colors.orangeAccent, 'Pré-reserva'),
        item(const Color(0xFFF5C432), 'Confirmada'),
        item(Colors.greenAccent, 'Hospedado'),
        item(const Color(0xFF5C7CB5), 'Concluída'),
        item(Colors.blueGrey, 'Bloqueio'),
      ],
    );
  }
}
