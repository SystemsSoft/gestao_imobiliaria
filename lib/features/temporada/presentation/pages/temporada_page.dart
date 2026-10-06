import 'package:flutter/material.dart';

import '../widgets/calendario_tab.dart';
import '../widgets/reservas_tab.dart';

/// Locação por temporada: calendário de reservas e lista de reservas.
class TemporadaPage extends StatefulWidget {
  const TemporadaPage({super.key});

  @override
  State<TemporadaPage> createState() => _TemporadaPageState();
}

class _TemporadaPageState extends State<TemporadaPage> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.calendar_month_outlined),
                label: Text('Calendário'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.list_alt_outlined),
                label: Text('Reservas'),
              ),
            ],
            selected: {_aba},
            onSelectionChanged: (s) => setState(() => _aba = s.first),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _aba,
            children: const [CalendarioTab(), ReservasTab()],
          ),
        ),
      ],
    );
  }
}
