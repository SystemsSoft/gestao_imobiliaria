import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/manutencao.dart';

IconData iconeTipo(TipoManutencao t) => switch (t) {
  TipoManutencao.eletrica => Icons.electrical_services,
  TipoManutencao.alvenaria => Icons.foundation,
  TipoManutencao.pintura => Icons.format_paint_outlined,
  TipoManutencao.acabamento => Icons.carpenter_outlined,
  TipoManutencao.outros => Icons.handyman_outlined,
};

Color corStatus(StatusManutencao s) => switch (s) {
  StatusManutencao.pendente => Colors.orangeAccent,
  StatusManutencao.emAndamento => AppColors.blueGlow,
  StatusManutencao.concluida => Colors.greenAccent,
};
