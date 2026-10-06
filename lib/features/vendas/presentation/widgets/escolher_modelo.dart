import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../contratos/domain/entities/modelo_contrato.dart';

/// Usa o único modelo disponível ou pergunta qual imprimir.
Future<ModeloContrato?> escolherModelo(
  BuildContext context,
  List<ModeloContrato> modelos,
) async {
  if (modelos.length == 1) return modelos.first;
  return showDialog<ModeloContrato>(
    context: context,
    builder: (ctx) => SimpleDialog(
      backgroundColor: AppColors.navy,
      title: const Text('Escolha o modelo'),
      children: [
        for (final m in modelos)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, m),
            child: Text(m.nome),
          ),
      ],
    ),
  );
}
