import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', //
  'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

String nomeMes(int mes) => _meses[mes - 1];

/// Seletor de mês/ano com setas para navegar entre competências.
class CompetenciaSelector extends StatelessWidget {
  const CompetenciaSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.anual = false,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  /// Navega por ano em vez de mês.
  final bool anual;

  @override
  Widget build(BuildContext context) {
    void mover(int delta) => onChanged(
      anual
          ? DateTime(value.year + delta)
          : DateTime(value.year, value.month + delta),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: anual ? 'Ano anterior' : 'Mês anterior',
            icon: const Icon(Icons.chevron_left, color: AppColors.gold),
            onPressed: () => mover(-1),
          ),
          SizedBox(
            width: anual ? 64 : 150,
            child: Text(
              anual ? '${value.year}' : '${nomeMes(value.month)}/${value.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: anual ? 'Próximo ano' : 'Próximo mês',
            icon: const Icon(Icons.chevron_right, color: AppColors.gold),
            onPressed: () => mover(1),
          ),
        ],
      ),
    );
  }
}
