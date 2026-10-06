import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/modelos_prontos_tab.dart';
import '../widgets/modelos_tab.dart';

/// Módulo "Contratos e Relatórios": modelos de contrato prontos e próprios.
class ContratosRelatoriosPage extends StatelessWidget {
  const ContratosRelatoriosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
                  icon: Icon(Icons.auto_stories_outlined),
                  text: 'Modelos prontos',
                ),
                Tab(icon: Icon(Icons.edit_document), text: 'Meus modelos'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [ModelosProntosTab(), ModelosTab()]),
          ),
        ],
      ),
    );
  }
}
