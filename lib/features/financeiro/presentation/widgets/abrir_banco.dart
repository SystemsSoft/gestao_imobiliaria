import 'package:flutter/material.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/conta_bancaria.dart';
import '../../domain/usecases/financeiro_usecases.dart';
import 'abrir_sicoob.dart';

/// Botão "Abrir banco" do Financeiro: lista as contas bancárias que têm
/// link do internet banking cadastrado. Some quando nenhuma tem.
class BotaoAbrirBanco extends StatefulWidget {
  const BotaoAbrirBanco({super.key});

  @override
  State<BotaoAbrirBanco> createState() => _BotaoAbrirBancoState();
}

class _BotaoAbrirBancoState extends State<BotaoAbrirBanco> {
  late final Stream<List<ContaBancaria>> _contas =
      sl<ObservarContasBancarias>()();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ContaBancaria>>(
      stream: _contas,
      builder: (context, snapshot) {
        final comLink = [
          for (final c in snapshot.data ?? const <ContaBancaria>[])
            if (c.linkInternetBanking.isNotEmpty) c,
        ];
        if (comLink.isEmpty) return const SizedBox.shrink();
        return PopupMenuButton<ContaBancaria>(
          tooltip: 'Abrir internet banking',
          color: AppColors.navy,
          icon: const Icon(Icons.language, color: AppColors.gold),
          onSelected: (c) => abrirSicoob(context, link: c.linkInternetBanking),
          itemBuilder: (_) => [
            for (final c in comLink)
              PopupMenuItem(
                value: c,
                child: Text(
                  c.banco.isEmpty ? c.nome : '${c.nome} • ${c.banco}',
                ),
              ),
          ],
        );
      },
    );
  }
}
