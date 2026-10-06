import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../contratos/domain/entities/modelo_contrato.dart';
import '../../../contratos/presentation/widgets/modelos_tab.dart';
import '../widgets/comissoes_tab.dart';
import '../widgets/recebimentos_tab.dart';
import '../widgets/vendas_tab.dart';

/// Módulo "Administração de Vendas".
class AdministracaoVendasPage extends StatelessWidget {
  const AdministracaoVendasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
                Tab(icon: Icon(Icons.sell_outlined), text: 'Vendas'),
                Tab(
                  icon: Icon(Icons.calendar_month_outlined),
                  text: 'Recebimentos',
                ),
                Tab(icon: Icon(Icons.percent), text: 'Comissões'),
                Tab(
                  icon: Icon(Icons.article_outlined),
                  text: 'Modelos de contrato',
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                VendasTab(),
                RecebimentosTab(),
                ComissoesTab(),
                ModelosTab(tipo: TipoModelo.venda),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
