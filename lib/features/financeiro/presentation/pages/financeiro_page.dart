import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/boletos_tab.dart';
import '../widgets/conciliacao_tab.dart';
import '../widgets/contas_tab.dart';
import '../widgets/encargos_tab.dart';
import '../widgets/fluxo_caixa_tab.dart';

/// Módulo "Financeiro".
class FinanceiroPage extends StatelessWidget {
  const FinanceiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Material(
            color: AppColors.navy,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.gold,
              labelColor: AppColors.gold,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(
                  icon: Icon(Icons.swap_vert),
                  text: 'Contas a pagar e a receber',
                ),
                Tab(icon: Icon(Icons.show_chart), text: 'Fluxo de caixa'),
                Tab(
                  icon: Icon(Icons.account_balance_outlined),
                  text: 'Conciliação bancária',
                ),
                Tab(
                  icon: Icon(Icons.qr_code_2),
                  text: 'Boletos e baixa automática',
                ),
                Tab(icon: Icon(Icons.percent), text: 'Juros, multa e correção'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ContasTab(),
                FluxoCaixaTab(),
                ConciliacaoTab(),
                BoletosTab(),
                EncargosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
